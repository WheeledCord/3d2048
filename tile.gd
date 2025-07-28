#sorry for my lack of comments... i dont usually comment unless its for a group project or something haha

extends Node3D

@export var value: int = 2:
	set(v):
		value = v
		$Label3D.text = str(value)
		if cube_mat:
			update_material()

@onready var mesh   = $Cube as MeshInstance3D
@onready var camera = get_viewport().get_camera_3d()

var cube_mat: StandardMaterial3D
var move_tween: Tween

const TILE_COLORS := {
	2:    Color8(224, 247, 255),
	4:    Color8(179, 229, 252),
	8:    Color8(129, 212, 250),
	16:   Color8(79, 195, 247),
	32:   Color8(41, 182, 246),
	64:   Color8(3, 169, 244),
	128:  Color8(3, 155, 229),
	256:  Color8(2, 136, 209),
	512:  Color8(2, 119, 189),
	1024: Color8(1, 87, 155),
	2048: Color8(1, 47, 91),
	4096: Color8(0, 31, 63),
	8192: Color8(0, 15, 31)
}

func _ready() -> void:
	$Label3D.text = str(value)
	var mat = mesh.material_override
	if mat == null or not (mat is StandardMaterial3D):
		mat = StandardMaterial3D.new()
		mat.albedo_color      = Color(1, 1, 1, 0xB3 / 255.0)
		mat.transparency      = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.flags_transparent = true
		mat.depth_draw_mode   = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		mesh.material_override = mat
	cube_mat = mat
	move_tween = create_tween()
	move_tween.kill()
	update_material()

func update_material() -> void:
	var base = TILE_COLORS.get(value, Color8(150, 150, 150))
	var a = cube_mat.albedo_color.a
	cube_mat.albedo_color = Color(base.r, base.g, base.b, a)

func move_to(target_pos: Vector3) -> void:
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
