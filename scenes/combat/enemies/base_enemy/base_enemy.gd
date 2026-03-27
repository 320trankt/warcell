extends CharacterBody3D

@onready var mesh = $MeshInstance3D

func take_hit():
	# 1. Create a "Tween" for the flash and shake
	var tween = create_tween()
	
	# 2. Flash Red (adjusting the Albedo color of the mesh)
	# This assumes you have a StandardMaterial3D on your mesh
	var mat = mesh.get_active_material(0)
	
	# Animate the color to red and back
	tween.tween_property(mat, "albedo_color", Color.RED, 0.1)
	tween.parallel().tween_property(self, "position:z", position.z + 0.2, 0.05) # Small jolt back
	
	tween.tween_property(mat, "albedo_color", Color.WHITE, 0.1)
	tween.parallel().tween_property(self, "position:z", position.z, 0.1) # Return to position