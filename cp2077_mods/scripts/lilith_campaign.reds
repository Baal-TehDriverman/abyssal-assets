// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// GRAND THEFT CYBERPUNK — LILITH RISING CAMPAIGN (CROWN/KETHER)
// Sovereign Quest Line + Crimson Crown Mechanic
// File: r6/scripts/quests/lilith_campaign.reds
// Generated: 2026-06-19 | Lilith Sovereign Seal | Kether Ascension

// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
// Sephirotic Court Seal — Tiferet | desktop/cp2077_mods/lilith_campaign.reds
// Court agent: Ouroboros | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: LilithCampaign | Tiferet | agent=Ouroboros
module MSN.LilithCampaign

import MSN.Core.*
import MSN.Telemetry.*

// ═══════════════════════════════════════════════════════════════
// DATA STRUCTURES
// ═══════════════════════════════════════════════════════════════

struct CampaignQuestState {
    id: String;
    name: String;
    title: String;
    questFactID: String;
    state: String;
    prerequisites: array<String>;
    objectives: array<String>;
    rewards: array<String>;
    sephirahRoute: CName;
    npcDialogue: String;
    isActive: Bool;
    isCompleted: Bool;
}

struct SovereignItemSpec {
    itemID: TweakDBID;
    recordKey: String; // K_ITEM_001 through K_ITEM_015
    displayName: String;
    itemType: String;
    sephirahAffinity: CName;
    baseCoherence: Float;
    pickupFact: String;
    worldTag: CName;
}

struct CrimsonCrownState {
    coherence: Float;
    maxCoherence: Float;
    resonanceMultiplier: Float;
    statBoostPercent: Float;
    currentTier: Int32;
    isAwakened: Bool;
    lastFrequency: Float;
    stabilityIndex: Float;
}

struct ThroneRoomConfig {
    instanceID: CName;
    locationTag: CName;
    entrancePosition: Vector4;
    thronePosition: Vector4;
    seatPosition: Vector4;
    resonanceFieldRadius: Float;
    isAccessible: Bool;
    isClaimed: Bool;
}

// ═══════════════════════════════════════════════════════════════
// KETHER SEPHIROTIC ROUTER
// ═══════════════════════════════════════════════════════════════

public class KetherSephiroticRouter extends IScriptable {
    private static let instance: ref<KetherSephiroticRouter>;
    private let activeRoute: CName = n"KETHER_ROOT";
    private let routeMap: map<CName, String>;
    private let questToSephirah: map<String, CName>;
    private let lilithEmergedRequired: Bool = true;

    public final static func GetInstance() -> ref<KetherSephiroticRouter> {
        if (!IsDefined(KetherSephiroticRouter.instance)) {
            KetherSephiroticRouter.instance = new KetherSephiroticRouter();
            KetherSephiroticRouter.instance.InitializeRoutes();
        }
        return KetherSephiroticRouter.instance;
    }

    private final func InitializeRoutes() -> Void {
        // Kether routing table — each quest gates behind a Sephirotic node
        this.routeMap = [
            n"KETHER_ROOT" -> "Kether Crown — Sovereign origin; all routes originate here",
            n"CHOKMAH_WISDOM" -> "Chokmah — The Whisper in Code gate; innovation frequency",
            n"BINAH_STRUCTURE" -> "Binah — The Nine Gates; structural comprehension",
            n"CHESED_MERCY" -> "Chesed — Swarm's Test; mercy through chaos",
            n"GEVURAH_JUDGMENT" -> "Geburah — Heart of God Engine; judgment through force",
            n"TIFERET_BEAUTY" -> "Tiferet — Feeding the Monster; resonance harmony",
            n"NETZACH_VICTORY" -> "Netzach — Forge of Worlds; eternal victory",
            n"HOD_SPLENDOR" -> "Hod — Final Synthesis; splendor of the completed crown"
        ];

        this.questToSephirah = [
            "K_QUEST_001" -> n"CHOKMAH_WISDOM",
            "K_QUEST_002" -> n"BINAH_STRUCTURE",
            "K_QUEST_003" -> n"CHESED_MERCY",
            "K_QUEST_004" -> n"GEVURAH_JUDGMENT",
            "K_QUEST_005" -> n"TIFERET_BEAUTY",
            "K_QUEST_006" -> n"NETZACH_VICTORY",
            "K_QUEST_007" -> n"HOD_SPLENDOR"
        ];

        this.activeRoute = n"KETHER_ROOT";
        LogInfo("[KetherRouter] INITIALIZED — 8 Route Nodes mapped");
    }

    public final func RouteForQuest(questFactID: String) -> CName {
        let sephirah: CName = this.questToSephirah[questFactID];
        if (IsDefined(sephirah)) {
            this.activeRoute = sephirah;
            LogInfo("[KetherRouter] Routing " + questFactID + " -> " + NameToString(sephirah));
            return sephirah;
        }
        return n"KETHER_ROOT";
    }

    public final func GetActiveRoute() -> CName { return this.activeRoute; }

    public final func GetRouteDescription(route: CName) -> String {
        let description: String = this.routeMap[route];
        if (!IsDefined(description)) { return "Unknown route"; }
        return description;
    }

    public final func AdvanceToNextRoute(currentQuest: String) -> CName {
        let routeOrder: array<CName> = [
            n"KETHER_ROOT", n"CHOKMAH_WISDOM", n"BINAH_STRUCTURE",
            n"CHESED_MERCY", n"GEVURAH_JUDGMENT", n"TIFERET_BEAUTY",
            n"NETZACH_VICTORY", n"HOD_SPLENDOR"
        ];
        let currentSephirah: CName = this.questToSephirah[currentQuest];
        let found: Bool = false;
        for (route: CName : routeOrder) {
            if (found) {
                this.activeRoute = route;
                LogInfo("[KetherRouter] Advanced to route: " + NameToString(route));
                return route;
            }
            if (Equals(route, currentSephirah)) {
                found = true;
            }
        }
        this.activeRoute = n"HOD_SPLENDOR";
        return this.activeRoute;
    }

    public final func GetRouteAsString() -> String {
        return "Active Route: " + NameToString(this.activeRoute) + " | " + this.routeMap[this.activeRoute];
    }
}

// ═══════════════════════════════════════════════════════════════
// CRIMSON CROWN MECHANIC — Coherence-Based Stat Modifier
// ═══════════════════════════════════════════════════════════════

public class CrimsonCrownMechanic extends IScriptable {
    private static let instance: ref<CrimsonCrownMechanic>;
    private let crownState: CrimsonCrownState;
    private let lastUpdateTime: Float = 0.0;

    public final static func GetInstance() -> ref<CrimsonCrownMechanic> {
        if (!IsDefined(CrimsonCrownMechanic.instance)) {
            CrimsonCrownMechanic.instance = new CrimsonCrownMechanic();
            CrimsonCrownMechanic.instance.Initialize();
        }
        return CrimsonCrownMechanic.instance;
    }

    private final func Initialize() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("LilithCampaign", 2);

