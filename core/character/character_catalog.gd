class_name CharacterCatalog
extends RefCounted
## Opzioni di personalizzazione di Gioia (GDD § 4.2). Ogni slot ha stili
## (con chiave di traduzione) e una tavolozza di colori. Alcuni stili sono
## bloccati all'inizio e si sbloccano con le missioni (Fase 9).

const SLOTS: Array[StringName] = [&"skin", &"hair", &"outfit", &"shoes", &"accessory", &"height"]

const SKIN_TONES: Array[Color] = [
	Color("ffe3d0"), Color("ffd2b3"), Color("f1b98f"), Color("d99a6c"), Color("b5774c"), Color("8a5636")]

const HAIR_STYLES: Array[StringName] = [&"ponytail", &"bob", &"pigtails", &"long", &"bun", &"short"]
const HAIR_COLORS: Array[Color] = [
	Color("7a4a32"), Color("3b2a24"), Color("d9a05b"), Color("f2d48a"), Color("c4552f"), Color("2b2b33"), Color("b98ad9"), Color("7fc3e6")]

const OUTFIT_STYLES: Array[StringName] = [&"dress", &"tshirt_shorts", &"overalls", &"sweater_skirt", &"raincoat"]
const OUTFIT_COLORS: Array[Color] = [
	Color("ff8a7a"), Color("6aa8e8"), Color("8ccf6b"), Color("ffd75e"), Color("c79be8"), Color("fff8ee"), Color("ff9ec4"), Color("5b8f7a")]

const SHOE_STYLES: Array[StringName] = [&"sneakers", &"boots", &"sandals"]
const SHOE_COLORS: Array[Color] = [Color("fffaf2"), Color("c58f5e"), Color("ff6f6f"), Color("4a3a55"), Color("ffd75e")]

const ACCESSORIES: Array[StringName] = [&"none", &"bow", &"straw_hat", &"glasses", &"flower_crown", &"backpack"]
const ACCESSORY_COLORS: Array[Color] = [Color("ffd75e"), Color("ff6f91"), Color("8fb6ff"), Color("8ccf6b"), Color("fff8ee")]

const HEIGHTS: Array[float] = [0.93, 1.0, 1.07]

## Stili disponibili solo dopo uno sblocco (id → chiave del flag di sblocco).
const LOCKED: Dictionary = {
	&"raincoat": "unlock_raincoat",
	&"flower_crown": "unlock_flower_crown",
	&"backpack": "unlock_backpack",
	&"boots": "unlock_boots",
}


static func styles_for(slot: StringName) -> Array[StringName]:
	match slot:
		&"hair":
			return HAIR_STYLES
		&"outfit":
			return OUTFIT_STYLES
		&"shoes":
			return SHOE_STYLES
		&"accessory":
			return ACCESSORIES
	return []


static func colors_for(slot: StringName) -> Array[Color]:
	match slot:
		&"skin":
			return SKIN_TONES
		&"hair":
			return HAIR_COLORS
		&"outfit":
			return OUTFIT_COLORS
		&"shoes":
			return SHOE_COLORS
		&"accessory":
			return ACCESSORY_COLORS
	return []


static func is_unlocked(style: StringName, unlocked_flags: Dictionary) -> bool:
	if not LOCKED.has(style):
		return true
	return bool(unlocked_flags.get(String(LOCKED[style]), false))
