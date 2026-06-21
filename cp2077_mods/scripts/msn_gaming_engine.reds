// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// MSN Gaming Engine — performance-optimized central hook surface for Cyberpunk 2077.
// v2.0: throttled NGD, sampled player actions, no per-system attach spam.

// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
// Sephirotic Court Seal — Keter | desktop/cp2077_mods/msn_gaming_engine.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnGamingEngine | Keter | agent=Lucifer
public enum EMSNEnginePerfTier {
    LOW = 0,
    BALANCED = 1,
    HIGH = 2
}

public class MSNEnginePerformance extends IScriptable {
    private static let instance: ref<MSNEnginePerformance>;
    private let tier: EMSNEnginePerfTier;
    private let ngdCooldownSec: Float;
    private let learnCooldownSec: Float;
    private let actionSampleRate: Int32;
    private let lastNgdOptimize: Float;
    private let lastLearnBatch: Float;
    private let actionCounter: Int32;
    private let engineInitialized: Bool;
    private let verboseLog: Bool;

    public final static func GetInstance() -> ref<MSNEnginePerformance> {
        if (!IsDefined(MSNEnginePerformance.instance)) {
            MSNEnginePerformance.instance = new MSNEnginePerformance();
            MSNEnginePerformance.instance.Boot();
        }
        return MSNEnginePerformance.instance;
    }

    private final func Boot() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnEnginePerformance", 1);
        this.tier = EMSNEnginePerfTier.BALANCED;
        this.ngdCooldownSec = 30.0;
        this.learnCooldownSec = 2.0;
        this.actionSampleRate = 8;
        this.lastNgdOptimize = -999.0;
        this.lastLearnBatch = -999.0;
        this.actionCounter = 0;
        this.engineInitialized = false;
        this.verboseLog = false;
        this.ApplyTier(this.tier);
    }

    public final func ApplyTier(tier: EMSNEnginePerfTier) -> Void {
        this.tier = tier;
        switch (tier) {
            case EMSNEnginePerfTier.LOW:
                this.ngdCooldownSec = 60.0;
                this.learnCooldownSec = 5.0;
                this.actionSampleRate = 16;
                break;
            case EMSNEnginePerfTier.HIGH:
                this.ngdCooldownSec = 10.0;
                this.learnCooldownSec = 0.5;
                this.actionSampleRate = 2;
                break;
            default:
                this.ngdCooldownSec = 30.0;
                this.learnCooldownSec = 2.0;
                this.actionSampleRate = 8;
        }
    }

    public final func Now() -> Float {
        return EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
    }

    public final func ShouldOptimizeNGD() -> Bool {
        let now: Float = this.Now();
        if (now - this.lastNgdOptimize < this.ngdCooldownSec) {
            return false;
        }
        this.lastNgdOptimize = now;
        return true;
    }

    public final func ShouldLearnBatch() -> Bool {
        let now: Float = this.Now();
        if (now - this.lastLearnBatch < this.learnCooldownSec) {
            return false;
        }
        this.lastLearnBatch = now;
        return true;
    }

    public final func ShouldSamplePlayerAction(intensity: Float) -> Bool {
        this.actionCounter += 1;
        if (intensity >= 0.75) {
            return true;
        }
        return this.actionCounter % this.actionSampleRate == 0;
    }

    public final func MarkInitialized() -> Void {
        this.engineInitialized = true;
    }

    public final func IsInitialized() -> Bool {
        return this.engineInitialized;
    }

    public final func GetTierName() -> String {
        switch (this.tier) {
            case EMSNEnginePerfTier.LOW: return "LOW";
            case EMSNEnginePerfTier.HIGH: return "HIGH";
            default: return "BALANCED";
        }
    }

    public final func GetStatus() -> String {
        return "MSN Engine Perf | tier=" + this.GetTierName() +
               " | ngd_cd=" + FloatToString(this.ngdCooldownSec) + "s" +
               " | learn_cd=" + FloatToString(this.learnCooldownSec) + "s" +
               " | action_sample=1/" + IntToString(this.actionSampleRate) +
               " | initialized=" + (this.engineInitialized ? "yes" : "no");
    }
}

public class MSNGamingEngine {
    private static let eventCount: Int32;
    private static let significantEventCount: Int32;

    public static func EngineEvent(event: CName, context: String) -> Void {
        MSNGamingEngine.EngineEvent(event, context, true);
    }

