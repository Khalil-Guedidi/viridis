@tool

extends ModifierNode

class_name TextureNode

@export var texture: Texture2D:
	set(value):
		texture = value
		update_node()

@export var uv_scale: Vector3 = Vector3(1, 1, 1):
	set(value):
		uv_scale = value
		update_node()

@export var uv_offset: Vector3 = Vector3.ZERO:
	set(value):
		uv_offset = value
		update_node()

func add_node() -> void:
	if Engine.is_editor_hint():
		transform_mesh()

func update_node() -> void:
	if Engine.is_editor_hint():
		transform_mesh()
		update_next_node()

func transform_mesh() -> void:
	var original_mesh = node_before.mesh_instance.mesh
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	surface_tool.create_from(original_mesh, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	
	material.uv1_scale = uv_scale
	material.uv1_offset = uv_offset
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.texture_repeat = true
	
	surface_tool.set_material(material)
	
	mesh_instance.mesh = surface_tool.commit()
