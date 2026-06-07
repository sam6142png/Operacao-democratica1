extends Node2D

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

var _sequencia_em_execucao := false

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	call_deferred("_tentar_iniciar_sequencia")
	
	# Inicia a música de fundo se não estiver na intro
	if has_node("/root/MusicManager"):
		var music_mgr = get_node("/root/MusicManager")
		if not (GameState.fase_atual == 1 and (GameState.timeline_atual == "" or GameState.timeline_atual == "Intro_Narrativa")):
			music_mgr.play_default_music()


func _tentar_iniciar_sequencia() -> void:
	if _sequencia_em_execucao:
		return
	if not _deve_iniciar_sequencia_fase():
		return
	_sequencia_em_execucao = true
	if GameState.aguardando_sequencia_fase:
		GameState.aguardando_sequencia_fase = false
	GameState.limpar_timeline_ativa()
	await iniciar_sequencia_fase()
	_sequencia_em_execucao = false


func _deve_iniciar_sequencia_fase() -> bool:
	if GameState.aguardando_sequencia_fase:
		return true
	if GameState.timeline_atual == "" and GameState.cena_atual.ends_with("game_scene.tscn"):
		return true
	if GameState.fase_atual >= 2 and _timeline_preso_na_fase_1():
		GameState.limpar_timeline_ativa()
		return true
	return false


func _timeline_preso_na_fase_1() -> bool:
	var tl := GameState.timeline_atual
	if tl.is_empty():
		return false
	var fase1 := [
		"Intro_Narrativa", "m01_rua_velho", "Dante_na_usina_Fase1",
		"Timeline_VilaPeixeiro", "res://ASSETS/DIALOGIC/TIMELINES/Timeline_VilaPeixeiro"
	]
	for nome in fase1:
		if tl.contains(nome):
			return true
	return false

