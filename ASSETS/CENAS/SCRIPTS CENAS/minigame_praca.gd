extends Control

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const FONTE_MONO = preload("res://ASSETS/FONTES/dogicapixel.ttf")
const BG_TEX = preload("res://ASSETS/SPRITES/FUNDOS/Rua com manifestação.jpeg")
const DANTE_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/PROTA/Apontando (braço estendido, expressão acusatória).png")
const PROTESTANTES_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/Protestantes - Fase Praça.png")
const CLICK_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesClick.mp3")

const PALACIO_SCENE: String = "res://ASSETS/CENAS/minigame_final_palacio.tscn"

# === EVENTOS E NARRATIVA (MOMENTOS DA MOBILIZAÇÃO) ===
const MOMENTOS: Array[Dictionary] = [
	{
		"titulo": "FASE 1: A CONCENTRAÇÃO DA MARCHA",
		"texto": "A multidão se reúne na entrada da praça. A presença da polícia militar está se intensificando a distância. Como você lidera a entrada?",
		"opcoes": [
			{
				"titulo_carta": "DISPERSÃO TÁTICA",
				"desc": "Entrar em pequenos grupos separados pelas laterais para evitar chamar atenção imediata.",
				"efeito_txt": "Segurança +20  Tensão -10  Mobilização -15",
				"categoria": "CARTA: PRECAUÇÃO",
				"cor": "#40d7ff",
				"mod_mob": -15, "mod_seg": 20, "mod_org": 5, "mod_ten": -10,
				"aliado": "", "carta": "", "bonus": 5
			},
			{
				"titulo_carta": "MARCHA UNIFICADA",
				"desc": "Avançar juntos pela avenida principal, de braços dados, cantando hinos civis de Usina Velha.",
				"efeito_txt": "Mobilização +25  Organização +15  Tensão +15",
				"categoria": "CARTA: LIDERANÇA",
				"cor": "#ffd447",
				"mod_mob": 25, "mod_seg": -5, "mod_org": 15, "mod_ten": 15,
				"aliado": "familias", "carta": "humanos", "bonus": 10
			},
			{
				"titulo_carta": "OCUPAÇÃO DIRETA",
				"desc": "Correr em direção às barricadas do palácio, forçando a abertura dos portões com energia.",
				"efeito_txt": "Mobilização +35  Segurança -25  Tensão +30",
				"categoria": "CARTA: CHOQUE",
				"cor": "#ff5c5c",
				"mod_mob": 35, "mod_seg": -25, "mod_org": -10, "mod_ten": 30,
				"aliado": "", "carta": "", "bonus": -5
			}
		]
	},
	{
		"titulo": "FASE 2: O DISCURSO DA RESISTÊNCIA",
		"texto": "Dante pega o megafone sob os alto-falantes da praça. A multidão silencia aguardando suas palavras. Qual o tom do discurço?",
		"opcoes": [
			{
				"titulo_carta": "APELO CÍVICO",
				"desc": "Discursar sobre direitos civis históricos, citando a antiga constituição e cobrando a ordem legal.",
				"efeito_txt": "Organização +20  Segurança +10  Tensão -5",
				"categoria": "CARTA: LEGALIDADE",
				"cor": "#bda6ff",
				"mod_mob": 10, "mod_seg": 10, "mod_org": 20, "mod_ten": -5,
				"aliado": "", "carta": "", "bonus": 8
			},
			{
				"titulo_carta": "DENÚNCIA DE CENSURA",
				"desc": "Transmitir trechos gravados da rádio livre expondo a farsa da doutrinação escolar militar.",
				"efeito_txt": "Mobilização +30  Organização +10  Tensão +15",
				"categoria": "CARTA: CONSCIENTIZAÇÃO",
				"cor": "#62ff86",
				"mod_mob": 30, "mod_seg": -5, "mod_org": 10, "mod_ten": 15,
				"aliado": "radio_livre", "carta": "imprensa", "bonus": 12
			},
			{
				"titulo_carta": "ATAQUE RETÓRICO",
				"desc": "Conclamar o povo a cercar a prefeitura imediatamente, chamando os generais de tiranos covardes.",
				"efeito_txt": "Mobilização +40  Organização -15  Tensão +25",
				"categoria": "CARTA: INSURREIÇÃO",
				"cor": "#ff2d2d",
				"mod_mob": 40, "mod_seg": -15, "mod_org": -15, "mod_ten": 25,
				"aliado": "", "carta": "", "bonus": -2
			}
		]
	},
	{
		"titulo": "FASE 3: A REAÇÃO DAS PATRULHAS",
		"texto": "Uma patrulha de guardas com cassetetes se aproxima da ala norte. Cidadãos entram em pânico. Qual a diretiva?",
		"opcoes": [
			{
				"titulo_carta": "BARREIRA HUMANA",
				"desc": "Pedir que os manifestantes mais jovens formem uma barreira pacífica de braços dados para deter os guardas.",
				"efeito_txt": "Organização +25  Segurança +15  Mobilização -10",
				"categoria": "CARTA: RESISTÊNCIA CÍVICA",
				"cor": "#40d7ff",
				"mod_mob": -10, "mod_seg": 15, "mod_org": 25, "mod_ten": 5,
				"aliado": "estudantes", "carta": "educacao", "bonus": 10
			},
			{
				"titulo_carta": "EVACUAÇÃO RÁPIDA",
				"desc": "Ordenar a retirada imediata do grupo vulnerável pelos becos, dispersando parte da marcha.",
				"efeito_txt": "Segurança +30  Mobilização -25  Tensão -15",
				"categoria": "CARTA: EVACUAÇÃO",
				"cor": "#a2a8b3",
				"mod_mob": -25, "mod_seg": 30, "mod_org": 5, "mod_ten": -15,
				"aliado": "", "carta": "", "bonus": 5
			},
			{
				"titulo_carta": "DISTRAÇÃO RADICAL",
				"desc": "Provocar os soldados atirando latas e pedras na direção oposta para dividir as patrulhas.",
				"efeito_txt": "Mobilização +25  Segurança -20  Tensão +30",
				"categoria": "CARTA: CONTRATAQUE",
				"cor": "#ffa240",
				"mod_mob": 25, "mod_seg": -20, "mod_org": -20, "mod_ten": 30,
				"aliado": "", "carta": "", "bonus": -10
			}
		]
	},
	{
		"titulo": "FASE 4: O CERCO FINAL AO PALÁCIO",
		"texto": "A multidão chega aos portões de ferro. O Coronel ordena carregar as armas. Dante precisa tomar a decisão que definirá o cerco.",
		"opcoes": [
			{
				"titulo_carta": "DESOBEDIÊNCIA TOTAL",
				"desc": "Ajoelhar diante dos portões e manter o silêncio absoluto. A força moral do silêncio paralisa a ação armada.",
				"efeito_txt": "Segurança +20  Organização +20  Tensão -15",
				"categoria": "CARTA: NÃO-VIOLÊNCIA",
				"cor": "#62ff86",
				"mod_mob": 15, "mod_seg": 20, "mod_org": 20, "mod_ten": -15,
				"aliado": "familias", "carta": "humanos", "bonus": 15
			},
			{
				"titulo_carta": "OCUPAÇÃO MASSIVA",
				"desc": "Furar a barreira de escudos empurrando o portão principal de uma só vez, arrombando as correntes.",
				"efeito_txt": "Mobilização +45  Segurança -35  Tensão +30",
				"categoria": "CARTA: RUPTURA",
				"cor": "#ff5c5c",
				"mod_mob": 45, "mod_seg": -35, "mod_org": -10, "mod_ten": 30,
				"aliado": "", "carta": "", "bonus": 5
			},
			{
				"titulo_carta": "NEGOCIAÇÃO PÚBLICA",
				"desc": "Chamar o comandante local em frente às câmeras de transmissão, expondo a covardia do ataque civil ao vivo.",
				"efeito_txt": "Mobilização +20  Organização +10  Segurança +10",
				"categoria": "CARTA: EXPOSIÇÃO",
				"cor": "#ffd447",
				"mod_mob": 20, "mod_seg": 10, "mod_org": 10, "mod_ten": 5,
				"aliado": "radio_livre", "carta": "imprensa", "bonus": 10
			}
		]
	}
]

