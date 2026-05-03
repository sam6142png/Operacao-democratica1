extends Node2D

func _ready() -> void:
	# Fade in para limpar a transição do menu
	if has_node("CanvasLayer/Overlay"):
		var overlay = $CanvasLayer/Overlay
		overlay.color = Color(0, 0, 0, 1)
		var tw = create_tween()
		tw.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.5)
	
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	# Se existe uma timeline salva para retomar
	if GameState.timeline_atual != "":
		var t_retomar = GameState.timeline_atual
		
		# Prevenção contra autosave defasado: se a timeline for da fase 1 mas já estamos na fase 2, ignorar
		if GameState.fase_atual == 2 and t_retomar.contains("VilaPeixeiro"):
			GameState.timeline_atual = ""
			t_retomar = ""
		
		if t_retomar != "":
			# Se for um path completo, pega só o nome base (que o Dialogic prefere)
			if t_retomar.contains("res://"):
				t_retomar = t_retomar.get_file().replace(".dtl", "")
			
			await TimelineManager.tocar_dialogo(t_retomar)
			
			# Após terminar a timeline retomada, verifica se deve seguir a sequência
			if t_retomar == "m01_rua_velho":
				await TimelineManager.tocar_dialogo("Dante_na_usina_Fase1")
				await TimelineManager.tocar_dialogo("Timeline_VilaPeixeiro")
			elif t_retomar == "Dante_na_usina_Fase1":
				await TimelineManager.tocar_dialogo("Timeline_VilaPeixeiro")
			return

	# Sequência normal (Novo Jogo ou fim de timeline)
	match GameState.fase_atual:
		1:
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
