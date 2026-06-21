// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
// Sephirotic Court Seal — Chesed | desktop/cp2077_mods/msn_guilds_expansion.reds
// Court agent: Thoth | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnGuildsExpansion | Chesed | agent=Thoth
module MSN.Storylines.GuildExpansion

import MSN.Core.*
import MSN.Telemetry.*

// =========================================================
// GUILD MANAGEMENT SYSTEM
// =========================================================

public class GuildManager extends IScriptable {
    private static let instance: ref<GuildManager>;

    public final static func GetInstance() -> ref<GuildManager> {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnGuildsExpansion", 1);

        if (!IsDefined(GuildManager.instance)) {
            GuildManager.instance = new GuildManager();
        }
        return GuildManager.instance;
    }

    public final func ProcessGuildEffects(player: ref<PlayerPuppet>) -> Void {
        let ts = GameInstance.GetTransactionSystem(player.GetGame());
        
        let hasAlchemists = ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_Alchemists"));
        let hasVoidRunners = ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_VoidRunners"));
        let hasLochSmugglers = ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_LochSmugglers"));

        // The Kingdom outlaws monopolistic guild merging to preserve balance of power
        if (hasAlchemists && hasVoidRunners) || (hasAlchemists && hasLochSmugglers) || (hasVoidRunners && hasLochSmugglers) {
            MSN_Log("Kingdom_Enforcement", "WARNING: Multiple Guild Charters Detected. Kingdom anti-monopoly laws violated. Invoking Imperial Wrath.");
            // Apply a severe debuff
            StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.Overheating");
            GameObject.PlaySoundEvent(player, n"vfx_cyberware_glitch");
            return;
        }

        // Apply specific guild buffs and dues
        if hasAlchemists {
            MSN_Log("Guild_Alchemists", "Ouroboros Alchemy Active: Crafting algorithms optimized.");
            // Buff: Better crafting outcome simulated in logging
            MSN_Log("Crafting", "Alchemist Guild Buff Applied -> +15% chance to craft Legendary.");
        }
        else if hasVoidRunners {
            MSN_Log("Guild_VoidRunners", "Void Runner Link Active: NGD inference accelerated.");
            // Buff: Simulated RAM cost reduction
            MSN_Log("Quickhacks", "Void Runner Guild Buff Applied -> Local inference RAM costs reduced.");
        }
        else if hasLochSmugglers {
            MSN_Log("Guild_LochSmugglers", "Smuggler Routes Active: Exchange taxes bypassed.");
            // Buff: Passive income spike
            MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Smuggler_Yield | Value: 300_SC");
        }

        // The Kingdom's Grip: Overarching tithe and dominance across all guilds
        if hasAlchemists || hasVoidRunners || hasLochSmugglers {
            MSN_Log("Kingdom_Grip", "All Guilds serve the Kingdom. Processing Imperial Tithe (-50 SC).");
            MSN_Log("Business_Exchange", "KINGDOM_TITHE | Value: -50_SC | Status: Glorious_Purpose");
            StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.WellRested"); // The Kingdom protects
        }
    }
}

// Hook into the Game Attached event to process the daily/session Guild effects
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
    let result = wrappedMethod();
    
    // Process guild buffs and dues upon loading into the world
    GuildManager.GetInstance().ProcessGuildEffects(this);
    
    return result;
}

// Intercept Shard reading to hand out the Charters (for testing/modding convenience)
@wrapMethod(MenuHubGameController)
protected cb func OnShardRead(evt: ref<ShardReadEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    // If player reads the initiation broadcast, we grant all three charters so they can choose
    if StrContains(ToString(evt.item), "MSN_QuestShard_GuildInitiation") {
        let player = this.GetPlayerControlledObject() as PlayerPuppet;
        if IsDefined(player) {
            let ts = GameInstance.GetTransactionSystem(player.GetGame());
            
            ts.GiveItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_Alchemists"), 1);
            ts.GiveItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_VoidRunners"), 1);
            ts.GiveItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_LochSmugglers"), 1);
            
            MSN_Log("Guilds", "Initiation Broadcast read. All 3 Charters distributed. Drop 2 to avoid the Guild War Penalty.");
        }
    }
    
    return result;
}
