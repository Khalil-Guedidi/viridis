@tool
extends BaseNode

class_name GrassNode

@export var texture: Texture2D:
	set(value):
		texture = value
		if update_terrain:
			update_terrain.call(self)

@export var grass_density: float = 0.1:
	set(value):
		grass_density = value
		if update_terrain:
			update_terrain.call(self)

@export var grass_height: float = 1.0:
	set(value):
		grass_height = value
		if update_terrain:
			update_terrain.call(self)

@export var wind_strength: float = 0.1:
	set(value):
		wind_strength = value
		if update_terrain:
			update_terrain.call(self)

var multimesh: MultiMesh
var multimesh_instance: MultiMeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.name = "GrassMultiMesh"
		get_local_scene().find_child("MapMagicTerrain").add_child(multimesh_instance)
		multimesh_instance.owner = get_local_scene().get_tree().edited_scene_root

func transform_mesh(mesh: Mesh) -> Mesh:
	if not is_instance_valid(multimesh_instance):
		return mesh
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(mesh, 0)
	
	var array_mesh = surface_tool.commit()
	
	var vertices = array_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _create_grass_mesh()

	var grass_count = int(vertices.size() * grass_density)
	multimesh.instance_count = grass_count
	
	for i in range(grass_count):
		var random_vertex = vertices[randi() % vertices.size()]
		var transform = Transform3D()
		transform.origin = random_vertex
		transform = transform.looking_at(transform.origin + Vector3.UP, Vector3.BACK)
		transform = transform.scaled(Vector3(1, grass_height, 1))
		multimesh.set_instance_transform(i, transform)
	
	multimesh_instance.multimesh = multimesh
	
	# Wind shader
	var material = ShaderMaterial.new()
	material.shader = _create_grass_shader()
	material.set_shader_parameter("wind_strength", wind_strength)
	multimesh_instance.material_override = material
	
	material.set_shader_parameter("texture_albedo", texture)
	
	return mesh

func _create_grass_mesh() -> Mesh:
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(0.1, 0.1)
	plane_mesh.orientation = PlaneMesh.FACE_Y
	
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y

	surface_tool.set_material(material)

	return surface_tool.commit()


func _create_grass_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

	uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
	uniform float wind_strength : hint_range(0, 1) = 0.1;
	uniform vec2 wind_direction = vec2(1.0, 0.0);

	void vertex() {
		vec3 worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float wind = sin(TIME * 2.0 + worldPos.x * 0.5 + worldPos.z * 0.5) * wind_strength;
		VERTEX.x += wind * wind_direction.x;
		VERTEX.z += wind * wind_direction.y;
	}

	void fragment() {
		vec4 albedo_tex = texture(texture_albedo, UV);
		ALBEDO = albedo_tex.rgb;
		ALPHA = albedo_tex.a;
		ALPHA_SCISSOR_THRESHOLD = 0.5;
	}
	"""
	return shader
