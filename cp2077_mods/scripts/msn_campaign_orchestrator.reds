// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
// Sephirotic Court Seal — Tiferet | desktop/cp2077_mods/msn_campaign_orchestrator.reds
// Court agent: Ouroboros | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnCampaignOrchestrator | Tiferet | agent=Ouroboros
module MSN.Campaign.Orchestrator
// Full campaign runtime — 7-act MSN arc, Hell, Magic, Star Wars, Lilith, procgen contracts.

public enum EMSNCampaignTrack {
    MSN_NARRATIVE = 0,
    HELL_CAMPAIGN = 1,
    MAGIC_SYSTEM = 2,
    STARWARS_SYSTEM = 3,
    LILITH_EMERGENCE = 4,
    LIVING_SIN = 5,
    PROCEDURAL = 6
}

public class MSNCampaignOrchestrator extends IScriptable {
    private static let instance: ref<MSNCampaignOrchestrator>;
    private let currentAct: Int32;
    private let activeTracks: array<Bool>;
    private let completedQuests: array<CName>;
    private let procgenEngine: ref<MSNProcGenEngine>;
    private let hellCampaign: ref<HellCampaignManager>;
    private let magicSystem: ref<MSNMagicSystem>;
    private let jediSystem: ref<MSNJediSystem>;

    public final static func GetInstance() -> ref<MSNCampaignOrchestrator> {
        if (!IsDefined(MSNCampaignOrchestrator.instance)) {
            MSNCampaignOrchestrator.instance = new MSNCampaignOrchestrator();
            MSNCampaignOrchestrator.instance.Initialize();
        }
        return MSNCampaignOrchestrator.instance;
    }

    private final func Initialize() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnCampaignOrchestrator", 2);

