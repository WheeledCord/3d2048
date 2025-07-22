extends Node3D

@export var sensitivity := 0.1
@export var fixed_distance := 5.0

var yaw := 0.0
var pitch := 0.0

@onready var camera = $Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, -9999999999, 999999999999999)

func _process(delta):
	rotation_degrees = Vector3(pitch, yaw, 0)

	var cam_offset = Vector3(0, 0, fixed_distance)
	camera.transform = Transform3D.IDENTITY.translated(cam_offset).looking_at(Vector3.ZERO, Vector3.UP)
