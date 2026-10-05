extends SceneTree

# 2048奶龙版 无头测试：定向合并 + fuzz 不变量
# 运行: godot --headless --path . -s tests/run_tests.gd

var failures: Array[String] = []
var checks := 0

func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		printerr("  FAIL: ", msg)

func values_of_row(m, i: int) -> Array:
	var out := []
	for c in m.map[i]:
		out.append(c.log2_value if c != null else 0)
	return out

func values_of_col(m, j: int) -> Array:
	var out := []
	for i in 4:
		var c = m.map[i][j]
		out.append(c.log2_value if c != null else 0)
	return out

func count_pieces(m) -> int:
	var n := 0
	for row in m.map:
		for c in row:
			if c != null:
				n += 1
	return n

func validate_board(m, ctx: String) -> void:
	if m.map.size() != 4:
		check(false, ctx + ": map 不是 4 行")
		return
	for i in 4:
		if m.map[i].size() != 4:
			check(false, ctx + ": 行 %d 长度异常" % i)
			return
		for j in 4:
			var c = m.map[i][j]
			if c != null:
				check(c is Piece, ctx + ": (%d,%d) 不是 Piece" % [i, j])
				check(c.log2_value >= 1, ctx + ": (%d,%d) log2_value=%d 非法" % [i, j, c.log2_value])

# spec: 4x4 的 log2 值矩阵，0 = 空
func setup_board(m, spec: Array) -> void:
	m.clean_map()
	for i in 4:
		for j in 4:
			if spec[i][j] > 0:
				m.place_piece(Vector2(i + 1, j + 1), spec[i][j])
	m.update_map()

func _initialize() -> void:
	print("== 2048奶龙版 无头测试 ==")
	var main = load("res://scene/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# ---------- 0. 环境 ----------
	check(main.gif_bytes.size() == 43, "预加载数量应为 43, 实际 %d" % main.gif_bytes.size())
	check(main.gif_bytes[1].size() > 1000, "1.bin 字节异常: %d" % main.gif_bytes[1].size())

	# ---------- 1. 新棋子 Label 同步 ----------
	main.clean_map()
	var p = main.place_piece(Vector2(1, 1), 2)  # 值 = 4
	main.update_map()
	check(p.get_node("Value").text == "4", "新棋子(值=4) Label 显示 '%s' (应为 4)" % p.get_node("Value").text)

	# ---------- 2. 定向合并: _on_up_pressed (对行操作, 向 index 0 合并) ----------
	# Case A: [1,1,2,2] -> 前部应为 [2,3]
	setup_board(main, [[1,1,2,2],[3,4,3,4],[4,3,4,3],[3,4,3,4]])
	main._on_up_pressed()
	var r: Array = values_of_row(main, 0)
	check(r[0] == 2 and r[1] == 3, "CaseA [1,1,2,2] 上-> 前部 [2,3], 实际 %s" % str(r))
	check((r[2] == 0 and r[3] == 0) or ((r[2] in [1, 2]) and r[3] == 0), "CaseA 尾部应为至多1个新棋子(1或2), 实际 %s" % str(r))

	# Case B: [1,1,1,1] -> 前部 [2,2]
	setup_board(main, [[1,1,1,1],[3,4,3,4],[4,3,4,3],[3,4,3,4]])
	main._on_up_pressed()
	r = values_of_row(main, 0)
	check(r[0] == 2 and r[1] == 2, "CaseB [1,1,1,1] -> 前部 [2,2], 实际 %s" % str(r))

	# Case C: [1,2,3,3] -> [1,2,4,x]
	setup_board(main, [[1,2,3,3],[3,4,3,4],[4,3,4,3],[3,4,3,4]])
	main._on_up_pressed()
	r = values_of_row(main, 0)
	check(r[0] == 1 and r[1] == 2 and r[2] == 4, "CaseC [1,2,3,3] -> [1,2,4], 实际 %s" % str(r))

	# Case D: 无合并无移动 -> 棋盘完全不变, 且不放新子
	setup_board(main, [[1,2,1,2],[2,1,2,1],[1,2,1,2],[2,1,2,1]])
	main._on_up_pressed()
	check(count_pieces(main) == 16, "CaseD 死锁盘不应变化, 棋子数 %d" % count_pieces(main))
	check(values_of_row(main, 0) == [1,2,1,2], "CaseD 行0不应变化, 实际 %s" % str(values_of_row(main, 0)))

	# ---------- 3. 定向合并: _on_down_pressed (向 index 3) ----------
	setup_board(main, [[1,1,2,2],[3,4,3,4],[4,3,4,3],[3,4,3,4]])
	main._on_down_pressed()
	r = values_of_row(main, 0)
	check(r[2] == 2 and r[3] == 3, "CaseE [1,1,2,2] 下-> 尾部 [2,3], 实际 %s" % str(r))

	# ---------- 4. 定向合并: _on_left_pressed (对列操作, 向顶部合并) ----------
	setup_board(main, [[1,3,4,3],[1,4,3,4],[2,3,4,3],[2,4,3,4]])
	main._on_left_pressed()
	var cv: Array = values_of_col(main, 0)
	check(cv[0] == 2 and cv[1] == 3, "CaseF 列[1,1,2,2] left-> 顶部 [2,3], 实际 %s" % str(cv))

	# ---------- 5. 定向合并: _on_right_pressed (向底部) ----------
	setup_board(main, [[1,3,4,3],[1,4,3,4],[2,3,4,3],[2,4,3,4]])
	main._on_right_pressed()
	cv = values_of_col(main, 0)
	check(cv[2] == 2 and cv[3] == 3, "CaseG 列[1,1,2,2] right-> 底部 [2,3], 实际 %s" % str(cv))

	# ---------- 6. 合并后 Label 与数值同步 ----------
	setup_board(main, [[1,1,2,2],[3,4,3,4],[4,3,4,3],[3,4,3,4]])
	main._on_up_pressed()
	var survivor = main.map[0][0]
	if survivor != null:
		check(survivor.get_node("Value").text == str(2 ** survivor.log2_value),
			"合并后 Label '%s' 与值 %d 不同步" % [survivor.get_node("Value").text, 2 ** survivor.log2_value])

	# ---------- 7. fuzz: 200 步随机滑动 ----------
	var dirs := ["_on_up_pressed", "_on_down_pressed", "_on_left_pressed", "_on_right_pressed"]
	var crash_free := true
	for n in 200:
		var before := count_pieces(main)
		main.call(dirs[randi() % 4])
		moves_note()
		validate_board(main, "fuzz#%d" % n)
		var after := count_pieces(main)
		# after = before - 合并数(0~8) + 1(新子); 无变化时相等
		if after < before - 8 or after > before + 1:
			check(false, "fuzz#%d 棋子数异常 %d -> %d" % [n, before, after])
		if n % 10 == 0:
			await process_frame
	await process_frame

	# ---------- 8. 满盘死锁: 持续填充到满, 再滑动不应崩溃 ----------
	setup_board(main, [[1,2,1,2],[2,1,2,1],[1,2,1,2],[2,1,2,1]])
	for d in dirs:
		main.call(d)
	check(count_pieces(main) == 16, "死锁盘滑动后棋子数 %d" % count_pieces(main))
	await process_frame

	print("\n== 结果: %d 项检查, %d 项失败 ==" % [checks, failures.size()])
	for f in failures:
		print("  - ", f)
	quit(1 if failures.size() > 0 else 0)

func moves_note() -> void:
	pass
