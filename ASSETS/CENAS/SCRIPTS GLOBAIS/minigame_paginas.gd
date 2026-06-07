extends Control

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const TEX_LIVRO = preload("res://ASSETS/SPRITES/PROPS/LivroAberto.png")

const MAX_ERROS: int = 4
const TEMPO_POR_PAGINA: float = 32.0
const TOTAL_PAGINAS: int = 10

const COR_FUNDO := Color("#08090d")
const COR_PAPEL := Color("#f0dfb8")
const COR_TINTA := Color("#2f2114")
const COR_BORDA := Color("#a66a2d")
const COR_DIREITO := Color("#25a9ff")
const COR_DEVER := Color("#ff9b2f")
const COR_PROPAGANDA := Color("#b86cff")
const COR_SUCESSO := Color("#31d67b")
const COR_ERRO := Color("#e84848")

const TODAS_PAGINAS: Array[Dictionary] = [
	{
		"texto": "Todo cidadao tem direito a educacao gratuita e de qualidade.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "Educacao e um direito social. O regime tenta apagar isso porque povo instruido questiona."
	},
	{
		"texto": "E dever do cidadao votar, fiscalizar representantes e participar da vida publica.",
		"resposta": "dever",
		"adulterada": false,
		"explicacao": "Participacao politica nao termina no voto. Democracia tambem exige vigilancia cidada."
	},
	{
		"texto": "O governo pode censurar informacoes perigosas para preservar a ordem publica.",
		"resposta": "adulterada",
		"adulterada": true,
		"explicacao": "Versao adulterada. Liberdade de informacao protege o povo contra abusos de poder."
	},
	{
		"texto": "Todo cidadao tem direito a liberdade de expressao e manifestacao pacifica.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "Manifestacao pacifica e ferramenta legitima de participacao popular."
	},
	{
		"texto": "E dever do cidadao preservar patrimonio publico e respeitar espacos comunitarios.",
		"resposta": "dever",
		"adulterada": false,
		"explicacao": "O que e publico pertence a todos. Preservar tambem e defender a cidade."
	},
	{
		"texto": "O Estado deve garantir saude, moradia, seguranca e dignidade a populacao.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "Direitos sociais existem para impedir que cidadania seja privilegio de poucos."
	},
	{
		"texto": "Cidadaos que discordarem do governo devem ser removidos para trabalho obrigatorio.",
		"resposta": "adulterada",
		"adulterada": true,
		"explicacao": "Versao adulterada. Discordar do governo nao e crime em uma democracia."
	},
	{
		"texto": "E dever do cidadao contribuir com impostos para financiar servicos publicos.",
		"resposta": "dever",
		"adulterada": false,
		"explicacao": "Impostos sustentam servicos coletivos quando usados com transparencia."
	},
	{
		"texto": "Todo cidadao tem direito a julgamento justo e presuncao de inocencia.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "Sem julgamento justo, qualquer pessoa pode virar alvo do poder."
	},
	{
		"texto": "O regime pode suspender eleicoes quando a sociedade parecer instavel.",
		"resposta": "adulterada",
		"adulterada": true,
		"explicacao": "Versao adulterada. Eleicoes livres sao base da soberania popular."
	}
]

var paginas: Array[Dictionary] = []
var indice: int = 0
var acertos: int = 0
var erros: int = 0
var adulteradas_encontradas: int = 0
var tempo_restante: float = TEMPO_POR_PAGINA
var aguardando_feedback: bool = false
var jogo_ativo: bool = false
var finalizando: bool = false
var confianca_inicial: int = 0
var card_pos_original: Vector2 = Vector2.ZERO
var arrastando: bool = false

var bg: ColorRect
var mesa: PanelContainer
var lbl_titulo: Label
var lbl_progresso: Label
var lbl_erros: Label
var lbl_timer: Label
var lbl_card: Label
var lbl_feedback: Label
var lbl_explicacao: Label
var card_holder: Control
var card: PanelContainer
var btn_direito: Button
var btn_dever: Button
var btn_adulterada: Button
var zona_direito: PanelContainer
var zona_dever: PanelContainer
var zona_adulterada: PanelContainer
var painel_overlay: PanelContainer


func _ready() -> void:
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false
	confianca_inicial = GameState.confianca
	_montar_ui()
	call_deferred("_centralizar_card")
	_mostrar_intro()


