# Animal World — Game Design Document

> **Versione:** 0.1 (bozza iniziale)
> **Stato:** in revisione con il committente
> **Ultimo aggiornamento:** 2026-11-22
>
> Questo documento è la fonte di verità per il design del gioco. Ogni decisione approvata viene registrata qui; quelle ancora aperte sono in [`DECISIONI_APERTE.md`](DECISIONI_APERTE.md).
> Le voci marcate **[PROPOSTA]** sono suggerimenti del team, non ancora approvati.

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
| 3 | **Accoglienza e relax** | Nessuna punizione dura, nessuna fretta, nessun combattimento. Il giocatore gioca al proprio ritmo. |
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
| Motore | Unity (C#) |
| Piattaforma | **Da decidere** (vedi D-01) |
| Pubblico | **Da decidere** (vedi D-03) — [PROPOSTA] tutti, con particolare attenzione a 8+ anni |
| Durata obiettivo | Decine di ore di gioco, con contenuto aperto e senza "fine" obbligata |

---

## 3. Direzione artistica

### 3.1 Linee guida
- Stile **stilizzato e morbido**, ispirato *nello spirito* ai giochi Nintendo: forme arrotondate, proporzioni leggermente esagerate, colori saturi ma armoniosi, illuminazione calda.
- **Identità visiva originale**: nessun personaggio, modello, texture, musica o elemento riconoscibile di altri giochi.
- Animali **realistici nell'anatomia e nel comportamento** (sono animali veri), ma **stilizzati nella forma** e molto **espressivi** (occhi, orecchie, coda, postura).

### 3.2 [PROPOSTA] Regole tecniche dello stile
- **Shading:** toon/cel morbido a 2–3 bande con rim light leggera, oppure PBR semplificato con palette controllata (decisione D-08).
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
Gioia è il personaggio controllato dal giocatore. Arriva sull'isola (o vi abita già — vedi D-12, *premessa narrativa*) e la sua storia è legata alla scoperta e alla cura degli animali.

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
- **Da decidere:** opzioni di corporatura/altezza (D-10).

### 4.3 Movimento e animazioni
| Azione | Note |
|--------|------|
| Idle | Con varianti "idle fidget" dopo alcuni secondi di inattività |
| Camminata | Velocità analogica (stick) o tasto |
| Corsa | Tasto/stick premuto a fondo. [PROPOSTA] Nessuna stamina, per restare rilassante |
| Salto | **Da decidere** (D-13) — utile per esplorazione verticale ma non indispensabile |
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
- **[PROPOSTA] Dimensione:** circa 2 × 2 km per la versione 1.0 (equivalente a 20–30 minuti per attraversarla a piedi correndo). È già molto grande per un gioco di questo genere; si può espandere in seguito. Decisione D-05.
- Gli interni (casa, negozi) sono **[PROPOSTA]** scene separate con breve transizione, per prestazioni migliori. Decisione D-14.

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
- Le zone si **sbloccano progressivamente** (es. un ponte da riparare, un sentiero da liberare) — **[PROPOSTA]**, decisione D-15.

### 5.3 Ciclo giorno/notte
- Sole e luna con traiettorie, cielo con stelle di notte, transizioni di colore (alba, giorno, tramonto, notte).
- **Gli animali reagiscono all'ora**: specie diurne/notturne (es. gufi e ricci di notte), routine (dormire, mangiare).
- **[PROPOSTA] Durata:** 1 giorno di gioco = 24 minuti reali (1 ora = 1 minuto). Decisione D-06.
- Possibilità di dormire nel letto per passare alla mattina successiva.
- **Da decidere:** meteo (pioggia, vento, neve in montagna) e stagioni (D-07).

### 5.4 Senso di mondo vivo
- Animali selvatici che vagano, si incontrano, reagiscono a Gioia.
- Abitanti del villaggio (NPC) — **da decidere** se umani, quanti e con che ruolo (D-11).
- Elementi ambientali animati: erba e alberi mossi dal vento, farfalle, foglie, acqua.
- Eventi casuali leggeri (es. "un cervo si è avvicinato al ruscello", "stormo di anatre in volo al tramonto").

---

## 6. Gli animali

### 6.1 Principi
- Specie **reali e comuni**, domestiche e selvatiche.
- **Solo adulti.**
- Ogni specie ha comportamento credibile e personalità individuale.
- Gli animali **non muoiono**, non soffrono in modo esplicito e non ci sono punizioni pesanti (pilastro 3). Decisione su conseguenze della trascuratezza: D-17.

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

- **Da decidere:** tutti gli animali sono adottabili o solo alcuni? (es. animali selvatici come cervi o aquile potrebbero essere solo "amici" che vengono a trovarti, mentre i domestici si adottano — D-16).

### 6.4 Animali adottati
- Ogni animale adottato ha: **nome**, specie, variante colore, personalità, livello di amicizia, stato dei bisogni, data di adozione, preferenze scoperte.
- **[PROPOSTA] Bisogni semplici:** Fame, Felicità, Pulizia (massimo 3, per non trasformare il gioco in una gestione stressante).
- Gli animali **vivono a casa** (interno, giardino, spazi dedicati).
- Il giocatore sceglie **quali animali seguono Gioia** durante l'esplorazione; gli altri restano a casa.
- **Numero di adozioni:** nessun limite rigido di gameplay. Tecnicamente il sistema simula in modo completo solo gli animali vicini al giocatore (vedi Architettura § Animali).
- **[PROPOSTA] Compagni al seguito:** massimo 3 contemporaneamente (decisione D-04). È una scelta di leggibilità e prestazioni, non di adozione.
- I compagni al seguito possono **aiutare** (es. un cane trova oggetti nascosti, un gatto segnala animali vicini) — **[PROPOSTA]**, D-18.

### 6.5 Personalità [PROPOSTA]
Ogni animale riceve 1–2 tratti casuali che modificano animazioni e reazioni: *Giocherellone, Dormiglione, Goloso, Timido, Curioso, Affettuoso, Indipendente*.

### 6.6 Prima lista specie [PROPOSTA per la v1.0 — circa 20–25 specie]
- **Domestici:** cane (più razze/varianti), gatto, coniglio, criceto, pappagallino.
- **Fattoria:** mucca, pecora, capra, maiale, gallina, cavallo, asino, anatra.
- **Selvatici:** volpe, cervo, scoiattolo, riccio, gufo, tartaruga, rana, lontra, marmotta, stambecco, gabbiano, foca.
- Decisione definitiva D-09. Ogni specie è un costo significativo (modello + rig + animazioni): conviene iniziare con poche specie fatte molto bene.

---

## 7. Attività principali

### 7.1 Esplorazione
- Movimento libero, scoperta di zone, punti panoramici, oggetti raccoglibili, segreti.
- Mappa dell'isola che si completa man mano (fog of war leggero) — **[PROPOSTA]**.
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
| Visita dal veterinario | **Da decidere** (D-17) |

### 7.4 Costruzione e personalizzazione della casa
Vedi § 8.

### 7.5 Cucina
Vedi § 9.

### 7.6 Giardinaggio
- Zappare, piantare semi, innaffiare, raccogliere.
- Piante: fiori (decorazione, missioni, felicità animali), ortaggi e frutta (ingredienti di cucina), erbe (ricette per animali).
- Le piante crescono nel tempo di gioco (fasi visive).
- **[PROPOSTA]** Nessuna pianta "muore": se non innaffiata, semplicemente non cresce.
- Alcuni animali interagiscono col giardino (galline, api…).

### 7.7 Missioni e obiettivi
Vedi § 10.

### 7.8 Raccolta di oggetti e ricompense
- Raccoglibili: conchiglie, sassi colorati, fiori, piume, funghi, frutti, legna…
- Usati per: ricette, costruzione/arredamento, missioni, scambio con NPC.
- **Valuta di gioco:** **da decidere** (D-19). [PROPOSTA] una sola valuta semplice (es. "monete") + materiali.

---

## 8. Casa e personalizzazione

- La casa parte **piccola** (1 stanza) e si **espande** per fasi: nuove stanze, piano superiore, giardino più grande, spazi per animali.
- **Stanze previste:** soggiorno, camera da letto, cucina, bagno, stanza degli animali, + stanze extra sbloccabili.
- **Spazi animali:** cucce, cuscini, tiragraffi, gabbie aperte/voliere, recinto, stalla, stagno, pollaio.
- **Arredamento:** posizionamento su **griglia** con rotazione a 90° — **[PROPOSTA]** (semplice, chiaro, compatibile con mouse e controller). Decisione D-20.
- **Personalizzazione:** carta da parati, pavimenti, colori, mobili, decorazioni, luci.
- **Sblocchi:** mobili e decorazioni da missioni, negozi, scoperte, ricette.
- Modalità di costruzione con telecamera dall'alto dedicata.
- **Da decidere:** esterno della casa personalizzabile (tetto, colore pareti, recinzioni) e se si può scegliere dove costruirla (D-21).

---

## 9. Cucina

- Si cucina in casa (fornello/bancone) — **[PROPOSTA]** anche fuochi da campo in alcune zone.
- **Due famiglie di ricette:**
  - **Per Gioia:** [PROPOSTA] effetto cosmetico o di comodità (es. corsa più veloce temporanea, "buonumore" che fa avvicinare gli animali più facilmente). Decisione D-22 — Gioia ha bisogno di mangiare? [PROPOSTA] No, nessuna fame obbligatoria per Gioia.
  - **Per gli animali:** cibi specifici per specie, aumentano fame/felicità/amicizia; alcuni sono necessari per conquistare animali timidi.
- **Ricette sbloccabili:** da missioni, NPC, libri trovati nel mondo, sperimentazione.
- **[PROPOSTA] Interazione:** scelta ingredienti + mini-gioco leggero e facoltativo (es. mescolare a tempo), saltabile. Decisione D-23.
- Ingredienti: dal giardino, raccolti nel mondo, comprati, prodotti dagli animali della fattoria (uova, latte, lana per artigianato?) — vedi D-24.

---

## 10. Missioni e progressione

### 10.1 Tipi di missioni
| Tipo | Descrizione | Esempi |
|------|-------------|--------|
| **Principali** | Guidano la progressione e sbloccano zone/funzioni | "Ripara il ponte verso la foresta", "Costruisci la stanza degli animali" |
| **Secondarie** | Richieste di NPC, obiettivi di zona | "Trova il gatto della fornaia", "Pianta 5 girasoli" |
| **Giornaliere [PROPOSTA]** | Piccoli obiettivi rinnovati ogni giorno di gioco | "Accarezza 3 animali", "Cucina un piatto" |
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

### 10.4 Curva di progressione [PROPOSTA]
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
| **Foto [PROPOSTA]** | Galleria della modalità foto (D-25) |

- Le **curiosità reali** sugli animali danno anche un valore educativo leggero.

---

## 12. Interfaccia e controlli

### 12.1 Principi UI
- Pulita, morbida, leggibile, coerente con lo stile artistico (angoli arrotondati, icone illustrate).
- HUD minimo durante l'esplorazione: ora/giorno, mini-indicatore missione attiva, prompt di interazione contestuale.
- Tutti i menu navigabili **sia con mouse sia con controller**.
- Testo grande e leggibile; opzioni di accessibilità (dimensione testo, sottotitoli, daltonismo).

### 12.2 Controlli [PROPOSTA — da confermare con la piattaforma]
| Azione | Tastiera/mouse | Controller |
|--------|----------------|-----------|
| Muoversi | WASD | Stick sinistro |
| Telecamera | Mouse | Stick destro |
| Correre | Shift (tenere) | Stick a fondo / grilletto |
| Interagire | E | A / ✕ |
| Annulla/indietro | Esc | B / ◯ |
| Diario | J / Tab | Menu/Start |
| Scegli strumento/cibo | Rotella / 1–9 | Croce direzionale |

### 12.3 Telecamera [PROPOSTA]
Terza persona libera con orbit, distanza regolabile, collisione con l'ambiente, zoom ravvicinato durante le interazioni con gli animali. Decisione D-02.

---

## 13. Audio
- Musica diversa per zona e fascia oraria, morbida e acustica.
- Suoni ambientali per bioma (onde, uccelli, vento, grilli di notte).
- Versi animali realistici ma "puliti".
- **Da decidere:** voci/borbottii per NPC e Gioia (D-26), fonte degli asset audio (D-27).

---

## 14. Salvataggio
- **[PROPOSTA]** Salvataggio automatico (cambio zona, dormire, ogni N minuti) + salvataggio manuale in casa.
- **[PROPOSTA]** 3 slot di salvataggio.
- Il salvataggio contiene: aspetto di Gioia, posizione, ora/giorno, inventario, casa, giardino, animali adottati, missioni, diario, impostazioni.

---

## 15. Localizzazione
- **Da decidere:** lingue al lancio (D-28). [PROPOSTA] Italiano e inglese, con sistema di localizzazione predisposto fin dall'inizio (nessun testo scritto direttamente nel codice).

---

## 16. Registro delle modifiche
| Versione | Data | Modifica |
|----------|------|----------|
| 0.1 | 2026-11-22 | Prima stesura dal brief del committente |