# === ESTADO DO SIMULADOR ===
var indice: int = 0
var apoio_bonus: int = 0
var escolhidos: Array[String] = []

# Recursos Ativos da Manifestação
var mobilizacao: float = 35.0  # Começa em 35%
var seguranca: float = 80.0    # Começa bem seguro (80%)
var organizacao: float = 70.0  # Começa em 70%
var tensao: float = 15.0       # Tensão inicial baixa (15%)

# === COMPONENTES DE UI ===
var layer: CanvasLayer
var panel_main: PanelContainer
var progresso: Label
var titulo: Label
var texto: Label
var opcoes_box: HBoxContainer
var lbl_feedback: Label
var crowd_visualizer: Control
var crowd_rect: TextureRect

# Barras de Recursos
var bar_mob: ProgressBar
var bar_seg: ProgressBar
var bar_org: ProgressBar
var bar_ten: ProgressBar

var sfx_click: AudioStreamPlayer
var finalizado: bool = false
var em_simulacao: bool = false
var alarm_overlay: ColorRect
var alarm_timer: float = 0.0


func _ready() -> void:
	_configurar_audio()
	_montar_cena()
	_mostrar_momento()


func _process(delta: float) -> void:
	if finalizado:
		return
		
	# Rotaciona/Redesenha radar continuamente
	if crowd_visualizer:
		crowd_visualizer.queue_redraw()
		
	# Atualiza medidores na interface em tempo real
	if bar_mob: bar_mob.value = mobilizacao
	if bar_seg: bar_seg.value = seguranca
	if bar_org: bar_org.value = organizacao
	if bar_ten: bar_ten.value = tensao
	
	if crowd_rect:
		var target_a = clamp(mobilizacao / 100.0 * 0.9, 0.15, 0.95)
		crowd_rect.modulate.a = target_a
		
	# Alarme visual se a tensão militar estiver muito alta
	if tensao >= 70.0:
		alarm_timer += delta * 4.0
		var a = (sin(alarm_timer) + 1.0) / 2.0 * 0.14
		alarm_overlay.color = Color(1.0, 0.0, 0.0, a)
	else:
		alarm_overlay.color.a = 0.0


