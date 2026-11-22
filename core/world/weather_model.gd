class_name WeatherModel
extends RefCounted
## Meteo semplice (D-07): sereno, nuvoloso o pioggia, deciso a blocchi di
## 6 ore di gioco in modo deterministico (stessa partita = stesso meteo).
## Il primo giorno è sempre sereno, per accogliere il giocatore.

enum Kind { CLEAR, CLOUDY, RAIN }

const BLOCK_HOURS: int = 6
## Sopra questa quota la pioggia diventa neve.
const SNOW_ALTITUDE: float = 70.0


static func at(day: int, hour: int) -> Kind:
	if day <= 1:
		return Kind.CLEAR
	var block: int = day * (24 / BLOCK_HOURS) + hour / BLOCK_HOURS
	var r: float = float(absi(hash(block * 92821 + 17)) % 1000) / 1000.0
	if r < 0.58:
		return Kind.CLEAR
	if r < 0.83:
		return Kind.CLOUDY
	return Kind.RAIN


static func is_raining(day: int, hour: int) -> bool:
	return at(day, hour) == Kind.RAIN
