@tool
extends Resource

class_name BaseNode

var update_terrain: Callable

func transform_mesh(mesh: Mesh) -> Mesh:
	return Mesh.new()
