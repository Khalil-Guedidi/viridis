@tool
extends Panel

@export_storage var id: int
@export_storage var mapmagic_terrain: String

@export_storage var texture_path: String
@export_storage var uv_scale: Vector3 = Vector3(1, 1, 1)
@export_storage var uv_offset: Vector3 = Vector3.ZERO

@export_storage var mesh: Mesh

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
	if Engine.is_editor_hint() and texture_path:
		var original_mesh = get_node(node_before_path).mesh
		
		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		surface_tool.create_from(original_mesh, 0)
		
		var image_texture = load(texture_path)
		
		var material = StandardMaterial3D.new()
		material.albedo_texture = image_texture
		
		material.uv1_scale = uv_scale
		material.uv1_offset = uv_offset
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		material.texture_repeat = true
		
		surface_tool.set_material(material)
		
		mesh = surface_tool.commit()
		get_node(mapmagic_terrain + "/TerrainMesh").mesh = mesh
		
		if node_after_path:
			get_node(node_after_path).transform_mesh()

func _on_texture_path_changed(path: String) -> void:
	texture_path = path
	transform_mesh()

func _on_change_property(value, node) -> void:
	if Engine.is_editor_hint():
		match node.get_parent().name:
			"Size":
				if node.name == "x":
					uv_scale.x = value
				else:
					uv_scale.y = value
			"Point":
				if node.name == "x":
					uv_offset.x = value
				else:
					uv_offset.y = value
		
		if get_node(mapmagic_terrain).has_node("TerrainMesh") and node_before_path:
			transform_mesh()

func remove_connection_line():
	node_after_path = null
	$NodeAfter/Button/Line.remove_point(1)
	$NodeAfter/Button/Line.remove_point(0)

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
			if node_after_path:
				$NodeAfter/Button/Line.set_point_position(1, (get_node(str(node_after_path) + "/NodeBefore/Button").global_position + Vector2(10, 10) - $NodeAfter/Button/Line.global_position) * 2)

func _on_delete_node() -> void:
	if Engine.is_editor_hint():		
		if node_before_path and get_node(mapmagic_terrain).has_node("TerrainMesh"):
			get_node(mapmagic_terrain + "/TerrainMesh").mesh = get_node(node_before_path).mesh
			get_node(node_before_path).remove_connection_line()
		
		queue_free()

func _on_node_before_pressed() -> void:
	if not node_before_path and get_node(mapmagic_terrain).node_before_to_set_path:
		node_before_path = get_node(mapmagic_terrain).node_before_to_set_path
		get_node(node_before_path).setting_node_after = false
		get_node(node_before_path).node_after_path = get_path()
		get_node(mapmagic_terrain).node_before_to_set_path = null
		if get_node(mapmagic_terrain).has_node("TerrainMesh"):
			transform_mesh()
	else:
		if get_node(mapmagic_terrain).has_node("TerrainMesh"):
			get_node(mapmagic_terrain + "/TerrainMesh").mesh = get_node(node_before_path).mesh
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