func _configurar_audio() -> void:
	sfx_click = AudioStreamPlayer.new()
	sfx_click.stream = CLICK_SOUND
	sfx_click.bus = "SFX"
	add_child(sfx_click)


func _montar_cena() -> void:
	layer = CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	# Fundo com protestantes e prota desfocado
	var bg := TextureRect.new()
	bg.texture = BG_TEX
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.5, 0.5, 0.55)
	layer.add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.04, 0.65)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)

	# Personagens integrados na lateral inferior
	crowd_rect = TextureRect.new()
	crowd_rect.texture = PROTESTANTES_TEX
	crowd_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crowd_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crowd_rect.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	crowd_rect.offset_left = 20
	crowd_rect.offset_right = 580
	crowd_rect.offset_top = -320
	crowd_rect.offset_bottom = -10
	crowd_rect.modulate.a = clamp(mobilizacao / 100.0 * 0.9, 0.15, 0.95)
	layer.add_child(crowd_rect)

	var dante := TextureRect.new()
	dante.texture = load(GameState.obter_caminho_sprite_dante("Apontando (braço estendido, expressão acusatória).png"))
	dante.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dante.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dante.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	dante.offset_left = -340
	dante.offset_right = -30
	dante.offset_top = -480
	dante.offset_bottom = -10
	dante.modulate.a = 0.95
	layer.add_child(dante)

	alarm_overlay = ColorRect.new()
	alarm_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	alarm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	alarm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(alarm_overlay)

	# Painel de Comando Operacional (Glassmorphism layout)
	panel_main = PanelContainer.new()
	panel_main.set_anchors_preset(Control.PRESET_CENTER)
	panel_main.custom_minimum_size = Vector2(1120, 680)
	panel_main.add_theme_stylebox_override("panel", _stylebox(_ca("#060509", 0.90), Color("#54d6ff"), 2, 12))
	layer.add_child(panel_main)
	call_deferred("_centralizar", panel_main)

	var margin := _margin(20)
	panel_main.add_child(margin)
	
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	# Título do Ato
	var header_hbox := HBoxContainer.new()
	root.add_child(header_hbox)
	
	var head := _label("PAINEL DE CONTROLE TÁTICO", 28, Color("#54d6ff"), FONTE)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(head)
	
	progresso = _label("", 15, Color("#62ff86"), FONTE_MONO)
	header_hbox.add_child(progresso)

	# ═════ COLUNAS SPLIT-SCREEN ═════
	var split_hbox := HBoxContainer.new()
	split_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hbox.add_theme_constant_override("separation", 24)
	root.add_child(split_hbox)

	# Coluna Esquerda: Radar Tático
	var col_left := VBoxContainer.new()
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.size_flags_stretch_ratio = 1.0
	col_left.add_theme_constant_override("separation", 8)
	split_hbox.add_child(col_left)

	col_left.add_child(_label("MONITOR DE DENSIDADE E SEGURANÇA", 13, Color("#54d6ff"), FONTE_MONO))

	var monitor_panel := PanelContainer.new()
	monitor_panel.custom_minimum_size = Vector2(0, 310)
	monitor_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	monitor_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.01, 0.01, 0.02, 0.94), Color("#54d6ff", 0.4), 2, 8))
	col_left.add_child(monitor_panel)
	
	crowd_visualizer = Control.new()
	crowd_visualizer.set_anchors_preset(Control.PRESET_FULL_RECT)
	crowd_visualizer.draw.connect(_desenhar_monitor_multidao)
	monitor_panel.add_child(crowd_visualizer)

	# Coluna Direita: Narrativa e Recursos
	var col_right := VBoxContainer.new()
	col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_right.size_flags_stretch_ratio = 1.2
	col_right.add_theme_constant_override("separation", 14)
	split_hbox.add_child(col_right)

	# Painel de descrição da etapa
	var desc_panel := PanelContainer.new()
	desc_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.08, 0.09, 0.13, 0.65), Color("#2a2c35", 0.5), 1, 8))
	col_right.add_child(desc_panel)

	var desc_margin := _margin(14)
	desc_panel.add_child(desc_margin)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 8)
	desc_margin.add_child(desc_vbox)

	titulo = _label("", 21, Color("#fff4d6"), FONTE)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_vbox.add_child(titulo)

	texto = _label("", 16, Color("#d7c9aa"), FONTE)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_vbox.add_child(texto)

	# Medidores verticais de recursos
	var bar_vbox := VBoxContainer.new()
	bar_vbox.add_theme_constant_override("separation", 8)
	col_right.add_child(bar_vbox)

	# Barra 1: Mobilização
	var box_mob := HBoxContainer.new()
	box_mob.add_theme_constant_override("separation", 10)
	var lbl_mob := _label("👥 MOBILIZACAO: ", 14, Color("#ffa240"), FONTE_MONO)
	lbl_mob.custom_minimum_size = Vector2(150, 0)
	box_mob.add_child(lbl_mob)
	bar_mob = _criar_barra(Color("#ffa240"))
	box_mob.add_child(bar_mob)
	bar_vbox.add_child(box_mob)

	# Barra 2: Organização
	var box_org := HBoxContainer.new()
	box_org.add_theme_constant_override("separation", 10)
	var lbl_org := _label("📋 ORGANIZACAO:", 14, Color("#62ff86"), FONTE_MONO)
	lbl_org.custom_minimum_size = Vector2(150, 0)
	box_org.add_child(lbl_org)
	bar_org = _criar_barra(Color("#62ff86"))
	box_org.add_child(bar_org)
	bar_vbox.add_child(box_org)

	# Barra 3: Segurança
	var box_seg := HBoxContainer.new()
	box_seg.add_theme_constant_override("separation", 10)
	var lbl_seg := _label("🛡️ SEGURANCA:  ", 14, Color("#40d7ff"), FONTE_MONO)
	lbl_seg.custom_minimum_size = Vector2(150, 0)
	box_seg.add_child(lbl_seg)
	bar_seg = _criar_barra(Color("#40d7ff"))
	box_seg.add_child(bar_seg)
	bar_vbox.add_child(box_seg)

	# Barra 4: Tensão Militar
	var box_ten := HBoxContainer.new()
	box_ten.add_theme_constant_override("separation", 10)
	var lbl_ten := _label("⚠️ TENSÃO MIL.: ", 14, Color("#ff5c5c"), FONTE_MONO)
	lbl_ten.custom_minimum_size = Vector2(150, 0)
	box_ten.add_child(lbl_ten)
	bar_ten = _criar_barra(Color("#ff5c5c"))
	box_ten.add_child(bar_ten)
	bar_vbox.add_child(box_ten)

	# Rodapé: Container para cartas
	opcoes_box = HBoxContainer.new()
	opcoes_box.alignment = BoxContainer.ALIGNMENT_CENTER
	opcoes_box.add_theme_constant_override("separation", 20)
	opcoes_box.custom_minimum_size = Vector2(0, 240)
	root.add_child(opcoes_box)

	lbl_feedback = _label("", 18, Color("#ffffff"), FONTE)
	lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(lbl_feedback)

	_atualizar_barras()


