import os
import re

SCRIPTS_DIR = '/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods/scripts'

def process_redscript_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    modified = False

    # Inject MSN Skill XP on Combat End/Kill
    if "public func OnTargetKilled" in content or "private func OnTargetKilled" in content:
        # We find the function and inject the hook at the beginning of the body
        content = re.sub(
            r'(func OnTargetKilled[^\{]*\{)',
            r'\1\n        // --- MSN SKILLTREE INTEGRATION ---\n        if IsDefined(MSNAbyssalSkillSystemInstance) { MSNAbyssalSkillSystemInstance.GrantSkillXP(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet, "hunting", 50.0, SXPContext{activityMultiplier: 1.0}); }\n        // ---------------------------------',
            content
        )
        modified = True

    # Inject MSN Skill XP on Quickhack
    if "public func OnQuickHack" in content or "private func OnQuickHack" in content:
        content = re.sub(
            r'(func OnQuickHack[^\{]*\{)',
            r'\1\n        // --- MSN SKILLTREE INTEGRATION ---\n        if IsDefined(MSNAbyssalSkillSystemInstance) { MSNAbyssalSkillSystemInstance.GrantSkillXP(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet, "sonar_tuning", 30.0, SXPContext{activityMultiplier: 1.0}); }\n        // ---------------------------------',
            content
        )
        modified = True

    # Inject MSN Skill XP on Crafting
    if "public func OnItemCrafted" in content or "private func OnItemCrafted" in content:
        content = re.sub(
            r'(func OnItemCrafted[^\{]*\{)',
            r'\1\n        // --- MSN SKILLTREE INTEGRATION ---\n        if IsDefined(MSNAbyssalSkillSystemInstance) { MSNAbyssalSkillSystemInstance.GrantSkillXP(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet, "masterwork", 75.0, SXPContext{activityMultiplier: 1.0}); }\n        // ---------------------------------',
            content
        )
        modified = True

    # If it's a magic/jedi skill cast
    if "public func CastSpell" in content or "private func CastSpell" in content:
        content = re.sub(
            r'(func CastSpell[^\{]*\{)',
            r'\1\n        // --- MSN SKILLTREE INTEGRATION ---\n        if IsDefined(MSNAbyssalSkillSystemInstance) { MSNAbyssalSkillSystemInstance.GrantSkillXP(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet, "enchanting", 20.0, SXPContext{activityMultiplier: 1.0}); }\n        // ---------------------------------',
            content
        )
        modified = True

    if "public func UseForcePower" in content or "private func UseForcePower" in content:
        content = re.sub(
            r'(func UseForcePower[^\{]*\{)',
            r'\1\n        // --- MSN SKILLTREE INTEGRATION ---\n        if IsDefined(MSNAbyssalSkillSystemInstance) { MSNAbyssalSkillSystemInstance.GrantSkillXP(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet, "lore", 25.0, SXPContext{activityMultiplier: 1.0}); }\n        // ---------------------------------',
            content
        )
        modified = True

    # If it's the master integration, ensure it initializes the Abyssal skill system
    if "MSNMasterIntegration" in filepath and "func InitializeFullSovereignStack" in content:
        if "MSNAbyssalSkillSystemInstance.Initialize" not in content:
            content = re.sub(
                r'(func InitializeFullSovereignStack[^\{]*\{)',
                r'\1\n        // --- MSN SKILLTREE INTEGRATION ---\n        MSNAbyssalSkillSystemInstance = new MSNAbyssalSkillSystem();\n        MSNAbyssalSkillSystemInstance.Initialize();\n        // ---------------------------------',
                content
            )
            modified = True

    if modified and content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

modified_files = 0
for root, dirs, files in os.walk(SCRIPTS_DIR):
    for filename in files:
        if filename.endswith('.reds'):
            filepath = os.path.join(root, filename)
            if process_redscript_file(filepath):
                modified_files += 1
                print(f"Integrated MSN Skilltree into: {filename}")

print(f"Total files modified: {modified_files}")
