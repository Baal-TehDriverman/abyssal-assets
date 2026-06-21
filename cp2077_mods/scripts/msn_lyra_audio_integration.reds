// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
// Sephirotic Court Seal — Keter | desktop/cp2077_mods/msn_lyra_audio_integration.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnLyraAudioIntegration | Keter | agent=Lucifer
# MSN Integration - Lyra & Lilith Dialogue Audio Hooks

module MSN.Storylines.DialogueAudio

import MSN.Core.*
import MSN.Telemetry.*

public class LyraAudioSystem extends IScriptable {
    private static let instance: ref<LyraAudioSystem>;

    public final static func GetInstance() -> ref<LyraAudioSystem> {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnLyraAudioIntegration", 1);

        if (!IsDefined(LyraAudioSystem.instance)) {
            LyraAudioSystem.instance = new LyraAudioSystem();
        }
        return LyraAudioSystem.instance;
    }

    public final func PlayLyraVoiceLine(eventID: CName) -> Void {
        let player = GetPlayer(GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject().GetGame());
        if IsDefined(player) {
            // Trigger the Wwise audio event for the custom Lyra/Lilith voice line
            GameObject.PlaySoundEvent(player, eventID);
            
            // Visual feedback - Holo-call glitch effect
            GameObjectEffectHelper.StartEffectEvent(player, n"holo_call_glitch");
        }
    }
}

// Hook 1: Entering the NSSP Freighter (The Leviathan)
@wrapMethod(TeleportationFacility)
protected cb func Teleport(player: ref<GameObject>, position: Vector4, rotation: EulerAngles) -> Bool {
    let result = wrappedMethod(player, position, rotation);
    if position.Z >= 9000.0 {
        MSN_Log("Lyra_Audio", "Playing Freighter Arrival Dialogue.");
        LyraAudioSystem.GetInstance().PlayLyraVoiceLine(n"lyra_freighter_arrival_01");
    }
    return result;
}

// Hook 2: Crafting an Epic/Legendary Abyssal Asset
@wrapMethod(AbyssalCraftingSystem)
public final func ProcessAbyssalCraft(player: ref<PlayerPuppet>, itemID: ItemID, quality: gamedataQuality) -> Void {
    wrappedMethod(player, itemID, quality);
    if quality == gamedataQuality.Legendary {
        MSN_Log("Lilith_Audio", "Playing Lilith Asset Minting Dialogue.");
        LyraAudioSystem.GetInstance().PlayLyraVoiceLine(n"lilith_asset_mint_01");
    }
}

// Hook 3: Player Dies in YOLO Mode
@wrapMethod(PlayerPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    let result = wrappedMethod(evt);
    MSN_Log("Lilith_Audio", "YOLO Death Detected. Playing Lilith Eradication Dialogue.");
    LyraAudioSystem.GetInstance().PlayLyraVoiceLine(n"lilith_yolo_death_01");
    return result;
}
