// Service Worker for Abyssal Assets Mobile
// Handles offline caching, push notifications, background sync

var STATIC_CACHE = 'abyssal-static-v1';
var DYNAMIC_CACHE = 'abyssal-dynamic-v1';
var OFFLINE_CACHE = 'abyssal-offline-v1';

var STATIC_ASSETS = [
  '/',
  '/mobile',
  '/mobile/dredge',
  '/mobile/exchange',
  '/mobile/inventory',
  '/mobile/admin',
  '/manifest.json',
  '/favicon.svg',
];

var OFFLINE_CRITICAL_PATHS = [
  '/api/auth/me',
  '/api/inventory',
  '/api/market',
  '/api/market/stats',
  '/api/leaderboard/clout',
  '/api/leaderboard/wealth',
];

// Install - cache static assets
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(STATIC_CACHE).then(function(cache) {
      return cache.addAll(STATIC_ASSETS);
    }).then(function() {
      self.skipWaiting();
    })
  );
});

// Activate - clean old caches
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames
          .filter(function(name) {
            return name !== STATIC_CACHE && name !== DYNAMIC_CACHE && name !== OFFLINE_CACHE;
          })
          .map(function(name) {
            return caches.delete(name);
          })
      );
    }).then(function() {
      self.clients.claim();
    })
  );
});

// Fetch - network first for API, cache first for static
self.addEventListener('fetch', function(event) {
  var request = event.request;
  var url = new URL(request.url);
  
  if (request.method !== 'GET') return;
  
  // API requests - network first with offline fallback
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(networkFirstWithCache(request));
    return;
  }
  
  // Static assets - cache first
  var isStatic = STATIC_ASSETS.some(function(asset) { 
    return url.pathname === asset || url.pathname.startsWith(asset); 
  });
  if (isStatic) {
    event.respondWith(cacheFirst(request));
    return;
  }
  
  // Default: network first
  event.respondWith(networkFirstWithCache(request));
});

function cacheFirst(request) {
  return caches.open(STATIC_CACHE).then(function(cache) {
    return cache.match(request).then(function(cached) {
      if (cached) return cached;
      return fetch(request).then(function(response) {
        if (response.ok) cache.put(request, response.clone());
        return response;
      }).catch(function() {
        return new Response('Offline', { status: 503 });
      });
    });
  });
}

function networkFirstWithCache(request) {
  var cachePromise = caches.open(DYNAMIC_CACHE);
  
  return fetch(request).then(function(response) {
    if (response.ok) {
      cachePromise.then(function(c) { c.put(request, response.clone()); });
    }
    return response;
  }).catch(function() {
    return cachePromise.then(function(c) { return c.match(request); }).then(function(cached) {
      if (cached) return cached;
      
      var url = new URL(request.url);
      var isCritical = OFFLINE_CRITICAL_PATHS.some(function(path) { return request.url.includes(path); });
      if (isCritical) {
        return caches.open('abyssal-offline-v1').then(function(oc) { return oc.match(request); }).then(function(ocr) {
          if (ocr) return ocr;
        });
      }
      
      return new Response(JSON.stringify({ error: 'Offline', offline: true }), {
        status: 503,
        headers: { 'Content-Type': 'application/json' },
      });
    });
  };
}

// Push notifications
self.addEventListener('push', function(event) {
  if (!event.data) return;
  
  var data = event.data.json();
  var options = {
    body: data.body,
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    vibrate: [200, 100, 200],
    tag: data.tag || 'default',
    data: data.data || {},
    actions: data.actions || [],
    requireInteraction: data.requireInteraction || false,
    silent: false,
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// Notification click
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  
  var data = event.notification.data;
  var action = event.action;
  
  var url = '/mobile';
  if (data && data.url) url = data.url;
  else if (action === 'dredge') url = '/mobile/dredge';
  else if (action === 'exchange') url = '/mobile/exchange';
  else if (action === 'inventory') url = '/mobile/inventory';
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clients) {
      for (var i = 0; i < clients.length; i++) {
        var client = clients[i];
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus().then(function() { return client.navigate(url); });
        }
      }
      return clients.openWindow(url);
    })
  );
});

