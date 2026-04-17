extends Control

@onready var stats_container: VBoxContainer = %StatsContainer
@onready var resources_container: VBoxContainer = %ResourcesContainer
@onready var points_label: Label = %PointsLabel
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_resources_section()
	_build_stats_section()
	_update_points_label()

func _build_resources_section() -> void:
	for key in PlayerData.RESOURCE_INFO:
		var info: Dictionary = PlayerData.RESOURCE_INFO[key]
		var row := _create_resource_row(info)
		resources_container.add_child(row)

func _build_stats_section() -> void:
	for key in PlayerData.STAT_INFO:
		var info: Dictionary = PlayerData.STAT_INFO[key]
		var value: int = PlayerData.get_stat(key)
		var row := _create_stat_row(key, info, value)
		stats_container.add_child(row)

func _create_resource_row(info: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.14, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = info.display
	title.add_theme_color_override("font_color", info.color)
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = info.description
	desc.add_theme_color_override("font_color", Color(0.55, 0.5, 0.48, 1))
	desc.add_theme_font_size_override("font_size", 13)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	return panel

func _create_stat_row(stat_key: String, info: Dictionary, value: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.14, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Top row: icon, name, value, upgrade button
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	vbox.add_child(top_row)

	var icon_label := Label.new()
	icon_label.text = info.icon
	icon_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.28, 1))
	icon_label.add_theme_font_size_override("font_size", 16)
	icon_label.custom_minimum_size.x = 40
	top_row.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = info.display
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 1))
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = str(value)
	value_label.name = "ValueLabel"
	value_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7, 1))
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 36
	top_row.add_child(value_label)

	var upgrade_btn := Button.new()
	upgrade_btn.text = "+"
	upgrade_btn.name = "UpgradeButton"
	upgrade_btn.custom_minimum_size = Vector2(44, 44)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.25, 0.4, 0.25, 1)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	upgrade_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.3, 0.5, 0.3, 1)
	btn_hover.corner_radius_top_left = 6
	btn_hover.corner_radius_top_right = 6
	btn_hover.corner_radius_bottom_left = 6
	btn_hover.corner_radius_bottom_right = 6
	upgrade_btn.add_theme_stylebox_override("hover", btn_hover)
	upgrade_btn.add_theme_font_size_override("font_size", 22)
	upgrade_btn.pressed.connect(_on_upgrade_pressed.bind(stat_key, value_label))
	top_row.add_child(upgrade_btn)

	# Description
	var desc := Label.new()
	desc.text = info.description
	desc.add_theme_color_override("font_color", Color(0.55, 0.5, 0.48, 1))
	desc.add_theme_font_size_override("font_size", 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	return panel

func _on_upgrade_pressed(stat_key: String, value_label: Label) -> void:
	if PlayerData.try_upgrade(stat_key):
		value_label.text = str(PlayerData.get_stat(stat_key))
		_update_points_label()

func _update_points_label() -> void:
	points_label.text = "Upgrade Points: %d" % PlayerData.upgrade_points

func _on_back_pressed() -> void:
	SceneManager.change_scene("res://scenes/global_map/global_map.tscn")
