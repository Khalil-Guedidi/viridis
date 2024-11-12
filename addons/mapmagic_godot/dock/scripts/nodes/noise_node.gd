@tool
extends Panel

@export_storage var id: int
@export_storage var mapmagic_terrain: String

@export_storage var noise_type_number: int = 0
@export_storage var seed: int = 0
@export_storage var frequency: float = 0.01
@export_storage var octaves: int = 3
@export_storage var plane_size: Vector2 = Vector2(1000, 1000)
@export_storage var resolution: int = 200
@export_storage var height_scale: float = 100.0

@export_storage var mesh: Mesh

@export_storage var node_after_path

var noise = FastNoiseLite.new()
var noise_image: Image

var dragging = false
var drag_start_position = Vector2()

var setting_node_after: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		if not is_connected("gui_input", _on_gui_input):
			connect("gui_input", _on_gui_input)
		if not $DeleteNode.is_connected("pressed", _on_delete_node):
			$DeleteNode.pressed.connect(_on_delete_node)
		if not $NodeAfter/Button.is_connected("pressed", _on_node_after_pressed):
			$NodeAfter/Button.pressed.connect(_on_node_after_pressed)
		
		for node in find_children("*"):
			if node.is_in_group("values"):
				if node.get_parent().name == "NoiseType":
					node.item_selected.connect(_on_noise_type_changed)
				else:
					node.value_changed.connect(_on_change_property.bind(node))
		
		$MarginContainer/VBoxContainer/Properties/NoiseType/Value.selected = noise_type_number if noise_type_number else 0

func _process(delta: float) -> void:
	if setting_node_after:
		$NodeAfter/Button/Line.set_point_position(1, $NodeAfter/Button/Line.get_local_mouse_position())

func add_node(node_id: int, mapmagic_terrain_node: MapMagicTerrain) -> void:
	if Engine.is_editor_hint():
		id = node_id
		mapmagic_terrain = mapmagic_terrain_node.get_path()
		noise_type_number = 0
		var mesh_instance = MeshInstance3D.new()
		create_mesh(mesh_instance)
		mesh = mesh_instance.mesh
		mesh_instance.name = "TerrainMesh"
		mapmagic_terrain_node.add_child(mesh_instance)
		mesh_instance.owner = get_tree().edited_scene_root

func create_mesh(mesh_instance: MeshInstance3D) -> void:
	if Engine.is_editor_hint():
		noise_image = generate_noise_image()
		
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
					clamp(percent.x * resolution, 0, resolution - 1),
					clamp(percent.y * resolution, 0, resolution - 1)
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
		
		mesh = surface_tool.commit()
		mesh_instance.mesh = mesh
		
		if node_after_path:
			get_node(node_after_path).transform_mesh()

func generate_noise_image() -> Image:
	noise.noise_type = noise_type_number
	noise.seed = seed
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	
	var image = Image.create(resolution, resolution, false, Image.FORMAT_RF)
	for x in range(resolution):
		for y in range(resolution):
			var noise_value = noise.get_noise_2d(x, y)
			image.set_pixel(x, y, Color(noise_value, 0, 0))
	
	return image

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
			if node_after_path:
				$NodeAfter/Button/Line.set_point_position(1, (get_node(str(node_after_path) + "/NodeBefore/Button").global_position + Vector2(10, 10) - $NodeAfter/Button/Line.global_position) * 2)

func _on_noise_type_changed(index: int) -> void:
	if Engine.is_editor_hint():
		match index:
			0:
				noise_type_number = FastNoiseLite.TYPE_SIMPLEX
			1:
				noise_type_number = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			2:
				noise_type_number = FastNoiseLite.TYPE_CELLULAR
			3:
				noise_type_number = FastNoiseLite.TYPE_PERLIN
			4:
				noise_type_number = FastNoiseLite.TYPE_VALUE_CUBIC
			5:
				noise_type_number = FastNoiseLite.TYPE_VALUE

		if get_node(mapmagic_terrain).has_node("TerrainMesh"):
			create_mesh(get_node(mapmagic_terrain).get_node("TerrainMesh"))

func _on_change_property(value, node) -> void:
	if Engine.is_editor_hint():
		match node.get_parent().name:
			"Seed":
				seed = value
			"Frequency":
				frequency = value
			"Octaves":
				octaves = value
			"Size":
				if node.name == "x":
					plane_size.x = value
				else:
					plane_size.y = value
			"Resolution":
				resolution = value
			"HeightScale":
				height_scale = value
		
		if get_node(mapmagic_terrain).has_node("TerrainMesh"):
			create_mesh(get_node(mapmagic_terrain).get_node("TerrainMesh"))

func _on_delete_node() -> void:
	if Engine.is_editor_hint():
		if get_node(mapmagic_terrain).has_node("TerrainMesh"):
			get_node(mapmagic_terrain).get_node("TerrainMesh").queue_free()
		
		if node_after_path:
			get_node(node_after_path).node_before_path = null
		queue_free()

func _on_node_after_pressed() -> void:
	if not node_after_path:
		get_node(mapmagic_terrain).node_before_to_set_path = get_path()
		$NodeAfter/Button/Line.add_point(Vector2(15, 15))
		setting_node_after = true
		$NodeAfter/Button/Line.add_point(Vector2(15, 15))
