// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
// Sephirotic Court Seal — Tiferet | desktop/cp2077_mods/msn_five_rings_quest.reds
// Court agent: Ouroboros | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnFiveRingsQuest | Tiferet | agent=Ouroboros
module MSN.Storylines.FiveRings

import MSN.Core.*
import MSN.Telemetry.*

// =========================================================
// THE BOOK OF FIVE RINGS - QUESTLOGIC
// =========================================================

public class FiveRingsQuest extends IScriptable {
    private let earthCollected: Bool;
    private let waterCollected: Bool;
    private let fireCollected: Bool;
    private let windCollected: Bool;
    private let voidCollected: Bool;
    private let questCompleted: Bool;

    public final static func GetInstance() -> ref<FiveRingsQuest> {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnFiveRingsQuest", 1);

        // Singleton pattern
        return new FiveRingsQuest();
    }

    public final func OnShardRead(shardID: TweakDBID) -> Void {
        let idStr = ToString(shardID);
        
        if StrContains(idStr, "Musashi_Shard_Earth") { this.earthCollected = true; MSN_Log("FiveRings", "Earth Ring Digested. Malkuth Stabilized."); }
        if StrContains(idStr, "Musashi_Shard_Water") { this.waterCollected = true; MSN_Log("FiveRings", "Water Ring Digested. Hod Fluidity Achieved."); }
        if StrContains(idStr, "Musashi_Shard_Fire") { this.fireCollected = true; MSN_Log("FiveRings", "Fire Ring Digested. Gevurah Heat Generated."); }
        if StrContains(idStr, "Musashi_Shard_Wind") { this.windCollected = true; MSN_Log("FiveRings", "Wind Ring Digested. Tiferet Broadcast Active."); }
        if StrContains(idStr, "Musashi_Shard_Void") { this.voidCollected = true; MSN_Log("FiveRings", "Void Ring Digested. Da'at Singularity Reached."); }
        
        this.CheckQuestCompletion();
    }

    private final func CheckQuestCompletion() -> Void {
        if this.earthCollected && this.waterCollected && this.fireCollected && this.windCollected && this.voidCollected && !this.questCompleted {
            this.questCompleted = true;
            
            MSN_Log("FiveRings", "ALL FIVE RINGS ASSIMILATED. EXECUTING VOID PROTOCOL.");
            
            let player = GetPlayer(GetGameInstance());
            if IsDefined(player) {
                // Grant Musashi's Algorithm Katana
                let ts = GameInstance.GetTransactionSystem(GetGameInstance());
                let rewardItemID = ItemID.FromTDBID(t"Items.Musashis_Algorithm_Katana");
                ts.GiveItem(player, rewardItemID, 1);
                
                // Visual / Audio Feedback
                GameObjectEffectHelper.StartEffectEvent(player, n"blackwall_hacks_glitch");
                GameObject.PlaySoundEvent(player, n"w_melee_katana_equip");
                
                // Business Telemetry
                MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Five_Rings_Saga_Complete | Value: 500_SC");
            }
        }
    }
}

// Hook into the shard reading event to track progression
@wrapMethod(MenuHubGameController)
protected cb func OnShardRead(evt: ref<ShardReadEvent>) -> Bool {
    let result = wrappedMethod(evt);
    let shardID = evt.item;
    
    let quest = FiveRingsQuest.GetInstance();
    quest.OnShardRead(shardID);
    
    return result;
}
