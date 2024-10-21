@tool
extends BaseNode

class_name InputNode

@export var node_after: BaseNode:
	set(node):
		if node_after:
			node_after.remove_node()
		if node is ModifierNode or node is OutputNode:
			node.root_node = root_node
			node.node_before = self
			node.add_node()
			node_after = node
		if not node:
			if node_after.get("node_after"):
				node = node_after.node_after
				node.node_before = self
				node.update_node()
			
			node_after = node

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
