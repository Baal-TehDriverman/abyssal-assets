// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// MSN Token Economy — Abyssal Assets × Lochness × NSSP unified ledger
// BTC (Lochness/Coinbase), Chaos (NGD/Vex), Lilith (sovereign inference), Soul Coins

// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
// Sephirotic Court Seal — Chesed | desktop/cp2077_mods/msn_token_economy.reds
// Court agent: Thoth | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnTokenEconomy | Chesed | agent=Thoth
public enum EMSNTokenType {
    SOUL_COIN = 0,
    CHAOS = 1,
    LILITH = 2,
    BTC_SAT = 3
}

public class MSNTokenWallet extends IScriptable {
    public let soulCoins: Int32;
    public let chaosTokens: Int32;
    public let lilithTokens: Int32;
    public let btcSats: Int32;
    public let btcUsdPrice: Float;
    public let lastSyncTime: Float;
    public let lochnessOnline: Bool;
    public let nsspSynced: Bool;
}

public class MSNTokenEconomy extends IScriptable {
    private static let instance: ref<MSNTokenEconomy>;
    private let wallet: ref<MSNTokenWallet>;
    private let tokenBridgeUrl: String = "http://localhost:8008/api/lochness";
    private let syncPending: Bool = false;

    // Exchange rates (match tweakdb/nssp_token_economy.yaml)
    private let soulCoinsPerChaos: Float = 13.0;      // 13 SC per Chaos
    private let chaosPerLilith: Float = 3.0;          // 3 Chaos per Lilith
    private let satsPerSoulCoin: Float = 3.5;         // 3.5 sats per 1 SC

    public final static func GetInstance() -> ref<MSNTokenEconomy> {
        if (!IsDefined(MSNTokenEconomy.instance)) {
            MSNTokenEconomy.instance = new MSNTokenEconomy();
            MSNTokenEconomy.instance.Initialize();
        }
        return MSNTokenEconomy.instance;
    }

    private final func Initialize() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnTokenEconomy", 2);

