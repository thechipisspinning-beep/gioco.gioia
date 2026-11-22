# Animal World

Videogioco 3D di simulazione di vita, esplorazione e cura degli animali, sviluppato con **Godot 4.7** (GDScript).
La protagonista, **Gioia**, vive su un'isola enorme piena di animali reali da incontrare, curare e adottare.

## Provare il gioco
La versione web viene pubblicata automaticamente su GitHub Pages a ogni aggiornamento:
**https://thechipisspinning-beep.github.io/gioco.gioia/** (funziona anche da telefono).

Controlli: WASD per muoversi, Shift per correre, Spazio per saltare, clic per controllare la telecamera con il mouse, rotella per lo zoom. Con il controller: stick sinistro, R2 per correre, X/□ per saltare. Su telefono: joystick a sinistra, trascinare a destra per la telecamera.

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
