# Animal World — Decisioni

> Il 2026-11-22 il committente ha delegato al team tutte le decisioni aperte ("decidi tutto tu").
> Le decisioni qui sotto sono quindi **prese**; restano modificabili su richiesta del committente.
> Le nuove domande che emergeranno durante lo sviluppo vanno aggiunte in "Ancora aperte".

## Ancora aperte (dipendono da fattori esterni)

| ID | Domanda | Stato |
|----|---------|-------|
| D-41 | **Pubblicazione su console** (Switch 2, PS5, Xbox Series): con Godot serve una società di porting (es. W4 Games, Lone Wolf Technology) e l'iscrizione ai programmi sviluppatori dei produttori, di norma riservata a società registrate | Rimandata a dopo l'uscita su PC e mobile. Il codice resta compatibile con controller e prestazioni console fin da subito |
| D-42 | **Build iOS**: richiede un Mac con Xcode e un account Apple Developer (99 $/anno) | Rimandata alla Fase 13. Android, PC e web si possono generare da qui |
| D-43 | **Store e distribuzione** (Steam, itch.io, Google Play, App Store) | Da definire prima del lancio |

## Decise

| ID | Decisione | Motivazione | Data |
|----|-----------|-------------|------|
| — | Single-player, non Roblox, isola unica con zone, giorno/notte con sole, luna e stelle | Brief iniziale | Brief |
| — | Animali reali e adulti, nessuna creatura fantastica, non si cavalcano | Brief iniziale | Brief |
| — | Adozione con nome, animali a casa, scelta di chi segue Gioia, nessun limite rigido di adozioni | Brief iniziale | Brief |
| — | Gioia personalizzabile, cammina e corre; casa espandibile, cucina, giardino, missioni, diario | Brief iniziale | Brief |
| D-01 | Piattaforme: **PC, console e mobile** (+ versione web per i test) | Committente | 2026-11-22 |
| D-04 | Massimo **3 compagni** al seguito | Committente | 2026-11-22 |
| D-16 | **Anche i selvatici sono adottabili**, ma più difficilmente | Committente | 2026-11-22 |
| D-17 | Animale **trascurato si ammala**, senza cure **muore in 3 giorni** | Committente | 2026-11-22 |
| D-30 | Motore **Godot 4.7** (sostituisce Unity), linguaggio **GDScript** con tipizzazione statica | Il committente non ha Unity; Godot è gratuito, senza account, e il team può eseguirlo, testarlo e generare build da solo. GDScript (non C#) perché C# in Godot non esporta per il web | 2026-11-22 |
| D-29 | **Asset 3D prodotti dal team**: modelli stilizzati low-poly generati via codice/script (forme morbide, colori da palette), animazioni procedurali e via script. Sostituibili in futuro da asset di artisti professionisti senza cambiare il codice | Nessun budget/artista disponibile; lo stile "giocattolo" low-poly si presta alla generazione procedurale e resta coerente | 2026-11-22 |
| D-02 | Telecamera **terza persona libera** (orbita, zoom, collisioni), più ravvicinata nelle interazioni, dall'alto in costruzione | Standard del genere, migliore per esplorare | 2026-11-22 |
| D-03 | Pubblico: **tutti, dai 7 anni**. Morte degli animali mai cruda | Compatibile con PEGI 7 / ESRB E | 2026-11-22 |
| D-05 | Isola di **circa 2 × 2 km** nella v1.0 | Grande ma realizzabile | 2026-11-22 |
| D-06 | **1 giorno di gioco = 24 minuti reali**; si può dormire per passare alla mattina | Ritmo buono per routine e crescita | 2026-11-22 |
| D-07 | **Meteo semplice** (sereno, nuvoloso, pioggia; neve solo in vetta) in v1.0; **stagioni** in espansione successiva | Costo grafico delle stagioni molto alto | 2026-11-22 |
| D-08 | Shading **toon morbido** a bande con rim light + **palette texture** condivisa; terreno a mesh generate a blocchi (chunk) | Stile coerente, poche texture, ottimo su mobile | 2026-11-22 |
| D-09 | Lista specie v1.0 come GDD § 6.6 (~25 specie). **Primo animale: cane**, seconda specie: **volpe** (selvatica) | Il cane è l'animale più riconoscibile per un primo incontro | 2026-11-22 |
| D-10 | Gioia: **3 preset di altezza**, nessuna variante di corporatura | Evita di moltiplicare i vestiti | 2026-11-22 |
| D-11 | **8 abitanti** del villaggio con dialoghi semplici e missioni | Villaggio vivo, costo contenuto | 2026-11-22 |
| D-12 | Premessa: Gioia eredita dalla nonna un **vecchio rifugio per animali** sull'isola, ormai in rovina, e lo fa rinascere | Dà senso a casa, adozioni e missioni principali | 2026-11-22 |
| D-13 | **Salto piccolo** sì; **niente nuoto** (l'acqua profonda respinge dolcemente) | Esplorazione più varia senza animazioni costose | 2026-11-22 |
| D-14 | **Interni in scene separate** con breve dissolvenza | Prestazioni e semplicità | 2026-11-22 |
| D-15 | Zone **sbloccate progressivamente** dalle missioni principali (ponte, sentiero, funivia) | Ritmo e guida | 2026-11-22 |
| D-18 | Ogni specie compagna ha **una piccola abilità** (es. cane trova oggetti sepolti, gatto segnala animali nascosti) | Rende la scelta dei compagni interessante | 2026-11-22 |
| D-19 | Una valuta (**monete**) + materiali; negozi al villaggio | Semplice | 2026-11-22 |
| D-20 | Arredamento su **griglia** con rotazione a 90° (mezza cella per piccole decorazioni) | Facile con mouse, controller e touch | 2026-11-22 |
| D-21 | **Esterno casa personalizzabile** (colori, tetto, recinzioni), **posizione fissa** | Level design gestibile | 2026-11-22 |
| D-22 | Gioia **non ha bisogni** propri; i suoi cibi danno piccoli bonus temporanei | Niente microgestione | 2026-11-22 |
| D-23 | Cucina con **mini-gioco leggero e saltabile** | Divertente ma non ripetitivo | 2026-11-22 |
| D-24 | Gli animali da fattoria **producono** uova, latte, lana, miele | Collega animali, cucina e artigianato | 2026-11-22 |
| D-25 | **Modalità foto** semplice collegata al diario | Molto apprezzata nel genere | 2026-11-22 |
| D-26 | **Borbottii espressivi** + testo, nessun doppiaggio | Costo e localizzazione | 2026-11-22 |
| D-27 | Audio: effetti e musica **generati/sintetizzati dal team** o da librerie CC0; musica definitiva rimpiazzabile | Nessun budget audio | 2026-11-22 |
| D-28 | Lingue: **italiano e inglese**, sistema di traduzione attivo da subito | | 2026-11-22 |
| D-31 | **3 slot** di salvataggio, salvataggio automatico + salvataggio a letto | | 2026-11-22 |
| D-32 | **GitHub Actions**: test automatici e build web a ogni push | Verifica continua | 2026-11-22 |
| D-33 | Gioco **completo a pagamento**, nessuna microtransazione | Coerente con un gioco rilassante per famiglie | 2026-11-22 |
| D-34 | Console **dopo** il lancio PC/mobile (vedi D-41) | Servono società e accordi esterni | 2026-11-22 |
| D-35 | I 3 giorni della malattia sono **giorni di gioco** (~72 minuti di gioco); il tempo **non scorre a gioco chiuso** | Il giocatore non trova mai animali morti dopo una pausa | 2026-11-22 |
| D-36 | Cura: **ambulatorio veterinario** al villaggio + **medicine** preparabili in cucina con erbe del giardino | Collega malattia a cucina e giardino | 2026-11-22 |
| D-37 | Aiuti per molti animali: **mangiatoie/abbeveratoi automatici** costruibili (durano 2–3 giorni) e un **custode** sbloccabile | Rende compatibili adozioni illimitate e malattia | 2026-11-22 |
| D-38 | **Opzione "Modalità serena"** a inizio partita: gli animali si ammalano ma non muoiono. **Predefinita: morte attiva** (come deciso in D-17) | Accessibilità per i più piccoli senza togliere la regola scelta | 2026-11-22 |
| D-39 | Mobile: **Android e iOS**, telefoni e tablet; minimo telefoni di fascia media degli ultimi 5 anni | | 2026-11-22 |
| D-40 | Solo gli **animali adottati** possono ammalarsi | Responsabilità solo per chi si è scelto | 2026-11-22 |