func iniciar_sequencia_fase():
	match GameState.fase_atual:
		1:
			await FadeManager.mostrar_intro_fase(1, "Um pequeno passo para o homem, um grande passo para a humanidade")
			await TimelineManager.tocar_dialogo("Intro_Narrativa")
			if has_node("/root/MusicManager"):
				get_node("/root/MusicManager").play_default_music()
			await FadeManager.transicao_com_dica()
			await _mostrar_tutorial()
			await TimelineManager.tocar_dialogo("m01_rua_velho")
			await FadeManager.transicao_com_dica()
			await TimelineManager.tocar_dialogo("Dante_na_usina_Fase1")
			await FadeManager.transicao_com_dica()
			await TimelineManager.tocar_dialogo("Timeline_VilaPeixeiro")
		2:
			if GameState.fase2_passo == "inicio":
				await GameState.mostrar_resumo_transicao_fase(1, {
					"titulo_fase": "FASE 1 CONCLUÍDA: A BUSCA PELO LIVRO",
					"aprendido": "Localizamos o livro proibido 'Direitos e Deveres Civis' na Vila do Açude Seco e removemos as mentiras e propagandas que o regime tentou impor.\n\nLição: Conhecer os direitos constitucionais e combater a desinformação oficial é o primeiro passo de qualquer resistência cívica.",
					"titulo_proximo": "PRÓXIMO NÍVEL: VOZ NAS ENTRELINHAS",
					"objetivos": "• Despistar as patrulhas militares das ruas de Usina Velha.\n• Invadir o prédio da Rádio sob o controle do regime.\n• Decifrar as transmissões criptografadas da 'Operação Frequência'.\n\nLição: Compreender a importância do livre fluxo de informação no combate ao autoritarismo estatal."
				})
				await FadeManager.mostrar_intro_fase(2, "Voz nas Entrelinhas")
				await TimelineManager.tocar_dialogo("timeline_resultado_paginas")
				await FadeManager.transicao_com_dica()
				await TimelineManager.tocar_dialogo("fase2_guardas")
			elif GameState.fase2_passo == "casa_velho":
				await TimelineManager.tocar_dialogo("fase2_casa_velho")
			elif GameState.fase2_passo == "radio_concluida":
				await TimelineManager.tocar_dialogo("fase2_reacao_mensagem_1")
				await FadeManager.transicao_com_dica()
				await TimelineManager.tocar_dialogo("fase2_reacao_mensagem_2")
				await FadeManager.transicao_com_dica()
				await TimelineManager.tocar_dialogo("fase2_reacao_final")
		3:
			if GameState.fase3_passo == "inicio":
				await GameState.mostrar_resumo_transicao_fase(2, {
					"titulo_fase": "FASE 2 CONCLUÍDA: VOZ NAS ENTRELINHAS",
					"aprendido": "Distraímos as patrulhas nas ruas, invadimos o centro de transmissões da rádio estatal e deciframos as comunicações da 'Operação Frequência'.\n\nLição: A lógica e a persistência cívica superam a censura técnica. A informação livre é a maior ameaça à propaganda.",
					"titulo_proximo": "PRÓXIMO NÍVEL: MENTES EM DISPUTA",
					"objetivos": "• Infiltrar a Escola de Usina Velha sob vigilância das patrulhas.\n• Conectar o sinal da rádio livre na caixa de controle de alto-falantes.\n• Distribuir cartilhas históricas corretas aos estudantes.\n\nLição: Defender a educação livre e o pensamento crítico é garantir a memória e a consciência democrática."
				})
				await FadeManager.mostrar_intro_fase(3, "Mentes em disputa")
				await TimelineManager.tocar_dialogo("fase3_escola_inicio")
			elif GameState.fase3_passo == "escola_concluida":
				await TimelineManager.tocar_dialogo("fase3_escola_conclusao")

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
			GameState.fase_atual = 2
			GameState.fase2_passo = "inicio"
			await _ir_para_minigame("res://ASSETS/CENAS/minigame_paginas.tscn")
		"iniciar_distracao":
			await _ir_para_minigame("res://ASSETS/CENAS/minigame_distracao.tscn")
		"iniciar_radio":
			await _ir_para_minigame("res://ASSETS/CENAS/minigame_radio.tscn")
		"iniciar_minigame_escola":
			await _ir_para_minigame("res://ASSETS/CENAS/minigame_escola.tscn")
		"escolha_escola_expor": _e.call("Expos a doutrinacao abertamente", +2)
		"escolha_escola_discreto": _e.call("Trocou folhas nos armarios discretamente", +1)
		"escolha_escola_mobilizar": _e.call("Mobilizou protesto silencioso", +1)
		"fim_fase_2":
			GameState.fase_atual = 3
			GameState.fase3_passo = "inicio"
			await GameState.retornar_para_game_scene_apos_minigame()
		"fim_fase_3":
			GameState.fase_atual = 4
			await GameState.mostrar_resumo_transicao_fase(3, {
				"titulo_fase": "FASE 3 CONCLUÍDA: MENTES EM DISPUTA",
				"aprendido": "Restabelecemos a Rádio Livre nos alto-falantes da escola e alertamos os estudantes sobre a doutrinação oficial nas salas.\n\nLição: A circulação livre de ideias na escola quebra as correntes do medo e do silêncio. A juventude organizada é imparável.",
				"titulo_proximo": "PRÓXIMO NÍVEL: PRAÇA DA LIBERDADE",
				"objetivos": "• Liderar a marcha dos cidadãos de Usina Velha na Praça do Palácio.\n• Equilibrar mobilização, segurança e organização sob forte tensão militar.\n• Desafiar os portões do regime pacificamente com o poder do povo.\n\nLição: A desobediência civil organizada e pacífica é a maior força moral contra a opressão armada."
			})
			await _ir_para_minigame("res://ASSETS/CENAS/minigame_praca.tscn")


func _ir_para_minigame(caminho_cena: String) -> void:
	await GameState.preparar_transicao_minigame(caminho_cena)
	await FadeManager.carregar_cena(caminho_cena)