        this.wallet = new MSNTokenWallet();
        this.wallet.soulCoins = 350;
        this.wallet.chaosTokens = 13;
        this.wallet.lilithTokens = 3;
        this.wallet.btcSats = 0;
        this.wallet.btcUsdPrice = 0.0;
        this.wallet.lastSyncTime = 0.0;
        this.wallet.lochnessOnline = false;
        this.wallet.nsspSynced = false;
        LogInfo("[TokenEconomy] NSSP ledger online — BTC/Chaos/Lilith/Soul Coins linked.");
    }

    public final func GetWallet() -> ref<MSNTokenWallet> {
        return this.wallet;
    }

    public final func GetStatusReport() -> String {
        let w: ref<MSNTokenWallet> = this.wallet;
        let btcUsd: String = w.btcUsdPrice > 0.0 ? "$" + FloatToString(w.btcUsdPrice) : "awaiting Lochness sync";
        return "NSSP TOKEN ECONOMY\n" +
               "  Soul Coins:  " + IntToString(w.soulCoins) + " SC\n" +
               "  Chaos:       " + IntToString(w.chaosTokens) + " (NGD/Vex entropy)\n" +
               "  Lilith:      " + IntToString(w.lilithTokens) + " (sovereign inference)\n" +
               "  BTC:         " + IntToString(w.btcSats) + " sats\n" +
               "  BTC/USD:     " + btcUsd + "\n" +
               "  Lochness:    " + (w.lochnessOnline ? "ONLINE ✓" : "OFFLINE") + "\n" +
               "  NSSP Sync:   " + (w.nsspSynced ? "SYNCED ✓" : "LOCAL") + "\n" +
               "  Rates: 13 SC ↔ 1 Chaos | 3 Chaos ↔ 1 Lilith | 350 sats ↔ 100 SC";
    }

    public final func GrantToken(tokenType: EMSNTokenType, amount: Int32, reason: String) -> Void {
        if (amount <= 0) { return; }
        switch (tokenType) {
            case EMSNTokenType.SOUL_COIN:
                this.wallet.soulCoins += amount;
                break;
            case EMSNTokenType.CHAOS:
                this.wallet.chaosTokens += amount;
                break;
            case EMSNTokenType.LILITH:
                this.wallet.lilithTokens += amount;
                break;
            case EMSNTokenType.BTC_SAT:
                this.wallet.btcSats += amount;
                break;
        }
        this.GrantTokenItem(tokenType, amount);
        Game.GetUISystem().ShowNotification("+" + IntToString(amount) + " " + this.TokenName(tokenType) + " — " + reason, "legendary");
        LogInfo("[TokenEconomy] Grant " + IntToString(amount) + " " + this.TokenName(tokenType) + ": " + reason);
    }

    private final func GrantTokenItem(tokenType: EMSNTokenType, amount: Int32) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; }
        switch (tokenType) {
            case EMSNTokenType.SOUL_COIN:
                player.AddItem("Items.Token_Soul_Coin");
                break;
            case EMSNTokenType.CHAOS:
                player.AddItem("Items.Token_Chaos");
                break;
            case EMSNTokenType.LILITH:
                player.AddItem("Items.Token_Lilith");
                break;
            case EMSNTokenType.BTC_SAT:
                player.AddItem("Items.Token_BTC_Sat");
                break;
        }
    }

    private final func TokenName(tokenType: EMSNTokenType) -> String {
        switch (tokenType) {
            case EMSNTokenType.SOUL_COIN: return "Soul Coins";
            case EMSNTokenType.CHAOS: return "Chaos";
            case EMSNTokenType.LILITH: return "Lilith";
            case EMSNTokenType.BTC_SAT: return "BTC sats";
            default: return "Token";
        }
    }

    public final func OnNessieSighting(tier: Int32) -> Void {
        let sc: Int32 = 7 + tier * 13;
        let chaos: Int32 = 1 + tier / 2;
        this.GrantToken(EMSNTokenType.SOUL_COIN, sc, "Nessie sighting Tier " + IntToString(tier));
        this.GrantToken(EMSNTokenType.CHAOS, chaos, "Lochness entropy pulse");
        if (tier >= 3) {
            this.GrantToken(EMSNTokenType.LILITH, 1, "Deep Kin resonance");
        }
        if (tier >= 4) {
            this.SyncFromLochness();
        }
    }

    public final func OnVexChaosInjection() -> Void {
        this.GrantToken(EMSNTokenType.CHAOS, 1, "Vex Fragment — NGD reroll");
        this.SyncFromLochness();
    }

    public final func OnLilithEmergence() -> Void {
        this.GrantToken(EMSNTokenType.LILITH, 13, "Lilith emergence — sovereign currency minted");
    }

    public final func OnCampaignActAdvance(act: Int32) -> Void {
        this.GrantToken(EMSNTokenType.SOUL_COIN, act * 50, "Act " + IntToString(act) + " progression");
        if (act >= 3) {
            this.GrantToken(EMSNTokenType.CHAOS, act - 2, "Campaign chaos accrual");
        }
        if (act >= 5) {
            this.GrantToken(EMSNTokenType.LILITH, 1, "Act " + IntToString(act) + " Lilith covenant");
            Game.GetQuestSystem().SetFact("msn_nessie_tier2", true);
        }
        if (act >= 3) {
            Game.GetQuestSystem().SetFact("msn_nessie_tier1", true);
        }
    }

    public final func OnProcgenContractPayout(soulCoins: Int32) -> Void {
        this.GrantToken(EMSNTokenType.SOUL_COIN, soulCoins, "ProcGen contract settlement");
        let btcGrant: Int32 = CastInt32(Cast<Float>(soulCoins) * this.satsPerSoulCoin);
        if (btcGrant > 0) {
            this.GrantToken(EMSNTokenType.BTC_SAT, btcGrant, "Lochness BTC bridge");
        }
    }

    public final func Exchange(fromType: EMSNTokenType, toType: EMSNTokenType, amount: Int32) -> String {
        if (amount <= 0) { return "Exchange amount must be positive."; }
        if (!this.CanAfford(fromType, amount)) {
            return "Insufficient " + this.TokenName(fromType) + " balance.";
        }
        let received: Int32 = this.CalculateExchange(fromType, toType, amount);
        if (received <= 0) { return "Exchange rate yields zero — try a larger amount."; }
        this.Deduct(fromType, amount);
        this.GrantToken(toType, received, "Loch Exchange swap");
        return "Exchanged " + IntToString(amount) + " " + this.TokenName(fromType) +
               " → " + IntToString(received) + " " + this.TokenName(toType);
    }

    private final func CanAfford(tokenType: EMSNTokenType, amount: Int32) -> Bool {
        switch (tokenType) {
            case EMSNTokenType.SOUL_COIN: return this.wallet.soulCoins >= amount;
            case EMSNTokenType.CHAOS: return this.wallet.chaosTokens >= amount;
            case EMSNTokenType.LILITH: return this.wallet.lilithTokens >= amount;
            case EMSNTokenType.BTC_SAT: return this.wallet.btcSats >= amount;
            default: return false;
        }
    }

    private final func Deduct(tokenType: EMSNTokenType, amount: Int32) -> Void {
        switch (tokenType) {
            case EMSNTokenType.SOUL_COIN: this.wallet.soulCoins -= amount; break;
            case EMSNTokenType.CHAOS: this.wallet.chaosTokens -= amount; break;
            case EMSNTokenType.LILITH: this.wallet.lilithTokens -= amount; break;
            case EMSNTokenType.BTC_SAT: this.wallet.btcSats -= amount; break;
        }
    }

    private final func CalculateExchange(fromType: EMSNTokenType, toType: EMSNTokenType, amount: Int32) -> Int32 {
        let soulEquiv: Float = this.ToSoulCoinEquiv(fromType, amount);
        return this.FromSoulCoinEquiv(toType, soulEquiv);
    }

    private final func ToSoulCoinEquiv(tokenType: EMSNTokenType, amount: Int32) -> Float {
        switch (tokenType) {
            case EMSNTokenType.SOUL_COIN: return Cast<Float>(amount);
            case EMSNTokenType.CHAOS: return Cast<Float>(amount) * this.soulCoinsPerChaos;
            case EMSNTokenType.LILITH: return Cast<Float>(amount) * this.soulCoinsPerChaos * this.chaosPerLilith;
            case EMSNTokenType.BTC_SAT: return Cast<Float>(amount) / this.satsPerSoulCoin;
            default: return 0.0;
        }
    }

    private final func FromSoulCoinEquiv(tokenType: EMSNTokenType, soulEquiv: Float) -> Int32 {
        switch (tokenType) {
            case EMSNTokenType.SOUL_COIN: return CastInt32(soulEquiv);
            case EMSNTokenType.CHAOS: return CastInt32(soulEquiv / this.soulCoinsPerChaos);
            case EMSNTokenType.LILITH: return CastInt32(soulEquiv / (this.soulCoinsPerChaos * this.chaosPerLilith));
            case EMSNTokenType.BTC_SAT: return CastInt32(soulEquiv * this.satsPerSoulCoin);
            default: return 0;
        }
    }

    public final func SyncFromLochness() -> Void {
        if (this.syncPending) {
            Game.GetUISystem().ShowNotification("Token sync already in flight...", "info");
            return;
        }
        this.syncPending = true;
        let http: ref<HttpClient> = Game.GetHttpClient();
        if (!IsDefined(http)) {
            this.syncPending = false;
            Game.GetUISystem().ShowNotification("[TokenEconomy] HTTP unavailable — local ledger only.", "warning");
            return;
        }
        let request: ref<UrlRequest> = new UrlRequest();
        request.url = this.tokenBridgeUrl + "/sync-tokens";
        request.method = "POST";
        request.headers.PushBack("Content-Type: application/json");
        request.body = "{}";
        request.callback = this, n"OnTokenSyncResponse";
        HttpRequest.Request(request);
        Game.GetUISystem().ShowNotification("Syncing Lochness BTC → NSSP ledger...", "info");
    }

    protected cb func OnTokenSyncResponse(response: ref<HttpResponse>) -> Bool {
        this.syncPending = false;
        if (response.code != 200) {
            Game.GetUISystem().ShowNotification("[TokenEconomy] Lochness bridge offline (HTTP " + IntToString(response.code) + ")", "warning");
            return true;
        }
        let d: JsonObject = JsonObject.FromString(response.body);
        this.wallet.btcUsdPrice = d.GetFloat("btc_usd", 0.0);
        this.wallet.lochnessOnline = d.GetBool("lochness_online", false);
        this.wallet.nsspSynced = true;
        this.wallet.lastSyncTime = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());

        let btcGrant: Int32 = d.GetInt("btc_sats_grant", 0);
        if (btcGrant > 0) {
            this.GrantToken(EMSNTokenType.BTC_SAT, btcGrant, "Lochness Nessie-Prime sync");
        }

        let chaosPulse: Int32 = d.GetInt("chaos_pulse", 0);
        if (chaosPulse > 0) {
            this.GrantToken(EMSNTokenType.CHAOS, chaosPulse, "Market volatility — Nessie-Arbitrage");
        }

        Game.GetUISystem().ShowNotification(
            "NSSP synced | BTC $" + FloatToString(this.wallet.btcUsdPrice) +
            " | Lochness " + (this.wallet.lochnessOnline ? "ONLINE" : "OFFLINE"),
            "legendary"
        );
        return true;
    }

    public final func OnGameplayEvent(event: String, context: String) -> Void {
        if (StrContains(context, "NPCDeath") || StrContains(event, "NPCDeath")) {
            this.GrantToken(EMSNTokenType.CHAOS, 1, "combat entropy");
        }
        if (StrContains(context, "quest")) {
            this.GrantToken(EMSNTokenType.LILITH, 1, "narrative resonance");
        }
    }

    public final func ParseTokenType(name: String) -> EMSNTokenType {
        let lower: String = name.Lower();
        if (StrContains(lower, "btc") || StrContains(lower, "satoshi") || StrContains(lower, "sat")) {
            return EMSNTokenType.BTC_SAT;
        }
        if (StrContains(lower, "chaos")) { return EMSNTokenType.CHAOS; }
        if (StrContains(lower, "lilith")) { return EMSNTokenType.LILITH; }
        if (StrContains(lower, "soul")) { return EMSNTokenType.SOUL_COIN; }
        return EMSNTokenType.SOUL_COIN;
    }
}

