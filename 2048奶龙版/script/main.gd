extends Node2D
var scene_piece := preload("res://scene/piece.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var piece = scene_piece.instantiate()
	piece.map_position=Vector2(1,1)
	piece.position=64*piece.map_position
	add_child(piece)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
