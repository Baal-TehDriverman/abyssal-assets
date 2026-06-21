// Sephirotic Court Seal — Keter | desktop/cp2077_mods/skill_tree_registry.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: SkillTreeRegistry | Keter | agent=Lucifer
// CourtFile: SkillTreeRegistry | Keter | agent=Lucifer
// CourtFile: SkillTreeRegistry | Keter | agent=Lucifer
// CourtFile: SkillTreeRegistry | Keter | agent=Lucifer
// CourtFile: SkillTreeRegistry | Keter | agent=Lucifer
// CourtFile: SkillTreeRegistry | Keter | agent=Lucifer
// CourtFile: SkillTreeRegistry | Keter | agent=Lucifer
// AUTO-GENERATED — do not edit. Run tools/generate_cyberpunk_skill_trees.py
// Generated: 2026-06-21T07:16:16.425787+00:00

public class SkillTreeRegistry extends IScriptable {
    public const AbyssalSkillCount: Int32 = 24;
    public const AbyssalTreeCount: Int32 = 7;
    public const MSNWeaponTierCount: Int32 = 10;
    public const HermesCategoryCount: Int32 = 54;

    public final static func GetAbyssalTreeNames() -> array<String> {
        return {
            "Gathering (Malkuth)",
            "Processing (Yesod)",
            "Crafting (Hod)",
            "Knowledge (Binah)",
            "Social / Economic (Chesed)",
            "Combat / Survival (Geburah)",
            "Projection (Tiferet)",
        };
    }

    public final static func GetMSNPerkNames() -> array<String> {
        return {
            "MSN_DualBrain_Base",
            "MSN_SephiroticRouting",
            "MSN_OuroborosMemory",
            "MSN_SanctuaryThrottle",
            "MSN_SpeculativeExecution",
            "MSN_AkashicCompression",
            "MSN_LilithEmergence",
            "MSN_CloudCortexLink",
        };
    }

    public final static func GetWeaponTierSummary() -> array<String> {
        return {
            "Tier 1 Initiate: Budget Arms Scrap Bat",
            "Tier 2 Adept: Arasaka Oni Warhammer, Militech Breacher Sledge",
            "Tier 3 Expert: Kang Tao Dragon Mauls",
            "Tier 4 Master: Arasaka Seeker, Militech Homing Rifle",
            "Tier 5 Grandmaster: NGD Governor Smart-Gun, Militech Breach Shotgun",
            "Tier 6 Sovereign: Lyra Resonance Bow, Kang Tao Arc Rifle",
            "Tier 7 Transcendent: Ouroboros Loop-Blade",
            "Tier 8 Transcendent II: Lilith's Wrath",
            "Tier 9 Ascendant: Sephirot Multi-Form",
            "Tier 10 Omega: All weapons + Custom Crafting",
        };
    }

    public final static func GetHermesCategorySummary() -> array<String> {
        return {
            "metaconscious: 268 skills",
            "creative: 189 skills",
            "integration: 101 skills",
            "metaconscious-singularity-node: 46 skills",
            "cyberpunk-msn-integration: 40 skills",
            "mlops: 33 skills",
            "nvidia-gratitude-driver: 23 skills",
            "github: 21 skills",
            "research: 21 skills",
            "himalaya-email-swarm: 20 skills",
            "software-development: 20 skills",
            ".system: 16 skills",
            "game-development: 15 skills",
            "modding: 15 skills",
            "productivity: 14 skills",
            "autonomous-ai-agents: 12 skills",
            "metaconscious-dialogue-resonance-interface: 10 skills",
            "email: 8 skills",
            "apple: 6 skills",
            "business-analytics-swarm: 6 skills",
            "devops: 6 skills",
            "media: 6 skills",
            "linux-conversion: 5 skills",
            "market-system: 5 skills",
            "sephirotic-resonance-weaver: 5 skills",
            "abyssal-architecture: 4 skills",
            "cyberpunk-cnn: 4 skills",
            "lyra-integration: 4 skills",
            "antigravity-ingestion-bridge: 3 skills",
            "dogfood: 3 skills",
            "hermes-mcp-bridge: 3 skills",
            "hermes-skill-marketplace: 3 skills",
            "kairos-dream-system: 3 skills",
            "client-codebase: 2 skills",
            "cryptid-bestiary: 2 skills",
            "data-science: 2 skills",
            "external-worker-bridge: 2 skills",
            "frontier-cognitive-maps: 2 skills",
            "living-sin-gm: 2 skills",
            "note-taking: 2 skills",
            "ouroboros-agent-system: 2 skills",
            "ouroboros-autonomous-rnn: 2 skills",
            "scribe-ledger-system: 2 skills",
            "sephirotic-court-waves: 2 skills",
            "server-codebase: 2 skills",
            "skill-system: 2 skills",
            "smart-home: 2 skills",
            "social-media: 2 skills",
            "speculative-cerebellum: 2 skills",
            "swarm-orchestration: 2 skills",
            "yeshua-causality-gate: 2 skills",
            "contract-hunter: 1 skills",
            "new_skill.md: 1 skills",
            "yuanbao: 1 skills",
        };
    }
}
