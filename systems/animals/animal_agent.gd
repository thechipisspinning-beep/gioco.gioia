class_name AnimalAgent
extends CharacterBody3D
## Animale nel mondo: comportamento (macchina a stati semplice), reazioni a
## Gioia e interazioni (accarezzare, dare cibo, giocare, spazzolare).
##
## Lo stato persistente (amicizia, bisogni…) è in `AnimalState` dentro
## `GameState.animals`; questo nodo è solo la sua rappresentazione "attiva"
## (vedi Architettura § 6.4, simulazione a livelli).

signal busy_changed(busy: bool)

enum State { IDLE, WANDER, SNIFF, SIT, LIE, SLEEP, CURIOUS, FLEE, ATTENTIVE, PETTED, EAT, FETCH_WAIT, FETCH_GO, FETCH_RETURN, FOLLOW, REFUSE }

const GRAVITY: float = 15.0
const INTERACT_DISTANCE: float = 1.3
const BALL_THROW_DISTANCE: float = 7.0

var species: SpeciesDefinition
var data: AnimalState
var home_position: Vector3
var visual: QuadrupedVisual

var _state: State = State.IDLE
var _state_time: float = 0.0
var _state_duration: float = 2.0
var _target: Vector3
var _player: PlayerController
var _player_distance: float = 999.0
var _curious_cooldown: float = 0.0
var _avoid_side: float = 1.0
var _ball: Node3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _met_reported: bool = false
var _follow_slot: int = 0
var _dying: bool = false


## Inizializza l'animale. Va chiamato prima di aggiungerlo alla scena.
func setup(species_def: SpeciesDefinition, state: AnimalState, home: Vector3) -> void:
	species = species_def
	data = state
	home_position = home
	_rng.seed = hash(String(state.id))


func _ready() -> void:
	add_to_group(&"interactable")
	add_to_group(&"animals")
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.3
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.28
	shape.shape = sphere
	shape.position.y = 0.3
	add_child(shape)
	visual = QuadrupedVisual.new()
	visual.name = "Visual"
	add_child(visual)
	visual.setup(species, data.variant)
	rotation.y = _rng.randf() * TAU
	_ensure_player()
	_enter(State.IDLE)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_curious_cooldown = maxf(0.0, _curious_cooldown - delta)
	_ensure_player()
	if _player != null:
		_player_distance = global_position.distance_to(_player.global_position)
	else:
		_player_distance = 999.0
	_check_met()
	_sync_with_data()
	if _dying:
		return
	_check_global_transitions()
	_run_state(delta)
	_apply_gravity(delta)
	move_and_slide()
	visual.speed = Vector2(velocity.x, velocity.z).length()


# ---------------------------------------------------------------------------
# Interazione (interfaccia usata da `Interactor` e dal menu)
# ---------------------------------------------------------------------------

func get_interaction_title() -> String:
	return data.display_name(tr(species.name_key))


func get_hearts() -> int:
	return data.hearts()


## Testo di stato per l'interfaccia (es. "Dorme", "È timida").
func get_status_text() -> String:
	if data.health == AnimalState.Health.SICK:
		var day: int = AnimalHealth.sick_day(data, GameClock.time.get_total_minutes())
		return (tr("ANIMAL_STATUS_SICK_SERENE") if GameState.serene_mode else tr("ANIMAL_STATUS_SICK")) % mini(day, 3)
	if data.health == AnimalState.Health.CONVALESCENT:
		return tr("ANIMAL_STATUS_CONVALESCENT")
	if data.adopted:
		if data.hunger < AnimalHealth.LOW_NEED_WARNING:
			return tr("ANIMAL_STATUS_HUNGRY")
		if data.cleanliness < AnimalHealth.LOW_NEED_WARNING:
			return tr("ANIMAL_STATUS_DIRTY")
		if data.happiness < AnimalHealth.LOW_NEED_WARNING:
			return tr("ANIMAL_STATUS_SAD")
	if _state == State.SLEEP:
		return tr("ANIMAL_STATUS_SLEEPING")
	if _state == State.FLEE:
		return tr("ANIMAL_STATUS_SCARED")
	if not TrustModel.tolerates_distance(data, species, _player_distance):
		return tr("ANIMAL_STATUS_SHY")
	if not data.adopted:
		if TrustModel.can_adopt(data, species):
			return tr("ANIMAL_STATUS_CAN_ADOPT")
		var progress: Dictionary = TrustModel.adoption_progress(data, species)
		if float(progress["friendship_missing"]) <= 0.0 and int(progress["days_missing"]) > 0:
			return tr("ANIMAL_STATUS_NEEDS_DAYS") % int(progress["days_missing"])
	return ""


