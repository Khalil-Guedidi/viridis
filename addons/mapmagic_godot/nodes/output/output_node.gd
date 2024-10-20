@tool
extends BaseNode

class_name OutputNode

var node_before: BaseNode

func add_node() -> void:
	if Engine.is_editor_hint():
		mesh_instance.mesh = node_before.mesh_instance.mesh
		mesh_instance.name = "TerrainMesh"
		root_node.add_child(mesh_instance)
		mesh_instance.owner = root_node.get_tree().edited_scene_root

func update_node() -> void:
	if Engine.is_editor_hint():
		mesh_instance.mesh = node_before.mesh_instance.mesh

func remove_node() -> void:
	if Engine.is_editor_hint():
		root_node.find_child("TerrainMesh").queue_free()
