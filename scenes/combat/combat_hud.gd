extends CanvasLayer

@onready var player_health_bar: ProgressBar = %PlayerHealthBar
@onready var player_energy_bar: ProgressBar = %PlayerEnergyBar
@onready var player_health_label: Label = %PlayerHealthLabel
@onready var player_energy_label: Label = %PlayerEnergyLabel

@onready var enemy_health_bar: ProgressBar = %EnemyHealthBar
@onready var enemy_posture_bar: ProgressBar = %EnemyPostureBar
@onready var enemy_health_label: Label = %EnemyHealthLabel
@onready var enemy_posture_label: Label = %EnemyPostureLabel

func _ready() -> void:
	update_player_bars()

func update_player_bars() -> void:
	player_health_bar.max_value = PlayerData.max_health
	player_health_bar.value = PlayerData.health
	player_health_label.text = "%.0f" % PlayerData.health

	player_energy_bar.max_value = PlayerData.max_energy
	player_energy_bar.value = PlayerData.energy
	player_energy_label.text = "%.0f" % PlayerData.energy

func update_enemy_bars(stats: EnemyStats) -> void:
	enemy_health_bar.max_value = stats.max_health
	enemy_health_bar.value = stats.health
	enemy_health_label.text = "%.0f" % stats.health

	enemy_posture_bar.max_value = stats.max_posture
	enemy_posture_bar.value = stats.posture
	enemy_posture_label.text = "%.0f" % stats.posture
