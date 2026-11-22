# Istruzioni per Claude Code — Animal World

Progetto: videogioco 3D Unity/C# "Animal World", protagonista Gioia. Documentazione in `docs/`. Lingua di lavoro: italiano.

## Regole del committente (vincolanti)
- Non prendere decisioni importanti senza confrontarsi: aggiungerle a `docs/DECISIONI_APERTE.md` e chiedere.
- Non eliminare funzionalità approvate; non modificare parti funzionanti senza motivo.
- Non lasciare sistemi incompleti presentandoli come funzionanti: dichiarare sempre cosa è stato verificato e cosa no.
- Quando si trova un bug: individuare la causa e correggerla.
- Procedere per fasi (`docs/PIANO_SVILUPPO.md`); chiudere una fase solo a criteri verificati.
- A ogni sessione aggiornare `docs/STATO_LAVORI.md` e, se il design cambia, `docs/GDD.md` (registro modifiche).

## Vincoli di design
- Animali reali e adulti (niente cuccioli, niente creature fantastiche), non si cavalcano. Niente combattimento.
- Stile ispirato allo spirito Nintendo ma con identità originale: nessun contenuto copiato da altri giochi.

## Vincoli tecnici
- Seguire `docs/ARCHITETTURA.md` (assembly separati, logica pura in `AnimalWorld.Core`, dati in ScriptableObject, ID stabili nei salvataggi).
- Niente allocazioni nel gameplay a regime, niente `Find*` nel gameplay, testi solo tramite localizzazione.
- L'editor Unity non è disponibile in questo ambiente: ogni consegna deve includere istruzioni di verifica manuale.
