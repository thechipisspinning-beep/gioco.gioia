# Animal World — Stato dei lavori

> Aggiornato a ogni sessione di lavoro. Legenda: ✅ completato e verificato · 🔧 in corso · ⏳ da fare · ⛔ bloccato

**Ultimo aggiornamento:** 2026-11-22
**Fase attuale:** 11 completata → prossima: 12 (espansione del mondo). Ordine scelto: prima gli animali (6, 7), poi i salvataggi (10), poi 4, 5, 8, 9, 11, 12, 13
**Motore:** Godot 4.7.2 (D-30)

## Riepilogo fasi
| Fase | Stato |
|------|-------|
| 1 — Concept e GDD | ✅ |
| 2 — Architettura e setup progetto | ✅ |
| 3 — Movimento e telecamera | ✅ (da provare dal committente) |
| 4 — Protagonista Gioia | ✅ |
| 5 — Prima area esplorabile | ✅ (terreno di tutta l'isola; contenuti dettagliati nel villaggio e a casa, le altre zone si arricchiscono in Fase 12) |
| 6 — Primo animale e interazione | ✅ |
| 7 — Adozione | ✅ |
| 8 — Casa e personalizzazione | ✅ |
| 9 — Missioni e ricompense | ✅ |
| 10 — Diario e salvataggi | ✅ |
| 11 — Cucina e giardinaggio | ✅ |
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
| CI GitHub Actions: test + build web + pubblicazione su Pages | ✅ | Prima esecuzione completa riuscita; gioco online su https://thechipisspinning-beep.github.io/gioco.gioia/ |

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

## Fase 6 — Primo animale e interazione ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| Dati delle specie e degli oggetti come Resource (`data/species`, `data/items`), autoload `Database` e `GameState` | ✅ | Test: catalogo caricato, cibi coerenti |
| `AnimalState`, `AnimalRegistry`, `Inventory`, `DiscoveryLog` (logica pura, salvabili) | ✅ | Test di andata/ritorno dei dati |
| `TrustModel`: amicizia con rendimenti decrescenti, cibo preferito/rifiutato, selvatici più lenti, spavento | ✅ | 12 test unitari |
| `AnimalAgent`: girovagare, annusare, sedersi, sdraiarsi, dormire di notte, curiosità, timidezza e fuga, coccole, mangiare, riportare la pallina | ✅ | 9 test di integrazione + screenshot |
| Modello procedurale dei quadrupedi (cane, volpe) con animazioni: passo, coda, orecchie, sguardo, occhi che sbattono, saltelli | ✅ | Screenshot |
| `Interactor` + scheda con cuori + menu delle azioni + notifiche + pulsante touch | ✅ | Screenshot, navigazione da tastiera/controller |

## Fase 7 — Adozione, bisogni e malattia ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| Adozione con nome (finestra con "Suggerisci un nome"), adozioni illimitate | ✅ | 7 test + screenshot del flusso completo |
| Compagni al seguito (max 3, D-04) in formazione, "Torna a casa" | ✅ | Test con fisica: il compagno segue Gioia per 10 m |
| Volpe selvatica: più timida, scappa se Gioia corre, 90 di amicizia e 3 giorni di visite (D-16) | ✅ | Test |
| `AnimalHealth`: bisogni che calano, malattia dopo 12 ore di trascuratezza, morte dopo 3 giorni (D-17, D-35), modalità serena (D-38), solo adottati (D-40) | ✅ | 11 test unitari, anche con salti di tempo grandi |
| Cura: medicina dalla cassetta del veterinario (1 al giorno), convalescenza | ✅ | Test di integrazione |
| Servizio `AnimalCare`: aggiorna ogni ora anche gli animali non presenti nella scena, notifiche | ✅ | Test |

**Test automatici:** 80 superati, 0 falliti.

## Fase 10 — Salvataggi e diario ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| `SaveCodec`: formato JSON versionato con migrazioni, rifiuta file rovinati o di versioni future | ✅ | Test |
| `SaveManager`: 3 slot, scrittura sicura (temporaneo → verifica → sostituzione), copia di riserva usata se il file principale è rovinato | ✅ | 8 test, incluso il file danneggiato |
| Salvataggio automatico ogni 3 minuti, dopo un'adozione, alla chiusura e quando l'app va in background | ✅ | Verificato a vista: il file viene creato |
| Ripristino completo: animali, inventario, scoperte, cibi preferiti scoperti, ora, modalità serena, posizione di Gioia | ✅ | Test di andata/ritorno |
| Menu principale (Continua, Nuova partita con scelta dello slot e Modalità serena, Carica, Lingua, Esci) | ✅ | Screenshot, navigazione da tastiera/controller |
| Menu di pausa (Riprendi, Diario, Salva, Menu principale) | ✅ | Screenshot |
| Diario: Animali (incontrati, orari, cibo preferito scoperto, curiosità), Famiglia (cuori, bisogni, salute, ricordi), Progressi | ✅ | Screenshot |
| Lingua scelta ricordata (`Settings`) | ✅ | |

**Test automatici:** 88 superati, 0 falliti.

## Fase 4 — Protagonista Gioia ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| `CharacterAppearance` + `CharacterCatalog`: 6 toni di pelle, 6 acconciature × 8 colori, 5 vestiti × 8 colori, 3 scarpe × 5 colori, 6 accessori × 5 colori, 3 stature | ✅ | 6 test unitari |
| Stili sbloccabili (impermeabile, stivaletti, corona di fiori, zainetto) saltati finché bloccati | ✅ | Test |
| Modello di Gioia ricostruito dall'aspetto, con viso (occhi, guance, sorriso) | ✅ | Test: ogni stile si costruisce; screenshot |
| Gesti animati: accarezzare (si accovaccia), porgere il cibo, lanciare la pallina, spazzolare; Gioia si gira verso l'animale | ✅ | Test |
| Schermata di personalizzazione con anteprima dal vivo, "Sorprendimi", "Ruota"; telecamera in modalità ritratto che nasconde gli animali | ✅ | Screenshot, navigazione con tasto di conferma |
| Si apre a inizio partita e dallo specchio vicino alla casetta; aspetto salvato | ✅ | Test di ripristino |

**Test automatici:** 97 superati, 0 falliti.

## Fase 5 — Prima area esplorabile ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| `IslandLayout` (dati): isola di ~1,9 km di diametro, 7 zone, aree spianate, lago, 7 sentieri, casa di Gioia | ✅ | Test |
| `TerrainModel`: altezza e colore deterministici (costa irregolare, colline, montagna a nord con neve, lago, spiagge, sentieri) | ✅ | 8 test |
| `WorldStreamer` + `TerrainChunk`: blocchi da 64 m caricati/scaricati attorno a Gioia, collisione heightmap, alberi/cespugli/rocce/canne in MultiMesh, erba e fiori solo vicino | ✅ | Test: carica, scarica, memoria stabile; blocco costruito in 5–12 ms |
| `PropMeshes`: alberi tondi e pini, cespugli, rocce, erba, fiori, canne fusi in una mesh per tipo (un materiale) | ✅ | Screenshot |
| `DayNight`: sole e luna che si muovono, cielo con stelle (shader), colori per fascia oraria, compensazione per il web | ✅ | Test: sole a mezzogiorno, luna a mezzanotte |
| Mare con shader stilizzato; acqua profonda non attraversabile (Gioia scivola lungo la riva; gli animali la evitano) | ✅ | Test con fisica sulla costa |
| Villaggio: piazza, fontana, 6 casette colorate, lampioni, panchine, cassetta del veterinario | ✅ | Screenshot |
| Casa di Gioia (il rifugio della nonna) con giardino recintato e specchio; gli animali adottati vivono nel giardino | ✅ | Screenshot |
| `ZoneTracker`: nome della zona quando ci si entra, luoghi scoperti nel diario | ✅ | |
| Menu principale → isola; versione web provata in Chromium fino alla personalizzazione | ✅ | Screenshot |

**Test automatici:** 109 superati, 0 falliti.

## Fase 8 — Casa e personalizzazione ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| `HomeLayout` + `FurnitureCatalog`: griglia da 0,5 m, 4 stanze sbloccabili (soggiorno, camera, cucina, stanza degli animali), 14 mobili, porte e passaggi sempre liberi, tappeti sotto i mobili | ✅ | 7 test unitari |
| Interno della casa (scena separata, D-14) in stile casa delle bambole, costruito dai dati; mobili con collisione | ✅ | Test + screenshot |
| Porta di casa e porta d'uscita con dissolvenza (`SceneRouter`), arrivo davanti alla porta | ✅ | |
| Modalità arredamento: cursore con mouse/tocco/tastiera/controller, anteprima verde/rossa, ruota, colore, togli, raccogli e sposta | ✅ | Test + screenshot |
| Colori di pareti e pavimento per stanza, colori esterni di muri e tetto (D-21); la casa esterna si allarga con le stanze | ✅ | |
| Mangiatoia automatica in giardino (D-37): si riempie con le crocchette, nutre ogni ora gli animali di casa affamati | ✅ | Test |
| Arredamento iniziale e mobili in inventario a inizio partita | ✅ | |

**Test automatici:** 122 superati, 0 falliti.

## Fase 9 — Missioni e ricompense ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| `QuestLog` (logica pura): prerequisiti, obiettivi multipli, cuori raggiunti, giornaliere deterministiche, salvataggio | ✅ | 7 test unitari, coerenza dei dati |
| `QuestData`: storia principale in 10 capitoli (il rifugio della nonna, D-12), 7 missioni degli abitanti, 6 giornaliere (3 al giorno) | ✅ | Test: la storia avanza con eventi reali |
| `QuestService`: collega gli eventi (incontri, adozioni, cure, raccolta, dialoghi, mobili, zone, mangiatoia) e consegna le ricompense (monete, oggetti, mobili, vestiti sbloccati, permessi per nuove stanze, custode) | ✅ | Test |
| 8 abitanti (D-11) con aspetto proprio, passeggiano attorno alla piazza, si girano verso Gioia, "!" quando hanno qualcosa da dire | ✅ | Test + screenshot |
| Dialoghi; negozio di Bruno (compra oggetti e mobili, vendi ciò che raccogli) (D-19); veterinaria che cura a pagamento (D-36) | ✅ | Test |
| Custode degli animali (D-37), sbloccato da Lia: tiene felici e puliti gli animali di casa | ✅ | Test |
| Oggetti da raccogliere (fiori, conchiglie, funghi, erbe, frutti di bosco) per zona, ricompaiono ogni giorno | ✅ | Test |
| HUD: monete e missione principale con obiettivi; diario: scheda Missioni | ✅ | Screenshot |

**Test automatici:** 138 superati, 0 falliti.

**Nota su D-15 (zone sbloccate progressivamente):** su un'isola aperta senza barriere fisiche, lo sblocco è realizzato tramite la storia: le missioni guidano Gioia verso le zone nell'ordine previsto e introducono animali e abitanti legati a ciascuna. Tutte le zone restano esplorabili liberamente (registrato nel GDD).

## Fase 11 — Cucina e giardinaggio ✅
| Attività | Stato | Verifica |
|----------|-------|----------|
| `Cooking` + `RecipeData`: 6 ricette (biscotti e snack per animali, mix di bacche per la volpe, medicina alle erbe D-36, macedonia e zuppa di funghi per Gioia), alcune sbloccate dalle missioni | ✅ | Test |
| Fornello in casa (mobile interattivo) e fuoco da campo in giardino | ✅ | Screenshot |
| Finestra della cucina con ingredienti posseduti/necessari e mini-gioco "Mescola!" facoltativo (D-23): 2 centri su 3 = porzione extra | ✅ | Test + screenshot |
| `Garden`: 6 parcelle, 4 piante (carote, fragole, erbe, fiori), crescita solo se annaffiate (12 ore per annaffiatura), nessuna pianta muore | ✅ | 4 test unitari + ciclo completo nel gioco |
| Zaino con tutti gli oggetti per categoria; i piatti di Gioia si mangiano: buonumore (+25% amicizia) ed energia (+15% velocità) per 3 ore (D-22) | ✅ | Test |
| Semi nel negozio; Bruno compra anche carote e fragole; nuovi cibi preferiti (biscotti per il cane, mix di bacche per la volpe) | ✅ | Test |
| Missioni "Il primo piatto" e "L'orto della nonna" | ✅ | |

**Test automatici:** 148 superati, 0 falliti.

## Da fare / limiti noti
- **Prestazioni reali non misurate:** qui il rendering è software (3 fps nel browser). Serve una prova su un telefono e un PC veri. Su telefono il raggio di caricamento è già ridotto (5 × 5 blocchi); se la costruzione dei blocchi causasse scatti, in Fase 13 si sposterà su un thread separato (build native) o si dividerà su più frame.
- **Export Android:** richiede SDK Android e chiave di firma; da configurare in Fase 5. iOS richiede un Mac (D-42).
- **Due macchie bianche nel cielo** visibili in alcune inquadrature di giorno: da verificare in Fase 13 (probabilmente il disco del sole con il bagliore).
- **Controller fisico:** mappato ma non provato con un controller vero (qui non c'è hardware).

## Bug trovati e corretti
| Bug | Causa | Correzione |
|-----|-------|------------|
| L'orologio andava 60 volte troppo veloce | Fattore di conversione sbagliato (60 minuti di gioco per secondo invece di 1) | `game_minutes_per_real_second = 1.0`, coperto da test |
| Con lo stick a metà Gioia era più lenta del dovuto | L'intensità dell'input veniva applicata due volte | La direzione viene normalizzata, l'intensità applicata solo alla velocità |
| Colori slavati sul web | Il renderer Compatibility somma luce ambientale e sole diversamente | Classe `Lighting` con fattori misurati per renderer |
| Su telefono compariva il suggerimento "WASD" | I tocchi generano anche clic del mouse emulati | Gli eventi emulati vengono ignorati (anche per la cattura del mouse) |
| Gli animali usavano un riferimento a Gioia non più valido | Riferimento salvato una volta sola | L'animale verifica e ritrova Gioia quando serve |
| Scheda animale e notifiche fuori dallo schermo | Ancoraggi calcolati prima che il pannello avesse dimensioni | Posizionamento calcolato a ogni frame |
| Riflessi degli occhi enormi | Dimensione non proporzionata alla testa | Dimensioni relative alla testa |
| Curare un animale lo faceva riammalare subito | Il tempo non ancora simulato veniva calcolato dopo la cura | La cura aggiorna prima lo stato all'ora attuale |
| Un animale malato che dormiva non si poteva curare | Nessuna azione disponibile durante il sonno | La medicina si può dare anche mentre dorme |
| Un compagno poteva comparire nella scena sbagliata durante un cambio di scena | Anche il gestore della scena in uscita reagiva | Agisce solo il gestore della scena corrente |
| Il test runner considerava superati i test interrotti da un errore di script | Gli errori del motore non venivano intercettati | `ErrorCatcher` (Logger) fa fallire ogni test con errori |
| Il punto esclamativo della volpe spaventata non funzionava | Nodo aggiunto due volte | Corretto (trovato grazie al runner più severo) |
| I sentieri dell'isola non venivano letti | Liste di punti non convertite nel tipo giusto | Dichiarate come `PackedVector2Array` |
| Terreno, erba e fiori slavati su desktop, troppo scuri sul web | I colori per vertice non venivano convertiti da sRGB (e il renderer web lo fa già) | Conversione nello shader solo dove serve |
| Foschia che velava cielo e colori | Nebbia troppo densa applicata anche al cielo | Nebbia leggera, cielo escluso |
| Errori di formattazione dei testi delle missioni | Testi mancanti nelle traduzioni | Aggiunti; il runner severo li ha segnalati |
| Pannello della personalizzazione schiacciato | Lo ScrollContainer non trasmette l'altezza del contenuto | Altezza calcolata dal contenuto |
| Diario e pausa in alto a sinistra senza sfondo | I pannelli creati da codice restavano di dimensione zero | Ancoraggi e margini impostati insieme (`set_anchors_and_offsets_preset`) |
