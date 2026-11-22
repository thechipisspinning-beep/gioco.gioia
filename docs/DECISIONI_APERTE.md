# Animal World — Decisioni aperte

> Elenco delle decisioni che il team **non prende da solo**. Per ognuna c'è una proposta e l'impatto.
> Quando una decisione viene presa, si sposta in fondo nella tabella "Decise" e si aggiorna il GDD.
>
> **Priorità:** 🔴 blocca le prime fasi · 🟠 serve entro la fase indicata · 🟢 si può rimandare

## Da decidere

| ID | Pri. | Domanda | Proposta del team | Perché conta | Serve entro |
|----|------|---------|-------------------|--------------|-------------|
| D-01 | 🔴 | **Piattaforma** di destinazione (PC, Mac, console, mobile)? | PC (Windows) come piattaforma principale, con supporto controller; console in seguito | Determina controlli, budget prestazioni, UI, salvataggi | Fase 2 |
| D-29 | 🔴 | **Chi produce gli asset 3D** (modelli, rig, animazioni) e con quale budget? Artisti interni/esterni, asset store, generazione AI, placeholder? | Prototipo con forme semplici (placeholder); in parallelo definire la pipeline artistica definitiva | È il costo maggiore del progetto: ogni specie animale richiede modello + rig + animazioni. Claude può scrivere codice e shader, **non** può modellare personaggi 3D di qualità | Fase 4 |
| D-30 | 🔴 | Versione di **Unity** e licenza disponibile? | Unity 6 LTS, URP | Il codice va scritto per la versione giusta | Fase 2 |
| D-02 | 🔴 | **Telecamera:** terza persona libera (orbit) o semi-fissa dall'alto? | Terza persona libera con orbit e zoom | Cambia controller, level design e leggibilità | Fase 3 |
| D-03 | 🟠 | **Pubblico/età** di riferimento? | Tutti, attenzione a 8+ | Influenza testi, complessità UI, rating | Fase 5 |
| D-04 | 🟠 | Quanti **compagni al seguito** contemporaneamente? | Massimo 3 (adozioni illimitate) | Prestazioni e leggibilità durante l'esplorazione | Fase 7 |
| D-05 | 🟠 | **Dimensione dell'isola** per la v1.0? | ~2 × 2 km, espandibile | Determina tempi di produzione dei contenuti | Fase 5 |
| D-06 | 🟠 | **Durata del giorno** di gioco? | 24 minuti reali, possibilità di dormire | Ritmo di crescita piante, bisogni, routine animali | Fase 5 |
| D-07 | 🟢 | **Meteo e stagioni**? | Meteo semplice (sole, nuvole, pioggia) in v1.0; stagioni in espansione | Lavoro grafico notevole per le stagioni | Fase 12 |
| D-08 | 🟠 | **Stile di shading:** toon/cel o PBR stilizzato? Terrain Unity o mesh modellate? | Toon morbido + palette texture; Terrain a tile | Definisce tutta la pipeline artistica | Fase 5 |
| D-09 | 🟠 | **Lista specie** della v1.0? | 20–25 specie (lista nel GDD § 6.6), con primo animale cane o gatto | Ogni specie ha un costo alto | Fase 6 |
| D-10 | 🟢 | Personalizzazione di **corporatura/altezza** di Gioia? | Solo 2–3 preset di altezza, nessuna corporatura | Ogni variante moltiplica i vestiti da adattare | Fase 4 |
| D-11 | 🟠 | Ci sono **abitanti umani (NPC)** nel villaggio? Quanti, con dialoghi? | Sì, 6–10 NPC con dialoghi semplici e missioni | Molte missioni e il "villaggio vivo" dipendono da loro | Fase 9 |
| D-12 | 🟠 | **Premessa narrativa:** perché Gioia è sull'isola? C'è una storia principale? | Gioia arriva per prendersi cura di un vecchio rifugio per animali sull'isola e farlo rinascere | Dà senso alle missioni principali e alla progressione | Fase 9 |
| D-13 | 🟢 | Gioia può **saltare** / arrampicarsi / nuotare? | Salto piccolo sì; nuoto no (l'acqua profonda blocca dolcemente) | Impatta level design e animazioni | Fase 3 |
| D-14 | 🟠 | Gli **interni** sono scene separate (breve transizione) o integrati senza caricamento? | Scene separate | Molto più semplice e performante | Fase 8 |
| D-15 | 🟠 | Le zone si **sbloccano progressivamente** o sono tutte aperte subito? | Sblocco leggero tramite missioni principali | Guida il giocatore e dà ritmo | Fase 9 |
| D-16 | 🟠 | **Tutti gli animali sono adottabili**, anche i selvatici (cervo, aquila, foca)? | Domestici e fattoria adottabili; selvatici diventano "amici" che vengono a trovarti in giardino | Credibilità, spazi in casa, messaggio sul rispetto della fauna | Fase 7 |
| D-17 | 🟠 | Cosa succede se un animale viene **trascurato**? Esiste il veterinario/malattie? | Nessuna malattia né fuga: l'animale è solo meno felice e meno "attivo" finché non riceve cure | Coerenza col tono rilassante | Fase 7 |
| D-18 | 🟢 | I compagni hanno **abilità utili** (cane trova oggetti, ecc.)? | Sì, una piccola abilità per specie | Rende interessante scegliere chi portare | Fase 12 |
| D-19 | 🟠 | **Economia:** esiste una valuta? Negozi? | Una valuta ("monete") + materiali; negozi al villaggio | Ricompense, sblocchi, arredamento | Fase 8 |
| D-20 | 🟠 | **Arredamento** su griglia o libero? | Griglia con rotazione a 90°, opzione mezza cella per decorazioni | Facilità d'uso con controller | Fase 8 |
| D-21 | 🟢 | **Esterno della casa** personalizzabile? Posizione scelta dal giocatore? | Esterno personalizzabile (colori, tetto, recinzioni), posizione fissa | La posizione libera complica molto il level design | Fase 8 |
| D-22 | 🟠 | Gioia ha **bisogni propri** (fame, energia)? | No, i cibi per Gioia danno solo piccoli bonus temporanei | Evita stress e microgestione | Fase 11 |
| D-23 | 🟢 | Cucina con **mini-gioco** o istantanea? | Mini-gioco leggero e saltabile | Divertimento vs ripetitività | Fase 11 |
| D-24 | 🟢 | Gli animali della fattoria **producono** risorse (uova, latte, lana)? | Sì, come ingredienti e materiali | Collega animali, cucina e artigianato | Fase 11 |
| D-25 | 🟢 | **Modalità foto**? | Sì, semplice, collegata al diario | Molto apprezzata nel genere, costo contenuto | Fase 12 |
| D-26 | 🟢 | Voci dei personaggi: doppiaggio, borbottii o solo testo? | Borbottii/suoni espressivi + testo | Costo e localizzazione | Fase 12 |
| D-27 | 🟢 | Fonte di **musica e audio**? | Da definire (compositore, librerie con licenza) | Licenze e budget | Fase 12 |
| D-28 | 🟠 | **Lingue** al lancio? | Italiano + inglese | Sistema di localizzazione da predisporre subito | Fase 2 |
| D-31 | 🟢 | **Slot di salvataggio** e salvataggio manuale? | 3 slot, autosave + salvataggio a letto | Struttura dei file di salvataggio | Fase 10 |
| D-32 | 🟢 | **Integrazione continua** (GameCI su GitHub Actions) per compilare ed eseguire i test a ogni commit? | Sì, se la licenza Unity lo consente | Permette a Claude di verificare automaticamente che il codice compili | Fase 2 |
| D-33 | 🟢 | **Modello di distribuzione** (gioco a pagamento, gratuito, demo)? | Gioco completo a pagamento, nessuna microtransazione | Influenza design di progressione ed economia | Prima del lancio |

## Decise

| ID | Decisione | Data |
|----|-----------|------|
| — | Motore Unity, linguaggio C#, single-player, non Roblox | Brief iniziale |
| — | Un'unica isola enorme con più zone, ciclo giorno/notte con sole, luna e stelle | Brief iniziale |
| — | Solo animali reali e adulti; nessuna creatura fantastica; non si cavalcano | Brief iniziale |
| — | Adozione con nome, animali a casa, scelta di chi segue Gioia, nessun limite rigido di adozioni | Brief iniziale |
| — | Protagonista Gioia completamente personalizzabile; cammina e corre | Brief iniziale |
| — | Casa espandibile, cucina (per Gioia e animali), giardinaggio, missioni, diario | Brief iniziale |
