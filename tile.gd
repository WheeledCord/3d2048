extends Node3D

@export var value: int = 2:
	set(v):
		value = v
		$Label3D.text = str(value)
		update_material()

@onready var camera := get_viewport().get_camera_3d()
var tween: Tween

func _ready():
	tween = create_tween()
	tween.kill()  # stop any empty tween

func _process(delta):
	pass

func update_material():
	var shift = log(value) / log(2) if value > 0 else 1
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color8(
		255 - shift * 20,
		255 - shift * 40,
		255
	)
	$Cube.material_override = mat

func move_to(target_pos: Vector3):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
