extends Node

var swipe_start = Vector2.ZERO
var _last_swipe_end = Vector2.ZERO
var minimum_drag = 100 # the minimum pixel distance to count as a deliberate swipe
var combat_active: bool = true

const SWIPE_ENERGY_COST := 10.0

@onready var enemy = $"../Enemy"
@onready var hud = $"../CombatHUD"
@onready var swipe_trail = $"../SwipeTrail"

const COLOR_PARRY := Color(1.0, 0.85, 0.2)
const COLOR_ATTACK_STUN := Color(1.0, 0.2, 0.15)
const COLOR_ATTACK := Color(0.85, 0.85, 0.9)
const COLOR_NO_ENERGY := Color(0.4, 0.4, 0.4)

func _ready():
	PlayerData.reset_resources()

	if enemy:
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)
		if enemy.has_signal("attack_landed"):
			enemy.attack_landed.connect(_on_enemy_attack_landed)
		if enemy.has_signal("stats_updated"):
			enemy.stats_updated.connect(_on_enemy_stats_updated)

func _process(delta: float) -> void:
	if not combat_active:
		return
	PlayerData.regen_energy(delta)
	if hud:
		hud.update_player_bars()

func _on_enemy_died():
	combat_active = false
	await get_tree().create_timer(2.0).timeout
	SceneManager.change_scene("res://scenes/global_map/global_map.tscn")

func _on_enemy_attack_landed(damage: float) -> void:
	PlayerData.take_damage(damage)
	print("[Player] Health: %.0f / %.0f" % [PlayerData.health, PlayerData.max_health])
	if hud:
		hud.update_player_bars()
	if not PlayerData.is_alive():
		print("[Player] DEFEATED!")
		combat_active = false
		await get_tree().create_timer(1.5).timeout
		SceneManager.change_scene("res://scenes/global_map/global_map.tscn")

func _on_enemy_stats_updated() -> void:
	if hud and enemy:
		hud.update_enemy_bars(enemy.stats)

func _input(event):
	if not combat_active:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
		else:
			_calculate_swipe(event.position)

func _calculate_swipe(swipe_end):
	var swipe_vector = swipe_end - swipe_start
	_last_swipe_end = swipe_end

	if swipe_vector.length() >= minimum_drag:
		# Check energy — can't act without it
		if not PlayerData.spend_energy(SWIPE_ENERGY_COST):
			print("[Player] Not enough energy!")
			if swipe_trail:
				swipe_trail.show_swipe(swipe_start, swipe_end, COLOR_NO_ENERGY)
			return

		var angle = swipe_vector.angle()
		var direction = ""

		if angle >= -PI / 8 and angle < PI / 8:
			direction = "right"
		elif angle >= PI / 8 and angle < 3 * PI / 8:
			direction = "down-right"
		elif angle >= 3 * PI / 8 and angle < 5 * PI / 8:
			direction = "down"
		elif angle >= 5 * PI / 8 and angle < 7 * PI / 8:
			direction = "down-left"
		elif angle >= 7 * PI / 8 or angle < -7 * PI / 8:
			direction = "left"
		elif angle >= -7 * PI / 8 and angle < -5 * PI / 8:
			direction = "up-left"
		elif angle >= -5 * PI / 8 and angle < -3 * PI / 8:
			direction = "up"
		else:
			direction = "up-right"

		print("[Player] Swipe: %s" % direction)
		_on_swipe_detected(direction)

func _on_swipe_detected(direction):
	if not enemy:
		return
	# During parry window with correct direction → parry (posture damage only)
	if enemy.is_parry_possible(direction):
		if swipe_trail:
			swipe_trail.show_swipe(swipe_start, _last_swipe_end, COLOR_PARRY)
		enemy.receive_parry(direction)
	else:
		# Normal attack — full damage if stunned, greatly reduced otherwise
		var is_stunned: bool = enemy.state == enemy.State.STUNNED
		if swipe_trail:
			swipe_trail.show_swipe(swipe_start, _last_swipe_end, COLOR_ATTACK_STUN if is_stunned else COLOR_ATTACK)
		enemy.receive_attack(direction)