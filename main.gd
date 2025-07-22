extends Node3D

const GRID_SIZE = 3
const TILE_SCENE = preload("res://Tile.tscn")

@onready var wireframe_root = $WireframeGrid
@onready var grid_root      = $GridRoot
@onready var camera         = $CameraRig/Camera3D

var grid = {}

func _ready():
	draw_wireframe_grid()
	spawn_random_tile()
	spawn_random_tile()

func _unhandled_input(event):
	var dir := Vector3.ZERO
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W: dir = get_camera_direction()["z"] * -1
			KEY_S: dir = get_camera_direction()["z"]
			KEY_A: dir = get_camera_direction()["x"] * -1
			KEY_D: dir = get_camera_direction()["x"]
			KEY_SPACE: dir = Vector3.UP
			KEY_SHIFT, KEY_C: dir = Vector3.DOWN

		if dir != Vector3.ZERO:
			dir = get_move_axis(dir)
			if move_tiles(dir):
				spawn_random_tile()
				spawn_random_tile()

func get_camera_direction():
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
		var dot = abs(raw_dir.dot(axis))
		if dot > max_dot:
			max_dot = dot
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

			if target_pos != pos:
				grid.erase(pos)
				if target_pos in grid:
					# merge
					var other = grid[target_pos]
					tile.value *= 2
					other.queue_free()
					grid_root.remove_child(other)
					merged.append(target_pos)
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
	tile.move_to(grid_to_world(new_pos))
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
				mat.albedo_color     = Color(0.5, 0.5, 0.5, 1)  # gray
				mi.material_override = mat
				wireframe_root.add_child(mi)
