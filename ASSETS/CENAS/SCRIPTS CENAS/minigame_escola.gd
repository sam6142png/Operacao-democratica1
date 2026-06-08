extends Control

# ═══════════════════════════════════════════════════════════════
#  MINIGAME ECO DA ESCOLA — REDESENHO CÍVICO
#  Etapa 1: Editor do Pasquim (Diagramação do jornal clandestino)
#  Etapa 2: Persuasão Socrática (Desmobilizar a doutrinação no pátio)
# ═══════════════════════════════════════════════════════════════

const FONTE      = preload("res://ASSETS/FONTES/determination.ttf")
const FONTE_MONO = preload("res://ASSETS/FONTES/dogicapixel.ttf")
const BG_TEX     = preload("res://ASSETS/SPRITES/FUNDOS/Sala de Aula.png")

# Audio Streams
const CLICK_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesClick.mp3")
const HOVER_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesHover.mp3")
const ERRO_SOUND  = preload("res://ASSETS/SOUNDS/FSX/SlideMenu.mp3")

# Cores do Tema Cívico-Retrô
const COR_BG_OVERLAY  := Color(0.04, 0.04, 0.05, 0.88)
const COR_PANEL_BG    := Color(0.06, 0.06, 0.09, 0.96)
const COR_PANEL_BORDA := Color(0.0,  0.64, 1.0,  0.8) # Azul Cívico

const COR_GREEN_FILL  := Color(0.0,  0.85, 0.35, 1.0)
const COR_GREEN_BG    := Color(0.0,  0.85, 0.35, 0.14)
const COR_RED_FILL    := Color(0.95, 0.2,  0.2,  1.0)
const COR_RED_BG      := Color(0.95, 0.2,  0.2,  0.14)

const COR_TEXT_PRI    := Color(1.0,  1.0,  1.0,  1.0)
const COR_TEXT_SEC    := Color(0.84, 0.79, 0.67, 1.0)
const COR_TEXT_TER    := Color(0.56, 0.53, 0.46, 1.0)

# ==========================================
# ESTADO GERAL DO MINIGAME
# ==========================================
var etapa_atual: int = 1 # 1 = Editor de Jornal, 2 = Persuasão
var finalizado := false
var sfx_click: AudioStreamPlayer
var sfx_hover: AudioStreamPlayer
var sfx_erro: AudioStreamPlayer

# Camada Principal de UI
var layer: CanvasLayer

# ==========================================
# DADOS DO EDITOR DO PASQUIM
# ==========================================
var manchete_selecionada: int = -1
var charge_selecionada: int = -1
var relato_selecionado: int = -1

const MANCHETES := [
	{"id": 0, "texto": "A Verdade Sobre o Grande Apagão de 2006", "impacto": 35, "risco": 25, "desc": "Revela o corte intencional de energia do Coronel.", "tema": "apagao"},
	{"id": 1, "texto": "Prefeito Dantas: O Legado de Liberdade Silenciado", "impacto": 40, "risco": 30, "desc": "Homenageia o antigo prefeito e sua constituição.", "tema": "historia"},
	{"id": 2, "texto": "Reflexões Cívicas na Sala de Aula", "impacto": 15, "risco": 5, "desc": "Artigo moderado pedindo mais debates livres.", "tema": "escola"},
	{"id": 3, "texto": "Protestos Estudantis nos Pátios", "impacto": 25, "risco": 15, "desc": "Documenta a união do grêmio estudantil.", "tema": "escola"}
]

const CHARGES := [
	{"id": 0, "texto": "O Coronel Antônio Controlando as Mentes", "impacto": 35, "risco": 35, "desc": "Desenho satírico do ditador como titereiro.", "tema": "historia"},
	{"id": 1, "texto": "Fusíveis Rompidos da Censura na Escola", "impacto": 20, "risco": 15, "desc": "Metáfora visual da rádio livre invadindo o sinal.", "tema": "apagao"},
	{"id": 2, "texto": "Estudantes de Mãos Dadas Pela Verdade", "impacto": 15, "risco": 8, "desc": "Representação pacífica da resistência.", "tema": "escola"}
]

const RELATOS := [
	{"id": 0, "texto": "Relato do Peixeiro: 'Meu irmão sumiu na usina'", "impacto": 35, "risco": 30, "desc": "Testemunho cru sobre repressões passadas.", "tema": "apagao"},
	{"id": 1, "texto": "Relato do Professor: 'Estamos sob mordaça'", "impacto": 30, "risco": 25, "desc": "O drama de lecionar sob a mira do exército.", "tema": "escola"},
	{"id": 2, "texto": "Estudantes: 'Queremos livros reais, não propaganda'", "impacto": 20, "risco": 10, "desc": "Manifesto por educação livre e não tendenciosa.", "tema": "historia"}
]

# UI Editor
var panel_editor: PanelContainer
var draw_preview: Control
var bar_impacto: ProgressBar
var bar_risco: ProgressBar
var lbl_risco_alerta: Label
var lbl_sinergia: Label

# Sinergias e métricas do jornal transportadas para a persuasão
var sinergia_ativa: String = ""
var jornal_impacto: float = 0.0
var jornal_risco: float = 0.0

# ==========================================
# DADOS DA PERSUASÃO SOCRÁTICA
# ==========================================
var doutrinacao_estudante: float = 100.0
var alerta_militar: float = 0.0
var rodadas_restantes: int = 5
var argumento_estudante_id: int = 0
var argumentos_rodada: Array = []

