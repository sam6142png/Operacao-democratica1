extends Node

func _ready() -> void:
	await FadeManager.fade_in(0.8)
	
	# Conecta o sinal do Dialogic antes de iniciar
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	await TimelineManager.tocar_dialogo("FASE1")
	await TimelineManager.tocar_dialogo("Dante_na_usina - Fase1")
	await TimelineManager.tocar_dialogo("Timeline - VilaPeixeiro")
	await TimelineManager.tocar_dialogo("radio_abertura")

func _on_dialogic_signal(valor: String) -> void:
	match valor:
		"iniciar_minigame":
			get_tree().change_scene_to_file("res://ASSETS/CENAS/minigame_radio_cifra.tscn")
		"minigame_encerrado":
			get_tree().change_scene_to_file("res://ASSETS/CENAS/game_scene.tscn")
