@tool
extends Panel

@export_storage var id: int
@export_storage var mapmagic_terrain: String

@export_storage var texture_path: String
@export_storage var grass_height: float = 1.0
@export_storage var cell_size: float = 50.0
@export_storage var min_density: float = 0.01
@export_storage var max_density: float = 0.1
@export_storage var max_distance: float = 100.0

var multimesh: MultiMesh
var multimesh_instance: MultiMeshInstance3D

@export_storage var node_before_path
@export_storage var node_after_path

var dragging = false
var drag_start_position = Vector2()

var setting_node_after: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		if not is_connected("gui_input", _on_gui_input):
			connect("gui_input", _on_gui_input)
		if not $DeleteNode.is_connected("pressed", _on_delete_node):
			$DeleteNode.pressed.connect(_on_delete_node)
		if not $NodeBefore/Button.is_connected("pressed", _on_node_before_pressed):
			$NodeBefore/Button.pressed.connect(_on_node_before_pressed)
		if not $NodeAfter/Button.is_connected("pressed", _on_node_after_pressed):
			$NodeAfter/Button.pressed.connect(_on_node_after_pressed)
		if not $MarginContainer/VBoxContainer/Properties/Texture/TextureProperties/Preview.is_connected("pressed", _on_texture_button_pressed):
			$MarginContainer/VBoxContainer/Properties/Texture/TextureProperties/Preview.pressed.connect(_on_texture_button_pressed)
		if not $FileDialog.is_connected("file_selected", _on_file_dialog_file_selected):
			$FileDialog.file_selected.connect(_on_file_dialog_file_selected)
		
		for node in find_children("*"):
			if node.is_in_group("values"):
				if node.get_parent().name == "TextureProperties":
					node.text_changed.connect(_on_texture_path_changed)
				else:
					node.value_changed.connect(_on_change_property.bind(node))

func _process(delta: float) -> void:
	if setting_node_after:
		$NodeAfter/Button/Line.set_point_position(1, $NodeAfter/Button/Line.get_local_mouse_position())

func add_node(node_id: int, mapmagic_terrain_node: MapMagicTerrain) -> void:
	if Engine.is_editor_hint():
		id = node_id
		mapmagic_terrain = mapmagic_terrain_node.get_path()

func transform_mesh() -> void:
	if Engine.is_editor_hint():
		if node_before_path and get_node(mapmagic_terrain).has_node("TerrainMesh/GrassInstance"):
			get_node(mapmagic_terrain + "/TerrainMesh/GrassInstance").free()
		multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.name = "GrassInstance"
		get_node(mapmagic_terrain).find_child("TerrainMesh").add_child(multimesh_instance)
		multimesh_instance.owner = get_tree().edited_scene_root
		
		var original_mesh = get_node(node_before_path).mesh
		
		var mdt = MeshDataTool.new()
		mdt.create_from_surface(original_mesh, 0)

		multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = create_grass_mesh()

		var grass_count = int(mdt.get_vertex_count() * max_density)
		multimesh.instance_count = grass_count
		
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

func _on_texture_path_changed(path: String) -> void:
	texture_path = path
	transform_mesh()

func _on_change_property(value, node) -> void:
	if Engine.is_editor_hint():
		match node.get_parent().name:
			"GrassHeight":
				grass_height = value
			"CellSize":
				cell_size = value
			"DensityMin":
				min_density = value
			"DensityMax":
				max_density = value
			"MaxDistance":
				max_distance = value
		
		if get_node(mapmagic_terrain).has_node("TerrainMesh") and node_before_path:
			transform_mesh()

func _on_gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					dragging = true
					drag_start_position = get_global_mouse_position() - global_position
				else:
					dragging = false
		elif event is InputEventMouseMotion and dragging:
			global_position = get_global_mouse_position() - drag_start_position
			if node_before_path:
				get_node(str(node_before_path) + "/NodeAfter/Button/Line").set_point_position(1, ($NodeBefore/Button.global_position + Vector2(10, 10) - get_node(str(node_before_path) + "/NodeAfter/Button/Line").global_position) * 2)

func _on_delete_node() -> void:
	if Engine.is_editor_hint():		
		if node_before_path and get_node(mapmagic_terrain).has_node("TerrainMesh/GrassInstance"):
			get_node(mapmagic_terrain + "/TerrainMesh/GrassInstance").queue_free()
			get_node(node_before_path).remove_connection_line()
			
		queue_free()

func _on_node_before_pressed() -> void:
	if not node_before_path and get_node(mapmagic_terrain).node_before_to_set_path:
		node_before_path = get_node(mapmagic_terrain).node_before_to_set_path
		get_node(node_before_path).setting_node_after = false
		get_node(node_before_path).node_after_path = get_path()
		get_node(mapmagic_terrain).node_before_to_set_path = null
		if get_node(mapmagic_terrain).has_node("TerrainMesh") and texture_path:
			transform_mesh()
	else:
		if get_node(mapmagic_terrain).has_node("TerrainMesh/GrassInstance"):
			get_node(mapmagic_terrain + "/TerrainMesh/GrassInstance").queue_free()
			get_node(node_before_path).remove_connection_line()
			node_before_path = null

func _on_node_after_pressed() -> void:
	if not node_after_path:
		get_node(mapmagic_terrain).node_before_to_set_path = get_path()
		$NodeAfter/Button/Line.add_point(Vector2(15, 15))
		setting_node_after = true
		$NodeAfter/Button/Line.add_point(Vector2(15, 15))

func _on_texture_button_pressed() -> void:
	$FileDialog.popup()

func _on_file_dialog_file_selected(path) -> void:
	texture_path = path
	
	var image_texture = load(path)
	
	$MarginContainer/VBoxContainer/Properties/Texture/TextureProperties/Preview.texture_normal = image_texture
	$MarginContainer/VBoxContainer/Properties/Texture/TextureProperties/Preview/Label.visible = false
	$MarginContainer/VBoxContainer/Properties/Texture/TextureProperties/Path.text = path
	
	if get_node(mapmagic_terrain).has_node("TerrainMesh") and node_before_path:
			transform_mesh()
