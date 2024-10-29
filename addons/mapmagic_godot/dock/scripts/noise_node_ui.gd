@tool
extends Panel

var id: int
var mapmagic_terrain_id: int

var noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_PERLIN
var seed: int = 0
var frequency: float = 0.01
var octaves: int = 3
var plane_size: Vector2 = Vector2(1000, 1000)
var resolution: int = 200
var height_scale: float = 100.0

var noise = FastNoiseLite.new()
var noise_image: Image

var dragging = false
var drag_start_position = Vector2()

func _ready() -> void:
	if not is_connected("gui_input", _on_gui_input):
		connect("gui_input", _on_gui_input)

func add_node(node_id: int, mapmagic_terrain_node: MapMagicTerrain) -> void:
	id = node_id
	mapmagic_terrain_id = mapmagic_terrain_node.id
	var mesh_instance = MeshInstance3D.new()
	create_mesh(mesh_instance)
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
		
		mesh_instance.mesh = surface_tool.commit()

func generate_noise_image() -> Image:
	noise.noise_type = noise_type
	noise.seed = seed
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	
	var image = Image.create(resolution, resolution, false, Image.FORMAT_RF)
	for x in range(resolution):
		for y in range(resolution):
			var noise_value = noise.get_noise_2d(x, y)
			image.set_pixel(x, y, Color(noise_value, 0, 0))
	
	return image

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start_position = get_global_mouse_position() - global_position
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_start_position