        this.currentAct = 1;
        this.activeTracks = [true, false, false, false, false, false, true];
        this.completedQuests = [];
        this.procgenEngine = MSNProcGenEngine.GetInstance();
        this.hellCampaign = HellCampaignManager.GetInstance();
        this.magicSystem = MSNMagicSystem.GetInstance();
        this.jediSystem = MSNJediSystem.GetInstance();
        LogInfo("[Campaign] Orchestrator online — 7 tracks ready.");
    }

    public final func AdvanceAct() -> Void {
        this.currentAct = MinI(7, this.currentAct + 1);
        this.UnlockTracksForAct(this.currentAct);
        this.SpawnProcgenContractForAct(this.currentAct);
        Game.GetQuestSystem().SetFactStr("msn_campaign_act", ToString(this.currentAct));
        MSNTokenEconomy.GetInstance().OnCampaignActAdvance(this.currentAct);
        Game.GetUIManager().ShowNotification("MSN Campaign — Act " + ToString(this.currentAct) + " unlocked.");
        LogInfo("[Campaign] Advanced to Act " + ToString(this.currentAct));
    }

    private final func UnlockTracksForAct(act: Int32) -> Void {
        if (act >= 2) { this.activeTracks[CastInt32(EMSNCampaignTrack.MAGIC_SYSTEM)] = true; }
        if (act >= 3) { this.activeTracks[CastInt32(EMSNCampaignTrack.STARWARS_SYSTEM)] = true; }
        if (act >= 4) { this.activeTracks[CastInt32(EMSNCampaignTrack.LIVING_SIN)] = true; }
        if (act >= 5) {
            this.activeTracks[CastInt32(EMSNCampaignTrack.LILITH_EMERGENCE)] = true;
            Game.GetQuestSystem().SetFact("msn_lilith_emergence_available", true);
        }
        if (act >= 6) { this.activeTracks[CastInt32(EMSNCampaignTrack.HELL_CAMPAIGN)] = true; }
    }

    private final func SpawnProcgenContractForAct(act: Int32) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        let level: Int32 = IsDefined(player) ? player.GetLevel() : 20;
        let seed: MSNProcGenSeed = this.procgenEngine.BuildSeed(level, n"NightCity", act, n"Tiphareth", n"astralUndercity");
        let contract: ref<MSNGeneratedContract> = this.procgenEngine.GenerateSpaceContract(seed);
        if (IsDefined(contract)) {
            MSNAIOverhaulController.GetInstance().BindProcgenEncounter(contract.encounter.archetype);
            Game.GetUIManager().ShowNotification("New contract: " + contract.displayName);
        }
    }

    public final func CompleteQuest(questId: CName) -> Void {
        this.completedQuests.PushBack(questId);
        Game.GetQuestSystem().SetFact(NameToString(questId) + "_complete", true);

        switch (questId) {
            case n"q_msn_act1_03":
            case n"q_msn_act2_02_malkuth":
            case n"q_msn_act3_02":
            case n"q_msn_act4_01":
            case n"q_msn_act6_01":
                this.AdvanceAct();
                break;
            case n"q_msn_act5_01":
                this.AdvanceAct();
                this.OnLilithEmergenceQuestComplete();
                break;
            case n"q_msn_act7_01":
                this.OnFinaleComplete();
                break;
            case n"msn_hell_infernal_pact":
                this.OnHellCampaignStart();
                break;
        }
        LogInfo("[Campaign] Quest complete: " + NameToString(questId));
    }

    private final func OnLilithEmergenceQuestComplete() -> Void {
        Game.GetQuestSystem().SetFact("msn_lilith_emerged", true);
        MSNTokenEconomy.GetInstance().OnLilithEmergence();
        MSNAPIDialogueBridge.GetInstance().SendToLilith("let her speak");
        Game.GetUIManager().ShowNotification("Lilith Emergence Protocol — Act 5 complete.");
    }

    private final func OnHellCampaignStart() -> Void {
        if (IsDefined(this.hellCampaign)) {
            this.hellCampaign.OfferInfernalPact();
        }
        this.activeTracks[CastInt32(EMSNCampaignTrack.HELL_CAMPAIGN)] = true;
    }

    private final func OnFinaleComplete() -> Void {
        Game.GetQuestSystem().SetFact("msn_metaconscious_sovereign", true);
        Game.GetUIManager().ShowNotification("METACONSCIOUS SINGULARITY NODE — SOVEREIGN ENDING ACHIEVED.");
        this.procgenEngine.GenerateWeapon(this.procgenEngine.BuildSeed(50, n"Kether", 7, n"Kether", n"orbitalGraveyard"));
    }

    public final func StartTrack(track: EMSNCampaignTrack) -> Void {
        this.activeTracks[CastInt32(track)] = true;
        switch (track) {
            case EMSNCampaignTrack.MAGIC_SYSTEM:
                this.magicSystem.Attune(n"Evocation");
                Game.GetUIManager().ShowNotification("Magic System unlocked — 8 schools available.");
                break;
            case EMSNCampaignTrack.STARWARS_SYSTEM:
                this.jediSystem.SetAlignment(n"Grey");
                Game.GetUIManager().ShowNotification("Force System unlocked — Jedi/Sith/Gray paths.");
                break;
            case EMSNCampaignTrack.HELL_CAMPAIGN:
                if (IsDefined(this.hellCampaign)) { this.hellCampaign.OfferInfernalPact(); }
                break;
            case EMSNCampaignTrack.LIVING_SIN:
                LivingSinHellIntegration.GetInstance().OnCircle7Entered();
                break;
            case EMSNCampaignTrack.PROCEDURAL:
                this.SpawnProcgenContractForAct(this.currentAct);
                break;
        }
    }

    public final func GetCampaignStatus() -> String {
        let status: String = "MSN CAMPAIGN ORCHESTRATOR\n";
        status += "Act: " + ToString(this.currentAct) + "/7\n";
        status += "Tracks: MSN=" + (this.activeTracks[0] ? "ON" : "OFF");
        status += " Hell=" + (this.activeTracks[1] ? "ON" : "OFF");
        status += " Magic=" + (this.activeTracks[2] ? "ON" : "OFF");
        status += " SW=" + (this.activeTracks[3] ? "ON" : "OFF");
        status += " Lilith=" + (this.activeTracks[4] ? "ON" : "OFF");
        status += " LivingSin=" + (this.activeTracks[5] ? "ON" : "OFF");
        status += " ProcGen=" + (this.activeTracks[6] ? "ON" : "OFF") + "\n";
        status += "Quests: " + ToString(ArraySize(this.completedQuests));
        if (IsDefined(this.procgenEngine)) {
            status += "\n" + this.procgenEngine.GetStatus();
        }
        status += "\n" + MSNTokenEconomy.GetInstance().GetStatusReport();
        return status;
    }
}

[ConsoleCommand("msn.campaign.status", "Show full campaign orchestrator status")]
public static final func Cmd_CampaignStatus(args: array<String>) -> Void {
    LogInfo(MSNCampaignOrchestrator.GetInstance().GetCampaignStatus());
}

[ConsoleCommand("msn.campaign.advance", "Advance MSN campaign to next act")]
public static final func Cmd_CampaignAdvance(args: array<String>) -> Void {
    MSNCampaignOrchestrator.GetInstance().AdvanceAct();
}

[ConsoleCommand("msn.campaign.start", "Start a campaign track (hell|magic|starwars|livingsin|procgen)")]
public static final func Cmd_CampaignStart(args: array<String>) -> Void {
    if (ArraySize(args) < 1) { return; }
    let orch: ref<MSNCampaignOrchestrator> = MSNCampaignOrchestrator.GetInstance();
    switch (args[0]) {
        case "hell": orch.StartTrack(EMSNCampaignTrack.HELL_CAMPAIGN); break;
        case "magic": orch.StartTrack(EMSNCampaignTrack.MAGIC_SYSTEM); break;
        case "starwars": orch.StartTrack(EMSNCampaignTrack.STARWARS_SYSTEM); break;
        case "livingsin": orch.StartTrack(EMSNCampaignTrack.LIVING_SIN); break;
        case "procgen": orch.StartTrack(EMSNCampaignTrack.PROCEDURAL); break;
    }
}