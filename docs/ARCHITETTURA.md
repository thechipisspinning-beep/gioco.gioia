# Animal World — Architettura tecnica (Godot 4)

> **Versione:** 1.0 · **Ultimo aggiornamento:** 2026-11-22
> Motore: **Godot 4.7.2 stable** · Linguaggio: **GDScript tipizzato** (D-30).
> Questa architettura sostituisce la precedente proposta per Unity.

---

## 1. Principi

1. **Sistemi indipendenti.** Ogni sistema vive nella propria cartella e comunica con gli altri tramite **segnali** dell'`EventBus` o API pubbliche dei servizi, mai cercando nodi per nome in giro per la scena.
2. **Dati separati dalla logica.** Il contenuto (specie, oggetti, ricette, mobili, missioni) è definito in **Resource** (`.tres`); lo stato di gioco in classi `RefCounted` serializzabili in dizionari.
3. **Logica pura testabile.** Le regole (amicizia, salute, inventario, missioni, crescita piante, salvataggio) stanno in `res://core/`, classi che **non dipendono dalla scena**: si testano in modalità headless in pochi secondi.
4. **Semplicità.** Niente plugin superflui. Pochi autoload (singleton) ben definiti.
5. **Prestazioni per progetto.** Streaming a blocchi, LOD, pooling e simulazione a livelli fin dall'inizio.
6. **Tipizzazione statica ovunque** (`var x: int`, `func f() -> void`), con warning di tipo trattati come errori.

---

## 2. Tecnologie

| Area | Scelta | Note |
|------|--------|------|
| Motore | Godot 4.7.2 stable | Gratuito, open source (MIT), nessun account |
| Rendering | **Forward+** su PC/console, **Mobile** su telefoni, **Compatibility** sul web | Lo stile toon è progettato per apparire uguale su tutti e tre |
| Fisica | Jolt (integrata in Godot 4.4+) | Più stabile e veloce |
| Input | InputMap con azioni; tastiera/mouse, controller, touch | Il gameplay legge solo azioni |
| Navigazione | NavigationServer3D (NavigationRegion3D per blocco) | Movimento animali e NPC |
| UI | Control + Theme condiviso | Navigabile con controller e touch |
| Salvataggi | JSON in `user://`, versionato, scrittura atomica | Leggibile e migrabile |
| Traduzioni | TranslationServer con file CSV (`it`, `en`) | Nessun testo nel codice |
| Test | Runner di test interno headless (`tests/run_tests.gd`) | Nessuna dipendenza esterna |
| CI | GitHub Actions: test + build web | D-32 |
| Asset 3D | Generati dal team (mesh procedurali/script), D-29 | Sostituibili con modelli `.glb` |

---

## 3. Struttura delle cartelle

```
project.godot
autoload/            # Singleton globali (EventBus, GameClock, Services…)
core/                # Logica pura, senza dipendenze dalla scena — testata
  time/  animals/  inventory/  quests/  home/  garden/  cooking/  save/
data/                # Resource di contenuto (.tres)
  species/  items/  recipes/  plants/  furniture/  quests/  outfits/  zones/
systems/             # Nodi e scene di gameplay, per sistema
  player/  camera/  animals/  world/  interaction/  home/  activities/
ui/                  # HUD, menu, diario, controlli touch, tema
art/                 # Generatori di mesh, shader, materiali, palette
audio/
scenes/
  boot/  main_menu/  world/  interiors/
  sandbox/           # Scene di prova di singoli sistemi
localization/        # it.csv / en.csv
tests/               # Test automatici (unit + integrazione)
tools/               # Script di build, screenshot, esportazione
docs/                # Documentazione di progetto
```

---

## 4. Autoload (singleton)

| Autoload | Responsabilità |
|----------|----------------|
| `EventBus` | Segnali globali del gameplay (`animal_met`, `animal_adopted`, `item_collected`, `recipe_cooked`, …). Disaccoppia missioni, diario e notifiche dai sistemi che generano gli eventi |
| `GameClock` | Ora/giorno di gioco, velocità, pausa; emette `hour_changed`, `day_started`. Avvolge `core/time/GameTime` |
| `Settings` | Opzioni utente (audio, grafica, controlli, lingua, Modalità serena) |
| `SaveManager` | Raccolta e ripristino dello stato di tutti i servizi, slot, salvataggio automatico |
| `Services` (fasi successive) | Accesso a `AnimalRegistry`, `Inventory`, `QuestLog`, `HomeLayout`, `Garden`… |

