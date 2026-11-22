class_name TestCase
extends RefCounted
## Classe base dei test automatici.
##
## Ogni file `tests/**/test_*.gd` estende TestCase; ogni metodo che inizia con
## `test_` viene eseguito da `tests/run_tests.gd`. I test di integrazione possono
## usare `tree` per aggiungere nodi alla scena e `await wait_physics_frames(n)`.

var tree: SceneTree
var _failures: PackedStringArray = PackedStringArray()


## Chiamato prima di ogni test.
func before_each() -> void:
	pass


## Chiamato dopo ogni test (anche se fallisce).
func after_each() -> void:
	pass


func get_failures() -> PackedStringArray:
	return _failures


func clear_failures() -> void:
	_failures = PackedStringArray()


func fail(message: String) -> void:
	_failures.append(message)


func assert_true(condition: bool, message: String = "atteso true") -> void:
	if not condition:
		fail(message)


func assert_false(condition: bool, message: String = "atteso false") -> void:
	if condition:
		fail(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		fail("%s atteso <%s>, ottenuto <%s>" % [message, str(expected), str(actual)])


func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		fail("%s atteso %f ± %f, ottenuto %f" % [message, expected, tolerance, actual])


func assert_gt(actual: float, threshold: float, message: String = "") -> void:
	if not actual > threshold:
		fail("%s atteso > %f, ottenuto %f" % [message, threshold, actual])


func assert_lt(actual: float, threshold: float, message: String = "") -> void:
	if not actual < threshold:
		fail("%s atteso < %f, ottenuto %f" % [message, threshold, actual])


## Attende `count` frame di fisica (per i test di integrazione).
func wait_physics_frames(count: int) -> void:
	for i: int in count:
		await tree.physics_frame
