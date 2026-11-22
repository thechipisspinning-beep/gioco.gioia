class_name Lighting
extends RefCounted
## Regole di illuminazione comuni a tutte le scene.
##
## Il renderer Compatibility (web e telefoni più vecchi) somma luce ambientale
## e luce del sole in modo diverso da Forward+/Mobile: con gli stessi valori
## l'immagine risulta molto più chiara e slavata. Questi fattori, misurati
## confrontando screenshot dei due renderer (vedi docs/STATO_LAVORI.md), fanno
## sì che i colori della palette appaiano uguali su tutte le piattaforme.

const COMPAT_SUN_SCALE: float = 0.58
const COMPAT_AMBIENT_SCALE: float = 0.25


static func is_compatibility_renderer() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


## Energia del sole da usare, dato il valore di riferimento (Forward+).
static func sun_energy(reference: float) -> float:
	return reference * (COMPAT_SUN_SCALE if is_compatibility_renderer() else 1.0)


## Energia della luce ambientale da usare, dato il valore di riferimento (Forward+).
static func ambient_energy(reference: float) -> float:
	return reference * (COMPAT_AMBIENT_SCALE if is_compatibility_renderer() else 1.0)
