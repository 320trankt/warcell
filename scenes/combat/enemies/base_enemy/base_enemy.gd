extends Node3D

var mesh: MeshInstance3D

func _ready():
    mesh = _find_mesh_instance(self)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
    for child in node.get_children():
        if child is MeshInstance3D:
            return child
        var result = _find_mesh_instance(child)
        if result:
            return result
    return null

func take_hit():
    var tween = create_tween()
    var mat = mesh.get_active_material(0)
    
    tween.tween_property(mat, "albedo_color", Color.RED, 0.1)
    tween.parallel().tween_property(self, "position:z", position.z + 0.2, 0.05)
    
    tween.tween_property(mat, "albedo_color", Color.WHITE, 0.1)
    tween.parallel().tween_property(self, "position:z", position.z, 0.1)