@tool
extends Resource

class_name BaseNode

var root_node: Node3D
var update_terrain: Callable

var mesh_instance: MeshInstance3D = MeshInstance3D.new()

func transform_mesh() -> void:
	pass

func update_node() -> void:
	pass

func update_next_node() -> void:
	pass

func add_node() -> void:
	pass

func remove_node() -> void:
	pass