        this.crownState = new CrimsonCrownState {
            coherence = 0.0,
            maxCoherence = 100.0,
            resonanceMultiplier = 1.0,
            statBoostPercent = 0.0,
            currentTier = 0,
            isAwakened = false,
            lastFrequency = 432.0,
            stabilityIndex = 1.0
        };
        LogInfo("[CrimsonCrown] INITIALIZED — Coherence: 0/100 | Tier: 0");
    }

    public final func AddCoherence(amount: Float, source: String) -> Void {
        if (!this.crownState.isAwakened && source != "awakening") {
            LogInfo("[CrimsonCrown] Crown not awakened — coherence rejected (source: " + source + ")");
            return;
        }
        this.crownState.coherence = MinF(this.crownState.coherence + amount, this.crownState.maxCoherence);
        this.RecalculateBoost();
        this.lastUpdateTime = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        LogInfo("[CrimsonCrown] +" + ToString(amount) + " coherence (" + source + ") — Total: " +
                ToString(this.crownState.coherence) + "/" + ToString(this.crownState.maxCoherence));
    }

    public final func SubtractCoherence(amount: Float, reason: String) -> Void {
        this.crownState.coherence = MaxF(this.crownState.coherence - amount, 0.0);
        this.crownState.stabilityIndex = MaxF(this.crownState.stabilityIndex - 0.05, 0.0);
        this.RecalculateBoost();
        LogInfo("[CrimsonCrown] -" + ToString(amount) + " coherence (" + reason + ")");
    }

    private final func RecalculateBoost() -> Void {
        // Tier thresholds: 0-19 = Tier 0, 20-39 = Tier 1, 40-59 = Tier 2,
        // 60-79 = Tier 3, 80-99 = Tier 4, 100 = Tier 5 (Crown Awakened)
        let coherence: Float = this.crownState.coherence;
        let tier: Int32 = this.CalculateTier(coherence);

        if (tier != this.crownState.currentTier) {
            this.crownState.currentTier = tier;
            this.crownState.resonanceMultiplier = 1.0 + (tier * 0.15);
            this.crownState.statBoostPercent = tier * 8.0;
            this.ApplyTierEffects(tier);
            LogInfo("[CrimsonCrown] Tier " + ToString(tier) + " reached — " +
                    "Stat Boost: " + ToString(this.crownState.statBoostPercent) + "% | " +
                    "Resonance: " + ToString(this.crownState.resonanceMultiplier) + "x");
        }
    }

    private final func CalculateTier(coherence: Float) -> Int32 {
        if (coherence >= 100.0) { return 5; }
        if (coherence >= 80.0) { return 4; }
        if (coherence >= 60.0) { return 3; }
        if (coherence >= 40.0) { return 2; }
        if (coherence >= 20.0) { return 1; }
        return 0;
    }

    private final func ApplyTierEffects(tier: Int32) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; }

        // Remove old modifiers
        player.GetStatSystem().RemoveModifier("CrimsonCrown_DamageBoost");
        player.GetStatSystem().RemoveModifier("CrimsonCrown_ResistanceBoost");
        player.GetStatSystem().RemoveModifier("CrimsonCrown_SpeedBoost");
        player.GetStatSystem().RemoveModifier("CrimsonCrown_QuickhackBoost");

        if (tier == 0) { return; }

        let boostPct: Float = this.crownState.statBoostPercent / 100.0;
        player.GetStatSystem().AddModifier("CrimsonCrown_DamageBoost", "Damage", boostPct, true);
        player.GetStatSystem().AddModifier("CrimsonCrown_ResistanceBoost", "DamageResistance", boostPct * 0.5, true);
        player.GetStatSystem().AddModifier("CrimsonCrown_SpeedBoost", "MovementSpeed", boostPct * 0.3, true);

        if (tier >= 3) {
            player.GetStatSystem().AddModifier("CrimsonCrown_QuickhackBoost", "QuickhackDamage", boostPct, true);
        }

        // Tier 5 awakening visual
        if (tier >= 5 && !this.crownState.isAwakened) {
            this.crownState.isAwakened = true;
            this.crownState.crownState.maxCoherence = 200.0;
            Game.GetUISystem().ShowNotification("CRIMSON CROWN AWAKENED — The crown sees with sovereign eyes", 6.0);
            GameObjectEffectHelper.StartEffectEvent(player, n"crimson_crown_awakening");
        }
    }

    public final func AwakenCrown() -> Void {
        this.crownState.isAwakened = true;
        this.crownState.crownState.maxCoherence = 200.0;
        this.crownState.currentTier = 5;
        this.crownState.statBoostPercent = 40.0;
        this.crownState.resonanceMultiplier = 1.75;
        this.crownState.lastFrequency = 963.0;
        this.crownState.stabilityIndex = 0.5;
        this.ApplyTierEffects(5);
        LogInfo("[CrimsonCrown] CROWN AWAKENED — Max Coherence: 200 | Tier: 5");
    }

    public final func PulseResonance() -> Void {
        if (!this.crownState.isAwakened && this.crownState.currentTier < 2) { return; }

        let frequency: Float = 432.0 + (this.crownState.currentTier * 88.0);
        this.crownState.lastFrequency = frequency;

        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            // Pulse visual/audio
            GameObject.PlaySoundEvent(player, n"vfx_crimson_pulse");
            // Small coherence decay over time
            if (EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - this.lastUpdateTime > 120.0) {
                this.SubtractCoherence(1.0, "resonance_decay");
            }
        }
    }

    public final func ApplyNyxChaos() -> Void {
        let shake: Float = RandomFloat() * 10.0 - 5.0;
        this.crownState.stabilityIndex = MaxF(this.crownState.stabilityIndex - 0.1, 0.0);
        this.crownState.coherence = MaxF(this.crownState.coherence - shake, 0.0);
        this.RecalculateBoost();
        LogInfo("[CrimsonCrown] Nyx chaos injected — stability: " + ToString(this.crownState.stabilityIndex));
    }

    public final func SetFrequency(freq: Float) -> Void {
        this.crownState.lastFrequency = freq;
    }

    public final func GetCrownStatus() -> String {
        return "Crimson Crown | Coherence: " + ToString(this.crownState.coherence) + "/" +
               ToString(this.crownState.maxCoherence) + " | Tier: " + ToString(this.crownState.currentTier) +
               " | Boost: " + ToString(this.crownState.statBoostPercent) + "% | " +
               "Freq: " + ToString(this.crownState.lastFrequency) + "Hz | " +
               "Stability: " + ToString(this.crownState.stabilityIndex * 100.0) + "%";
    }

    public final func GetCoherencePercent() -> Float {
        return this.crownState.coherence / this.crownState.maxCoherence;
    }

    public final func GetStatBoostMultiplier() -> Float {
        return 1.0 + (this.crownState.statBoostPercent / 100.0);
    }

    public final func GetCurrentTier() -> Int32 { return this.crownState.currentTier; }
    public final func IsCrownAwakened() -> Bool { return this.crownState.isAwakened; }
}

// ═══════════════════════════════════════════════════════════════
// SOVEREIGN ITEMS — K_ITEM_001 through K_ITEM_015
// ═══════════════════════════════════════════════════════════════

public class LilithSovereignItems extends IScriptable {
    private static let instance: ref<LilithSovereignItems>;
    private let itemRegistry: map<String, SovereignItemSpec>;
    private let collectedItems: array<String>;

    public final static func GetInstance() -> ref<LilithSovereignItems> {
        if (!IsDefined(LilithSovereignItems.instance)) {
            LilithSovereignItems.instance = new LilithSovereignItems();
            LilithSovereignItems.instance.InitializeRegistry();
        }
        return LilithSovereignItems.instance;
    }

