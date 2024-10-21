@tool
extends DetailNode

class_name GrassNode

@export var texture: Texture2D:
	set(value):
		texture = value
		update_node()

@export var grass_height: float = 1.0:
	set(value):
		grass_height = value
		update_node()

@export var cell_size: float = 50.0:
	set(value):
		cell_size = value
		update_node()

@export var min_density: float = 0.01:
	set(value):
		min_density = value
		update_node()

@export var max_density: float = 0.1:
	set(value):
		max_density = value
		update_node()

@export var max_distance: float = 100.0:
	set(value):
		max_distance = value
		update_node()

var multimesh: MultiMesh
var multimesh_instance: MultiMeshInstance3D

func _process(delta: float) -> void:
	update_detail()

# Called when the node enters the scene tree for the first time.
func add_node() -> void:
	if Engine.is_editor_hint():
		multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.name = "GrassInstance"
		root_node.find_child("TerrainMesh").add_child(multimesh_instance)
		multimesh_instance.owner = root_node.get_tree().edited_scene_root
		generate_detail()

func update_node() -> void:
	if Engine.is_editor_hint():
		generate_detail()

func remove_node() -> void:
	if Engine.is_editor_hint():
		root_node.find_child("GrassInstance").queue_free()

func calculate_density(distance: float) -> float:
	return lerp(max_density, min_density, distance / max_distance)

func update_detail() -> void:
	var camera_position = root_node.get_viewport().get_camera_3d().global_transform.origin
	var visible_instances = []
	
	for i in range(multimesh.instance_count):
		var transform = multimesh.get_instance_transform(i)
		var position = transform.origin
		
		if (position - camera_position).length() < cell_size:
			var distance_to_camera = (position - camera_position).length()
			var density_factor = calculate_density(distance_to_camera)
			
			if randf() < density_factor:
				visible_instances.append(transform)
	
	multimesh.instance_count = visible_instances.size()
	for i in range(visible_instances.size()):
		multimesh.set_instance_transform(i, visible_instances[i])

func generate_detail() -> void:
	var original_mesh = node_before.mesh_instance.mesh
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(original_mesh, 0)

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = create_grass_mesh()

	var grass_count = int(mdt.get_vertex_count() * max_density)
	multimesh.instance_count = grass_count
	
	var camera_position = root_node.get_viewport().get_camera_3d().global_transform.origin

	for i in range(grass_count):
		var random_triangle = randi() % mdt.get_face_count()
		var vertex1 = mdt.get_vertex(mdt.get_face_vertex(random_triangle, 0))
		var vertex2 = mdt.get_vertex(mdt.get_face_vertex(random_triangle, 1))
		var vertex3 = mdt.get_vertex(mdt.get_face_vertex(random_triangle, 2))

		var position = random_point_in_triangle(vertex1, vertex2, vertex3)
		
		var normal = mdt.get_face_normal(random_triangle).normalized()

		var transform = align_with_normal(normal)
		transform.origin = position

		var random_rotation = Transform3D().rotated(Vector3.UP, randf() * TAU)
		transform *= random_rotation

		var random_scale_factor = randf_range(0.75, 1.25) * grass_height
		transform.scaled(Vector3(random_scale_factor, random_scale_factor, random_scale_factor))

		multimesh.set_instance_transform(i, transform)
	
	multimesh_instance.multimesh = multimesh

func random_point_in_triangle(v1: Vector3, v2: Vector3, v3: Vector3) -> Vector3:
	var r1 = sqrt(randf())
	var r2 = randf()
	var a = 1.0 - r1
	var b = r1 * (1.0 - r2)
	var c = r1 * r2
	return a * v1 + b * v2 + c * v3

func align_with_normal(normal: Vector3) -> Transform3D:
	var up = normal.normalized()
	var right = up.cross(Vector3.BACK).normalized()
	var forward = up.cross(right).normalized()
	return Transform3D(right, up, forward, Vector3.ZERO)

func create_grass_mesh() -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_width = 0.5

	# Premier plan du billboard
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(-half_width, 0, 0))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(half_width, 0, 0))
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(-half_width, grass_height, 0))
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(half_width, grass_height, 0))

	st.add_index(0)
	st.add_index(1)
	st.add_index(2)
	st.add_index(1)
	st.add_index(3)
	st.add_index(2)

	# Second plan du billboard (rotation de 90 degrés)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0, 0, -half_width))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(0, 0, half_width))
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(0, grass_height, -half_width))
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(0, grass_height, half_width))

	st.add_index(4)
	st.add_index(5)
	st.add_index(6)
	st.add_index(5)
	st.add_index(7)
	st.add_index(6)

	st.generate_normals()
	st.generate_tangents()

	var mesh = st.commit()
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, material)

	return mesh
