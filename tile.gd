extends Node3D

# Exported value with classic setter to avoid inline‐setter quirks
@export var value: int = 2 setget set_value

# Node references
@onready var cube_node = $Cube
@onready var label3d   = $Label3D
@onready var camera    = get_viewport().get_camera_3d()

# Will hold our material instances and tween
var cube_mat
var label_mat
var move_tween

func _ready() -> void:
	# ─── Cube material: reuse if present, else create + configure ───
	if cube_node.material_override is StandardMaterial3D:
		cube_mat = cube_node.material_override
	else:
		cube_mat = StandardMaterial3D.new()
		cube_mat.transparency      = BaseMaterial3D.TRANSPARENCY_ALPHA
		cube_mat.flags_transparent = true
		cube_mat.depth_draw_mode   = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		cube_node.material_override = cube_mat

	# ─── Label3D material: always fully opaque ───────────────────────
	label_mat = StandardMaterial3D.new()
	label_mat.transparency      = BaseMaterial3D.TRANSPARENCY_DISABLED
	label_mat.flags_transparent = false
	label3d.material_override   = label_mat

	# ─── Prepare our movement tween ─────────────────────────────────
	move_tween = create_tween()
	move_tween.kill()

	# ─── Initialize text + cube color ───────────────────────────────
	label3d.text = str(value)
	update_material()

func set_value(v) -> void:
	value = v
	label3d.text = str(value)
	# only update the cube once its material is ready
	if cube_mat:
		update_material()

func update_material() -> void:
	# compute which “step” we’re on (2→1, 4→2, 8→3, etc)
	var step = log(value) / log(2.0) if value > 0 else 1.0
	var hue  = fmod(step * 0.1, 1.0)

	# pick an RGB color for that hue and preserve the editor‐set alpha
	var rgb   = Color.from_hsv(hue, 0.6, 1.0)
	var alpha = cube_mat.albedo_color.a
	cube_mat.albedo_color = Color(rgb.r, rgb.g, rgb.b, alpha)

func _process(delta) -> void:
	pass  # (billboard logic could go here later)

func move_to(target_pos) -> void:
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(self, "global_position", target_pos, 0.15) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

func animate_spawn() -> void:
	scale = Vector3.ONE * 0.1
	var t = create_tween()
	t.tween_property(self, "scale", Vector3.ONE, 0.2) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

func animate_merge() -> void:
	scale = Vector3.ONE
	var t = create_tween()
	t.tween_property(self, "scale", Vector3.ONE * 1.25, 0.1) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector3.ONE, 0.1) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