func _centralizar(node: Control) -> void:
	node.size = node.custom_minimum_size
	node.position = (get_viewport_rect().size - node.size) * 0.5 + Vector2(0, 10)


func _criar_barra(cor: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 50
	bar.custom_minimum_size = Vector2(300, 20)
	bar.show_percentage = true
	bar.add_theme_font_override("font", FONTE_MONO)
	bar.add_theme_font_size_override("font_size", 12)
	bar.add_theme_color_override("font_color", Color.WHITE)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.04, 0.03, 0.05)
	bar.add_theme_stylebox_override("background", sb_bg)
	
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = cor
	sb_fg.corner_radius_top_left = 3; sb_fg.corner_radius_top_right = 3
	sb_fg.corner_radius_bottom_left = 3; sb_fg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", sb_fg)
	
	return bar


func _atualizar_barras() -> void:
	bar_mob.value = mobilizacao
	bar_seg.value = seguranca
	bar_org.value = organizacao
	bar_ten.value = tensao
	if crowd_rect:
		var target_a = clamp(mobilizacao / 100.0 * 0.9, 0.15, 0.95)
		create_tween().tween_property(crowd_rect, "modulate:a", target_a, 0.45)
	crowd_visualizer.queue_redraw()


func _mostrar_momento() -> void:
	if finalizado:
		return
		
	if indice >= MOMENTOS.size():
		await _concluir_simulacao()
		return

	var momento: Dictionary = MOMENTOS[indice] as Dictionary
	progresso.text = "FASE OPERACIONAL " + str(indice + 1) + "/" + str(MOMENTOS.size())
	titulo.text = str(momento["titulo"])
	texto.text = str(momento["texto"])
	
	_limpar(opcoes_box)

	var i = 0
	for opcao_data in momento["opcoes"]:
		var opcao: Dictionary = opcao_data as Dictionary
		var btn: Button = _criar_carta_botao(opcao)
		btn.pressed.connect(func(): _escolher(opcao))
		opcoes_box.add_child(btn)
		
		# Animação de entrada (Scale up com bounce/mola)
		btn.scale = Vector2(0.4, 0.4)
		btn.modulate.a = 0.0
		
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(i * 0.1)
		tw.tween_property(btn, "modulate:a", 1.0, 0.35).set_delay(i * 0.1)
		
		i += 1


