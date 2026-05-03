extends CanvasLayer

var overlay: ColorRect

func _ready() -> void:
	layer = 1000  # fica acima de tudo
	_garantir_overlay()

func _garantir_overlay() -> void:
	if overlay == null:
		overlay = ColorRect.new()
		overlay.color = Color(0, 0, 0, 0)
		overlay.anchors_preset = Control.PRESET_FULL_RECT
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(overlay)

func fade_out(duracao: float = 0.6) -> void:
	_garantir_overlay()
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), duracao)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	await tween.finished

func fade_in(duracao: float = 0.8) -> void:
	_garantir_overlay()
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), duracao)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
