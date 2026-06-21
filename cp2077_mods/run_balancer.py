import os
import glob
import re

MODS_DIR = "/home/tehlappy/Desktop/Lilith/Core_Systems/AI/abyssal-assets/cp2077_mods"

def structure_and_balance(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Balance Quickhacks: Cooldown = RAMCost * 10.0
    # Match block for Quickhacks
    def quickhack_repl(match):
        block = match.group(0)
        # Find RAMCost
        ram_m = re.search(r'RAMCost\s*=\s*([0-9]+)', block)
        if ram_m:
            ram = int(ram_m.group(1))
            new_cooldown = float(ram * 10)
            block = re.sub(r'Cooldown\s*=\s*[0-9.]+', f'Cooldown = {new_cooldown}', block)
        return block

    content = re.sub(r'Items\.[A-Za-z0-9_]+\s*=\s*\{[^}]*Type\s*=\s*SkillType\.Quickhack[^}]*\}', quickhack_repl, content)

    # Balance Weapons: DPS = BaseDamage * FireRate. Target DPS ~ 1000 for standard, 1500 for Legendary, etc.
    # Let's say Target DPS = 1024 for all to ensure "mathematical perfection" 
    # Or calculate BaseDamage from FireRate.
    def weapon_repl(match):
        block = match.group(0)
        rarity_m = re.search(r'Rarity\s*=\s*"([^"]+)"', block)
        target_dps = 1000.0
        if rarity_m:
            rarity = rarity_m.group(1)
            if rarity == "Legendary":
                target_dps = 1500.0
            elif rarity == "Epic":
                target_dps = 1200.0
            elif rarity == "Rare":
                target_dps = 1000.0
            else:
                target_dps = 800.0
        
        firerate_m = re.search(r'FireRate\s*=\s*([0-9.]+)', block)
        if firerate_m:
            firerate = float(firerate_m.group(1))
            if firerate > 0:
                new_damage = round(target_dps / firerate, 1)
                block = re.sub(r'BaseDamage\s*=\s*[0-9.]+', f'BaseDamage = {new_damage}', block)
        return block

    content = re.sub(r'Items\.[A-Za-z0-9_]+\s*=\s*\{[^}]*Type\s*=\s*WeaponType\.[A-Za-z0-9_]+[^}]*\}', weapon_repl, content)

    # Balance Cyberware: Capacity cost based on SephiroticSlots or VRAMBudget
    def cyberware_repl(match):
        block = match.group(0)
        vram_m = re.search(r'VRAMBudgetMB\s*=\s*([0-9]+)', block)
        if vram_m:
            vram = int(vram_m.group(1))
            # Capacity = VRAM / 50
            new_cap = int(max(1, vram / 50))
            block = re.sub(r'Capacity\s*=\s*[0-9]+', f'Capacity = {new_cap}', block)
        return block

    content = re.sub(r'Items\.[A-Za-z0-9_]+\s*=\s*\{[^}]*Type\s*=\s*CyberwareType\.[A-Za-z0-9_]+[^}]*\}', cyberware_repl, content)

    # Structure Data Formats: ensure standard indentation (4 spaces)
    # This is a bit tricky with regex, we will ensure that lines inside blocks are indented by 4 spaces.
    def format_block(match):
        block = match.group(0)
        lines = block.split('\n')
        for i in range(1, len(lines)-1):
            if lines[i].strip() != '':
                lines[i] = '    ' + lines[i].strip()
        return '\n'.join(lines)

    content = re.sub(r'^[ \t]*Items\.[A-Za-z0-9_]+\s*=\s*\{[\s\S]*?^\};', format_block, content, flags=re.MULTILINE)

    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Balanced and structured: {file_path}")

def main():
    # Find all .toml and .yaml files
    target_files = []
    for root, dirs, files in os.walk(MODS_DIR):
        for file in files:
            if file.endswith('.toml') or file.endswith('.yaml') or file.endswith('.tweakdb'):
                target_files.append(os.path.join(root, file))
                
    for f in target_files:
        try:
            structure_and_balance(f)
        except Exception as e:
            print(f"Error processing {f}: {e}")

if __name__ == '__main__':
    main()
