// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
// Sephirotic Court Seal — Binah | desktop/cp2077_mods/msn_abyssal_crafting.reds
// Court agent: Yeshua | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnAbyssalCrafting | Binah | agent=Yeshua
module MSN.Storylines.AbyssalCrafting

import MSN.Core.*
import MSN.Telemetry.*

public class AbyssalCraftingSystem extends IScriptable {
    private static let instance: ref<AbyssalCraftingSystem>;

    public final static func GetInstance() -> ref<AbyssalCraftingSystem> {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnAbyssalCrafting", 1);

        if (!IsDefined(AbyssalCraftingSystem.instance)) {
            AbyssalCraftingSystem.instance = new AbyssalCraftingSystem();
        }
        return AbyssalCraftingSystem.instance;
    }

    public final func ProcessAbyssalCraft(player: ref<PlayerPuppet>, itemID: ItemID, quality: gamedataQuality) -> Void {
        // Only trigger Abyssal Asset minting on Epic or Legendary crafts
        if quality == gamedataQuality.Legendary || quality == gamedataQuality.Epic {
            MSN_Log("Crafting", "High-tier item fabricated. Minting corresponding Abyssal Asset on the Loch Exchange.");
            
            // Send telemetry to the Python backend to register this item as a tradeable asset
            let itemStr = ToString(itemID);
            MSN_Log("Abyssal_Asset", "MINT_ASSET | Item: " + itemStr + " | Owner: Player_Syndicate");
            
            // Reward the player with Soul Coins for supplying the economy
            MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Crafting_Bounty | Value: 150_SC");
            
            // Visual feedback
            GameObjectEffectHelper.StartEffectEvent(player, n"hack_successful");
        }
    }
}

// Hook into the core crafting system
@wrapMethod(CraftingSystem)
private final func ProcessCraftItemRequest(request: ref<CraftItemRequest>) -> Void {
    // Let the vanilla game handle the actual inventory insertion
    wrappedMethod(request);
    
    let player = this.GetPlayer();
    if IsDefined(player) {
        // Fetch the quality of the item being crafted
        let itemRecord = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(request.itemToCraft));
        let qualityRecord = itemRecord.Quality();
        let quality = qualityRecord.Type();
        
        AbyssalCraftingSystem.GetInstance().ProcessAbyssalCraft(player, request.itemToCraft, quality);
    }
}
