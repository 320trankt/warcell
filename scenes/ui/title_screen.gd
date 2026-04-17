extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var enter_button: Button = %EnterButton

func _ready() -> void:
	enter_button.pressed.connect(_on_enter_pressed)
	username_input.text_submitted.connect(func(_t): _on_enter_pressed())

func _on_enter_pressed() -> void:
	var username := username_input.text.strip_edges()
	if username.is_empty():
		username_input.placeholder_text = "Enter a name first!"
		return
	SceneManager.change_scene("res://scenes/global_map/global_map.tscn")