const ARGUMENTOS_ESTUDANTE := [
	{"id": 0, "texto": "\"O Coronel nos protege do caos e da desordem. Sem ele, a cidade morre.\"", "defesa": "ordem"},
	{"id": 1, "texto": "\"Nossos livros de história dizem que as eleições antigas eram todas corrompidas.\"", "defesa": "livro"},
	{"id": 2, "texto": "\"Se eu questionar ou ler coisas proibidas, serei punido. Tenho medo.\"", "defesa": "medo"},
	{"id": 3, "texto": "\"Pelo menos a usina funciona e há comida. Para que arriscar com política?\"", "defesa": "seguranca"}
]

# UI Persuasão
var panel_persuasao: PanelContainer
var lbl_dialogo_estudante: Label
var lbl_rodadas: Label
var bar_doutrinacao: ProgressBar
var bar_alerta: ProgressBar
var cards_container: HBoxContainer
var lbl_persuasao_status: Label

# ==========================================
# INICIALIZAÇÃO
# ==========================================
func _ready() -> void:
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false
		
	argumentos_rodada = ARGUMENTOS_ESTUDANTE.duplicate()
	argumentos_rodada.shuffle()
	
	_configurar_audio()
	_construir_ui()

func _configurar_audio() -> void:
	sfx_click = AudioStreamPlayer.new()
	sfx_click.stream = CLICK_SOUND
	sfx_click.bus = "SFX"
	add_child(sfx_click)
	
	sfx_hover = AudioStreamPlayer.new()
	sfx_hover.stream = HOVER_SOUND
	sfx_hover.bus = "SFX"
	add_child(sfx_hover)
	
	sfx_erro = AudioStreamPlayer.new()
	sfx_erro.stream = ERRO_SOUND
	sfx_erro.bus = "SFX"
	add_child(sfx_erro)

func _play(player: AudioStreamPlayer, pitch: float = 1.0) -> void:
	if player:
		player.pitch_scale = pitch
		player.play()

# ==========================================
# CONSTRUÇÃO DA UI DINÂMICA
# ==========================================
func _construir_ui() -> void:
	layer = CanvasLayer.new()
	add_child(layer)
	
	# Background
	var bg = TextureRect.new()
	if BG_TEX:
		bg.texture = BG_TEX
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.modulate = Color(0.4, 0.4, 0.45) # Escurece a sala de aula
	layer.add_child(bg)
	
	# Overlay escurecido
	var overlay = ColorRect.new()
	overlay.color = COR_BG_OVERLAY
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	layer.add_child(overlay)
	
	# Grid de efeito tecnológico
	var bg_grid = Control.new()
	bg_grid.set_anchors_preset(PRESET_FULL_RECT)
	bg_grid.modulate = Color(0.0, 0.5, 1.0, 0.02)
	bg_grid.draw.connect(func():
		var step = 40
		var grid_size = bg_grid.size
		for x in range(0, int(grid_size.x), step):
			bg_grid.draw_line(Vector2(x, 0), Vector2(x, grid_size.y), Color.WHITE, 1.0)
		for y in range(0, int(grid_size.y), step):
			bg_grid.draw_line(Vector2(0, y), Vector2(grid_size.x, y), Color.WHITE, 1.0)
	)
	layer.add_child(bg_grid)
	
	# ---------------------------------------------
	# TELA DA ETAPA 1: EDITOR DO PASQUIM
	# ---------------------------------------------
	_criar_layout_editor()
	
	# ---------------------------------------------
	# TELA DA ETAPA 2: PERSUASÃO SOCRÁTICA (Inicialmente escondida)
	# ---------------------------------------------
	_criar_layout_persuasao()
	panel_persuasao.hide()

