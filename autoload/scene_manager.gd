extends CanvasLayer
## Global scene transition manager. Autoloaded as "SceneManager".

var _fade_rect: ColorRect

func _ready() -> void:
	layer = 100
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

func change_scene(path: String, fade_duration: float = 0.3) -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var tween_out := create_tween()
	tween_out.tween_property(_fade_rect, "color:a", 0.0, fade_duration)
	await tween_out.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
