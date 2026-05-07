extends Control

# === RECURSOS ===
const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const TEX_LIVRO = preload("res://ASSETS/SPRITES/PROPS/LivroAberto.png")

# === DADOS ===
const TODAS_PAGINAS = [
	{"texto": "Todo cidadão tem direito à educação gratuita e de qualidade.", "resposta": "direito", "adulterada": false, "explicacao": "A educação é um direito fundamental garantido pela Constituição."},
	{"texto": "É dever do cidadão votar nas eleições e participar da vida política.", "resposta": "dever", "adulterada": false, "explicacao": "Participar da vida política é um dever cívico de todo cidadão."},
	{"texto": "O governo pode censurar qualquer informação que julgue perigosa para a ordem pública.", "resposta": "adulterada", "adulterada": true, "explicacao": "⚠ VERSÃO ADULTERADA! A liberdade de informação é um direito fundamental."},
	{"texto": "Todo cidadão tem direito à liberdade de expressão e manifestação pacífica.", "resposta": "direito", "adulterada": false, "explicacao": "A liberdade de expressão é um pilar fundamental da democracia."},
	{"texto": "É dever do cidadão respeitar e preservar o patrimônio público e comunitário.", "resposta": "dever", "adulterada": false, "explicacao": "Preservar o patrimônio público é responsabilidade de todos os cidadãos."},
	{"texto": "O Estado tem o dever de garantir saúde, moradia e segurança a todos os cidadãos.", "resposta": "direito", "adulterada": false, "explicacao": "Saúde, moradia e segurança são direitos sociais garantidos pelo Estado."},
	{"texto": "Cidadãos que discordarem do governo devem ser realocados para zonas de trabalho forçado.", "resposta": "adulterada", "adulterada": true, "explicacao": "⚠ VERSÃO ADULTERADA! Nenhum cidadão pode ser punido por discordar do governo."},
	{"texto": "É dever do cidadão pagar impostos para financiar serviços públicos coletivos.", "resposta": "dever", "adulterada": false, "explicacao": "O pagamento de impostos é um dever que sustenta os serviços públicos."},
	{"texto": "Todo cidadão tem direito a um julgamento justo e à presunção de inocência.", "resposta": "direito", "adulterada": false, "explicacao": "O direito a um julgamento justo é garantia fundamental do Estado de Direito."},
	{"texto": "O regime tem autoridade para suspender eleições em períodos de instabilidade social.", "resposta": "adulterada", "adulterada": true, "explicacao": "⚠ VERSÃO ADULTERADA! Eleições são direito inalienável do povo."}
]
const MAX_ERROS = 3

# === CORES ===
const COR_PAPEL = Color("#F4E4BC")
const COR_TEXTO = Color("#3A2A1A")
const COR_BORDA = Color("#8B5A2B")
const COR_FUNDO = Color("#0A0A0C")

# === ESTADO ===
var paginas: Array = []
var idx: int = 0
var acertos: int = 0
var erros: int = 0
var arrastando := false
var pos_orig: Vector2
var timer_seg: float = 0.0
var aguardando := false
var ativo := false
var confianca_ini: int = 0

# === NÓS (criados por código) ===
var fundo: ColorRect
var hud: Panel
var lbl_erros: Label
var lbl_progresso: Label
var lbl_timer: Label
var zona_esq: Control
var zona_dir: Control
var zona_baixo: Control
var card_container: Control
var card: PanelContainer
var lbl_card: Label
var lbl_feedback: Label
var painel_explicacao: PanelContainer
var lbl_explicacao: Label
var btn_direito: Button
var btn_dever: Button
var btn_adulterada: Button
var painel_overlay: PanelContainer

func _ready():
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false
	confianca_ini = GameState.confianca
	_construir_ui()
	_mostrar_intro()

# ══════════════════════════════════════════════
#  CONSTRUÇÃO DA UI (substitui a .tscn)
# ══════════════════════════════════════════════

