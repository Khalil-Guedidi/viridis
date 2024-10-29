@tool
extends Node3D

class_name MapMagicTerrain

var id: int = int(Time.get_unix_time_from_system())

#@export var entrypoint: InputNode:
	#set(new_entrypoint):
		#if new_entrypoint == null:
			#entrypoint.remove_node()
		#else:
			#new_entrypoint.root_node = self
			#new_entrypoint.add_node()
		#entrypoint = new_entrypoint

@export var editor_panel_path: String = "res://.godot/mapmagic_godot/" + str(id) + "/editor_panel.tscn"

func _ready() -> void:
	if not FileAccess.file_exists(editor_panel_path):
		DirAccess.make_dir_recursive_absolute("res://.godot/mapmagic_godot/" + str(id))
		var editor_panel = preload("res://addons/mapmagic_godot/dock/scenes/editor_panel.tscn")
		ResourceSaver.save(editor_panel, editor_panel_path)
