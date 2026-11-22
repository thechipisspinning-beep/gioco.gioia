# Animal World — Piano di sviluppo

> **Versione:** 1.0 · **Ultimo aggiornamento:** 2026-11-22
>
> Regola d'oro: **ogni fase si chiude solo quando i suoi criteri di completamento sono verificati.** Non si passa alla successiva con sistemi "quasi funzionanti".

## Ipotesi per le stime

Dal 2026-11-22 lo sviluppo è svolto interamente dal team (Claude Code) in **Godot 4.7** (D-30), con asset 3D generati via codice (D-29). Le durate indicate sono stime di lavoro equivalente e servono a confrontare le fasi tra loro.

## Milestone

| Milestone | Fasi | Obiettivo |
|-----------|------|-----------|
| **M0 — Fondamenta** | 1–2 | Design approvato, progetto Godot pronto |
| **M1 — "Si muove bene"** | 3–4 | Gioia cammina e corre in modo piacevole |
| **M2 — Primo incontro** | 5–7 | Una zona, un animale, adozione completa |
| **M3 — Vertical slice** | 8–11 | Un piccolo pezzo del gioco con *tutti* i sistemi, rifinito come il prodotto finale |
| **M4 — Produzione** | 12 | Tutte le zone, specie e contenuti |
| **M5 — Rilascio** | 13 | Ottimizzazione, test, bilanciamento |

Il **vertical slice (M3)** è il momento chiave: dimostra che il gioco è divertente e permette di stimare con precisione la produzione dei contenuti.

---

## Fase 1 — Concept e Game Design Document ✅ completata
**Durata:** 1 settimana
- GDD, architettura, decisioni aperte, piano (questo documento).
- **Completata quando:** il committente ha letto i documenti e preso le decisioni 🔴.

## Fase 2 — Architettura tecnica e setup del progetto ✅ completata
**Durata:** 1–2 settimane
- Progetto Godot 4.7 (Forward+ / Mobile / Compatibility), mappa degli input, traduzioni IT/EN.
- Struttura cartelle, `.gitignore`.
- Autoload `EventBus`, `GameClock` (logica in `GameTime`), `DevTools`, scena Boot.
- Livelli di qualità (Low/Medium/High) e build di prova su PC, Android e iOS.
- Runner di test interno e CI su GitHub Actions (test + versione web pubblicata su GitHub Pages).
- **Completata quando:** il progetto si importa senza errori, Boot → scena di test funziona, i test passano.

## Fase 3 — Prototipo movimento e telecamera ✅ completata
**Durata:** 2 settimane
- `PlayerMotor` (camminata, corsa, pendenze, gradini, eventuale salto).
- Telecamera in terza persona con orbita, SpringArm (collisioni) e zoom.
- Input tastiera/mouse, controller e **touch** (joystick virtuale, telecamera a trascinamento).
- Scena *greybox* con salite, scale, ostacoli, acqua.
- **Completata quando:** movimento fluido a 60 fps, nessun incastro nella geometria, telecamera che non attraversa i muri, controller, tastiera e touch equivalenti; provato anche su un telefono reale. Test di "sensazione" con il committente.

## Fase 4 — Creazione della protagonista Gioia ✅ completata
**Durata:** 3–5 settimane (dipende dagli asset)
- Modello base con scheletro, sistema di parti modulari, shader con maschere colore.
- AnimationTree: idle, camminata, corsa, transizioni, IK piedi e sguardo.
- Schermata di creazione/personalizzazione con anteprima.
- Salvataggio dell'aspetto.
- **Completata quando:** almeno 3 acconciature, 3 parti superiori, 3 inferiori, 2 scarpe, 2 accessori combinabili con colori liberi, senza compenetrazioni evidenti; l'aspetto sopravvive a salvataggio/caricamento.

## Fase 5 — Prima area esplorabile ✅ completata
**Durata:** 3–4 settimane
- Scelta e realizzazione di una prima zona (proposta: **Villaggio + Campagna**, area ~300 × 300 m).
- Sistema di streaming a celle (anche con poche celle, per validarlo subito).
- Ciclo giorno/notte completo: sole, luna, stelle, illuminazione per fascia oraria.
- Vegetazione con instancing, audio ambientale.
- Definizione dello stile visivo definitivo (shader, palette, post-processing).
- **Completata quando:** la zona è attraversabile senza scatti, il ciclo giorno/notte è bello in ogni fascia oraria, i budget di prestazioni sono rispettati sia su PC sia sul telefono di riferimento.

