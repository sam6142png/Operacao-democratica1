extends Control

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const FONTE_MONO = preload("res://ASSETS/FONTES/dogicapixel.ttf")


func _ready() -> void:
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.2)
	_criar_interface()


func _get_ranking() -> Dictionary:
	var resultado: String = GameState.resultado_final
	if resultado == "democratica":
		return {
			"titulo": "RECONSTRUCAO DEMOCRATICA",
			"cor": Color("#22ff70"),
			"desc": "Voce venceu sem vinganca: restaurou justica, memoria e participacao popular."
		}
	if resultado == "institucional":
		return {
			"titulo": "VITORIA INSTITUCIONAL",
			"cor": Color("#ffe28a"),
			"desc": "O regime caiu e a cidade escolheu reconstruir suas instituicoes."
		}
	if resultado == "vingativa":
		return {
			"titulo": "VITORIA FERIDA",
			"cor": Color("#ff4b4b"),
			"desc": "O lider caiu, mas a vinganca mostrou que democracia precisa de limites e principios."
		}
	if resultado == "fragil":
		return {
			"titulo": "DEMOCRACIA FRAGIL",
			"cor": Color("#ff9f2f"),
			"desc": "A cidade evitou o pior, mas deixou feridas politicas abertas."
		}
	if resultado == "derrota":
		return {
			"titulo": "RESISTENCIA ADIADA",
			"cor": Color("#ff4b4b"),
			"desc": "O regime manteve controle da transmissao. A consciencia popular ainda precisa crescer."
		}
	var conf: int = GameState.confianca
	if conf >= 12:
		return {"titulo": "CIDADAO ATIVO", "cor": Color("#22ff55"), "desc": "Voce agiu para mudar a realidade. Sua coragem inspira outros."}
	if conf >= 6:
		return {"titulo": "RESISTENCIA CONSCIENTE", "cor": Color("#ff8c00"), "desc": "Voce entende os riscos e agiu sem perder seus principios."}
	return {"titulo": "CIDADAO OBSERVADOR", "cor": Color("#ff2222"), "desc": "A prudencia guiou seus passos. As vezes sobreviver tambem e resistencia."}


func _criar_interface() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color("#050508")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(1080, 720)
	panel.add_theme_stylebox_override("panel", _stylebox(_ca("#0d0b12", 0.98), Color("#ffe28a"), 4, 8))
	center.add_child(panel)

	var margin: MarginContainer = _margin(42)
	panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var titulo: Label = _label("OPERACAO DEMOCRATICA", 46, Color("#ffe28a"), FONTE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)

	var subtitulo: Label = _label("A cidade ouviu a transmissao final", 24, Color("#d7c9aa"), FONTE)
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitulo)

	var stats: HBoxContainer = HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 28)
	vbox.add_child(stats)
	_criar_stat(stats, "Confianca", str(GameState.confianca))
	_criar_stat(stats, "Popular", str(GameState.pontuacao_final.get("popular", 0)))
	_criar_stat(stats, "Regime", str(GameState.pontuacao_final.get("regime", 0)))
	_criar_stat(stats, "Cartas", str(GameState.cartas_final_desbloqueadas.size()))

	var rank: Dictionary = _get_ranking()
	var rank_label: Label = _label("RESULTADO FINAL", 22, Color("#8f8875"), FONTE_MONO)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rank_label)

	var rank_titulo: Label = _label(str(rank["titulo"]), 50, rank["cor"] as Color, FONTE)
	rank_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(rank_titulo)

	var desc: Label = _label(str(rank["desc"]), 24, Color("#f5ead7"), FONTE)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(860, 0)
	vbox.add_child(desc)

	var rota: Label = _label(_texto_rota(), 21, Color("#d7c9aa"), FONTE)
	rota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rota.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(rota)

	_criar_secao_registros(vbox)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	_criar_botao(vbox, "VOLTAR AO MENU PRINCIPAL", func():
		FadeManager.carregar_cena("res://title_screen.tscn")
	)


func _texto_rota() -> String:
	match GameState.resultado_final:
		"democratica":
			return "Melhor rota: julgamento com instituicoes, provas e participacao. Democracia nao e vinganca."
		"institucional":
			return "Boa rota: a prisao abre caminho para reconstruir leis e freios ao poder."
		"fragil":
			return "Rota fragil: o exilio evita violencia, mas nao resolve memoria e justica."
		"vingativa":
			return "Rota de alerta: vencer usando vinganca enfraquece o ideal democratico."
		"derrota":
			return "Rota de resistencia: a luta continua quando a consciencia popular ainda nao venceu o medo."
	return "A jornada mostrou que direitos dependem de participacao, memoria e coragem coletiva."


func _criar_stat(parent: Control, label_txt: String, valor_txt: String) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(150, 86)
	parent.add_child(box)
	var lbl: Label = _label(label_txt, 17, Color("#8f8875"), FONTE_MONO)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lbl)
	var val: Label = _label(valor_txt, 32, Color("#fff4d6"), FONTE)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(val)


func _criar_secao_registros(parent: VBoxContainer) -> void:
	if GameState.registros_democraticos.is_empty():
		return

	var titulo: Label = _label("APRENDIZADOS DA JORNADA", 18, Color("#8f8875"), FONTE_MONO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(titulo)

	var grid: GridContainer = GridContainer.new()
	grid.columns = int(min(3, GameState.registros_democraticos.size()))
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)

	for registro in GameState.registros_democraticos:
		if typeof(registro) == TYPE_DICTIONARY:
			grid.add_child(_criar_card_registro(registro))


func _criar_card_registro(registro: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(285, 150)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _stylebox(_ca("#151820", 0.94), Color("#54d6ff", 0.75), 2, 6))

	var margin: MarginContainer = _margin(12)
	card.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var fase: Label = _label(str(registro.get("fase", "")).to_upper(), 13, Color("#54d6ff"), FONTE_MONO)
	fase.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(fase)

	var conceito: Label = _label(str(registro.get("conceito", "")), 17, Color("#fff4d6"), FONTE)
	conceito.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(conceito)

	var impacto: Label = _label(str(registro.get("impacto", "")), 15, Color("#d7c9aa"), FONTE)
	impacto.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(impacto)

	return card


func _criar_botao(parent: Control, texto: String, acao: Callable) -> void:
	var btn: Button = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(420, 60)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 23)
	btn.add_theme_color_override("font_color", Color("#21180f"))
	btn.add_theme_stylebox_override("normal", _stylebox(Color("#ffe28a"), Color("#2b2118"), 3, 6))
	btn.add_theme_stylebox_override("hover", _stylebox(Color("#fff4d6"), Color("#ffe28a"), 3, 6))
	btn.pressed.connect(acao)
	parent.add_child(btn)


func _label(texto: String, tamanho: int, cor: Color, fonte: Font) -> Label:
	var lbl: Label = Label.new()
	lbl.text = texto
	lbl.add_theme_font_override("font", fonte)
	lbl.add_theme_font_size_override("font_size", tamanho)
	lbl.add_theme_color_override("font_color", cor)
	return lbl


func _margin(valor: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", valor)
	margin.add_theme_constant_override("margin_right", valor)
	margin.add_theme_constant_override("margin_top", valor)
	margin.add_theme_constant_override("margin_bottom", valor)
	return margin


func _ca(code: String, alpha: float) -> Color:
	var color: Color = Color(code)
	color.a = alpha
	return color


func _stylebox(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_width
	sb.border_width_top = border_width
	sb.border_width_right = border_width
	sb.border_width_bottom = border_width
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
