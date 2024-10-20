@tool

extends BaseNode

class_name TextureNode

@export var texture: Texture2D:
	set(value):
		texture = value
		if update_terrain:
			update_terrain.call(self)

@export var uv_scale: Vector3 = Vector3(1, 1, 1):
	set(value):
		uv_scale = value
		if update_terrain:
			update_terrain.call(self)

@export var uv_offset: Vector3 = Vector3.ZERO:
	set(value):
		uv_offset = value
		if update_terrain:
			update_terrain.call(self)

func transform_mesh(mesh: Mesh) -> Mesh:
	if not texture:
		return mesh
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	surface_tool.create_from(mesh, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	
	material.uv1_scale = uv_scale
	material.uv1_offset = uv_offset
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.texture_repeat = true
	
	surface_tool.set_material(material)
	
	return surface_tool.commit()
