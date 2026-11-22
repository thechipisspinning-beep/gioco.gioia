class_name ZoneTracker
extends Node
## Rileva in che zona dell'isola si trova Gioia: mostra il nome della zona
## quando ci si entra e registra le zone scoperte nel diario.

@export var target: Node3D
var current_zone: StringName = &""
var _timer: float = 0.0


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0 or target == null:
		return
	_timer = 0.7
	var p: Vector3 = target.global_position
	var zone: StringName = IslandLayout.zone_at(Vector2(p.x, p.z))
	if p.y < 2.2 and zone != &"lake" and Vector2(p.x, p.z).length() > IslandLayout.ISLAND_RADIUS * 0.75:
		zone = &"beach"
	if zone == current_zone:
		return
	current_zone = zone
	EventBus.zone_entered.emit(zone)
	var first: bool = GameState.discoveries.mark_place(zone, GameState.current_day())
	var zone_name: String = tr(IslandLayout.zone_name_key(zone))
	EventBus.notification_requested.emit(tr("NOTIFY_NEW_ZONE") % zone_name if first else zone_name)
