extends Node2D

class_name Piece
 
var  shown_index:int
var log2_value:int  #label标签上 显示的值（这里用2为底的对数表示） 

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	shown_index  = log2_value
	$Value.text = str(2**log2_value)
	$AnimatedImagePlayer.load_from_file(
			"res://img/milk_dragon_img/%d.bin" % log2_value	)
 
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
 

func _on_update_img(gif_bytes):	
	if log2_value != shown_index:
		shown_index = log2_value
		$Value.text = str(2**log2_value)
		var bytes = gif_bytes.get(log2_value)
		if bytes == null: #假如有大神超过了43张，就使用默认sprite
			$AnimatedImagePlayer.load_from_file(
			"res://img/milk_dragon_img/43.bin")
			return 			
		$AnimatedImagePlayer.animated_image = AnimatedImageTexture.load_from_buffer(bytes)
		$AnimatedImagePlayer.play()