// Background sync
self.addEventListener('sync', function(event) {
  if (event.tag === 'sync-market') {
    event.waitUntil(syncMarketData());
  } else if (event.tag === 'sync-inventory') {
    event.waitUntil(syncInventory());
  } else if (event.tag === 'send-commands') {
    event.waitUntil(sendQueuedCommands());
  }
});

function syncMarketData() {
  return fetch('/api/market').then(function(response) {
    if (response.ok) {
      return caches.open('abyssal-offline-v1').then(function(cache) {
        return cache.put('/api/market', response.clone());
      });
    }
  }).catch(function(error) {
    console.error('Market sync failed:', error);
  });
}

function syncInventory() {
  return fetch('/api/inventory').then(function(response) {
    if (response.ok) {
      return caches.open('abyssal-offline-v1').then(function(cache) {
        return cache.put('/api/inventory', response.clone());
      });
    }
  }).catch(function(error) {
    console.error('Inventory sync failed:', error);
  });
}

function sendQueuedCommands() {
  return openDB().then(function(db) {
    var tx = db.transaction('commandQueue', 'readwrite');
    var store = tx.objectStore('commandQueue');
    return store.getAll().then(function(commands) {
      var promises = commands.map(function(cmd) {
        return fetch('/api/admin/commands', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(cmd),
        }).then(function() {
          return store.delete(cmd.id);
        }).catch(function(e) {
          console.error('Command send failed:', e);
        });
      });
      return Promise.all(promises);
    });
  });
}

// Periodic sync (if supported)
self.addEventListener('periodicsync', function(event) {
  if (event.tag === 'periodic-market-sync') {
    event.waitUntil(syncMarketData());
  }
});

// Message handling from main thread
self.addEventListener('message', function(event) {
  if (event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  } else if (event.data.type === 'CACHE_API_RESPONSE') {
    cacheApiResponse(event.data.url, event.data.response);
  } else if (event.data.type === 'QUEUE_COMMAND') {
    queueCommand(event.data.command, event.data.args);
  }
});

function cacheApiResponse(url, response) {
  caches.open('abyssal-offline-v1').then(function(cache) {
    cache.put(url, response.clone());
  });
}

// IndexedDB for command queue
function openDB() {
  return new Promise(function(resolve, reject) {
    var request = indexedDB.open('AbyssalAssets', 1);
    request.onerror = function() { reject(request.error); };
    request.onsuccess = function() { resolve(request.result); };
    request.onupgradeneeded = function(event) {
      var db = event.target.result;
      if (!db.objectStoreNames.contains('commandQueue')) {
        db.createObjectStore('commandQueue', { keyPath: 'id', autoIncrement: true });
      }
    };
  });
}

function queueCommand(command, args) {
  openDB().then(function(db) {
    var tx = db.transaction('commandQueue', 'readwrite');
    var store = tx.objectStore('commandQueue');
    store.add({ command: command, args: args, timestamp: Date.now() });
  });
}

// Periodic background sync registration
self.addEventListener('periodicsync', function(event) {
  if (event.tag === 'market-sync') {
    event.waitUntil(syncMarketData());
  } else if (event.tag === 'inventory-sync') {
    event.waitUntil(syncInventory());
  }
});

// Cleanup old caches periodically
setInterval(function() {
  caches.keys().then(function(names) {
    names.forEach(function(name) {
      if (name.startsWith('abyssal-') && 
          !['abyssal-static-v1', 'abyssal-dynamic-v1', 'abyssal-offline-v1'].includes(name)) {
        caches.delete(name);
      }
    });
  });
}, 1000 * 60 * 60 * 24); // Daily