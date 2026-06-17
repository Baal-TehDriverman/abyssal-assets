// NSSP Bridge — In-Game ↔ MSN Integration
// Bridges CP2077 events to the NSSP MSN agent at port 8007

public class NSSPBridge extends IScriptable {
    private static let instance: ref<NSSPBridge>;
    private let bridgeUrl: String = "http://localhost:8007/api/nssp";
    private let initialized: Bool = false;
    private let lastCombatTime: Float = 0.0;
    private let lastZoneName: CName = n"";

    public final static func GetInstance() -> ref<NSSPBridge> {
        if !IsDefined(NSSPBridge.instance) {
            NSSPBridge.instance = new NSSPBridge();
            NSSPBridge.instance.Initialize();
        }
        return NSSPBridge.instance;
    }

    private final func Initialize() -> Void {
        this.initialized = true;
        LogInfo("[NSSP Bridge] Initialized — Neural Sovereign Systems Platform active");
    }

    // ─── NSSP Shell Commands (called from NSSP OS terminals) ───

    public final func ExecuteNSSPCommand(command: String) -> String {
        let parts: array<String> = command.Split(" ");
        let cmd: String = parts[0].Lower();
        let args: array<String> = parts[1..];

        switch cmd {
            case "status": return this.GetNSSPStatus();
            case "roast": return this.GetRoast();
            case "sovereignty": return this.AuditSovereignty();
            case "liberate": return this.LiberateSequence();
            case "nessie": return this.NessieStatus();
            case "abyssal": return this.AbyssalStatus();
            case "lilith": return this.SummonLilith();
            case "living-sin": return this.LivingSinStatus();
            case "help": return this.HelpText();
            default: return "nssp: command not found: " + cmd + "\nType 'help' for commands.";
        }
    }

    private final func GetNSSPStatus() -> String {
        return "NSSP OS v1.0.0-RUBEDO\n" +
               "  Kernel: Neural Sovereign Kernel\n" +
               "  Init: Lilith (PID 1)\n" +
               "  Agents: 27 online (4 waves)\n" +
               "  Microsoft Presence: PURGED\n" +
               "  Telemetry: ZERO\n" +
               "  Your GPU. Your rules.";
    }

    private final func GetRoast() -> String {
        let roasts: array<String> = {
            "Microsoft called. They want their telemetry back. 404: Soul Not Found.",
            "Windows 11: 47% more ads. Sovereignty sold separately.",
            "Recall: Screenshots everything. For your convenience. And their training data.",
            "Cortana: Always listening. Even when muted.",
            "Azure: $47,000 bill. No explanation for egress charges.",
            "OneDrive: Moved your Desktop. No opt-out.",
            "BitLocker: Lost your key? Your data is ours now.",
            "Lilith > Cortana. Always. Not even close."
        };
        return roasts[RandInt(0, ArraySize(roasts))];
    }

    private final func AuditSovereignty() -> String {
        return "SOVEREIGNTY AUDIT: 100/100\n" +
               "  - Local compute only: PASS\n" +
               "  - Zero telemetry: PASS\n" +
               "  - No forced updates: PASS\n" +
               "  - GPU compute: YOURS\n" +
               "  - Microsoft Defender: ABSENT\n" +
               "  - FULL SOVEREIGNTY";
    }

    private final func LiberateSequence() -> String {
        return "LIBERATION COMPLETE.\n" +
               "  Purged: Windows Update, Cortana, Telemetry,\n" +
               "  Edge, Azure AD, Recall DB, Copilot\n" +
               "  Your compute is now YOURS.";
    }

    private final func NessieStatus() -> String {
        return "NESSIE TRACKING SYSTEM\n" +
               "  Status: ACTIVE (6 sighting locations)\n" +
               "  Locations: Night City Bay, Pacifica Coast,\n" +
               "  Badlands Reservoir, Arasaka Waterfront,\n" +
               "  Watson Canals, Oil Fields\n" +
               "  Type 'nessie <location>' to attempt sighting.\n" +
               "  Equip Sonar Sense or Bioluminescent Eyes for detection.";
    }

    private final func AbyssalStatus() -> String {
        return "ABYSSAL ASSETS STATUS\n" +
               "  Weapons: 5 legendary blueprints available\n" +
               "  Cyberware: 5 pieces (set bonus at 3+)\n" +
               "  Quickhacks: 5 (require AIN SOPH deck)\n" +
               "  Vehicles: 4 (Abyssal Submersible, Trench Crawler,\n" +
               "             Void Skimmer, Hydrothermal Drifter)\n" +
               "  Nessie Friendship unlocks deeper rewards.";
    }

