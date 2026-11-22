extends SceneTree
## Esegue tutti i test automatici del progetto.
##
## Uso:
##   godot --headless --path . -s res://tests/run_tests.gd
##   godot --headless --path . -s res://tests/run_tests.gd -- --filter=game_time
##
## Codice di uscita 0 se tutti i test passano, 1 altrimenti.

const TEST_DIRS: PackedStringArray = ["res://tests/unit", "res://tests/integration"]


func _initialize() -> void:
	# Lascia che gli autoload siano pronti prima di eseguire i test.
	_run.call_deferred()


func _run() -> void:
	var filter: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.trim_prefix("--filter=")

	var files: PackedStringArray = PackedStringArray()
	for dir: String in TEST_DIRS:
		_collect_test_files(dir, files)
	files.sort()

	var passed: int = 0
	var failed: int = 0
	var failed_names: PackedStringArray = PackedStringArray()

	for path: String in files:
		if filter != "" and not path.contains(filter):
			continue
		var script: GDScript = load(path) as GDScript
		if script == null:
			print("ERRORE: impossibile caricare ", path)
			failed += 1
			failed_names.append(path)
			continue
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var test: TestCase = script.new() as TestCase
			test.tree = self
			test.before_each()
			await test.call(method_name)
			test.after_each()
			var label: String = "%s::%s" % [path.get_file().get_basename(), method_name]
			if test.get_failures().is_empty():
				passed += 1
				print("  ok    ", label)
			else:
				failed += 1
				failed_names.append(label)
				print("  FAIL  ", label)
				for failure: String in test.get_failures():
					print("        - ", failure)

	print("")
	print("Test superati: %d   Test falliti: %d" % [passed, failed])
	if failed > 0:
		for name: String in failed_names:
			print("  fallito: ", name)
	quit(1 if failed > 0 else 0)


func _collect_test_files(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_collect_test_files(dir_path.path_join(sub), out)
	for file: String in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
