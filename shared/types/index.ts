// Shared type definitions for Abyssal Assets
// Used by both client and server for type-safe communication

export interface MarketItem {
  id: string
  name: string
  tier: Tier
  price: number
  quantity: number
  sellerId?: string
  sellerName?: string
  stats: Record<string, number>
  visual: {
    sprite: string
    particleEffect?: string
    shader?: string
  }
  provenance: {
    creatorId?: string
    creationTimestamp: number
    tradeHistory: TradeRecord[]
  }
  metadata: {
    discontinued: boolean
    limitedEdition: boolean
    eventSource?: string
    serialNumber?: number
  }
}

export type Tier =
  | 'noob'
  | 'common'
  | 'uncommon'
  | 'rare'
  | 'epic'
  | 'legendary'
  | 'mythic'

export const TIER_ORDER: Tier[] = [
  'noob',
  'common',
  'uncommon',
  'rare',
  'epic',
  'legendary',
  'mythic',
]

export const TIER_COLORS: Record<Tier, number> = {
  noob: 0x888888,
  common: 0xffffff,
  uncommon: 0x4caf50,
  rare: 0x2196f3,
  epic: 0x9c27b0,
  legendary: 0xffd700,
  mythic: 0xff00ff,
}

export interface TradeRecord {
  from: string
  to: string
  price: number
  timestamp: number
}

export interface OrderBookEntry {
  price: number
  quantity: number
  orders: number
  isBuy: boolean
}

export interface PlayerMarketData {
  abyssalCoins: number
  inventory: MarketItem[]
  activeListings: MarketListing[]
  tradeHistory: TradeRecord[]
}

export interface MarketListing {
  id: string
  itemId: string
  price: number
  quantity: number
  timestamp: number
  expiresAt: number
}

export interface DredgeSpotData {
  x: number
  y: number
  zone: Zone
  depth: number
  active: boolean
  cooldown: number
}

export type Zone = 'shallows' | 'standard' | 'deep' | 'abyssal' | 'trench'

export const ZONES: Zone[] = ['shallows', 'standard', 'deep', 'abyssal', 'trench']

export interface PlayerData {
  abyssalCoins: number
  inventory: MarketItem[]
  boatTier: number
  clout: number
  currentZone: Zone
  skillLevels: Record<string, number>
  questFlags: Record<string, boolean>
}

export interface HatData extends MarketItem {
  // All MarketItem fields + hat-specific
  hatType: string
  equipSlot: 'head'
}

export interface BoatData {
  tier: number
  name: string
  maxDepth: number
  sonarRange: number
  cargoCapacity: number
  speed: number
  durability: number
}

export interface SkillNode {
  id: string
  name: string
  sephira: 'yesod' | 'hod' | 'tiferet' | 'netzach' | 'chesed' | 'binah'
  tier: 1 | 2 | 3 | 4 | 5
  prerequisites: string[]
  questGate?: string
  bidirectionalTrace: boolean
  description: string
  effects: SkillEffect[]
}

export type SkillEffect =
  | { type: 'dredge_speed'; value: number }
  | { type: 'sonar_resolution'; value: number }
  | { type: 'crafting_success'; value: number }
  | { type: 'market_fee_reduction'; value: number }
  | { type: 'navigation_speed'; value: number }
  | { type: 'lore_discovery'; value: number }
  | { type: 'hat_drop_rate'; value: number }
  | { type: 'essence_yield'; value: number }

export interface QuestData {
  id: string
  name: string
  act: 1 | 2 | 3
  description: string
  primarySkill: string
  secondarySkills: string[]
  unlockOnComplete: string[]
  narrativeBeat: string
  objectives: QuestObjective[]
  rewards: QuestReward[]
}

export interface QuestObjective {
  id: string
  type: 'dredge' | 'craft' | 'trade' | 'explore' | 'lore' | 'defeat'
  target: string
  count: number
  description: string
}

export interface QuestReward {
  type: 'coins' | 'hat' | 'skill_xp' | 'recipe' | 'access' | 'title'
  value: string | number
  quantity?: number
}

export interface MonsterLootEntry {
  monsterId: string
  table: WeightedDrop[]
  valorization: {
    identifyScrollCost: number
    cleanseEssenceCost: number
    salvageYield: ResourceBundle
  }
}

export interface WeightedDrop {
  hatId: string
  weight: number
  minTier: Tier
  maxTier: Tier
}

export interface ResourceBundle {
  essence: number
  scrap: number
  rareMaterial?: string
}

export interface NetworkEvents {
  'player:join': (data: { playerId: string; playerData: PlayerData }) => void
  'player:leave': (data: { playerId: string }) => void
  'market:update': (data: { items: MarketItem[]; orderBook: { buys: OrderBookEntry[]; sells: OrderBookEntry[] } }) => void
  'dredge:result': (data: { success: boolean; loot?: MarketItem; spotId: string }) => void
  'chat:message': (data: { from: string; text: string; channel: string }) => void
  'quest:progress': (data: { questId: string; objectiveId: string; progress: number }) => void
  'skill:xp': (data: { skillId: string; xp: number }) => void
  'zone:change': (data: { playerId: string; from: Zone; to: Zone }) => void
  'nessie:spawn': (data: { zone: Zone; position: { x: number; y: number } }) => void
}

export interface ServerToClientEvents {
  'market:items': { items: MarketItem[] }
  'market:orderbook': { buys: OrderBookEntry[]; sells: OrderBookEntry[] }
  'dredge:spot': { spot: DredgeSpotData }
  'dredge:start': { spotId: string; difficulty: string }
  'dredge:complete': { success: boolean; loot?: MarketItem; cloutGained: number }
  'player:update': { coins: number; clout: number; inventory: MarketItem[] }
  'quest:update': { questId: string; progress: number }
  'skill:levelup': { skillId: string; newLevel: number }
}

export interface ClientToServerEvents {
  'market:buy': { itemId: string; price: number; quantity: number }
  'market:sell': { itemId: string; price: number; quantity: number }
  'market:list': { itemId: string; price: number; quantity: number }
  'dredge:start': { spotId: string }
  'dredge:action': { sweepAngle: number }
  'player:move': { x: number; y: number; angle: number }
  'chat:send': { text: string; channel: string }
  'quest:accept': { questId: string }
  'skill:train': { skillId: string }
}