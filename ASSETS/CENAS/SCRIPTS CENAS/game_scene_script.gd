extends Node2D

func _ready() -> void:
	# O sistema de carregamento (Continue) agora é gerenciado pelo GameState.continuar_jogo()
	# para evitar conflitos de sincronização.
	
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	# Se estivermos retomando um save, o GameState.continuar_jogo() cuidará de disparar o diálogo.
	# Aqui só iniciamos a sequência normal se for um NOVO JOGO (timeline_atual vazia)
	if GameState.timeline_atual == "":
		iniciar_sequencia_fase()

func iniciar_sequencia_fase():
	match GameState.fase_atual:
		1:
			await TimelineManager.tocar_dialogo("Intro_Narrativa")
			await FadeManager.transicao_com_dica()
			await TimelineManager.tocar_dialogo("m01_rua_velho")
			await FadeManager.transicao_com_dica()
			await TimelineManager.tocar_dialogo("Dante_na_usina_Fase1")
			await FadeManager.transicao_com_dica()
			await TimelineManager.tocar_dialogo("Timeline_VilaPeixeiro")
		2:
			await TimelineManager.tocar_dialogo("timeline_resultado_paginas")
			FadeManager.carregar_cena("res://ASSETS/CENAS/TelaFinal.tscn")

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
			GameState.timeline_atual = ""
			GameState.salvar_jogo()
			FadeManager.carregar_cena("res://ASSETS/CENAS/minigame_paginas.tscn")