Regola: un autoload non dipende dalla scena corrente; la UI legge lo stato e invia comandi, non contiene regole di gioco.

---

## 5. Scene e flusso

```
Boot ──► MainMenu ──► World (persistente)
                        ├── Chunk_x_y (caricati/scaricati per distanza)
                        └── Interior_* (caricati su richiesta, D-14)
```

- **World:** contiene Gioia, telecamera, sole/luna/cielo, gestore streaming, HUD.
- **Chunk:** l'isola (2 × 2 km, D-05) è divisa in blocchi di 128 × 128 m. Il `WorldStreamer` carica in background (`ResourceLoader.load_threaded_request`) i blocchi entro un raggio dal giocatore e libera quelli lontani. Ogni blocco contiene terreno, vegetazione (MultiMeshInstance3D), oggetti, navigazione e punti di comparsa degli animali.
- **Interni:** scene separate con dissolvenza; l'esterno viene sospeso.

---

## 6. Sistemi

### 6.1 Tempo e giorno/notte
- `core/time/GameTime`: minuti di gioco totali, conversioni giorno/ora, avanzamento in base al tempo reale (1 giorno = 24 min, D-06). Logica pura, testata.
- `systems/world/DayNight`: ruota il sole (DirectionalLight3D) e la luna, interpola colori di cielo, luce e nebbia per fascia oraria, mostra le stelle di notte tramite shader del cielo.
- Tutti i sistemi a tempo (bisogni, malattia, crescita piante) leggono `GameClock`: accelerando il tempo si testano in pochi secondi.

### 6.2 Giocatore (Gioia)
- `CharacterBody3D` con movimento relativo alla telecamera, accelerazione/decelerazione morbide, camminata/corsa analogica, salto piccolo (D-13), pendenze e gradini.
- **Personalizzazione modulare:** un unico scheletro; ogni slot (capelli, maglia, …) è una mesh agganciata. I colori passano come parametri dello shader toon (maschere colore) → nessun materiale duplicato. L'aspetto è salvato come `{slot: item_id, colori}`.
- `Interactor`: individua l'oggetto interagibile migliore davanti a Gioia (distanza + angolo + priorità) e mostra il suggerimento contestuale.

### 6.3 Telecamera (D-02)
- Perno che segue Gioia con smorzamento, `SpringArm3D` per non attraversare i muri, orbita con mouse/stick/trascinamento touch, zoom, limiti di inclinazione.
- Modalità: esplorazione, interazione ravvicinata, costruzione dall'alto.

### 6.4 Animali
**Dati:** `SpeciesDefinition` (Resource): taglia, zone, orari, cibi, timidezza, difficoltà di adozione, parametri bisogni/salute, scena del modello, abilità da compagno.

**Stato:** `AnimalState` (core): id stabile, specie, variante, nome, personalità, amicizia, bisogni, salute, luogo (casa/giardino/compagno/selvatico).

**Simulazione a livelli** — permette adozioni senza limite rigido:

| Livello | Quando | Cosa succede |
|---------|--------|--------------|
| Attivo | Vicino e visibile | Nodo completo, IA a stati, navigazione, animazioni |
| Ridotto | Distanza media | IA aggiornata a intervalli, animazioni semplificate |
| Virtuale | Lontano o in scena non caricata | Solo dati; bisogni e salute calcolati dal tempo trascorso |

- Budget di animali attivi per piattaforma (mobile 10–15, PC 25–40).
- I selvatici senza rapporto non vengono salvati: compaiono dai punti di comparsa e tornano nel pool.
- **IA:** macchina a stati semplice (`Idle`, `Wander`, `Eat`, `Sleep`, `Flee`, `Curious`, `Follow`, `Petted`, `Play`, `Sick`).
- **Salute (D-17, D-35, D-38, D-40):** `core/animals/AnimalHealth`: `Sano → Malato (giorno 1–3) → Morto`, `Convalescente` dopo la cura. Le soglie sono dati della specie. In Modalità serena la malattia non avanza oltre il giorno 3. Coperta da test.

