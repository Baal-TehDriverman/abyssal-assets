// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
// Sephirotic Court Seal — Chesed | desktop/cp2077_mods/msn_crypto_wallet.reds
// Court agent: Thoth | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnCryptoWallet | Chesed | agent=Thoth
module MSN.CryptoWallet

@wrapMethod(PlayerPuppet)
protected cb func OnAction(action: ref<Action>, consumer: ref<ActionConsumer>) -> Bool {
    let actionName: CName = ListenerAction.GetName(action);
    let actionType: gameinputActionType = ListenerAction.GetType(action);

    // "Vision" is the action name for toggling the scanner / focus mode in Cyberpunk 2077
    if Equals(actionName, n"Vision") && Equals(actionType, gameinputActionType.BUTTON_PRESSED) {
        this.ShowAbyssalBalanceNotification();
    }
    
    return wrappedMethod(action, consumer);
}

@addMethod(PlayerPuppet)
public func ShowAbyssalBalanceNotification() -> Void {
    let msg: SimpleScreenMessage;
    msg.isShown = true;
    msg.duration = 4.0;
    
    // Fetches live real-time balances from the local MSN Token Economy ledger
    let wallet: ref<MSNTokenWallet> = MSNTokenEconomy.GetInstance().GetWallet();
    msg.message = "MSN SYNC | Soul Coins: " + IntToString(wallet.soulCoins) + " SC | Chaos: " + IntToString(wallet.chaosTokens) + " | Lilith: " + IntToString(wallet.lilithTokens);
    
    let bbSystem: ref<BlackboardSystem> = GameInstance.GetBlackboardSystem(this.GetGame());
    let bb: ref<IBlackboard> = bbSystem.Get(GetAllBlackboardDefs().UI_Notifications);
    
    if IsDefined(bb) {
        bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
    }
}