func _montar_ui() -> void:
	bg = ColorRect.new()
	bg.color = COR_FUNDO
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var grade: Control = Control.new()
	grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.draw.connect(func():
		var size_rect: Vector2 = grade.size
		for x in range(0, int(size_rect.x), 64):
			grade.draw_line(Vector2(x, 0), Vector2(x, size_rect.y), Color("#ffffff", 0.025), 1.0)
		for y in range(0, int(size_rect.y), 64):
			grade.draw_line(Vector2(0, y), Vector2(size_rect.x, y), Color("#ffffff", 0.025), 1.0)
	)
	add_child(grade)

	var root: MarginContainer = MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 70)
	root.add_theme_constant_override("margin_right", 70)
	root.add_theme_constant_override("margin_top", 34)
	root.add_theme_constant_override("margin_bottom", 42)
	add_child(root)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	root.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	vbox.add_child(header)

	lbl_titulo = _label("ANALISE DO LIVRO CIVIL", 40, Color("#ffd28a"), FONTE)
	lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_titulo)

	var status_box: VBoxContainer = VBoxContainer.new()
	status_box.custom_minimum_size = Vector2(360, 0)
	header.add_child(status_box)

	lbl_progresso = _label("PAGINA 0/" + str(TOTAL_PAGINAS), 20, Color("#f5e7cc"), FONTE)
	lbl_progresso.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_box.add_child(lbl_progresso)

	lbl_erros = _label("ERROS 0/" + str(MAX_ERROS), 20, Color("#f5e7cc"), FONTE)
	lbl_erros.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_box.add_child(lbl_erros)

	lbl_timer = _label("TEMPO " + str(int(TEMPO_POR_PAGINA)) + "s", 20, Color("#f5e7cc"), FONTE)
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_box.add_child(lbl_timer)

	var corpo: HBoxContainer = HBoxContainer.new()
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_theme_constant_override("separation", 22)
	vbox.add_child(corpo)

	var esquerda: VBoxContainer = VBoxContainer.new()
	esquerda.custom_minimum_size = Vector2(300, 0)
	esquerda.add_theme_constant_override("separation", 16)
	corpo.add_child(esquerda)

	zona_direito = _zona("DIREITO", COR_DIREITO)
	zona_dever = _zona("DEVER", COR_DEVER)
	esquerda.add_child(zona_direito)
	esquerda.add_child(zona_dever)

	mesa = PanelContainer.new()
	mesa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mesa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mesa.add_theme_stylebox_override("panel", _stylebox(Color("#17100b", 0.82), COR_BORDA, 3, 8))
	corpo.add_child(mesa)

	var mesa_margin: MarginContainer = _margin(26)
	mesa.add_child(mesa_margin)

	var mesa_box: VBoxContainer = VBoxContainer.new()
	mesa_box.add_theme_constant_override("separation", 18)
	mesa_margin.add_child(mesa_box)

	card_holder = Control.new()
	card_holder.custom_minimum_size = Vector2(720, 470)
	card_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mesa_box.add_child(card_holder)

	card = PanelContainer.new()
	card.custom_minimum_size = Vector2(690, 430)
	card.add_theme_stylebox_override("panel", _card_style())
	card_holder.add_child(card)

	lbl_card = _label("", 28, Color("#101010"), FONTE)
	lbl_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_card.offset_left = 88
	lbl_card.offset_right = -88
	lbl_card.offset_top = 70
	lbl_card.offset_bottom = -78
	card.add_child(lbl_card)

	var botoes: HBoxContainer = HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 18)
	mesa_box.add_child(botoes)

	btn_direito = _botao("DIREITO", COR_DIREITO)
	btn_dever = _botao("DEVER", COR_DEVER)
	btn_adulterada = _botao("PROPAGANDA", COR_PROPAGANDA)
	btn_direito.pressed.connect(func(): _avaliar("direito"))
	btn_dever.pressed.connect(func(): _avaliar("dever"))
	btn_adulterada.pressed.connect(func(): _avaliar("adulterada"))
	botoes.add_child(btn_direito)
	botoes.add_child(btn_dever)
	botoes.add_child(btn_adulterada)

	var direita: VBoxContainer = VBoxContainer.new()
	direita.custom_minimum_size = Vector2(330, 0)
	direita.add_theme_constant_override("separation", 16)
	corpo.add_child(direita)

	zona_adulterada = _zona("PROPAGANDA", COR_PROPAGANDA)
	direita.add_child(zona_adulterada)

	var painel_info: PanelContainer = PanelContainer.new()
	painel_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	painel_info.add_theme_stylebox_override("panel", _stylebox(Color("#11151f", 0.92), Color("#52627f"), 2, 8))
	direita.add_child(painel_info)

	var info_margin: MarginContainer = _margin(18)
	painel_info.add_child(info_margin)
	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 14)
	info_margin.add_child(info_box)

	lbl_feedback = _label("", 24, Color("#f5e7cc"), FONTE)
	lbl_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_box.add_child(lbl_feedback)

	lbl_explicacao = _label("", 19, Color("#cbd7e8"), FONTE)
	lbl_explicacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_explicacao.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.add_child(lbl_explicacao)

	_set_jogo_visivel(false)


