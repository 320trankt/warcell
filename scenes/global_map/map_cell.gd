class_name MapCell
extends PanelContainer

enum CellState { EMPTY, ENEMY, CONQUERED, LOCKED }

var cell_state: CellState = CellState.LOCKED
var grid_position: Vector2i = Vector2i.ZERO
var enemy_name: String = ""

signal cell_pressed(cell: PanelContainer)

@onready var coords_label: Label = %CoordsLabel
@onready var icon_label: Label = %IconLabel
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_update_visuals()

func setup(pos: Vector2i, state: CellState, p_enemy_name: String = "") -> void:
	grid_position = pos
	cell_state = state
	enemy_name = p_enemy_name
	if is_inside_tree():
		_update_visuals()

func _update_visuals() -> void:
	coords_label.text = "%d,%d" % [grid_position.x, grid_position.y]
	match cell_state:
		CellState.LOCKED:
			icon_label.text = "?"
			status_label.text = "Unknown"
			_apply_style(Color(0.15, 0.13, 0.18, 1), Color(0.25, 0.22, 0.3, 1))
		CellState.EMPTY:
			icon_label.text = "~"
			status_label.text = "Wilds"
			_apply_style(Color(0.18, 0.22, 0.18, 1), Color(0.3, 0.38, 0.3, 1))
		CellState.ENEMY:
			icon_label.text = "!"
			status_label.text = enemy_name
			_apply_style(Color(0.35, 0.1, 0.1, 1), Color(0.55, 0.2, 0.2, 1))
		CellState.CONQUERED:
			icon_label.text = "^"
			status_label.text = "Ours"
			_apply_style(Color(0.12, 0.25, 0.12, 1), Color(0.2, 0.4, 0.2, 1))

func _apply_style(bg_color: Color, border_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	add_theme_stylebox_override("panel", style)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cell_pressed.emit(self)
