extends Node2D

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	await TimelineManager.tocar_dialogo("m01_rua_velho")
	await TimelineManager.tocar_dialogo("Dante_na_usina_Fase1")
	await TimelineManager.tocar_dialogo("Timeline_VilaPeixeiro")

func _on_dialogic_signal(valor: String) -> void:
	match valor:
		"escolha_investigar_discreto": GameState.confianca += 1
		"escolha_intervir": GameState.confianca += 2
		"escolha_ficar_parado": GameState.confianca -= 1
		"escolha_seguir_velho": GameState.confianca += 1
		"escolha_placa": GameState.confianca += 1
		"escolha_pescador": GameState.confianca += 1
		"escolha_verdade": GameState.confianca += 2
		"escolha_mentira": GameState.confianca -= 1
		"escolha_confrontar_peixeiro": GameState.confianca -= 1
		"escolha_entender_peixeiro": GameState.confianca += 1
		"escolha_esperar_guardas": GameState.confianca += 1
		"iniciar_minigame_paginas":
			get_tree().change_scene_to_file("res://ASSETS/CENAS/minigame_paginas.tscn")