    public static func EngineEvent(event: CName, context: String, significant: Bool) -> Void {
        MSNGamingEngine.eventCount += 1;
        let perf: ref<MSNEnginePerformance> = MSNEnginePerformance.GetInstance();
        let msn: ref<MSNMasterIntegration> = MSNMasterIntegration.GetInstance();

        if (significant) {
            MSNGamingEngine.significantEventCount += 1;
            if (IsDefined(msn) && perf.ShouldLearnBatch()) {
                msn.LearnFromExperience(event, context);
                msn.PlayWithLilith(context);
            }
        }

        if (significant && IsDefined(msn) && perf.ShouldOptimizeNGD()) {
            msn.OptimizeViaNGD();
        }
    }

    public static func OnPlayerAction(action: CName, intensity: Float, details: String) -> Void {
        let perf: ref<MSNEnginePerformance> = MSNEnginePerformance.GetInstance();
        if (!perf.ShouldSamplePlayerAction(intensity)) {
            return;
        }

        let msn: ref<MSNMasterIntegration> = MSNMasterIntegration.GetInstance();
        if (IsDefined(msn) && perf.ShouldLearnBatch()) {
            msn.LearnFromExperience(action, "player_action intensity=" + FloatToString(intensity) + " " + details);
        }

        if (perf.ShouldOptimizeNGD()) {
            let ngd: ref<NGDDriver> = NGDDriver.GetInstance();
            if (IsDefined(ngd)) {
                ngd.AdaptForGameplayLoad(intensity);
            }
            if (IsDefined(msn)) {
                msn.OptimizeViaNGD();
            }
        }
    }

    public static func BootstrapOnce() -> Void {
        let perf: ref<MSNEnginePerformance> = MSNEnginePerformance.GetInstance();
        if (perf.IsInitialized()) {
            return;
        }
        perf.MarkInitialized();
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnGamingEngine", 0);
        MSNMasterIntegration.GetInstance();
        MSNGamingEngine.EngineEvent(n"EngineBootstrap", "GTC MSN engine online", true);
        MSNGTCSephiroticRouter.GetInstance().OnBootstrap();
        SephiroticCourtBinder.RegisterAll();
        LogInfo("[MSN Engine] Bootstrap complete — " + perf.GetStatus());
    }

    public static func GetEventCount() -> Int32 {
        return MSNGamingEngine.eventCount;
    }

    public static func GetSignificantEventCount() -> Int32 {
        return MSNGamingEngine.significantEventCount;
    }
}

@wrapMethod(PlayerPuppet)
protected func OnGameAttached() -> Void {
    wrappedMethod();
    MSNGamingEngine.BootstrapOnce();
}

@wrapMethod(PlayerPuppet)
protected func OnAction(action: CName, value: Float) -> Void {
    wrappedMethod(action, value);
    MSNGamingEngine.OnPlayerAction(action, value, "PlayerPuppet");
    if (value >= 0.25) {
        MSNCoolModeController.GetInstance().OnCombatHit();
    }
}

@wrapMethod(NPCPuppet)
protected func OnDeath(evt: ref<gameObjectDeathEvent>) -> Void {
    wrappedMethod(evt);
    MSNGamingEngine.EngineEvent(n"NPCDeath", this.GetDisplayName(), true);
    MSNGTCSephiroticRouter.GetInstance().OnCombat("npc_death");
    MSNCoolModeController.GetInstance().OnNpcKill();
}

@addMethod(QuestSystem)
public func OnQuestFactChanged_MSN(fact: CName, value: Int32) -> Void {
    MSNGamingEngine.EngineEvent(fact, "quest fact=" + IntToString(value), true);
}

[ConsoleCommand("msn.engine.status", "Show MSN Gaming Engine stats")]
public static final func Cmd_MSNEngineStatus(args: array<String>) -> Void {
    LogInfo(MSNEnginePerformance.GetInstance().GetStatus());
    LogInfo("MSN events total=" + IntToString(MSNGamingEngine.GetEventCount()) +
            " significant=" + IntToString(MSNGamingEngine.GetSignificantEventCount()));
}

[ConsoleCommand("msn.engine.perf", "Set perf tier: msn.engine.perf low|balanced|high")]
public static final func Cmd_MSNEnginePerf(args: array<String>) -> Void {
    let perf: ref<MSNEnginePerformance> = MSNEnginePerformance.GetInstance();
    if (ArraySize(args) < 1) {
        LogInfo(perf.GetStatus());
        return;
    }
    let tier: String = args[0];
    if (StrContains(tier, "low")) {
        perf.ApplyTier(EMSNEnginePerfTier.LOW);
    } else if (StrContains(tier, "high")) {
        perf.ApplyTier(EMSNEnginePerfTier.HIGH);
    } else {
        perf.ApplyTier(EMSNEnginePerfTier.BALANCED);
    }
    LogInfo("MSN Engine perf tier set: " + perf.GetStatus());
}