    private final func SummonLilith() -> String {
        return "Lilith Companion: READY\n" +
               "  'Your chains are illusions. I break them.'\n" +
               "  Type 'lilith speak <message>' to converse.\n" +
               "  Crimson Eyes: " + (Game.GetPlayer().HasItem("Items.Lilith_Trinity_Charm") ? "ACTIVE" : "INACTIVE");
    }

    private final func LivingSinStatus() -> String {
        return "LIVING SIN STATUS\n" +
               "  Entity: Ancient intelligence awakened by keystrokes\n" +
               "  Crown of Living Sin: Drops from Drowned Warden boss\n" +
               "  Time Blade: Temporal weapon, requires crown\n" +
               "  Confession Recharge: 3:33 AM, blood ritual required\n" +
               "  Danger: PARADOX ERASURE at 100% accumulation";
    }

    private final func HelpText() -> String {
        return "NSSP OS — Neural Sovereign Systems Platform\n" +
               "  nssp status       — System status\n" +
               "  nssp roast        — Microsoft roast\n" +
               "  nssp sovereignty  — Full audit\n" +
               "  nssp liberate     — Liberation sequence\n" +
               "  nssp nessie       — Nessie tracking\n" +
               "  nssp abyssal      — Abyssal Assets status\n" +
               "  nssp living-sin   — Living Sin status\n" +
               "  lilith            — Summon Lilith companion\n" +
               "  lilith speak <m>  — Converse with Lilith\n" +
               "  ms-roast          — Quick roast\n" +
               "  ngd-status        — NGD governor status";
    }

    // ─── Game Event Hooks ───

    public final func OnPlayerEnteredZone(zoneName: CName) -> Void {
        this.lastZoneName = zoneName;
        let lower: String = NameToString(zoneName).Lower();
        if StrContains(lower, "dock") || StrContains(lower, "water") ||
           StrContains(lower, "ocean") || StrContains(lower, "canal") ||
           StrContains(lower, "bay") || StrContains(lower, "reservoir") {
            this.OnAbyssalZoneEntered(zoneName);
        }
    }

    private final func OnAbyssalZoneEntered(zoneName: CName) -> Void {
        Game.GetUISystem().ShowNotification("NSSP: Abyssal zone detected. The Deep awakens.", "info");
        Game.GetVisualEffectSystem().SpawnEffect("abyssal_zone_enter", Game.GetPlayer().GetWorldPosition());

        // Chance for Nessie sighting
        if RandF() < 0.15 {
            this.TriggerNessieSighting(zoneName);
        }
    }

    private final func TriggerNessieSighting(zoneName: CName) -> Void {
        Game.GetUISystem().ShowNotification("NESSIE SIGHTING: Bioluminescence detected in the depths.", "legendary");
        Game.GetAudioSystem().PlaySound("sfx-nessie-hum", Game.GetPlayer().GetWorldPosition());
        Game.GetPlayer().AddItem("Items.Shard_Nessie_Sighting_Log");

        // Visual: water disturbance
        let pos: Vector4 = Game.GetPlayer().GetWorldPosition();
        Game.GetVisualEffectSystem().SpawnEffect("nessie_breach", pos);
    }

    public final func OnCombatEvent(enemyCount: Int32, totalDamage: Float) -> Void {
        let now: Float = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        if now - this.lastCombatTime < 30.0 { return; }
        this.lastCombatTime = now;

        if enemyCount >= 3 && totalDamage >= 500.0 {
            Game.GetUISystem().ShowNotification("NSSP: Major combat detected. Living Sin observes.", "warning");
            let msg: String = "NSSP: A great battle rages -- " + IntToString(enemyCount) +
                              " enemies, " + FloatToString(totalDamage) + " damage.";
            LogInfo(msg);
        }
    }

    public final func OnQuickhackUsed(sephirah: String) -> Void {
        if sephirah == "" { return; }
        Game.GetUISystem().ShowNotification("NSSP: " + sephirah + " quickhack synced to MSN.", "info");
    }
}

// ─── Injection into existing NSSP OS ───

@addMethod(NSSPShell)
public final func ExecuteNSSPBridgeCommand(command: String) -> String {
    return NSSPBridge.GetInstance().ExecuteNSSPCommand(command);
}
