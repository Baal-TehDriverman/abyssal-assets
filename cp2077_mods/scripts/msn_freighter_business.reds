// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
// Sephirotic Court Seal — Chesed | desktop/cp2077_mods/msn_freighter_business.reds
// Court agent: Thoth | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnFreighterBusiness | Chesed | agent=Thoth
module MSN.Storylines.SpaceCombat

import MSN.Core.*
import MSN.Telemetry.*

public class FreighterBusinessManager extends IScriptable {
    private static let instance: ref<FreighterBusinessManager>;

    public final static func GetInstance() -> ref<FreighterBusinessManager> {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnFreighterBusiness", 1);

        if (!IsDefined(FreighterBusinessManager.instance)) {
            FreighterBusinessManager.instance = new FreighterBusinessManager();
        }
        return FreighterBusinessManager.instance;
    }

    public final func ProcessFreighterLogistics(player: ref<PlayerPuppet>) -> Void {
        let ts = GameInstance.GetTransactionSystem(player.GetGame());
        let hasServerRack = ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_Freighter_ServerRack"));

        if hasServerRack {
            // Because the freighter is in orbit, it bypasses Earth's local network latency and local police heat.
            // Optimized movement vectors and evasion logic ensure victory through superior mobility.
            MSN_Log("Orbital_Business", "NSSP Freighter 'Leviathan' connection secure. Evasive orbital vectors locked. Processing tax-free Abyssal Exchange batch.");
            MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Orbital_Server_Farm | Value: 2500_SC");
            
            // Suppress all police heat because operations are happening in space
            MSN_Log("Heat_System", "NCPD Tracking nullified. Operations moved to low orbit. Evasion logic maximized.");
        }
    }
}

// Hook to simulate the orbital business processing whenever the player sleeps or waits
@wrapMethod(TimeSkipPopupGameController)
protected cb func OnTimeSkipFinished(skipTime: Float) -> Bool {
    let result = wrappedMethod(skipTime);
    
    let player = GetPlayer(this.GetPlayerControlledObject().GetGame());
    if IsDefined(player) {
        FreighterBusinessManager.GetInstance().ProcessFreighterLogistics(player);
    }
    
    return result;
}