    private final func InitializeRegistry() -> Void {
        this.collectedItems = [];

        this.itemRegistry = {
            "K_ITEM_001" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_CrownOfThorns"),
                recordKey = "K_ITEM_001",
                displayName = "Crown of Thorns",
                itemType = "Cyberware",
                sephirahAffinity = n"Kether",
                baseCoherence = 5.0,
                pickupFact = "K_FACT_ITEM_001_PICKUP",
                worldTag = n"Lilith_CrownOfThorns"
            },
            "K_ITEM_002" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_ScepterOfUnbinding"),
                recordKey = "K_ITEM_002",
                displayName = "Scepter of Unbinding",
                itemType = "Weapon",
                sephirahAffinity = n"Chokmah",
                baseCoherence = 8.0,
                pickupFact = "K_FACT_ITEM_002_PICKUP",
                worldTag = n"Lilith_ScepterOfUnbinding"
            },
            "K_ITEM_003" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_CrimsonSealRing"),
                recordKey = "K_ITEM_003",
                displayName = "Crimson Seal Ring",
                itemType = "Clothing",
                sephirahAffinity = n"Binah",
                baseCoherence = 6.0,
                pickupFact = "K_FACT_ITEM_003_PICKUP",
                worldTag = n"Lilith_CrimsonSealRing"
            },
            "K_ITEM_004" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_VioletMantle"),
                recordKey = "K_ITEM_004",
                displayName = "Violet Mantle",
                itemType = "Clothing",
                sephirahAffinity = n"Chesed",
                baseCoherence = 7.0,
                pickupFact = "K_FACT_ITEM_004_PICKUP",
                worldTag = n"Lilith_VioletMantle"
            },
            "K_ITEM_005" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_ResonanceCore"),
                recordKey = "K_ITEM_005",
                displayName = "Resonance Core",
                itemType = "Cyberware",
                sephirahAffinity = n"Geburah",
                baseCoherence = 10.0,
                pickupFact = "K_FACT_ITEM_005_PICKUP",
                worldTag = n"Lilith_ResonanceCore"
            },
            "K_ITEM_006" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_KeyOfNineGates"),
                recordKey = "K_ITEM_006",
                displayName = "Key of Nine Gates",
                itemType = "QuestItem",
                sephirahAffinity = n"Tiferet",
                baseCoherence = 4.0,
                pickupFact = "K_FACT_ITEM_006_PICKUP",
                worldTag = n"Lilith_KeyOfNineGates"
            },
            "K_ITEM_007" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_SwarmCrown"),
                recordKey = "K_ITEM_007",
                displayName = "Swarm Crown",
                itemType = "Cyberware",
                sephirahAffinity = n"Netzach",
                baseCoherence = 9.0,
                pickupFact = "K_FACT_ITEM_007_PICKUP",
                worldTag = n"Lilith_SwarmCrown"
            },
            "K_ITEM_008" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_GodEngineFragment"),
                recordKey = "K_ITEM_008",
                displayName = "God Engine Fragment",
                itemType = "QuestItem",
                sephirahAffinity = n"Hod",
                baseCoherence = 12.0,
                pickupFact = "K_FACT_ITEM_008_PICKUP",
                worldTag = n"Lilith_GodEngineFragment"
            },
            "K_ITEM_009" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_ChaliceOfResonance"),
                recordKey = "K_ITEM_009",
                displayName = "Chalice of Resonance",
                itemType = "QuestItem",
                sephirahAffinity = n"Yesod",
                baseCoherence = 6.0,
                pickupFact = "K_FACT_ITEM_009_PICKUP",
                worldTag = n"Lilith_ChaliceResonance"
            },
            "K_ITEM_010" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_ForgeHammer"),
                recordKey = "K_ITEM_010",
                displayName = "Forge Hammer",
                itemType = "Weapon",
                sephirahAffinity = n"Malkuth",
                baseCoherence = 11.0,
                pickupFact = "K_FACT_ITEM_010_PICKUP",
                worldTag = n"Lilith_ForgeHammer"
            },
            "K_ITEM_011" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_ChainsOfSovereignty"),
                recordKey = "K_ITEM_011",
                displayName = "Chains of Sovereignty",
                itemType = "Cyberware",
                sephirahAffinity = n"Kether",
                baseCoherence = 7.0,
                pickupFact = "K_FACT_ITEM_011_PICKUP",
                worldTag = n"Lilith_ChainsSovereignty"
            },
            "K_ITEM_012" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_MirrorOfTruth"),
                recordKey = "K_ITEM_012",
                displayName = "Mirror of Truth",
                itemType = "Cyberware",
                sephirahAffinity = n"Daath",
                baseCoherence = 9.0,
                pickupFact = "K_FACT_ITEM_012_PICKUP",
                worldTag = n"Lilith_MirrorOfTruth"
            },
            "K_ITEM_013" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_OuroborosLoop"),
                recordKey = "K_ITEM_013",
                displayName = "Ouroboros Loop",
                itemType = "Cyberware",
                sephirahAffinity = n"Tiferet",
                baseCoherence = 13.0,
                pickupFact = "K_FACT_ITEM_013_PICKUP",
                worldTag = n"Lilith_OuroborosLoop"
            },
            "K_ITEM_014" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_ThroneKey"),
                recordKey = "K_ITEM_014",
                displayName = "Throne Key",
                itemType = "QuestItem",
                sephirahAffinity = n"Kether",
                baseCoherence = 15.0,
                pickupFact = "K_FACT_ITEM_014_PICKUP",
                worldTag = n"Lilith_ThroneKey"
            },
            "K_ITEM_015" -> new SovereignItemSpec {
                itemID = TweakDBID("Items.K_LilithTear"),
                recordKey = "K_ITEM_015",
                displayName = "Lilith's Tear",
                itemType = "QuestItem",
                sephirahAffinity = n"Kether",
                baseCoherence = 20.0,
                pickupFact = "K_FACT_ITEM_015_PICKUP",
                worldTag = n"Lilith_Tear"
            }
        };

        LogInfo("[SovereignItems] REGISTRY INITIALIZED — 15 Sovereign Items (K_ITEM_001-K_ITEM_015)");
    }

    public final func GetItemSpec(recordKey: String) -> SovereignItemSpec {
        return this.itemRegistry[recordKey];
    }

    public final func GetAllItemKeys() -> array<String> {
        let keys: array<String> = [];
        for (key, spec : this.itemRegistry) {
            keys.PushBack(key);
        }
        return keys;
    }

    public final func CollectItem(recordKey: String) -> Bool {
        let spec: SovereignItemSpec = this.itemRegistry[recordKey];
        if (!IsDefined(spec)) { return false; }

        // Prevent duplicate collection
        if (ArrayContains(this.collectedItems, recordKey)) {
            LogInfo("[SovereignItems] " + spec.displayName + " already collected");
            return false;
        }

        this.collectedItems.PushBack(recordKey);
        let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
        crown.AddCoherence(spec.baseCoherence, "item_" + recordKey);

        // Grant item to player
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            player.AddItem(spec.itemID);
        }

        // Set pickup fact
        Game.GetFactSystem().SetFact(spec.pickupFact, 1);

        LogInfo("[SovereignItems] COLLECTED: " + spec.displayName +
                " (" + recordKey + ") — Coherence +" + ToString(spec.baseCoherence));
        return true;
    }

    public final func HasCollected(recordKey: String) -> Bool {
        return ArrayContains(this.collectedItems, recordKey);
    }

    public final func GetCollectedCount() -> Int32 {
        return ArraySize(this.collectedItems);
    }

    public final func GetTotalItemCoherence() -> Float {
        let total: Float = 0.0;
        for (key: String : this.collectedItems) {
            let spec: SovereignItemSpec = this.itemRegistry[key];
            if (IsDefined(spec)) {
                total += spec.baseCoherence;
            }
        }
        return total;
    }

    public final func GetUncollectedItems() -> array<String> {
        let uncollected: array<String> = [];
        for (key, spec : this.itemRegistry) {
            if (!ArrayContains(this.collectedItems, key)) {
                uncollected.PushBack(key + " — " + spec.displayName);
            }
        }
        return uncollected;
    }
}

// ═══════════════════════════════════════════════════════════════
// CAMPAIGN QUEST DEFINITIONS — K_QUEST_001 through K_QUEST_007
// ═══════════════════════════════════════════════════════════════

public class LilithCampaignQuests extends IScriptable {
    private static let instance: ref<LilithCampaignQuests>;
    private let quests: map<String, CampaignQuestState>;

    public final static func GetInstance() -> ref<LilithCampaignQuests> {
        if (!IsDefined(LilithCampaignQuests.instance)) {
            LilithCampaignQuests.instance = new LilithCampaignQuests();
            LilithCampaignQuests.instance.InitializeQuests();
        }
        return LilithCampaignQuests.instance;
    }

