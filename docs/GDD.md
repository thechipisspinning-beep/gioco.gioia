# Animal World — Game Design Document

> **Versione:** 1.0
> **Stato:** in revisione con il committente
> **Ultimo aggiornamento:** 2026-11-22
>
> Questo documento è la fonte di verità per il design del gioco. Ogni decisione approvata viene registrata qui; quelle ancora aperte sono in [`DECISIONI_APERTE.md`](DECISIONI_APERTE.md).
> Dal 2026-11-22 tutte le decisioni sono prese (il committente le ha delegate al team): il dettaglio e le motivazioni sono in `DECISIONI_APERTE.md`.

---

## 1. Visione

**Animal World** è una simulazione di vita rilassante in 3D: Gioia vive su un'isola enorme e piena di vita, incontra animali reali, se ne prende cura, li adotta e costruisce una casa sempre più bella dove vivere insieme a loro.

### 1.1 Frase guida (pillar statement)
> *"Ogni passeggiata sull'isola porta un incontro, e ogni incontro può diventare un amico che torna a casa con te."*

### 1.2 Pilastri del design
Ogni funzionalità deve rafforzare almeno uno di questi pilastri. Se non lo fa, va rimessa in discussione.

| # | Pilastro | Significato concreto |
|---|----------|----------------------|
| 1 | **Gli animali sono il cuore** | Ogni sistema (casa, cucina, giardino, missioni) ha un collegamento con gli animali. |
| 2 | **Un'isola viva da scoprire** | Ogni zona ha animali, piante, segreti e atmosfera propri; il mondo cambia con l'ora del giorno. |
| 3 | **Accoglienza e responsabilità** | Nessun combattimento, nessuna fretta nell'esplorazione. Prendersi cura degli animali è però una responsabilità vera: se vengono trascurati si ammalano e possono morire (§ 6.7). |
| 4 | **Espressione personale** | Gioia, la casa e il giardino riflettono i gusti del giocatore. |
| 5 | **Progressione gratificante** | C'è sempre un prossimo obiettivo piccolo e uno grande all'orizzonte. |

### 1.3 Cosa il gioco NON è
- Non è un gioco con combattimenti, nemici o game over.
- Non contiene creature magiche o fantastiche.
- Non contiene cuccioli: tutti gli animali sono adulti.
- Non prevede di cavalcare gli animali.
- Non è sviluppato su Roblox.
- Non è multiplayer.

---

## 2. Informazioni generali

| Voce | Valore |
|------|--------|
| Titolo provvisorio | Animal World |
| Protagonista | Gioia |
| Genere | Simulazione di vita, esplorazione, cura degli animali |
| Modalità | Single-player |
| Motore | **Godot 4.7** (GDScript) — D-30 |
| Piattaforma | **PC e mobile (Android, iOS)** al lancio, **console** in seguito; versione web per i test (D-01, D-34, D-39) |
| Pubblico | Tutti, dai 7 anni (D-03) |
| Durata obiettivo | Decine di ore di gioco, con contenuto aperto e senza "fine" obbligata |

---

## 3. Direzione artistica

### 3.1 Linee guida
- Stile **stilizzato e morbido**, ispirato *nello spirito* ai giochi Nintendo: forme arrotondate, proporzioni leggermente esagerate, colori saturi ma armoniosi, illuminazione calda.
- **Identità visiva originale**: nessun personaggio, modello, texture, musica o elemento riconoscibile di altri giochi.
- Animali **realistici nell'anatomia e nel comportamento** (sono animali veri), ma **stilizzati nella forma** e molto **espressivi** (occhi, orecchie, coda, postura).

### 3.2 Regole tecniche dello stile
- **Shading:** toon/cel morbido a 2–3 bande con rim light leggera (D-08).
- **Texture:** prevalentemente colori piatti / gradienti da *palette texture* (atlante colori condiviso) → pochi materiali, ottime prestazioni, coerenza cromatica.
- **Palette per zona:** ogni bioma ha 5–7 colori dominanti definiti in una "scheda zona".
- **Post-processing:** bloom leggero, color grading per fascia oraria, nebbia atmosferica per la profondità.
- **Contorni (outline):** opzionali, da valutare nei test visivi.

### 3.3 Riferimenti da produrre
- Moodboard per zona (da preparare insieme al committente).
- Scheda di stile per Gioia, per gli animali e per l'architettura.

