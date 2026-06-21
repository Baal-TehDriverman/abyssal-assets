// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
// Sephirotic Court Seal — Keter | desktop/cp2077_mods/msn_custom_item_factory.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnCustomItemFactory | Keter | agent=Lucifer
module MSN.Items.Factory
// Custom item factory — static catalog + procgen weapons, bios, hell items, crossover gear.

public class MSNCustomItemFactory extends IScriptable {
    private static let instance: ref<MSNCustomItemFactory>;
    private let catalogSize: Int32;
    private let grantedItems: array<CName>;

    public final static func GetInstance() -> ref<MSNCustomItemFactory> {
        if (!IsDefined(MSNCustomItemFactory.instance)) {
            MSNCustomItemFactory.instance = new MSNCustomItemFactory();
            MSNCustomItemFactory.instance.Initialize();
        }
        return MSNCustomItemFactory.instance;
    }

    private final func Initialize() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnCustomItemFactory", 2);

        this.catalogSize = 0;
        this.grantedItems = [];
        this.catalogSize = this.CountCatalogEntries();
        LogInfo("[ItemFactory] Catalog loaded — " + ToString(this.catalogSize) + " custom items.");
    }

    private final func CountCatalogEntries() -> Int32 {
        // Static catalog from TweakDB manifests
        return 500 + 69 + 40 + 26 + 12 + 10000; // hell + bios + magic + force + legendaries + hats
    }

    public final func GrantLegendaryWeapon(weaponId: CName) -> Bool {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return false; }

        switch (weaponId) {
            case n"Voidsplitter_Railgun":
            case n"Krakens_Wrath_Launcher":
            case n"Nyx_Whisper_Monowire":
            case n"Lucifers_Dawn_Pistol":
            case n"LivingSin_TimeBlade":
            case n"Sophias_Symphony_Cannon":
                player.AddItem(weaponId, 1);
                this.grantedItems.PushBack(weaponId);
                Game.GetUIManager().ShowNotification("Legendary acquired: " + NameToString(weaponId));
                return true;
        }
        return false;
    }

    public final func GrantCyberware(cyberwareId: CName) -> Bool {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            player.AddItem(cyberwareId, 1);
            this.grantedItems.PushBack(cyberwareId);
            Game.GetUIManager().ShowNotification("Cyberware acquired: " + NameToString(cyberwareId));
            return true;
        }
        return false;
    }

    public final func GrantClothing(clothingId: CName) -> Bool {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            player.AddItem(clothingId, 1);
            this.grantedItems.PushBack(clothingId);
            Game.GetUIManager().ShowNotification("Clothing acquired: " + NameToString(clothingId));
            return true;
        }
        return false;
    }

    public final func GrantQuickhack(hackId: CName) -> Bool {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            player.AddItem(hackId, 1);
            this.grantedItems.PushBack(hackId);
            Game.GetUIManager().ShowNotification("Quickhack acquired: " + NameToString(hackId));
            return true;
        }
        return false;
    }

    public final func GrantShard(shardId: CName) -> Bool {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            player.AddItem(shardId, 1);
            this.grantedItems.PushBack(shardId);
            Game.GetUIManager().ShowNotification("Shard acquired: " + NameToString(shardId));
            return true;
        }
        return false;
    }

    public final func GrantVehicle(vehicleId: CName) -> Bool {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            player.AddItem(vehicleId, 1);
            this.grantedItems.PushBack(vehicleId);
            Game.GetUIManager().ShowNotification("Vehicle unlocked: " + NameToString(vehicleId));
            return true;
        }
        return false;
    }

    public final func GrantHellCircleLoot(circle: Int32) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; }

        switch (circle) {
            case 1: player.AddItem(n"Hell_Limbo_Shroud", 1); break;
            case 4: player.AddItem(n"Hell_Greed_Coin", 1); break;
            case 5: player.AddItem(n"Hell_Wrath_Brand", 1); break;
            case 7:
                player.AddItem(n"Items.CrownOfLivingSin", 1);
                LivingSinHellIntegration.GetInstance().GrantTimeBlade(player);
                break;
            case 9: player.AddItem(n"Hell_Sovereign_Key", 1); break;
        }
        LogInfo("[ItemFactory] Hell Circle " + ToString(circle) + " loot granted.");
    }

    public final func GrantBiosUpgrade(biosId: CName, act: Int32) -> Bool {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        if (questSys.GetFact("msn_act" + ToString(act) + "_complete", false)) {
            let player: ref<PlayerPuppet> = Game.GetPlayer();
            if (IsDefined(player)) {
                player.AddItem(biosId, 1);
                this.grantedItems.PushBack(biosId);
                Game.GetUIManager().ShowNotification("Bios upgrade installed: " + NameToString(biosId));
                return true;
            }
        }
        return false;
    }

    public final func GrantProcgenWeapon() -> Void {
        let engine: ref<MSNProcGenEngine> = MSNProcGenEngine.GetInstance();
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        let level: Int32 = IsDefined(player) ? player.GetLevel() : 25;
        let seed: MSNProcGenSeed = engine.BuildSeed(level, n"Pacifica", 3, n"Geburah", n"pressureAbyss");
        let weapon: ref<MSNGeneratedWeapon> = engine.GenerateWeapon(seed);
        engine.GrantGeneratedWeaponToPlayer(weapon);
    }

    public final func GrantCampaignActRewards(act: Int32) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; }

        switch (act) {
            case 1: player.AddItem(n"Cyberdeck_MSN_Cerebellum", 1); break;
            case 2: this.GrantBiosUpgrade(n"Bios_Kether_Cortex_Array", 2); break;
            case 3:
                this.GrantLegendaryWeapon(n"Voidsplitter_Railgun");
                break;
            case 4: this.GrantLegendaryWeapon(n"Krakens_Wrath_Launcher"); break;
            case 5:
                this.GrantLegendaryWeapon(n"Nyx_Whisper_Monowire");
                player.AddItem(n"Item.Seyphirotic_Blade", 1);
                break;
            case 6: player.AddItem(n"Item.MSN_Smart_Gun", 1); break;
            case 7:
                this.GrantLegendaryWeapon(n"LivingSin_TimeBlade");
                this.GrantLegendaryWeapon(n"Sophias_Symphony_Cannon");
                this.GrantProcgenWeapon();
                break;
        }
        LogInfo("[ItemFactory] Act " + ToString(act) + " rewards granted.");
    }

    public final func GetCatalogSummary() -> String {
        return "Item Factory | Catalog: " + ToString(this.catalogSize) +
               " | Granted: " + ToString(ArraySize(this.grantedItems)) +
               " | Sources: hell_items, custom_weapons, bios, procgen, hats";
    }
}