func is_busy() -> bool:
	return _state in [State.PETTED, State.EAT, State.FETCH_WAIT, State.FETCH_GO, State.FETCH_RETURN, State.REFUSE]


## Azioni disponibili ora. Ogni voce: {id, label, enabled}.
func get_interaction_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if not data.is_alive() or is_busy():
		return actions
	var inv_now: Inventory = GameState.inventory
	# Un animale malato si può curare anche mentre dorme (la notte non deve impedire la cura).
	if _state == State.SLEEP and data.health == AnimalState.Health.SICK:
		actions.append({"id": "medicine", "label": tr("ACTION_MEDICINE") % inv_now.count(&"medicine"), "enabled": inv_now.has(&"medicine")})
		return actions
	if _state in [State.SLEEP, State.FLEE]:
		return actions
	if not TrustModel.tolerates_distance(data, species, _player_distance):
		return actions
	var inv: Inventory = GameState.inventory
	var sick: bool = data.health == AnimalState.Health.SICK
	if TrustModel.can_adopt(data, species):
		actions.append({"id": "adopt", "label": tr("ACTION_ADOPT"), "enabled": true})
	if sick:
		actions.append({"id": "medicine", "label": tr("ACTION_MEDICINE") % inv.count(&"medicine"), "enabled": inv.has(&"medicine")})
	actions.append({"id": "pet", "label": tr("ACTION_PET"), "enabled": true})
	for item_id: StringName in inv.item_ids():
		var item: ItemDefinition = Database.item(item_id)
		if item != null and item.category == ItemDefinition.Category.FOOD:
			actions.append({"id": "feed:" + String(item_id), "label": tr("ACTION_FEED") % [tr(item.name_key), inv.count(item_id)], "enabled": true})
	if species.likes_fetch and inv.has(&"ball") and not sick:
		actions.append({"id": "play", "label": tr("ACTION_PLAY_BALL"), "enabled": true})
	if inv.has(&"brush"):
		actions.append({"id": "brush", "label": tr("ACTION_BRUSH"), "enabled": true})
	if data.adopted and not sick:
		if data.location == AnimalState.Location.COMPANION:
			actions.append({"id": "stay", "label": tr("ACTION_GO_HOME"), "enabled": true})
		else:
			var full: bool = GameState.animals.companions().size() >= Adoption.MAX_COMPANIONS
			var label: String = tr("ACTION_FOLLOW_FULL") % Adoption.MAX_COMPANIONS if full else tr("ACTION_FOLLOW")
			actions.append({"id": "follow", "label": label, "enabled": not full})
	return actions


