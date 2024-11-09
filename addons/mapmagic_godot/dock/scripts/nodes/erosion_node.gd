@tool
extends Panel

@export_storage var id: int
@export_storage var mapmagic_terrain: String

@export_storage var erosion_strength: float = 0.1

@export_storage var node_before_path

var dragging = false
var drag_start_position = Vector2()

func _ready() -> void:
	if Engine.is_editor_hint():
		if not is_connected("gui_input", _on_gui_input):
			connect("gui_input", _on_gui_input)
		if not $DeleteNode.is_connected("pressed", _on_delete_node):
			$DeleteNode.pressed.connect(_on_delete_node)
		if not $NodeBefore/Button.is_connected("pressed", _on_node_before_pressed):
			$NodeBefore/Button.pressed.connect(_on_node_before_pressed)
		
		for node in find_children("*"):
			if node.is_in_group("values"):
				node.value_changed.connect(_on_change_property.bind(node))

func add_node(node_id: int, mapmagic_terrain_node: MapMagicTerrain) -> void:
	if Engine.is_editor_hint():
		id = node_id
		mapmagic_terrain = mapmagic_terrain_node.get_path()

func transform_mesh(mesh_instance: MeshInstance3D) -> void:
	if Engine.is_editor_hint():
		var original_mesh = get_node(node_before_path).mesh
		
		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var array_mesh = original_mesh.surface_get_arrays(0)
		var vertices = array_mesh[Mesh.ARRAY_VERTEX]
		var indices = array_mesh[Mesh.ARRAY_INDEX]
		var uvs = array_mesh[Mesh.ARRAY_TEX_UV]
		
		for i in range(vertices.size()):
			var vertex = vertices[i]
			vertex.y -= erosion_strength * randf()
			vertices[i] = vertex
		
		array_mesh[Mesh.ARRAY_VERTEX] = vertices
		
		for j in range(vertices.size()):
			surface_tool.set_uv(uvs[j])
			surface_tool.add_vertex(vertices[j])
		
		for index in indices:
			surface_tool.add_index(index)
		
		surface_tool.generate_normals()
		surface_tool.generate_tangents()
		
		mesh_instance.mesh = surface_tool.commit()

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

func _on_change_property(value, node) -> void:
	if Engine.is_editor_hint():
		match node.get_parent().name:
			"Strength":
				erosion_strength = value
		
		if get_node(mapmagic_terrain).has_node("TerrainMesh"):
			transform_mesh(get_node(mapmagic_terrain).get_node("TerrainMesh"))

func _on_delete_node() -> void:
	if Engine.is_editor_hint():
		if get_node(mapmagic_terrain).has_node("TerrainMesh"):
			get_node(mapmagic_terrain).get_node("TerrainMesh").queue_free()
		
		if node_before_path:
			get_node(node_before_path).remove_connection_line()
		
		queue_free()

func _on_node_before_pressed() -> void:
	if not node_before_path and get_node(mapmagic_terrain).node_before_to_set_path:
		node_before_path = get_node(mapmagic_terrain).node_before_to_set_path
		get_node(node_before_path).setting_node_after = false
		get_node(node_before_path).node_after_path = get_path()
		get_node(mapmagic_terrain).node_before_to_set_path = null
