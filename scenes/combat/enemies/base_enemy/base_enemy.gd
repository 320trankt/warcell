extends Node3D

## Enemy combat states
enum State { IDLE, TELEGRAPH, ATTACK, RECOVERY, HIT, STUNNED, DEATH }

## Attack definitions: animation name, required parry direction, and timing windows
## parry_window_start/end are seconds into the attack animation
var attacks: Array[Dictionary] = [
	{
		"animation": "Punch",
		"direction": "left",
		"telegraph_anim": "Duck",
		"telegraph_duration": 0,
		"parry_window_start": 0.15,
		"parry_window_end": 0.55,
		"recovery_duration": 0.5,
	},
	{
		"animation": "Weapon",
		"direction": "up-right",
		"telegraph_anim": "Duck",
		"telegraph_duration": 0,
		"parry_window_start": 0.2,
		"parry_window_end": 0.5,
		"recovery_duration": 0.6,
	},
]

var state: State = State.IDLE
var current_attack: Dictionary = {}
var parry_window_open: bool = false
var parry_succeeded: bool = false

var mesh: MeshInstance3D
var anim_player: AnimationPlayer
var stats: EnemyStats

var idle_duration_min: float = 1.0
var idle_duration_max: float = 2.5
var stun_duration: float = 3.0

const STUN_DAMAGE_MULTIPLIER := 1.0
const NORMAL_DAMAGE_MULTIPLIER := 0.15

## Override these in inherited scenes / spawner to customise stats
@export var enemy_strength: int = 5
@export var enemy_technique: int = 5
@export var enemy_agility: int = 5
@export var enemy_constitution: int = 5

signal parry_result(success: bool, direction: String)
signal attack_landed(damage: float)
signal died
signal stats_updated

func _ready():
	stats = EnemyStats.new(enemy_constitution, enemy_strength, enemy_technique, enemy_agility)
	stats.stat_changed.connect(_on_stat_changed)
	stats.health_depleted.connect(_on_health_depleted)
	stats.posture_broken.connect(_on_posture_broken)

	mesh = _find_node_recursive(self, MeshInstance3D) as MeshInstance3D
	anim_player = _find_node_recursive(self, AnimationPlayer) as AnimationPlayer

	if anim_player:
		print("[Enemy] Animations: ", anim_player.get_animation_list())
		# ensure Idle loops so it plays until a state change interrupts it
		var idle_anim := anim_player.get_animation("Idle")
		if idle_anim:
			idle_anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.animation_finished.connect(_on_animation_finished)
		_enter_state(State.IDLE)
	else:
		push_warning("[Enemy] No AnimationPlayer found in children!")

	stats_updated.emit.call_deferred()

func _process(_delta: float) -> void:
	if state == State.ATTACK and anim_player.is_playing():
		var pos := anim_player.current_animation_position
		var was_open := parry_window_open
		# Technique shrinks the parry window — higher technique = harder to parry
		var shrink := stats.get_parry_window_shrink()
		var pw_start: float = current_attack.parry_window_start + shrink
		var pw_end: float = current_attack.parry_window_end - shrink
		parry_window_open = pw_start < pw_end and pos >= pw_start and pos <= pw_end
		if parry_window_open and not was_open:
			print("[Enemy] Parry window OPEN — swipe %s!" % current_attack.direction)
		elif not parry_window_open and was_open:
			print("[Enemy] Parry window CLOSED")

# ── State machine ─────────────────────────────────────────────

func _enter_state(new_state: State) -> void:
	state = new_state
	parry_window_open = false

	match state:
		State.IDLE:
			parry_succeeded = false
			anim_player.play("Idle")
			# wait a random beat then pick an attack
			var wait := randf_range(idle_duration_min, idle_duration_max)
			get_tree().create_timer(wait).timeout.connect(_start_attack, CONNECT_ONE_SHOT)

		State.TELEGRAPH:
			print("[Enemy] Telegraphing: %s attack incoming (parry %s)" % [current_attack.animation, current_attack.direction])
			anim_player.play(current_attack.telegraph_anim)
			get_tree().create_timer(current_attack.telegraph_duration).timeout.connect(
				func(): _enter_state(State.ATTACK), CONNECT_ONE_SHOT
			)

		State.ATTACK:
			anim_player.play(current_attack.animation)
			# animation_finished callback handles transition

		State.RECOVERY:
			anim_player.play("Idle")
			if not parry_succeeded:
				# player failed to parry — attack lands using stat-driven damage
				var dmg := stats.get_attack_damage()
				print("[Enemy] Attack landed! %.1f damage." % dmg)
				attack_landed.emit(dmg)
			get_tree().create_timer(current_attack.recovery_duration).timeout.connect(
				func(): _enter_state(State.IDLE), CONNECT_ONE_SHOT
			)

		State.HIT:
			anim_player.play("HitReact")
			_flash_hit()
			# animation_finished callback returns to RECOVERY

		State.STUNNED:
			print("[Enemy] POSTURE BROKEN — stunned for %.1fs!" % stun_duration)
			stats.is_posture_broken = true
			if anim_player.has_animation("HitReact"):
				anim_player.play("HitReact")
			_flash_stun()
			get_tree().create_timer(stun_duration).timeout.connect(func():
				if state == State.STUNNED and stats.is_alive():
					stats.restore_posture()
					print("[Enemy] Posture restored!")
					stats_updated.emit()
					_enter_state(State.IDLE)
			, CONNECT_ONE_SHOT)

		State.DEATH:
			anim_player.play("Death")