func _construir_ui():
	# Fundo
	fundo = ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(PRESET_FULL_RECT)
	add_child(fundo)

	# HUD superior
	hud = Panel.new()
	hud.set_anchors_preset(PRESET_TOP_WIDE)
	hud.offset_bottom = 90
	var hud_sb = StyleBoxFlat.new()
	hud_sb.bg_color = COR_PAPEL
	hud_sb.border_width_bottom = 4
	hud_sb.border_color = COR_BORDA
	hud.add_theme_stylebox_override("panel", hud_sb)
	add_child(hud)

	lbl_erros = _label("ERROS: 0/3", 18, Color("#B22222"))
	lbl_erros.offset_left = 30; lbl_erros.offset_top = 15
	lbl_erros.offset_right = 300; lbl_erros.offset_bottom = 50
	hud.add_child(lbl_erros)

	lbl_progresso = _label("PÁGINA: 0/10", 16, COR_TEXTO)
	lbl_progresso.set_anchors_preset(PRESET_CENTER_TOP)
	lbl_progresso.offset_left = -200; lbl_progresso.offset_right = 200
	lbl_progresso.offset_top = 10; lbl_progresso.offset_bottom = 40
	lbl_progresso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(lbl_progresso)

	lbl_timer = _label("", 16, Color("#AA6600"))
	lbl_timer.set_anchors_preset(PRESET_CENTER_TOP)
	lbl_timer.offset_left = -200; lbl_timer.offset_right = 200
	lbl_timer.offset_top = 45; lbl_timer.offset_bottom = 75
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(lbl_timer)

	# Zonas laterais
	zona_esq = _criar_zona(0.0, 0.1, "⬅ DIREITO", Color(0, 0.6, 0.9, 0.2))
	zona_dir = _criar_zona(0.9, 1.0, "DEVER ➡", Color(1, 0.45, 0.1, 0.2))
	zona_baixo = _criar_zona_baixo()

	# Card central
	card_container = Control.new()
	card_container.set_anchors_preset(PRESET_CENTER)
	card_container.offset_left = -350; card_container.offset_right = 350
	card_container.offset_top = -200; card_container.offset_bottom = 230
	card_container.grow_horizontal = GROW_DIRECTION_BOTH
	card_container.grow_vertical = GROW_DIRECTION_BOTH
	add_child(card_container)

	card = PanelContainer.new()
	card.custom_minimum_size = Vector2(700, 480)
	card.set_anchors_preset(PRESET_FULL_RECT)
	var card_sb = StyleBoxTexture.new()
	card_sb.texture = TEX_LIVRO
	for prop in ["texture_margin_left","texture_margin_right","texture_margin_top","texture_margin_bottom"]:
		card_sb.set(prop, 90)
	card.add_theme_stylebox_override("panel", card_sb)
	card_container.add_child(card)

	lbl_card = Label.new()
	lbl_card.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_card.add_theme_font_override("font", FONTE)
	lbl_card.add_theme_font_size_override("font_size", 24)
	lbl_card.add_theme_color_override("font_color", Color("#111111"))
	card.add_child(lbl_card)

	# Botões abaixo do card
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(PRESET_BOTTOM_WIDE)
	hbox.offset_top = -80
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	card_container.add_child(hbox)

	btn_direito = _btn("[DIREITO]", Color(0, 0.6, 0.9))
	btn_dever = _btn("[DEVER]", Color(1, 0.45, 0))
	btn_adulterada = _btn("[ REJEITAR ]", Color(0.7, 0.3, 1))
	btn_adulterada.custom_minimum_size.x = 260
	hbox.add_child(btn_direito)
	hbox.add_child(btn_dever)
	hbox.add_child(btn_adulterada)
	btn_direito.pressed.connect(func(): _avaliar("direito"))
	btn_dever.pressed.connect(func(): _avaliar("dever"))
	btn_adulterada.pressed.connect(func(): _avaliar("adulterada"))

	# Feedback
	lbl_feedback = _label("", 28, COR_PAPEL)
	lbl_feedback.set_anchors_preset(PRESET_CENTER_TOP)
	lbl_feedback.offset_left = -400; lbl_feedback.offset_right = 400
	lbl_feedback.offset_top = 100; lbl_feedback.offset_bottom = 150
	lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_feedback.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl_feedback.add_theme_constant_override("outline_size", 4)
	add_child(lbl_feedback)

	# Explicação
	painel_explicacao = PanelContainer.new()
	painel_explicacao.visible = false
	painel_explicacao.set_anchors_preset(PRESET_BOTTOM_WIDE)
	painel_explicacao.offset_left = 150; painel_explicacao.offset_right = -150
	painel_explicacao.offset_top = -140; painel_explicacao.offset_bottom = -20
	var exp_sb = _stylebox(COR_PAPEL, COR_BORDA, 3, 5)
	painel_explicacao.add_theme_stylebox_override("panel", exp_sb)
	add_child(painel_explicacao)

	lbl_explicacao = Label.new()
	lbl_explicacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_explicacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_explicacao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_explicacao.add_theme_font_override("font", FONTE)
	lbl_explicacao.add_theme_font_size_override("font_size", 20)
	lbl_explicacao.add_theme_color_override("font_color", COR_TEXTO)
	painel_explicacao.add_child(lbl_explicacao)

	pos_orig = card_container.position

