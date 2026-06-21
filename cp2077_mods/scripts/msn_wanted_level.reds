// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
// Sephirotic Court Seal — Gevurah | desktop/cp2077_mods/msn_wanted_level.reds
// Court agent: Abraxas | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnWantedLevel | Gevurah | agent=Abraxas
module MSN.Storylines.WantedLevel

import MSN.Core.*
import MSN.Telemetry.*

public class MSNWantedLevelManager extends IScriptable {
    private static let instance: ref<MSNWantedLevelManager>;

    public final static func GetInstance() -> ref<MSNWantedLevelManager> {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnWantedLevel", 1);

        if (!IsDefined(MSNWantedLevelManager.instance)) {
            MSNWantedLevelManager.instance = new MSNWantedLevelManager();
        }
        return MSNWantedLevelManager.instance;
    }

    public final func ProcessAssassination(player: ref<PlayerPuppet>, target: ref<ScriptedPuppet>) -> Void {
        let preventionSystem = GameInstance.GetPreventionSystem(player.GetGame());
        if IsDefined(preventionSystem) {
            MSN_Log("WantedLevel", "Abyssal Exchange target eliminated. Raising NCPD Heat to 4 stars.");
            
            let heatReq = new PreventionHeatActionRequest();
            heatReq.action = EPreventionHeatAction.SetHeatStage;
            heatReq.stage = 4;
            preventionSystem.QueueRequest(heatReq);

            // Log to Abyssal Exchange Telemetry
            MSN_Log("Business_Exchange", "ASSASSINATION_COMPLETE | Target Eliminated | Result: HEAT_LEVEL_4");
        }
    }
}

// Hook into NPC Death to check for Abyssal Exchange Assassinations
@wrapMethod(ScriptedPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    let player = evt.instigator as PlayerPuppet;
    if IsDefined(player) {
        // Checking if the dead NPC is an Abyssal Exchange target
        // We check for the specific TweakDB tag
        let isAbyssalTarget: Bool = this.GetRecord().TagsContains(n"AbyssalAssassinationTarget");
        
        if isAbyssalTarget {
            MSNWantedLevelManager.GetInstance().ProcessAssassination(player, this);
        }
    }
    
    return result;
}
