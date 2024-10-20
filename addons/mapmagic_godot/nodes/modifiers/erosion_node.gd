@tool
extends ModifierNode

class_name ErosionNode

@export var erosion_strength: float = 0.1:
	set(value):
		erosion_strength = value
		transform_mesh()
		update_next_node()

func add_node() -> void:
	if Engine.is_editor_hint():
		transform_mesh()

func update_node() -> void:
	transform_mesh()
	update_next_node()

func transform_mesh() -> void:
	var original_mesh = node_before.mesh_instance.mesh
	
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
