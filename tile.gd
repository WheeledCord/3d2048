extends Node3D

@export var value: int = 2:
	set(v):
		value = v
		$Label3D.text = str(value)
		update_material()

@onready var camera := get_viewport().get_camera_3d()

# a dedicated tween just for movement
var move_tween: Tween

func _ready():
	move_tween = create_tween()
	move_tween.kill()

func _process(delta):
	pass  # no billboard logic here

func update_material():
	# compute which “step” we’re on (2→1, 4→2, 8→3, etc)
	var step = log(value) / log(2) if value > 0 else 1
	# map that onto a hue [0..1], e.g. each step shifts hue by 0.1
	var hue = fmod(step * 0.1, 1.0)
	# pick moderate saturation + brightness
	var col = Color.from_hsv(hue, 0.6, 1.0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	$Cube.material_override = mat

func move_to(target_pos: Vector3):
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(self, "global_position", target_pos, 0.15) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

func animate_spawn():
	# starting tiny, growing to 1.0
	scale = Vector3.ONE * 0.1
	var t = create_tween()
	t.tween_property(self, "scale", Vector3.ONE, 0.2) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

func animate_merge():
	# pop: 1.0 → 1.25 → 1.0
	scale = Vector3.ONE
	var t = create_tween()
	t.tween_property(self, "scale", Vector3.ONE * 1.25, 0.1) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector3.ONE, 0.1) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
