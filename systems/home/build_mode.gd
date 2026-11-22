class_name BuildMode
extends Node3D
## Modalità arredamento (GDD § 8, D-20): griglia da 0,5 m, rotazione a 90°.
##
## Comandi:
## - mouse/tocco: il cursore segue il puntatore; clic/tocco = posiziona o raccogli
## - tastiera/controller: movimento = sposta il cursore; Interagisci (E / A) = posiziona
##   o raccogli; Salta (Spazio / X) = ruota; dorsali (L1/R1) = mobile precedente/successivo
## - Esc / B = esci
## Toccando un mobile già posizionato (senza averne uno selezionato) lo si
## raccoglie per spostarlo.

signal opened
signal closed
signal selection_changed

const CURSOR_REPEAT: float = 0.14

var camera_rig: CameraRig
var player: PlayerController
var active: bool = false
var selected: StringName = &""
var rot: int = 0
var color: int = 0
var cursor: Vector2i = Vector2i(4, 4)

var _ghost_root: Node3D
var _ghost: Node3D
var _plate: MeshInstance3D
var _grid: MeshInstance3D
var _repeat: float = 0.0
var _ok_mat: Material
var _bad_mat: Material


func _ready() -> void:
	EventBus.build_mode_requested.connect(open)
	_ghost_root = Node3D.new()
	add_child(_ghost_root)
	_plate = MeshInstance3D.new()
	var plane: BoxMesh = BoxMesh.new()
	plane.size = Vector3(1, 0.03, 1)
	_plate.mesh = plane
	_ghost_root.add_child(_plate)
	_ok_mat = _flat(Color(0.55, 0.9, 0.55, 0.55))
	_bad_mat = _flat(Color(1.0, 0.45, 0.45, 0.6))
	_ghost_root.visible = false
	set_process(false)


func open() -> void:
	if active:
		return
	active = true
	if player != null:
		player.input_locked = true
	_build_grid()
	_ghost_root.visible = true
	_refresh_ghost()
	if camera_rig != null:
		camera_rig.set_build_view(true, _cursor_world())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_process(true)
	opened.emit()


func close() -> void:
	if not active:
		return
	active = false
	if player != null:
		player.input_locked = false
	_ghost_root.visible = false
	if _grid != null:
		_grid.queue_free()
		_grid = null
	if camera_rig != null:
		camera_rig.set_build_view(false, Vector3.ZERO)
	set_process(false)
	SaveManager.autosave()
	closed.emit()


## Mobili disponibili da posizionare (nell'inventario).
func owned_furniture() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in FurnitureCatalog.DEFS.keys():
		if GameState.inventory.count(GameState.furniture_item(id)) > 0:
			out.append(id)
	return out


func select(id: StringName) -> void:
	selected = id
	_refresh_ghost()
	selection_changed.emit()


func cycle_selection(step: int) -> void:
	var list: Array[StringName] = owned_furniture()
	if list.is_empty():
		select(&"")
		return
	var i: int = list.find(selected)
	select(list[wrapi(i + step, 0, list.size())])


func rotate_selected() -> void:
	rot = (rot + 1) % 4
	_refresh_ghost()


func cycle_color() -> void:
	color = (color + 1) % FurnitureCatalog.COLORS.size()
	_refresh_ghost()


## Posiziona il mobile selezionato, oppure (se non c'è) raccoglie quello sotto il cursore.
func place_or_pick() -> void:
	var home: HomeLayout = GameState.home
	if selected == &"":
		var picked: Dictionary = home.remove_at(cursor.x, cursor.y)
		if not picked.is_empty():
			GameState.inventory.add(GameState.furniture_item(picked["id"]))
			rot = int(picked["rot"])
			color = int(picked["color"])
			select(picked["id"])
		return
	if not home.can_place(selected, cursor.x, cursor.y, rot):
		return
	var item: StringName = GameState.furniture_item(selected)
	if not GameState.inventory.try_remove(item):
		return
	home.place(selected, cursor.x, cursor.y, rot, color)
	EventBus.furniture_placed.emit(selected)
	if GameState.inventory.count(item) == 0:
		select(&"")
	selection_changed.emit()


## Rimette nell'inventario il mobile sotto il cursore.
func remove_at_cursor() -> void:
	var picked: Dictionary = GameState.home.remove_at(cursor.x, cursor.y)
	if not picked.is_empty():
		GameState.inventory.add(GameState.furniture_item(picked["id"]))
		selection_changed.emit()