func perform_interaction(action_id: String) -> void:
	if is_busy():
		return
	_face_player_now()
	var day: int = GameState.current_day()
	if action_id == "adopt":
		EventBus.adoption_requested.emit(self)
		return
	if action_id == "follow" or action_id == "stay":
		AnimalCare.set_companion(data, action_id == "follow")
		_sync_with_data()
		return
	if action_id == "medicine":
		EventBus.player_gesture.emit(&"feed")
		if AnimalCare.give_medicine(data):
			Emote.spawn(self, global_position + Vector3.UP * 0.95, Emote.Kind.BIG_HEARTS)
			_enter(State.PETTED)
		return
	if action_id == "pet":
		EventBus.player_gesture.emit(&"pet")
		_apply_trust(TrustModel.Action.PET, day)
		_enter(State.PETTED)
	elif action_id == "brush":
		EventBus.player_gesture.emit(&"brush")
		_apply_trust(TrustModel.Action.BRUSH, day)
		_enter(State.PETTED)
	elif action_id.begins_with("feed:"):
		var item_id: StringName = StringName(action_id.trim_prefix("feed:"))
		EventBus.player_gesture.emit(&"feed")
		var pref: int = species.food_preference(item_id)
		if pref == 0:
			TrustModel.interact(data, species, TrustModel.Action.FEED, day, 0)
			EventBus.notification_requested.emit(tr("NOTIFY_FOOD_REFUSED") % [get_interaction_title(), tr(Database.item(item_id).name_key)])
			_enter(State.REFUSE)
			return
		if not GameState.inventory.try_remove(item_id):
			return
		_apply_trust(TrustModel.Action.FEED, day, pref)
		if pref >= 2:
			EventBus.notification_requested.emit(tr("NOTIFY_FOOD_FAVORITE") % get_interaction_title())
			GameState.discoveries.mark_favorite_food(species.id, item_id)
		_enter(State.EAT)
	elif action_id == "play":
		EventBus.player_gesture.emit(&"throw")
		_start_fetch()


func _apply_trust(action: TrustModel.Action, day: int, food_pref: int = 1) -> void:
	var before: int = data.hearts()
	var result: TrustModel.Result = TrustModel.interact(data, species, action, day, food_pref)
	EventBus.animal_interacted.emit(data.id, species.id, action, result.gain)
	var head: Vector3 = global_position + Vector3.UP * 0.95
	if result.reaction == TrustModel.Reaction.TIRED:
		EventBus.notification_requested.emit(tr("NOTIFY_ANIMAL_TIRED") % get_interaction_title())
	elif result.reaction == TrustModel.Reaction.VERY_HAPPY:
		Emote.spawn(self, head, Emote.Kind.BIG_HEARTS)
	else:
		Emote.spawn(self, head, Emote.Kind.HEARTS)
	if data.hearts() > before:
		EventBus.notification_requested.emit(tr("NOTIFY_FRIENDSHIP_UP") % [get_interaction_title(), data.hearts()])
	EventBus.friendship_changed.emit(data.id, data.friendship)


# ---------------------------------------------------------------------------
# Macchina a stati
# ---------------------------------------------------------------------------

func _check_met() -> void:
	if _met_reported or _player == null or _player_distance > species.notice_distance:
		return
	_met_reported = true
	var first: bool = GameState.discoveries.mark_species_met(species.id, GameState.current_day(), GameState.current_hour())
	EventBus.animal_met.emit(species.id, data.id)
	if first:
		EventBus.notification_requested.emit(tr("NOTIFY_NEW_SPECIES") % tr(species.name_key))


func _check_global_transitions() -> void:
	if is_busy() or _state == State.FOLLOW:
		return
	# Sonno fuori dagli orari di attività.
	var active: bool = species.is_active_at(GameState.current_hour())
	if not active and _state != State.SLEEP and _state != State.FLEE:
		_enter(State.SLEEP)
		return
	if active and _state == State.SLEEP:
		_enter(State.IDLE)
		return
	if _player == null or _state == State.SLEEP:
		return
	# Timidezza: un animale timido mantiene le distanze e si spaventa se Gioia corre.
	if _state != State.FLEE:
		var too_close: bool = not TrustModel.tolerates_distance(data, species, _player_distance)
		var startled: bool = _player.is_running() and _player_distance < species.notice_distance * 0.6 and species.shyness >= 0.5
		if too_close or startled:
			if startled:
				TrustModel.startle(data, species)
			Emote.spawn(self, global_position + Vector3.UP * 0.9, Emote.Kind.ALERT)
			_enter(State.FLEE)
			return
	# Curiosità: gli animali socievoli vengono a salutare.
	if _state in [State.IDLE, State.WANDER, State.SNIFF] and _curious_cooldown <= 0.0 \
			and _player_distance < species.notice_distance * 0.8 and _player_distance > INTERACT_DISTANCE + 0.5 \
			and species.shyness < 0.5:
		_enter(State.CURIOUS)


