extends Control

const MAP_COLS := 5
const MAP_ROWS := 10
const MapCellScene := preload("res://scenes/global_map/map_cell.tscn")

@onready var grid: GridContainer = %CellGrid
@onready var info_label: Label = %InfoLabel

func _ready() -> void:
	grid.columns = MAP_COLS
	_generate_map()

func _generate_map() -> void:
	for y in MAP_ROWS:
		for x in MAP_COLS:
			var cell := MapCellScene.instantiate()
			var state: MapCell.CellState
			var ename := ""

			# Simple procedural layout: conquered → frontline → enemy → locked
			if y < 2:
				state = MapCell.CellState.CONQUERED
			elif y == 2:
				# Frontline row — mix of enemies and empty wilds
				if x % 2 == 0:
					state = MapCell.CellState.ENEMY
					ename = ["Orc", "Goblin", "Skeleton"].pick_random()
				else:
					state = MapCell.CellState.EMPTY
			elif y < 5:
				state = MapCell.CellState.ENEMY
				ename = ["Warlord", "Dark Knight", "Troll", "Bandit", "Wraith"].pick_random()
			else:
				state = MapCell.CellState.LOCKED

			cell.setup(Vector2i(x, y), state, ename)
			grid.add_child(cell)
			cell.cell_pressed.connect(_on_cell_pressed)

func _on_cell_pressed(cell: MapCell) -> void:
	match cell.cell_state:
		MapCell.CellState.ENEMY:
			info_label.text = "Sieging %s at [%d,%d]..." % [cell.enemy_name, cell.grid_position.x, cell.grid_position.y]
			await get_tree().create_timer(0.5).timeout
			SceneManager.change_scene("res://scenes/combat/combat_scene.tscn")
		MapCell.CellState.CONQUERED:
			info_label.text = "Territory secured. [%d,%d]" % [cell.grid_position.x, cell.grid_position.y]
		MapCell.CellState.EMPTY:
			info_label.text = "Empty wilderness. [%d,%d]" % [cell.grid_position.x, cell.grid_position.y]
		MapCell.CellState.LOCKED:
			info_label.text = "Unknown territory. Push the frontline!"
