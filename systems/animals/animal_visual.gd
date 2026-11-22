class_name AnimalVisual
extends Node3D
## Base comune dei modelli animali (quadrupedi, uccelli, tartarughe…).
## L'agente imposta solo questi parametri; ogni modello li anima a modo suo.

enum Pose { STAND, SIT, LIE, SLEEP }

## Layer di rendering degli animali (la telecamera può nasconderli, es. nel ritratto).
const RENDER_LAYER: int = 2

var speed: float = 0.0
var pose: Pose = Pose.STAND
## 0 = calmo, 1 = felicissimo (coda che scodinzola, ali che sbattono…).
var wag: float = 0.2
## Punto (globale) da guardare; `null` per guardare avanti.
var look_target: Variant = null
## 0 = testa normale, 1 = testa a terra (annusare, mangiare, beccare).
var head_down: float = 0.0
var scratching: bool = false
var happy_eyes: bool = false


func setup(_species: SpeciesDefinition, _variant: int) -> void:
	pass


func get_mouth_anchor() -> Node3D:
	return self


func hop(_strength: float = 1.0) -> void:
	pass


func shake_head() -> void:
	pass


## Crea il modello giusto per la specie.
static func create_for(species: SpeciesDefinition) -> AnimalVisual:
	match species.model:
		&"bird":
			return BirdVisual.new()
		&"turtle":
			return TurtleVisual.new()
	return QuadrupedVisual.new()
