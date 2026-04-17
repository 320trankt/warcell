extends CanvasLayer
## Draws an animated slash trail from swipe start to end, then fades out.

const FADE_DURATION := 0.35
const LINE_WIDTH := 6.0
const ARROW_SIZE := 18.0
const GLOW_WIDTH := 14.0

var _trails: Array[Node] = []

func show_swipe(from: Vector2, to: Vector2, color: Color) -> void:
	var trail := _SwipeTrailLine.new(from, to, color)
	add_child(trail)
	_trails.append(trail)
	trail.animate()

## Internal drawing node — one per swipe
class _SwipeTrailLine extends Control:
	var from_pos: Vector2
	var to_pos: Vector2
	var trail_color: Color
	var progress: float = 0.0  # 0→1 draw-in
	var alpha: float = 1.0

	func _init(p_from: Vector2, p_to: Vector2, p_color: Color) -> void:
		from_pos = p_from
		to_pos = p_to
		trail_color = p_color
		# Full-screen so we can draw anywhere
		set_anchors_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE

	func animate() -> void:
		# Phase 1: draw the slash (fast)
		var tween := create_tween()
		tween.tween_property(self, "progress", 1.0, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		# Phase 2: hold briefly then fade out
		tween.tween_interval(0.1)
		tween.tween_property(self, "alpha", 0.0, FADE_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(queue_free)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if progress <= 0.0 or alpha <= 0.0:
			return

		var end := from_pos.lerp(to_pos, progress)
		var dir := (to_pos - from_pos).normalized()

		# Glow layer (wider, semi-transparent)
		var glow_color := Color(trail_color, alpha * 0.3)
		draw_line(from_pos, end, glow_color, GLOW_WIDTH, true)

		# Main slash line
		var main_color := Color(trail_color, alpha)
		draw_line(from_pos, end, main_color, LINE_WIDTH, true)

		# Bright core (thin, white-ish)
		var core_color := Color(1.0, 1.0, 1.0, alpha * 0.6)
		draw_line(from_pos, end, core_color, 2.0, true)

		# Arrowhead at the tip
		if progress > 0.3:
			var perp := Vector2(-dir.y, dir.x)
			var arrow_base := end - dir * ARROW_SIZE
			var p1 := arrow_base + perp * ARROW_SIZE * 0.45
			var p2 := arrow_base - perp * ARROW_SIZE * 0.45
			var arrow_points := PackedVector2Array([end, p1, p2])
			var arrow_colors := PackedColorArray([main_color, main_color, main_color])
			draw_polygon(arrow_points, arrow_colors)

		# Small dot at origin
		draw_circle(from_pos, 4.0, Color(1.0, 1.0, 1.0, alpha * 0.5))
