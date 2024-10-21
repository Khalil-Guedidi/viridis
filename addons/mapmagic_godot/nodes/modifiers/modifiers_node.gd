@tool
extends BaseNode

class_name ModifierNode

var node_before: BaseNode
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

func update_next_node() -> void:
	if Engine.is_editor_hint():
		if node_after:
			node_after.update_node()