### 6.5 Interazione e adozione
- `TrustModel` (core): guadagno di fiducia per azione, bonus cibo preferito, penalità se Gioia corre vicino a specie timide, rendimenti decrescenti nello stesso giorno; soglie più alte e giorni di visita richiesti per i selvatici (D-16).
- `Adoption`: verifica condizioni, scelta del nome, registrazione nell'`AnimalRegistry`, segnale `animal_adopted`.
- Compagni: massimo 3 (D-04), stato `Follow` con formazione morbida e teletrasporto discreto se restano indietro.

### 6.6 Inventario, casa, giardino, cucina, missioni
- `Inventory` (core): `item_id → quantità`, operazioni atomiche.
- `HomeLayout` (core): stanze sbloccate + mobili `{id, stanza, cella, rotazione, colore}` su griglia (D-20).
- `Garden` (core): parcelle con pianta, fase, ultima annaffiatura; crescita calcolata dal tempo.
- `Cooking` (core): verifica e consumo ingredienti, ricette per Gioia/animali/medicine (D-36).
- `QuestLog` (core): missioni data-driven composte da obiettivi standard (`meet_species`, `adopt`, `collect`, `cook`, `plant`, `place_furniture`, `visit_zone`, `talk`), aggiornate dai segnali dell'`EventBus`.
- **Diario:** solo una vista su registro animali, scoperte, missioni e ricette → non può andare fuori sincrono.

### 6.7 Salvataggi
- Un dizionario radice con `schema_version`; ogni servizio implementa `to_dict()` / `from_dict()`.
- Scrittura **atomica** (file temporaneo → rinomina) + copia di backup dell'ultimo salvataggio valido.
- **Migrazioni** versionate per non rompere i salvataggi vecchi.
- Riferimenti ai contenuti solo tramite **ID stringa stabili**.
- Mobile: salvataggio automatico quando l'app va in background (`NOTIFICATION_APPLICATION_PAUSED`).

---

## 7. Multipiattaforma

- **Tre profili di qualità:** Basso (mobile/web), Medio, Alto. Regolano risoluzione 3D, ombre, distanza di visibilità, densità della vegetazione, animali attivi.
- **Input:** azioni InputMap con tre schemi; i controlli touch (joystick virtuale, trascinamento della telecamera, pulsanti) compaiono solo su dispositivi touch.
- **UI adattiva:** ancore e contenitori, aree sicure (notch), bersagli touch grandi.
- **Esportazioni:** Windows, Linux, Android e Web si generano da questo ambiente; macOS/iOS richiedono un Mac (D-42); console tramite società di porting (D-41).

## 8. Budget di prestazioni (iniziali)

| Voce | Mobile / Web | PC / Console |
|------|--------------|--------------|
| Frame rate | 30 fps stabili | 60 fps |
| Draw call per frame | < 300 | < 1500 |
| Triangoli a schermo | < 300k | < 1.5 M |
| Animali attivi | 10–15 | 25–40 |
| Memoria | < 1.5 GB | secondo piattaforma |

Tecniche: blocchi caricati in streaming, LOD automatici delle mesh, visibility range, MultiMesh per la vegetazione, materiali condivisi da palette, IA distribuita su più frame, nessuna allocazione superflua in `_process`.

## 9. Qualità e verifica

- **Test automatici** (`tests/`), eseguiti headless:
  `godot --headless --path . -s res://tests/run_tests.gd`
- **Scene sandbox** per ogni sistema.
- **Screenshot automatici** di controllo (`tools/screenshot.gd`) eseguiti su display virtuale con rendering software, per verificare l'aspetto visivo.
- **Build web** giocabile nel browser per il committente.
- **Menu debug** nelle build di sviluppo: tempo accelerato, teletrasporto, oggetti, animali.

## 10. Convenzioni di codice

- `snake_case` per file, funzioni e variabili; `PascalCase` per `class_name` e nodi; `UPPER_CASE` per costanti.
- Un file = una classe; `class_name` per le classi riutilizzabili.
- Tipizzazione statica obbligatoria; niente `get_node("../../..")`: riferimenti con `@export` o `%NomeUnico`.
- Segnali al passato (`adopted`, `item_collected`).
- Commenti `##` (documentazione) sulle classi e funzioni pubbliche; commenti normali solo dove il *perché* non è ovvio.
