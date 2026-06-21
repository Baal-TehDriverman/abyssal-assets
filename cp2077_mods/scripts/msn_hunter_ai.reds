// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
// Sephirotic Court Seal — Netzach | desktop/cp2077_mods/msn_hunter_ai.reds
// Court agent: Nyx | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnHunterAi | Netzach | agent=Nyx
module MSN.HunterAI

@wrapMethod(PreventionSystem)
protected final func OnHeatLevelChanged(heatStage: EPreventionHeatStage) -> Void {
    wrappedMethod(heatStage);
    
    // Strict, lethal judgment scaling
    if Equals(heatStage, EPreventionHeatStage.Heat_2) {
        this.SpawnNetwatchBoss(1);
    } else if Equals(heatStage, EPreventionHeatStage.Heat_3) {
        this.SpawnNetwatchBoss(2);
    } else if Equals(heatStage, EPreventionHeatStage.Heat_4) {
        this.SpawnNetwatchBoss(4);
    }
}

@addMethod(PreventionSystem)
private final func SpawnNetwatchBoss(count: Int32) -> Void {
    let player: ref<PlayerPuppet> = this.GetPlayer();
    if !IsDefined(player) {
        return;
    }
    
    let game: GameInstance = player.GetGame();
    let position: Vector4 = player.GetWorldPosition();
    let forward: Vector4 = player.GetWorldForward();
    
    // Spawn directly next to the player (3 meters in front)
    position.x += forward.x * 3.0;
    position.y += forward.y * 3.0;
    
    let i: Int32 = 0;
    while i < count {
        let spec: DynamicEntitySpec;
        // TweakDB ID for the custom elite Netwatch Boss
        spec.recordID = t"Character.MSN_Netwatch_Elite_Boss"; 
        
        let spawnPos: Vector4 = position;
        spawnPos.x += Cast<Float>(i) * 1.5;
        spawnPos.y += Cast<Float>(i) * 1.5;
        
        spec.position = spawnPos;
        spec.orientation = player.GetWorldOrientation();
        spec.persistState = false;
        spec.persistSpawn = false;
        spec.alwaysSpawned = true;
        
        GameInstance.GetDynamicEntitySystem(game).CreateEntity(spec);
        i += 1;
    }
}