---

## 4. La protagonista: Gioia

### 4.1 Ruolo
Gioia è il personaggio controllato dal giocatore. Eredita dalla nonna un **vecchio rifugio per animali** sull'isola, ormai in rovina, e lo fa rinascere (D-12). La sua storia è legata alla scoperta e alla cura degli animali.

### 4.2 Personalizzazione
Il sistema è **modulare**: ogni categoria è uno slot, ogni slot accetta oggetti compatibili.

| Categoria | Esempi | Colorabile |
|-----------|--------|-----------|
| Viso | Forma occhi, sopracciglia, lentiggini | Sì (occhi) |
| Pelle | Tonalità | Sì |
| Capelli | Acconciature (corti, lunghi, coda, trecce, chignon…) | Sì (1–2 colori) |
| Parte superiore | Magliette, felpe, camicie | Sì |
| Parte inferiore | Pantaloni, gonne, salopette | Sì |
| Abito intero | Vestiti, tute | Sì |
| Scarpe | Stivali, sneakers, sandali | Sì |
| Copricapo | Cappelli, cerchietti, fiocchi | Sì |
| Accessori | Occhiali, zaino, borsa, sciarpa | Sì |

- La personalizzazione è accessibile all'inizio (creazione) e in seguito da uno **specchio/armadio** in casa.
- Nuovi capi si ottengono da missioni, negozi, scoperte.
- **Altezza:** 3 preset; nessuna variante di corporatura (D-10).

### 4.3 Movimento e animazioni
| Azione | Note |
|--------|------|
| Idle | Con varianti "idle fidget" dopo alcuni secondi di inattività |
| Camminata | Velocità analogica (stick) o tasto |
| Corsa | Tasto/stick premuto a fondo. Nessuna stamina, per restare rilassante |
| Salto | Piccolo salto; niente nuoto: l'acqua profonda respinge dolcemente (D-13) |
| Accarezzare | Altezze diverse (animale piccolo a terra / animale grande) |
| Dare da mangiare | Ciotola a terra o dalla mano |
| Spazzolare / lavare | Per la cura |
| Giocare | Lanciare una pallina/bastoncino |
| Raccogliere | Oggetti a terra, frutti, fiori |
| Giardinaggio | Zappare, piantare, innaffiare, raccogliere |
| Cucinare | Animazione al bancone/fornello |
| Sedersi / dormire | Panchine, letto (per far passare il tempo) |

- Le animazioni devono essere **fluide**: blend tree per locomozione, IK per piedi sul terreno e per lo sguardo verso animali/oggetti vicini.

---

## 5. Il mondo

### 5.1 Struttura
- **Un'unica isola enorme**, esplorabile liberamente e senza caricamenti visibili durante l'esplorazione (streaming a celle — vedi Architettura).
- **Dimensione (D-05):** circa 2 × 2 km per la versione 1.0 (5–8 minuti correndo in linea retta da costa a costa, ma con rilievi, sentieri e punti di interesse ogni poche decine di metri). È già grande per il genere; si può espandere in seguito.
- Gli interni (casa, negozi) sono scene separate con breve dissolvenza, per prestazioni migliori (D-14).

### 5.2 Zone (prima proposta)
| Zona | Atmosfera | Animali tipici (esempi) | Elementi caratteristici |
|------|-----------|-------------------------|-------------------------|
| **Villaggio** (hub) | Accogliente, vivace | Cani, gatti, piccioni, passeri | Negozi, piazza, bacheca missioni, casa di Gioia vicina |
| **Campagna / fattoria** | Dorata, tranquilla | Mucche, pecore, capre, galline, maiali, cavalli, asini, conigli | Campi, fienili, staccionate, mulino |
| **Spiaggia** | Luminosa, ventilata | Gabbiani, granchi, tartarughe marine, foche | Faro, scogli, conchiglie, molo |
| **Foresta** | Fresca, misteriosa | Volpi, cervi, scoiattoli, ricci, gufi, tassi | Radure, funghi, ruscelli |
| **Lago / zona umida** | Calma, riflessi | Anatre, aironi, rane, castori, lontre | Canneti, pontili, ninfee |
| **Montagna** | Aria pura, panorami | Stambecchi, marmotte, aquile, camosci | Sentieri, rifugio, cima panoramica |
| **Prati fioriti / colline** | Colorata, primaverile | Lepri, farfalle, api, cavalli selvatici | Fiori rari, arnie, mongolfiera? |

