class_name SaveCodec
extends RefCounted
## Formato dei salvataggi (logica pura, testabile).
##
## Un salvataggio è un dizionario JSON:
##   { "schema_version": N, "saved_at": unix, "summary": {...}, "game": {...} }
## Quando il formato cambia si aumenta CURRENT_VERSION e si aggiunge una
## migrazione `_migrate_to_N` che trasforma i salvataggi vecchi: così i
## salvataggi dei giocatori non si rompono mai con gli aggiornamenti.

const CURRENT_VERSION: int = 1


## Crea il documento completo da salvare.
static func encode(game: Dictionary, summary: Dictionary, saved_at: int) -> String:
	var doc: Dictionary = {
		"schema_version": CURRENT_VERSION,
		"saved_at": saved_at,
		"summary": summary,
		"game": game,
	}
	return JSON.stringify(doc, "\t")


## Legge un documento. Restituisce {} se il testo non è un salvataggio valido.
## I salvataggi di versioni precedenti vengono migrati; quelli di versioni
## future (gioco più vecchio del salvataggio) vengono rifiutati.
static func decode(text: String) -> Dictionary:
	# JSON.parse (non parse_string) non scrive errori nel log per i file rovinati:
	# sono un caso previsto, gestito restituendo {}.
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {}
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var doc: Dictionary = parsed as Dictionary
	if not doc.has("schema_version") or not doc.has("game") or typeof(doc["game"]) != TYPE_DICTIONARY:
		return {}
	var version: int = int(doc["schema_version"])
	if version < 1 or version > CURRENT_VERSION:
		return {}
	while version < CURRENT_VERSION:
		version += 1
		doc = _migrate(doc, version)
		doc["schema_version"] = version
	return doc


static func _migrate(doc: Dictionary, to_version: int) -> Dictionary:
	# Nessuna migrazione ancora necessaria (versione 1).
	# Esempio futuro:  if to_version == 2: doc["game"]["garden"] = {}
	push_warning("Migrazione salvataggio alla versione %d" % to_version)
	return doc