func _enter(new_state: State) -> void:
	var was_busy: bool = is_busy()
	_state = new_state
	_state_time = 0.0
	visual.pose = QuadrupedVisual.Pose.STAND
	visual.head_down = 0.0
	visual.happy_eyes = false
	visual.scratching = false
	visual.look_target = null
	visual.wag = 0.25 + data.happiness * 0.2
	match new_state:
		State.IDLE:
			_state_duration = _rng.randf_range(1.5, 4.0)
		State.WANDER:
			var angle: float = _rng.randf() * TAU
			var dist: float = _rng.randf_range(2.0, species.roam_radius)
			_target = home_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
			_state_duration = 12.0
		State.SNIFF:
			_state_duration = _rng.randf_range(2.0, 4.0)
			visual.head_down = 1.0
		State.SIT:
			_state_duration = _rng.randf_range(4.0, 8.0)
			visual.pose = QuadrupedVisual.Pose.SIT
			visual.scratching = _rng.randf() < 0.35
		State.LIE:
			_state_duration = _rng.randf_range(6.0, 12.0)
			visual.pose = QuadrupedVisual.Pose.LIE
		State.SLEEP:
			_state_duration = 9999.0
			visual.pose = QuadrupedVisual.Pose.SLEEP
		State.CURIOUS:
			_state_duration = 8.0
			visual.wag = 0.9
		State.FLEE:
			_state_duration = 6.0
		State.ATTENTIVE:
			_state_duration = _rng.randf_range(4.0, 7.0)
			visual.wag = 0.8
		State.PETTED:
			_state_duration = 2.2
			visual.happy_eyes = true
			visual.wag = 1.0
			visual.hop(0.6)
		State.EAT:
			_state_duration = 2.6
			visual.head_down = 1.0
			visual.wag = 1.0
		State.REFUSE:
			_state_duration = 1.4
			visual.shake_head()
			Emote.spawn(self, global_position + Vector3.UP * 0.9, Emote.Kind.CLOUD)
		State.FETCH_WAIT:
			_state_duration = 1.2
			visual.wag = 1.0
		State.FETCH_GO, State.FETCH_RETURN:
			_state_duration = 15.0
			visual.wag = 1.0
		State.FOLLOW:
			_state_duration = 9999.0
	if was_busy != is_busy():
		busy_changed.emit(is_busy())


func _run_state(delta: float) -> void:
	if _player == null and _state not in [State.IDLE, State.WANDER, State.SNIFF, State.SIT, State.LIE, State.SLEEP]:
		if _ball != null:
			_ball.queue_free()
			_ball = null
		_enter(State.IDLE)
	match _state:
		State.IDLE:
			_brake(delta)
			if _state_time > _state_duration:
				_choose_idle_activity()
		State.WANDER:
			if _move_to(_target, species.walk_speed, delta, 0.6) or _state_time > _state_duration:
				_enter(State.IDLE)
		State.SNIFF, State.SIT, State.LIE:
			_brake(delta)
			if _state_time > _state_duration:
				_enter(State.IDLE)
		State.SLEEP:
			_brake(delta)
		State.CURIOUS:
			visual.look_target = _player_head()
			if _player_distance > INTERACT_DISTANCE:
				_move_to(_player.global_position, species.walk_speed * 1.6, delta, INTERACT_DISTANCE)
			else:
				_brake(delta)
				_enter(State.ATTENTIVE)
			if _state_time > _state_duration:
				_curious_cooldown = 20.0
				_enter(State.IDLE)
		State.ATTENTIVE:
			_brake(delta)
			_face(_player.global_position, delta)
			visual.look_target = _player_head()
			if _state_time > _state_duration or _player_distance > species.notice_distance:
				_curious_cooldown = 25.0
				_enter(State.IDLE)
		State.FLEE:
			var away: Vector3 = (global_position - _player.global_position)
			away.y = 0.0
			var flee_target: Vector3 = global_position + away.normalized() * 4.0
			# Non allontanarsi troppo da casa: scappa in direzione mista.
			if flee_target.distance_to(home_position) > species.roam_radius * 1.6:
				flee_target = home_position + (flee_target - home_position).normalized() * species.roam_radius
			_move_to(flee_target, species.run_speed, delta, 0.3)
			var safe: bool = TrustModel.tolerates_distance(data, species, _player_distance - 2.0) and not _player.is_running()
			if _state_time > _state_duration or (safe and _state_time > 1.5):
				_enter(State.ATTENTIVE if safe else State.IDLE)
		State.PETTED, State.EAT, State.REFUSE:
			_brake(delta)
			visual.look_target = _player_head() if _state != State.EAT else null
			if _state_time > _state_duration:
				_enter(State.ATTENTIVE)
		State.FETCH_WAIT:
			_brake(delta)
			visual.look_target = _ball.global_position if _ball != null else null
			if _state_time > _state_duration:
				_enter(State.FETCH_GO)
		State.FETCH_GO:
			if _ball == null:
				_enter(State.IDLE)
				return
			visual.look_target = _ball.global_position
			if _move_to(_ball.global_position, species.run_speed, delta, 0.45) or _state_time > _state_duration:
				_pick_up_ball()
				_enter(State.FETCH_RETURN)
		State.FETCH_RETURN:
			visual.look_target = _player_head()
			if _move_to(_player.global_position, species.run_speed * 0.8, delta, INTERACT_DISTANCE) or _state_time > _state_duration:
				_finish_fetch()
		State.FOLLOW:
			_run_follow(delta)