func _mostrar_intro() -> void:
	painel_overlay = _overlay("LIVRO ADULTERADO", Color("#ffd28a"))
	var vbox: VBoxContainer = painel_overlay.get_child(0)
	var desc: Label = _label(
		"O livro que o peixeiro guardou foi rasgado e reescrito pelo regime.\n\n" +
		"Classifique cada pagina como direito, dever ou propaganda. A cidade precisa saber o que ainda e verdade.",
		22,
		COR_TINTA,
		FONTE
	)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var botao: Button = _botao("COMEÇAR", COR_BORDA)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao.pressed.connect(func():
		painel_overlay.queue_free()
		_iniciar_rodada()
	)
	vbox.add_child(botao)


func _iniciar_rodada() -> void:
	_set_jogo_visivel(true)
	paginas = TODAS_PAGINAS.duplicate()
	paginas.shuffle()
	indice = 0
	acertos = 0
	erros = 0
	adulteradas_encontradas = 0
	aguardando_feedback = false
	jogo_ativo = true
	finalizando = false
	arrastando = false
	_atualizar_hud()
	await _centralizar_card()
	_carregar_pagina()


func _carregar_pagina() -> void:
	if indice >= paginas.size():
		_mostrar_resultado(true)
		return

	var pagina: Dictionary = paginas[indice]
	lbl_card.text = String(pagina["texto"])
	lbl_feedback.text = "Leia como se sua cidade dependesse disso."
	lbl_feedback.add_theme_color_override("font_color", Color("#f5e7cc"))
	lbl_explicacao.text = ""
	aguardando_feedback = false
	tempo_restante = TEMPO_POR_PAGINA
	arrastando = false
	_atualizar_hud()
	_set_botoes_ativos(true)
	_resetar_card_visual()


func _process(delta: float) -> void:
	if not jogo_ativo or aguardando_feedback:
		return

	tempo_restante -= delta
	if tempo_restante <= 0.0:
		_avaliar("timeout")
		return
	_atualizar_hud()
	_processar_arraste()


func _processar_arraste() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse: Vector2 = get_global_mouse_position()
		var rect_card: Rect2 = Rect2(card.global_position, card.size)
		if rect_card.has_point(mouse) or arrastando:
			arrastando = true
			card.global_position = mouse - card.size * 0.5
			var delta_x: float = card.global_position.x - card_pos_original.x
			card.rotation = lerp(card.rotation, deg_to_rad(delta_x / 20.0), 0.18)
			_realcar_zonas()
	elif arrastando:
		arrastando = false
		var centro: Vector2 = card.global_position + card.size * 0.5
		if zona_direito.get_global_rect().has_point(centro):
			_avaliar("direito")
		elif zona_dever.get_global_rect().has_point(centro):
			_avaliar("dever")
		elif zona_adulterada.get_global_rect().has_point(centro):
			_avaliar("adulterada")
		else:
			_resetar_card_visual()
		_realcar_zonas(false)