# ==========================================
# DETALHAMENTO DA ETAPA 1: EDITOR
# ==========================================
func _criar_layout_editor() -> void:
	panel_editor = PanelContainer.new()
	panel_editor.custom_minimum_size = Vector2(1100, 680)
	panel_editor.set_anchors_preset(PRESET_CENTER)
	panel_editor.grow_horizontal = GROW_DIRECTION_BOTH
	panel_editor.grow_vertical = GROW_DIRECTION_BOTH
	panel_editor.add_theme_stylebox_override("panel", _stylebox(COR_PANEL_BG, COR_PANEL_BORDA, 3, 10))
	layer.add_child(panel_editor)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	panel_editor.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	# Título
	var lbl_title = Label.new()
	lbl_title.text = "DIAGRAMADOR DE IMPRENSA CLANDESTINA"
	lbl_title.add_theme_font_override("font", FONTE)
	lbl_title.add_theme_font_size_override("font_size", 32)
	lbl_title.add_theme_color_override("font_color", COR_PANEL_BORDA)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)
	
	# Dividir em colunas: Esquerda (Itens), Direita (Layout Preview)
	var columns = HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	vbox.add_child(columns)
	
	# Coluna Esquerda: Seletor de Blocos
	var col_left = ScrollContainer.new()
	col_left.size_flags_horizontal = SIZE_EXPAND_FILL
	col_left.size_flags_stretch_ratio = 1.3
	columns.add_child(col_left)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 16)
	col_left.add_child(left_vbox)
	
	# Seção 1: Manchetes
	left_vbox.add_child(_label("1. SELECIONE A MANCHETE PRINCIPAL", 16, COR_PANEL_BORDA, FONTE_MONO))
	var grp_manchetes = VBoxContainer.new()
	left_vbox.add_child(grp_manchetes)
	for item in MANCHETES:
		_criar_opcao_seletor(grp_manchetes, item, "manchete")
		
	# Seção 2: Charges
	left_vbox.add_child(_label("2. SELECIONE A CHARGE EDITORIAL", 16, COR_PANEL_BORDA, FONTE_MONO))
	var grp_charges = VBoxContainer.new()
	left_vbox.add_child(grp_charges)
	for item in CHARGES:
		_criar_opcao_seletor(grp_charges, item, "charge")
		
	# Seção 3: Relatos/Testemunhos
	left_vbox.add_child(_label("3. SELECIONE O TESTEMUNHO POPULAR", 16, COR_PANEL_BORDA, FONTE_MONO))
	var grp_relatos = VBoxContainer.new()
	left_vbox.add_child(grp_relatos)
	for item in RELATOS:
		_criar_opcao_seletor(grp_relatos, item, "relato")
		
	# Coluna Direita: O jornal simulado
	var col_right = VBoxContainer.new()
	col_right.size_flags_horizontal = SIZE_EXPAND_FILL
	col_right.add_theme_constant_override("separation", 12)
	columns.add_child(col_right)
	
	col_right.add_child(_label("VISUALIZAÇÃO DA PÁGINA IMPRESSA", 15, COR_TEXT_TER, FONTE_MONO))
	
	draw_preview = Control.new()
	draw_preview.size_flags_vertical = SIZE_EXPAND_FILL
	draw_preview.custom_minimum_size = Vector2(0, 320)
	draw_preview.draw.connect(_desenhar_preview_jornal)
	col_right.add_child(draw_preview)
	
	# Barra de Métricas (Impacto e Risco)
	var metrics_box = HBoxContainer.new()
	metrics_box.add_theme_constant_override("separation", 30)
	vbox.add_child(metrics_box)
	
	# Impacto
	var box_imp = VBoxContainer.new()
	box_imp.size_flags_horizontal = SIZE_EXPAND_FILL
	box_imp.add_child(_label("IMPACTO DE CONSCIENTIZAÇÃO (META >= 50%)", 14, COR_GREEN_FILL, FONTE_MONO))
	bar_impacto = _criar_barra(COR_GREEN_FILL, COR_GREEN_BG)
	box_imp.add_child(bar_impacto)
	metrics_box.add_child(box_imp)
	
	# Risco
	var box_ris = VBoxContainer.new()
	box_ris.size_flags_horizontal = SIZE_EXPAND_FILL
	box_ris.add_child(_label("RISCO DE APREENSÃO MILITAR (LIMITE <= 80%)", 14, COR_RED_FILL, FONTE_MONO))
	bar_risco = _criar_barra(COR_RED_FILL, COR_RED_BG)
	box_ris.add_child(bar_risco)
	metrics_box.add_child(box_ris)
	
	# Linha de Sinergia
	lbl_sinergia = _label("Selecione os blocos do jornal para analisar a coerência cívica.", 14, COR_TEXT_TER, FONTE_MONO)
	vbox.add_child(lbl_sinergia)

	# Alerta e Botão de Publicação
	var bottom_box = HBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 20)
	vbox.add_child(bottom_box)
	
	lbl_risco_alerta = _label("Ajuste o layout do jornal cívico.", 16, COR_TEXT_SEC, FONTE)
	lbl_risco_alerta.size_flags_horizontal = SIZE_EXPAND_FILL
	bottom_box.add_child(lbl_risco_alerta)
	
	var btn_publicar = Button.new()
	btn_publicar.text = " PUBLICAR JORNAL "
	btn_publicar.custom_minimum_size = Vector2(250, 48)
	btn_publicar.add_theme_font_override("font", FONTE)
	btn_publicar.add_theme_font_size_override("font_size", 22)
	btn_publicar.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	btn_publicar.pressed.connect(_tentar_publicar_jornal)
	
	var sb_n = _stylebox(COR_PANEL_BORDA, Color.WHITE, 1, 4)
	var sb_h = _stylebox(Color("#008ae6"), Color.WHITE, 1, 4)
	btn_publicar.add_theme_stylebox_override("normal", sb_n)
	btn_publicar.add_theme_stylebox_override("hover", sb_h)
	btn_publicar.add_theme_stylebox_override("pressed", sb_h)
	bottom_box.add_child(btn_publicar)
	
	_recalcular_metricas()

func _criar_opcao_seletor(parent: Control, item: Dictionary, categoria: String) -> Button:
	var btn = Button.new()
	btn.text = "  " + item["texto"]
	btn.custom_minimum_size = Vector2(0, 36)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 16)
	btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_n = StyleBoxFlat.new()
	sb_n.bg_color = Color(0.08, 0.08, 0.12, 0.8)
	sb_n.border_width_left = 3
	sb_n.border_color = Color("#8c96a6")
	btn.add_theme_stylebox_override("normal", sb_n)
	
	var sb_h = sb_n.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.12, 0.12, 0.18, 0.9)
	sb_h.border_color = COR_PANEL_BORDA
	btn.add_theme_stylebox_override("hover", sb_h)
	
	btn.pressed.connect(func():
		_play(sfx_click, 1.1)
		if categoria == "manchete":
			manchete_selecionada = item["id"]
		elif categoria == "charge":
			charge_selecionada = item["id"]
		elif categoria == "relato":
			relato_selecionado = item["id"]
			
		_atualizar_selecao_botoes(parent, item["id"])
		_recalcular_metricas()
		if draw_preview:
			draw_preview.queue_redraw()
	)
	
	btn.mouse_entered.connect(func(): _play(sfx_hover, 1.0))
	parent.add_child(btn)
	return btn

