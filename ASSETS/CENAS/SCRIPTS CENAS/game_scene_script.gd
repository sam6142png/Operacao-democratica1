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
	return true


func executar_passo_timeline(timeline_nome: String, passo_id: String, proximo_passo_id: String, salvar_ao_final: bool = true) -> void:
	var passo_atual_gravado = ""
	match GameState.fase_atual:
		1: passo_atual_gravado = GameState.fase1_passo
		2: passo_atual_gravado = GameState.fase2_passo
		3: passo_atual_gravado = GameState.fase3_passo
		4: passo_atual_gravado = GameState.fase4_passo
	
	# Caso 1: Se o jogador salvou exatamente no meio desta timeline, retomamos
	if GameState.timeline_atual == timeline_nome:
		print("[game_scene] Retomando timeline salva no meio: ", timeline_nome)
		await TimelineManager.retomar_dialogo_salvo(timeline_nome)
		_atualizar_passo_fase(proximo_passo_id)
		return

	# Caso 2: Se estamos carregando e o passo gravado já passou deste passo, pulamos
	if passo_atual_gravado != passo_id:
		print("[game_scene] Pulando timeline ", timeline_nome, " (passo gravado: ", passo_atual_gravado, ", passo esperado: ", passo_id, ")")
		return

	# Caso padrão: Executa a timeline normalmente
	print("[game_scene] Executando timeline normalmente: ", timeline_nome)
	await TimelineManager.tocar_dialogo(timeline_nome, salvar_ao_final)
	_atualizar_passo_fase(proximo_passo_id)


func _atualizar_passo_fase(novo_passo: String) -> void:
	match GameState.fase_atual:
		1: GameState.fase1_passo = novo_passo
		2: GameState.fase2_passo = novo_passo
		3: GameState.fase3_passo = novo_passo
		4: GameState.fase4_passo = novo_passo


func iniciar_sequencia_fase():
	match GameState.fase_atual:
		1:
			if GameState.fase1_passo == "inicio" and GameState.timeline_atual == "":
				await FadeManager.mostrar_intro_fase(1, "Um pequeno passo para o homem, um grande passo para a humanidade")
			
			await executar_passo_timeline("Intro_Narrativa", "inicio", "rua_velho")
			
			if GameState.fase1_passo == "rua_velho" and GameState.timeline_atual == "":
				if has_node("/root/MusicManager"):
					get_node("/root/MusicManager").play_default_music()
				await FadeManager.transicao_com_dica()
				await _mostrar_tutorial()
			
			await executar_passo_timeline("m01_rua_velho", "rua_velho", "usina")
			
			if GameState.fase1_passo == "usina" and GameState.timeline_atual == "":
				await FadeManager.transicao_com_dica()
			
			await executar_passo_timeline("Dante_na_usina_Fase1", "usina", "vila")
			
			if GameState.fase1_passo == "vila" and GameState.timeline_atual == "":
				await FadeManager.transicao_com_dica()
			
			await executar_passo_timeline("Timeline_VilaPeixeiro", "vila", "concluido")
		2:
			if GameState.fase2_passo == "inicio" and GameState.timeline_atual == "":
				await GameState.mostrar_resumo_transicao_fase(1, {
					"titulo_fase": "FASE 1 CONCLUÍDA: A BUSCA PELO LIVRO",
					"aprendido": "Localizamos o livro proibido 'Direitos e Deveres do Povo' na Vila do Açude Seco e removemos as mentiras e propagandas que o regime tentou impor.\n\nLição: Conhecer os direitos constitucionais e combater a desinformação oficial é o primeiro passo de qualquer resistência cívica.",
					"titulo_proximo": "PRÓXIMO NÍVEL: VOZ NAS ENTRELINHAS",
					"objetivos": "• Despistar as patrulhas militares das ruas de Usina Velha.\n• Invadir o prédio da Rádio sob o controle do regime.\n• Decifrar as transmissões criptografadas da 'Operação Frequência'.\n\nLição: Compreender a importância do livre fluxo de informação no combate ao autoritarismo estatal."
				})
				await FadeManager.mostrar_intro_fase(2, "Voz nas Entrelinhas")
			
			await executar_passo_timeline("timeline_resultado_paginas", "inicio", "guardas")
			
			if GameState.fase2_passo == "guardas" and GameState.timeline_atual == "":
				await FadeManager.transicao_com_dica()
				
			await executar_passo_timeline("fase2_guardas", "guardas", "inicio_jogo_fase2")
			
			await executar_passo_timeline("fase2_casa_velho", "casa_velho", "casa_velho_concluida")
			
			await executar_passo_timeline("fase2_reacao_mensagem_1", "radio_concluida", "reacao_msg2")
			
			if GameState.fase2_passo == "reacao_msg2" and GameState.timeline_atual == "":
				await FadeManager.transicao_com_dica()
				
			await executar_passo_timeline("fase2_reacao_mensagem_2", "reacao_msg2", "reacao_final")
			
			if GameState.fase2_passo == "reacao_final" and GameState.timeline_atual == "":
				await FadeManager.transicao_com_dica()
				
			await executar_passo_timeline("fase2_reacao_final", "reacao_final", "fase2_concluida")
		3:
			if GameState.fase3_passo == "inicio" and GameState.timeline_atual == "":
				await GameState.mostrar_resumo_transicao_fase(2, {
					"titulo_fase": "FASE 2 CONCLUÍDA: VOZ NAS ENTRELINHAS",
					"aprendido": "Distraímos as patrulhas nas ruas, invadimos o centro de transmissões da rádio estatal e deciframos as comunicações da 'Operação Frequência'.\n\nLição: A lógica e a persistência cívica superam a censura técnica. A informação livre é a maior ameaça à propaganda.",
					"titulo_proximo": "PRÓXIMO NÍVEL: MENTES EM DISPUTA",
					"objetivos": "• Infiltrar a Escola de Usina Velha sob vigilância das patrulhas.\n• Conectar o sinal da rádio livre na caixa de controle de alto-falantes.\n• Distribuir cartilhas históricas corretas aos estudantes.\n\nLição: Defender a educação livre e o pensamento crítico é garantir a memória e a consciência democrática."
				})
				await FadeManager.mostrar_intro_fase(3, "Mentes em disputa")
				
			await executar_passo_timeline("fase3_escola_inicio", "inicio", "escola_jogo")
			
			await executar_passo_timeline("fase3_escola_conclusao", "escola_concluida", "fase3_concluida")
		4:
			if GameState.fase4_passo == "inicio" and GameState.timeline_atual == "":
				await FadeManager.mostrar_intro_fase(4, "Praça da Liberdade")
				
			await executar_passo_timeline("fase4_praca_inicio", "inicio", "praca_jogo")


