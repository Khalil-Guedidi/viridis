@tool
extends BaseNode

class_name InputNode

@export var node_after: BaseNode:
	set(new_node):
		if new_node is ModifierNode or new_node is OutputNode or not new_node:
			if node_after:
				if node_after.node_after:
					new_node = node_after.node_after
				else:
					node_after.remove_node()
			if new_node:
				new_node.root_node = root_node
				new_node.node_before = self
				new_node.add_node()
			node_after = new_node

func create_mesh() -> void:
	pass

func remove_node() -> void:
	if Engine.is_editor_hint():
		var terrain_mesh = root_node.find_child("TerrainMesh")
		if terrain_mesh:
			terrain_mesh.queue_free()

func update_next_node() -> void:
	if Engine.is_editor_hint():
		if node_after:
			node_after.update_node()
