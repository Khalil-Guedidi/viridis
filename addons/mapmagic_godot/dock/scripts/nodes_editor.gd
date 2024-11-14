@tool
extends Control

var mapmagic_terrain_node: MapMagicTerrain

func _ready() -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_selection().connect("selection_changed", _on_editor_selection_changed)
		$VBoxContainer/ToolsPanel/HBoxContainer/MenuButton.get_popup().id_pressed.connect(_on_add_node_item_pressed)

func _on_editor_selection_changed() -> void:
	if Engine.is_editor_hint():
		if EditorInterface.get_selection().get_selected_nodes() and EditorInterface.get_selection().get_selected_nodes()[0] is MapMagicTerrain:
			mapmagic_terrain_node = EditorInterface.get_selection().get_selected_nodes()[0]
			open_editor_panel()
		else:
			close_editor_panel()

func open_editor_panel() -> void:
	if Engine.is_editor_hint():
		var editor_panel = load(mapmagic_terrain_node.editor_panel_path).instantiate()
		$VBoxContainer.add_child(editor_panel)

func close_editor_panel() -> void:
	if Engine.is_editor_hint():
		if $VBoxContainer.has_node("EditorPanel"):
			$VBoxContainer/EditorPanel.queue_free()
			if EditorInterface.get_edited_scene_root().has_node("MapMagicTerrain"):
				var scene = PackedScene.new()
				scene.pack($VBoxContainer/EditorPanel)
				ResourceSaver.save(scene, mapmagic_terrain_node.editor_panel_path)

func _on_add_node_item_pressed(id: int):
	if Engine.is_editor_hint():
		match id:
			0:
				var noise = preload("res://addons/mapmagic_godot/dock/scenes/nodes/noise_node.tscn").instantiate()
				if $VBoxContainer.has_node("EditorPanel") && mapmagic_terrain_node:
					$VBoxContainer/EditorPanel/Content.add_child(noise)
					set_editable_instance(noise, true)
					noise.owner = $VBoxContainer/EditorPanel
					var node_id = $VBoxContainer/EditorPanel/Content.get_child_count()
					noise.add_node(node_id, mapmagic_terrain_node)
					var scene = PackedScene.new()
					scene.pack($VBoxContainer/EditorPanel)
					ResourceSaver.save(scene, mapmagic_terrain_node.editor_panel_path)
			1:
				var erosion = preload("res://addons/mapmagic_godot/dock/scenes/nodes/erosion_node.tscn").instantiate()
				if $VBoxContainer.has_node("EditorPanel") && mapmagic_terrain_node:
					$VBoxContainer/EditorPanel/Content.add_child(erosion)
					set_editable_instance(erosion, true)
					erosion.owner = $VBoxContainer/EditorPanel
					var node_id = $VBoxContainer/EditorPanel/Content.get_child_count()
					erosion.add_node(node_id, mapmagic_terrain_node)
					var scene = PackedScene.new()
					scene.pack($VBoxContainer/EditorPanel)
					ResourceSaver.save(scene, mapmagic_terrain_node.editor_panel_path)
			2:
				var texture = preload("res://addons/mapmagic_godot/dock/scenes/nodes/texture_node.tscn").instantiate()
				if $VBoxContainer.has_node("EditorPanel") && mapmagic_terrain_node:
					$VBoxContainer/EditorPanel/Content.add_child(texture)
					set_editable_instance(texture, true)
					texture.owner = $VBoxContainer/EditorPanel
					var node_id = $VBoxContainer/EditorPanel/Content.get_child_count()
					texture.add_node(node_id, mapmagic_terrain_node)
					var scene = PackedScene.new()
					scene.pack($VBoxContainer/EditorPanel)
					ResourceSaver.save(scene, mapmagic_terrain_node.editor_panel_path)
			3:
				var grass = preload("res://addons/mapmagic_godot/dock/scenes/nodes/grass_node.tscn").instantiate()
				if $VBoxContainer.has_node("EditorPanel") && mapmagic_terrain_node:
					$VBoxContainer/EditorPanel/Content.add_child(grass)
					set_editable_instance(grass, true)
					grass.owner = $VBoxContainer/EditorPanel
					var node_id = $VBoxContainer/EditorPanel/Content.get_child_count()
					grass.add_node(node_id, mapmagic_terrain_node)
					var scene = PackedScene.new()
					scene.pack($VBoxContainer/EditorPanel)
					ResourceSaver.save(scene, mapmagic_terrain_node.editor_panel_path)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		if $VBoxContainer.has_node("EditorPanel"):
			$VBoxContainer/EditorPanel.queue_free()
			if EditorInterface.get_edited_scene_root().has_node("MapMagicTerrain"):
				var scene = PackedScene.new()
				scene.pack($VBoxContainer/EditorPanel)
				ResourceSaver.save(scene, mapmagic_terrain_node.editor_panel_path)
