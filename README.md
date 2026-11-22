# Animal World

Videogioco 3D di simulazione di vita, esplorazione e cura degli animali, sviluppato con **Godot 4.7** (GDScript).
La protagonista, **Gioia**, vive su un'isola enorme piena di animali reali da incontrare, curare e adottare.

## Provare il gioco
La versione web viene pubblicata automaticamente su GitHub Pages a ogni aggiornamento:
**https://thechipisspinning-beep.github.io/gioco.gioia/** (funziona anche da telefono).

**Tastiera e mouse:** WASD muoversi · Shift correre · Spazio saltare · E interagire · clic per controllare la telecamera · rotella zoom · J diario · I zaino · P foto · Esc pausa.
**Controller:** stick sinistro muoversi · R2 correre · X/□ saltare · A interagire · stick destro telecamera · L1/R1 zoom · Select diario · Start pausa.
**Telefono:** joystick a sinistra (al bordo per correre) · trascinare a destra per la telecamera · pulsanti per saltare e interagire · Foto, Zaino, Diario e Pausa in alto.

Cosa c'è: un'isola di circa 2 km con villaggio, campagna e fattoria, foresta, lago, montagna, prati e spiagge; 21 specie di animali da incontrare, curare e adottare (fino a 3 compagni al seguito); casa da arredare e ampliare; orto, cucina, negozio, veterinaria; 8 abitanti; una storia in 18 capitoli più missioni secondarie e giornaliere; ciclo giorno/notte e meteo; diario, foto e 3 slot di salvataggio.

## Documentazione
| Documento | Contenuto |
|-----------|-----------|
| [docs/GDD.md](docs/GDD.md) | Game Design Document |
| [docs/ARCHITETTURA.md](docs/ARCHITETTURA.md) | Architettura tecnica (Godot) |
| [docs/DECISIONI_APERTE.md](docs/DECISIONI_APERTE.md) | Decisioni prese e ancora aperte |
| [docs/PIANO_SVILUPPO.md](docs/PIANO_SVILUPPO.md) | Fasi e milestone |
| [docs/STATO_LAVORI.md](docs/STATO_LAVORI.md) | Avanzamento e bug noti |

## Sviluppo
```
godot --headless --path . --import                    # importa le risorse
godot --headless --path . -s res://tests/run_tests.gd # esegue i test
godot --path .                                         # avvia il gioco
```