- Ogni zona ha: palette colori, musica, suoni ambientali, set di vegetazione, set di animali, punti di interesse, segreti/collezionabili.
- Le zone si **sbloccano progressivamente** tramite la storia (D-15): le missioni principali guidano Gioia verso ogni zona e vi introducono animali e abitanti. L'isola resta comunque esplorabile liberamente (nessuna barriera fisica).

### 5.3 Ciclo giorno/notte
- Sole e luna con traiettorie, cielo con stelle di notte, transizioni di colore (alba, giorno, tramonto, notte).
- **Gli animali reagiscono all'ora**: specie diurne/notturne (es. gufi e ricci di notte), routine (dormire, mangiare).
- **Durata (D-06):** 1 giorno di gioco = 24 minuti reali (1 ora = 1 minuto). Il tempo non scorre a gioco chiuso.
- Possibilità di dormire nel letto per passare alla mattina successiva.
- **Meteo (D-07):** sereno, nuvoloso, pioggia; neve solo in vetta. Le stagioni arriveranno in un aggiornamento successivo.

### 5.4 Senso di mondo vivo
- Animali selvatici che vagano, si incontrano, reagiscono a Gioia.
- **8 abitanti** del villaggio con dialoghi semplici e missioni (D-11).
- Elementi ambientali animati: erba e alberi mossi dal vento, farfalle, foglie, acqua.
- Eventi casuali leggeri (es. "un cervo si è avvicinato al ruscello", "stormo di anatre in volo al tramonto").

---

## 6. Gli animali

### 6.1 Principi
- Specie **reali e comuni**, domestiche e selvatiche.
- **Solo adulti.**
- Ogni specie ha comportamento credibile e personalità individuale.
- La cura ha conseguenze reali: un animale adottato trascurato **si ammala** e, se non curato, **muore in 3 giorni** (deciso, D-17). Dettagli in § 6.7.

### 6.2 Dati di ogni specie (definizione)
- Nome specie, categoria (domestico / da fattoria / selvatico), zone in cui appare, orari di attività.
- Taglia (piccola / media / grande) → determina animazioni di interazione e spazio richiesto in casa.
- Cibi preferiti, cibi accettati, cibi rifiutati.
- Attività di gioco preferite.
- Bisogno di spazio (casa, giardino, recinto, stagno…).
- **Difficoltà di avvicinamento** (es. gatto facile, volpe timida, cervo molto timido).
- Varianti di mantello/colore.
- Suoni e set di animazioni.

### 6.3 Ciclo di vita dell'incontro
```
Avvistamento → Avvicinamento → Fiducia → Amicizia → Adozione → Vita a casa / Compagno
   (diario)      (non spaventarlo)  (cibo, gesti)  (cura ripetuta)   (nome)
```

1. **Avvistamento:** l'animale viene registrato nel diario ("Incontrato").
2. **Avvicinamento:** Gioia deve muoversi lentamente (camminare, non correre) per non spaventare le specie timide.
3. **Fiducia:** offrire il cibo giusto, accarezzare, giocare. Barra/cuori di fiducia.
4. **Amicizia:** raggiunta la soglia, l'animale può essere adottato.
5. **Adozione:** il giocatore sceglie un nome. L'animale entra nella "famiglia".

- **Tutti gli animali sono adottabili**, anche i selvatici, ma **i selvatici sono più difficili** (D-16). La difficoltà si ottiene con:
  - soglia di amicizia più alta e guadagno di fiducia più lento;
  - più giorni di visite consecutive prima di poter adottare;
  - cibi specifici (spesso da cucinare) e condizioni particolari (ora del giorno, meteo, avvicinarsi senza correre);
  - spazio adatto già pronto in casa/giardino (es. stagno per la lontra, recinto ampio per il cervo).

