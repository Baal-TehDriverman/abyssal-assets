import 'phaser'
import { BootScene } from './scenes/BootScene'
import { PreloadScene } from './scenes/PreloadScene'
import { MainMenuScene } from './scenes/MainMenuScene'
import { GameScene } from './scenes/GameScene'
import { DredgeMiniGameScene } from './scenes/DredgeMiniGameScene'
import { MarketScene } from './scenes/MarketScene'

// Vite/ImportMeta type declaration
declare global {
  interface ImportMeta {
    env: {
      readonly DEV: boolean
      readonly PROD: boolean
      readonly MODE: string
      readonly BASE_URL: string
      [key: string]: string | boolean | undefined
    }
  }
}

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.WEBGL,
  parent: 'game-container',
  width: window.innerWidth,
  height: window.innerHeight,
  scale: {
    mode: Phaser.Scale.RESIZE,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: window.innerWidth,
    height: window.innerHeight,
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 0 },
      debug: import.meta.env.DEV,
    },
  },
  render: {
    antialias: false,
    pixelArt: true,
    roundPixels: true,
  },
  input: {
    gamepad: true,
    keyboard: true,
  },
  audio: {
    disableWebAudio: false,
  },
  scene: [
    BootScene,
    PreloadScene,
    MainMenuScene,
    GameScene,
    DredgeMiniGameScene,
    MarketScene,
  ],
  backgroundColor: '#0a0a12',
  dom: {
    createContainer: true,
  },
  callbacks: {
    postBoot: () => {
      document.getElementById('loading')?.classList.add('hidden')
    },
  },
}

class AbyssalAssetsGame extends Phaser.Game {
  constructor(config: Phaser.Types.Core.GameConfig) {
    super(config)
    this.events.on('resize', this.handleResize, this)
    window.addEventListener('resize', () => this.handleResize())
  }

  private handleResize(): void {
    const width = window.innerWidth
    const height = window.innerHeight
    this.scale.resize(width, height)
    this.scene.scenes.forEach((scene) => {
      if (scene.scene.isActive()) {
        scene.cameras.main.setViewport(0, 0, width, height)
      }
    })
  }
}

// Initialize game when DOM is ready
if (document.readyState === 'complete') {
  new AbyssalAssetsGame(config)
} else {
  window.addEventListener('load', () => new AbyssalAssetsGame(config))
}

// Global type declarations
declare global {
  interface Window {
    game: AbyssalAssetsGame
    __ABYSSAL_DEBUG__: boolean
  }
}

window.game = new AbyssalAssetsGame(config)
window.__ABYSSAL_DEBUG__ = import.meta.env.DEV