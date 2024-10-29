@tool
extends Control

var mapmagic_terrain_node: MapMagicTerrain

func _ready() -> void:
	EditorInterface.get_selection().connect("selection_changed", _on_editor_selection_changed)
	$VBoxContainer/ToolsPanel/HBoxContainer/MenuButton.get_popup().id_pressed.connect(_on_add_node_item_pressed)

func _on_editor_selection_changed() -> void:
	if EditorInterface.get_selection().get_selected_nodes() and EditorInterface.get_selection().get_selected_nodes()[0] is MapMagicTerrain:
		mapmagic_terrain_node = EditorInterface.get_selection().get_selected_nodes()[0]
		open_editor_panel()
	else:
		close_editor_panel()

func open_editor_panel() -> void:
	var editor_panel = load(mapmagic_terrain_node.editor_panel_path).instantiate()
	$VBoxContainer.add_child(editor_panel)
	#$VBoxContainer/EditorPanel.load_nodes(mapmagic_terrain_node.nodes)

func close_editor_panel() -> void:
	if $VBoxContainer.has_node("EditorPanel"):
		var scene = PackedScene.new()
		scene.pack($VBoxContainer/EditorPanel)
		ResourceSaver.save(scene, mapmagic_terrain_node.editor_panel_path)
		$VBoxContainer/EditorPanel.queue_free()

func _on_add_node_item_pressed(id: int):
	match id:
		0:
			var noise = preload("res://addons/mapmagic_godot/dock/scenes/noise_node.tscn").instantiate()
			if $VBoxContainer.has_node("EditorPanel"):
				$VBoxContainer/EditorPanel/Content.add_child(noise)
				noise.owner = $VBoxContainer/EditorPanel
				var node_id = $VBoxContainer/EditorPanel/Content.get_child_count()
				noise.add_node(node_id, mapmagic_terrain_node)
				var scene = PackedScene.new()
				scene.pack($VBoxContainer/EditorPanel)
				ResourceSaver.save(scene, mapmagic_terrain_node.editor_panel_path)
