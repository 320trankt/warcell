class_name EnemyStats
extends Resource

## Emitted when any stat changes. Passes the stat name and new value.
signal stat_changed(stat_name: String, new_value: float)
signal health_depleted
signal posture_broken

# ── Base stats ────────────────────────────────────────────────
## Affects attack damage dealt to the player.
@export var strength: int = 5
## Affects the length of the parry window for attacks (higher = shorter window).
@export var technique: int = 5
## Affects chance of enemy dodging a player attack.
@export var agility: int = 5
## Affects max health.
@export var constitution: int = 5

# ── Derived resource caps ─────────────────────────────────────
var max_health: float = 100.0
var max_posture: float = 100.0
var posture_regen_rate: float = 3.0  # per second

# ── Runtime resources ─────────────────────────────────────────
var health: float:
	set(value):
		health = clampf(value, 0.0, max_health)
		stat_changed.emit("health", health)
		if health <= 0.0:
			health_depleted.emit()

var posture: float:
	set(value):
		var old := posture
		posture = clampf(value, 0.0, max_posture)
		stat_changed.emit("posture", posture)
		if posture <= 0.0 and old > 0.0:
			posture_broken.emit()

var is_posture_broken: bool = false

func _init(p_constitution: int = 5, p_strength: int = 5, p_technique: int = 5, p_agility: int = 5) -> void:
	constitution = p_constitution
	strength = p_strength
	technique = p_technique
	agility = p_agility
	_recalculate()
	health = max_health
	posture = max_posture

func _recalculate() -> void:
	max_health = 50.0 + constitution * 10.0
	max_posture = 100.0
	posture_regen_rate = 3.0

# ── Derived combat values ─────────────────────────────────────
func get_attack_damage() -> float:
	return 8.0 + strength * 2.0

func get_parry_window_shrink() -> float:
	## Returns seconds to subtract from the base parry window.
	## Higher technique → smaller window → harder to parry.
	return technique * 0.015

func get_dodge_chance() -> float:
	## Returns a 0.0–1.0 probability of dodging a player attack.
	return clampf(agility * 0.03, 0.0, 0.6)

# ── Resource manipulation ─────────────────────────────────────
func take_damage(amount: float) -> void:
	health -= absf(amount)

func heal(amount: float) -> void:
	health += absf(amount)

func damage_posture(amount: float) -> void:
	posture -= absf(amount)

func restore_posture() -> void:
	is_posture_broken = false
	posture = max_posture

func regen_posture(delta: float) -> void:
	if not is_posture_broken and posture < max_posture:
		posture = clampf(posture + posture_regen_rate * delta, 0.0, max_posture)

func is_alive() -> bool:
	return health > 0.0

func is_stunned() -> bool:
	return is_posture_broken