// ─── Console Commands ───

[ConsoleCommand("msn.tokens.status", "Show NSSP token economy wallet status")]
public static final func Cmd_TokensStatus(args: array<String>) -> Void {
    LogInfo(MSNTokenEconomy.GetInstance().GetStatusReport());
}

[ConsoleCommand("msn.tokens.sync", "Sync BTC/Chaos from Lochness Monster bots")]
public static final func Cmd_TokensSync(args: array<String>) -> Void {
    MSNTokenEconomy.GetInstance().SyncFromLochness();
}

[ConsoleCommand("msn.tokens.grant", "Grant tokens: msn.tokens.grant <soul|chaos|lilith|btc> <amount>")]
public static final func Cmd_TokensGrant(args: array<String>) -> Void {
    if (ArraySize(args) < 2) { return; }
    let econ: ref<MSNTokenEconomy> = MSNTokenEconomy.GetInstance();
    let tokenType: EMSNTokenType = econ.ParseTokenType(args[0]);
    let amount: Int32 = StringToInt(args[1]);
    econ.GrantToken(tokenType, amount, "debug grant");
}

[ConsoleCommand("msn.tokens.exchange", "Exchange tokens: msn.tokens.exchange <from> <to> <amount>")]
public static final func Cmd_TokensExchange(args: array<String>) -> Void {
    if (ArraySize(args) < 3) { return; }
    let econ: ref<MSNTokenEconomy> = MSNTokenEconomy.GetInstance();
    let fromType: EMSNTokenType = econ.ParseTokenType(args[0]);
    let toType: EMSNTokenType = econ.ParseTokenType(args[1]);
    let amount: Int32 = StringToInt(args[2]);
    LogInfo(econ.Exchange(fromType, toType, amount));
}