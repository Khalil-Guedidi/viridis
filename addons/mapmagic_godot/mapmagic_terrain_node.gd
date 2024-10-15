@tool
extends Node3D

class_name MapMagicTerrain

@export var plane_size: Vector2 = Vector2(1000, 1000):
	set(value):
		plane_size = value
		_create_mesh_instance()
		_update_terrain()

@export var resolution: int = 200:
	set(value):
		resolution = value
		_update_terrain()

@export var noise_seed: int = 0:
	set(value):
		noise_seed = value
		if noise_node:
			noise_node.seed = value
			_update_terrain()

@export var noise_frequency: float = 0.01:
	set(value):
		noise_frequency = value
		if noise_node:
			noise_node.frequency = value
			_update_terrain()

@export var noise_ocatves: int = 3:
	set(value):
		noise_ocatves = value
		if noise_node:
			noise_node.octaves = value
			_update_terrain()

@export var height_scale: float = 100.0:
	set(value):
		height_scale = value
		_update_terrain()

var mesh_instance: MeshInstance3D
var noise_node: NoiseNode

func _init() -> void:
	print("MapMagicTerrain initialized")
	if Engine.is_editor_hint():
		print("Running in editor")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("MapMagicTerrain ready")
	if not mesh_instance:
		print("Mesh null. Creating one")
		_create_mesh_instance()
	
	if not noise_node:
		print("No noise detected. Creating one")
		noise_node = NoiseNode.new()
	
	print("Assigning new seed : " + str(noise_seed))
	noise_node.seed = noise_seed
	print("Assigning new frequency : " + str(noise_frequency))
	noise_node.frequency = noise_frequency
	print("Assigning new octaves : " + str(noise_ocatves))
	noise_node.octaves = noise_ocatves
	
	_update_terrain()

func _create_mesh_instance():
	if mesh_instance:
		mesh_instance.queue_free()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	
	add_child(mesh_instance)
	if Engine.is_editor_hint():
		mesh_instance.owner = get_tree().edited_scene_root

func _update_terrain():
	print("Updating terrain")
	print("Mesh instance :" + str(mesh_instance))
	print("Noise node instance :" + str(noise_node))
	if not mesh_instance or not noise_node:
		print("No mesh or noise found. Update stopped")
		return
	
	print("Generating noise")
	noise_node.generate_noise()
	var noise_image = noise_node.get_output("noise")
	print("Noise image" + str(noise_image))
	
	print("Creating new surface")
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(resolution):
		for x in range (resolution):
			var percent = Vector2(x, z) / (resolution - 1)
			var point_on_mesh = Vector3(
				percent.x * plane_size.x - plane_size.x / 2,
				0,
				percent.y * plane_size.y - plane_size.y / 2
			)
			
			var noise_value = noise_image.get_pixelv(Vector2(
				clamp(percent.x * 1000, 0, 999),
				clamp(percent.y * 1000, 0, 999)
				)).r

			point_on_mesh.y = noise_value * height_scale
			
			surface_tool.set_uv(percent)
			surface_tool.add_vertex(point_on_mesh)
	
	for z in range(resolution - 1):
		for x in range(resolution - 1):
			var i = z * resolution + x
			surface_tool.add_index(i)
			surface_tool.add_index(i + resolution + 1)
			surface_tool.add_index(i + resolution)
			surface_tool.add_index(i)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + resolution + 1)
			
	surface_tool.generate_normals()
	surface_tool.generate_tangents()

	mesh_instance.mesh = surface_tool.commit()
