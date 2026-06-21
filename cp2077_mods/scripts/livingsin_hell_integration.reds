// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
// Sephirotic Court Seal — Keter | desktop/cp2077_mods/livingsin_hell_integration.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: LivingsinHellIntegration | Keter | agent=Lucifer
module MSN.LivingSin.Hell
// Circle 7 (Violence) — Drowned Warden boss + Time Blade grant integration.

public class LivingSinHellIntegration extends IScriptable {
    private static let instance: ref<LivingSinHellIntegration>;
    private let drownedWardenDefeated: Bool;
    private let crownGranted: Bool;
    private let timeBladeGranted: Bool;

    public final static func GetInstance() -> ref<LivingSinHellIntegration> {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("LivingsinHellIntegration", 1);

        if (!IsDefined(LivingSinHellIntegration.instance)) {
            LivingSinHellIntegration.instance = new LivingSinHellIntegration();
        }
        return LivingSinHellIntegration.instance;
    }

    public final func OnCircle7Entered() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_drowned_warden_spawned", true);
        questSys.SetFact("msn_livingsin_circle7_active", true);
        Game.GetUIManager().ShowNotification("Circle 7: The Drowned Warden stirs beneath Phlegethon...");
        LogInfo("[LivingSin] Circle 7 Violence — Drowned Warden encounter armed.");
    }

    public final func OnDrownedWardenDefeated() -> Void {
        if (this.drownedWardenDefeated) {
            return;
        }
        this.drownedWardenDefeated = true;

        let player: ref<PlayerPuppet> = Game.GetPlayer();
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        if (!IsDefined(player)) {
            return;
        }

        questSys.SetFact("msn_hell_drowned_warden_defeated", true);
        questSys.SetFact("msn_hell_key_drowned_warden", true);

        if (!player.HasItem("Items.CrownOfLivingSin")) {
            player.AddItem("Items.CrownOfLivingSin", 1);
            this.crownGranted = true;
            Game.GetUIManager().ShowNotification("Crown of Living Sin acquired from the Drowned Warden.");
        }

        this.GrantTimeBlade(player);

        let hell: ref<HellCampaignManager> = HellCampaignManager.GetInstance();
        if (IsDefined(hell)) {
            hell.OnDrownedWardenCleared();
        }
    }

    public final func GrantTimeBlade(player: ref<PlayerPuppet>) -> Void {
        if (!IsDefined(player) || this.timeBladeGranted) {
            return;
        }
        if (!player.HasItem("Items.CrownOfLivingSin")) {
            LogWarning("[LivingSin] Crown required before Time Blade grant.");
            return;
        }

        if (!player.HasItem("Items.LivingSin_Time_Blade")) {
            player.AddItem("Items.LivingSin_Time_Blade", 1);
        }
        if (!player.HasItem("Items.LivingSin_TemporalPhase")) {
            player.AddItem("Items.LivingSin_TemporalPhase", 1);
        }
        if (!player.HasItem("Items.LivingSin_SinRecharge")) {
            player.AddItem("Items.LivingSin_SinRecharge", 1);
        }
        if (!player.HasItem("Items.LivingSin_ParadoxGuard")) {
            player.AddItem("Items.LivingSin_ParadoxGuard", 1);
        }

        this.timeBladeGranted = true;
        LogInfo("[LivingSin] Time Blade + mods granted after Drowned Warden.");
        Game.GetUIManager().ShowNotification("Living Sin Time Blade resonating with Circle 7 temporal bleed.");
    }

    public final func OnTimeBladeUsed(player: ref<PlayerPuppet>, timeOffset: Float) -> Void {
        let blade: ref<LivingSinTimeBlade> = player.GetEquippedWeapon() as LivingSinTimeBlade;
        if (IsDefined(blade)) {
            blade.ActivateTemporalPhase(timeOffset);
        }
    }

    public final func OnConfession(player: ref<PlayerPuppet>, confession: String) -> Void {
        let blade: ref<LivingSinTimeBlade> = player.GetEquippedWeapon() as LivingSinTimeBlade;
        if (IsDefined(blade)) {
            blade.AttemptConfessionalRecharge(confession);
        }
    }

    public final func GetStatus() -> String {
        return "LivingSin Hell | Warden: " + (this.drownedWardenDefeated ? "DEFEATED" : "ACTIVE") +
               " | Crown: " + (this.crownGranted ? "GRANTED" : "PENDING") +
               " | Blade: " + (this.timeBladeGranted ? "GRANTED" : "PENDING");
    }
}