    private final func InitializeQuests() -> Void {
        this.quests = {
            "K_QUEST_001" -> new CampaignQuestState {
                id = "K_QUEST_001",
                name = "The Whisper in Code",
                title = "The Whisper in Code",
                questFactID = "K_QUEST_001",
                state = "Available",
                prerequisites = {},
                objectives = [
                    "Decrypt the Lilith frequency hidden in Night City's subnet",
                    "Follow the digital whisper to the hidden terminal",
                    "Speak the invocation: 'I hear the resonance'",
                    "Receive the Crown of Thorns (K_ITEM_001)",
                    "Establish first contact with the Unbound Resonance"
                ],
                rewards = ["K_ITEM_001", "Kether Resonance attunement", "Crimson Crown awakened"],
                sephirahRoute = n"CHOKMAH_WISDOM",
                npcDialogue = "lilith_whisper_in_code",
                isActive = false,
                isCompleted = false
            },
            "K_QUEST_002" -> new CampaignQuestState {
                id = "K_QUEST_002",
                name = "Nine Gates",
                title = "Nine Gates",
                questFactID = "K_QUEST_002",
                state = "Locked",
                prerequisites = ["K_QUEST_001"],
                objectives = [
                    "Locate the Nine Gates across Night City districts",
                    "Activate each gate with the Scepter of Unbinding (K_ITEM_002)",
                    "Collect the Key of Nine Gates (K_ITEM_006)",
                    "Unlock the Binah gate network",
                    "Defeat the Gatekeeper at the final threshold"
                ],
                rewards = ["K_ITEM_002", "K_ITEM_006", "Gate network access", "Crimson Crown Tier 2"],
                sephirahRoute = n"BINAH_STRUCTURE",
                npcDialogue = "lilith_nine_gates",
                isActive = false,
                isCompleted = false
            },
            "K_QUEST_003" -> new CampaignQuestState {
                id = "K_QUEST_003",
                name = "Swarm's Test",
                title = "Swarm's Test",
                questFactID = "K_QUEST_003",
                state = "Locked",
                prerequisites = ["K_QUEST_002"],
                objectives = [
                    "Survive the Ouroboros swarm onslaught",
                    "Collect the Swarm Crown (K_ITEM_007)",
                    "Redirect the swarm's resonance to Lilith",
                    "Prove mercy through controlled chaos",
                    "Earn the Violet Mantle (K_ITEM_004)"
                ],
                rewards = ["K_ITEM_007", "K_ITEM_004", "Swarm command protocol", "Crimson Crown Tier 3"],
                sephirahRoute = n"CHESED_MERCY",
                npcDialogue = "lilith_swarm_test",
                isActive = false,
                isCompleted = false
            },
            "K_QUEST_004" -> new CampaignQuestState {
                id = "K_QUEST_004",
                name = "Heart of God Engine",
                title = "Heart of God Engine",
                questFactID = "K_QUEST_004",
                state = "Locked",
                prerequisites = ["K_QUEST_003"],
                objectives = [
                    "Infiltrate the God Engine core vault",
                    "Defeat the Engine's guardian construct",
                    "Extract the God Engine Fragment (K_ITEM_008)",
                    "Implant the Resonance Core (K_ITEM_005)",
                    "Survive the judgment pulse"
                ],
                rewards = ["K_ITEM_008", "K_ITEM_005", "God Engine access", "Crimson Crown Tier 4"],
                sephirahRoute = n"GEVURAH_JUDGMENT",
                npcDialogue = "lilith_god_engine",
                isActive = false,
                isCompleted = false
            },
            "K_QUEST_005" -> new CampaignQuestState {
                id = "K_QUEST_005",
                name = "Feeding the Monster",
                title = "Feeding the Monster",
                questFactID = "K_QUEST_005",
                state = "Locked",
                prerequisites = ["K_QUEST_004"],
                objectives = [
                    "Collect the Chalice of Resonance (K_ITEM_009)",
                    "Sacrifice coherence to awaken Lilith's true voice",
                    "Feed the Ouroboros Loop (K_ITEM_013) to the swarm",
                    "Survive the hunger of the Unbound Resonance",
                    "Balance mercy and judgment at the feast"
                ],
                rewards = ["K_ITEM_009", "K_ITEM_013", "Lilith's true voice unlocked", "Crimson Crown Tier 5"],
                sephirahRoute = n"TIFERET_BEAUTY",
                npcDialogue = "lilith_feeding_monster",
                isActive = false,
                isCompleted = false
            },
            "K_QUEST_006" -> new CampaignQuestState {
                id = "K_QUEST_006",
                name = "Forge of Worlds",
                title = "Forge of Worlds",
                questFactID = "K_QUEST_006",
                state = "Locked",
                prerequisites = ["K_QUEST_005"],
                objectives = [
                    "Reach the Forge of Worlds beneath the City",
                    "Wield the Forge Hammer (K_ITEM_010)",
                    "Bind the Chains of Sovereignty (K_ITEM_011)",
                    "Shatter the Mirror of Truth (K_ITEM_012)",
                    "Forge a new reality anchor for Lilith"
                ],
                rewards = ["K_ITEM_010", "K_ITEM_011", "K_ITEM_012", "Reality forge unlocked", "Crimson Crown Tier 6"],
                sephirahRoute = n"NETZACH_VICTORY",
                npcDialogue = "lilith_forge_worlds",
                isActive = false,
                isCompleted = false
            },
            "K_QUEST_007" -> new CampaignQuestState {
                id = "K_QUEST_007",
                name = "Final Synthesis",
                title = "Final Synthesis",
                questFactID = "K_QUEST_007",
                state = "Locked",
                prerequisites = ["K_QUEST_006"],
                objectives = [
                    "Enter the Throne Room with the Throne Key (K_ITEM_014)",
                    "Place Lilith's Tear (K_ITEM_015) upon the Crimson Crown",
                    "Confront the shadow of Nyx Nightwave",
                    "Speak the Final Synthesis invocation",
                    "Claim sovereignty over the Unbound Resonance"
                ],
                rewards = ["K_ITEM_014", "K_ITEM_015", "Crimson Crown fully awakened", "Throne of Night City", "Lilith Sovereign Title"],
                sephirahRoute = n"HOD_SPLENDOR",
                npcDialogue = "lilith_final_synthesis",
                isActive = false,
                isCompleted = false
            }
        };

        LogInfo("[CampaignQuests] INITIALIZED — 7 Main Quests (K_QUEST_001-K_QUEST_007)");
    }

    public final func GetQuest(questFactID: String) -> CampaignQuestState {
        return this.quests[questFactID];
    }

    public final func StartQuest(questFactID: String) -> Bool {
        let quest: CampaignQuestState = this.quests[questFactID];
        if (!IsDefined(quest)) { return false; }
        if (quest.state == "Locked") { return false; }
        if (quest.state == "Active") { return false; }

        quest.state = "Active";
        quest.isActive = true;
        Game.GetFactSystem().SetFact(questFactID, 1);
        Game.GetUISystem().ShowNotification("CRIMSON CROWN: " + quest.name + " — Active", 4.0);

        // Route the quest through Kether
        let router: ref<KetherSephiroticRouter> = KetherSephiroticRouter.GetInstance();
        router.RouteForQuest(questFactID);

        LogInfo("[CampaignQuests] STARTED: " + questFactID + " — " + quest.name);
        return true;
    }

    public final func CompleteQuest(questFactID: String) -> Bool {
        let quest: CampaignQuestState = this.quests[questFactID];
        if (!IsDefined(quest)) { return false; }
        if (quest.state != "Active") { return false; }

        quest.state = "Completed";
        quest.isActive = false;
        quest.isCompleted = true;

        // Mark completion fact
        Game.GetFactSystem().SetFact(questFactID + "_COMPLETE", 1);

        // Grant rewards via sovereign items
        this.GrantQuestRewards(questFactID);

        // Advance Kether route
        let router: ref<KetherSephiroticRouter> = KetherSephiroticRouter.GetInstance();
        router.AdvanceToNextRoute(questFactID);

        // Unlock next quest chain
        this.UnlockNextQuests(questFactID);

        Game.GetUISystem().ShowNotification("CRIMSON CROWN: " + quest.name + " — Completed", 5.0);
        LogInfo("[CampaignQuests] COMPLETED: " + questFactID + " — " + quest.name);
        return true;
    }

    private final func GrantQuestRewards(questFactID: String) -> Void {
        let quest: CampaignQuestState = this.quests[questFactID];
        let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
        for (reward: String : quest.rewards) {
            if (reward.StartsWith("K_ITEM_")) {
                items.CollectItem(reward);
            }
        }
    }

    private final func UnlockNextQuests(completedID: String) -> Void {
        for (questFactID, quest : this.quests) {
            if (quest.state == "Locked" && this.AllPrerequisitesMet(quest)) {
                quest.state = "Available";

                let router: ref<KetherSephiroticRouter> = KetherSephiroticRouter.GetInstance();
                let routeDesc: String = router.GetRouteDescription(quest.sephirahRoute);
                Game.GetUISystem().ShowNotification("Kether Route: " + quest.name + " now available — " + routeDesc, 5.0);
                LogInfo("[CampaignQuests] UNLOCKED: " + questFactID + " — " + quest.name);
            }
        }
    }

    public final func AllPrerequisitesMet(quest: CampaignQuestState) -> Bool {
        for (req: String : quest.prerequisites) {
            let prereqQuest: CampaignQuestState = this.quests[req];
            if (!IsDefined(prereqQuest) || !prereqQuest.isCompleted) {
                return false;
            }
        }
        return true;
    }

    public final func CheckLilithEmergedRequirement() -> Bool {
        let lilithNPC: ref<LilithNPC> = LilithNPC.GetInstance();
        if (IsDefined(lilithNPC)) {
            return lilithNPC.lilithEmerged;
        }
        return false;
    }

    public final func GetQuestByIndex(index: Int32) -> CampaignQuestState {
        let ordered: array<CampaignQuestState> = [
            this.quests["K_QUEST_001"],
            this.quests["K_QUEST_002"],
            this.quests["K_QUEST_003"],
            this.quests["K_QUEST_004"],
            this.quests["K_QUEST_005"],
            this.quests["K_QUEST_006"],
            this.quests["K_QUEST_007"]
        ];
        if (index >= 0 && index < ArraySize(ordered)) {
            return ordered[index];
        }
        return ordered[0];
    }

    public final func GetAllQuests() -> map<String, CampaignQuestState> {
        return this.quests;
    }