func _criar_carta_botao(opcao: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(310, 275)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Layout interno
	var margin := _margin(16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	# Categoria superior
	var lbl_cat := _label(str(opcao["categoria"]), 16, Color(opcao["cor"]), FONTE)
	lbl_cat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl_cat)
	
	# Divisor estético
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(opcao["cor"], 0.4)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(div)

	# Título principal da Carta
	var lbl_title := _label(str(opcao["titulo_carta"]), 21, Color.WHITE, FONTE)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl_title)
	
	# Descrição da ação
	var lbl_desc := Label.new()
	lbl_desc.text = str(opcao["desc"])
	lbl_desc.add_theme_font_override("font", FONTE)
	lbl_desc.add_theme_font_size_override("font_size", 16)
	lbl_desc.add_theme_color_override("font_color", Color("#ede6d8"))
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl_desc)
	
	# Divisor de rodapé
	var div2 := ColorRect.new()
	div2.custom_minimum_size = Vector2(0, 1)
	div2.color = Color(0.3, 0.3, 0.3, 0.5)
	div2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(div2)

	# Efeitos listados na base
	var lbl_eff := _label(str(opcao["efeito_txt"]), 13, Color("#7bd88f") if int(opcao["bonus"]) >= 0 else Color("#ff7373"), FONTE_MONO)
	lbl_eff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_eff.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl_eff)
	
	# Estilo personalizado
	var card_color = Color(opcao["cor"])
	var style_n = _stylebox(Color("#14131a", 0.94), card_color, 2, 8)
	var style_h = _stylebox(Color("#201e28", 0.98), card_color.lightened(0.18), 3, 8)
	style_h.shadow_size = 10
	style_h.shadow_color = Color(card_color, 0.22)
	var style_p = _stylebox(Color("#0d0d12", 0.96), card_color.darkened(0.2), 2, 8)
	
	btn.add_theme_stylebox_override("normal", style_n)
	btn.add_theme_stylebox_override("hover", style_h)
	btn.add_theme_stylebox_override("pressed", style_p)
	
	# Efeito de hover suave
	btn.pivot_offset = Vector2(155, 137)
	btn.mouse_entered.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	)
	btn.mouse_exited.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	)
	
	return btn


