@tool
extends BaseNode

class_name OutputNode

var node_before: BaseNode
@export var node_after: BaseNode:
	set(node):
		if node_after:
			node_after.remove_node()
		if node is DetailNode:
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

func add_node() -> void:
	if Engine.is_editor_hint():
		mesh_instance.mesh = node_before.mesh_instance.mesh
		mesh_instance.name = "TerrainMesh"
		root_node.add_child(mesh_instance)
		mesh_instance.owner = root_node.get_tree().edited_scene_root
		setup_collision()

func setup_collision() -> void:
	var static_body = StaticBody3D.new()
	static_body.name = "TerrainBody"
	root_node.find_child("TerrainMesh").add_child(static_body)
	
	static_body.owner = root_node.get_tree().edited_scene_root
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "TerrainCollision"
	
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(mesh_instance.mesh.get_faces())
	collision_shape.shape = shape
	
	static_body.add_child(collision_shape)
	
	collision_shape.owner = root_node.get_tree().edited_scene_root

func update_node() -> void:
	if Engine.is_editor_hint():
		mesh_instance.mesh = node_before.mesh_instance.mesh
		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(mesh_instance.mesh.get_faces())
		root_node.find_child("TerrainCollision").shape = shape

func remove_node() -> void:
	if Engine.is_editor_hint():
		root_node.find_child("TerrainMesh").queue_free()