### 6.4 Animali adottati
- Ogni animale adottato ha: **nome**, specie, variante colore, personalità, livello di amicizia, stato dei bisogni, data di adozione, preferenze scoperte.
- **Bisogni:** Fame, Felicità, Pulizia (massimo 3, per non trasformare il gioco in una gestione stressante).
- Gli animali **vivono a casa** (interno, giardino, spazi dedicati).
- Il giocatore sceglie **quali animali seguono Gioia** durante l'esplorazione; gli altri restano a casa.
- **Numero di adozioni:** nessun limite rigido di gameplay. Tecnicamente il sistema simula in modo completo solo gli animali vicini al giocatore (vedi Architettura § Animali).
- **Compagni al seguito:** massimo **3** contemporaneamente (deciso, D-04). È una scelta di leggibilità e prestazioni, non un limite alle adozioni.
- I compagni al seguito possono **aiutare** (es. un cane trova oggetti nascosti, un gatto segnala animali vicini) (D-18).

### 6.5 Personalità
Ogni animale riceve 1–2 tratti casuali che modificano animazioni e reazioni: *Giocherellone, Dormiglione, Goloso, Timido, Curioso, Affettuoso, Indipendente*.

### 6.6 Lista specie v1.0 (~25 specie, D-09)
- **Domestici:** cane (più razze/varianti), gatto, coniglio, criceto, pappagallino.
- **Fattoria:** mucca, pecora, capra, maiale, gallina, cavallo, asino, anatra.
- **Selvatici:** volpe, cervo, scoiattolo, riccio, gufo, tartaruga, rana, lontra, marmotta, stambecco, gabbiano, foca.
- **Primo animale: cane. Seconda specie: volpe** (selvatica). Ogni specie è un costo significativo (modello + rig + animazioni): conviene iniziare con poche specie fatte molto bene.

### 6.7 Salute, malattia e morte (deciso, D-17)
**Regola approvata:** se un animale adottato viene trascurato **si ammala**; se resta senza cure, **muore entro 3 giorni** dall'inizio della malattia.

Funzionamento:
```
Sano ──(bisogni a zero per troppo tempo)──► Malato: giorno 1 → giorno 2 → giorno 3 ──► Muore
                                               │
                                               └──(cura)──► Convalescente ──► Sano
```
- **Segnali chiari prima della malattia:** icona sopra l'animale, animazioni tristi, notifica, avviso nel diario. Il giocatore non deve mai essere colto di sorpresa.
- **Durante la malattia:** l'animale non segue Gioia, non gioca, resta nella cuccia; avvisi sempre più evidenti ogni giorno.
- **Morte:** momento delicato e rispettoso (nessuna scena cruda). L'animale resta nel diario con un ricordo.

Decisioni collegate:
- I 3 giorni sono **giorni di gioco** (~72 minuti); a gioco chiuso il tempo è fermo (D-35).
- Cura: ambulatorio veterinario + medicine preparate in cucina con erbe del giardino (D-36).
- Con molti animali: mangiatoie/abbeveratoi automatici (durano 2–3 giorni) e un custode sbloccabile (D-37).
- **Modalità serena** opzionale a inizio partita: gli animali si ammalano ma non muoiono; predefinita la morte attiva (D-38).
- Solo gli animali adottati possono ammalarsi (D-40).

---

## 7. Attività principali

### 7.1 Esplorazione
- Movimento libero, scoperta di zone, punti panoramici, oggetti raccoglibili, segreti.
- Mappa dell'isola che si completa man mano (fog of war leggero).
- Indicatori discreti per punti di interesse scoperti.

### 7.2 Ricerca e adozione degli animali
Vedi § 6.3.

### 7.3 Cura degli animali
| Azione | Effetto |
|--------|---------|
| Dare da mangiare | Fame ↑, Amicizia ↑ (di più con cibo preferito) |
| Accarezzare | Felicità ↑, Amicizia ↑ |
| Spazzolare / lavare | Pulizia ↑ |
| Giocare | Felicità ↑↑ |
| Portare a passeggio | Felicità ↑, scoperte |
| Curare un animale malato | Ferma la malattia (ambulatorio veterinario al villaggio o medicine preparate in cucina — D-36) |

### 7.4 Costruzione e personalizzazione della casa
Vedi § 8.

### 7.5 Cucina
Vedi § 9.

### 7.6 Giardinaggio
- Zappare, piantare semi, innaffiare, raccogliere.
- Piante: fiori (decorazione, missioni, felicità animali), ortaggi e frutta (ingredienti di cucina), erbe (ricette per animali).
- Le piante crescono nel tempo di gioco (fasi visive).
- Nessuna pianta "muore": se non innaffiata, semplicemente non cresce.
- Alcuni animali interagiscono col giardino (galline, api…).

### 7.7 Missioni e obiettivi
Vedi § 10.