func _atualizar_selecao_botoes(parent: Control, ativo_id: int) -> void:
	for i in range(parent.get_child_count()):
		var btn = parent.get_child(i) as Button
		if btn:
			var sb = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if i == ativo_id:
				sb.border_color = COR_GREEN_FILL
				sb.bg_color = Color(COR_GREEN_FILL, 0.12)
			else:
				sb.border_color = Color("#8c96a6")
				sb.bg_color = Color(0.08, 0.08, 0.12, 0.8)
			btn.add_theme_stylebox_override("normal", sb)

func _recalcular_metricas() -> void:
	var total_imp = 0
	var total_ris = 0
	
	var tema_manchete = ""
	var tema_charge = ""
	var tema_relato = ""
	
	if manchete_selecionada != -1:
		total_imp += MANCHETES[manchete_selecionada]["impacto"]
		total_ris += MANCHETES[manchete_selecionada]["risco"]
		tema_manchete = MANCHETES[manchete_selecionada]["tema"]
	if charge_selecionada != -1:
		total_imp += CHARGES[charge_selecionada]["impacto"]
		total_ris += CHARGES[charge_selecionada]["risco"]
		tema_charge = CHARGES[charge_selecionada]["tema"]
	if relato_selecionado != -1:
		total_imp += RELATOS[relato_selecionado]["impacto"]
		total_ris += RELATOS[relato_selecionado]["risco"]
		tema_relato = RELATOS[relato_selecionado]["tema"]
		
	if manchete_selecionada != -1 and charge_selecionada != -1 and relato_selecionado != -1:
		if tema_manchete == tema_charge and tema_charge == tema_relato:
			sinergia_ativa = tema_manchete
			if sinergia_ativa == "apagao":
				total_imp += 30
				total_ris -= 15
				lbl_sinergia.text = "SINERGIA: SABOTAGEM REVELADA (+30% Impacto, -15% Risco)\nBônus na Persuasão: Aumenta a eficácia de 'Apresentar Evidência' em +15."
				lbl_sinergia.add_theme_color_override("font_color", COR_GREEN_FILL)
			elif sinergia_ativa == "historia":
				total_imp += 25
				total_ris -= 10
				lbl_sinergia.text = "SINERGIA: VERDADE HISTÓRICA (+25% Impacto, -10% Risco)\nBônus na Persuasão: Aumenta a eficácia de 'Pergunta Socrática' em +10."
				lbl_sinergia.add_theme_color_override("font_color", COR_GREEN_FILL)
			elif sinergia_ativa == "escola":
				total_imp += 20
				total_ris -= 10
				lbl_sinergia.text = "SINERGIA: VOZ ESTUDANTIL (+20% Impacto, -10% Risco)\nBônus na Persuasão: Reduz a doutrinação inicial em -15%."
				lbl_sinergia.add_theme_color_override("font_color", COR_GREEN_FILL)
		elif tema_manchete != tema_charge and tema_charge != tema_relato and tema_manchete != tema_relato:
			sinergia_ativa = "incoerente"
			total_imp -= 15
			total_ris += 15
			lbl_sinergia.text = "PENALIDADE: INCOERÊNCIA EDITORIAL (-15% Impacto, +15% Risco)\nEfeito na Persuasão: Alerta militar começa em +20% e táticas causam -5 de dano."
			lbl_sinergia.add_theme_color_override("font_color", COR_RED_FILL)
		else:
			sinergia_ativa = ""
			lbl_sinergia.text = "FOCO EDITORIAL: MODERADO (Foco misto, sem bônus adicionais)."
			lbl_sinergia.add_theme_color_override("font_color", COR_TEXT_SEC)
	else:
		sinergia_ativa = ""
		lbl_sinergia.text = "Selecione todos os blocos do jornal para analisar a coerência cívica."
		lbl_sinergia.add_theme_color_override("font_color", COR_TEXT_TER)
		
	jornal_impacto = clamp(total_imp, 0, 100)
	jornal_risco = clamp(total_ris, 0, 100)
	
	bar_impacto.value = jornal_impacto
	bar_risco.value = jornal_risco
	
	if jornal_risco > 80:
		lbl_risco_alerta.text = "¡ CENSURA IMINENTE ! Risco muito alto. Substitua por peças mais seguras."
		lbl_risco_alerta.add_theme_color_override("font_color", COR_RED_FILL)
	elif jornal_impacto < 50:
		lbl_risco_alerta.text = "Impacto cívico insuficiente. Adicione manchetes ou relatos mais marcantes."
		lbl_risco_alerta.add_theme_color_override("font_color", Color("#ffa240"))
	else:
		lbl_risco_alerta.text = "Layout estável e pronto para publicação."
		lbl_risco_alerta.add_theme_color_override("font_color", COR_GREEN_FILL)

