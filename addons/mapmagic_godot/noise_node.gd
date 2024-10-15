@tool
extends BaseNode

class_name NoiseNode

@export var seed: int = 0
@export var frequency: float = 0.01
@export var octaves: int = 3

var noise = FastNoiseLite.new()

func _init() -> void:
	outputs["noise"] = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func generate_noise() -> void:
	noise.seed = seed
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	
	var image = Image.create(1000, 1000, false, Image.FORMAT_RF)
	for x in range(1000):
		for y in range(1000):
			var noise_value = noise.get_noise_2d(x, y)
			image.set_pixel(x, y, Color(noise_value, 0, 0))
	
	outputs["noise"] = image
