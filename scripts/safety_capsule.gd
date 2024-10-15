extends Node3D

@export var ANIMATION : AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ANIMATION.play("RESET")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_door_area_body_entered(body: Node3D) -> void:
	if body.name == "Character":
		ANIMATION.play("open_door")

func _on_door_area_body_exited(body: Node3D) -> void:
	if body.name == "Character":
		ANIMATION.play("close_door")
