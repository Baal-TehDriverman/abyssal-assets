// Sephirotic Court Seal — Malkuth | desktop/cp2077_mods/msn_skill_console.reds
// Court agent: Malkuth | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnSkillConsole | Malkuth | agent=Malkuth
// CourtFile: MsnSkillConsole | Malkuth | agent=Malkuth
// MSN Skill Console — Abyssal Arts 24-skill bridge
@addMethod(PlayerPuppet)
protected func RegisterMSNSkillConsoles() {
    RegisterConsoleCommand("msn.skill.status", "MSN skill status", n"msn_skill_status");
    RegisterConsoleCommand("msn.skill.trees", "MSN skill trees", n"msn_skill_trees");
}
