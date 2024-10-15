@tool
extends Resource

class_name BaseNode

var inputs = {}
var outputs = {}

func get_output(key):
	return outputs.get(key)

func set_input(key, value):
	inputs[key] = value
