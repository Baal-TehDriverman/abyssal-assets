// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// GRAND THEFT CYBERPUNK - STAR WARS/JEDI COMPATIBILITY WRAPPER
// The older StarWarsSystem entry point now delegates to MSNJediSystem.
// Item, holocron, and saber records are data-only in tweakdb/msn_magic_jedi.tweakdb.

// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
// Sephirotic Court Seal — Hod | desktop/cp2077_mods/msn_starwars_system.reds
// Court agent: Hod | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnStarwarsSystem | Hod | agent=Hod
public class StarWarsSystem extends IScriptable {
    private static let instance: ref<StarWarsSystem>;
    private let initialized: Bool;

    public final static func GetInstance() -> ref<StarWarsSystem> {
        if (!IsDefined(StarWarsSystem.instance)) {
            StarWarsSystem.instance = new StarWarsSystem();
            StarWarsSystem.instance.Initialize();
        };
        return StarWarsSystem.instance;
    }

    private final func Initialize() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnStarwarsSystem", 2);

        if (this.initialized) {
            return;
        };
        this.initialized = true;
        MSNJediSystem.GetInstance();
        LogInfo("[StarWarsSystem] compatibility wrapper online; delegated to MSNJediSystem");
    }

    public final func InitializeForceUser(entity: ref<Entity>, alignment: CName) -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.SetAlignment(alignment);
    }

    public final func UseForcePower(powerName: CName) -> Bool {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        return jedi.UsePower(powerName);
    }

    public final func ToggleLightsaber(user: ref<Entity>) -> Bool {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        return jedi.UsePower(n"SaberFormShiiCho");
    }

    public final func ChangeLightsaberForm(user: ref<Entity>, form: CName) -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.UsePower(form);
    }

    @Command("msn.starwars.status")
    public final func CmdStarWarsStatus() -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        Game.GetUIManager().ShowNotification("MSN Star Wars compatibility: " + jedi.GetStatus());
    }
}

public class ForceSensitivityCerebellum extends IScriptable {
    @Property() public let alignmentBias: CName = n"Grey";

    public final func OnInstall(entity: ref<Entity>) -> Void {
        let sw: ref<StarWarsSystem> = StarWarsSystem.GetInstance();
        sw.InitializeForceUser(entity, this.alignmentBias);
    }
}
