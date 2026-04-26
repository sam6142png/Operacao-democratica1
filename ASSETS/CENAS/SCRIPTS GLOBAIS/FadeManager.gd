extends CanvasLayer

var overlay: ColorRect

func _ready() -> void:
	layer = 1000  # fica acima de tudo
	
	overlay = ColorRect.new()
	overlay.color = Color(1, 1, 1, 0)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func fade_out(duracao: float = 0.6) -> void:
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(1, 1, 1, 1), duracao)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	await tween.finished

func fade_in(duracao: float = 0.8) -> void:
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(1, 1, 1, 0), duracao)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
