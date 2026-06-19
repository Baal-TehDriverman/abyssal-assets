// GRAND THEFT CYBERPUNK - MSN MAGIC SYSTEM
// Script-only runtime glue for the Arcane Cybernetics content layer.
// Item records live in tweakdb/msn_magic_jedi.tweakdb.

public class MSNSimpleSpellData extends IScriptable {
    public let name: CName;
    public let school: CName;
    public let manaCost: Float;
    public let cooldown: Float;
    public let effect: CName;
}

public class MSNSimpleSpellResult extends IScriptable {
    public let success: Bool;
    public let message: String;
    public let spell: CName;
    public let school: CName;
    public let manaRemaining: Float;
}

public class MSNMagicSystem extends IScriptable {
    private static let instance: ref<MSNMagicSystem>;
    private let initialized: Bool;
    private let maxMana: Float;
    private let currentMana: Float;
    private let regenPerPulse: Float;
    private let attunedSchool: CName;
    private let lastCastTime: Float;
    private let lastSpell: CName;

    public final static func GetInstance() -> ref<MSNMagicSystem> {
        if (!IsDefined(MSNMagicSystem.instance)) {
            MSNMagicSystem.instance = new MSNMagicSystem();
            MSNMagicSystem.instance.Initialize();
        };
        return MSNMagicSystem.instance;
    }

    private final func Initialize() -> Void {
        if (this.initialized) {
            return;
        };

        this.initialized = true;
        this.maxMana = 150.0;
        this.currentMana = this.maxMana;
        this.regenPerPulse = 12.5;
        this.attunedSchool = n"Evocation";
        this.lastCastTime = -9999.0;
        this.lastSpell = n"";

        LogInfo("[MSNMagic] online: mana pool, 8 schools, 12 spells, arcane cyberware hooks");
    }

    public final func Attune(school: CName) -> Void {
        this.attunedSchool = school;
        this.PulseMana();
        this.Notify("MSN Magic attuned to " + NameToString(school));
    }

    public final func PulseMana() -> Void {
        this.currentMana = MinF(this.maxMana, this.currentMana + this.regenPerPulse);
    }

    public final func GetManaSummary() -> String {
        return "mana " + FloatToString(this.currentMana) + "/" + FloatToString(this.maxMana) + " | attuned " + NameToString(this.attunedSchool);
    }

    public final func Cast(spellName: CName) -> ref<MSNSimpleSpellResult> {
        let spell: ref<MSNSimpleSpellData> = this.GetSpellData(spellName);
        let result: ref<MSNSimpleSpellResult> = new MSNSimpleSpellResult();
        if (!IsDefined(spell)) {
            result.success = false;
            result.message = "Unknown spell";
            result.manaRemaining = this.currentMana;
            return result;
        };

        result.spell = spellName;
        result.school = spell.school;

        if (spell.effect == n"Unknown") {
            result.success = false;
            result.message = "Unknown spell";
            result.manaRemaining = this.currentMana;
            this.Notify("MSN Magic: unknown spell " + NameToString(spellName));
            return result;
        };

        if (this.currentMana < spell.manaCost) {
            result.success = false;
            result.message = "Insufficient mana";
            result.manaRemaining = this.currentMana;
            this.Notify("MSN Magic: not enough mana for " + NameToString(spellName));
            return result;
        };

        if (spellName == this.lastSpell && this.lastCastTime > 0.0) {
            let elapsed: Float = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - this.lastCastTime;
            if (elapsed < spell.cooldown) {
                result.success = false;
                result.message = "Spell cooling down";
                result.manaRemaining = this.currentMana;
                this.Notify("MSN Magic: " + NameToString(spellName) + " cooling down");
                return result;
            };
        };

        this.currentMana = this.currentMana - spell.manaCost;
        this.lastCastTime = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        this.lastSpell = spellName;

        this.ApplySpellEffect(spell);
        this.RouteSephiroticResonance(spell.school);

        result.success = true;
        result.message = "Cast " + NameToString(spellName) + " via " + NameToString(spell.school);
        result.manaRemaining = this.currentMana;
        this.Notify("MSN Magic: " + result.message);
        return result;
    }

