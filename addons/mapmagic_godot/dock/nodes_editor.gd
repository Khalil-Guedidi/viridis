@tool
extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EditorInterface.get_selection().connect("selection_changed", _on_editor_selection_changed)

func _on_editor_selection_changed() -> void:
	if EditorInterface.get_selection().get_selected_nodes()[0] is MapMagicTerrain:
		open_editor_panel()
	else:
		close_editor_panel()

func open_editor_panel() -> void:
	var editor_panel = preload("res://addons/mapmagic_godot/dock/editor_panel.tscn").instantiate()
	$VBoxContainer.add_child(editor_panel)

func close_editor_panel() -> void:
	if $VBoxContainer.has_node("EditorPanel"):
		$VBoxContainer/EditorPanel.queue_free()
