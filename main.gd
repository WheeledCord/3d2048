#sorry for my lack of comments... i dont usually comment unless its for a group project or something haha

extends Node3D

const GRID_SIZE = 3
const TILE_SCENE = preload("res://Tile.tscn")

@onready var wireframe_root = $WireframeGrid
@onready var grid_root      = $GridRoot
@onready var camera         = $CameraRig/Camera3D
@onready var score_label    = $CanvasLayer/ScoreLabel

var grid: Dictionary = {}
var score: int = 0
var high_score: int = 0
var move_tween: Tween

func _ready() -> void:
	load_high_score()
	draw_wireframe_grid()
	reset_game()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reset_game()
		return
	if event is InputEventKey and event.pressed:
		var dir = Vector3.ZERO
		match event.keycode:
			KEY_W:            dir = get_camera_direction().z * -1
			KEY_S:            dir = get_camera_direction().z
			KEY_A:            dir = get_camera_direction().x * -1
			KEY_D:            dir = get_camera_direction().x
			KEY_SPACE:        dir = Vector3.UP
			KEY_SHIFT, KEY_C: dir = Vector3.DOWN
		if dir != Vector3.ZERO:
			dir = get_move_axis(dir)
			if move_tiles(dir):
				spawn_random_tile()
				spawn_random_tile()

func reset_game() -> void:
	for child in grid_root.get_children():
		child.queue_free()
	grid.clear()
	score = 0
	update_score_label()
	spawn_random_tile()
	spawn_random_tile()

func get_camera_direction() -> Dictionary:
	var b = camera.global_transform.basis
	return {
		"x": b.x.normalized(),
		"y": b.y.normalized(),
		"z": b.z.normalized()
	}

func get_move_axis(raw_dir: Vector3) -> Vector3:
	var best = Vector3.ZERO
	var max_dot = 0.0
	for axis in [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]:
		var d = abs(raw_dir.dot(axis))
		if d > max_dot:
			max_dot = d
			best = axis * sign(raw_dir.dot(axis))
	return best

func move_tiles(direction: Vector3) -> bool:
	var moved = false
	var sorted = get_sorted_positions(direction)
	var merged: Array = []
	for pos in sorted:
		if not pos in grid:
			continue
		var tile = grid[pos]
		var current_pos = pos
		var target_pos = pos
		while true:
			var next_pos = current_pos + Vector3i(direction)
			if not is_in_bounds(next_pos):
				break
			if next_pos in grid:
				var other = grid[next_pos]
				if other.value == tile.value and not next_pos in merged:
					target_pos = next_pos
				break
			current_pos = next_pos
			target_pos = next_pos
		if target_pos != pos:
			grid.erase(pos)
			if target_pos in grid:
				var other = grid[target_pos]
				tile.value *= 2
				score += tile.value
				if score > high_score:
					high_score = score
					save_high_score()
				update_score_label()
				other.queue_free()
				grid_root.remove_child(other)
				merged.append(target_pos)
				tile.animate_merge()
			grid[target_pos] = tile
			tile.move_to(grid_to_world(target_pos))
			moved = true
	grid = clean_grid()
	return moved

func get_sorted_positions(direction: Vector3) -> Array:
	var positions = grid.keys()
	positions.sort_custom(func(a, b):
		return Vector3(a).dot(direction) > Vector3(b).dot(direction)
	)
	return positions

func clean_grid() -> Dictionary:
	var clean = {}
	for pos in grid:
		clean[pos] = grid[pos]
	return clean

func spawn_random_tile() -> void:
	var empty: Array = []
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			for z in GRID_SIZE:
				var p = Vector3i(x, y, z)
				if not p in grid:
					empty.append(p)
	if empty.is_empty():
		return
	var new_pos = empty.pick_random()
	var tile = TILE_SCENE.instantiate()
	tile.value = 2
	tile.global_position = grid_to_world(new_pos)
	tile.animate_spawn()
	grid_root.add_child(tile)
	grid[new_pos] = tile

func is_in_bounds(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE \
	   and pos.y >= 0 and pos.y < GRID_SIZE \
	   and pos.z >= 0 and pos.z < GRID_SIZE

func grid_to_world(pos: Vector3i) -> Vector3:
	var off = Vector3(GRID_SIZE * 0.5 - 0.5,
					  GRID_SIZE * 0.5 - 0.5,
					  GRID_SIZE * 0.5 - 0.5)
	return (Vector3(pos) - off) * 1.5

func draw_wireframe_grid() -> void:
	var size = 1.5
	var half = size * 0.5
	var off = Vector3(GRID_SIZE * 0.5 - 0.5,
					  GRID_SIZE * 0.5 - 0.5,
					  GRID_SIZE * 0.5 - 0.5)
	var corners = [
		Vector3(-half, -half, -half), Vector3( half, -half, -half),
		Vector3( half,  half, -half), Vector3(-half,  half, -half),
		Vector3(-half, -half,  half), Vector3( half, -half,  half),
		Vector3( half,  half,  half), Vector3(-half,  half,  half)
	]
	var edges = [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			for z in GRID_SIZE:
				var m = ImmediateMesh.new()
				m.surface_begin(Mesh.PRIMITIVE_LINES)
				var center = (Vector3(x, y, z) - off) * size
				for e in edges:
					m.surface_add_vertex(corners[e[0]] + center)
					m.surface_add_vertex(corners[e[1]] + center)
				m.surface_end()
				var mi = MeshInstance3D.new()
				mi.mesh = m
				var mat = StandardMaterial3D.new()
				mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
				mat.albedo_color     = Color(0.5, 0.5, 0.5, 1)
				mi.material_override = mat
				wireframe_root.add_child(mi)

func update_score_label() -> void:
	score_label.text = "Score: %d\nHigh Score: %d" % [score, high_score]

func save_high_score() -> void:
	if Engine.has_singleton("JavaScript"):
		var js = Engine.get_singleton("JavaScript")
		var script = "document.cookie = 'highScore=' + %d + ';path=/;max-age=' + %d;" % [high_score, 60*60*24*365]
		js.eval(script, false)

func load_high_score() -> void:
	if Engine.has_singleton("JavaScript"):
		var js = Engine.get_singleton("JavaScript")
		var script = "(()=>{let m=document.cookie.match(/(?:^|; )highScore=(\\\\d+)/);return m?m[1]:'0';})()"
		var result = js.eval(script, true)
		high_score = int(result)