func _escolher(opcao: Dictionary) -> void:
	if finalizado: return
	_play_click()
	
	# Entra em simulação
	em_simulacao = true
	_bloquear_botoes(true)
	
	# Exibe painel de processamento
	_mostrar_processamento_simulacao(str(opcao["titulo_carta"]))
	
	# Calcula novos valores
	var target_mob = clamp(mobilizacao + float(opcao["mod_mob"]), 0.0, 100.0)
	var target_seg = clamp(seguranca + float(opcao["mod_seg"]), 0.0, 100.0)
	var target_org = clamp(organizacao + float(opcao["mod_org"]), 0.0, 100.0)
	var target_ten = clamp(tensao + float(opcao["mod_ten"]), 0.0, 100.0)
	
	# Anima as variáveis de recurso suavemente
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "mobilizacao", target_mob, 1.2)
	tw.tween_property(self, "seguranca", target_seg, 1.2)
	tw.tween_property(self, "organizacao", target_org, 1.2)
	tw.tween_property(self, "tensao", target_ten, 1.2)
	
	# Spawna popups de feedback nas barras
	_spawnar_popups_modificadores(opcao)
	
	# Espera o tempo da animação e simulação
	await get_tree().create_timer(1.6).timeout
	
	em_simulacao = false
	
	# Salva aliados e escolhas
	var aliado: String = str(opcao["aliado"])
	if not aliado.is_empty():
		GameState.aliados_final[aliado] = true
	var carta: String = str(opcao["carta"])
	if not carta.is_empty() and not GameState.cartas_final_desbloqueadas.has(carta):
		GameState.cartas_final_desbloqueadas.append(carta)
	escolhidos.append(str(opcao["titulo_carta"]))
	
	# Verificação de falhas críticas imediatas
	if seguranca <= 0.0:
		_falha_marcha("A SEGURANÇA DA MULTIDÃO CHEGOU A ZERO. Os generais reprimiram o ato violentamente.")
		return
	if tensao >= 100.0:
		_falha_marcha("A PRESSÃO MILITAR CHEGOU A 100%. Dante e seus aliados foram encurralados pelas patrulhas.")
		return
		
	# Feedback breve de efeitos
	lbl_feedback.text = "Efeito da diretiva selecionada aplicado!"
	lbl_feedback.add_theme_color_override("font_color", Color("#62ff86"))
	
	# Efeito vermelho breve de impacto se a tensão aumentou
	if float(opcao["mod_ten"]) > 0:
		var alert = ColorRect.new()
		alert.color = Color(1.0, 0.0, 0.0, 0.15)
		alert.set_anchors_preset(Control.PRESET_FULL_RECT)
		alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(alert)
		var tw_alert = create_tween()
		tw_alert.tween_property(alert, "color:a", 0.0, 0.4)
		tw_alert.tween_callback(func(): alert.queue_free())

	await get_tree().create_timer(0.8).timeout
	lbl_feedback.text = ""
	
	indice += 1
	_mostrar_momento()

func _mostrar_processamento_simulacao(titulo_diretiva: String) -> void:
	_limpar(opcoes_box)
	
	var sim_panel = PanelContainer.new()
	sim_panel.custom_minimum_size = Vector2(900, 220)
	sim_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.04, 0.03, 0.06, 0.90), Color("#62ff86", 0.8), 2, 8))
	opcoes_box.add_child(sim_panel)
	
	var margin = _margin(20)
	sim_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	var lbl_proc = _label("DIRETIVA ATIVADA: " + titulo_diretiva.to_upper(), 22, Color("#62ff86"), FONTE)
	lbl_proc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_proc)
	
	var lbl_status = _label("Mobilizando cidadãos nas vias centrais... Sincronizando rede de vigilância...", 15, Color("#a2a8b3"), FONTE_MONO)
	lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_status)
	
	# Adiciona uma barrinha de progresso de simulação fictícia
	var sim_bar = ProgressBar.new()
	sim_bar.custom_minimum_size = Vector2(600, 12)
	sim_bar.show_percentage = false
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0,0,0,0.5)
	sim_bar.add_theme_stylebox_override("background", sb_bg)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color("#62ff86")
	sim_bar.add_theme_stylebox_override("fill", sb_fg)
	vbox.add_child(sim_bar)
	
	# Tween do progresso da simulação
	var tw = create_tween()
	tw.tween_property(sim_bar, "value", 100.0, 1.4)