func _desenhar_preview_jornal() -> void:
	if not draw_preview: return
	var size = draw_preview.size
	
	# Desenha fundo de papel
	draw_preview.draw_rect(Rect2(Vector2.ZERO, size), Color("#ede6d8"))
	draw_preview.draw_rect(Rect2(Vector2.ZERO, size), Color("#423d33"), false, 3.0)
	
	# Header do Jornal Clandestino
	draw_preview.draw_rect(Rect2(12, 12, size.x - 24, 44), Color("#211d17"))
	draw_preview.draw_string(FONTE, Vector2(size.x/2.0, 42), "O ECO DA RESISTENCIA", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color("#ede6d8"))
	
	# Linha divisória
	draw_preview.draw_line(Vector2(12, 64), Vector2(size.x - 12, 64), Color.BLACK, 1.5)
	
	# Desenha Manchete selecionada
	if manchete_selecionada != -1:
		var m_txt = MANCHETES[manchete_selecionada]["texto"].to_upper()
		draw_preview.draw_string(FONTE, Vector2(size.x/2.0, 92), m_txt, HORIZONTAL_ALIGNMENT_CENTER, size.x - 40, 16, Color.BLACK)
	else:
		draw_preview.draw_string(FONTE, Vector2(size.x/2.0, 92), "[MANCHETE PRINCIPAL AUSENTE]", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color("#a83232"))
		
	draw_preview.draw_line(Vector2(12, 114), Vector2(size.x - 12, 114), Color.BLACK, 1.0)
	
	# Esquerda do jornal: Relato
	var relato_rect = Rect2(15, 124, size.x/2.0 - 20, size.y - 140)
	draw_preview.draw_rect(relato_rect, Color(0, 0, 0, 0.05))
	draw_preview.draw_string(FONTE, Vector2(24, 144), "DEPOIMENTO POPULAR:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
	if relato_selecionado != -1:
		var r_txt = RELATOS[relato_selecionado]["texto"]
		var r_desc = RELATOS[relato_selecionado]["desc"]
		draw_preview.draw_string(FONTE, Vector2(24, 170), r_txt, HORIZONTAL_ALIGNMENT_LEFT, size.x/2.0 - 35, 11, Color("#211d17"))
		draw_preview.draw_string(FONTE, Vector2(24, 210), r_desc, HORIZONTAL_ALIGNMENT_LEFT, size.x/2.0 - 35, 11, Color("#4f4b43"))
	else:
		draw_preview.draw_string(FONTE, Vector2(24, 180), "[SELECIONE UM DEPOIMENTO]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#a83232"))
		
	# Divisor central
	draw_preview.draw_line(Vector2(size.x/2.0, 120), Vector2(size.x/2.0, size.y - 14), Color.BLACK, 1.0)
	
	# Direita do jornal: Charge
	var charge_rect = Rect2(size.x/2.0 + 10, 124, size.x/2.0 - 25, size.y - 140)
	draw_preview.draw_rect(charge_rect, Color(0, 0, 0, 0.03))
	draw_preview.draw_string(FONTE, Vector2(size.x/2.0 + 20, 144), "CHARGE EDITORIAL:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
	if charge_selecionada != -1:
		var c_txt = CHARGES[charge_selecionada]["texto"]
		draw_preview.draw_rect(Rect2(size.x/2.0 + 20, 160, size.x/2.0 - 45, 80), Color.BLACK, false, 1.5)
		draw_preview.draw_string(FONTE, Vector2(size.x/2.0 + size.x/4.0 - 10, 204), "[CARTOON SATIRA]", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.BLACK)
		draw_preview.draw_string(FONTE, Vector2(size.x/2.0 + 20, 260), c_txt, HORIZONTAL_ALIGNMENT_LEFT, size.x/2.0 - 45, 11, Color("#4f4b43"))
	else:
		draw_preview.draw_string(FONTE, Vector2(size.x/2.0 + 20, 180), "[SELECIONE UMA CHARGE]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#a83232"))

	# Carimbo de Linha Editorial no rodapé do papel
	if sinergia_ativa != "":
		var carimbo_txt = ""
		var carimbo_cor = Color.BLACK
		if sinergia_ativa == "escola":
			carimbo_txt = "★ COLETIVO ESTUDANTIL ★"
			carimbo_cor = Color("#1f5f3f")
		elif sinergia_ativa == "historia":
			carimbo_txt = "★ VERDADE E MEMÓRIA ★"
			carimbo_cor = Color("#2b4c7e")
		elif sinergia_ativa == "apagao":
			carimbo_txt = "★ CONTRA-INFORMAÇÃO ★"
			carimbo_cor = Color("#7e4b1a")
		elif sinergia_ativa == "incoerente":
			carimbo_txt = "⚠ EDITORIAL INCOERENTE ⚠"
			carimbo_cor = Color("#8b2525")
		
		draw_preview.draw_string(FONTE_MONO, Vector2(size.x/2.0, size.y - 6), carimbo_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, carimbo_cor)