func _avaliar(escolha: String) -> void:
	if aguardando_feedback or finalizando:
		return

	aguardando_feedback = true
	_set_botoes_ativos(false)
	_realcar_zonas(false)

	var pagina: Dictionary = paginas[indice]
	var correta: bool = escolha == String(pagina["resposta"])
	if escolha == "timeout":
		correta = false

	if correta:
		acertos += 1
		if bool(pagina["adulterada"]):
			adulteradas_encontradas += 1
			GameState.adulterada_identificada_fase1 = true
			GameState.confianca += 2
			GameState.registrar_escolha("Identificou propaganda no livro", 2)
		else:
			GameState.confianca += 1
			GameState.registrar_escolha("Classificou pagina como " + escolha, 1)
		_feedback(true, "VERDADE RESTAURADA")
	else:
		erros += 1
		GameState.confianca -= 1
		if escolha == "timeout":
			GameState.registrar_escolha("Demorou na analise do livro", -1)
			_feedback(false, "TEMPO ESGOTADO")
		elif bool(pagina["adulterada"]):
			GameState.registrar_escolha("Deixou propaganda passar", -1)
			_feedback(false, "PROPAGANDA PASSOU")
		else:
			GameState.registrar_escolha("Classificacao incorreta do livro", -1)
			_feedback(false, "CLASSIFICACAO INCORRETA")

	lbl_explicacao.text = String(pagina["explicacao"])
	_atualizar_hud()
	await _animar_saida(escolha)

	if erros >= MAX_ERROS:
		_mostrar_resultado(false)
		return

	indice += 1
	await get_tree().create_timer(0.75).timeout
	_carregar_pagina()


func _mostrar_resultado(concluiu: bool) -> void:
	jogo_ativo = false
	_set_botoes_ativos(false)
	card.visible = false
	painel_overlay = _overlay("ANALISE CONCLUIDA" if concluiu else "ANALISE FALHOU", COR_SUCESSO if concluiu else COR_ERRO)
	var vbox: VBoxContainer = painel_overlay.get_child(0)

	var resumo: Label = _label(
		"Paginas validadas: " + str(acertos) + "/" + str(TOTAL_PAGINAS) +
		"\nPropagandas encontradas: " + str(adulteradas_encontradas) +
		"\nErros: " + str(erros) + "/" + str(MAX_ERROS),
		22,
		COR_TINTA,
		FONTE
	)
	resumo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(resumo)

	if concluiu:
		var botao: Button = _botao("SEGUIR", COR_SUCESSO)
		botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		botao.pressed.connect(_finalizar)
		vbox.add_child(botao)
	else:
		var botao_retry: Button = _botao("TENTAR DE NOVO", COR_ERRO)
		botao_retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		botao_retry.pressed.connect(func():
			painel_overlay.queue_free()
			GameState.confianca = confianca_inicial
			_iniciar_rodada()
		)
		vbox.add_child(botao_retry)


func _finalizar() -> void:
	if finalizando:
		return
	finalizando = true
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = true
	GameState.acertos_paginas_fase1 = acertos
	GameState.fase_atual = 2
	GameState.fase2_passo = "inicio"
	GameState.limpar_timeline_ativa()
	GameState.desbloquear_conquista("historiador")
	await GameState.retornar_para_game_scene_apos_minigame()


func _atualizar_hud() -> void:
	lbl_progresso.text = "PAGINA " + str(mini(indice + 1, TOTAL_PAGINAS)) + "/" + str(TOTAL_PAGINAS)
	lbl_erros.text = "ERROS " + str(erros) + "/" + str(MAX_ERROS)
	lbl_timer.text = "TEMPO " + str(ceili(tempo_restante)) + "s"
	lbl_timer.add_theme_color_override("font_color", COR_ERRO if tempo_restante <= 7.0 else Color("#f5e7cc"))
	lbl_erros.add_theme_color_override("font_color", COR_ERRO if erros >= MAX_ERROS - 1 else Color("#f5e7cc"))


func _feedback(ok: bool, texto: String) -> void:
	lbl_feedback.text = texto
	lbl_feedback.add_theme_color_override("font_color", COR_SUCESSO if ok else COR_ERRO)


func _animar_saida(escolha: String) -> void:
	var destino: Vector2 = card.position
	var rotacao: float = 0.0
	match escolha:
		"direito":
			destino += Vector2(-900, -40)
			rotacao = deg_to_rad(-18.0)
		"dever":
			destino += Vector2(-900, 180)
			rotacao = deg_to_rad(-10.0)
		"adulterada":
			destino += Vector2(900, 80)
			rotacao = deg_to_rad(18.0)
		_:
			destino += Vector2(0, 520)
			rotacao = deg_to_rad(7.0)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(card, "position", destino, 0.35)
	tw.tween_property(card, "modulate:a", 0.0, 0.28)
	tw.tween_property(card, "rotation", rotacao, 0.35)
	await tw.finished


