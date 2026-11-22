# Istruzioni per Claude Code — Animal World

Progetto: videogioco 3D **Godot 4.7 / GDScript** "Animal World", protagonista Gioia. Documentazione in `docs/`. Lingua di lavoro: italiano.
Il committente ha delegato al team tutte le decisioni (2026-11-22) e non usa l'editor: lo sviluppo, le verifiche e le build sono a carico di Claude.

## Regole del committente (vincolanti)
- Le decisioni importanti si registrano in `docs/DECISIONI_APERTE.md` con la motivazione; cambiare una decisione del committente (D-01, D-04, D-16, D-17) richiede di chiedere.
- Non eliminare funzionalità approvate; non modificare parti funzionanti senza motivo.
- Non lasciare sistemi incompleti presentandoli come funzionanti: dichiarare sempre cosa è stato verificato e cosa no.
- Quando si trova un bug: individuare la causa e correggerla.
- Procedere per fasi (`docs/PIANO_SVILUPPO.md`); chiudere una fase solo a criteri verificati.
- A ogni sessione aggiornare `docs/STATO_LAVORI.md` e, se il design cambia, `docs/GDD.md` (registro modifiche).

## Vincoli di design
- Animali reali e adulti (niente cuccioli, niente creature fantastiche), non si cavalcano. Niente combattimento.
- Stile ispirato allo spirito Nintendo ma con identità originale: nessun contenuto copiato da altri giochi.

## Vincoli tecnici
- Seguire `docs/ARCHITETTURA.md`: logica pura in `core/` (testata), dati in Resource, ID stringa stabili nei salvataggi, GDScript tipizzato.
- Colori solo da `art/palette.gd`, materiali da `ToonMaterials`, energia delle luci tramite `Lighting` (compensa il renderer web).
- Testi solo tramite `localization/strings.csv`.

## Comandi
- Godot: `godot` (4.7.2). Se manca, scaricarlo da GitHub Releases (vedi `.github/workflows/ci.yml`).
- Import: `godot --headless --path . --import`
- Test: `godot --headless --path . -s res://tests/run_tests.gd` (`-- --filter=nome` per filtrare)
- Mappa input (dopo modifiche a `tools/setup_input_map.gd`): `godot --headless --path . -s res://tools/setup_input_map.gd`
- Screenshot con rendering software: `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan -- --lang=it --shot=2:/percorso.png --quit-at=2.3` (opzioni in `autoload/dev_tools.gd`; `--rendering-driver opengl3` per vedere come appare sul web)
- Build web: `godot --headless --path . --export-release "Web" build/web/index.html`