[ConsoleCommand("msn.items.grant", "Grant legendary weapon (voidsplitter|kraken|nyx|lucifer|timesin)")]
public static final func Cmd_GrantItem(args: array<String>) -> Void {
    if (ArraySize(args) < 1) { return; }
    let factory: ref<MSNCustomItemFactory> = MSNCustomItemFactory.GetInstance();
    switch (args[0]) {
        case "voidsplitter": factory.GrantLegendaryWeapon(n"Voidsplitter_Railgun"); break;
        case "kraken": factory.GrantLegendaryWeapon(n"Krakens_Wrath_Launcher"); break;
        case "nyx": factory.GrantLegendaryWeapon(n"Nyx_Whisper_Monowire"); break;
        case "lucifer": factory.GrantLegendaryWeapon(n"Lucifers_Dawn_Pistol"); break;
        case "timesin": factory.GrantLegendaryWeapon(n"LivingSin_TimeBlade"); break;
        case "procgen": factory.GrantProcgenWeapon(); break;
        case "act":
            if (ArraySize(args) >= 2) {
                factory.GrantCampaignActRewards(StringToInt(args[1]));
            }
            break;
    }
}

[ConsoleCommand("msn.items.catalog", "Show custom item factory catalog status")]
public static final func Cmd_ItemCatalog(args: array<String>) -> Void {
    LogInfo(MSNCustomItemFactory.GetInstance().GetCatalogSummary());
}