func _spawnar_popups_modificadores(opcao: Dictionary) -> void:
	if int(opcao["mod_mob"]) != 0:
		_mostrar_popup_efeito(int(opcao["mod_mob"]), Color("#ffa240"), bar_mob)
	if int(opcao["mod_org"]) != 0:
		_mostrar_popup_efeito(int(opcao["mod_org"]), Color("#62ff86"), bar_org)
	if int(opcao["mod_seg"]) != 0:
		_mostrar_popup_efeito(int(opcao["mod_seg"]), Color("#40d7ff"), bar_seg)
	if int(opcao["mod_ten"]) != 0:
		_mostrar_popup_efeito(int(opcao["mod_ten"]), Color("#ff5c5c"), bar_ten)

func _mostrar_popup_efeito(valor: int, cor: Color, parent_node: Control) -> void:
	var popup := Label.new()
	popup.text = ("+" if valor >= 0 else "") + str(valor) + "%"
	popup.add_theme_font_override("font", FONTE_MONO)
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", cor)
	popup.position = Vector2(240, -4)
	parent_node.add_child(popup)
	
	var tw = popup.create_tween()
	tw.tween_property(popup, "position:y", -24.0, 1.2).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(popup, "modulate:a", 0.0, 1.2)
	tw.tween_callback(popup.queue_free)


func _falha_marcha(motivo: String) -> void:
	finalizado = true
	_bloquear_botoes(true)
	lbl_feedback.text = motivo + "\nA mobilização dispersou. Tente outra estratégia de liderança cívica."
	lbl_feedback.add_theme_color_override("font_color", Color("#ff4b4b"))
	
	# Fade out preto antes de recarregar
	var o := ColorRect.new()
	o.color = Color(0, 0, 0, 0)
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(o)
	var tw = create_tween()
	tw.tween_property(o, "color:a", 1.0, 2.5)
	await tw.finished
	FadeManager.carregar_cena("res://ASSETS/CENAS/minigame_praca.tscn")


func _concluir_simulacao() -> void:
	finalizado = true
	# Recompensas finais baseadas nos recursos acumulados
	apoio_bonus = int(mobilizacao * 0.6 + organizacao * 0.4 + seguranca * 0.4 - tensao * 0.4)
	
	await _ir_para_palacio()


func _ir_para_palacio() -> void:
	var cometeu_violencia = "OCUPAÇÃO DIRETA" in escolhidos or "ATAQUE RETÓRICO" in escolhidos or "DISTRAÇÃO RADICAL" in escolhidos or "OCUPAÇÃO MASSIVA" in escolhidos
	if seguranca >= 80.0 and not cometeu_violencia:
		GameState.desbloquear_conquista("praca_pacifica")

	GameState.fase4_passo = "palacio"
	GameState.pontuacao_final = {
		"bonus_praca": apoio_bonus,
		"escolhas_praca": escolhidos.duplicate()
	}
	await GameState.mostrar_registro_democratico({
		"fase": "Fase 4 - Praca",
		"conceito": "Participacao popular, protesto pacifico e organizacao coletiva",
		"evidencia": "O jogador equilibrou mobilizacao, seguranca, organizacao e tensao militar durante a marcha.",
		"impacto": "A mobilizacao avancou com responsabilidade civica e protecao da comunidade.",
		"reflexao": "Participar da democracia exige estrategia, solidariedade e cuidado com a vida coletiva."
	})
	GameState.registrar_escolha("Liderou a marcha da praca com " + str(int(mobilizacao)) + "% de apoio", maxi(-2, int(apoio_bonus / 10)))
	
	if GameState.is_minigame_mode:
		await GameState.retornar_para_game_scene_apos_minigame()
	else:
		GameState.cena_atual = PALACIO_SCENE
		GameState.salvar_jogo(false)
		await TimelineManager.parar_tudo()
		await FadeManager.carregar_cena(PALACIO_SCENE)