# === HELPERS DE UI ===

func _label(txt: String, sz: int, cor: Color) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", cor)
	return l

func _btn(txt: String, cor: Color) -> Button:
	var b = Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(180, 60)
	b.add_theme_font_override("font", FONTE)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", COR_TEXTO)
	var sb = _stylebox(Color("#D4C49C"), COR_BORDA, 2, 5)
	b.add_theme_stylebox_override("normal", sb)
	var hover = _stylebox(cor, cor, 2, 5)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	return b

func _stylebox(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	for p in ["border_width_left","border_width_top","border_width_right","border_width_bottom"]:
		sb.set(p, bw)
	sb.border_color = border
	for p in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		sb.set(p, cr)
	return sb

func _criar_zona(anchor_l: float, anchor_r: float, txt: String, cor: Color) -> Control:
	var z = Control.new()
	z.anchor_left = anchor_l; z.anchor_right = anchor_r
	z.anchor_top = 0.12; z.anchor_bottom = 0.95
	z.offset_left = 10; z.offset_right = -10
	z.modulate = cor
	add_child(z)
	var p = Panel.new()
	p.set_anchors_preset(PRESET_FULL_RECT)
	z.add_child(p)
	var lbl = _label(txt, 36, Color.WHITE)
	lbl.set_anchors_preset(PRESET_CENTER)
	lbl.offset_left = -100; lbl.offset_right = 100
	lbl.offset_top = -25; lbl.offset_bottom = 25
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	z.add_child(lbl)
	return z

func _criar_zona_baixo() -> Control:
	var z = Control.new()
	z.set_anchors_preset(PRESET_BOTTOM_WIDE)
	z.offset_top = -250
	z.modulate = Color(0.8, 0.2, 0.2, 0.0)
	add_child(z)
	var lbl = _label("⬇ DESCARTAR FALSO ⬇", 36, Color.WHITE)
	lbl.set_anchors_preset(PRESET_CENTER_BOTTOM)
	lbl.offset_bottom = -100
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	z.add_child(lbl)
	return z

func _criar_painel_overlay(titulo_txt: String, cor_titulo: Color) -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(600, 400)
	p.set_anchors_preset(PRESET_CENTER)
	p.grow_horizontal = GROW_DIRECTION_BOTH
	p.grow_vertical = GROW_DIRECTION_BOTH
	p.add_theme_stylebox_override("panel", _stylebox(COR_PAPEL, COR_BORDA, 4, 10))
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	p.add_child(vbox)
	var t = _label(titulo_txt, 32, cor_titulo)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(t)
	add_child(p)
	return p

# ══════════════════════════════════════════════
#  LÓGICA DO JOGO
# ══════════════════════════════════════════════

func _mostrar_intro():
	card_container.visible = false
	painel_explicacao.visible = false
	lbl_feedback.text = ""

	painel_overlay = _criar_painel_overlay("ANÁLISE DE DOCUMENTOS", COR_TEXTO)
	var vbox = painel_overlay.get_child(0)
	var desc = _label("Arraste para ESQUERDA os Direitos.\nArraste para DIREITA os Deveres.\nArraste para BAIXO as páginas falsas.\n\nVocê só pode errar 3 vezes.", 20, COR_TEXTO)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)
	var b = _btn("COMEÇAR ANÁLISE", COR_BORDA)
	b.size_flags_horizontal = SIZE_SHRINK_CENTER
	b.pressed.connect(func():
		painel_overlay.queue_free()
		_iniciar_rodada()
	)
	vbox.add_child(b)