## Fase 6 — Primo animale e sistema di interazione ✅ completata
**Durata:** 3 settimane
- `SpeciesDefinition`, `AnimalState`, AI a stati, NavMesh.
- Primo animale (proposta: **cane** o **gatto**) con animazioni espressive.
- `Interactor` + prompt contestuale; accarezzare, dare cibo, giocare.
- Modello di fiducia/amicizia, registrazione "Incontrato" nel diario (versione minima).
- Simulazione a livelli (attivo/ridotto/virtuale) e pooling, testata con molte istanze.
- **Completata quando:** l'animale si comporta in modo credibile per 10 minuti di osservazione, le interazioni sono chiare e piacevoli, 40 animali in scena restano nei budget.

## Fase 7 — Sistema di adozione ✅ completata
**Durata:** 2 settimane
- Soglia di amicizia, schermata nome, `AdoptionService`, `AnimalRegistry`.
- Compagni al seguito (attiva/disattiva), animali che vanno a casa.
- Seconda specie **selvatica** (es. **volpe**) con adozione più difficile, per validare la generalità del sistema.
- Bisogni, **malattia, cura e morte** (D-17) con avvisi chiari; aiuti alla cura per molti animali (D-37).
- **Completata quando:** si può adottare, nominare, far seguire (max 3), mandare a casa; un animale trascurato si ammala, si può curare, e muore dopo 3 giorni senza cure; il sistema regge 100+ animali adottati in un salvataggio di test senza cali di prestazioni.

## Fase 8 — Casa e personalizzazione ✅ completata
**Durata:** 4–5 settimane
- Interno della casa (scena separata), transizione entrata/uscita.
- Modalità costruzione su griglia: posiziona, ruota, sposta, rimuovi, colori.
- Prima espansione (nuova stanza), spazi per animali usati dagli animali adottati.
- Inventario e primi 20–30 mobili/decorazioni.
- **Completata quando:** la casa si arreda in modo intuitivo con mouse e controller, gli animali usano cucce/cuscini, tutto è salvato correttamente.

## Fase 9 — Missioni e ricompense ✅ completata
**Durata:** 2–3 settimane
- `QuestService`, obiettivi data-driven, ricompense, bacheca/NPC.
- Missioni del tutorial ("primo giorno") e 10 missioni secondarie.
- HUD della missione attiva, notifiche.
- **Completata quando:** tutte le missioni sono completabili, nessuna si blocca, ricompense consegnate una sola volta.

## Fase 10 — Diario e salvataggi ✅ completata
**Durata:** 2–3 settimane
- Diario completo (animali, famiglia, missioni, scoperte, progressi).
- Salvataggio completo: slot, autosave, scrittura atomica, backup, migrazioni.
- **Completata quando:** test di salvataggio/caricamento su ogni sistema; un salvataggio interrotto a metà non corrompe i dati; un salvataggio della versione precedente si carica.

## Fase 11 — Cucina e giardinaggio ✅ completata
**Durata:** 3 settimane
- Ricette per Gioia e per animali, sblocchi, interfaccia cucina.
- Parcelle, semina, innaffiatura, crescita nel tempo, raccolto.
- Collegamento con missioni e diario.
- **Completata quando:** ciclo completo "pianta → raccogli → cucina → dai all'animale" funzionante e divertente.

### 🎯 Revisione Vertical Slice (fine M3)
Sessione di gioco di 45–60 minuti con giocatori esterni. Si misura: divertimento, chiarezza, bug, prestazioni. **Si decide insieme** cosa migliorare prima di entrare in produzione.

## Fase 12 — Espansione del mondo ✅ completata
**Durata:** la fase più lunga (mesi), dipende dai contenuti
- Zone restanti (spiaggia, foresta, lago, montagna, prati).
- Restanti specie animali, NPC, missioni, ricette, mobili, vestiti.
- Meteo, modalità foto, abilità dei compagni, contenuti post-game (se approvati).
- Si procede **zona per zona**, ognuna chiusa e testata prima della successiva.

## Fase 13 — Ottimizzazione e test ✅ completata
**Durata:** 4–8 settimane
- Profilazione su hardware minimo, riduzione memoria e caricamenti.
- Bilanciamento progressione ed economia.
- Test di regressione completi, accessibilità, localizzazione.
- Certificazione console e pubblicazione sugli store mobile.
- Build di rilascio per PC, console e mobile.

---

## Processo per ogni fase

1. **Pianificazione:** elenco attività in [`STATO_LAVORI.md`](STATO_LAVORI.md), decisioni necessarie chiarite.
2. **Sviluppo:** piccoli commit su branch dedicato, codice + test.
3. **Verifica tecnica:** test automatici + istruzioni di verifica manuale nell'editor.
4. **Verifica del committente:** prova della versione web (browser o telefono) e approvazione.
5. **Chiusura:** aggiornamento di GDD, Stato lavori, registro modifiche.
