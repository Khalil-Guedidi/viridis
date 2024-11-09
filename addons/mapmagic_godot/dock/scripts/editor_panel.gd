@tool
extends Panel

var zoom_factor = 0.5
var zoom_speed = 0.05
var min_zoom = 0.2
var max_zoom = 2.0

@onready var content = $Content

var is_dragging = false
var drag_start_position = Vector2.ZERO

func _ready() -> void:
	if Engine.is_editor_hint():
		content.scale = Vector2.ONE * zoom_factor

func load_nodes(nodes: Array[BaseNode]) -> void:
	if Engine.is_editor_hint():
		for node in nodes:
			var node_scene = load(node.associated_ui_scene).instantiate()
			$Content.add_child(node_scene)

func zoom(factor, mouse_pos) -> void:
	if Engine.is_editor_hint():
		if not content:
			return
		
		var old_zoom = zoom_factor
		zoom_factor *= factor
		zoom_factor = clamp(zoom_factor, min_zoom, max_zoom)

		var viewport_size = get_viewport_rect().size
		var old_position = content.global_position
		var old_mouse_offset = mouse_pos - old_position

		content.scale = Vector2.ONE * zoom_factor

		var new_mouse_offset = old_mouse_offset * (zoom_factor / old_zoom)
		var new_position = mouse_pos - new_mouse_offset

		content.global_position = new_position

func _on_gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		if event is InputEventMouseButton:
			var mouse_pos = get_global_mouse_position()
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom(1 + zoom_speed, mouse_pos)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom(1 / (1 + zoom_speed), mouse_pos)
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					is_dragging = true
					drag_start_position = mouse_pos - content.global_position
				else:
					is_dragging = false
		elif event is InputEventMouseMotion and is_dragging:
			content.global_position = get_global_mouse_position() - drag_start_position