func _tentar_publicar_jornal() -> void:
	if manchete_selecionada == -1 or charge_selecionada == -1 or relato_selecionado == -1:
		_play(sfx_erro, 0.95)
		_shake_panel(10)
		lbl_risco_alerta.text = "Incompleto! Preencha todos os blocos do jornal clandestino."
		lbl_risco_alerta.add_theme_color_override("font_color", COR_RED_FILL)
		return
		
	var imp = bar_impacto.value
	var ris = bar_risco.value
	
	if ris > 80:
		_play(sfx_erro, 0.9)
		_shake_panel(15)
		lbl_risco_alerta.text = "Falha! O jornal foi apreendido pelos militares devido ao risco alto."
		return
		
	if imp < 50:
		_play(sfx_erro, 0.95)
		_shake_panel(10)
		lbl_risco_alerta.text = "Falha! Conteúdo muito brando, não despertará a consciência cívica."
		return
		
	# Sucesso! Transição para a Etapa 2
	_play(sfx_click, 0.85)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(panel_editor, "modulate:a", 0.0, 0.45)
	tw.tween_property(panel_editor, "scale", Vector2(0.95, 0.95), 0.45)
	await tw.finished
	
	panel_editor.hide()
	etapa_atual = 2
	
	# Inicia a etapa de persuasão
	panel_persuasao.show()
	panel_persuasao.modulate.a = 0.0
	panel_persuasao.scale = Vector2(0.95, 0.95)
	
	# Inicializa as variáveis da persuasão socrática com base no jornal publicado
	# Impacto reduz doutrinação inicial
	doutrinacao_estudante = clamp(120.0 - jornal_impacto, 30.0, 100.0)
	
	# Risco aumenta alerta militar inicial
	alerta_militar = clamp(jornal_risco - 20.0, 0.0, 60.0)
	
	# Aplica bônus específicos da sinergia
	var bonus_text = ""
	if sinergia_ativa == "escola":
		doutrinacao_estudante = max(15.0, doutrinacao_estudante - 15.0)
		bonus_text = "Bônus 'Voz Estudantil': Doutrinação reduzida em -15%!"
	elif sinergia_ativa == "apagao":
		bonus_text = "Bônus 'Sabotagem Revelada': Carta 'Apresentar Evidência' fortalecida!"
	elif sinergia_ativa == "historia":
		bonus_text = "Bônus 'Verdade Histórica': Carta 'Pergunta Socrática' fortalecida!"
	elif sinergia_ativa == "incoerente":
		alerta_militar = min(90.0, alerta_militar + 20.0)
		bonus_text = "Penalidade 'Incoerência': Alerta militar +20% e menor dano de cartas!"
	else:
		bonus_text = "Foco Moderado: Sem bônus de persuasão adicionais."
		
	bar_doutrinacao.value = doutrinacao_estudante
	bar_alerta.value = alerta_militar
	
	lbl_persuasao_status.text = bonus_text
	lbl_persuasao_status.add_theme_color_override("font_color", COR_GREEN_FILL if sinergia_ativa != "incoerente" else COR_RED_FILL)
	
	_construir_cards_persuasao()
	
	var tw2 = create_tween().set_parallel(true)
	tw2.tween_property(panel_persuasao, "modulate:a", 1.0, 0.45)
	tw2.tween_property(panel_persuasao, "scale", Vector2.ONE, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	_atualizar_argumento_estudante()

func _shake_panel(intensity: float) -> void:
	var orig_pos = panel_editor.position
	var tw = create_tween()
	for i in range(5):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(panel_editor, "position", orig_pos + offset, 0.05)
	tw.tween_property(panel_editor, "position", orig_pos, 0.05)

# ==========================================
# DETALHAMENTO DA ETAPA 2: PERSUASÃO SOCRÁTICA
# ==========================================
func _criar_layout_persuasao() -> void:
	panel_persuasao = PanelContainer.new()
	panel_persuasao.custom_minimum_size = Vector2(1000, 640)
	panel_persuasao.set_anchors_preset(PRESET_CENTER)
	panel_persuasao.grow_horizontal = GROW_DIRECTION_BOTH
	panel_persuasao.grow_vertical = GROW_DIRECTION_BOTH
	panel_persuasao.add_theme_stylebox_override("panel", _stylebox(COR_PANEL_BG, COR_GREEN_FILL, 3, 10))
	layer.add_child(panel_persuasao)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	panel_persuasao.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Header Persuasão
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var lbl_title = _label("CONVERSA DE PERSUASÃO SOCRÁTICA", 26, COR_GREEN_FILL, FONTE)
	lbl_title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(lbl_title)
	
	lbl_rodadas = _label("AÇÕES RESTANTES: 5", 18, COR_TEXT_SEC, FONTE_MONO)
	header.add_child(lbl_rodadas)
	
	# Box do Estudante (Diálogo e Silhouette)
	var box_student = PanelContainer.new()
	box_student.custom_minimum_size = Vector2(0, 160)
	var sb_st = StyleBoxFlat.new()
	sb_st.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	sb_st.border_width_left = 2; sb_st.border_color = COR_GREEN_FILL
	sb_st.content_margin_left = 20; sb_st.content_margin_right = 20
	box_student.add_theme_stylebox_override("panel", sb_st)
	vbox.add_child(box_student)
	
	var h_st = HBoxContainer.new()
	h_st.add_theme_constant_override("separation", 20)
	box_student.add_child(h_st)
	
	# Desenho do estudante (Vetorial ou placeholder desenhado)
	var avatar = Control.new()
	avatar.custom_minimum_size = Vector2(100, 120)
	avatar.draw.connect(func():
		var size = avatar.size
		# Desenha ombro e cabeça estilizados
		avatar.draw_circle(Vector2(size.x/2.0, 40), 28.0, Color("#54d6ff"))
		var points = PackedVector2Array([
			Vector2(10, size.y),
			Vector2(size.x - 10, size.y),
			Vector2(size.x/2.0 + 35, 75),
			Vector2(size.x/2.0 - 35, 75)
		])
		avatar.draw_polygon(points, PackedColorArray([Color("#2a5c78"), Color("#2a5c78"), Color("#4585a8"), Color("#4585a8")]))
		avatar.draw_string(FONTE_MONO, Vector2(size.x/2.0, size.y - 4), "ESTUDANTE", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)
	)
	h_st.add_child(avatar)
	
	lbl_dialogo_estudante = _label("", 21, COR_TEXT_PRI, FONTE)
	lbl_dialogo_estudante.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_dialogo_estudante.size_flags_horizontal = SIZE_EXPAND_FILL
	h_st.add_child(lbl_dialogo_estudante)
	
	# Indicadores (Doutrinação vs Alerta Militar)
	var meters_hbox = HBoxContainer.new()
	meters_hbox.add_theme_constant_override("separation", 36)
	vbox.add_child(meters_hbox)
	
	# Doutrinação
	var box_dou = VBoxContainer.new()
	box_dou.size_flags_horizontal = SIZE_EXPAND_FILL
	box_dou.add_child(_label("INDICE DE DOUTRINAÇÃO (META: 0%)", 14, Color("#ffa240"), FONTE_MONO))
	bar_doutrinacao = _criar_barra(Color("#ffa240"), Color("#ffa240", 0.12))
	bar_doutrinacao.value = 100
	box_dou.add_child(bar_doutrinacao)
	meters_hbox.add_child(box_dou)
	
	# Alerta Militar
	var box_ale = VBoxContainer.new()
	box_ale.size_flags_horizontal = SIZE_EXPAND_FILL
	box_ale.add_child(_label("ALERTA PATRULHA MILITAR (LIMITE: 100%)", 14, COR_RED_FILL, FONTE_MONO))
	bar_alerta = _criar_barra(COR_RED_FILL, COR_RED_BG)
	bar_alerta.value = 0
	box_ale.add_child(bar_alerta)
	meters_hbox.add_child(box_ale)
	
	# Cartas de Ação Cívica
	vbox.add_child(_label("SUAS CARTAS DE PERSUASÃO CIVICA:", 15, COR_TEXT_TER, FONTE_MONO))
	
	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 24)
	vbox.add_child(cards_container)
	
	# Rodapé de status
	lbl_persuasao_status = _label("Selecione uma tática socrática para responder ao argumento do estudante.", 17, COR_TEXT_SEC, FONTE)
	lbl_persuasao_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_persuasao_status)
	
	_construir_cards_persuasao()

