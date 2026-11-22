extends TestCase
## Telecamera: limiti di inclinazione e zoom, inquadratura alle spalle di Gioia,
## movimento relativo alla telecamera, collisione con i muri.

const PLAYER_SCENE: PackedScene = preload("res://systems/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://systems/camera/camera_rig.tscn")

var _root: Node3D
var _player: PlayerController
var _rig: CameraRig


func before_each() -> void:
	_root = Node3D.new()
	tree.root.add_child(_root)
	LevelBuilder.new(_root).solid_box(Vector3(200.0, 1.0, 200.0), Vector3(0.0, -0.5, 0.0), Palette.GRASS)
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_root.add_child(_player)
	_rig = CAMERA_SCENE.instantiate() as CameraRig
	_rig.target = _player
	_rig.auto_align_enabled = false
	_root.add_child(_rig)
	_player.camera_rig = _rig


func after_each() -> void:
	Input.action_release(&"move_forward")
	_root.queue_free()
	await tree.process_frame


func test_starts_behind_player() -> void:
	await wait_physics_frames(5)
	var cam_pos: Vector3 = _rig.get_camera().global_position
	# Gioia guarda verso +Z (rotazione 0): la telecamera deve stare dietro, a -Z.
	assert_lt(cam_pos.z, _player.global_position.z - 1.0, "telecamera dietro a Gioia")
	assert_gt(cam_pos.y, _player.global_position.y + 1.0, "telecamera sopra a Gioia")


func test_pitch_is_clamped() -> void:
	_rig.add_look(0.0, -500.0)
	assert_almost_eq(_get_pitch_after_apply(), deg_to_rad(_rig.min_pitch_degrees), 0.001, "limite inferiore")
	_rig.add_look(0.0, 1000.0)
	assert_almost_eq(_get_pitch_after_apply(), deg_to_rad(_rig.max_pitch_degrees), 0.001, "limite superiore")


func test_zoom_is_clamped() -> void:
	for i: int in 30:
		_rig.add_zoom(-1.0)
	await wait_physics_frames(120)
	assert_almost_eq(_rig.get_node("SpringArm3D").get("spring_length") as float, _rig.min_distance, 0.05, "zoom minimo")


func test_movement_is_relative_to_camera() -> void:
	await wait_physics_frames(5)
	_rig.add_look(90.0, 0.0)  # telecamera ruotata di 90° a sinistra
	await wait_physics_frames(2)
	var cam_forward: Vector3 = -_rig.global_transform.basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()
	var start: Vector3 = _player.global_position
	Input.action_press(&"move_forward")
	await wait_physics_frames(40)
	var moved: Vector3 = (_player.global_position - start)
	moved.y = 0.0
	assert_gt(moved.normalized().dot(cam_forward), 0.98, "\"avanti\" segue la direzione della telecamera")


func test_spring_arm_shortens_behind_wall() -> void:
	# Muro appena dietro Gioia (che guarda verso +Z): la telecamera deve avvicinarsi.
	LevelBuilder.new(_root).solid_box(Vector3(6.0, 6.0, 0.4), Vector3(0.0, 3.0, -1.5), Palette.STONE)
	await wait_physics_frames(30)
	var cam_dist: float = _rig.get_camera().global_position.distance_to(_rig.global_position)
	assert_lt(cam_dist, 1.6, "la telecamera non attraversa il muro")


func _get_pitch_after_apply() -> float:
	_rig._apply_rotation()
	return _rig.rotation.x
