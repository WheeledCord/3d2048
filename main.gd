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

func _ready():
	load_high_score()
	draw_wireframe_grid()
	reset_game()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			reset_game()
			return

		var dir := Vector3.ZERO
		match event.keycode:
			KEY_W:     dir = get_camera_direction()["z"] * -1
			KEY_S:     dir = get_camera_direction()["z"]
			KEY_A:     dir = get_camera_direction()["x"] * -1
			KEY_D:     dir = get_camera_direction()["x"]
			KEY_SPACE: dir = Vector3.UP
			KEY_SHIFT, KEY_C: dir = Vector3.DOWN

		if dir != Vector3.ZERO:
			dir = get_move_axis(dir)
			if move_tiles(dir):
				spawn_random_tile()
				spawn_random_tile()

func reset_game():
	# clear existing tiles
	for child in grid_root.get_children():
		child.queue_free()
	grid.clear()

	# reset score
	score = 0
	update_score_label()

	# spawn initial tiles
	spawn_random_tile()
	spawn_random_tile()

func get_camera_direction() -> Dictionary:
	var basis = camera.global_transform.basis
	return {
		"x": basis.x.normalized(),
		"y": basis.y.normalized(),
		"z": basis.z.normalized()
	}

func get_move_axis(raw_dir: Vector3) -> Vector3:
	var axes = [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]
	var max_dot = 0.0
	var best_axis = Vector3.ZERO
	for axis in axes:
		var dot_val = abs(raw_dir.dot(axis))
		if dot_val > max_dot:
			max_dot = dot_val
			best_axis = axis * sign(raw_dir.dot(axis))
	return best_axis

func move_tiles(direction: Vector3) -> bool:
	var moved = false
	var sorted = get_sorted_positions(direction)
	var merged = []

	for pos in sorted:
		if pos in grid:
			var tile        = grid[pos]
			var current_pos = pos
			var target_pos  = pos

			# slide as far as possible
			while true:
				var next_pos = current_pos + Vector3i(direction)
				if not is_in_bounds(next_pos):
					break
				if next_pos in grid:
					var other = grid[next_pos]
					if other.value == tile.value and next_pos not in merged:
						target_pos = next_pos
					break
				current_pos = next_pos
				target_pos  = next_pos

			# Perform move or merge
			if target_pos != pos:
				grid.erase(pos)
				if target_pos in grid:
					# Merge
					var other = grid[target_pos]
					tile.value *= 2
					# update score
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

func spawn_random_tile():
	var empty = []
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			for z in GRID_SIZE:
				var pos = Vector3i(x, y, z)
				if pos not in grid:
					empty.append(pos)
	if empty.is_empty():
		return
	var new_pos = empty.pick_random()
	var tile    = TILE_SCENE.instantiate()
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
	var offset = Vector3(GRID_SIZE * 0.5 - 0.5,
						GRID_SIZE * 0.5 - 0.5,
						GRID_SIZE * 0.5 - 0.5)
	return (Vector3(pos) - offset) * 1.5

func draw_wireframe_grid():
	var size   = 1.5
	var half   = size * 0.5
	var offset = Vector3(GRID_SIZE * 0.5 - 0.5,
						GRID_SIZE * 0.5 - 0.5,
						GRID_SIZE * 0.5 - 0.5)

	for x in GRID_SIZE:
		for y in GRID_SIZE:
			for z in GRID_SIZE:
				var mesh = ImmediateMesh.new()
				mesh.surface_begin(Mesh.PRIMITIVE_LINES)
				var pos    = Vector3(x, y, z)
				var center = (pos - offset) * size

				var corners = [
					Vector3(-half, -half, -half),
					Vector3( half, -half, -half),
					Vector3( half,  half, -half),
					Vector3(-half,  half, -half),
					Vector3(-half, -half,  half),
					Vector3( half, -half,  half),
					Vector3( half,  half,  half),
					Vector3(-half,  half,  half)
				]
				var edges = [
					[0,1],[1,2],[2,3],[3,0],
					[4,5],[5,6],[6,7],[7,4],
					[0,4],[1,5],[2,6],[3,7]
				]
				for e in edges:
					mesh.surface_add_vertex(corners[e[0]] + center)
					mesh.surface_add_vertex(corners[e[1]] + center)
				mesh.surface_end()

				var mi = MeshInstance3D.new()
				mi.mesh = mesh
				var mat = StandardMaterial3D.new()
				mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
				mat.albedo_color     = Color(0.5, 0.5, 0.5, 1)
				mi.material_override = mat
				wireframe_root.add_child(mi)

func update_score_label():
	score_label.text = "Score: %d\nHigh Score: %d" % [score, high_score]

func save_high_score():
	if Engine.has_singleton("JavaScript"):
		var js_iface = Engine.get_singleton("JavaScript")
		var js = "document.cookie = 'highScore=' + %d + ';path=/;max-age=' + %d;" % [high_score, 60*60*24*365]
		js_iface.eval(js, false)

func load_high_score():
	if Engine.has_singleton("JavaScript"):
		var js_iface = Engine.get_singleton("JavaScript")
		var js = """
			(()=>{
				let m = document.cookie.match(/(?:^|; )highScore=(\\d+)/);
				return m ? m[1] : '0';
			})()
		"""
		var val = js_iface.eval(js, true)
		high_score = int(val)
