class_name WorldQuery
extends RefCounted
## Domande sul mondo che i sistemi di gioco possono fare senza conoscere
## la scena: per ora "si può camminare qui?" (niente acqua profonda, D-13).
## La scena del mondo imposta `ground_height`; senza di essa ogni punto è camminabile.

static var ground_height: Callable = Callable()


static func is_walkable(p: Vector3) -> bool:
	if not ground_height.is_valid():
		return true
	return float(ground_height.call(p.x, p.z)) > IslandLayout.DEEP_WATER