func current_room() -> StringName:
	return GameState.home.room_at_cell(cursor.x)


func _process(delta: float) -> void:
	# Movimento del cursore con tastiera/controller (con ripetizione).
	var v: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_repeat -= delta
	if v.length() > 0.5 and _repeat <= 0.0:
		_repeat = CURSOR_REPEAT
		var step: Vector2i = Vector2i(roundi(v.x), roundi(v.y))
		_set_cursor(cursor + step)
	if camera_rig != null:
		camera_rig.set_build_focus(_cursor_world())


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		_cursor_from_screen((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_cursor_from_screen(mb.position)
			place_or_pick()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			rotate_selected()
	elif event.is_action_pressed("interact"):
		place_or_pick()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump"):
		rotate_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_zoom_in"):
		cycle_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_zoom_out"):
		cycle_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and (event as InputEventKey).pressed:
		match (event as InputEventKey).physical_keycode:
			KEY_R:
				rotate_selected()
			KEY_C:
				cycle_color()
			KEY_DELETE, KEY_BACKSPACE:
				remove_at_cursor()


func _cursor_from_screen(screen_pos: Vector2) -> void:
	if camera_rig == null:
		return
	var cam: Camera3D = camera_rig.get_camera()
	var from: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return
	var t: float = -from.y / dir.y
	if t < 0.0:
		return
	var hit: Vector3 = from + dir * t
	var fp: Vector2i = FurnitureCatalog.footprint(selected, rot) if selected != &"" else Vector2i.ONE
	_set_cursor(Vector2i(floori(hit.x / HomeLayout.CELL - fp.x * 0.5 + 0.5), floori(hit.z / HomeLayout.CELL - fp.y * 0.5 + 0.5)))


func _set_cursor(c: Vector2i) -> void:
	var size: Vector2i = GameState.home.grid_size()
	var fp: Vector2i = FurnitureCatalog.footprint(selected, rot) if selected != &"" else Vector2i.ONE
	c.x = clampi(c.x, 0, size.x - fp.x)
	c.y = clampi(c.y, 0, size.y - fp.y)
	if c != cursor:
		cursor = c
		_refresh_ghost()


func _cursor_world() -> Vector3:
	var fp: Vector2i = FurnitureCatalog.footprint(selected, rot) if selected != &"" else Vector2i.ONE
	return Vector3((cursor.x + fp.x * 0.5) * HomeLayout.CELL, 0.0, (cursor.y + fp.y * 0.5) * HomeLayout.CELL)


func _refresh_ghost() -> void:
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	var fp: Vector2i = FurnitureCatalog.footprint(selected, rot) if selected != &"" else Vector2i.ONE
	_set_cursor(cursor)  # riadatta ai bordi se l'ingombro è cambiato
	_ghost_root.position = _cursor_world()
	_plate.scale = Vector3(fp.x * HomeLayout.CELL, 1.0, fp.y * HomeLayout.CELL)
	_plate.position.y = 0.02
	var ok: bool = selected == &"" or GameState.home.can_place(selected, cursor.x, cursor.y, rot)
	_plate.material_override = _ok_mat if ok else _bad_mat
	if selected != &"":
		_ghost = FurnitureBuilder.build(selected, FurnitureCatalog.COLORS[color])
		_ghost.rotation.y = -rot * PI * 0.5
		_ghost.position.y = 0.05
		_ghost_root.add_child(_ghost)


func _build_grid() -> void:
	var size: Vector2i = GameState.home.grid_size()
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for x: int in size.x + 1:
		im.surface_add_vertex(Vector3(x * HomeLayout.CELL, 0.015, 0))
		im.surface_add_vertex(Vector3(x * HomeLayout.CELL, 0.015, size.y * HomeLayout.CELL))
	for y: int in size.y + 1:
		im.surface_add_vertex(Vector3(0, 0.015, y * HomeLayout.CELL))
		im.surface_add_vertex(Vector3(size.x * HomeLayout.CELL, 0.015, y * HomeLayout.CELL))
	im.surface_end()
	_grid = MeshInstance3D.new()
	_grid.mesh = im
	_grid.material_override = _flat(Color(1, 1, 1, 0.35))
	add_child(_grid)


func _flat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	return m
