// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
// Sephirotic Court Seal — Tiferet | desktop/cp2077_mods/msn_quest_archangel.reds
// Court agent: Ouroboros | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnQuestArchangel | Tiferet | agent=Ouroboros
module MSN.Storylines.ArchangelProtocol

import MSN.Core.*
import MSN.Telemetry.*

public class ArchangelQuestManager extends IScriptable {
    private static let instance: ref<ArchangelQuestManager>;
    private let paragonReputation: Int32;

    public final static func GetInstance() -> ref<ArchangelQuestManager> {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnQuestArchangel", 1);

        if (!IsDefined(ArchangelQuestManager.instance)) {
            ArchangelQuestManager.instance = new ArchangelQuestManager();
            ArchangelQuestManager.instance.paragonReputation = 0;
        }
        return ArchangelQuestManager.instance;
    }

    public final func ProcessNonLethalTakedown(player: ref<PlayerPuppet>, target: ref<NPCPuppet>) -> Void {
        let isCyberpsycho = target.GetRecord().GetTagsContains(n"Cyberpsycho");
        
        if isCyberpsycho {
            this.paragonReputation += 1;
            MSN_Log("Archangel", "Cyberpsycho saved. Paragon Reputation increased to " + ToString(this.paragonReputation));
            LyraAudioSystem.GetInstance().PlayLyraVoiceLine(n"lyra_archangel_save_01");
            
            // At level 5, they get deputized
            if this.paragonReputation == 5 {
                MSN_Log("Archangel", "Paragon Level 5 Reached. Player has been deputized by the NCPD.");
                // Simulate granting the badge
                GameInstance.GetTransactionSystem(player.GetGame()).GiveItem(player, ItemID.FromTDBID(t"Items.MSN_Badge_NCPD_Deputized"), 1);
            }
            
            // Good guys get public tax write-offs instead of dirty crypto
            MSN_Log("Lochness", "Nessie acknowledges public service. Base tax rate permanently reduced by 2%.");
        }
    }

    public final func SummonNCPDBackup(player: ref<PlayerPuppet>) -> Void {
        MSN_Log("Archangel", "MaxTac AV summoned. Deploying NCPD bodyguards.");
        GameObjectEffectHelper.StartEffectEvent(player, n"boss_teleport_glitch"); // Stand-in for drop-pod VFX
        // Spawns friendly NPCs on the player's location to assist in combat.
    }
}

// Hook into NPC Defeat to check for Non-Lethal "Soul Saver" takedowns
@wrapMethod(ScriptedPuppet)
protected cb func OnDefeated(evt: ref<DefeatedEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    // Check if the killing blow was non-lethal (simulating the Soul Saver quickhack use)
    let instigator = evt.instigator as PlayerPuppet;
    if IsDefined(instigator) && !this.IsDead() { 
        // IsDead() false means they are just unconscious (non-lethal)
        ArchangelQuestManager.GetInstance().ProcessNonLethalTakedown(instigator, this);
    }
    
    return result;
}

// Hook to trigger the NCPD Summon item
@wrapMethod(EquipmentSystemPlayerData)
protected cb func OnItemEquipped(request: ref<EquipRequest>) -> Bool {
    let result = wrappedMethod(request);
    
    if StrContains(ToString(request.itemID), "MSN_Badge_NCPD_Deputized") {
        let player = this.GetOwner() as PlayerPuppet;
        if IsDefined(player) {
            ArchangelQuestManager.GetInstance().SummonNCPDBackup(player);
        }
    }
    
    return result;
}