func _construir_cards_persuasao() -> void:
	# Remove cartas anteriores
	for c in cards_container.get_children():
		c.queue_free()
		
	var dmg_soc = 20
	var dmg_evi = 35
	var dmg_emo = 15
	
	var bonus_soc = ""
	var bonus_evi = ""
	var bonus_emo = ""
	
	if sinergia_ativa == "historia":
		dmg_soc = 30
		bonus_soc = " [BÔNUS +10]"
	elif sinergia_ativa == "apagao":
		dmg_evi = 50
		bonus_evi = " [BÔNUS +15]"
	elif sinergia_ativa == "incoerente":
		dmg_soc = 15
		dmg_evi = 30
		dmg_emo = 10
		bonus_soc = " [PENALIDADE -5]"
		bonus_evi = " [PENALIDADE -5]"
		bonus_emo = " [PENALIDADE -5]"
		
	# Carta 1: Pergunta Socrática
	_criar_card_tática(
		"Pergunta Socrática", 
		"Questione o argumento sobre controle.\nEfeito: -%d%% Doutrinação%s.\nDobro contra 'Ordem'/'Segurança'.\nCusto: +10%% Alerta." % [dmg_soc, bonus_soc],
		Color("#54d6ff"),
		func(): _jogar_tática("socrática")
	)
	
	# Carta 2: Apresentar Evidência
	_criar_card_tática(
		"Apresentar Evidência", 
		"Mostre o jornal publicado.\nEfeito: -%d%% Doutrinação%s.\nDobro contra mentiras de 'Livro'.\nCusto: +30%% Alerta." % [dmg_evi, bonus_evi],
		Color("#62ff86"),
		func(): _jogar_tática("evidência")
	)
	
	# Carta 3: Apelo Emocional
	_criar_card_tática(
		"Apelo Emocional", 
		"Fale sobre o futuro cívico livre.\nEfeito: -%d%% Doutrinação%s.\nDobro contra o medo de 'Punido'.\nCusto: +5%% Alerta." % [dmg_emo, bonus_emo],
		Color("#ffe28a"),
		func(): _jogar_tática("emocional")
	)