func _iniciar_rodada():
	card_container.visible = true
	ativo = true
	paginas = TODAS_PAGINAS.duplicate()
	paginas.shuffle()
	idx = 0; acertos = 0; erros = 0; aguardando = false
	lbl_erros.text = "ERROS: 0/" + str(MAX_ERROS)
	_carregar_pagina(0)

func _carregar_pagina(i: int):
	if i >= paginas.size():
		_mostrar_resultado(true)
		return
	var p = paginas[i]
	lbl_card.text = p["texto"]
	lbl_progresso.text = "PÁGINA: " + str(i + 1) + "/" + str(paginas.size())
	lbl_erros.text = "ERROS: " + str(erros) + "/" + str(MAX_ERROS)

	card_container.position = pos_orig + Vector2(0, 500)
	card_container.modulate.a = 0.0
	card_container.rotation = 0.0
	card_container.scale = Vector2.ONE
	var tw = create_tween().set_parallel(true)
	tw.tween_property(card_container, "position", pos_orig, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_container, "modulate:a", 1.0, 0.4)

	lbl_feedback.text = "Lendo..."
	lbl_feedback.add_theme_color_override("font_color", COR_PAPEL)
	painel_explicacao.visible = false
	aguardando = false
	timer_seg = 30.0
	lbl_timer.visible = true

func _process(delta):
	if not ativo or aguardando: return

	# Timer
	timer_seg -= delta
	lbl_timer.text = "TEMPO: " + str(int(timer_seg)) + "s"
	if timer_seg <= 5.0:
		var piscar = (Time.get_ticks_msec() % 500) > 250
		lbl_timer.add_theme_color_override("font_color", Color("#FF3333") if piscar else COR_TEXTO)
	else:
		lbl_timer.add_theme_color_override("font_color", Color("#AA6600"))
	if timer_seg <= 0:
		_avaliar("timeout")
		return

	# Arrastar
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mp = get_global_mouse_position()
		if card_container.get_global_rect().has_point(mp) or arrastando:
			arrastando = true
			card_container.global_position = mp - card_container.size / 2.0
			var ox = card_container.position.x - pos_orig.x
			card_container.rotation = lerp(card_container.rotation, deg_to_rad(ox / 15.0), 0.2)
			var oy = card_container.position.y - pos_orig.y
			card_container.scale = Vector2.ONE * (1.0 - clamp(oy / 1000.0, 0.0, 0.3)) if oy > 0 else Vector2.ONE

			var centro = card_container.global_position + card_container.size / 2.0
			zona_esq.modulate.a = 0.6 if zona_esq.get_global_rect().has_point(centro) else 0.2
			zona_dir.modulate.a = 0.6 if zona_dir.get_global_rect().has_point(centro) else 0.2
			zona_baixo.modulate.a = 0.6 if zona_baixo.get_global_rect().has_point(centro) else 0.0
	elif arrastando:
		arrastando = false
		var centro = card_container.global_position + card_container.size / 2.0
		if zona_baixo.get_global_rect().has_point(centro): _avaliar("adulterada")
		elif zona_esq.get_global_rect().has_point(centro): _avaliar("direito")
		elif zona_dir.get_global_rect().has_point(centro): _avaliar("dever")
		else: _voltar_centro()
		zona_esq.modulate.a = 0.2; zona_dir.modulate.a = 0.2; zona_baixo.modulate.a = 0.0

func _voltar_centro():
	var tw = create_tween().set_parallel(true)
	tw.tween_property(card_container, "position", pos_orig, 0.4).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_container, "rotation", 0.0, 0.3)
	tw.tween_property(card_container, "scale", Vector2.ONE, 0.3)

