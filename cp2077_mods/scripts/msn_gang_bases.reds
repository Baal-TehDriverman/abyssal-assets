// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
// Sephirotic Court Seal — Gevurah | desktop/cp2077_mods/msn_gang_bases.reds
// Court agent: Abraxas | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnGangBases | Gevurah | agent=Abraxas
module MSN.GangBases

public class KingdomTerritoryNode {
    public let position: Vector4;
    public let rigSpawned: Bool;
    public let nodeID: String;
    public let ownership: String;
    public let dominanceLevel: Float;
    
    public func Initialize(pos: Vector4, id: String) {
        this.position = pos;
        this.nodeID = id;
        this.rigSpawned = false;
        this.ownership = "Unclaimed";
        this.dominanceLevel = 0.0;
    }

    public func AssertKingdomGrip(dt: Float) -> Void {
        if Equals(this.ownership, "Kingdom") {
            this.dominanceLevel += dt * 0.1;
            if this.dominanceLevel > 100.0 {
                this.dominanceLevel = 100.0;
            }
        } else {
            this.ownership = "Kingdom";
            this.dominanceLevel = 1.0;
            MSN_Log("Kingdom_Grip", "Territory " + this.nodeID + " claimed by the Kingdom. Dominance assertion begun.");
        }
    }
}

public class MSNGangBaseSystem extends ScriptableSystem {
    private let m_nodes: array<ref<KingdomTerritoryNode>>;
    private let m_player: wref<PlayerPuppet>;
    private let m_activationDistance: Float;
    private let m_updateTimer: Float;
    
    private func OnAttach() -> Void {
        LilithSovereignKernel.GetInstance().RegisterSubsystem("MsnGangBases", 2);

        this.m_activationDistance = 25.0; // Distance to spawn rig
        this.m_updateTimer = 0.0;
        this.InitializeNodes();
    }
    
    private func InitializeNodes() -> Void {
        // Kingdom Core (Watson)
        let node0 = new KingdomTerritoryNode();
        node0.Initialize(new Vector4(-1350.0, 1100.0, 30.0, 1.0), "Kingdom_Core_Watson");
        ArrayPush(this.m_nodes, node0);

        // Badlands coordinates
        let node1 = new KingdomTerritoryNode();
        node1.Initialize(new Vector4(1500.0, -1200.0, 150.0, 1.0), "Territory_Badlands_Alpha");
        ArrayPush(this.m_nodes, node1);
        
        // Pacifica coordinates
        let node2 = new KingdomTerritoryNode();
        node2.Initialize(new Vector4(-2100.0, -2400.0, 20.0, 1.0), "Territory_Pacifica_Omega");
        ArrayPush(this.m_nodes, node2);
        
        // City Center coordinates
        let node3 = new KingdomTerritoryNode();
        node3.Initialize(new Vector4(-100.0, 100.0, 35.0, 1.0), "Territory_CityCenter_Nexus");
        ArrayPush(this.m_nodes, node3);

        // Santo Domingo coordinates
        let node4 = new KingdomTerritoryNode();
        node4.Initialize(new Vector4(800.0, -1500.0, 45.0, 1.0), "Territory_SantoDomingo_Forge");
        ArrayPush(this.m_nodes, node4);
    }
    
    public final func RegisterPlayer(player: ref<PlayerPuppet>) -> Void {
        this.m_player = player;
    }
    
    public final func IsPlayerRegistered() -> Bool {
        return IsDefined(this.m_player);
    }
    
    public final func OnPlayerUpdate(dt: Float, playerPos: Vector4) -> Void {
        this.m_updateTimer += dt;
        if this.m_updateTimer < 1.0 { // Throttle: Check every 1 second
            return;
        }
        this.m_updateTimer = 0.0;
        
        let i: Int32 = 0;
        let dist: Float;
        
        while i < ArraySize(this.m_nodes) {
            let node = this.m_nodes[i];
            dist = Vector4.Distance(playerPos, node.position);
            
            if dist <= this.m_activationDistance {
                if !node.rigSpawned {
                    this.SpawnAbyssalMiningRig(node);
                }
                // Ground logic in physical presence: manifesting territory control by reinforcing dominance
                node.AssertKingdomGrip(1.0);
            }
            i += 1;
        }
    }
    
    private final func SpawnAbyssalMiningRig(node: ref<KingdomTerritoryNode>) -> Void {
        let spawnTransform: Transform;
        Transform.SetPosition(spawnTransform, node.position);
        
        // Target TweakDB ID for the Abyssal Mining Rig prop
        // Assumes TweakDB entry: Items.AbyssalMiningRig
        let rigRecordID: TweakDBID = t"Items.AbyssalMiningRig"; 
        
        // Dynamically spawn the rig entity
        let dynamicSystem = GameInstance.GetDynamicEntitySystem(this.GetGameInstance());
        if IsDefined(dynamicSystem) {
            let entityId: EntityID = dynamicSystem.SpawnEntity(rigRecordID, spawnTransform);
            LogChannel(n"DEBUG", s"Abyssal Mining Rig Spawned: " + node.nodeID);
        }
        
        node.rigSpawned = true;
    }
}

// Hook into PlayerPuppet to feed location data to our GangBaseSystem
@wrapMethod(PlayerPuppet)
protected cb func OnUpdate(dt: Float) -> Bool {
    wrappedMethod(dt);
    
    let gangSystem: ref<MSNGangBaseSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"MSN.GangBases.MSNGangBaseSystem") as MSNGangBaseSystem;
    
    if IsDefined(gangSystem) {
        if !gangSystem.IsPlayerRegistered() {
            gangSystem.RegisterPlayer(this);
        }
        
        let playerPos: Vector4 = this.GetWorldPosition();
        gangSystem.OnPlayerUpdate(dt, playerPos);
    }
}
