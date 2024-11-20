@tool
extends Node3D

var mapmagic_terrain: NodePath
@export_storage var multimeshes: Dictionary = {}
@export_storage var bounds_min = Vector3.INF
@export_storage var bounds_max = -Vector3.INF
@export_storage var cell_size: float
@export_storage var max_distance: float
@export_storage var min_density: float
@export_storage var max_density: float
@export_storage var grass_height: float
@export_storage var texture_path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mapmagic_terrain = get_parent().get_parent().get_path()
	
	for child in get_children():
		child.get_node("Area3D").body_entered.connect(_on_body_entered.bind(child))

func update_loaded_multimeshes(mesh_instance_name: String) -> void:
	var player_x = int(mesh_instance_name.reverse()[2])
	var player_y = int(mesh_instance_name.reverse()[0])
	
	for node in get_children():
		var node_x = int(node.name.reverse()[2])
		var node_y = int(node.name.reverse()[0])
		
		if abs(player_x - node_x) <= 1 and abs(player_y - node_y) <= 1:
			if not node.multimesh:
				node.multimesh = multimeshes[node.name]
		else:
			if node.multimesh:
				node.multimesh = null

func create_multimeshes(node_before_path, _cell_size, _max_distance, _min_density, _max_density, _grass_height, _texture_path) -> void:
	if Engine.is_editor_hint():
		var original_mesh = get_node(node_before_path).mesh
		var mdt = MeshDataTool.new()
		mdt.create_from_surface(original_mesh, 0)
		
		bounds_min = Vector3.INF
		bounds_max = -Vector3.INF
		cell_size = _cell_size
		max_distance = _max_distance
		min_density = _min_density
		max_density = _max_density
		grass_height = _grass_height
		texture_path = _texture_path
		
		for i in range(mdt.get_vertex_count()):
			var vertex = mdt.get_vertex(i)
			bounds_min = bounds_min.min(vertex)
			bounds_max = bounds_max.max(vertex)
		
		var cell_count_x = ceil((bounds_max.x - bounds_min.x) / cell_size)
		var cell_count_z = ceil((bounds_max.z - bounds_min.z) / cell_size)
		
		var mesh = create_grass_mesh()
		
		for cell_x in range(cell_count_x):
			for cell_z in range(cell_count_z):
				var cell_min = Vector3(
					bounds_min.x + cell_x * cell_size,
					bounds_min.y,
					bounds_min.z + cell_z * cell_size
				)
				var cell_max = Vector3(
					cell_min.x + cell_size,
					bounds_max.y,
					cell_min.z + cell_size
				)

				var multimesh = MultiMesh.new()
				multimesh.transform_format = MultiMesh.TRANSFORM_3D
				multimesh.mesh = mesh

				var instance_positions = generate_grass_instances(mdt, cell_min, cell_max)
				multimesh.instance_count = instance_positions.size()
				for i in range(instance_positions.size()):
					multimesh.set_instance_transform(i, instance_positions[i])

				var multimesh_instance = MultiMeshInstance3D.new()
				multimesh_instance.name = "GrassInstance_{x}_{y}".format({"x": cell_x, "y": cell_z})
				multimesh_instance.transform.origin = (cell_min + cell_max) * 0.5
				multimesh_instance.visibility_range_end = max_distance
				multimesh_instance.visibility_range_end_margin = max_distance / 10
				multimesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				add_child(multimesh_instance)
				multimesh_instance.owner = get_tree().edited_scene_root
				
				multimeshes[multimesh_instance.name] = multimesh
				
				var detection_area = Area3D.new()
				detection_area.name = "Area3D"
				multimesh_instance.add_child(detection_area)
				detection_area.owner = get_tree().edited_scene_root
				
				var detection_collision = CollisionShape3D.new()
				detection_collision.name = "CollisionShape3D"
				var detection_shape = BoxShape3D.new()
				detection_shape.size = Vector3(cell_size, 1000, cell_size)
				detection_collision.shape = detection_shape
				detection_area.add_child(detection_collision)
				detection_collision.owner = get_tree().edited_scene_root

func generate_grass_instances(mdt: MeshDataTool, cell_min: Vector3, cell_max: Vector3) -> Array:
	var positions = []
	var cell_bounds = AABB(cell_min, cell_max - cell_min)

	# Calcul du centre de la cellule
	var cell_center = (cell_min + cell_max) * 0.5

	for triangle in range(mdt.get_face_count()):
		var vertex1 = mdt.get_vertex(mdt.get_face_vertex(triangle, 0))
		var vertex2 = mdt.get_vertex(mdt.get_face_vertex(triangle, 1))
		var vertex3 = mdt.get_vertex(mdt.get_face_vertex(triangle, 2))

		if !cell_bounds.intersects_segment(vertex1, vertex2) and !cell_bounds.intersects_segment(vertex2, vertex3) and !cell_bounds.intersects_segment(vertex3, vertex1):
			continue

		var density = randf_range(min_density, max_density)
		var count = int(density * 100)
		for i in range(count):
			var position = random_point_in_triangle(vertex1, vertex2, vertex3)
			if cell_bounds.has_point(position):
				var normal = mdt.get_face_normal(triangle).normalized()
				var transform = align_with_normal(normal)

				# Ajuster le point d'origine pour correspondre au centre de la cellule
				transform.origin = position - cell_center

				transform *= Transform3D().rotated(Vector3.UP, randf() * TAU)
				transform.scaled(Vector3.ONE * randf_range(0.75, 1.25) * grass_height)

				positions.append(transform)

	return positions

func create_grass_mesh():
	if Engine.is_editor_hint() and texture_path:
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
		var image_texture = load(texture_path)
		material.albedo_texture = image_texture
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.surface_set_material(0, material)

		return mesh

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

func _on_body_entered(body: Node3D, mesh_instance):
	if body.name == "Character":
		update_loaded_multimeshes(mesh_instance.name)
