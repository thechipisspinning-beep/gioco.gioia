# Animal World — Stato dei lavori

> Aggiornato a ogni sessione di lavoro. Legenda: ✅ completato e verificato · 🔧 in corso · ⏳ da fare · ⛔ bloccato

**Ultimo aggiornamento:** 2026-11-22
**Fase attuale:** 3 completata → prossima: 4 (Gioia definitiva e personalizzazione)
**Motore:** Godot 4.7.2 (D-30)

## Riepilogo fasi
| Fase | Stato |
|------|-------|
| 1 — Concept e GDD | ✅ |
| 2 — Architettura e setup progetto | ✅ |
| 3 — Movimento e telecamera | ✅ (da provare dal committente) |
| 4 — Protagonista Gioia | ⏳ |
| 5 — Prima area esplorabile | ⏳ |
| 6 — Primo animale e interazione | ⏳ |
| 7 — Adozione | ⏳ |
| 8 — Casa e personalizzazione | ⏳ |
| 9 — Missioni e ricompense | ⏳ |
| 10 — Diario e salvataggi | ⏳ |
| 11 — Cucina e giardinaggio | ⏳ |
| 12 — Espansione del mondo | ⏳ |
| 13 — Ottimizzazione e test | ⏳ |

## Fase 1 — Concept e GDD ✅
GDD v1.0, architettura Godot, tutte le decisioni registrate (`DECISIONI_APERTE.md`), piano di sviluppo.

## Fase 2 — Setup progetto ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| Progetto Godot 4.7 (Forward+ / Mobile / Compatibility per il web), fisica Jolt | ✅ | Importazione senza errori |
| Mappa degli input generata da `tools/setup_input_map.gd` (tastiera, controller) | ✅ | Usata dai test |
| Traduzioni IT/EN (`localization/strings.csv`) | ✅ | Screenshot in italiano e inglese |
| `GameTime` (logica pura) + autoload `GameClock`, `EventBus` | ✅ | 9 test unitari |
| `DevTools`: input simulato, screenshot, scena di avvio da riga di comando | ✅ | Usato per le verifiche visive |
| Runner di test headless (`tests/run_tests.gd`) | ✅ | Verificato che rilevi anche i fallimenti asincroni |
| Esportazioni Web, Windows, Linux (`export_presets.cfg`) | ✅ Web provata · ⏳ Windows/Linux non ancora provate | Build web avviata in Chromium (desktop e telefono emulato) |
| CI GitHub Actions: test + build web + pubblicazione su Pages | 🔧 | Vedi "Da fare" sotto |

## Fase 3 — Movimento e telecamera ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| `PlayerController`: camminata/corsa analogiche relative alla telecamera, accelerazione e frenata morbide, salto piccolo con coyote time e buffer, pendenze fino a 46°, recupero dalle cadute | ✅ | 11 test di integrazione con fisica reale |
| `CameraRig`: orbita (mouse, stick, touch), zoom, SpringArm anti-muri, riallineamento automatico alle spalle, inquadratura adattata agli schermi verticali | ✅ | 5 test di integrazione + screenshot |
| Controlli touch: joystick fluttuante (al bordo = corsa), trascinamento telecamera, pulsante salto | ✅ | Test in Chromium con telefono emulato (tocchi reali via CDP) |
| HUD minimo: giorno/ora, suggerimento dei controlli adattato al dispositivo | ✅ | Screenshot |
| Gioia provvisoria (forme semplici) con animazione procedurale: passo, dondolio, inclinazione in corsa, schiacciamento all'atterraggio | ✅ | Screenshot; sarà sostituita in Fase 4 |
| Shader toon + palette ufficiale + compensazione luce per il renderer web | ✅ | Colori misurati: differenza < 10/255 tra desktop e web |
| Sandbox di prova (rampe 15°/30°/55°, scala, piattaforme, tunnel, casetta, laghetto, recinto, alberi, 3200 fili d'erba e fiori in MultiMesh) | ✅ | Screenshot |

**Test automatici:** 25 superati, 0 falliti.

## Da fare / limiti noti
- **GitHub Pages:** per pubblicare la versione web va attivato una volta su GitHub: *Settings → Pages → Source: GitHub Actions*. Senza, la CI esegue comunque test e build.
- **Prestazioni reali non misurate:** qui il rendering è software (3 fps nel browser). Serve una prova su un telefono e un PC veri; il budget verrà verificato in Fase 5.
- **Export Android:** richiede SDK Android e chiave di firma; da configurare in Fase 5. iOS richiede un Mac (D-42).
- **Controller fisico:** mappato ma non provato con un controller vero (qui non c'è hardware).

## Bug trovati e corretti
| Bug | Causa | Correzione |
|-----|-------|------------|
| L'orologio andava 60 volte troppo veloce | Fattore di conversione sbagliato (60 minuti di gioco per secondo invece di 1) | `game_minutes_per_real_second = 1.0`, coperto da test |
| Con lo stick a metà Gioia era più lenta del dovuto | L'intensità dell'input veniva applicata due volte | La direzione viene normalizzata, l'intensità applicata solo alla velocità |
| Colori slavati sul web | Il renderer Compatibility somma luce ambientale e sole diversamente | Classe `Lighting` con fattori misurati per renderer |
| Su telefono compariva il suggerimento "WASD" | I tocchi generano anche clic del mouse emulati | Gli eventi emulati vengono ignorati (anche per la cattura del mouse) |
