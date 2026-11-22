class_name Feeder
extends StaticBody3D
## Mangiatoia automatica del giardino (D-37): Gioia la riempie con le
## crocchette e, ogni ora, gli animali adottati che vivono a casa e hanno
## fame mangiano da soli una porzione.

const FLAG: String = "feeder_portions"
const PORTIONS_PER_KIBBLE: int = 3
const KIBBLE_PER_REFILL: int = 5
const MAX_PORTIONS: int = 40


func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 1
	var b: LevelBuilder = LevelBuilder.new(self)
	var base: CylinderMesh = CylinderMesh.new()
	base.top_radius = 0.55
	base.bottom_radius = 0.6
	base.height = 0.25
	b.decor(base, Vector3(0, 0.12, 0), Palette.WOOD, Vector3.ZERO, Vector3.ONE, self)
	var bowl: CylinderMesh = CylinderMesh.new()
	bowl.top_radius = 0.45
	bowl.bottom_radius = 0.4
	bowl.height = 0.08
	b.decor(bowl, Vector3(0, 0.28, 0), Palette.FLOWER_BLUE, Vector3.ZERO, Vector3.ONE, self)
	var tank: CylinderMesh = CylinderMesh.new()
	tank.top_radius = 0.22
	tank.bottom_radius = 0.22
	tank.height = 0.7
	b.decor(tank, Vector3(0, 0.65, 0), Color("dff2ff"), Vector3.ZERO, Vector3.ONE, self)
	var lid: SphereMesh = SphereMesh.new()
	lid.radius = 0.24
	lid.height = 0.2
	b.decor(lid, Vector3(0, 1.02, 0), Palette.ROOF_RED, Vector3.ZERO, Vector3.ONE, self)
	var cs: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = 0.6
	cyl.height = 1.1
	cs.shape = cyl
	cs.position.y = 0.55
	add_child(cs)


static func portions() -> int:
	return int(GameState.flags.get(FLAG, 0))


## Le porzioni consumate automaticamente (chiamato da AnimalCare ogni ora).
static func feed_hungry_animals() -> int:
	var fed: int = 0
	for state: AnimalState in GameState.animals.adopted():
		if portions() <= 0:
			break
		if state.is_alive() and state.location == AnimalState.Location.HOME and state.hunger < 0.4:
			state.hunger = 1.0
			GameState.flags[FLAG] = portions() - 1
			fed += 1
	return fed


func get_interaction_title() -> String:
	return tr("FEEDER_TITLE")


func get_status_text() -> String:
	return tr("FEEDER_STATUS") % portions()


func get_interaction_actions() -> Array[Dictionary]:
	var can: bool = GameState.inventory.has(&"kibble", KIBBLE_PER_REFILL) and portions() < MAX_PORTIONS
	return [{"id": "refill", "label": tr("FEEDER_REFILL") % KIBBLE_PER_REFILL, "enabled": can}]


func perform_interaction(_action_id: String) -> void:
	if GameState.inventory.try_remove(&"kibble", KIBBLE_PER_REFILL):
		GameState.flags[FLAG] = mini(MAX_PORTIONS, portions() + KIBBLE_PER_REFILL * PORTIONS_PER_KIBBLE)
		EventBus.notification_requested.emit(tr("FEEDER_REFILLED") % portions())
