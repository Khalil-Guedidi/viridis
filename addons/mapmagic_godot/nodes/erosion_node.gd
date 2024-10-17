@tool
extends BaseNode

class_name ErosionNode

@export var erosion_strength: float = 0.1:
	set(value):
		erosion_strength = value
		if update_terrain:
			update_terrain.call(self)

var original_mesh: Mesh = null

func transform_mesh(mesh: Mesh) -> Mesh:
	if not original_mesh:
		original_mesh = mesh.duplicate()
	
	if not original_mesh:
		return mesh
	
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
	
	return surface_tool.commit()
