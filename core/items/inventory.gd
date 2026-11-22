class_name Inventory
extends RefCounted
## Inventario di Gioia: quantità per ID oggetto (logica pura).

signal changed(item_id: StringName, new_count: int)

var _counts: Dictionary = {}  # StringName -> int


func count(item_id: StringName) -> int:
	return int(_counts.get(item_id, 0))


func has(item_id: StringName, amount: int = 1) -> bool:
	return count(item_id) >= amount


func add(item_id: StringName, amount: int = 1) -> void:
	if amount <= 0:
		return
	_counts[item_id] = count(item_id) + amount
	changed.emit(item_id, count(item_id))


## Rimuove solo se ce n'è abbastanza; restituisce true se ha rimosso.
func try_remove(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or not has(item_id, amount):
		return false
	var left: int = count(item_id) - amount
	if left == 0:
		_counts.erase(item_id)
	else:
		_counts[item_id] = left
	changed.emit(item_id, left)
	return true


func item_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in _counts.keys():
		out.append(k)
	out.sort()
	return out


func to_dict() -> Dictionary:
	var d: Dictionary = {}
	for k: StringName in _counts.keys():
		d[String(k)] = _counts[k]
	return d


func from_dict(d: Dictionary) -> void:
	_counts.clear()
	for k: Variant in d.keys():
		var n: int = int(d[k])
		if n > 0:
			_counts[StringName(str(k))] = n
