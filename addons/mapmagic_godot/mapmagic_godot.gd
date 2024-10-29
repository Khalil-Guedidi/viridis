@tool
extends EditorPlugin

var dock

func _enter_tree() -> void:
	add_custom_type("MapMagicTerrain", "Node3D", preload("res://addons/mapmagic_godot/mapmagic_terrain_node.gd"), preload("res://icon.svg"))
	
	dock = preload("res://addons/mapmagic_godot/dock/scenes/nodes_editor.tscn").instantiate()
	add_control_to_bottom_panel(dock, "Map Magic")

func _exit_tree() -> void:
	remove_custom_type("MapMagicTerrain")
	remove_control_from_bottom_panel(dock)
	dock.free()
