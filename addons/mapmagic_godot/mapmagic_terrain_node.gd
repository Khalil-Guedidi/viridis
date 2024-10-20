@tool
extends Node3D

class_name MapMagicTerrain

#var mesh_instance: MeshInstance3D
#var static_body: StaticBody3D
#var collision_shape = CollisionShape3D

@export var entrypoint: InputNode:
	set(new_entrypoint):
		if new_entrypoint == null:
			entrypoint.remove_node()
		else:
			new_entrypoint.root_node = self
			new_entrypoint.add_node()
		entrypoint = new_entrypoint

#@export var nodes: Array[BaseNode] = [NoiseNode.new()]:
	#set(value):
		#nodes = value
		#_update_terrain()
#
#func _init() -> void:
	#if Engine.is_editor_hint():
		#pass
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#if Engine.is_editor_hint():
		#mesh_instance = find_child("TerrainMesh")
		#static_body = find_child("TerrainBody")
		#collision_shape = find_child("TerrainBody/TerrainCollision")
		#
		#if not mesh_instance:
			#_create_mesh_instance()
		#
		#if not static_body:
			#_setup_collision()
		#
		#_update_terrain()
#
#func _create_mesh_instance():
	#if Engine.is_editor_hint():
		#mesh_instance = MeshInstance3D.new()
		#mesh_instance.name = "TerrainMesh"
		#
		#add_child(mesh_instance)
		#if Engine.is_editor_hint():
			#mesh_instance.owner = get_tree().edited_scene_root
#
#func _setup_collision():
	#if Engine.is_editor_hint():
		#static_body = StaticBody3D.new()
		#static_body.name = "TerrainBody"
		#add_child(static_body)
		#
		#static_body.owner = get_tree().edited_scene_root
		#
		#collision_shape = CollisionShape3D.new()
		#collision_shape.name = "TerrainCollision"
		#
		#static_body.add_child(collision_shape)
		#
		#collision_shape.owner = get_tree().edited_scene_root
#
#func update_terrain(node):
	#if Engine.is_editor_hint():
		#mesh_instance.mesh = node.transform_mesh(mesh_instance.mesh)
#
#func _update_terrain():
	#if Engine.is_editor_hint():
		#var current_mesh = mesh_instance.mesh
		#
		#for node in nodes:
			#if not node:
				#continue
			#if not node.update_terrain:
				#node.update_terrain = Callable(self, "update_terrain")
			#
			#current_mesh = node.transform_mesh(current_mesh)
		#
		#mesh_instance.mesh = current_mesh
		#
		#var shape = ConcavePolygonShape3D.new()
		#shape.set_faces(current_mesh.get_faces())
		#collision_shape.shape = shape
