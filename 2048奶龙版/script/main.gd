#本程序面向过程进行开发

extends Node2D
var scene_piece := preload("res://scene/piece.tscn")

var map: Array[Array] = [[null,null,null,null],[null,null,null,null],[null,null,null,null],[null,null,null,null]]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	 
	random_place()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("up"):
		_on_up_pressed()
	elif  Input.is_action_just_pressed("down"):
		_on_down_pressed()
	elif  Input.is_action_just_pressed("right"):
		_on_right_pressed()
	elif  Input.is_action_just_pressed("left"):
		_on_left_pressed()





#region 直接参与游戏过程的重要方法
func random_place() -> void : #在map上随机放棋子
	#先获取所有 == null 的节点
	var empty : Array[Vector2]
	for i in range(4):
		for j in range(4):
			if map[i][j] == null:
				empty.append(Vector2(i,j))
	
	var random_pos: Vector2 = empty.pick_random() if not empty.is_empty() else Vector2(-1, -1) #选取随机位置，添加到map
	if random_pos != Vector2(-1,-1):
		var random := 1
		if(randf()>0.9):
			random = 2
		map[random_pos.x][random_pos.y] = place_piece(random_pos+Vector2(1,1),random) #这里加Vector2(1,1)的原因是 place_piece 的参数是地图坐标，不是数组索引
		update_map()			

func clean_map() -> void:
	#先释放掉所有节点
	for i in $Pieces.get_children():
		i.queue_free()		
	map  = [[null,null,null,null],[null,null,null,null],[null,null,null,null],[null,null,null,null]]
	update_map()


#endregion

#region 接近底层，游戏过程不直接调用的函数


func update_map() -> void: #将Map数据同步到场景树 
	#删除所有棋子节点，并重新绘制
	for i in $Pieces.get_children():
		$Pieces.remove_child(i)		
	for i in range(4):
		for j in range(4):
			if map[i][j]!=null:
				map[i][j].position = 128*Vector2(i+1,j+1)-Vector2(64,64)
				map[i][j].get_node("Value").text = str(2**map[i][j].log2_value)
				$Pieces.add_child(map[i][j])
#endregion
 
#region 显得有些冗余的历史遗留函数
func place_piece(map_position:Vector2,log2_value:=1) -> Node2D: #放置棋子于map,需要update才能同步到棋盘 value 可以不填 
	var piece = scene_piece.instantiate()	 
	piece.position = 128*map_position-Vector2(64,64) #减去一个vector(64,64) 让sprite对齐中心
	#$Pieces.add_child(piece)
	# if(randf()>0.9): #有10%概率生成一个4
	# 	log2_value =2 
	piece.log2_value = log2_value
	piece.get_node("Value").text =str(2**log2_value)
	#同步到map变量
	map[map_position.x-1][map_position.y-1]=piece;
	return  piece
#endregion

#region 按钮信号
func _on_reset_pressed() -> void: #重置整个游戏
	clean_map()
	random_place()

func _on_up_pressed() -> void: #上滑
	#先拷贝整个数组，用于比对，如果没有改动，那么就不随机生成
	var moved := false
	for i in range(4):		 
		var column =map[i]  #取得reference 
		for j in range(3):
			if column[j] == null:
				continue
			for k in range(1,4-j):
				if column[j+k] == null :
					continue
				if column[j].log2_value == column[j+k].log2_value: #相等，合并
					column[j].log2_value +=1					 
					column[j+k].queue_free()	
					column[j+k] = null				 
					moved = true		
					break
					
		#再通过冒泡法把所有的null下侧
		for j in range(4):
			for k in range(4-j-1):
				if column[k] == null and column[k+1] != null:
					column[k]=column[k+1]					 
					column[k+1]=null
					moved = true
	if moved:
		random_place() #该函数自带 update_map 所以上面的改动不需要update
 
func _on_down_pressed() -> void:
	#先拷贝整个数组，用于比对，如果没有改动，那么就不随机生成
	var moved := false
	for i in range(4):		 
		var column =map[i]  #取得reference 
		for j in range(3):
			if column[3-j] == null:
				continue
			for k in range(1,4-j):
				if column[3-j-k] == null :
					continue
				if column[3-j].log2_value == column[3-j-k].log2_value: #相等，合并
					column[3-j].log2_value +=1					 
					column[3-j-k].queue_free()	
					column[3-j-k] = null				 
					moved = true		
					break
					
		#再通过冒泡法把所有的null下侧
		for j in range(4):
			for k in range(4-j-1):
				if column[3-k] == null and column[3-k-1] != null:
					column[3-k]=column[3-k-1]					 
					column[3-k-1]=null
					moved = true
	if moved:
		random_place() #该函数自带 update_map 所以上面的改动不需要update


func _on_left_pressed() -> void:
	#先拷贝整个数组，用于比对，如果没有改动，那么就不随机生成
	var moved := false
	for i in range(4):		
		var column:Array=[]
		for j in range(4):
			column.append(map[j][i])  #取得reference 
		for j in range(3):
				if column[j] == null:
					continue
				for k in range(1,4-j):
					if column[j+k] == null :
						continue
					if column[j].log2_value == column[j+k].log2_value: #相等，合并
						column[j].log2_value +=1					 
						column[j+k].queue_free()
						column[j+k] = null											 
						moved = true		
						break	
					
		#再通过冒泡法把所有的null下侧
		for j in range(4):
			for k in range(4-j-1):
				if column[k] == null and column[k+1] != null:
					column[k]=column[k+1]					 
					column[k+1]=null
					moved = true
		#将第j行同步回去
		for j in range(4):
			map[j][i] = column[j]
	if moved:
		random_place() #该函数自带 update_map 所以上面的改动不需要update


func _on_right_pressed() -> void:
	#先拷贝整个数组，用于比对，如果没有改动，那么就不随机生成
	var moved := false
	for i in range(4):		
		var column:Array=[]
		for j in range(4):
			column.append(map[3-j][i])  #取得reference   #这里为了复用left代码，直接在写入column时倒过来写入，然后
		for j in range(3):
				if column[j] == null:
					continue
				for k in range(1,4-j):
					if column[j+k] == null :
						continue
					if column[j].log2_value == column[j+k].log2_value: #相等，合并
						column[j].log2_value +=1					 
						column[j+k].queue_free()
						column[j+k]=null						 
						moved = true		
						break	
					
		#再通过冒泡法把所有的null下侧
		for j in range(4):
			for k in range(4-j-1):
				if column[k] == null and column[k+1] != null:
					column[k]=column[k+1]					 
					column[k+1]=null					 
					moved = true
		#将第j行同步回去
		for j in range(4):
			map[3-j][i] = column[j]
	if moved:
		random_place() #该函数自带 update_map 所以上面的改动不需要update

#endregion



