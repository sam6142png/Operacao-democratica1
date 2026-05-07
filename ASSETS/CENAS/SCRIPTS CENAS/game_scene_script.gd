extends Node2D

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	if GameState.timeline_atual == "":
		iniciar_sequencia_fase()

func iniciar_sequencia_fase():
	match GameState.fase_atual:
		1:
			await TimelineManager.tocar_dialogo("Intro_Narrativa")
			await FadeManager.transicao_com_dica()
			await _mostrar_tutorial()
			await TimelineManager.tocar_dialogo("m01_rua_velho")
			await FadeManager.transicao_com_dica()
			await TimelineManager.tocar_dialogo("Dante_na_usina_Fase1")
			await FadeManager.transicao_com_dica()
			await TimelineManager.tocar_dialogo("Timeline_VilaPeixeiro")
		2:
			await TimelineManager.tocar_dialogo("timeline_resultado_paginas")
			FadeManager.carregar_cena("res://ASSETS/CENAS/TelaFinal.tscn")

# ══════════════════════════════════════════════
#  TELA DE TUTORIAL (30s auto-close + botão X)
# ══════════════════════════════════════════════

func _mostrar_tutorial() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	
	# Fundo escuro
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	
	# Painel central
	var painel = PanelContainer.new()
	painel.custom_minimum_size = Vector2(850, 550)
	painel.set_anchors_preset(Control.PRESET_CENTER)
	painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	painel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.04, 0.97)
	for p in ["border_width_left","border_width_top","border_width_right","border_width_bottom"]:
		sb.set(p, 2)
	sb.border_color = Color("#FF8C00")
	for p in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		sb.set(p, 12)
	sb.shadow_size = 30
	sb.shadow_color = Color("#FF8C00", 0.15)
	painel.add_theme_stylebox_override("panel", sb)
	layer.add_child(painel)
	
	# Margem interna
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	painel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 22)
	margin.add_child(vbox)
	
	# Título
	var titulo = _lbl("COMO JOGAR", 36, Color("#FF8C00"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)
	
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color("#FF8C00", 0.4)
	vbox.add_child(sep)
	
	# Itens do tutorial
	var itens = [
		["🖱  CLIQUE", "Clique na tela ou pressione ESPAÇO para avançar os diálogos."],
		["⏸  MENU (ESC)", "Pressione ESC para abrir o Menu de Pausa.\nLá você pode salvar, voltar ao menu ou sair."],
		["⚖  CONFIANÇA", "Suas decisões afetam a Confiança da cidade.\nA barra no canto mostra seu nível atual."],
		["⏱  ESCOLHAS", "Quando uma escolha aparecer, você terá 30 segundos.\nSe não decidir, uma opção será escolhida aleatoriamente!"],
		["👆  DECISÕES", "Pense com cuidado. Cada escolha muda a história\ne impacta diretamente o destino de Usina Velha."]
	]
	
	for item in itens:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 18)
		vbox.add_child(hbox)
		
		var icone = _lbl(item[0], 20, Color("#FF8C00"))
		icone.custom_minimum_size = Vector2(220, 0)
		hbox.add_child(icone)
		
		var desc = _lbl(item[1], 18, Color(0.85, 0.85, 0.85))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(desc)
	
	# Botão X (canto superior direito do painel — adicionado ao layer, não ao painel)
	var btn_fechar = Button.new()
	btn_fechar.text = "✕"
	btn_fechar.flat = true
	btn_fechar.add_theme_font_override("font", FONTE)
	btn_fechar.add_theme_font_size_override("font_size", 32)
	btn_fechar.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	btn_fechar.add_theme_color_override("font_hover_color", Color("#FF4444"))
	btn_fechar.set_anchors_preset(Control.PRESET_CENTER)
	btn_fechar.offset_left = 380; btn_fechar.offset_right = 430
	btn_fechar.offset_top = -280; btn_fechar.offset_bottom = -240
	btn_fechar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_fechar.z_index = 10
	layer.add_child(btn_fechar)
	
	# Timer visual (label no rodapé)
	var lbl_timer = _lbl("Fechando em 30s...", 16, Color(0.5, 0.5, 0.5))
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_timer)
	
	# Animação de entrada
	painel.modulate.a = 0.0
	painel.scale = Vector2(0.9, 0.9)
	painel.pivot_offset = painel.custom_minimum_size / 2.0
	var tw_in = create_tween().set_parallel(true)
	tw_in.tween_property(painel, "modulate:a", 1.0, 0.4)
	tw_in.tween_property(painel, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Lógica de fechar (usa Dictionary para compartilhar estado com a lambda)
	var estado := {"fechou": false}
	
	btn_fechar.pressed.connect(func():
		estado.fechou = true
	)
	
	# Contagem regressiva de 30s
	var tempo := 30.0
	while tempo > 0 and not estado.fechou:
		await get_tree().create_timer(0.5).timeout
		tempo -= 0.5
		if not estado.fechou:
			lbl_timer.text = "Fechando em " + str(int(tempo)) + "s..."
			if tempo <= 5:
				lbl_timer.add_theme_color_override("font_color", Color("#FF4444"))
	
	# Animação de saída
	var tw_out = create_tween().set_parallel(true)
	tw_out.tween_property(painel, "modulate:a", 0.0, 0.3)
	tw_out.tween_property(bg, "color:a", 0.0, 0.3)
	await tw_out.finished
	
	layer.queue_free()

func _lbl(txt: String, sz: int, cor: Color) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", cor)
	return l

func _on_dialogic_signal(valor: String) -> void:
	# Helper para registrar + aplicar
	var _e = func(txt: String, d: int):
		GameState.confianca += d
		GameState.registrar_escolha(txt, d)
	
	match valor:
		"escolha_investigar_discreto": _e.call("Investigou discretamente", +1)
		"escolha_intervir": _e.call("Interveio diretamente", +2)
		"escolha_ficar_parado": _e.call("Ficou parado", -1)
		"escolha_seguir_velho": _e.call("Seguiu o velho", +1)
		"escolha_placa": _e.call("Leu a placa", +1)
		"escolha_pescador": _e.call("Falou com o pescador", +1)
		"escolha_verdade": _e.call("Contou a verdade", +2)
		"escolha_mentira": _e.call("Mentiu", -1)
		"escolha_confrontar_peixeiro": _e.call("Confrontou o peixeiro", -1)
		"escolha_entender_peixeiro": _e.call("Entendeu o peixeiro", +1)
		"escolha_esperar_guardas": _e.call("Esperou os guardas", +1)
		"iniciar_minigame_paginas":
			GameState.timeline_atual = ""
			GameState.salvar_jogo()
			FadeManager.carregar_cena("res://ASSETS/CENAS/minigame_paginas.tscn")
