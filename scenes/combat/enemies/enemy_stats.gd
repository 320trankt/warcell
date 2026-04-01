class_name EnemyStats
extends Resource

## Emitted when any stat changes. Passes the stat name and new value.
signal stat_changed(stat_name: String, new_value: float)
signal health_depleted

@export var max_health: float = 100.0
var health: float:
	set(value):
		health = clampf(value, 0.0, max_health)
		stat_changed.emit("health", health)
		if health <= 0.0:
			health_depleted.emit()

func _init(p_max_health: float = 100.0) -> void:
	max_health = p_max_health
	health = max_health

func take_damage(amount: float) -> void:
	health -= absf(amount)

func heal(amount: float) -> void:
	health += absf(amount)

func is_alive() -> bool:
	return health > 0.0
