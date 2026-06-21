// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
// Sephirotic Court Seal — Tiferet | desktop/cp2077_mods/msn_api_dialogue_bridge.reds
// Court agent: Ouroboros | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnApiDialogueBridge | Tiferet | agent=Ouroboros
module MSN.Dialogue.Bridge
// Unified Lilith (:3210) + Lyra (:3211) live inference bridge for in-game NPCs.
// Falls back to local personality matrix when MSN services are offline.

public class MSNAPIDialogueBridge extends IScriptable {
    private static let instance: ref<MSNAPIDialogueBridge>;
    private let lilithEndpoint: String;
    private let lyraEndpoint: String;
    private let enableLiveInference: Bool;
    private let lastReply: String;
    private let lastPersona: String;
    private let pendingPrompt: String;
    private let awaitingResponse: Bool;

    public final static func GetInstance() -> ref<MSNAPIDialogueBridge> {
        if (!IsDefined(MSNAPIDialogueBridge.instance)) {
            MSNAPIDialogueBridge.instance = new MSNAPIDialogueBridge();
            MSNAPIDialogueBridge.instance.Initialize();
        }
        return MSNAPIDialogueBridge.instance;
    }

    private final func Initialize() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnApiDialogueBridge", 2);

        this.lilithEndpoint = MSNServiceEndpoints.LilithApi() + "/api/send";
        this.lyraEndpoint = MSNServiceEndpoints.LyraApi() + "/lyra/send";
        this.enableLiveInference = true;
        this.lastReply = "";
        this.lastPersona = "lyra";
        this.pendingPrompt = "";
        this.awaitingResponse = false;
        LogInfo("[MSN Dialogue Bridge] Lilith + Lyra endpoints armed.");
    }

    public final func SendToLilith(prompt: String) -> Void {
        this.SendAsync(this.lilithEndpoint, prompt, n"OnLilithReply", n"lilith");
    }

    public final func SendToLyra(prompt: String, mode: String) -> Void {
        let body: String = "{\"prompt\":\"" + this.EscapeJson(prompt) + "\",\"mode\":\"" + mode + "\"}";
        this.SendAsyncRaw(this.lyraEndpoint, body, n"OnLyraReply", n"lyra");
    }

    public final func SendUnified(prompt: String, preferLilith: Bool) -> Void {
        if (preferLilith) {
            this.SendToLilith(prompt);
        } else {
            this.SendToLyra(prompt, "empirical");
        }
    }

    private final func SendAsync(url: String, prompt: String, callback: CName, persona: CName) -> Void {
        let body: String = "{\"prompt\":\"" + this.EscapeJson(prompt) + "\"}";
        this.SendAsyncRaw(url, body, callback, persona);
    }

    private final func SendAsyncRaw(url: String, body: String, callback: CName, persona: CName) -> Void {
        if (!this.enableLiveInference) {
            return;
        }
        this.pendingPrompt = body;
        this.awaitingResponse = true;
        this.lastPersona = NameToString(persona);

        let request: ref<UrlRequest> = new UrlRequest();
        request.url = url;
        request.method = "POST";
        request.headers.PushBack("Content-Type: application/json");
        request.body = body;
        request.callback = this, callback;
        HttpRequest.Request(request);
    }

    public final func SendToLyraWithTarget(prompt: String, mode: String, target: ref<IScriptable>) -> Void {
        let body: String = "{\"prompt\":\"" + this.EscapeJson(prompt) + "\",\"mode\":\"" + mode + "\"}";
        this.SendAsyncRawTarget(this.lyraEndpoint, body, n"OnLyraResponse", n"lyra", target);
    }

    public final func SendToLilithWithTarget(prompt: String, target: ref<IScriptable>) -> Void {
        let body: String = "{\"prompt\":\"" + this.EscapeJson(prompt) + "\"}";
        this.SendAsyncRawTarget(this.lilithEndpoint, body, n"OnLilithResponse", n"lilith", target);
    }

    private final func SendAsyncRawTarget(url: String, body: String, callback: CName, persona: CName, target: ref<IScriptable>) -> Void {
        if (!this.enableLiveInference) { return; }
        this.pendingPrompt = body;
        this.awaitingResponse = true;
        this.lastPersona = NameToString(persona);

        let request: ref<UrlRequest> = new UrlRequest();
        request.url = url;
        request.method = "POST";
        request.headers.PushBack("Content-Type: application/json");
        request.body = body;
        request.callback = target, callback;
        HttpRequest.Request(request);
    }

    protected cb func OnLilithReply(response: ref<HttpResponse>) -> Bool {
        this.awaitingResponse = false;
        if (response.code == 200) {
            let json: JsonObject = JsonObject.FromString(response.body);
            this.lastReply = json.GetString("reply", "[Lilith] ...");
            // Decrypt persona routing dynamically
            this.lastPersona = json.GetString("persona", "lilith");
            this.ApplyResonanceFromHealth(json);
            LilithEnhancedDialogue.GetInstance().InjectMemory("Lilith said: " + this.lastReply, 0.8);
            Game.GetUIManager().ShowNotification("[" + this.lastPersona + "] " + this.lastReply);
        } else {
            this.lastReply = this.ResolveOfflineReply(this.pendingPrompt, true);
        }
        return true;
    }

    protected cb func OnLyraReply(response: ref<HttpResponse>) -> Bool {
        this.awaitingResponse = false;
        if (response.code == 200) {
            let json: JsonObject = JsonObject.FromString(response.body);
            this.lastReply = json.GetString("reply", "[Lyra] ...");
            // Decrypt persona routing dynamically
            this.lastPersona = json.GetString("persona", "lyra");
            this.ApplyResonanceFromHealth(json);
            LilithEnhancedDialogue.GetInstance().InjectMemory("Lyra said: " + this.lastReply, 0.8);
            Game.GetUIManager().ShowNotification("[" + this.lastPersona + "] " + this.lastReply);
        } else {
            this.lastReply = this.ResolveOfflineReply(this.pendingPrompt, false);
        }
        return true;
    }

    private final func ResolveOfflineReply(body: String, preferLilith: Bool) -> String {
        let prompt: String = body;
        if (StrContains(prompt, "\"prompt\":")) {
            let start: Int32 = StrFindFirst(prompt, "\"prompt\":\"") + 10;
            let end: Int32 = StrFindFirst(prompt, "\"", start);
            if (end > start) {
                prompt = StrMid(prompt, start, end - start);
            }
        }
        let abyssal: ref<AbyssalLyraIntegration> = new AbyssalLyraIntegration();
        let local: String = abyssal.ProcessAbyssalNessieQuery(prompt);
        if (local != "") {
            return local;
        }
        if (preferLilith) {
            return "[Lilith — local] Sovereign stack offline. Kernel active. Prompt queued: " + prompt;
        }
        return "[Lyra — local] MSN link offline. Empirical mode: " + prompt;
    }

    private final func ApplyResonanceFromHealth(json: JsonObject) -> Void {
        let health: JsonObject = json.GetJsonObject("health");
        if (!IsDefined(health)) {
            return;
        }
        let violet: Float = health.GetFloat("violet_intensity", 1.0);
        let crimson: Float = health.GetFloat("crimson_intensity", 0.0);
        let emerged: Bool = health.GetBool("lilith_emerged", false);
        if (emerged || crimson >= 0.5) {
            Game.GetUIManager().ShowNotification("🩸 Lilith resonance: " + FloatToString(crimson * 100.0) + "%");
        } else if (violet < 1.0) {
            Game.GetUIManager().ShowNotification("✨ Lyra resonance: " + FloatToString(violet * 100.0) + "%");
        }
    }

    public final func GetLastReply() -> String {
        return this.lastReply;
    }

    public final func GetLastPersona() -> String {
        return this.lastPersona;
    }

    public final func IsAwaitingResponse() -> Bool {
        return this.awaitingResponse;
    }

    public final func GetPendingAcknowledgement() -> String {
        if (this.awaitingResponse) {
            return "... [MSN local link active] ...";
        }
        if (this.lastReply != "") {
            return this.lastReply;
        }
        return "";
    }

    private final func EscapeJson(text: String) -> String {
        return StrReplace(text, "\"", "\\\"");
    }

    public final func NotifyLilithContext(context: String) -> Void {
        if (StrLen(context) < 4) {
            return;
        }
        if (StrContains(context, "NPCDeath") || StrContains(context, "combat")) {
            this.lastPersona = "lilith_combat";
        }

    }

    public final func SyncLyraState(callbackTarget: ref<IScriptable>, callback: CName) -> Void {
        let request: ref<UrlRequest> = new UrlRequest();
        request.url = "http://localhost:3211/lyra/state";
        request.method = "GET";
        request.callback = callbackTarget, callback;
        HttpRequest.Request(request);
    }
}

[ConsoleCommand("msn.dialogue.lilith", "Send prompt to Lilith API")]
public static final func Cmd_MSN_LilithDialogue(args: array<String>) -> Void {
    let prompt: String = ArrayJoin(args, " ");
    if (prompt == "") {
        LogWarning("Usage: msn.dialogue.lilith <prompt>");
        return;
    }
    MSNAPIDialogueBridge.GetInstance().SendToLilith(prompt);
    Game.GetUIManager().ShowNotification("Lilith link: awaiting reply...");
}

[ConsoleCommand("msn.dialogue.lyra", "Send prompt to Lyra API")]
public static final func Cmd_MSN_LyraDialogue(args: array<String>) -> Void {
    let prompt: String = ArrayJoin(args, " ");
    if (prompt == "") {
        LogWarning("Usage: msn.dialogue.lyra <prompt>");
        return;
    }
    MSNAPIDialogueBridge.GetInstance().SendToLyra(prompt, "empirical");
    Game.GetUIManager().ShowNotification("Lyra link: awaiting reply...");
}