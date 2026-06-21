// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
// Sephirotic Court Seal — Keter | desktop/cp2077_mods/msn_neon_zealots_ambush.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnNeonZealotsAmbush | Keter | agent=Lucifer
module MsnIntegration.NeonZealotsAmbush

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
    wrappedMethod();
    
    // Initialize the Neon Zealot Ambush Ticker
    let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
    let tickRequest: ref<NeonZealotAmbushTick> = new NeonZealotAmbushTick();
    tickRequest.player = this;
    tickRequest.lastPosition = this.GetWorldPosition();
    
    // Check every 10 seconds
    delaySystem.DelayCallback(tickRequest, 10.0, false);
}

class NeonZealotAmbushTick extends DelayCallback {
    public let player: wref<PlayerPuppet>;
    public let lastPosition: Vector4;

    public func Call() -> Void {
        if !IsDefined(this.player) {
            return;
        }

        let game: GameInstance = this.player.GetGame();
        let currentPos: Vector4 = this.player.GetWorldPosition();
        
        // Calculate distance moved to verify the player is actively moving through the world
        let distanceMoved: Float = Vector4.Distance(currentPos, this.lastPosition);
        
        // We evaluate movement to prevent spawning on AFK players
        if distanceMoved > 5.0 {
            // In a full implementation we query TweakDB for the exact current district (e.g., t"Districts.SantoDomingo")
            // Here we use a random chance simulating the Santo Domingo spawn rate (approx. 5% chance per 10s of movement)
            if RandRangeF(0.0, 100.0) < 5.0 { 
                this.TriggerAmbush(game, currentPos);
            }
        }

        // Re-queue next tick
        let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(game);
        let nextTick: ref<NeonZealotAmbushTick> = new NeonZealotAmbushTick();
        nextTick.player = this.player;
        nextTick.lastPosition = currentPos;
        delaySystem.DelayCallback(nextTick, 10.0, false);
    }

    private func TriggerAmbush(game: GameInstance, centerPos: Vector4) -> Void {
        // Spawn 10 to 15 enemies
        let count: Int32 = RandRange(10, 16);
        let i: Int32 = 0;
        
        let dynamicEntitySystem: ref<DynamicEntitySystem> = GameInstance.GetDynamicEntitySystem(game);
        
        while i < count {
            let spawnPos: Vector4 = centerPos;
            
            // Scatter enemies in a 15-30m radius around the player
            let radius: Float = RandRangeF(15.0, 30.0);
            let angle: Float = RandRangeF(0.0, 360.0);
            
            spawnPos.X += radius * CosF(angle);
            spawnPos.Y += radius * SinF(angle);
            
            let transform: Transform;
            Transform.SetPosition(transform, spawnPos);
            
            // Spawning our custom MSN Neon Zealot TweakDB ID
            let enemyID: TweakDBID = t"Character.msn_neon_zealot_grunt";
            
            // Execute spawn request
            dynamicEntitySystem.SpawnEntity(enemyID, transform);
            
            i += 1;
        }
    }
}
