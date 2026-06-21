import sys
import os

db_path = "/home/tehlappy/Desktop/AI/Pub/golem_diary.db"
if not os.path.exists(os.path.dirname(db_path)):
    print(f"Skipping DB write, path does not exist: {db_path}")
    sys.exit(0)

try:
    from concurrent_bidirectional_memory import BidirectionalMemoryEngine
    engine = BidirectionalMemoryEngine(
        db_path=db_path,
        forward_model="local:gemma-4",
        backward_model="local:deepseek",
        bridge_threshold=0.60
    )
    engine.record_step(
        environment_signature="msn_cp2077_mods",
        objective_vector="deploy_fully_sephirotic_court",
        forward_state="rewrote all 982 files using lilith_unify_cyberpunk",
        backward_state="permanent deployment by Thoth achieved via git commit"
    )
    print("Memory recorded successfully.")
except Exception as e:
    print(f"Failed to record memory: {e}")
