extends Node

var swipe_start = Vector2.ZERO
var minimum_drag = 100 # the minimum pixel distance to count as a deliberate swipe

func _input(event):
	# because we enabled touch emulation, mouse clicks will trigger this
	if event is InputEventScreenTouch:
		if event.pressed:
			# user just touched the screen
			swipe_start = event.position
		else:
			# user lifted their finger
			_calculate_swipe(event.position)

func _calculate_swipe(swipe_end):
	var swipe_vector = swipe_end - swipe_start
	
	# check if the swipe was long enough to ignore accidental taps
	if swipe_vector.length() >= minimum_drag:
		var angle = swipe_vector.angle()

		# split the circle into 8 equal sectors (45 degrees each)
		if angle >= -PI / 8 and angle < PI / 8:
			print("swiped right - parry right!")
		elif angle >= PI / 8 and angle < 3 * PI / 8:
			print("swiped down-right - low right guard!")
		elif angle >= 3 * PI / 8 and angle < 5 * PI / 8:
			print("swiped down - block!")
		elif angle >= 5 * PI / 8 and angle < 7 * PI / 8:
			print("swiped down-left - low left guard!")
		elif angle >= 7 * PI / 8 or angle < -7 * PI / 8:
			print("swiped left - parry left!")
		elif angle >= -7 * PI / 8 and angle < -5 * PI / 8:
			print("swiped up-left - rising left strike!")
		elif angle >= -5 * PI / 8 and angle < -3 * PI / 8:
			print("swiped up - vertical strike!")
		else:
			print("swiped up-right - rising right strike!")