    private final func ApplySpellEffect(spell: ref<MSNSimpleSpellData>) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) {
            return;
        };

        switch (spell.effect) {
            case n"Projectile":
                LogInfo("[MSNMagic] projectile spell routed: " + NameToString(spell.name));
                break;
            case n"AreaDamage":
                LogInfo("[MSNMagic] area spell routed: " + NameToString(spell.name));
                break;
            case n"Defense":
                Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.Invulnerable");
                break;
            case n"Scan":
                LogInfo("[MSNMagic] detect magic scan pulse emitted");
                break;
            case n"Mobility":
                LogInfo("[MSNMagic] teleport/phase mobility pulse emitted");
                break;
            case n"Heal":
                Game.GetStatPoolsSystem().RequestSettingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, 100.0, player);
                break;
            default:
                LogInfo("[MSNMagic] generic spell effect routed: " + NameToString(spell.name));
                break;
        };
    }

    private final func RouteSephiroticResonance(school: CName) -> Void {
        let sephirah: CName = this.GetSchoolSephirah(school);
        LogInfo("[MSNMagic] sephirotic resonance " + NameToString(school) + " -> " + NameToString(sephirah));
    }

    private final func GetSchoolSephirah(school: CName) -> CName {
        switch (school) {
            case n"Evocation":
                return n"Geburah";
            case n"Abjuration":
                return n"Chesed";
            case n"Conjuration":
                return n"Netzach";
            case n"Divination":
                return n"Chokmah";
            case n"Enchantment":
                return n"Netzach";
            case n"Illusion":
                return n"Hod";
            case n"Necromancy":
                return n"Geburah";
            case n"Transmutation":
                return n"Tiphareth";
            default:
                return n"Tiphareth";
        };
    }

    private final func GetSpellData(name: CName) -> ref<MSNSimpleSpellData> {
        let spell: ref<MSNSimpleSpellData> = new MSNSimpleSpellData();
        spell.name = name;

        switch (name) {
            case n"MagicMissile":
                spell.school = n"Evocation";
                spell.manaCost = 10.0;
                spell.cooldown = 3.0;
                spell.effect = n"Projectile";
                break;
            case n"Fireball":
                spell.school = n"Evocation";
                spell.manaCost = 30.0;
                spell.cooldown = 15.0;
                spell.effect = n"AreaDamage";
                break;
            case n"LightningBolt":
                spell.school = n"Evocation";
                spell.manaCost = 25.0;
                spell.cooldown = 10.0;
                spell.effect = n"Projectile";
                break;
            case n"MageArmor":
                spell.school = n"Abjuration";
                spell.manaCost = 15.0;
                spell.cooldown = 45.0;
                spell.effect = n"Defense";
                break;
            case n"Shield":
                spell.school = n"Abjuration";
                spell.manaCost = 10.0;
                spell.cooldown = 20.0;
                spell.effect = n"Defense";
                break;
            case n"DetectMagic":
                spell.school = n"Divination";
                spell.manaCost = 5.0;
                spell.cooldown = 10.0;
                spell.effect = n"Scan";
                break;
            case n"Teleport":
                spell.school = n"Conjuration";
                spell.manaCost = 40.0;
                spell.cooldown = 60.0;
                spell.effect = n"Mobility";
                break;
            case n"SummonFamiliar":
                spell.school = n"Conjuration";
                spell.manaCost = 50.0;
                spell.cooldown = 120.0;
                spell.effect = n"Summon";
                break;
            case n"Heal":
                spell.school = n"Necromancy";
                spell.manaCost = 20.0;
                spell.cooldown = 20.0;
                spell.effect = n"Heal";
                break;
            case n"RaiseDead":
                spell.school = n"Necromancy";
                spell.manaCost = 100.0;
                spell.cooldown = 300.0;
                spell.effect = n"Summon";
                break;
            case n"TimeStop":
                spell.school = n"Transmutation";
                spell.manaCost = 80.0;
                spell.cooldown = 300.0;
                spell.effect = n"Mobility";
                break;
            case n"Wish":
                spell.school = n"Transmutation";
                spell.manaCost = 150.0;
                spell.cooldown = 900.0;
                spell.effect = n"Reality";
                break;
            default:
                spell.school = n"Unknown";
                spell.manaCost = 9999.0;
                spell.cooldown = 9999.0;
                spell.effect = n"Unknown";
                break;
        };

        return spell;
    }

    private final func Notify(message: String) -> Void {
        LogInfo(message);
        Game.GetUIManager().ShowNotification(message);
    }

    @Command("msn.magic.status")
    public final func CmdMagicStatus() -> Void {
        this.Notify("MSN Magic: " + this.GetManaSummary());
    }

    @Command("msn.magic.cast")
    public final func CmdMagicCast(spellName: String) -> Void {
        let result: ref<MSNSimpleSpellResult> = this.Cast(StringToName(spellName));
        this.Notify(result.message + " | " + this.GetManaSummary());
    }

    @Command("msn.magic.attune")
    public final func CmdMagicAttune(schoolName: String) -> Void {
        this.Attune(StringToName(schoolName));
    }
}

public class MSNMagicCerebellum extends IScriptable {
    @Property() public let manaPoolSize: Float = 200.0;
    @Property() public let manaRegenPulse: Float = 15.0;
    @Property() public let schoolAffinity: CName = n"Evocation";

    public final func OnInstall(entity: ref<Entity>) -> Void {
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.Attune(this.schoolAffinity);
        LogInfo("[MSNMagicCerebellum] installed for arcane cyberware bridge");
    }
}