### 7.8 Raccolta di oggetti e ricompense
- Raccoglibili: conchiglie, sassi colorati, fiori, piume, funghi, frutti, legna…
- Usati per: ricette, costruzione/arredamento, missioni, scambio con NPC.
- **Valuta di gioco (D-19):** monete + materiali; negozi al villaggio.

---

## 8. Casa e personalizzazione

- La casa parte **piccola** (1 stanza) e si **espande** per fasi: nuove stanze, piano superiore, giardino più grande, spazi per animali.
- **Stanze previste:** soggiorno, camera da letto, cucina, bagno, stanza degli animali, + stanze extra sbloccabili.
- **Spazi animali:** cucce, cuscini, tiragraffi, gabbie aperte/voliere, recinto, stalla, stagno, pollaio.
- **Arredamento:** posizionamento su **griglia** con rotazione a 90° (semplice, chiaro, compatibile con mouse, controller e touch — D-20).
- **Personalizzazione:** carta da parati, pavimenti, colori, mobili, decorazioni, luci.
- **Sblocchi:** mobili e decorazioni da missioni, negozi, scoperte, ricette.
- Modalità di costruzione con telecamera dall'alto dedicata.
- **Esterno** personalizzabile (tetto, colore pareti, recinzioni); posizione della casa fissa (D-21).

---

## 9. Cucina

- Si cucina in casa (fornello/bancone) — anche fuochi da campo in alcune zone.
- **Due famiglie di ricette:**
  - **Per Gioia:** effetto cosmetico o di comodità (es. corsa più veloce temporanea, "buonumore" che fa avvicinare gli animali più facilmente). Gioia non ha bisogni propri né fame obbligatoria (D-22).
  - **Per gli animali:** cibi specifici per specie, aumentano fame/felicità/amicizia; alcuni sono necessari per conquistare animali timidi.
- **Ricette sbloccabili:** da missioni, NPC, libri trovati nel mondo, sperimentazione.
- **Interazione:** scelta ingredienti + mini-gioco leggero e facoltativo (es. mescolare a tempo), saltabile (D-23).
- Ingredienti: dal giardino, raccolti nel mondo, comprati, prodotti dagli animali della fattoria (uova, latte, lana, miele — D-24).

---

## 10. Missioni e progressione

### 10.1 Tipi di missioni
| Tipo | Descrizione | Esempi |
|------|-------------|--------|
| **Principali** | Guidano la progressione e sbloccano zone/funzioni | "Ripara il ponte verso la foresta", "Costruisci la stanza degli animali" |
| **Secondarie** | Richieste di NPC, obiettivi di zona | "Trova il gatto della fornaia", "Pianta 5 girasoli" |
| **Giornaliere** | Piccoli obiettivi rinnovati ogni giorno di gioco | "Accarezza 3 animali", "Cucina un piatto" |
| **Traguardi** | Obiettivi di lungo termine | "Incontra tutti gli animali della spiaggia" |

### 10.2 Struttura di una missione
Composta da **obiettivi** standard e riutilizzabili:
- Trovare/incontrare un animale (specie o specifico).
- Adottare un animale.
- Raggiungere un livello di amicizia.
- Raccogliere N oggetti.
- Preparare una ricetta.
- Piantare/raccogliere N piante.
- Posizionare un mobile/decorazione.
- Visitare una zona/un punto.
- Parlare con un NPC.

### 10.3 Ricompense
Oggetti, decorazioni, mobili, vestiti, ricette, semi, valuta, espansioni della casa, accesso a nuove zone.

### 10.4 Curva di progressione
1. **Primo giorno (tutorial, ~30 min):** arrivo, prima casa, primo animale (cane o gatto), prima ricetta, primo seme.
2. **Prime ore:** villaggio + campagna, prime adozioni, prima espansione della casa.
3. **Metà gioco:** sblocco di foresta, spiaggia, lago; ricette per animali selvatici.
4. **Avanzato:** montagna, animali rari/timidi, casa completa.
5. **Post-game:** completamento del diario, collezionabili, decorazione libera.

---

## 11. Diario di Gioia

Il diario è un menu "libro" con schede:

