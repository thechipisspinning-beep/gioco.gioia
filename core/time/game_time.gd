class_name GameTime
extends RefCounted
## Orologio di gioco puro (nessuna dipendenza dalla scena), testabile.
##
## Il tempo è conservato come minuti di gioco totali trascorsi dall'inizio
## della partita (giorno 1, ore 00:00). Con la configurazione predefinita
## un giorno di gioco dura 24 minuti reali (D-06): 1 minuto reale = 1 ora di gioco.

signal hour_changed(day: int, hour: int)
signal day_started(day: int)

const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const MINUTES_PER_DAY: int = MINUTES_PER_HOUR * HOURS_PER_DAY

## Ora di inizio di una nuova partita.
const NEW_GAME_START_HOUR: int = 8

## Minuti di gioco che scorrono per ogni secondo reale (1 → 1 ora = 1 minuto reale, 1 giorno = 24 min).
var game_minutes_per_real_second: float = 1.0
## Quando è in pausa (menu, dialoghi) il tempo non avanza.
var paused: bool = false

var _total_minutes: float = 0.0


func _init(start_total_minutes: float = NEW_GAME_START_HOUR * MINUTES_PER_HOUR) -> void:
	_total_minutes = maxf(start_total_minutes, 0.0)


## Minuti di gioco totali trascorsi.
func get_total_minutes() -> float:
	return _total_minutes


## Giorno corrente, a partire da 1.
func get_day() -> int:
	return int(_total_minutes / MINUTES_PER_DAY) + 1


## Ora corrente (0–23).
func get_hour() -> int:
	return int(fmod(_total_minutes, MINUTES_PER_DAY) / MINUTES_PER_HOUR)


## Minuto corrente dell'ora (0–59).
func get_minute() -> int:
	return int(fmod(_total_minutes, MINUTES_PER_HOUR))


## Posizione nel giorno in [0, 1): 0 = mezzanotte, 0.5 = mezzogiorno.
func get_day_fraction() -> float:
	return fmod(_total_minutes, MINUTES_PER_DAY) / MINUTES_PER_DAY


## Avanza il tempo di `real_seconds` secondi reali.
func advance_real_seconds(real_seconds: float) -> void:
	if paused or real_seconds <= 0.0:
		return
	advance_game_minutes(real_seconds * game_minutes_per_real_second)


## Avanza il tempo di gioco di `minutes` minuti, emettendo un segnale per
## ogni ora e ogni giorno attraversati (anche se il salto è grande, es. dormire).
func advance_game_minutes(minutes: float) -> void:
	if minutes <= 0.0:
		return
	var previous_hour_index: int = int(_total_minutes / MINUTES_PER_HOUR)
	_total_minutes += minutes
	var current_hour_index: int = int(_total_minutes / MINUTES_PER_HOUR)
	for hour_index: int in range(previous_hour_index + 1, current_hour_index + 1):
		@warning_ignore("integer_division")
		var day: int = hour_index / HOURS_PER_DAY + 1
		var hour: int = hour_index % HOURS_PER_DAY
		if hour == 0:
			day_started.emit(day)
		hour_changed.emit(day, hour)


## Porta il tempo alla prossima occorrenza dell'ora indicata (es. dormire fino alle 7).
func skip_to_next_hour(target_hour: int) -> void:
	var minutes_into_day: float = fmod(_total_minutes, MINUTES_PER_DAY)
	var target_minutes: float = float(clampi(target_hour, 0, HOURS_PER_DAY - 1) * MINUTES_PER_HOUR)
	var delta: float = target_minutes - minutes_into_day
	if delta <= 0.0:
		delta += MINUTES_PER_DAY
	advance_game_minutes(delta)


## Testo "HH:MM" per la UI.
func format_clock() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]


func to_dict() -> Dictionary:
	return {"total_minutes": _total_minutes}


func from_dict(data: Dictionary) -> void:
	_total_minutes = maxf(float(data.get("total_minutes", NEW_GAME_START_HOUR * MINUTES_PER_HOUR)), 0.0)
