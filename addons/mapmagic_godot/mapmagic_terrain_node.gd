@tool
extends Node3D

class_name MapMagicTerrain

var id: int = int(Time.get_unix_time_from_system())

@export var editor_panel_path: String = "res://addons/mapmagic_godot/data/" + str(id) + "/editor_panel.tscn"

var node_before_to_set_path

func _ready() -> void:
	if Engine.is_editor_hint():
		if not FileAccess.file_exists(editor_panel_path):
			DirAccess.make_dir_recursive_absolute("res://addons/mapmagic_godot/data/" + str(id))
			var editor_panel = preload("res://addons/mapmagic_godot/dock/scenes/editor_panel.tscn")
			ResourceSaver.save(editor_panel, editor_panel_path)

func _on_delete_node() -> void:
	if Engine.is_editor_hint():
		DirAccess.remove_absolute("res://addons/mapmagic_godot/data/" + str(id) + "/editor_panel.tscn")
		DirAccess.remove_absolute("res://addons/mapmagic_godot/data/" + str(id))