func _desenhar_monitor_multidao() -> void:
	var size_rect = crowd_visualizer.size
	var centro = size_rect * 0.5
	
	# Desenha grade radar tático circular
	var line_color = Color(0.0, 0.5, 0.25, 0.18)
	
	# Linhas circulares concêntricas do radar
	crowd_visualizer.draw_arc(centro, 20.0, 0.0, TAU, 32, line_color, 1.0)
	crowd_visualizer.draw_arc(centro, 45.0, 0.0, TAU, 48, line_color, 1.0)
	crowd_visualizer.draw_arc(centro, 70.0, 0.0, TAU, 64, line_color, 1.0)
	
	# Cruz central do radar
	crowd_visualizer.draw_line(Vector2(centro.x - 240, centro.y), Vector2(centro.x + 240, centro.y), line_color, 1.0)
	crowd_visualizer.draw_line(Vector2(centro.x, centro.y - 70), Vector2(centro.x, centro.y + 70), line_color, 1.0)
	
	# Linha rotativa de varredura do radar
	var sweep_speed = 1.8
	if em_simulacao:
		sweep_speed = 5.0
	var sweep_angle = fmod(Time.get_ticks_msec() * 0.001 * sweep_speed, TAU)
	var sweep_dir = Vector2(cos(sweep_angle), sin(sweep_angle))
	var sweep_len = 250.0
	crowd_visualizer.draw_line(centro, centro + sweep_dir * sweep_len, Color("#62ff86", 0.45), 2.0)
	
	# Cone de luz da varredura
	var tail_angle = sweep_angle - 0.25
	var tail_dir = Vector2(cos(tail_angle), sin(tail_angle))
	var radar_pts = PackedVector2Array([
		centro,
		centro + sweep_dir * sweep_len,
		centro + tail_dir * sweep_len
	])
	crowd_visualizer.draw_polygon(radar_pts, PackedColorArray([Color("#62ff86", 0.12), Color("#62ff86", 0.0), Color("#62ff86", 0.0)]))
	
	# Desenha pontinhos representando os manifestantes na praça (Verde)
	var manifestantes_count = int(mobilizacao * 1.5)
	var r = RandomNumberGenerator.new()
	r.seed = 1337 # Semente constante para não tremer a cada frame
	
	for i in range(manifestantes_count):
		var rx = r.randf_range(centro.x - 220, centro.x + 220)
		var ry = r.randf_range(centro.y - 60, centro.y + 60)
		
		# Adiciona jitter vibracional em simulação
		if em_simulacao:
			rx += randf_range(-4.0, 4.0)
			ry += randf_range(-4.0, 4.0)
			
		# Pontinho de manifestante (Verde Brilhante)
		var p_color = Color("#62ff86", r.randf_range(0.55, 0.95))
		crowd_visualizer.draw_circle(Vector2(rx, ry), 2.5, p_color)
		crowd_visualizer.draw_circle(Vector2(rx, ry), 4.5, Color("#62ff86", 0.08))

	# Desenha patrulhas militares cercando a praça (Vermelho)
	var patrulhas_count = int(tensao * 0.8)
	var r_p = RandomNumberGenerator.new()
	r_p.seed = 4321
	
	for i in range(patrulhas_count):
		var rx = r_p.randf_range(centro.x - 240, centro.x + 240)
		var ry = r_p.randf_range(centro.y - 70, centro.y + 70)
		
		if em_simulacao:
			rx += randf_range(-3.0, 3.0)
			ry += randf_range(-3.0, 3.0)
			
		# Desenha apenas nas bordas externas do radar
		if Vector2(rx, ry).distance_to(centro) > 75.0:
			var p_color = Color("#ff4b4b", r_p.randf_range(0.7, 1.0))
			crowd_visualizer.draw_circle(Vector2(rx, ry), 3.0, p_color)
			crowd_visualizer.draw_circle(Vector2(rx, ry), 5.5, Color("#ff4b4b", 0.12))


func _play_click() -> void:
	if sfx_click:
		sfx_click.play()


func _limpar(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _bloquear_botoes(bloquear: bool) -> void:
	for child in opcoes_box.get_children():
		if child is Button:
			child.disabled = bloquear


func _label(texto_lbl: String, tamanho: int, cor: Color, fonte: Font) -> Label:
	var lbl := Label.new()
	lbl.text = texto_lbl
	lbl.add_theme_font_override("font", fonte)
	lbl.add_theme_font_size_override("font_size", tamanho)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	return lbl


func _margin(valor: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", valor)
	margin.add_theme_constant_override("margin_right", valor)
	margin.add_theme_constant_override("margin_top", valor)
	margin.add_theme_constant_override("margin_bottom", valor)
	return margin


func _ca(code: String, alpha: float) -> Color:
	var color := Color(code)
	color.a = alpha
	return color


func _stylebox(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
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
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb
