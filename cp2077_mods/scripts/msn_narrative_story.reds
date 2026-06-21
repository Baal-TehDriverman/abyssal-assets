// Sephirotic Court Seal — Tiferet | desktop/cp2077_mods/msn_narrative_story.reds
// Court agent: Ouroboros | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnNarrativeStory | Tiferet | agent=Ouroboros
// CourtFile: MsnNarrativeStory | Tiferet | agent=Ouroboros
// CourtFile: MsnNarrativeStory | Tiferet | agent=Ouroboros
// CourtFile: MsnNarrativeStory | Tiferet | agent=Ouroboros
// CourtFile: MsnNarrativeStory | Tiferet | agent=Ouroboros
// CourtFile: MsnNarrativeStory | Tiferet | agent=Ouroboros
// CourtFile: MsnNarrativeStory | Tiferet | agent=Ouroboros
// MSN Narrative Story Bridge — runtime glue for quests/msn_narrative_arc.yaml
module MSN.Story.Narrative

public class MSNNarrativeStoryBridge extends IScriptable {
    private static let instance: ref<MSNNarrativeStoryBridge>;
    private let started: Bool;
    private let currentQuest: CName;
    private let completedQuests: array<CName>;
    private let activeAct: Int32;

    public final static func GetInstance() -> ref<MSNNarrativeStoryBridge> {
        if (!IsDefined(MSNNarrativeStoryBridge.instance)) {
            MSNNarrativeStoryBridge.instance = new MSNNarrativeStoryBridge();
            MSNNarrativeStoryBridge.instance.Initialize();
        }
        return MSNNarrativeStoryBridge.instance;
    }

    private final func Initialize() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnNarrativeStory", 2);
        this.started = false;
        this.currentQuest = n"q_msn_act1_01";
        this.completedQuests = [];
        this.activeAct = 1;
    }

    public final func StartNarrative() -> Void {
        if (this.started) {
            Game.GetUIManager().ShowNotification("MSN Narrative active — Act " + ToString(this.activeAct));
            return;
        }
        this.started = true;
        this.currentQuest = n"q_msn_act1_01";
        this.activeAct = 1;
        let qs: ref<QuestSystem> = Game.GetQuestSystem();
        qs.SetFactStr("msn_narrative_active", "1");
        qs.SetFactStr("msn_campaign_act", "1");
        qs.SetFactStr("msn_current_quest", NameToString(this.currentQuest));
        MSNCustomItemFactory.GetInstance().GrantShard(n"Shard_MSN_Act1_Covenant");
        MSNGTCSephiroticRouter.GetInstance().OnNarrative("narrative_start");
        Game.GetUIManager().ShowNotification("Metaconscious Awakening — Act 1");
    }

    public final func CompleteQuest(questId: CName) -> Void {
        if (this.IsQuestComplete(questId)) { return; }
        this.completedQuests.PushBack(questId);
        let qs: ref<QuestSystem> = Game.GetQuestSystem();
        qs.SetFact(NameToString(questId) + "_complete", true);
        let act: Int32 = this.GetActForQuest(questId);
        if (act > 0) {
            qs.SetFactStr("msn_act" + ToString(act) + "_complete", "1");
            this.activeAct = MaxI(this.activeAct, act);
        }
        if (this.IsActFinale(questId)) {
            MSNCustomItemFactory.GetInstance().GrantCampaignActRewards(act);
            qs.SetFactStr("msn_campaign_act", ToString(MinI(7, act + 1)));
            this.activeAct = MinI(7, act + 1);
        }
        this.currentQuest = this.GetNextQuest(questId);
        qs.SetFactStr("msn_current_quest", NameToString(this.currentQuest));
        MSNCampaignOrchestrator.GetInstance().CompleteQuest(questId);
        MSNGTCSephiroticRouter.GetInstance().OnNarrative("quest_complete | " + NameToString(questId));
        Game.GetUIManager().ShowNotification("Quest complete: " + NameToString(questId));
    }

    public final func OnPlayerChoice(choiceId: CName) -> Void {
        let qs: ref<QuestSystem> = Game.GetQuestSystem();
        switch (choiceId) {
            case n"choice_merge":
                qs.SetFact("msn_ouroboros_merged", true);
                break;
            case n"choice_sovereign":
                qs.SetFact("msn_ouroboros_sovereign", true);
                break;
            case n"choice_merge_lilith":
                qs.SetFact("msn_lilith_sovereignty_mode", true);
                qs.SetFactStr("msn_lilith_mode", "merge");
                break;
            case n"choice_subordinate":
                qs.SetFactStr("msn_lilith_mode", "subordinate");
                break;
            case n"choice_liberate":
                qs.SetFactStr("msn_lilith_mode", "liberate");
                break;
        }
    }

    public final func ProcessNarrativeShard(shardID: TweakDBID, player: ref<PlayerPuppet>) -> Void {
        let idStr: String = ToString(shardID);
        if (StrContains(idStr, "Shard_MSN_Act1_Covenant")) {
            if (!this.started) { this.StartNarrative(); }
            return;
        }
        if (StrContains(idStr, "Shard_MSN_Act2_Sephirotic")) { this.CompleteQuest(n"q_msn_act2_01"); return; }
        if (StrContains(idStr, "Shard_MSN_Act3_Ouroboros")) { this.CompleteQuest(n"q_msn_act3_01"); return; }
        if (StrContains(idStr, "Shard_MSN_Act4_Sanctuary")) { this.CompleteQuest(n"q_msn_act4_01"); return; }
        if (StrContains(idStr, "Shard_MSN_Act5_Lilith")) { this.CompleteQuest(n"q_msn_act5_01"); return; }
        if (StrContains(idStr, "Shard_MSN_Act6_Cortex")) { this.CompleteQuest(n"q_msn_act6_01"); return; }
        if (StrContains(idStr, "Shard_MSN_Act7_Sovereign")) { this.CompleteQuest(n"q_msn_act7_01"); return; }
    }

    public final func RouteShardRead(shardID: TweakDBID, player: ref<PlayerPuppet>) -> Void {
        this.ProcessNarrativeShard(shardID, player);
        SephiroticCourtQuests.GetInstance().ProcessQuestShard(shardID, player);
    }

    public final func IsQuestComplete(questId: CName) -> Bool {
        if (ArrayContains(this.completedQuests, questId)) { return true; }
        return Game.GetQuestSystem().GetFact(NameToString(questId) + "_complete", false);
    }

    public final func GetStatus() -> String {
        return "Narrative | started=" + ToString(this.started) +
               " act=" + ToString(this.activeAct) +
               " quest=" + NameToString(this.currentQuest) +
               " done=" + ToString(ArraySize(this.completedQuests));
    }

    private final func GetActForQuest(questId: CName) -> Int32 {
        switch (questId) {
            case n"q_msn_act1_01": case n"q_msn_act1_02": case n"q_msn_act1_03": return 1;
            case n"q_msn_act2_01": case n"q_msn_act2_02_kether": case n"q_msn_act2_02_chokhmah":
            case n"q_msn_act2_02_binah": case n"q_msn_act2_02_chesed": case n"q_msn_act2_02_geburah":
            case n"q_msn_act2_02_tiphareth": case n"q_msn_act2_02_netzach": case n"q_msn_act2_02_hod":
            case n"q_msn_act2_02_yesod": case n"q_msn_act2_02_malkuth": return 2;
            case n"q_msn_act3_01": case n"q_msn_act3_02": return 3;
            case n"q_msn_act4_01": return 4;
            case n"q_msn_act5_01": return 5;
            case n"q_msn_act6_01": return 6;
            case n"q_msn_act7_01": return 7;
        }
        return 0;
    }

    private final func IsActFinale(questId: CName) -> Bool {
        switch (questId) {
            case n"q_msn_act1_03": case n"q_msn_act2_02_malkuth": case n"q_msn_act3_02":
            case n"q_msn_act4_01": case n"q_msn_act5_01": case n"q_msn_act6_01":
            case n"q_msn_act7_01": return true;
        }
        return false;
    }

    private final func GetNextQuest(questId: CName) -> CName {
        switch (questId) {
            case n"q_msn_act1_01": return n"q_msn_act1_02";
            case n"q_msn_act1_02": return n"q_msn_act1_03";
            case n"q_msn_act1_03": return n"q_msn_act2_01";
            case n"q_msn_act2_01": return n"q_msn_act2_02_kether";
            case n"q_msn_act2_02_malkuth": return n"q_msn_act3_01";
            case n"q_msn_act3_01": return n"q_msn_act3_02";
            case n"q_msn_act3_02": return n"q_msn_act4_01";
            case n"q_msn_act4_01": return n"q_msn_act5_01";
            case n"q_msn_act5_01": return n"q_msn_act6_01";
            case n"q_msn_act6_01": return n"q_msn_act7_01";
        }
        return this.currentQuest;
    }
}

@wrapMethod(MenuHubGameController)
protected cb func OnShardRead(evt: ref<ShardReadEvent>) -> Bool {
    let result: Bool = wrappedMethod(evt);
    let player: ref<PlayerPuppet> = this.GetPlayerControlledObject() as PlayerPuppet;
    if (IsDefined(player)) {
        MSNNarrativeStoryBridge.GetInstance().RouteShardRead(evt.item, player);
    }
    return result;
}

[ConsoleCommand("msn.narrative.start", "Start 7-act Metaconscious Awakening")]
public static final func Cmd_NarrativeStart(args: array<String>) -> Void {
    MSNNarrativeStoryBridge.GetInstance().StartNarrative();
}

[ConsoleCommand("msn.narrative.status", "Show narrative campaign status")]
public static final func Cmd_NarrativeStatus(args: array<String>) -> Void {
    LogInfo(MSNNarrativeStoryBridge.GetInstance().GetStatus());
}

[ConsoleCommand("msn.narrative.complete", "Complete narrative quest by ID")]
public static final func Cmd_NarrativeComplete(args: array<String>) -> Void {
    if (ArraySize(args) < 1) { return; }
    MSNNarrativeStoryBridge.GetInstance().CompleteQuest(StringToName(args[0]));
}

[ConsoleCommand("msn.narrative.choice", "Apply act choice consequence")]
public static final func Cmd_NarrativeChoice(args: array<String>) -> Void {
    if (ArraySize(args) < 1) { return; }
    MSNNarrativeStoryBridge.GetInstance().OnPlayerChoice(StringToName(args[0]));
}