| Scheda | Contenuto |
|--------|-----------|
| **Animali** | Enciclopedia: specie incontrate (silhouette se non ancora incontrate), zona, orari, cibi preferiti scoperti, curiosità reali sulla specie |
| **Famiglia** | Animali adottati: nome, foto/ritratto, personalità, amicizia, data di adozione, compagni attuali |
| **Missioni** | Attive e completate |
| **Ricette** | Ricette conosciute e ingredienti |
| **Scoperte** | Luoghi, collezionabili, segreti |
| **Progressi** | Statistiche e traguardi |
| **Foto** | Galleria della modalità foto (D-25) |

- Le **curiosità reali** sugli animali danno anche un valore educativo leggero.

---

## 12. Interfaccia e controlli

### 12.1 Principi UI
- Pulita, morbida, leggibile, coerente con lo stile artistico (angoli arrotondati, icone illustrate).
- HUD minimo durante l'esplorazione: ora/giorno, mini-indicatore missione attiva, prompt di interazione contestuale.
- Tutti i menu navigabili **sia con mouse sia con controller**.
- Testo grande e leggibile; opzioni di accessibilità (dimensione testo, sottotitoli, daltonismo).

### 12.2 Controlli
Il gioco esce su PC, console e mobile: ogni azione deve funzionare con **tastiera/mouse, controller e touch**.

| Azione | Tastiera/mouse | Controller | Touch (mobile) |
|--------|----------------|-----------|----------------|
| Muoversi | WASD | Stick sinistro | Joystick virtuale a sinistra |
| Telecamera | Mouse | Stick destro | Trascinare a destra dello schermo |
| Correre | Shift (tenere) | R2 / clic stick sinistro | Joystick spinto fino al bordo |
| Saltare (piccolo salto) | Spazio | X / □ | Pulsante in basso a destra |
| Zoom telecamera | Rotella | L1 / R1 | — |
| Interagire | E | A / ✕ | Pulsante contestuale grande / tocco sull'animale |
| Annulla/indietro | Esc | B / ◯ | Pulsante indietro |
| Diario | J / Tab | Menu/Start | Icona in alto |
| Scegli strumento/cibo | Rotella / 1–9 | Croce direzionale | Barra rapida a scorrimento |
| Costruzione: sposta/ruota | Mouse + R | Stick + dorsali | Trascina + pulsante ruota |

- Su mobile l'interfaccia usa pulsanti grandi, si adatta a schermi piccoli e a notch/aree sicure.

### 12.3 Telecamera (D-02)
Terza persona libera con orbit, distanza regolabile, collisione con l'ambiente, zoom ravvicinato durante le interazioni con gli animali, vista dall'alto in modalità costruzione.

---

## 13. Audio
- Musica diversa per zona e fascia oraria, morbida e acustica.
- Suoni ambientali per bioma (onde, uccelli, vento, grilli di notte).
- Versi animali realistici ma "puliti".
- Voci: borbottii espressivi + testo, nessun doppiaggio (D-26). Audio generato dal team o da librerie CC0 (D-27).

---

## 14. Salvataggio
- Salvataggio automatico (cambio zona, dormire, ogni N minuti) + salvataggio manuale in casa.
- 3 slot di salvataggio (D-31).
- Il salvataggio contiene: aspetto di Gioia, posizione, ora/giorno, inventario, casa, giardino, animali adottati, missioni, diario, impostazioni.

---

## 15. Localizzazione
- Italiano e inglese al lancio (D-28), con sistema di localizzazione predisposto fin dall'inizio (nessun testo scritto direttamente nel codice).

---

## 16. Registro delle modifiche
| Versione | Data | Modifica |
|----------|------|----------|
| 0.1 | 2026-11-22 | Prima stesura dal brief del committente |
| 0.2 | 2026-11-22 | Decise: piattaforme PC + console + mobile (D-01), 3 compagni (D-04), selvatici adottabili ma più difficili (D-16), malattia e morte in 3 giorni per trascuratezza (D-17). Aggiunti § 6.7 e controlli touch |
| 1.0 | 2026-11-22 | Tutte le decisioni prese dal team su delega del committente; motore cambiato da Unity a Godot 4.7 (D-30) |
| 1.1 | 2026-11-22 | D-15 precisata: sblocco delle zone guidato dalla storia, isola esplorabile liberamente |
| 1.2 | 2026-11-22 | Realizzate tutte le fasi: 21 specie, produzione degli animali da fattoria, abilità dei compagni, meteo, modalità foto, storia in 18 capitoli; qualità grafica selezionabile |
