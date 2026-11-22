extends Node
## Bus di eventi globale del gameplay.
##
## I sistemi emettono qui gli eventi significativi; missioni, diario, notifiche
## e statistiche li ascoltano senza conoscere chi li ha generati.
## Gli ID passati sono sempre ID stringa stabili dei contenuti (mai riferimenti a nodi).
## Nuovi segnali vengono aggiunti man mano che i sistemi vengono realizzati.

## Il giocatore è entrato in una zona dell'isola.
@warning_ignore("unused_signal")
signal zone_entered(zone_id: StringName)
## Il giocatore ha incontrato (visto da vicino) un animale per la prima volta nella sessione.
@warning_ignore("unused_signal")
signal animal_met(species_id: StringName, animal_id: StringName)
## Gioia ha interagito con un animale (azione = TrustModel.Action).
@warning_ignore("unused_signal")
signal animal_interacted(animal_id: StringName, species_id: StringName, action: int, friendship_gain: float)
## L'amicizia di un animale è cambiata.
@warning_ignore("unused_signal")
signal friendship_changed(animal_id: StringName, friendship: float)
## Messaggio breve da mostrare a schermo (già tradotto).
@warning_ignore("unused_signal")
signal notification_requested(text: String)
