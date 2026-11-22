class_name QuestTracker
extends VBoxContainer
## In alto a sinistra, sotto l'orologio: monete e missione principale in corso.

var _coins: Label
var _title: Label
var _objective: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(24, 62)
	add_theme_constant_override("separation", 2)
	_coins = _label(20)
	_title = _label(19)
	_objective = _label(16)
	QuestService.quests_changed.connect(refresh)
	refresh()


func _process(_delta: float) -> void:
	_coins.text = tr("HUD_COINS") % GameState.coins


func refresh() -> void:
	var q: Dictionary = QuestService.tracked_quest()
	_title.visible = not q.is_empty()
	_objective.visible = not q.is_empty()
	if q.is_empty():
		return
	_title.text = tr(str(q["title_key"]))
	_objective.text = QuestTexts.objectives_text(q, GameState.quests.progress(q["id"]))


func _label(size: int) -> Label:
	var l: Label = Label.new()
	var ls: LabelSettings = LabelSettings.new()
	ls.font_size = size
	ls.font_color = Color.WHITE
	ls.outline_size = 6
	ls.outline_color = Color(0.36, 0.27, 0.42, 0.85)
	l.label_settings = ls
	add_child(l)
	return l
