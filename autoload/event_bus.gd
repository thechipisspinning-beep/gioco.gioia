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
## Il giocatore ha scelto "Adotta": la UI chiede il nome. `agent` è l'AnimalAgent.
@warning_ignore("unused_signal")
signal adoption_requested(agent: Node)
## Un animale è stato adottato.
@warning_ignore("unused_signal")
signal animal_adopted(animal_id: StringName, species_id: StringName)
## Sono cambiati i compagni che seguono Gioia (o dove vivono gli animali adottati).
@warning_ignore("unused_signal")
signal companions_changed
## È cambiata la salute di un animale (ammalato, guarito, morto).
@warning_ignore("unused_signal")
signal animal_health_changed(animal_id: StringName, health: int)
## Gioia esegue un gesto verso un animale (&"pet", &"feed", &"throw", &"brush").
@warning_ignore("unused_signal")
signal player_gesture(gesture: StringName)
## Apri la schermata di personalizzazione di Gioia (es. dallo specchio).
@warning_ignore("unused_signal")
signal customization_requested