func _start_attack() -> void:
	if state != State.IDLE or not stats.is_alive():
		return
	current_attack = attacks.pick_random()
	_enter_state(State.TELEGRAPH)

func _on_animation_finished(anim_name: StringName) -> void:
	match state:
		State.ATTACK:
			_enter_state(State.RECOVERY)
		State.HIT:
			_enter_state(State.RECOVERY)
		State.STUNNED:
			# Loop HitReact while stunned
			if stats.is_alive() and anim_player.has_animation("HitReact"):
				anim_player.play("HitReact")
		State.DEATH:
			pass

# ── Parry interface (posture damage only) ─────────────────────

func is_parry_possible(direction: String) -> bool:
	return state == State.ATTACK and parry_window_open and direction == current_attack.direction

func receive_parry(direction: String) -> void:
	print("[Enemy] PARRY SUCCESS!")
	parry_succeeded = true
	var posture_dmg := PlayerData.get_posture_damage()
	stats.damage_posture(posture_dmg)
	print("[Enemy] Posture: %.0f / %.0f" % [stats.posture, stats.max_posture])
	parry_result.emit(true, direction)
	stats_updated.emit()
	if stats.is_alive() and not stats.is_stunned():
		_enter_state(State.HIT)

# ── Attack interface (health damage) ──────────────────────────

func receive_attack(_direction: String) -> void:
	if state == State.DEATH:
		return
	# Check dodge chance (not while stunned)
	if state != State.STUNNED and randf() < stats.get_dodge_chance():
		print("[Enemy] Dodged the attack!")
		return
	var base_dmg := PlayerData.get_attack_damage()
	var multiplier := STUN_DAMAGE_MULTIPLIER if state == State.STUNNED else NORMAL_DAMAGE_MULTIPLIER
	var final_dmg := base_dmg * multiplier
	stats.take_damage(final_dmg)
	print("[Enemy] Hit for %.1f damage (%s). Health: %.0f / %.0f" % [
		final_dmg, "STUNNED" if state == State.STUNNED else "guarded", stats.health, stats.max_health
	])
	stats_updated.emit()
	_flash_hit()

# ── Visual feedback ───────────────────────────────────────────

func _flash_hit() -> void:
	if not mesh:
		return
	var mat = mesh.get_active_material(0)
	if not mat:
		return
	var tween = create_tween()
	tween.tween_property(mat, "albedo_color", Color.RED, 0.1)
	tween.parallel().tween_property(self, "position:z", position.z + 0.2, 0.05)
	tween.tween_property(mat, "albedo_color", Color.WHITE, 0.1)
	tween.parallel().tween_property(self, "position:z", position.z, 0.1)

func _flash_stun() -> void:
	if not mesh:
		return
	var mat = mesh.get_active_material(0)
	if not mat:
		return
	var tween = create_tween().set_loops(int(stun_duration / 0.6))
	tween.tween_property(mat, "albedo_color", Color(1.0, 0.9, 0.3), 0.3)
	tween.tween_property(mat, "albedo_color", Color(0.6, 0.5, 0.2), 0.3)
	get_tree().create_timer(stun_duration).timeout.connect(func():
		if mat:
			mat.albedo_color = Color.WHITE
	, CONNECT_ONE_SHOT)

# ── Stats callbacks ───────────────────────────────────────────

func _on_stat_changed(stat_name: String, new_value: float) -> void:
	stats_updated.emit()

func _on_health_depleted() -> void:
	print("[Enemy] DEFEATED!")
	died.emit()
	_enter_state(State.DEATH)

func _on_posture_broken() -> void:
	if state != State.DEATH:
		_enter_state(State.STUNNED)

# ── Helpers ───────────────────────────────────────────────────

func _find_node_recursive(node: Node, type: Variant) -> Node:
	for child in node.get_children():
		if is_instance_of(child, type):
			return child
		var result := _find_node_recursive(child, type)
		if result:
			return result
	return null