func _choose_idle_activity() -> void:
	var r: float = _rng.randf()
	# Fuori dal raggio di casa: torna indietro.
	if global_position.distance_to(home_position) > species.roam_radius:
		_target = home_position
		_state = State.WANDER
		_state_time = 0.0
		_state_duration = 15.0
		return
	if r < 0.5:
		_enter(State.WANDER)
	elif r < 0.7:
		_enter(State.SNIFF)
	elif r < 0.85:
		_enter(State.SIT)
	else:
		_enter(State.LIE)


func _run_follow(delta: float) -> void:
	if _player == null:
		return
	# Posizione in formazione dietro a Gioia, diversa per ogni compagno.
	var back: Vector3 = -_player.global_transform.basis.z
	var side: Vector3 = _player.global_transform.basis.x
	var offsets: Array[Vector2] = [Vector2(-0.9, 1.4), Vector2(0.9, 1.5), Vector2(0.0, 2.3)]
	var o: Vector2 = offsets[_follow_slot % offsets.size()]
	var slot: Vector3 = _player.global_position + side * o.x + back * o.y
	var dist: float = global_position.distance_to(slot)
	if dist > 25.0:
		# Rimasto troppo indietro: ricompare discretamente vicino a Gioia.
		global_position = slot + Vector3.UP * 0.3
		velocity = Vector3.ZERO
		return
	var speed: float = species.run_speed if dist > 4.0 else species.walk_speed * 1.5
	if dist > 0.5:
		_move_to(slot, speed, delta, 0.4)
	else:
		_brake(delta)
		_face(_player.global_position + back * -3.0, delta)
	visual.wag = 0.7


# ---------------------------------------------------------------------------
# Gioco della pallina
# ---------------------------------------------------------------------------

func _start_fetch() -> void:
	var forward: Vector3 = _player.global_transform.basis.z
	forward.y = 0.0
	var land: Vector3 = _player.global_position + forward.normalized() * BALL_THROW_DISTANCE
	land.y = _player.global_position.y + 0.1
	_ball = _make_ball()
	get_tree().current_scene.add_child(_ball)
	var start: Vector3 = _player.global_position + Vector3.UP * 1.0
	_ball.global_position = start
	var t: Tween = create_tween()
	t.tween_method(func(f: float) -> void:
		if is_instance_valid(_ball) and _ball.is_inside_tree():
			_ball.global_position = start.lerp(land, f) + Vector3.UP * sin(f * PI) * 2.2
	, 0.0, 1.0, 0.9)
	_enter(State.FETCH_WAIT)


func _pick_up_ball() -> void:
	if _ball == null:
		return
	_ball.get_parent().remove_child(_ball)
	visual.get_mouth_anchor().add_child(_ball)
	_ball.position = Vector3.ZERO