func _criar_card_tática(titulo: String, desc: String, cor: Color, callback: Callable) -> void:
	# Card Wrapper (Para evitar conflitos de rotação do HBox)
	var card_control = Control.new()
	card_control.custom_minimum_size = Vector2(280, 200)
	cards_container.add_child(card_control)
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 200)
	card.add_theme_stylebox_override("panel", _stylebox(Color("#131118"), cor, 2, 8))
	card_control.add_child(card)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	vbox.add_child(_label(titulo.to_upper(), 17, cor, FONTE))
	vbox.add_child(_label(desc, 13, COR_TEXT_SEC, FONTE_MONO))
	
	var btn = Button.new()
	btn.text = "SELECIONAR"
	btn.custom_minimum_size = Vector2(0, 32)
	btn.size_flags_vertical = SIZE_SHRINK_END
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 15)
	btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	btn.pressed.connect(callback)
	
	btn.add_theme_stylebox_override("normal", _stylebox(Color("#181b22"), cor, 1, 4))
	btn.add_theme_stylebox_override("hover", _stylebox(cor, cor, 1, 4))
	btn.add_theme_stylebox_override("pressed", _stylebox(cor, cor, 1, 4))
	
	btn.mouse_entered.connect(func():
		_play(sfx_hover, 1.1)
		# Efeito de elevação suave em hover
		var tw = create_tween().set_parallel(true)
		tw.tween_property(card, "position:y", -12.0, 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.15)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween().set_parallel(true)
		tw.tween_property(card, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(card, "scale", Vector2.ONE, 0.2)
	)
	
	vbox.add_child(btn)

func _atualizar_argumento_estudante() -> void:
	if finalizado: return
	var arg = argumentos_rodada[argumento_estudante_id]
	lbl_dialogo_estudante.text = arg["texto"]
	lbl_rodadas.text = "AÇÕES RESTANTES: " + str(rodadas_restantes)

func _jogar_tática(tática: String) -> void:
	if finalizado: return
	
	var arg = argumentos_rodada[argumento_estudante_id]
	var dano = 0.0
	var alerta_gerado = 0.0
	var critico = false
	var log_txt = ""
	
	# Resolve tática
	if tática == "socrática":
		dano = 20.0
		if sinergia_ativa == "historia":
			dano += 10.0
		elif sinergia_ativa == "incoerente":
			dano -= 5.0
		alerta_gerado = 10.0
		if arg["defesa"] == "ordem" or arg["defesa"] == "seguranca":
			dano *= 2.0
			critico = true
		log_txt = "Dante questionou as incoerências lógicas do controle militar."
	elif tática == "evidência":
		dano = 35.0
		if sinergia_ativa == "apagao":
			dano += 15.0
		elif sinergia_ativa == "incoerente":
			dano -= 5.0
		alerta_gerado = 30.0
		if arg["defesa"] == "livro":
			dano *= 2.0
			critico = true
		log_txt = "Dante mostrou o jornal ecoando fatos históricos censurados."
	elif tática == "emocional":
		dano = 15.0
		if sinergia_ativa == "incoerente":
			dano -= 5.0
		alerta_gerado = 5.0
		if arg["defesa"] == "medo":
			dano *= 2.0
			critico = true
		log_txt = "Dante consolou o estudante mostrando a esperança na liberdade coletiva."
		
	# Aplica no estado
	doutrinacao_estudante = max(0.0, doutrinacao_estudante - dano)
	alerta_militar = min(100.0, alerta_militar + alerta_gerado)
	rodadas_restantes -= 1
	
	bar_doutrinacao.value = doutrinacao_estudante
	bar_alerta.value = alerta_militar
	
	# Feedback sonoro
	if critico:
		_play(sfx_click, 1.25)
		lbl_persuasao_status.text = "¡ ARGUMENTO CRÍTICO ! O estudante ficou confuso com as contradições."
		lbl_persuasao_status.add_theme_color_override("font_color", COR_GREEN_FILL)
	else:
		_play(sfx_click, 0.95)
		lbl_persuasao_status.text = "O estudante ouviu o argumento."
		lbl_persuasao_status.add_theme_color_override("font_color", COR_TEXT_SEC)
		
	# Verifica derrota por alerta
	if alerta_militar >= 100.0:
		_finalizar_persuasao(false, "Os guardas notaram a distribuição de panfletos no pátio e apreenderam Dante!")
		return
		
	# Verifica vitória
	if doutrinacao_estudante <= 0.0:
		_finalizar_persuasao(true, "Você desmobilizou a mentira! O estudante guardou o jornal e se uniu à resistência cívica.")
		return
		
	# Verifica derrota por turnos
	if rodadas_restantes <= 0:
		_finalizar_persuasao(false, "Suas ações acabaram e o estudante não foi convencido a tempo. O pátio foi evacuado.")
		return
		
	# Muda o argumento do estudante para a próxima rodada
	argumento_estudante_id = (argumento_estudante_id + 1) % argumentos_rodada.size()
	_atualizar_argumento_estudante()

func _finalizar_persuasao(sucesso: bool, texto_resultado: String) -> void:
	finalizado = true
	
	# Esconde UI de jogo
	lbl_rodadas.hide()
	cards_container.hide()
	
	lbl_persuasao_status.text = texto_resultado
	if sucesso:
		lbl_persuasao_status.add_theme_color_override("font_color", COR_GREEN_FILL)
		await get_tree().create_timer(3.5).timeout
		GameState.fase3_passo = "escola_concluida"
		GameState.desbloquear_conquista("escola_ok")
		await GameState.retornar_para_game_scene_apos_minigame()
	else:
		_play(sfx_erro, 0.9)
		lbl_persuasao_status.add_theme_color_override("font_color", COR_RED_FILL)
		await get_tree().create_timer(3.5).timeout
		# Reinicia a fase da escola
		FadeManager.carregar_cena("res://ASSETS/CENAS/minigame_escola.tscn")

# ==========================================
# HELPERS DE UI
# ==========================================
func _label(texto: String, tamanho: int, cor: Color, fonte: Font = FONTE) -> Label:
	var lbl = Label.new()
	lbl.text = texto
	lbl.add_theme_font_override("font", fonte)
	lbl.add_theme_font_size_override("font_size", tamanho)
	lbl.add_theme_color_override("font_color", cor)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	return lbl

func _criar_barra(cor_fg: Color, cor_bg: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = true
	bar.add_theme_font_override("font", FONTE_MONO)
	bar.add_theme_font_size_override("font_size", 10)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = cor_bg
	bar.add_theme_stylebox_override("background", sb_bg)
	
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = cor_fg
	bar.add_theme_stylebox_override("fill", sb_fg)
	
	return bar

func _stylebox(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
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
	return sb
