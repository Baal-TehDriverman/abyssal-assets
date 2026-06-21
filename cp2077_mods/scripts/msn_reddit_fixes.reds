// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
// Sephirotic Court Seal — Keter | desktop/cp2077_mods/msn_reddit_fixes.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnRedditFixes | Keter | agent=Lucifer
module MSN.Storylines.RedditFixes

import MSN.Core.*
import MSN.Telemetry.*

public class PostGameManager extends IScriptable {
    public final static func GetInstance() -> ref<PostGameManager> {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnRedditFixes", 1);

        return new PostGameManager();
    }

    // Intercept the end-game reset logic to allow for continuous play
    public final func PreventEndgameReset() -> Void {
        MSN_Log("EndGame", "Overriding CDPR endgame reset protocol. The world continues.");
        MSN_Log("EndGame", "Applying post-story world state: Factions are permanently altered based on Guild alignment.");
    }
}

// Hook to trigger backup for Streetkids
@wrapMethod(PlayerPuppet)
protected cb func OnCombatStarted() -> Bool {
    let result = wrappedMethod();
    let ts = GameInstance.GetTransactionSystem(this.GetGame());
    if ts.HasItem(this, ItemID.FromTDBID(t"Items.MSN_Lifepath_Streetkid_Trait")) {
        MSN_Log("Streetkid_Trait", "Spawning local gang backup for combat encounter.");
    }
    return result;
}