func _finish_fetch() -> void:
	if _ball != null:
		_ball.queue_free()
		_ball = null
	_apply_trust(TrustModel.Action.PLAY, GameState.current_day())
	_enter(State.PETTED)


func _make_ball() -> Node3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var s: SphereMesh = SphereMesh.new()
	s.radius = 0.07
	s.height = 0.14
	s.radial_segments = 10
	s.rings = 6
	mi.mesh = s
	mi.material_override = ToonMaterials.get_material(Palette.ROOF_RED)
	return mi


# ---------------------------------------------------------------------------
# Movimento
# ---------------------------------------------------------------------------

## Si muove verso `target`; restituisce true se è arrivato entro `stop_distance`.
func _move_to(target: Vector3, speed: float, delta: float, stop_distance: float) -> bool:
	var to: Vector3 = target - global_position
	to.y = 0.0
	if to.length() <= stop_distance:
		_brake(delta)
		return true
	var dir: Vector3 = to.normalized()
	dir = _avoid_obstacles(dir)
	var desired: Vector3 = dir * speed
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z).move_toward(desired, 12.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	_face(global_position + dir, delta)
	return false


func _avoid_obstacles(dir: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = global_position + Vector3.UP * 0.35
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, from + dir * 1.1, 1)
	query.exclude = [get_rid()]
	if space.intersect_ray(query).is_empty():
		return dir
	# Ostacolo davanti: prova a girare sempre dallo stesso lato finché serve.
	for attempt: int in 2:
		var turned: Vector3 = dir.rotated(Vector3.UP, _avoid_side * deg_to_rad(65.0))
		query.to = from + turned * 1.1
		if space.intersect_ray(query).is_empty():
			return turned
		_avoid_side = -_avoid_side
	return dir.rotated(Vector3.UP, _avoid_side * PI * 0.5)


func _brake(delta: float) -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, 14.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face(point: Vector3, delta: float) -> void:
	var to: Vector3 = point - global_position
	if Vector2(to.x, to.z).length() < 0.05:
		return
	rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 1.0 - exp(-8.0 * delta))


func _face_player_now() -> void:
	if _player == null:
		return
	var to: Vector3 = _player.global_position - global_position
	rotation.y = atan2(to.x, to.z)


func _player_head() -> Vector3:
	return _player.global_position + Vector3.UP * 1.0 if _player != null else global_position + Vector3.FORWARD


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta


## Gioia può essere ricreata (cambio scena, caricamento): se il riferimento
## non è più valido lo si ritrova.
func _ensure_player() -> void:
	if _player != null and is_instance_valid(_player) and _player.is_inside_tree() and not _player.is_queued_for_deletion():
		return
	_player = null
	for n: Node in get_tree().get_nodes_in_group(&"player"):
		if not n.is_queued_for_deletion():
			_player = n as PlayerController
			return


## Allinea il comportamento allo stato persistente (adozione, compagni, salute).
func _sync_with_data() -> void:
	if _dying:
		return
	if not data.is_alive():
		_dying = true
		# Uscita di scena delicata (D-03): l'animale si addormenta e svanisce.
		visual.pose = QuadrupedVisual.Pose.SLEEP
		var t: Tween = create_tween()
		t.tween_interval(1.5)
		t.tween_property(visual, "scale", Vector3.ONE * 0.01, 1.5).set_ease(Tween.EASE_IN)
		t.tween_callback(queue_free)
		remove_from_group(&"interactable")
		return
	if is_busy():
		return
	var sick: bool = data.health == AnimalState.Health.SICK
	if sick:
		if _state != State.LIE and _state != State.SLEEP:
			_enter(State.LIE)
		_state_time = 0.0  # resta sdraiato finché non guarisce
		visual.wag = 0.0
		return
	var should_follow: bool = data.location == AnimalState.Location.COMPANION
	if should_follow and _state != State.FOLLOW:
		_enter(State.FOLLOW)
	elif not should_follow and _state == State.FOLLOW:
		_enter(State.IDLE)


## Posizione nella formazione dei compagni (0, 1, 2).
func set_follow_slot(slot: int) -> void:
	_follow_slot = slot


func get_state_name() -> String:
	return State.keys()[_state]
