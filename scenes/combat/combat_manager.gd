extends Node

var swipe_start = Vector2.ZERO
var _last_swipe_end = Vector2.ZERO
var minimum_drag = 100 # the minimum pixel distance to count as a deliberate swipe
var combat_active: bool = true

const SWIPE_ENERGY_COST := 10.0
const FAILED_PARRY_POSTURE_DAMAGE := 20.0 # swiping during an enemy attack without parrying it
const DODGED_ATTACK_POSTURE_DAMAGE := 10.0 # attacking and having the enemy dodge
const PLAYER_STUN_DURATION := 2.0 # seconds the player can't act after their posture breaks

## Swipe directions in 45° steps, clockwise from "right" (screen y points down).
## Must match the direction strings used by base_enemy.gd's attacks table.
const DIRECTIONS: Array[String] = ["right", "down-right", "down", "down-left", "left", "up-left", "up", "up-right"]
const NO_TOUCH := -1

# ── Touch tracking ────────────────────────────────────────────
var _touch_index: int = NO_TOUCH # finger being tracked; other fingers are ignored until it lifts
var _touch_resolved: bool = false # true once this touch has produced its one action

@onready var enemy = $"../Enemy"
@onready var hud = $"../CombatHUD"
@onready var swipe_trail = $"../SwipeTrail"

const COLOR_PARRY := Color(1.0, 0.85, 0.2)
const COLOR_FAILED_PARRY := Color(0.7, 0.3, 0.9)
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
	PlayerData.regen_posture(delta)
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

# ── Swipe input ───────────────────────────────────────────────

func _input(event):
	if not combat_active:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			# Track the first finger down (or the same finger again if its release was missed)
			if _touch_index == NO_TOUCH or event.index == _touch_index:
				_touch_index = event.index
				_touch_resolved = false
				swipe_start = event.position
		elif event.index == _touch_index:
			# Fallback for flicks too fast to produce a drag event past the threshold
			if not _touch_resolved and not event.canceled:
				_try_resolve_swipe(event.position)
			_touch_index = NO_TOUCH
	elif event is InputEventScreenDrag:
		if event.index == _touch_index and not _touch_resolved:
			_try_resolve_swipe(event.position)

## Resolves the active touch as a swipe once it has travelled at least minimum_drag.
## Each touch resolves at most once.
func _try_resolve_swipe(swipe_end: Vector2) -> void:
	var swipe_vector: Vector2 = swipe_end - swipe_start
	if swipe_vector.length() < minimum_drag:
		return
	_touch_resolved = true
	_last_swipe_end = swipe_end
	var direction := _get_swipe_direction(swipe_vector)
	print("[Player] Swipe: %s" % direction)
	_on_swipe_detected(direction)

## Maps a swipe vector to one of the 8 DIRECTIONS. Each direction covers a 45° sector
## centred on it, lower edge inclusive, upper edge exclusive.
func _get_swipe_direction(swipe_vector: Vector2) -> String:
	var sector := floori(swipe_vector.angle() / (PI / 4.0) + 0.5)
	return DIRECTIONS[posmod(sector, DIRECTIONS.size())]

func _on_swipe_detected(direction: String) -> void:
	# Stunned players can't act
	if PlayerData.is_stunned():
		print("[Player] Stunned — can't act!")
		_show_swipe_trail(COLOR_NO_ENERGY)
		return

	# Check energy — can't act without it
	if not PlayerData.spend_energy(SWIPE_ENERGY_COST):
		print("[Player] Not enough energy!")
		_show_swipe_trail(COLOR_NO_ENERGY)
		return

	if not enemy:
		return
	# During parry window with correct direction → parry (posture damage only)
	if enemy.is_parry_possible(direction):
		_show_swipe_trail(COLOR_PARRY)
		enemy.receive_parry(direction)
	elif enemy.is_attacking():
		# Mistimed or wrong-direction parry — no damage dealt, costs player posture
		_show_swipe_trail(COLOR_FAILED_PARRY)
		print("[Player] Failed parry!")
		_damage_player_posture(FAILED_PARRY_POSTURE_DAMAGE)
	else:
		# Normal attack — full damage if stunned, greatly reduced otherwise
		var is_stunned: bool = enemy.state == enemy.State.STUNNED
		_show_swipe_trail(COLOR_ATTACK_STUN if is_stunned else COLOR_ATTACK)
		var landed: bool = enemy.receive_attack(direction)
		if not landed and enemy.stats.is_alive():
			print("[Player] Attack dodged!")
			_damage_player_posture(DODGED_ATTACK_POSTURE_DAMAGE)

func _show_swipe_trail(color: Color) -> void:
	if swipe_trail:
		swipe_trail.show_swipe(swipe_start, _last_swipe_end, color)

# ── Player posture ────────────────────────────────────────────

func _damage_player_posture(amount: float) -> void:
	if PlayerData.is_stunned():
		return
	PlayerData.damage_posture(amount)
	print("[Player] Posture: %.0f / %.0f" % [PlayerData.posture, PlayerData.max_posture])
	if hud:
		hud.update_player_bars()
	if PlayerData.is_stunned():
		# Posture just broke — one timer per stun
		print("[Player] POSTURE BROKEN — stunned for %.1fs!" % PLAYER_STUN_DURATION)
		get_tree().create_timer(PLAYER_STUN_DURATION).timeout.connect(_on_player_stun_finished, CONNECT_ONE_SHOT)

func _on_player_stun_finished() -> void:
	PlayerData.restore_posture()
	print("[Player] Posture restored!")
	if hud:
		hud.update_player_bars()
