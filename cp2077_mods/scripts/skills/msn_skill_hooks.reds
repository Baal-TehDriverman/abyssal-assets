// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Abyssal Skill Hooks - Dynamically integrates the 24-skill system into vanilla Cyberpunk events

// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
// Sephirotic Court Seal — Keter | desktop/cp2077_mods/msn_skill_hooks.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnSkillHooks | Keter | agent=Lucifer
@wrapMethod(ScriptedPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    let player = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if IsDefined(player) && evt.instigator == player {
        // Grant Abyssal XP for Hunting when the player gets a kill
        let context = SXPContext(1.0, false, 1);
        if IsDefined(MSNAbyssalSkillSystemInstance) {
            MSNAbyssalSkillSystemInstance.GrantSkillXP(player, "hunting", 50.0, context);
        }
    }
    
    return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    let result = wrappedMethod(action, consumer);
    
    if ListenerAction.GetName(action) == n"Quickhack" {
        // Grant Abyssal XP for Sonar Tuning (Void Runners) on Quickhack usage
        let context = SXPContext(1.0, false, 1);
        if IsDefined(MSNAbyssalSkillSystemInstance) {
            MSNAbyssalSkillSystemInstance.GrantSkillXP(this, "sonar_tuning", 30.0, context);
        }
    }
    
    return result;
}

@wrapMethod(CraftingSystem)
private final func ProcessCraftItem(request: ref<CraftItemRequest>) -> Void {
    wrappedMethod(request);
    
    let player = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if IsDefined(player) {
        // Grant Abyssal XP for Masterwork (Ouroboros) upon crafting completion
        let context = SXPContext(1.0, false, 1);
        if IsDefined(MSNAbyssalSkillSystemInstance) {
            MSNAbyssalSkillSystemInstance.GrantSkillXP(player, "masterwork", 75.0, context);
        }
    }
}

@wrapMethod(Vendor)
public final func CompleteTrade(player: ref<PlayerPuppet>, item: ref<gameItemData>, price: Int32, isBuy: Bool) -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnSkillHooks", 2);

    wrappedMethod(player, item, price, isBuy);
    
    if IsDefined(player) {
        // Grant Abyssal XP for Trading and Negotiation (Loch Smugglers) upon trade
        let profitXP = Cast<Float>(price) * 0.1;
        let context = SXPContext(1.0, false, 1);
        if IsDefined(MSNAbyssalSkillSystemInstance) {
            MSNAbyssalSkillSystemInstance.GrantSkillXP(player, "trading", profitXP, context);
            MSNAbyssalSkillSystemInstance.GrantSkillXP(player, "negotiation", 10.0, context);
        }
    }
}