# ══════════════════════════════════════════════
#  TELA DE TUTORIAL (30s auto-close + botão X)
# ══════════════════════════════════════════════

func _mostrar_tutorial() -> void:
	var font_title = load("res://ASSETS/FONTES/Almendra,Comfortaa,Playfair,Share_Tech/Share_Tech/ShareTech-Regular.ttf")
	var font_body = load("res://ASSETS/FONTES/Almendra,Comfortaa,Playfair,Share_Tech/Comfortaa/Comfortaa-VariableFont_wght.ttf")
	
	var layer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	
	# Fundo escuro (cyber charcoal-blue translúcido)
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	
	# Painel central premium
	var painel = PanelContainer.new()
	painel.custom_minimum_size = Vector2(900, 600)
	painel.set_anchors_preset(Control.PRESET_CENTER)
	painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	painel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	for p in ["border_width_left","border_width_top","border_width_right","border_width_bottom"]:
		sb.set(p, 2)
	sb.border_color = Color("#FF8C00", 0.85)
	for p in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		sb.set(p, 16)
	sb.shadow_size = 35
	sb.shadow_color = Color("#FF8C00", 0.12)
	painel.add_theme_stylebox_override("panel", sb)
	layer.add_child(painel)
	
	# Margem interna
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 35)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	painel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Título
	var titulo = Label.new()
	titulo.text = "COMO JOGAR"
	titulo.add_theme_font_override("font", font_title)
	titulo.add_theme_font_size_override("font_size", 38)
	titulo.add_theme_color_override("font_color", Color("#FF9F33"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)
	
	# Separador estilizado
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color("#FF8C00", 0.25)
	vbox.add_child(sep)
	
	# Itens do tutorial
	var itens = [
		["🖱  CLIQUE", "Clique na tela ou pressione ESPAÇO para avançar os diálogos."],
		["⏸  MENU (ESC)", "Pressione ESC para abrir o Menu de Pausa. Lá você pode salvar, voltar ao menu ou sair."],
		["⚖  CONFIANÇA", "Suas decisões afetam a Confiança da cidade. A barra no canto mostra seu nível atual."],
		["⏱  ESCOLHAS", "Quando uma escolha aparecer, você terá 30 segundos. Se não decidir, uma opção será escolhida aleatoriamente!"],
		["👆  DECISÕES", "Pense com cuidado. Cada escolha muda a história e impacta diretamente o destino de Usina Velha."]
	]
	
	# Estilo base dos cards translúcidos
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.1, 0.13, 0.20, 0.25)
	for p in ["border_width_left","border_width_top","border_width_right","border_width_bottom"]:
		card_sb.set(p, 1)
	card_sb.border_color = Color(0.18, 0.22, 0.32, 0.4)
	for p in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		card_sb.set(p, 10)
	card_sb.content_margin_left = 20
	card_sb.content_margin_right = 20
	card_sb.content_margin_top = 12
	card_sb.content_margin_bottom = 12
	
	# Estilo base das badges dos ícones
	var badge_sb = StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.9, 0.55, 0.1, 0.08)
	for p in ["border_width_left","border_width_top","border_width_right","border_width_bottom"]:
		badge_sb.set(p, 1)
	badge_sb.border_color = Color(0.9, 0.55, 0.1, 0.4)
	for p in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		badge_sb.set(p, 6)
	badge_sb.content_margin_left = 14
	badge_sb.content_margin_right = 14
	badge_sb.content_margin_top = 6
	badge_sb.content_margin_bottom = 6
	
	for item in itens:
		var card_panel = PanelContainer.new()
		card_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var sb_item = card_sb.duplicate()
		card_panel.add_theme_stylebox_override("panel", sb_item)
		vbox.add_child(card_panel)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 24)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_panel.add_child(hbox)
		
		# Badge para o Ícone/Nome Técnico
		var badge = PanelContainer.new()
		badge.add_theme_stylebox_override("panel", badge_sb)
		badge.custom_minimum_size = Vector2(200, 0)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(badge)
		
		var icone = Label.new()
		icone.text = item[0]
		icone.add_theme_font_override("font", font_title)
		icone.add_theme_font_size_override("font_size", 16)
		icone.add_theme_color_override("font_color", Color("#FF9F33"))
		icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_child(icone)
		
		# Descrição detalhada
		var desc = Label.new()
		desc.text = item[1]
		desc.add_theme_font_override("font", font_body)
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color("#E2E8F0"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(desc)
		
		# Efeito de Hover interativo nos Cards (Micro-Animações)
		card_panel.mouse_entered.connect(func():
			var t = card_panel.create_tween().set_parallel(true)
			t.tween_property(sb_item, "bg_color", Color(0.14, 0.18, 0.28, 0.45), 0.2)
			t.tween_property(sb_item, "border_color", Color("#FF8C00", 0.65), 0.2)
			card_panel.pivot_offset = card_panel.size / 2.0
			t.tween_property(card_panel, "scale", Vector2(1.012, 1.012), 0.15)
		)
		card_panel.mouse_exited.connect(func():
			var t = card_panel.create_tween().set_parallel(true)
			t.tween_property(sb_item, "bg_color", Color(0.1, 0.13, 0.20, 0.25), 0.2)
			t.tween_property(sb_item, "border_color", Color(0.18, 0.22, 0.32, 0.4), 0.2)
			t.tween_property(card_panel, "scale", Vector2.ONE, 0.15)
		)
	
	# Container invisível para posicionamento absoluto do botão X
	var absolute_control = Control.new()
	absolute_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(absolute_control)
	
	# Botão X (circular, elegante, ancorado ao canto superior direito)
	var btn_fechar = Button.new()
	btn_fechar.text = "✕"
	btn_fechar.flat = true
	btn_fechar.add_theme_font_override("font", font_body)
	btn_fechar.add_theme_font_size_override("font_size", 22)
	btn_fechar.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	btn_fechar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_fechar.anchor_left = 1.0
	btn_fechar.anchor_right = 1.0
	btn_fechar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	btn_fechar.offset_left = -48
	btn_fechar.offset_right = -16
	btn_fechar.offset_top = 16
	btn_fechar.offset_bottom = 48
	btn_fechar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_fechar.z_index = 10
	absolute_control.add_child(btn_fechar)
	
	# Animação circular no botão fechar (Micro-Animações)
	btn_fechar.pivot_offset = Vector2(16, 16)
	btn_fechar.mouse_entered.connect(func():
		var t = btn_fechar.create_tween().set_parallel(true)
		t.tween_property(btn_fechar, "scale", Vector2(1.2, 1.2), 0.15)
		t.tween_property(btn_fechar, "modulate", Color(1.0, 0.35, 0.35), 0.15)
	)
	btn_fechar.mouse_exited.connect(func():
		var t = btn_fechar.create_tween().set_parallel(true)
		t.tween_property(btn_fechar, "scale", Vector2.ONE, 0.15)
		t.tween_property(btn_fechar, "modulate", Color.WHITE, 0.15)
	)
	
	# Pílula de Status no rodapé para o timer
	var center_container = CenterContainer.new()
	vbox.add_child(center_container)
	
	var pill_panel = PanelContainer.new()
	var pill_sb = StyleBoxFlat.new()
	pill_sb.bg_color = Color(0.1, 0.12, 0.18, 0.6)
	for p in ["border_width_left","border_width_top","border_width_right","border_width_bottom"]:
		pill_sb.set(p, 1)
	pill_sb.border_color = Color(0.18, 0.22, 0.32, 0.5)
	for p in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		pill_sb.set(p, 12)
	pill_sb.content_margin_left = 16
	pill_sb.content_margin_right = 16
	pill_sb.content_margin_top = 6
	pill_sb.content_margin_bottom = 6
	pill_panel.add_theme_stylebox_override("panel", pill_sb)
	center_container.add_child(pill_panel)
	
	var lbl_timer = Label.new()
	lbl_timer.text = "Fechando em 30s..."
	lbl_timer.add_theme_font_override("font", font_title)
	lbl_timer.add_theme_font_size_override("font_size", 14)
	lbl_timer.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill_panel.add_child(lbl_timer)
	
	# Animação de entrada do painel
	painel.modulate.a = 0.0
	painel.scale = Vector2(0.9, 0.9)
	painel.pivot_offset = Vector2(450, 300)
	var tw_in = create_tween().set_parallel(true)
	tw_in.tween_property(painel, "modulate:a", 1.0, 0.4)
	tw_in.tween_property(painel, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Lógica de fechar
	var estado := {"fechou": false, "pulsing": false}
	
	btn_fechar.pressed.connect(func():
		estado.fechou = true
	)
	
	# Contagem regressiva de 30s com pulso nos 5s finais
	var tempo := 30.0
	while tempo > 0 and not estado.fechou:
		await get_tree().create_timer(0.5).timeout
		tempo -= 0.5
		if not estado.fechou:
			lbl_timer.text = "Fechando em " + str(int(tempo)) + "s..."
			if tempo <= 5:
				lbl_timer.add_theme_color_override("font_color", Color("#FF4444"))
				pill_sb.border_color = Color("#FF4444", 0.6)
				if not estado.pulsing:
					estado.pulsing = true
					pill_panel.pivot_offset = pill_panel.size / 2.0
					var tw_pulse = pill_panel.create_tween().set_loops()
					tw_pulse.tween_property(pill_panel, "scale", Vector2(1.05, 1.05), 0.3).set_ease(Tween.EASE_OUT)
					tw_pulse.tween_property(pill_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_IN)
	
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
			GameState.fase4_passo = "inicio"
			await GameState.mostrar_resumo_transicao_fase(3, {
				"titulo_fase": "FASE 3 CONCLUÍDA: MENTES EM DISPUTA",
				"aprendido": "Restabelecemos a Rádio Livre nos alto-falantes da escola e alertamos os estudantes sobre a doutrinação oficial nas salas.\n\nLição: A circulação livre de ideias na escola quebra as correntes do medo e do silêncio. A juventude organizada é imparável.",
				"titulo_proximo": "PRÓXIMO NÍVEL: PRAÇA DA LIBERDADE",
				"objetivos": "• Liderar a marcha dos cidadãos de Usina Velha na Praça do Palácio.\n• Equilibrar mobilização, segurança e organização sob forte tensão militar.\n• Desafiar os portões do regime pacificamente com o poder do povo.\n\nLição: A desobediência civil organizada e pacífica é a maior força moral contra a opressão armada."
			})
			await GameState.retornar_para_game_scene_apos_minigame()
		"iniciar_minigame_praca":
			GameState.fase_atual = 4
			GameState.fase4_passo = "praca"
			await _ir_para_minigame("res://ASSETS/CENAS/minigame_praca.tscn")


func _ir_para_minigame(caminho_cena: String) -> void:
	await GameState.preparar_transicao_minigame(caminho_cena)
	await FadeManager.carregar_cena(caminho_cena)