func _resetar_card_visual() -> void:
	card.visible = true
	card.position = card_pos_original
	card.rotation = 0.0
	card.modulate = Color.WHITE


func _centralizar_card() -> void:
	await get_tree().process_frame
	var area: Vector2 = card_holder.size
	card_pos_original = (area - card.custom_minimum_size) * 0.5
	card.position = card_pos_original


func _realcar_zonas(ativo_realce: bool = true) -> void:
	var centro: Vector2 = card.global_position + card.size * 0.5
	_set_zona_alpha(zona_direito, ativo_realce and zona_direito.get_global_rect().has_point(centro))
	_set_zona_alpha(zona_dever, ativo_realce and zona_dever.get_global_rect().has_point(centro))
	_set_zona_alpha(zona_adulterada, ativo_realce and zona_adulterada.get_global_rect().has_point(centro))


func _set_zona_alpha(zona: PanelContainer, ativa: bool) -> void:
	zona.modulate.a = 1.0 if ativa else 0.72


func _set_botoes_ativos(ativo_botoes: bool) -> void:
	btn_direito.disabled = not ativo_botoes
	btn_dever.disabled = not ativo_botoes
	btn_adulterada.disabled = not ativo_botoes


func _set_jogo_visivel(visivel: bool) -> void:
	card_holder.visible = visivel
	zona_direito.visible = visivel
	zona_dever.visible = visivel
	zona_adulterada.visible = visivel
	lbl_feedback.visible = visivel
	lbl_explicacao.visible = visivel


func _zona(titulo: String, cor: Color) -> PanelContainer:
	var zona: PanelContainer = PanelContainer.new()
	zona.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zona.modulate.a = 0.72
	zona.add_theme_stylebox_override("panel", _stylebox(Color(cor.r, cor.g, cor.b, 0.12), cor, 3, 8))
	var margin: MarginContainer = _margin(16)
	zona.add_child(margin)
	var label: Label = _label(titulo, 32, cor, FONTE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(label)
	return zona


func _overlay(titulo: String, cor: Color) -> PanelContainer:
	var painel: PanelContainer = PanelContainer.new()
	painel.custom_minimum_size = Vector2(700, 430)
	painel.set_anchors_preset(Control.PRESET_CENTER)
	painel.add_theme_stylebox_override("panel", _stylebox(COR_PAPEL, cor, 4, 10))
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	painel.add_child(vbox)
	var label: Label = _label(titulo, 34, COR_TINTA, FONTE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	add_child(painel)
	return painel


func _botao(texto: String, cor: Color) -> Button:
	var botao: Button = Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(190, 58)
	botao.add_theme_font_override("font", FONTE)
	botao.add_theme_font_size_override("font_size", 22)
	botao.add_theme_color_override("font_color", Color("#fff4dd"))
	botao.add_theme_color_override("font_hover_color", Color("#0b0b0d"))
	botao.add_theme_stylebox_override("normal", _stylebox(Color("#222029"), cor, 2, 6))
	botao.add_theme_stylebox_override("hover", _stylebox(cor, cor, 2, 6))
	botao.add_theme_stylebox_override("pressed", _stylebox(cor.darkened(0.12), cor, 2, 6))
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return botao


func _label(texto: String, tamanho: int, cor: Color, fonte: Font) -> Label:
	var label: Label = Label.new()
	label.text = texto
	label.add_theme_font_override("font", fonte)
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _card_style() -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = TEX_LIVRO
	style.texture_margin_left = 90
	style.texture_margin_right = 90
	style.texture_margin_top = 90
	style.texture_margin_bottom = 90
	return style


func _stylebox(bg_color: Color, border: Color, largura: int, raio: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border
	for prop in ["border_width_left", "border_width_top", "border_width_right", "border_width_bottom"]:
		style.set(prop, largura)
	for prop in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		style.set(prop, raio)
	return style


func _margin(valor: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	for prop in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(prop, valor)
	return margin
