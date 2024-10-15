@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("MapMagicTerrain", "Node3D", preload("res://addons/mapmagic_godot/mapmagic_terrain_node.gd"), preload("res://icon.svg"))


func _exit_tree() -> void:
	remove_custom_type("MapMagicTerrain")