func _avaliar(escolha: String):
	if aguardando: return
	aguardando = true; arrastando = false
	var p = paginas[idx]

	if escolha == "timeout":
		erros += 1; GameState.confianca -= 1
		GameState.registrar_escolha("Timeout na análise", -1)
		_feedback(false, "TEMPO ESGOTADO!")
	elif p["adulterada"] and escolha == "adulterada":
		acertos += 1; GameState.confianca += 2
		GameState.registrar_escolha("Identificou página falsa", +2)
		_feedback(true, "DESCARTADO COM SUCESSO")
	elif not p["adulterada"] and escolha == p["resposta"]:
		acertos += 1; GameState.confianca += 1
		GameState.registrar_escolha("Classificou " + escolha, +1)
		_feedback(true, "CLASSIFICAÇÃO CORRETA")
	elif p["adulterada"] and escolha != "adulterada":
		erros += 1; GameState.confianca -= 2
		GameState.registrar_escolha("Aprovou página falsa!", -2)
		_feedback(false, "PÁGINA ADULTERADA APROVADA!")
	else:
		erros += 1; GameState.confianca -= 1
		GameState.registrar_escolha("Erro de classificação", -1)
		_feedback(false, "CLASSIFICAÇÃO INCORRETA")

	painel_explicacao.visible = true
	lbl_explicacao.text = p["explicacao"]
	painel_explicacao.modulate.a = 0.0
	create_tween().tween_property(painel_explicacao, "modulate:a", 1.0, 0.3)
	lbl_erros.text = "ERROS: " + str(erros) + "/" + str(MAX_ERROS)

	# Animação de saída
	var offset = Vector2.ZERO; var ang = 0; var sc = 1.0
	match escolha:
		"direito": offset = Vector2(-1500, 0); ang = -45
		"dever": offset = Vector2(1500, 0); ang = 45
		"adulterada": offset = Vector2(0, 1000); sc = 0.2
		_: offset = Vector2(0, 1000)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(card_container, "position", card_container.position + offset, 0.6)
	tw.tween_property(card_container, "modulate:a", 0.0, 0.5)
	tw.tween_property(card_container, "rotation", deg_to_rad(ang), 0.6)
	tw.tween_property(card_container, "scale", Vector2(sc, sc), 0.6)

	if erros >= MAX_ERROS:
		await get_tree().create_timer(1.5).timeout
		_mostrar_resultado(false)
		return
	await get_tree().create_timer(1.2).timeout
	idx += 1
	_carregar_pagina(idx)

func _feedback(ok: bool, txt: String):
	lbl_feedback.text = txt
	lbl_feedback.add_theme_color_override("font_color", Color("#00FF88") if ok else Color("#FF4444"))
	if not ok:
		var p0 = position
		var tw = create_tween()
		for i in 6:
			tw.tween_property(self, "position", p0 + Vector2(randf_range(-10,10), randf_range(-10,10)), 0.05)
		tw.tween_property(self, "position", p0, 0.05)

func _mostrar_resultado(concluiu: bool):
	ativo = false
	painel_explicacao.visible = false
	card_container.visible = false
	var titulo = "ANÁLISE CONCLUÍDA" if concluiu else "ANÁLISE INTERROMPIDA"
	var cor = Color("#228B22") if concluiu else Color("#B22222")
	painel_overlay = _criar_painel_overlay(titulo, cor)
	var vbox = painel_overlay.get_child(0)
	if concluiu:
		var d = _label("Páginas validadas: " + str(acertos) + "\nErros: " + str(erros) + "\n\nA confiança foi impactada.", 20, COR_TEXTO)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(d)
		var b = _btn("CONTINUAR", Color("#228B22"))
		b.size_flags_horizontal = SIZE_SHRINK_CENTER
		b.pressed.connect(_finalizar)
		vbox.add_child(b)
	else:
		var b = _btn("TENTAR NOVAMENTE", Color("#B22222"))
		b.size_flags_horizontal = SIZE_SHRINK_CENTER
		b.pressed.connect(func():
			painel_overlay.queue_free()
			GameState.confianca = confianca_ini
			_iniciar_rodada()
		)
		vbox.add_child(b)

func _finalizar():
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = true
	GameState.acertos_paginas_fase1 = acertos
	if GameState.fase_atual == 1: GameState.fase_atual = 2
	FadeManager.carregar_cena("res://ASSETS/CENAS/game_scene.tscn")