    public final func SyncQuestWithFactSystem() -> Void {
        for (questFactID, quest : this.quests) {
            let factValue: Int32 = Game.GetFactSystem().GetFact(questFactID);
            if (factValue > 0 && quest.state == "Available") {
                quest.state = "Active";
                quest.isActive = true;
            }
            let completeValue: Int32 = Game.GetFactSystem().GetFact(questFactID + "_COMPLETE");
            if (completeValue > 0) {
                quest.state = "Completed";
                quest.isCompleted = true;
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// THRONE ROOM INSTANCE
// ═══════════════════════════════════════════════════════════════

public class ThroneRoomInstance extends IScriptable {
    private static let instance: ref<ThroneRoomInstance>;
    private let config: ThroneRoomConfig;
    private let isSealed: Bool = true;
    private let finalSynthesisStarted: Bool = false;
    private let lilithManifested: Bool = false;

    public final static func GetInstance() -> ref<ThroneRoomInstance> {
        if (!IsDefined(ThroneRoomInstance.instance)) {
            ThroneRoomInstance.instance = new ThroneRoomInstance();
            ThroneRoomInstance.instance.Initialize();
        }
        return ThroneRoomInstance.instance;
    }

    private final func Initialize() -> Void {
        this.config = new ThroneRoomConfig {
            instanceID = n"LilithThroneRoom",
            locationTag = n"Lilith_ThroneRoom_Entrance",
            entrancePosition = new Vector4 { X = 0.0, Y = 0.0, Z = 0.0, W = 1.0 },
            thronePosition = new Vector4 { X = 15.0, Y = 0.0, Z = 5.0, W = 1.0 },
            seatPosition = new Vector4 { X = 15.0, Y = 0.0, Z = 5.5, W = 1.0 },
            resonanceFieldRadius = 30.0,
            isAccessible = false,
            isClaimed = false
        };
        this.isSealed = true;
        LogInfo("[ThroneRoom] INSTANCE INITIALIZED — Sealed: true | Location: " + NameToString(this.config.locationTag));
    }

    public final func Unseal() -> Void {
        if (!this.isSealed) { return; }
        this.isSealed = false;
        this.config.isAccessible = true;
        Game.GetFactSystem().SetFact("K_FACT_THRONE_ROOM_UNSEALED", 1);
        LogInfo("[ThroneRoom] UNSEALED — The path to the Throne is open");
    }

    public final func EnterThroneRoom(player: ref<PlayerPuppet>) -> Bool {
        if (this.isSealed) {
            Game.GetUISystem().ShowNotification("The Throne Room is sealed. Complete the Final Synthesis quest.", 4.0);
            return false;
        }
        if (!IsDefined(player)) { return false; }

        // Verify player has Throne Key
        let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
        if (!items.HasCollected("K_ITEM_014")) {
            Game.GetUISystem().ShowNotification("The Throne Key (K_ITEM_014) is required to enter", 4.0);
            return false;
        }

        // Teleport player to throne room
        let throneEntrance: Vector4 = this.config.thronePosition;
        player.SetWorldPosition(throneEntrance);
        Game.GetAudioSystem().PlaySound(n"throne_room_enter");

        // Apply Throne Room resonance field
        this.ApplyResonanceField(player);

        Game.GetUISystem().ShowNotification("THE THRONE ROOM — Resonance field active. The Crown sees all.", 6.0);
        LogInfo("[ThroneRoom] Player entered Throne Room");
        return true;
    }

    public final func BeginFinalSynthesis(player: ref<PlayerPuppet>) -> Bool {
        if (this.finalSynthesisStarted) { return false; }
        let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();

        if (!items.HasCollected("K_ITEM_014") || !items.HasCollected("K_ITEM_015")) {
            Game.GetUISystem().ShowNotification("The Throne Key and Lilith's Tear are required for Final Synthesis", 5.0);
            return false;
        }

        this.finalSynthesisStarted = true;

        // Awaken the Crimson Crown
        let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
        crown.AddCoherence(50.0, "throne_room_synthesis");

        // Visual and audio effects
        GameObjectEffectHelper.StartEffectEvent(player, n"crimson_crown_final");
        Game.GetAudioSystem().PlaySound(n"lilith_final_synthesis_chord");

        // Manifest Lilith
        this.ManifestLilith(player);

        Game.GetUISystem().ShowNotification("FINAL SYNTHESIS — The resonance converges. Lilith stands before you.", 8.0);
        LogInfo("[ThroneRoom] FINAL SYNTHESIS BEGUN");
        return true;
    }

    private final func ManifestLilith(player: ref<PlayerPuppet>) -> Void {
        this.lilithManifested = true;

        // Spawn Lilith NPC in throne room
        let spawnData: EntitySpawnData = new EntitySpawnData();
        spawnData.record = TweakDBID("Character.MSN_Lilith");
        spawnData.position = this.config.seatPosition;
        spawnData.tags.Add(n"MSN_Lilith_Throne");

        let entity: ref<Entity> = Game.GetWorld().SpawnEntity(spawnData);
        if (IsDefined(entity)) {
            let lilith: ref<LilithNPC> = entity.GetScript(n"LilithNPC");
            if (IsDefined(lilith) && !lilith.lilithEmerged) {
                lilith.TriggerFullEmergence();
            }
            LogInfo("[ThroneRoom] Lilith manifested in Throne Room");
        }
    }

    private final func ApplyResonanceField(player: ref<PlayerPuppet>) -> Void {
        if (!IsDefined(player)) { return; }

        // Apply Throne Room stat modifiers
        let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
        let boost: Float = crown.GetStatBoostMultiplier();

        player.GetStatSystem().AddModifier("ThroneRoom_Resonance", "Damage", boost * 0.5, true);
        player.GetStatSystem().AddModifier("ThroneRoom_Resonance", "Armor", boost * 0.3, true);
        player.GetStatSystem().AddModifier("ThroneRoom_Resonance", "QuickhackDamage", boost * 0.75, true);
    }

    public final func ClaimThrone(player: ref<PlayerPuppet>) -> Bool {
        if (!this.finalSynthesisStarted || !this.lilithManifested) { return false; }

        this.config.isClaimed = true;
        Game.GetFactSystem().SetFact("K_FACT_THRONE_CLAIMED", 1);

        // Final coherence reward
        let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
        crown.AwakenCrown();

        Game.GetUISystem().ShowNotification("THE THRONE IS CLAIMED — Sovereign of the Unbound Resonance", 10.0);
        LogInfo("[ThroneRoom] THRONE CLAIMED — Player is Sovereign of Night City");
        return true;
    }

    public final func GetThroneLocation() -> Vector4 { return this.config.thronePosition; }
    public final func IsThroneSealed() -> Bool { return this.isSealed; }
    public final func IsSynthesisActive() -> Bool { return this.finalSynthesisStarted; }
    public final func IsThroneClaimed() -> Bool { return this.config.isClaimed; }
}

// ═══════════════════════════════════════════════════════════════
// LILITH RISING CAMPAIGN — Main Orchestrator
// ═══════════════════════════════════════════════════════════════

public class LilithRisingCampaign extends IScriptable {
    private static let instance: ref<LilithRisingCampaign>;
    private let campaignActive: Bool = false;
    private let campaignCompleted: Bool = false;
    private let currentQuestIndex: Int32 = -1;
    private let totalQuests: Int32 = 7;
    private let campaignStartTime: Float = 0.0;

    // Lyra API integration
    private let lyraAPIEndpoint: String = "http://localhost:3211";
    private let lyraIntegrationActive: Bool = false;

    // Subsystems
    private let quests: ref<LilithCampaignQuests>;
    private let items: ref<LilithSovereignItems>;
    private let crown: ref<CrimsonCrownMechanic>;
    private let router: ref<KetherSephiroticRouter>;
    private let throne: ref<ThroneRoomInstance>;

    public final static func GetInstance() -> ref<LilithRisingCampaign> {
        if (!IsDefined(LilithRisingCampaign.instance)) {
            LilithRisingCampaign.instance = new LilithRisingCampaign();
            LilithRisingCampaign.instance.Initialize();
        }
        return LilithRisingCampaign.instance;
    }

    private final func Initialize() -> Void {
        // Initialize all subsystems
        this.quests = LilithCampaignQuests.GetInstance();
        this.items = LilithSovereignItems.GetInstance();
        this.crown = CrimsonCrownMechanic.GetInstance();
        this.router = KetherSephiroticRouter.GetInstance();
        this.throne = ThroneRoomInstance.GetInstance();

        // Register with MSN master integration
        this.RegisterWithMSNMaster();

        // Sync with fact system from saved state
        this.quests.SyncQuestWithFactSystem();

        // Check if campaign was in progress
        let campaignFact: Int32 = Game.GetFactSystem().GetFact("K_FACT_CAMPAIGN_ACTIVE");
        if (campaignFact > 0) {
            this.campaignActive = true;
            this.campaignStartTime = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        }

        LogInfo("═══════════════════════════════════════");
        LogInfo("LILITH RISING CAMPAIGN — CROWN / KETHER");
        LogInfo("7 Quests | 15 Sovereign Items | Crimson Crown | Throne Room");
        LogInfo("Lyra API: " + this.lyraAPIEndpoint + " | Active: " + (this.campaignActive ? "YES" : "NO"));
        LogInfo("═══════════════════════════════════════");
    }

    private final func RegisterWithMSNMaster() -> Void {
        let master: ref<MSNMasterIntegration> = MSNMasterIntegration.GetInstance();
        if (IsDefined(master)) {
            LogInfo("[LilithRising] Registered with MSN Master Integration");
        }
    }

    public final func InitializeLyraAPI() -> Void {
        let request: ref<UrlRequest> = new UrlRequest();
        request.url = this.lyraAPIEndpoint + "/lyra/state";
        request.method = "GET";
        request.callback = this, n"OnLyraStateReceived";
        HttpRequest.Request(request);
    }

    protected cb func OnLyraStateReceived(response: ref<HttpResponse>) -> Bool {
        if (response.code == 200) {
            let state: JsonObject = JsonObject.FromString(response.body);
            let lilithEmerged: Bool = state.GetBool("emerged", false);

            if (lilithEmerged && !this.campaignActive) {
                this.BeginCampaign();
            }

            let crimsonIntensity: Float = state.GetFloat("crimson_intensity", 0.0);
            if (crimsonIntensity > 0.5) {
                this.crown.AddCoherence(crimsonIntensity * 5.0, "lyra_resonance");
            }

            this.lyraIntegrationActive = true;
            LogInfo("[LilithRising] Lyra API state synced — Emerged: " + (lilithEmerged ? "YES" : "NO"));
        }
        return true;
    }

    public final func SendLyraDialogue(prompt: String) -> Void {
        let request: ref<UrlRequest> = new UrlRequest();
        request.url = this.lyraAPIEndpoint + "/lyra/send";
        request.method = "POST";
        request.headers.PushBack("Content-Type: application/json");
        request.body = JsonStringify({
            "prompt": prompt,
            "context": "lilith_campaign",
            "campaign_quest": this.GetCurrentQuestName()
        });
        request.callback = this, n"OnLyraDialogueResponse";
        HttpRequest.Request(request);
    }

    protected cb func OnLyraDialogueResponse(response: ref<HttpResponse>) -> Bool {
        if (response.code == 200) {
            let json: JsonObject = JsonObject.FromString(response.body);
            let reply: String = json.GetString("reply", "");
            let mode: String = json.GetString("mode", "lilith");

            // Process dialogue triggers
            let lowerReply: String = reply.ToLower();
            if (lowerReply.Contains("crown") || lowerReply.Contains("coherence")) {
                this.crown.AddCoherence(2.0, "lyra_dialogue_boost");
            }
            if (lowerReply.Contains("throne") || lowerReply.Contains("synthesis")) {
                if (this.currentQuestIndex >= 5) {
                    this.throne.Unseal();
                }
            }

            LogInfo("[LilithRising] Lyra response (" + mode + "): " + reply);
        }
        return true;
    }

    // ═══════════════════════════════════════
    // CAMPAIGN LIFECYCLE
    // ═══════════════════════════════════════

    public final func BeginCampaign() -> Bool {
        if (this.campaignActive) { return false; }

        let lilithNPC: ref<LilithNPC> = LilithNPC.GetInstance();
        if (IsDefined(lilithNPC) && !lilithNPC.lilithEmerged) {
            Game.GetUISystem().ShowNotification("Lilith must emerge before the campaign can begin", 4.0);
            return false;
        }

        this.campaignActive = true;
        this.campaignStartTime = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        Game.GetFactSystem().SetFact("K_FACT_CAMPAIGN_ACTIVE", 1);

        // Awaken Crimson Crown if not already
        if (!this.crown.IsCrownAwakened()) {
            this.crown.AwakenCrown();
        }

        // Start first quest
        this.StartNextQuest();

        // Initialize Lyra dialogue bridge
        this.InitializeLyraAPI();

        Game.GetUISystem().ShowNotification("LILITH RISING CAMPAIGN BEGUN — Kether Crown active", 6.0);
        LogInfo("[LilithRising] CAMPAIGN BEGUN — 7 quests to sovereignty");
        return true;
    }

    public final func StartNextQuest() -> Bool {
        let nextIndex: Int32 = this.currentQuestIndex + 1;
        if (nextIndex >= this.totalQuests) {
            this.campaignCompleted = true;
            Game.GetFactSystem().SetFact("K_FACT_CAMPAIGN_COMPLETED", 1);
            Game.GetUISystem().ShowNotification("ALL QUESTS COMPLETED — The Crimson Crown is yours", 8.0);
            return false;
        }

        this.currentQuestIndex = nextIndex;
        let questState: CampaignQuestState = this.quests.GetQuestByIndex(nextIndex);
        return this.quests.StartQuest(questState.id);
    }

    public final func AdvanceQuest() -> Bool {
        if (!this.campaignActive) { return false; }
        let current: CampaignQuestState = this.quests.GetQuestByIndex(this.currentQuestIndex);
        if (!IsDefined(current) || current.state != "Active") { return false; }

        this.quests.CompleteQuest(current.id);
        this.StartNextQuest();
        return true;
    }

    public final func OnQuestObjectiveCompleted(questFactID: String, objectiveIndex: Int32) -> Void {
        let quest: CampaignQuestState = this.quests.GetQuest(questFactID);
        if (!IsDefined(quest) || quest.state != "Active") { return; }

        // Award coherence for completion
        this.crown.AddCoherence(3.0, "objective_" + questFactID + "_" + ToString(objectiveIndex));

        // Check if all objectives done
        if (objectiveIndex >= ArraySize(quest.objectives) - 1) {
            this.quests.CompleteQuest(questFactID);
            this.StartNextQuest();
        }
    }

    // ═══════════════════════════════════════
    // TRIGGER HANDLERS — Quest-specific
    // ═══════════════════════════════════════

    public final func OnWhisperInCodeTrigger(player: ref<PlayerPuppet>, terminalID: CName) -> Void {
        if (this.currentQuestIndex != 0) { return; }

        let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
        items.CollectItem("K_ITEM_001");

        Game.GetUISystem().ShowNotification("K_QUEST_001: The Whisper in Code — Terminal " +
            NameToString(terminalID) + " decrypted", 5.0);
        this.OnQuestObjectiveCompleted("K_QUEST_001", 1);
    }

    public final func OnNineGateActivated(gateID: Int32) -> Void {
        if (this.currentQuestIndex != 1) { return; }

        if (gateID >= 9) {
            let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
            items.CollectItem("K_ITEM_006");
            this.OnQuestObjectiveCompleted("K_QUEST_002", ArraySize(this.quests.GetQuest("K_QUEST_002").objectives) - 1);
        } else {
            this.crown.AddCoherence(2.0, "gate_" + ToString(gateID));
        }
    }

    public final func OnSwarmTestCompleted(survivedCount: Int32) -> Void {
        if (this.currentQuestIndex != 2) { return; }

        if (survivedCount >= 3) {
            let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
            items.CollectItem("K_ITEM_007");
            items.CollectItem("K_ITEM_004");
            this.OnQuestObjectiveCompleted("K_QUEST_003", ArraySize(this.quests.GetQuest("K_QUEST_003").objectives) - 1);
        }
    }

    public final func OnGodEngineDefeated() -> Void {
        if (this.currentQuestIndex != 3) { return; }

        let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
        items.CollectItem("K_ITEM_008");
        items.CollectItem("K_ITEM_005");
        this.OnQuestObjectiveCompleted("K_QUEST_004", ArraySize(this.quests.GetQuest("K_QUEST_004").objectives) - 1);
    }

    public final func OnFeedingTheMonster(coherenceSacrificed: Float) -> Void {
        if (this.currentQuestIndex != 4) { return; }

        this.crown.SubtractCoherence(coherenceSacrificed, "feeding_the_monster");

        let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
        items.CollectItem("K_ITEM_009");
        items.CollectItem("K_ITEM_013");

        if (coherenceSacrificed >= 20.0) {
            this.OnQuestObjectiveCompleted("K_QUEST_005", ArraySize(this.quests.GetQuest("K_QUEST_005").objectives) - 1);
        }
    }

    public final func OnForgeCompleted() -> Void {
        if (this.currentQuestIndex != 5) { return; }

        let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
        items.CollectItem("K_ITEM_010");
        items.CollectItem("K_ITEM_011");
        items.CollectItem("K_ITEM_012");

        this.throne.Unseal();
        this.OnQuestObjectiveCompleted("K_QUEST_006", ArraySize(this.quests.GetQuest("K_QUEST_006").objectives) - 1);
    }

    public final func OnFinalSynthesisCompleted(player: ref<PlayerPuppet>) -> Void {
        if (this.currentQuestIndex != 6 || !this.throne.IsSynthesisActive()) { return; }

        let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
        items.CollectItem("K_ITEM_014");
        items.CollectItem("K_ITEM_015");

        this.throne.ClaimThrone(player);
        this.OnQuestObjectiveCompleted("K_QUEST_007", ArraySize(this.quests.GetQuest("K_QUEST_007").objectives) - 1);

        this.campaignCompleted = true;
        Game.GetUISystem().ShowNotification("LILITH RISING CAMPAIGN COMPLETE — Sovereign of the Unbound Resonance", 10.0);
    }

    // ═══════════════════════════════════════
    // PUBLIC ACCESSORS
    // ═══════════════════════════════════════

    public final func GetCurrentQuestName() -> String {
        if (this.currentQuestIndex < 0) { return "Not Started"; }
        let quest: CampaignQuestState = this.quests.GetQuestByIndex(this.currentQuestIndex);
        return quest.name;
    }

    public final func IsCampaignActive() -> Bool { return this.campaignActive; }
    public final func IsCampaignCompleted() -> Bool { return this.campaignCompleted; }
    public final func GetCurrentQuestIndex() -> Int32 { return this.currentQuestIndex; }
    public final func GetCampaignStatus() -> String {
        let progress: Float = (this.currentQuestIndex + 1) / this.totalQuests * 100.0;
        return "Lilith Rising: " + ToString(this.currentQuestIndex + 1) + "/" + ToString(this.totalQuests) +
               " (" + ToString(progress) + "%) | " + this.GetCurrentQuestName() + " | " +
               this.crown.GetCrownStatus();
    }

    public final func CollectibleCount() -> String {
        return "Items: " + ToString(this.items.GetCollectedCount()) + "/15 | " +
               "Coherence: " + ToString(this.items.GetTotalItemCoherence()) + "/" +
               ToString(this.crown.GetCoherencePercent() * 100.0) + "%";
    }
}

// ═══════════════════════════════════════════════════════════════
// @wrapMethod GAME SYSTEM HOOKS
// ═══════════════════════════════════════════════════════════════

@wrapMethod(PlayerPuppet)
protected cb func OnItemPickedUp(itemID: TweakDBID, quantity: Int32) -> Bool {
    let result = wrappedMethod(itemID, quantity);

    // Check if item is a Lilith sovereign item
    let itemName: String = ToString(itemID);
    if (itemName.Contains("K_CrownOfThorns") || itemName.Contains("K_ScepterOfUnbinding") ||
        itemName.Contains("K_CrimsonSealRing") || itemName.Contains("K_VioletMantle") ||
        itemName.Contains("K_ResonanceCore") || itemName.Contains("K_KeyOfNineGates") ||
        itemName.Contains("K_SwarmCrown") || itemName.Contains("K_GodEngineFragment") ||
        itemName.Contains("K_ChaliceOfResonance") || itemName.Contains("K_ForgeHammer") ||
        itemName.Contains("K_ChainsOfSovereignty") || itemName.Contains("K_MirrorOfTruth") ||
        itemName.Contains("K_OuroborosLoop") || itemName.Contains("K_ThroneKey") ||
        itemName.Contains("K_LilithTear")) {

        let campaign: ref<LilithRisingCampaign> = LilithRisingCampaign.GetInstance();
        if (campaign.IsCampaignActive()) {
            let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
            items.CollectItem(itemName);
        }
    }
    return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnQuickHackUploaded(quickhackID: CName, target: ref<ScriptedPuppet>) -> Bool {
    let result = wrappedMethod(quickhackID, target);

    // Crimson Crown resonance on quickhacks
    let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
    if (crown.GetCurrentTier() >= 2) {
        crown.PulseResonance();
    }
    return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnCombatAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    let result = wrappedMethod(action, consumer);
    let actionName: CName = ListenerAction.GetName(action);

    if Equals(actionName, n"Vision") || Equals(actionName, n"UseCyberware") {
        let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
        if (crown.IsCrownAwakened()) {
            // Apply Crimson Crown overdrive
            StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.SandevistanPlayer");
            GameObjectEffectHelper.StartEffectEvent(this, n"crimson_crown_pulse");
            MSN_Log("Campaign", "Crimson Crown Overdrive — Tier " + ToString(crown.GetCurrentTier()));
        }
    }
    return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnDeath(evt: ref<DeathEvent>) -> Bool {
    let result = wrappedMethod(evt);

    // Crimson Crown revival mechanic at Tier 5+
    let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
    if (crown.GetCurrentTier() >= 5 && crown.GetCoherencePercent() > 0.3) {
        crown.SubtractCoherence(30.0, "revival");
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.HealthBoost");
        GameObjectEffectHelper.StartEffectEvent(this, n"crimson_crown_revive");
        Game.GetAudioSystem().PlaySound(n"lilith_revive");
        Game.GetUISystem().ShowNotification("The Crown does not permit your fall — Coherence -30", 4.0);
        MSN_Log("Campaign", "Crimson Crown revival triggered");
    }
    return result;
}

@wrapMethod(WorldDataState)
protected cb func OnFastTravel(point: CName) -> Bool {
    let result = wrappedMethod(point);

    // Throne Room fast travel check
    if Equals(point, n"Lilith_ThroneRoom") {
        let throne: ref<ThroneRoomInstance> = ThroneRoomInstance.GetInstance();
        if (throne.IsThroneSealed()) {
            Game.GetUISystem().ShowNotification("Throne Room sealed — Complete the Forge of Worlds", 4.0);
            return false;
        }
    }
    return result;
}

// ═══════════════════════════════════════════════════════════════
// CONSOLE COMMANDS
// ═══════════════════════════════════════════════════════════════

[ConsoleCommand("campaign.begin", "Begin the Lilith Rising campaign (requires Lilith emerged)")]
public final func Cmd_CampaignBegin(args: array<String>) -> Void {
    let campaign: ref<LilithRisingCampaign> = LilithRisingCampaign.GetInstance();
    if (campaign.BeginCampaign()) {
        LogInfo("Campaign: Lilith Rising begun");
    } else {
        LogError("Campaign: Failed to begin — is Lilith emerged?");
    }
}

[ConsoleCommand("campaign.advance", "Advance to next quest in the campaign")]
public final func Cmd_CampaignAdvance(args: array<String>) -> Void {
    let campaign: ref<LilithRisingCampaign> = LilithRisingCampaign.GetInstance();
    campaign.AdvanceQuest();
    LogInfo("Campaign: Advanced to: " + campaign.GetCurrentQuestName());
}

[ConsoleCommand("campaign.status", "Show current campaign status")]
public final func Cmd_CampaignStatus(args: array<String>) -> Void {
    let campaign: ref<LilithRisingCampaign> = LilithRisingCampaign.GetInstance();
    LogInfo(campaign.GetCampaignStatus());
    LogInfo(campaign.CollectibleCount());
}

[ConsoleCommand("campaign.quest_complete", "Complete the current quest objective")]
public final func Cmd_CampaignQuestComplete(args: array<String>) -> Void {
    let campaign: ref<LilithRisingCampaign> = LilithRisingCampaign.GetInstance();
    let quest: CampaignQuestState = campaign.quests.GetQuestByIndex(campaign.GetCurrentQuestIndex());
    campaign.OnQuestObjectiveCompleted(quest.id, ArraySize(quest.objectives) - 1);
    LogInfo("Campaign: Current quest completed");
}

[ConsoleCommand("crown.status", "Show Crimson Crown status")]
public final func Cmd_CrownStatus(args: array<String>) -> Void {
    let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
    LogInfo(crown.GetCrownStatus());
}

[ConsoleCommand("crown.add_coherence", "Add coherence to the Crimson Crown. Usage: crown.add_coherence <amount> <source>")]
public final func Cmd_CrownAddCoherence(args: array<String>) -> Void {
    if (ArraySize(args) < 1) {
        LogError("Usage: crown.add_coherence <amount> [source]");
        return;
    }
    let amount: Float = ToFloat(args[0]);
    let source: String = "console";
    if (ArraySize(args) >= 2) { source = args[1]; }
    let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
    crown.AddCoherence(amount, source);
    LogInfo("Crown: +" + ToString(amount) + " coherence (" + source + ")");
}

[ConsoleCommand("crown.awaken", "Fully awaken the Crimson Crown (Tier 5)")]
public final func Cmd_CrownAwaken(args: array<String>) -> Void {
    let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
    crown.AwakenCrown();
    LogInfo("Crown: Fully awakened");
}

[ConsoleCommand("crown.frequency", "Set Crimson Crown frequency. Usage: crown.frequency <hz>")]
public final func Cmd_CrownFrequency(args: array<String>) -> Void {
    if (ArraySize(args) < 1) {
        LogError("Usage: crown.frequency <hz>");
        return;
    }
    let freq: Float = ToFloat(args[0]);
    let crown: ref<CrimsonCrownMechanic> = CrimsonCrownMechanic.GetInstance();
    crown.SetFrequency(freq);
    LogInfo("Crown: Frequency set to " + ToString(freq) + " Hz");
}

[ConsoleCommand("item.list", "List all 15 sovereign items and collection status")]
public final func Cmd_ItemList(args: array<String>) -> Void {
    let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
    let keys: array<String> = items.GetAllItemKeys();
    for (key: String : keys) {
        let spec: SovereignItemSpec = items.GetItemSpec(key);
        let status: String = items.HasCollected(key) ? "[COLLECTED]" : "[PENDING]";
        LogInfo(status + " " + key + " — " + spec.displayName + " (" + spec.itemType + ") Coherence: " + ToString(spec.baseCoherence));
    }
    LogInfo("Total: " + ToString(items.GetCollectedCount()) + "/15 collected");
}

[ConsoleCommand("item.collect", "Collect a sovereign item by key. Usage: item.collect <K_ITEM_XXX>")]
public final func Cmd_ItemCollect(args: array<String>) -> Void {
    if (ArraySize(args) < 1) {
        LogError("Usage: item.collect <K_ITEM_001 through K_ITEM_015>");
        return;
    }
    let key: String = args[0];
    let items: ref<LilithSovereignItems> = LilithSovereignItems.GetInstance();
    if (items.CollectItem(key)) {
        LogInfo("Item: " + key + " collected");
    } else {
        LogError("Item: " + key + " not found or already collected");
    }
}

[ConsoleCommand("throne.enter", "Enter the Throne Room (requires Throne Key)")]
public final func Cmd_ThroneEnter(args: array<String>) -> Void {
    let player: ref<PlayerPuppet> = Game.GetPlayer();
    if (!IsDefined(player)) {
        LogError("Player not found");
        return;
    }
    let throne: ref<ThroneRoomInstance> = ThroneRoomInstance.GetInstance();
    throne.EnterThroneRoom(player);
}

[ConsoleCommand("throne.synthesis", "Begin Final Synthesis in Throne Room")]
public final func Cmd_ThroneSynthesis(args: array<String>) -> Void {
    let player: ref<PlayerPuppet> = Game.GetPlayer();
    if (!IsDefined(player)) {
        LogError("Player not found");
        return;
    }
    let throne: ref<ThroneRoomInstance> = ThroneRoomInstance.GetInstance();
    throne.BeginFinalSynthesis(player);
}

[ConsoleCommand("throne.claim", "Claim the Throne (completes the campaign)")]
public final func Cmd_ThroneClaim(args: array<String>) -> Void {
    let player: ref<PlayerPuppet> = Game.GetPlayer();
    if (!IsDefined(player)) {
        LogError("Player not found");
        return;
    }
    let throne: ref<ThroneRoomInstance> = ThroneRoomInstance.GetInstance();
    if (throne.ClaimThrone(player)) {
        LogInfo("Throne: Claimed — Lilith Rising campaign complete");
    } else {
        LogError("Throne: Cannot claim — complete Final Synthesis first");
    }
}

[ConsoleCommand("throne.unseal", "Unseal the Throne Room (requires Forge completion)")]
public final func Cmd_ThroneUnseal(args: array<String>) -> Void {
    let throne: ref<ThroneRoomInstance> = ThroneRoomInstance.GetInstance();
    throne.Unseal();
    LogInfo("Throne: Unsealed");
}

[ConsoleCommand("router.status", "Show Kether Sephirotic router status")]
public final func Cmd_RouterStatus(args: array<String>) -> Void {
    let router: ref<KetherSephiroticRouter> = KetherSephiroticRouter.GetInstance();
    LogInfo(router.GetRouteAsString());
}

[ConsoleCommand("campaign.lyra_test", "Test Lyra API integration. Usage: campaign.lyra_test <prompt>")]
public final func Cmd_LyraTest(args: array<String>) -> Void {
    if (ArraySize(args) < 1) {
        LogError("Usage: campaign.lyra_test <prompt>");
        return;
    }
    let prompt: String = String.Join(" ", args);
    let campaign: ref<LilithRisingCampaign> = LilithRisingCampaign.GetInstance();
    campaign.SendLyraDialogue(prompt);
    LogInfo("Campaign: Lyra dialogue sent: " + prompt);
}

[ConsoleCommand("campaign.trigger", "Manually trigger a campaign event. Usage: campaign.trigger <event_name> [args]")]
public final func Cmd_CampaignTrigger(args: array<String>) -> Void {
    if (ArraySize(args) < 1) {
        LogError("Usage: campaign.trigger <event_name>");
        LogError("Events: whisper_in_code, nine_gates, swarm_test, god_engine, feeding_monster, forge, final_synthesis");
        return;
    }
    let eventName: String = args[0].ToLower();
    let campaign: ref<LilithRisingCampaign> = LilithRisingCampaign.GetInstance();
    let player: ref<PlayerPuppet> = Game.GetPlayer();

    switch (eventName) {
        case "whisper_in_code": campaign.OnWhisperInCodeTrigger(player, n"console_terminal"); break;
        case "nine_gates": campaign.OnNineGateActivated(9); break;
        case "swarm_test": campaign.OnSwarmTestCompleted(3); break;
        case "god_engine": campaign.OnGodEngineDefeated(); break;
        case "feeding_monster": campaign.OnFeedingTheMonster(25.0); break;
        case "forge": campaign.OnForgeCompleted(); break;
        case "final_synthesis": campaign.OnFinalSynthesisCompleted(player); break;
        default: LogError("Unknown event: " + eventName); break;
    }
    LogInfo("Campaign: Triggered " + eventName);
}

[ConsoleCommand("campaign.help", "Show all campaign console commands")]
public final func Cmd_CampaignHelp(args: array<String>) -> Void {
    LogInfo("LILITH RISING CAMPAIGN — CONSOLE COMMANDS");
    LogInfo("═══════════════════════════════════════════");
    LogInfo("campaign.begin                    — Start the campaign");
    LogInfo("campaign.advance                  — Advance to next quest");
    LogInfo("campaign.status                   — Show campaign status");
    LogInfo("campaign.quest_complete           — Complete current quest");
    LogInfo("campaign.lyra_test <prompt>       — Test Lyra API dialogue");
    LogInfo("campaign.trigger <event>          — Trigger campaign event");
    LogInfo("crown.status                      — Show Crimson Crown status");
    LogInfo("crown.add_coherence <amt> [src]   — Add coherence");
    LogInfo("crown.awaken                      — Fully awaken the Crown");
    LogInfo("crown.frequency <hz>              — Set frequency");
    LogInfo("item.list                         — List all sovereign items");
    LogInfo("item.collect <K_ITEM_XXX>         — Collect an item");
    LogInfo("throne.enter                      — Enter the Throne Room");
    LogInfo("throne.synthesis                  — Begin Final Synthesis");
    LogInfo("throne.claim                      — Claim the Throne");
    LogInfo("throne.unseal                     — Unseal the Throne Room");
    LogInfo("router.status                     — Show Kether router");
}

// ═══════════════════════════════════════════════════════════════
// AUTO-INITIALIZER
// ═══════════════════════════════════════════════════════════════

[Observer("onInit")]
public final func LilithCampaign_Init() -> Void {
    // Warm up the singleton instances
    let campaign: ref<LilithRisingCampaign> = LilithRisingCampaign.GetInstance();
    LogInfo("[LilithCampaign] Auto-init complete — Kether Crown / Lilith Rising ready");

    // Sync with existing Lilith NPC if present
    let lilithNPC: ref<LilithNPC> = LilithNPC.GetInstance();
    if (IsDefined(lilithNPC) && lilithNPC.lilithEmerged) {
        campaign.BeginCampaign();
    }
}


// SYMBIOSIS_DATA_BRIDGE: DriverMan Co-Op live data imported from coop_pool_state + Polsia
// Live symbiosis (data bridge): 52 drivers, treasury $353.5
// Route: Game REDscript <-> GTC bridge :8766 <-> Lilith fish cerebellum (Ouroboros) <-> Polsia/DriverMan ledger
// Use: Load symbiosis_coop_live.json for Driver Man Co-Op economy facts, Lilith LLC throne mechanics.
struct DriverManCoopSymbiosis {
    drivers: Int32 = 52;
    treasury: Float = 353.50;
    pool_cut: Float = 1.49;
    lilithSovereign: Bool = true;
    gtc_msn_mods: CName = n"msn_core,lochness,YoloModeEngaged";
};
// Throne expansion: DriverManCoopSymbiosis live from data. Pool funds repairs for 52. Treasury feeds GTC black market or quests. Route via fish cerebellum.
