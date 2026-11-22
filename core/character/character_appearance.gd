class_name CharacterAppearance
extends RefCounted
## Aspetto di Gioia: uno stile e un colore per slot (indici nel catalogo),
## più la statura. Serializzabile, con valori sempre validi.

signal changed

var skin: int = 1
var hair_style: int = 0
var hair_color: int = 0
var outfit_style: int = 0
var outfit_color: int = 0
var shoes_style: int = 0
var shoes_color: int = 0
var accessory: int = 1
var accessory_color: int = 0
var height: int = 1


func style_index(slot: StringName) -> int:
	match slot:
		&"hair":
			return hair_style
		&"outfit":
			return outfit_style
		&"shoes":
			return shoes_style
		&"accessory":
			return accessory
		&"height":
			return height
	return 0


func color_index(slot: StringName) -> int:
	match slot:
		&"skin":
			return skin
		&"hair":
			return hair_color
		&"outfit":
			return outfit_color
		&"shoes":
			return shoes_color
		&"accessory":
			return accessory_color
	return 0


## Passa allo stile successivo (step = +1) o precedente (step = -1), saltando
## quelli bloccati. Restituisce false se non c'è nulla da cambiare.
func cycle_style(slot: StringName, step: int, unlocked_flags: Dictionary) -> bool:
	if slot == &"height":
		height = wrapi(height + step, 0, CharacterCatalog.HEIGHTS.size())
		changed.emit()
		return true
	var styles: Array[StringName] = CharacterCatalog.styles_for(slot)
	if styles.is_empty():
		return false
	var i: int = style_index(slot)
	for attempt: int in styles.size():
		i = wrapi(i + step, 0, styles.size())
		if CharacterCatalog.is_unlocked(styles[i], unlocked_flags):
			_set_style(slot, i)
			changed.emit()
			return true
	return false


func set_color(slot: StringName, index: int) -> void:
	var n: int = CharacterCatalog.colors_for(slot).size()
	if n == 0:
		return
	index = clampi(index, 0, n - 1)
	match slot:
		&"skin":
			skin = index
		&"hair":
			hair_color = index
		&"outfit":
			outfit_color = index
		&"shoes":
			shoes_color = index
		&"accessory":
			accessory_color = index
	changed.emit()


func style_id(slot: StringName) -> StringName:
	var styles: Array[StringName] = CharacterCatalog.styles_for(slot)
	return styles[style_index(slot)] if not styles.is_empty() else &""


func color(slot: StringName) -> Color:
	var colors: Array[Color] = CharacterCatalog.colors_for(slot)
	return colors[color_index(slot)] if not colors.is_empty() else Color.WHITE


func height_scale() -> float:
	return CharacterCatalog.HEIGHTS[height]


## Aspetto casuale tra gli stili sbloccati (pulsante "Sorprendimi").
func randomize_look(rng: RandomNumberGenerator, unlocked_flags: Dictionary) -> void:
	skin = rng.randi() % CharacterCatalog.SKIN_TONES.size()
	hair_color = rng.randi() % CharacterCatalog.HAIR_COLORS.size()
	outfit_color = rng.randi() % CharacterCatalog.OUTFIT_COLORS.size()
	shoes_color = rng.randi() % CharacterCatalog.SHOE_COLORS.size()
	accessory_color = rng.randi() % CharacterCatalog.ACCESSORY_COLORS.size()
	for slot: StringName in [&"hair", &"outfit", &"shoes", &"accessory"]:
		cycle_style(slot, 1 + rng.randi() % 4, unlocked_flags)
	changed.emit()


func to_dict() -> Dictionary:
	return {
		"skin": skin, "hair_style": hair_style, "hair_color": hair_color,
		"outfit_style": outfit_style, "outfit_color": outfit_color,
		"shoes_style": shoes_style, "shoes_color": shoes_color,
		"accessory": accessory, "accessory_color": accessory_color, "height": height,
	}


func from_dict(d: Dictionary) -> void:
	skin = clampi(int(d.get("skin", 1)), 0, CharacterCatalog.SKIN_TONES.size() - 1)
	hair_style = clampi(int(d.get("hair_style", 0)), 0, CharacterCatalog.HAIR_STYLES.size() - 1)
	hair_color = clampi(int(d.get("hair_color", 0)), 0, CharacterCatalog.HAIR_COLORS.size() - 1)
	outfit_style = clampi(int(d.get("outfit_style", 0)), 0, CharacterCatalog.OUTFIT_STYLES.size() - 1)
	outfit_color = clampi(int(d.get("outfit_color", 0)), 0, CharacterCatalog.OUTFIT_COLORS.size() - 1)
	shoes_style = clampi(int(d.get("shoes_style", 0)), 0, CharacterCatalog.SHOE_STYLES.size() - 1)
	shoes_color = clampi(int(d.get("shoes_color", 0)), 0, CharacterCatalog.SHOE_COLORS.size() - 1)
	accessory = clampi(int(d.get("accessory", 1)), 0, CharacterCatalog.ACCESSORIES.size() - 1)
	accessory_color = clampi(int(d.get("accessory_color", 0)), 0, CharacterCatalog.ACCESSORY_COLORS.size() - 1)
	height = clampi(int(d.get("height", 1)), 0, CharacterCatalog.HEIGHTS.size() - 1)
	changed.emit()


func _set_style(slot: StringName, i: int) -> void:
	match slot:
		&"hair":
			hair_style = i
		&"outfit":
			outfit_style = i
		&"shoes":
			shoes_style = i
		&"accessory":
			accessory = i
