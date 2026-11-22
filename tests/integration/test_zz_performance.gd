extends TestCase
## Prestazioni (Fase 13): l'isola vera con Gioia alla fattoria (la zona più
## affollata) e poi in corsa attraverso l'isola (caricamento dei blocchi).
## Misura il tempo reale per frame della parte CPU (logica + fisica): il
## rendering non è misurabile qui (nessuna GPU) e va verificato su dispositivi reali.


func _frames(n: int) -> Dictionary:
	var total: float = 0.0
	var hitches: int = 0
	var worst: float = 0.0
	for i: int in n:
		var t0: int = Time.get_ticks_usec()
		await tree.physics_frame
		var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
		total += ms
		worst = maxf(worst, ms)
		if ms > 33.4:
			hitches += 1
	return {"avg": total / n, "hitches": hitches, "worst": worst}


func test_island_cpu_budget() -> void:
	GameState.start_new_game()
	var scene: Node3D = (load("res://scenes/world/island.tscn") as PackedScene).instantiate() as Node3D
	tree.root.add_child(scene)
	tree.current_scene = scene
	await wait_physics_frames(120)  # assestamento dopo il caricamento
	var p: PlayerController = tree.get_first_node_in_group(&"player") as PlayerController
	p.teleport_to(Vector3(302, float(scene.call("ground", 302.0, 160.0)) + 0.3, 160))
	await wait_physics_frames(240)
	var pop: AnimalPopulation = scene.get_node("AnimalPopulation") as AnimalPopulation
	var farm: Dictionary = await _frames(180)
	print("    fattoria: %d animali attivi · %.2f ms/frame · scatti %d · peggiore %.1f ms · mesh condivise %d" % [pop.active_count(), farm["avg"], farm["hitches"], farm["worst"], MeshCache.size()])
	assert_gt(float(pop.active_count()), 10.0, "fattoria popolata")
	assert_lt(float(farm["avg"]), 18.0, "60 fps di CPU alla fattoria")
	assert_lt(float(farm["hitches"]), 4.0, "quasi nessuno scatto a regime")
	# Corsa verso est: si caricano nuovi blocchi di terreno.
	p.rotation.y = PI * 0.5
	Input.action_press(&"move_right")
	Input.action_press(&"run")
	var run: Dictionary = await _frames(300)
	Input.action_release(&"move_right")
	Input.action_release(&"run")
	print("    corsa con caricamento blocchi: %.2f ms/frame · scatti %d · peggiore %.1f ms" % [run["avg"], run["hitches"], run["worst"]])
	assert_lt(float(run["avg"]), 25.0, "media accettabile anche mentre si caricano blocchi")
	scene.queue_free()
	await tree.process_frame
