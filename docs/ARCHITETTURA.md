# Animal World — Architettura tecnica (Unity)

> **Versione:** 0.1 (proposta) · **Ultimo aggiornamento:** 2026-11-22
> Le scelte marcate **[DA CONFERMARE]** dipendono da decisioni aperte (vedi [`DECISIONI_APERTE.md`](DECISIONI_APERTE.md)).

---

## 1. Principi

1. **Sistemi indipendenti, dipendenze esplicite.** Ogni sistema vive nel proprio Assembly Definition e comunica con gli altri tramite interfacce o eventi, mai cercando oggetti in scena "a caso".
2. **Dati separati dalla logica.** Il contenuto (specie, oggetti, ricette, missioni, mobili) è definito in **ScriptableObject**; lo stato di gioco (cosa possiede il giocatore) è in **classi C# semplici** serializzabili.
3. **Logica pura testabile.** Le regole di gioco (amicizia, inventario, missioni, crescita piante, salvataggio) stanno in un assembly **senza dipendenze da UnityEngine** quando possibile, così si possono coprire con unit test veloci.
4. **Semplicità prima di tutto.** Niente framework di dependency injection esterni, niente ECS/DOTS se non serve. Un piccolo `GameServices` locator inizializzato all'avvio è sufficiente.
5. **Prestazioni per progetto, non per correzione.** Streaming del mondo, LOD, pooling e simulazione a livelli sono previsti dall'inizio.

---

## 2. Stack tecnologico proposto

