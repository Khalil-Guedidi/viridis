@tool
extends BaseNode

class_name NoiseNode

@export var noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_PERLIN:
	set(value):
		noise_type = value
		if update_terrain:
			update_terrain.call(self)

@export var seed: int = 0:
	set(value):
		seed = value
		if update_terrain:
			update_terrain.call(self)

@export var frequency: float = 0.01:
	set(value):
		frequency = value
		if update_terrain:
			update_terrain.call()

@export var octaves: int = 3:
	set(value):
		octaves = value
		if update_terrain:
			update_terrain.call(self)

@export var plane_size: Vector2 = Vector2(1000, 1000):
	set(value):
		plane_size = value
		if update_terrain:
			update_terrain.call(self)

@export var resolution: int = 200:
	set(value):
		resolution = value
		if update_terrain:
			update_terrain.call(self)

@export var height_scale: float = 100.0:
	set(value):
		height_scale = value
		if update_terrain:
			update_terrain.call(self)

var noise = FastNoiseLite.new()
var noise_image: Image

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func transform_mesh(mesh: Mesh) -> Mesh:
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
	
	return mesh

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
