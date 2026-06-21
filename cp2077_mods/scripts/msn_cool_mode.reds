// Sephirotic Court Seal — Keter | desktop/cp2077_mods/msn_cool_mode.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnCoolMode | Keter | agent=Lucifer
// CourtFile: MsnCoolMode | Keter | agent=Lucifer
// CourtFile: MsnCoolMode | Keter | agent=Lucifer
// CourtFile: MsnCoolMode | Keter | agent=Lucifer
// CourtFile: MsnCoolMode | Keter | agent=Lucifer
// CourtFile: MsnCoolMode | Keter | agent=Lucifer
// CourtFile: MsnCoolMode | Keter | agent=Lucifer
// MSN Cool Mode — vibe layer (neon/sovereign/chaos/abyssal/jedi/auto)
module MSN.Cool

public enum EMSNCoolVibe {
    AUTO = 0,
    NEON = 1,
    SOVEREIGN = 2,
    CHAOS = 3,
    ABYSSAL = 4,
    JEDI = 5
}

public class MSNCoolModeController extends IScriptable {
    private static let instance: ref<MSNCoolModeController>;
    private let enabled: Bool;
    private let vibe: EMSNCoolVibe;
    private let corruption: Float;
    private let killStreak: Int32;

    public final static func GetInstance() -> ref<MSNCoolModeController> {
        if (!IsDefined(MSNCoolModeController.instance)) {
            MSNCoolModeController.instance = new MSNCoolModeController();
            MSNCoolModeController.instance.Boot();
        }
        return MSNCoolModeController.instance;
    }

    private final func Boot() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnCoolMode", 1);
        this.enabled = true;
        this.vibe = EMSNCoolVibe.AUTO;
        this.corruption = 0.0;
        this.killStreak = 0;
    }

    public final func IsEnabled() -> Bool { return this.enabled; }
    public final func GetVibe() -> EMSNCoolVibe { return this.vibe; }
    public final func GetCorruption() -> Float { return this.corruption; }
    public final func GetKillStreak() -> Int32 { return this.killStreak; }

    public final func SetEnabled(on: Bool) -> Void { this.enabled = on; }

    public final func SetVibe(vibe: EMSNCoolVibe) -> Void {
        this.vibe = vibe;
        if (EnumInt(vibe) == EnumInt(EMSNCoolVibe.JEDI)) {
            let saber: ref<LightsaberVFXController> = new LightsaberVFXController();
            saber.CompileShaders();
        }
    }

    public final func Pulse() -> Void { this.RefreshHud(); }

    public final func OnCombatHit() -> Void {
        if (!this.enabled) { return; }
        this.corruption = MinF(this.corruption + 0.01, 1.0);
        this.RefreshHud();
    }

    public final func OnNpcKill() -> Void {
        if (!this.enabled) { return; }
        this.killStreak += 1;
        this.corruption = MinF(this.corruption + 0.05, 1.0);
        this.RefreshHud();
    }

    private final func RefreshHud() -> Void {
        let hud: ref<CorruptionHUDController> = new CorruptionHUDController();
        hud.UpdatePurityMeter(this.corruption);
    }

    public final func GetStatus() -> String {
        return "CoolMode | on=" + ToString(this.enabled) +
               " vibe=" + ToString(EnumInt(this.vibe)) +
               " corruption=" + ToString(this.corruption) +
               " streak=" + ToString(this.killStreak);
    }
}

[ConsoleCommand("msn.cool.on", "Enable MSN Cool Mode")]
public static final func Cmd_CoolOn(args: array<String>) -> Void {
    MSNCoolModeController.GetInstance().SetEnabled(true);
}

[ConsoleCommand("msn.cool.off", "Disable MSN Cool Mode")]
public static final func Cmd_CoolOff(args: array<String>) -> Void {
    MSNCoolModeController.GetInstance().SetEnabled(false);
}

[ConsoleCommand("msn.cool.status", "Show Cool Mode status")]
public static final func Cmd_CoolStatus(args: array<String>) -> Void {
    LogInfo(MSNCoolModeController.GetInstance().GetStatus());
}

[ConsoleCommand("msn.cool.vibe", "Set vibe: neon|sovereign|chaos|abyssal|jedi|auto")]
public static final func Cmd_CoolVibe(args: array<String>) -> Void {
    if (ArraySize(args) < 1) { return; }
    let ctrl: ref<MSNCoolModeController> = MSNCoolModeController.GetInstance();
    switch (args[0]) {
        case "neon": ctrl.SetVibe(EMSNCoolVibe.NEON); break;
        case "sovereign": ctrl.SetVibe(EMSNCoolVibe.SOVEREIGN); break;
        case "chaos": ctrl.SetVibe(EMSNCoolVibe.CHAOS); break;
        case "abyssal": ctrl.SetVibe(EMSNCoolVibe.ABYSSAL); break;
        case "jedi": ctrl.SetVibe(EMSNCoolVibe.JEDI); break;
        default: ctrl.SetVibe(EMSNCoolVibe.AUTO); break;
    }
}

[ConsoleCommand("msn.cool.pulse", "Trigger Cool Mode pulse")]
public static final func Cmd_CoolPulse(args: array<String>) -> Void {
    MSNCoolModeController.GetInstance().Pulse();
}

[ConsoleCommand("msn.cool.corruption", "Show corruption meter")]
public static final func Cmd_CoolCorruption(args: array<String>) -> Void {
    LogInfo("Corruption: " + ToString(MSNCoolModeController.GetInstance().GetCorruption()));
}

[ConsoleCommand("msn.cool.saber", "Toggle lightsaber VFX vibe")]
public static final func Cmd_CoolSaber(args: array<String>) -> Void {
    MSNCoolModeController.GetInstance().SetVibe(EMSNCoolVibe.JEDI);
}