| Area | Scelta | Motivo |
|------|--------|--------|
| Versione Unity | **Unity 6 LTS** (ultima LTS disponibile all'avvio) | Supporto lungo, URP maturo, UI Toolkit runtime |
| Render pipeline | **URP** | Ideale per stile stilizzato, scalabile da Switch-class a PC |
| Input | **Input System** (nuovo) | Tastiera/mouse + controller con lo stesso codice, rebinding |
| Telecamera | **Cinemachine 3** | Orbit, collisioni, transizioni tra camere (esplorazione / interazione / costruzione) |
| Animazione | **Mecanim** + **Animation Rigging** | Blend tree locomozione, IK piedi e look-at |
| Contenuti caricabili | **Addressables** | Caricamento/scaricamento di zone, animali e mobili; controllo memoria |
| UI | **UI Toolkit** [DA CONFERMARE] (alternativa: uGUI) | Menu complessi (diario, inventario, costruzione) più facili da mantenere |
| Terreno | **Unity Terrain** a tile, oppure mesh modellate [DA CONFERMARE, D-08] | Terrain è rapido da iterare; mesh danno più controllo sullo stile |
| Vegetazione | GPU instancing (detail/tree del Terrain o sistema custom) | Migliaia di piante a basso costo |
| Navigazione | **AI Navigation** (NavMesh) per tile | Movimento animali e NPC |
| Salvataggio | JSON (Newtonsoft Json for Unity) con versione dello schema | Leggibile, debuggabile, migrabile |
| Localizzazione | **Unity Localization** package | Tabelle di stringhe, nessun testo hard-coded |
| Test | Unity Test Framework (EditMode + PlayMode) | Verifica automatica dei sistemi |
| Versionamento | Git + **Git LFS** per asset binari | Modelli, texture e audio fuori dalla storia "pesante" |

---

## 3. Struttura delle cartelle

```
Assets/
  _Project/
    Art/                  # Modelli, texture, materiali, shader, VFX (per categoria)
      Characters/Gioia/
      Animals/<Specie>/
      Environment/<Zona>/
      Props/  Furniture/  UI/
    Audio/                # Musica, ambienti, SFX, versi animali
    Data/                 # ScriptableObject di contenuto
      Species/  Items/  Recipes/  Plants/  Furniture/  Quests/  Outfits/  Zones/
    Prefabs/
    Scenes/
      Boot.unity          # Inizializzazione servizi
      MainMenu.unity
      World/              # Scena "persistente" + scene tile della mappa
      Interiors/          # Casa, negozi
      Sandbox/            # Scene di test per singoli sistemi
    Scripts/
      Core/               # Logica pura (no UnityEngine) — testabile
      Runtime/            # MonoBehaviour e integrazione con Unity, per sistema
      Editor/             # Strumenti editor (validatori, generatori)
    Settings/             # URP asset, Input Actions, Localization, Addressables
  Tests/
    EditMode/
    PlayMode/
```

---

## 4. Assembly Definition (moduli)

```
AnimalWorld.Core            (noEngineReferences: true) — modelli di stato, regole, eventi
AnimalWorld.Runtime.Common  — GameServices, EventBus, tempo, utilità, pooling
AnimalWorld.Runtime.Player  — controller Gioia, telecamera, interazione
AnimalWorld.Runtime.Animals — specie, AI, simulazione, compagni
AnimalWorld.Runtime.World   — streaming tile, giorno/notte, meteo, zone
AnimalWorld.Runtime.Home    — casa, costruzione, arredamento
AnimalWorld.Runtime.Activities — cucina, giardinaggio, raccolta
AnimalWorld.Runtime.Quests  — missioni, obiettivi, ricompense
AnimalWorld.Runtime.Save    — serializzazione, slot, migrazioni
AnimalWorld.Runtime.UI      — HUD, menu, diario
AnimalWorld.Editor          — strumenti editor
AnimalWorld.Tests.EditMode / AnimalWorld.Tests.PlayMode
```

Regola: i moduli `Runtime.*` dipendono da `Core` e `Common`, **mai tra di loro in modo circolare**. La UI legge lo stato e invia comandi, non contiene regole di gioco.

---

## 5. Flusso di avvio e scene

```
Boot ──► MainMenu ──► World (persistente)
                        ├── Tile_x_y (additive, caricate/scaricate per distanza)
                        └── Interior_Home / Interior_Shop (additive, su richiesta)
```

- **Boot:** crea i servizi (`SaveService`, `TimeService`, `InventoryService`, `AnimalRegistry`, `QuestService`, …), carica impostazioni, passa al menu.
- **World (persistente):** contiene Gioia, telecamere, luce sole/luna, gestore streaming, UI.
- **Tile:** la mappa è divisa in celle (es. 128 × 128 m). Il `WorldStreamer` carica le celle entro un raggio dal giocatore e scarica quelle lontane (Addressables + scene additive). Ogni cella contiene terreno, vegetazione, props, NavMesh e *spawn point* degli animali.
- **Interni:** caricati come scene additive con transizione breve; l'esterno viene messo in pausa/nascosto.

---

## 6. Sistemi principali

### 6.1 Servizi ed eventi
- `GameServices`: registro statico minimale inizializzato da Boot (`GameServices.Get<IInventoryService>()`).
- `EventBus` tipizzato leggero (`Publish<AnimalAdoptedEvent>(…)`) per disaccoppiare: es. il `QuestService` ascolta `AnimalAdoptedEvent` senza conoscere il sistema di adozione.
- Ogni evento significativo per missioni/diario passa dal bus: `AnimalMet`, `AnimalAdopted`, `ItemCollected`, `RecipeCooked`, `PlantHarvested`, `FurniturePlaced`, `ZoneVisited`, `NpcTalked`.

### 6.2 Tempo (giorno/notte)
- `TimeService` in Core: ora corrente, giorno, velocità, pausa. Emette eventi `HourChanged`, `DayStarted`.
- `DayNightController` (Runtime): ruota sole/luna, aggiorna skybox, colore luce, nebbia e post-processing tramite curve/gradienti per fascia oraria; stelle con shader del cielo.
- Tutti i sistemi a tempo (crescita piante, bisogni animali, routine) leggono il `TimeService` → si possono testare accelerando il tempo.

### 6.3 Giocatore (Gioia)
- `PlayerMotor` basato su **CharacterController** (prevedibile, niente fisica "scivolosa"), camminata/corsa analogica, gestione pendenze e gradini.
- `PlayerAnimator`: blend tree 1D/2D per locomozione, layer per interazioni, IK piedi e look-at.
- `Interactor`: rileva l'`IInteractable` più rilevante davanti a Gioia (sfera + priorità + angolo) e mostra il prompt; animali, oggetti, mobili, NPC implementano la stessa interfaccia.
- **Personalizzazione modulare:** un unico scheletro; ogni slot (capelli, maglia, …) è uno `SkinnedMeshRenderer` agganciato allo scheletro. I colori sono applicati con **MaterialPropertyBlock** o maschere colore in uno shader dedicato → un solo materiale per parte, infinite combinazioni senza duplicare asset. L'aspetto è salvato come `CharacterAppearance { slotId → itemId, colori }`.

### 6.4 Animali (cuore del gioco)

**Dati**
- `SpeciesDefinition` (ScriptableObject): taglia, zone, orari, cibi, timidezza, varianti, prefab Addressable, set animazioni, parametri AI.
- `AnimalState` (Core, serializzabile): id univoco, specie, variante, nome, personalità, amicizia, bisogni, luogo (casa/giardino/compagno/selvatico), statistiche.
- `AnimalRegistry` (Core): elenco di tutti gli animali **noti** (adottati + selvatici con cui c'è un rapporto). Fonte unica di verità.

**Simulazione a livelli (LOD di simulazione)** — è ciò che permette adozioni senza limite rigido:

| Livello | Quando | Costo | Cosa succede |
|---------|--------|-------|--------------|
| **Attivo** | Vicino al giocatore e visibile | Alto | GameObject completo, AI a stati, NavMesh, animazioni piene, IK |
| **Ridotto** | Distanza media / fuori vista | Medio | Animazioni a frequenza ridotta, AI aggiornata a intervalli, niente IK |
| **Virtuale** | Lontano / in una scena non caricata (es. animali a casa mentre esplori) | Quasi nullo | Nessun GameObject: solo dati. I bisogni si aggiornano matematicamente col tempo trascorso |

- Un `AnimalSimulationManager` promuove/declassa gli animali tra i livelli in base alla distanza, con un **budget massimo** di animali attivi (es. 25–40, da tarare per piattaforma).
- Gli **animali selvatici** non sono persistenti: vengono generati dagli *spawn point* della cella secondo specie/ora/zona e rilasciati quando la cella si scarica (con **object pooling**). Diventano persistenti solo quando nasce un rapporto (fiducia > 0) o vengono adottati.
- **AI:** macchina a stati semplice e leggibile (`Idle`, `Wander`, `Graze/Eat`, `Sleep`, `Flee`, `Curious`, `FollowPlayer`, `BeingPetted`, `Play`), con transizioni guidate da dati della specie e personalità. Niente behaviour tree complessi finché non servono.
- **Compagni al seguito:** stato `FollowPlayer` con posizionamento in formazione morbida, teletrasporto discreto se restano troppo indietro, gestione ingresso/uscita dagli interni.
- **Rendering:** LOD Group (3 livelli + impostore/cull), animatori con `cullingMode = CullUpdateTransforms`, GPU instancing per specie numerose.

### 6.5 Interazione e adozione
- `AnimalInteractable` espone azioni disponibili in base allo stato (accarezza, dai cibo, gioca, spazzola, adotta).
- `TrustModel` (Core): regole pure per amicizia/fiducia (bonus cibo preferito, penalità se Gioia corre vicino a specie timide, rendimenti decrescenti per azioni ripetute nello stesso giorno).
- `AdoptionService`: verifica soglia, apre UI nome, crea/aggiorna `AnimalState`, assegna luogo di residenza, pubblica `AnimalAdopted`.

### 6.6 Inventario e oggetti
- `ItemDefinition` (SO): id, categoria, icona, impilabile, valore, tag (cibo per…, ingrediente, decorazione).
- `Inventory` (Core): mappa `itemId → quantità` + oggetti unici; operazioni atomiche `TryAdd/TryRemove`.

### 6.7 Casa e costruzione
- `HomeLayout` (Core): stanze sbloccate + elenco mobili `{ furnitureId, stanza, cella griglia, rotazione, colore }`.
- `BuildModeController`: telecamera dall'alto, griglia, anteprima "fantasma", validazione sovrapposizioni, annulla/ripeti.
- Espansioni casa = prefab di stanza modulari attivati in base ai progressi.
- Spazi animali sono mobili speciali con tag (`bed`, `scratching`, `pond`…) che gli animali in casa usano tramite *smart object*.

### 6.8 Cucina e giardinaggio
- `RecipeDefinition` (SO): ingredienti, risultato, destinatario (Gioia / specie), condizioni di sblocco.
- `CookingService` (Core): verifica ingredienti, consuma, produce, pubblica `RecipeCooked`.
- `PlantDefinition` (SO): fasi di crescita, ore per fase, acqua richiesta, raccolto.
- `GardenState` (Core): parcelle con pianta, fase, ultimo innaffiamento. Crescita calcolata dal `TimeService` → funziona anche quando la scena del giardino non è caricata.

### 6.9 Missioni
- `QuestDefinition` (SO): titolo/descrizione (chiavi di localizzazione), prerequisiti, lista di `ObjectiveDefinition`, ricompense.
- Obiettivi **data-driven** riutilizzabili: `MeetSpecies`, `AdoptAnimal`, `ReachFriendship`, `CollectItem`, `CookRecipe`, `PlantOrHarvest`, `PlaceFurniture`, `VisitZone`, `TalkToNpc`.
- `QuestService` ascolta l'EventBus e aggiorna il progresso; nessuna missione richiede codice dedicato per i casi standard.

### 6.10 Diario
- Il diario **non ha stato proprio**: è una vista sopra `AnimalRegistry`, `DiscoveryLog`, `QuestService`, `CookingService`, statistiche. Così non può andare "fuori sincrono".
- `DiscoveryLog` (Core): specie incontrate (prima volta, luogo, ora), luoghi scoperti, collezionabili.

### 6.11 Salvataggio e caricamento
- Un unico `SaveGame` radice con `schemaVersion` che raccoglie gli stati di tutti i servizi (`ISaveable` → `CaptureState()` / `RestoreState()`).
- Scrittura **atomica** (file temporaneo → rinomina) + backup dell'ultimo salvataggio valido, per evitare salvataggi corrotti in caso di crash.
- **Migrazioni** versionate (`v1 → v2 → …`) per non rompere i salvataggi quando il gioco cresce.
- Riferimenti ai contenuti tramite **ID stringa stabili** (mai riferimenti diretti a asset o indici di lista).
- Salvataggio automatico su eventi chiave + intervallo; scrittura asincrona per non bloccare il frame.
- Astrazione `ISaveStorage` per supportare in futuro piattaforme con API di salvataggio proprie (console, cloud).

### 6.12 UI
- Schermate gestite da un `UIRouter` (stack: HUD → Diario → Dettaglio animale…), con focus/navigazione controller garantita.
- Pattern **presentatore**: la UI osserva lo stato e chiama i servizi; nessuna regola di gioco nella UI.
- Testi solo tramite chiavi di localizzazione.

---

## 7. Prestazioni e memoria — budget iniziali [DA CONFERMARE con la piattaforma]

| Voce | Budget indicativo (PC medio / console) |
|------|---------------------------------------|
| Frame rate | 60 fps PC, 30 fps stabili su hardware modesto |
| Draw call / SetPass | < 1500 / < 250 per frame |
| Triangoli a schermo | < 1.5 M |
| Animali attivi completi | 25–40 |
| Gioia | ~25–35k triangoli (LOD0) |
| Animale medio | 5–12k triangoli (LOD0) |
| Memoria texture | Atlanti/palette condivise, mip-map sempre attive |
| GC per frame | 0 byte nel gameplay normale (pooling, niente LINQ/allocazioni in Update) |

Tecniche: streaming a celle, LOD + culling, occlusion culling negli interni, GPU instancing per vegetazione e rocce, baking della luce ambientale dove possibile, Animator culling, aggiornamenti AI distribuiti su più frame, profilazione regolare con Profiler e Memory Profiler.

---

## 8. Qualità e verifica

- **Unit test (EditMode)** su tutta la logica Core: inventario, amicizia, missioni, crescita piante, cucina, salvataggio/migrazioni.
- **PlayMode test** su flussi chiave: movimento, interazione, adozione, entrata/uscita casa, salvataggio → caricamento.
- **Scene Sandbox** per ogni sistema, giocabili da sole.
- **Validatori editor**: controllano che ogni `SpeciesDefinition`, `ItemDefinition`, ecc. abbia ID univoco, icona, chiavi di localizzazione, prefab valido.
- **Menu debug** in build di sviluppo: accelerare il tempo, teletrasporto, aggiungere oggetti, generare animali, sbloccare tutto.
- Checklist QA per ogni fase (vedi [`PIANO_SVILUPPO.md`](PIANO_SVILUPPO.md)).

> **Nota operativa:** l'ambiente in cui lavora Claude Code non dispone dell'editor Unity. Claude scrive codice, test e configurazioni, ma la compilazione nell'editor, i test PlayMode e le verifiche visive devono essere eseguiti sul computer di sviluppo. Per questo ogni consegna includerà istruzioni di verifica precise. Si può valutare una pipeline CI (es. GameCI su GitHub Actions) per compilare ed eseguire i test automaticamente a ogni commit — vedi D-32.

---

## 9. Convenzioni di codice

- C# standard Microsoft: `PascalCase` per tipi/metodi/proprietà, `_camelCase` per campi privati, `camelCase` per locali/parametri.
- Namespace = assembly (`AnimalWorld.Animals`, …).
- `[SerializeField] private` invece di campi pubblici.
- Niente `FindObjectOfType`/`GameObject.Find` nel gameplay; niente `Update` vuoti; niente stringhe "magiche" (costanti o ID tipizzati).
- Commenti XML sui tipi pubblici e commenti solo dove il *perché* non è ovvio.
- Un file per tipo; file < ~400 righe come segnale di allarme per suddividere.
