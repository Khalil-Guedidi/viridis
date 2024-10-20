@tool
extends Node3D

class_name MapMagicTerrain

var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape = CollisionShape3D

@export var nodes: Array[BaseNode] = [NoiseNode.new()]:
	set(value):
		nodes = value
		_update_terrain()

func _init() -> void:
	if Engine.is_editor_hint():
		pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not mesh_instance:
		_create_mesh_instance()
	
	if not static_body:
		_setup_collision()
	
	_update_terrain()

func _create_mesh_instance():
	if mesh_instance:
		mesh_instance.queue_free()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	
	add_child(mesh_instance)
	if Engine.is_editor_hint():
		mesh_instance.owner = get_tree().edited_scene_root

func _setup_collision():
	if static_body:
		static_body.queue_free()
	
	static_body = StaticBody3D.new()
	static_body.name = "TerrainBody"
	add_child(static_body)
	
	if Engine.is_editor_hint():
		static_body.owner = get_tree().edited_scene_root
	
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "TerrainCollision"
	
	static_body.add_child(collision_shape)
	
	if Engine.is_editor_hint():
		collision_shape.owner = get_tree().edited_scene_root

func update_terrain(node):
	mesh_instance.mesh = node.transform_mesh(mesh_instance.mesh)

func _update_terrain():
	if not mesh_instance:
		_create_mesh_instance()
	
	if not static_body:
		_setup_collision()
	
	var current_mesh = mesh_instance.mesh
	
	for node in nodes:
		if not node:
			continue
		if not node.update_terrain:
			node.update_terrain = Callable(self, "update_terrain")
		
		current_mesh = node.transform_mesh(current_mesh)
	
	mesh_instance.mesh = current_mesh
	
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(current_mesh.get_faces())
	collision_shape.shape = shape
