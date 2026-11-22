class_name ErrorCatcher
extends Logger
## Registra gli errori del motore (errori di script, push_error) durante i test,
## così un test che si interrompe per un errore viene segnato come fallito.

var errors: PackedStringArray = PackedStringArray()
var _mutex: Mutex = Mutex.new()


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	# Gli avvisi (warning) non fanno fallire i test.
	if error_type == ERROR_TYPE_WARNING:
		return
	_mutex.lock()
	errors.append("%s (%s:%d %s)" % [rationale if rationale != "" else code, file.get_file(), line, function])
	_mutex.unlock()


func take() -> PackedStringArray:
	_mutex.lock()
	var out: PackedStringArray = errors.duplicate()
	errors.clear()
	_mutex.unlock()
	return out
