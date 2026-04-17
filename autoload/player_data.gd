extends Node
## Persistent player data. Autoloaded as "PlayerData".
## Holds base stats, derived resources, and stat descriptions.

# ── Signals ───────────────────────────────────────────────────
signal stat_changed(stat_name: String, new_value: int)
signal resource_changed(resource_name: String, current: float, maximum: float)

# ── Base stats (upgradeable) ──────────────────────────────────
var strength: int = 5:
	set(v): strength = maxi(v, 1); stat_changed.emit("strength", strength); _recalculate()
var technique: int = 5:
	set(v): technique = maxi(v, 1); stat_changed.emit("technique", technique); _recalculate()
var agility: int = 5:
	set(v): agility = maxi(v, 1); stat_changed.emit("agility", agility); _recalculate()
var constitution: int = 5:
	set(v): constitution = maxi(v, 1); stat_changed.emit("constitution", constitution); _recalculate()
var stamina: int = 5:
	set(v): stamina = maxi(v, 1); stat_changed.emit("stamina", stamina); _recalculate()

# ── Derived resource caps (recalculated from stats) ───────────
var max_health: float = 100.0
var max_energy: float = 100.0
var max_posture: float = 100.0
var energy_regen_rate: float = 5.0  # per second

# ── Runtime resource values (reset each battle) ──────────────
var health: float = 100.0
var energy: float = 100.0
var posture: float = 100.0

# ── Upgrade currency (placeholder) ───────────────────────────
var upgrade_points: int = 10

# ── Stat metadata for UI ─────────────────────────────────────
const STAT_INFO := {
	"strength": {
		"display": "Strength",
		"icon": "STR",
		"description": "Affects outgoing slash and attack damage. Higher strength means each landed blow hits harder.",
	},
	"technique": {
		"display": "Technique",
		"icon": "TEC",
		"description": "Affects outgoing posture damage caused by successful parries. Break the enemy's guard faster.",
	},
	"agility": {
		"display": "Agility",
		"icon": "AGI",
		"description": "Affects the invincibility window during directional dodges. More agility gives you wider dodge timing.",
	},
	"constitution": {
		"display": "Constitution",
		"icon": "CON",
		"description": "Affects maximum health. A higher constitution lets you survive more enemy blows before falling.",
	},
	"stamina": {
		"display": "Stamina",
		"icon": "STA",
		"description": "Affects maximum energy and energy regeneration rate. More stamina means more actions per fight.",
	},
}

const RESOURCE_INFO := {
	"health": {
		"display": "Health",
		"color": Color(0.8, 0.2, 0.2),
		"description": "Your life force. Decremented by successful enemy attacks. The battle ends in a loss when this reaches 0.",
	},
	"energy": {
		"display": "Energy",
		"color": Color(0.3, 0.6, 0.9),
		"description": "A recharging resource spent by attacks, parries, and dodges. Manages action pacing — discourages spamming.",
	},
	"posture": {
		"display": "Posture",
		"color": Color(0.9, 0.7, 0.2),
		"description": "A slowly recharging resource. Failed actions (attacks, parries, dodges) reduce it. Reaching 0 stuns you, leaving you vulnerable. Fully restores after recovering from stun.",
	},
}

# ── Stat accessors ────────────────────────────────────────────
func get_stat(stat_name: String) -> int:
	match stat_name:
		"strength": return strength
		"technique": return technique
		"agility": return agility
		"constitution": return constitution
		"stamina": return stamina
	return 0

func set_stat(stat_name: String, value: int) -> void:
	match stat_name:
		"strength": strength = value
		"technique": technique = value
		"agility": agility = value
		"constitution": constitution = value
		"stamina": stamina = value

# ── Upgrade ───────────────────────────────────────────────────
func try_upgrade(stat_name: String) -> bool:
	if upgrade_points <= 0:
		return false
	upgrade_points -= 1
	set_stat(stat_name, get_stat(stat_name) + 1)
	return true

# ── Derived value calculation ─────────────────────────────────
func _recalculate() -> void:
	max_health = 50.0 + constitution * 10.0
	max_energy = 50.0 + stamina * 10.0
	max_posture = 100.0  # fixed for now, could scale later
	energy_regen_rate = 3.0 + stamina * 0.4

# ── Battle helpers ────────────────────────────────────────────
func reset_resources() -> void:
	_recalculate()
	health = max_health
	energy = max_energy
	posture = max_posture

func take_damage(amount: float) -> void:
	health = clampf(health - absf(amount), 0.0, max_health)
	resource_changed.emit("health", health, max_health)

func spend_energy(amount: float) -> bool:
	if energy < amount:
		return false
	energy = clampf(energy - amount, 0.0, max_energy)
	resource_changed.emit("energy", energy, max_energy)
	return true

func regen_energy(delta: float) -> void:
	energy = clampf(energy + energy_regen_rate * delta, 0.0, max_energy)
	resource_changed.emit("energy", energy, max_energy)

func damage_posture(amount: float) -> void:
	posture = clampf(posture - absf(amount), 0.0, max_posture)
	resource_changed.emit("posture", posture, max_posture)

func restore_posture() -> void:
	posture = max_posture
	resource_changed.emit("posture", posture, max_posture)

func is_alive() -> bool:
	return health > 0.0

func is_stunned() -> bool:
	return posture <= 0.0

func get_attack_damage() -> float:
	return 8.0 + strength * 2.0

func get_posture_damage() -> float:
	return 5.0 + technique * 2.0

func get_dodge_window() -> float:
	return 0.15 + agility * 0.02

func _ready() -> void:
	_recalculate()
	reset_resources()
