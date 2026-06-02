extends Control

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const FONTE_MONO = preload("res://ASSETS/FONTES/dogicapixel.ttf")
const BG_TEX = preload("res://ASSETS/SPRITES/FUNDOS/O Comandante das Ruínas.png")
const DANTE_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/PROTA/Bravo determinado.png")
const DANTE_FALA_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/PROTA/Falando (boca aberta).png")
const VILAO_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/Vilão/cara maléfica sem fundo.png")
const VILAO_RAIVA_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/Vilão/raiva sem fundo.png")
const VILAO_ASSUSTADO_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/Vilão/assustado sem fundo.png")
const VILAO_RINDO_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/Vilão/rindo com um tim meio irônico sem fundo.png")
const CLICK_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesClick.mp3")
const HIT_SOUND = preload("res://ASSETS/SOUNDS/FSX/Impacto/impacto_radio_militar.mp3")
const STINGER_SOUND = preload("res://ASSETS/SOUNDS/FSX/Tensao/stinger_tensao.mp3")

const MAX_INFLUENCE: int = 100
const QTE_TIME: float = 6.0

# === ESTRUTURAS DE DADOS DO DEBATE ===
const PROOFS: Dictionary = {
	"radio": {"nome": "Prova da Rádio", "texto": "A transmissão interceptada prova censura e mentiras oficiais."},
	"livro": {"nome": "Livro de Direitos", "texto": "O livro prova que as liberdades civis existiam antes da ditadura."},
	"escola": {"nome": "Doutrinação Escolar", "texto": "O material escolar foi adulterado para pregar a obediência."},
	"memoria": {"nome": "Memória da Usina", "texto": "As anotações revelam como o medo calou os trabalhadores originais."},
	"praca": {"nome": "Apoio da Praça", "texto": "A praça cheia prova que a cidade quer participar e decidir."}
}

const PRINCIPLES: Dictionary = {
	"voto": {"nome": "Sufrágio Cívico", "texto": "A democracia respira quando o cidadão escolhe, cobra e muda governos."},
	"expressao": {"nome": "Liberdade de Expressão", "texto": "O contraditório e a crítica são os pilares de uma sociedade livre."},
	"imprensa": {"nome": "Imprensa Independente", "texto": "Sem jornalismo livre, os abusos são acobertados pela propaganda estatal."},
	"constituicao": {"nome": "Constituição Cívica", "texto": "A lei deve servir para limitar o poder e proteger os cidadãos."},
	"poderes": {"nome": "Divisão de Poderes", "texto": "Nenhum líder tem o direito de controlar lei, justiça e exército simultaneamente."},
	"participacao": {"nome": "Fiscalização Popular", "texto": "Cidadania é vigilância constante, não apenas votar a cada quatro anos."},
	"educacao": {"nome": "Pensamento Crítico", "texto": "O conhecimento transforma obediência cega em discernimento."},
	"humanos": {"nome": "Dignidade Humana", "texto": "O direito à vida e à justiça não se suspende sob pretexto de ordem."},
	"justica": {"nome": "Devido Processo", "texto": "O regime deve responder com provas, defesas e tribunais civis imparciais."},
	"memoria": {"nome": "Memória Histórica", "texto": "Lembrar os abusos do passado impede que a tirania se repita."}
}

# Atos do Debate Baseados no Roteiro
const ACTS: Array[Dictionary] = [
	{
		"fala": "Dante... você é jovem. O povo não tem discernimento técnico para governar. Por isso eu decido por todos.",
		"manipulacao": "paternalismo",
		"manipulacoes": [
			{"id": "paternalismo", "nome": "Paternalismo Autoritário", "texto": "O líder trata o povo como incapaz para justificar controle absoluto."},
			{"id": "boato", "nome": "Difamação sem Fonte", "texto": "Lançar boatos não comprovados para desviar o debate técnico."},
			{"id": "ameaca", "nome": "Ameaça Velada", "texto": "Usar o medo da punição imediata para forçar a submissão."}
		],
		"prova": "escola",
		"provas": ["escola", "praca", "memoria"],
		"principio": "educacao",
		"principios": ["educacao", "voto", "poderes"],
		"resposta": "Se o povo não sabe decidir, a resposta nunca será a tirania, mas sim a educação cívica e o pensamento livre!",
		"reacao": "A multidão lá fora canta em coro as palavras de Dante!"
	},
	{
		"fala": "A imprensa livre só semeia desavenças e discórdia. O controle da rádio protege a segurança nacional de Usina Velha.",
		"manipulacao": "censura",
		"manipulacoes": [
			{"id": "censura", "nome": "Censura Disfarçada", "texto": "Chamar o monopólio e o silenciamento de 'proteção da estabilidade'."},
			{"id": "culto", "nome": "Culto à Personalidade", "texto": "Exigir adoração e obediência cega devido a méritos pessoais autodeclarados."},
			{"id": "falsa_escolha", "nome": "Falso Dilema", "texto": "Apresentar a situação como se a única alternativa ao regime fosse o caos."}
		],
		"prova": "radio",
		"provas": ["radio", "livro", "praca"],
		"principio": "imprensa",
		"principios": ["imprensa", "expressao", "memoria"],
		"resposta": "Quando apenas o Estado fala, o abuso de poder se torna segredo. A Rádio Livre expôs suas mentiras ao vivo!",
		"reacao": "A transmissão militar começa a chiar sob interferência popular!"
	},
	{
		"fala": "As leis antigas são lentas, Dante. Um governante forte deve agir rápido, sem a burocracia de juízes e conselhos municipais.",
		"manipulacao": "concentracao",
		"manipulacoes": [
			{"id": "concentracao", "nome": "Concentração de Poder", "texto": "Tentar suprimir o parlamento e o judiciário em prol de uma ditadura absoluta."},
			{"id": "vitimismo", "nome": "Vitimismo do Opressor", "texto": "O regime se coloca como perseguido por conspirações para evitar críticas legítimas."},
			{"id": "desvio", "nome": "Tática de Evasão", "texto": "Mudar de assunto e fugir da pergunta central sobre a legalidade das ações."}
		],
		"prova": "livro",
		"provas": ["livro", "radio", "memoria"],
		"principio": "poderes",
		"principios": ["poderes", "constituicao", "justica"],
		"resposta": "Nenhum homem pode estar acima da lei. Sem separação dos poderes, a justiça vira capricho de um ditador!",
		"reacao": "Os alto-falantes da praça repetem o grito: NENHUM HOMEM ACIMA DA LEI!"
	},
	{
		"fala": "Protesto na praça é vandalismo. Quem caminha comigo trabalha; quem vai para as ruas é inimigo do progresso.",
		"manipulacao": "criminalizacao",
		"manipulacoes": [
			{"id": "criminalizacao", "nome": "Criminalização do Protesto", "texto": "Tentar rotular manifestações cívicas pacíficas como crimes violentos."},
			{"id": "apelo_medo", "nome": "Apelo ao Pânico", "texto": "Instigar medo de catástrofes imediatas para reprimir direitos civis."},
			{"id": "promessa_vazia", "nome": "Promessa sem Lastro", "texto": "Garantir soluções futuras sem apresentar planos, cobrando submissão."}
		],
		"prova": "praca",
		"provas": ["praca", "escola", "livro"],
		"principio": "participacao",
		"principios": ["participacao", "expressao", "humanos"],
		"resposta": "Participar e fiscalizar as decisões do poder não é crime, é a maior virtude de um povo soberano!",
		"reacao": "A transmissão de TV do Palácio mostra a multidão empunhando flores nas barricadas!"
	}
]

const FINAL_CHOICES: Array[Dictionary] = [
	{"id": "julgamento", "titulo": "Julgamento Civil e Público", "desc": "Submeter o ditador ao devido processo legal, com provas, júri e direito de defesa.", "delta": 15, "resultado": "democratica"},
	{"id": "prisao", "titulo": "Detenção Institucional", "desc": "Prender o Coronel imediatamente e entregar as chaves ao Conselho Civil da Usina Velha.", "delta": 8, "resultado": "institucional"},
	{"id": "exilio", "titulo": "Expulsão e Exílio", "desc": "Mandar o líder embora da região para evitar confrontos armados, mesmo sem julgamento.", "delta": -4, "resultado": "fragil"},
	{"id": "violencia", "titulo": "Retaliação Popular", "desc": "Entregar o Coronel à multidão enfurecida para linchamento imediato.", "delta": -25, "resultado": "vingativa"}
]

# === ESTADO DO COMBATE ===
var act_index: int = 0
var step: String = "debate" # "debate", "heartbeat_qte", "final_choices", "concluido"
var act_score: int = 0
var popular: int = 42
var regime: int = 42
var estabilidade_emocional: float = 100.0
var panic_active: bool = false
var selected_manipulation: String = ""
var selected_proof: String = ""

# Variáveis do QTE de Respiração (Heartbeat QTE)
var qte_pulse_pos: float = 0.0
var qte_successes: int = 0

# Animações
var glitch_phase: float = 0.0
var shake_time: float = 0.0
var shake_intensity: float = 0.0
var qte_ripple_radius: float = 0.0
var qte_ripple_alpha: float = 0.0

# === COMPONENTES DE UI ===
var layer: CanvasLayer
var fx_layer: Control
var main_panel: PanelContainer
var regime_bar: ProgressBar
var popular_bar: ProgressBar
var estabilidade_bar: ProgressBar

var lbl_step: Label
var lbl_vilao: Label
var lbl_dante: Label
var lbl_reacao: Label
var choices_box: VBoxContainer
var qte_panel: PanelContainer
var qte_draw_control: Control
var final_box: VBoxContainer
var dante_sprite: TextureRect
var vilao_sprite: TextureRect
var lbl_feedback: Label

var sfx_click: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_stinger: AudioStreamPlayer


func _ready() -> void:
	randomize()
	_configurar_audio()
	_configurar_estado_inicial()
	_montar_cena()
	await FadeManager.mostrar_intro_fase(0, "Está tão calado, o gato comeu sua língua?")
	_mostrar_tutorial()


func _process(delta: float) -> void:
	glitch_phase += delta
	
	# Sistema de Shake proporcional a shake_intensity
	if shake_time > 0.0:
		shake_time = max(0.0, shake_time - delta)
		var shake_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		main_panel.position = shake_offset
		if dante_sprite:
			dante_sprite.offset_left = 34 + shake_offset.x * 0.4
			dante_sprite.offset_right = 395 + shake_offset.x * 0.4
		if vilao_sprite:
			vilao_sprite.offset_left = -410 + shake_offset.x * 0.7
			vilao_sprite.offset_right = -34 + shake_offset.x * 0.7
	else:
		if main_panel:
			main_panel.position = Vector2(310, 34)
		if dante_sprite:
			dante_sprite.offset_left = 34
			dante_sprite.offset_right = 395
		if vilao_sprite:
			vilao_sprite.offset_left = -410
			vilao_sprite.offset_right = -34

	# Tremor do pânico emocional
	if panic_active:
		if lbl_vilao:
			lbl_vilao.position = Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0))
		if lbl_dante:
			lbl_dante.position = Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0))
			
	# Atualiza o QTE de respiração
	if step == "heartbeat_qte":
		qte_pulse_pos += delta * 1.8 # Velocidade do batimento cardíaco
		if qte_pulse_pos > 1.0:
			qte_pulse_pos = 0.0 # Missed beat
			estabilidade_emocional = max(0.0, estabilidade_emocional - 10.0)
			_shake(8.0, 0.25)
			_atualizar_barras()
		if qte_draw_control:
			qte_draw_control.queue_redraw()

	if fx_layer:
		fx_layer.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if step != "heartbeat_qte" or not event.is_pressed():
		return
		
	# Tecla ESPAÇO no tempo do EKG
	if event.is_action_pressed("ui_accept"):
		# Alvo central do EKG: t entre 0.45 e 0.58
		if qte_pulse_pos >= 0.45 and qte_pulse_pos <= 0.58:
			qte_successes += 1
			qte_pulse_pos = 0.0 # Reinicia para o próximo batimento
			_play(sfx_click, 1.25)
			
			# Ripple de sucesso verde
			qte_ripple_radius = 5.0
			qte_ripple_alpha = 1.0
			var tw_rip = create_tween()
			tw_rip.set_parallel(true)
			tw_rip.tween_property(self, "qte_ripple_radius", 220.0, 0.45).set_ease(Tween.EASE_OUT)
			tw_rip.tween_property(self, "qte_ripple_alpha", 0.0, 0.45)
			
			if qte_successes >= 3:
				_sucesso_heartbeat()
		else:
			qte_successes = 0 # Reinicia o combo se errar
			estabilidade_emocional = max(0.0, estabilidade_emocional - 15.0)
			_play(sfx_stinger, 1.0)
			_shake(15.0, 0.35)
			
			# Ripple de erro vermelho
			qte_ripple_radius = 5.0
			qte_ripple_alpha = 1.0
			var tw_rip = create_tween()
			tw_rip.set_parallel(true)
			tw_rip.tween_property(self, "qte_ripple_radius", 220.0, 0.45).set_ease(Tween.EASE_OUT)
			tw_rip.tween_property(self, "qte_ripple_alpha", 0.0, 0.45)
			
			qte_pulse_pos = 0.0
			_atualizar_barras()


func _configurar_audio() -> void:
	sfx_click = _audio(CLICK_SOUND)
	sfx_hit = _audio(HIT_SOUND)
	sfx_stinger = _audio(STINGER_SOUND)


func _audio(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	add_child(player)
	return player


func _configurar_estado_inicial() -> void:
	var bonus: int = int(GameState.pontuacao_final.get("bonus_praca", 0))
	popular = clamp(42 + bonus + int(GameState.confianca * 0.5), 24, 78)
	regime = clamp(42 - int(bonus * 0.25), 25, 68)


func _montar_cena() -> void:
	layer = CanvasLayer.new()
	layer.layer = 30
	add_child(layer)

	var bg := TextureRect.new()
	bg.texture = BG_TEX
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.42, 0.42, 0.50)
	layer.add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.0, 0.02, 0.64)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)

	fx_layer = Control.new()
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.draw.connect(_desenhar_fx)
	layer.add_child(fx_layer)

	_montar_personagens()
	_montar_ui()


func _montar_personagens() -> void:
	dante_sprite = TextureRect.new()
	dante_sprite.texture = DANTE_TEX
	dante_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dante_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dante_sprite.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dante_sprite.offset_left = 34
	dante_sprite.offset_right = 395
	dante_sprite.offset_top = -540
	dante_sprite.offset_bottom = -12
	layer.add_child(dante_sprite)

	vilao_sprite = TextureRect.new()
	vilao_sprite.texture = VILAO_TEX
	vilao_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vilao_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vilao_sprite.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	vilao_sprite.offset_left = -410
	vilao_sprite.offset_right = -34
	vilao_sprite.offset_top = -560
	vilao_sprite.offset_bottom = -12
	layer.add_child(vilao_sprite)


func _montar_ui() -> void:
	main_panel = PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.offset_left = 310
	main_panel.offset_top = 34
	main_panel.offset_right = -310
	main_panel.offset_bottom = -34
	main_panel.add_theme_stylebox_override("panel", _stylebox(_ca("#08070d", 0.94), Color("#54d6ff"), 4, 8))
	layer.add_child(main_panel)

	var margin := _margin(20)
	main_panel.add_child(margin)
	
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title := _label("A ÚLTIMA TRANSMISSÃO - O DEBATE", 38, Color("#ffe28a"), FONTE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	# Dicionário de falácias consultável
	var btn_dict := Button.new()
	btn_dict.text = " DICIONARIO DE FALACIAS (CONSULTAR) "
	btn_dict.custom_minimum_size = Vector2(300, 36)
	btn_dict.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_dict.add_theme_font_override("font", FONTE)
	btn_dict.add_theme_font_size_override("font_size", 16)
	btn_dict.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_dict.pressed.connect(_on_dicionario_pressed)
	
	var sb_dict = _stylebox(Color(0.05, 0.15, 0.35, 0.8), Color("#54d6ff"), 2, 6)
	btn_dict.add_theme_stylebox_override("normal", sb_dict)
	root.add_child(btn_dict)

	# ═════ 3 MEDIDORES DO DEBATE ═════
	var bars := GridContainer.new()
	bars.columns = 3
	bars.add_theme_constant_override("h_separation", 18)
	bars.add_theme_constant_override("v_separation", 6)
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(bars)

	# Regime/Autocracia
	var box_reg := HBoxContainer.new()
	box_reg.add_theme_constant_override("separation", 4)
	box_reg.add_child(_label("REGIME:", 14, Color("#ff4b4b"), FONTE_MONO))
	regime_bar = _criar_barra(Color("#ff4b4b"))
	box_reg.add_child(regime_bar)
	bars.add_child(box_reg)

	# Popular/Dante
	var box_pop := HBoxContainer.new()
	box_pop.add_theme_constant_override("separation", 4)
	box_pop.add_child(_label("CONSCIENCIA:", 14, Color("#62ff86"), FONTE_MONO))
	popular_bar = _criar_barra(Color("#62ff86"))
	box_pop.add_child(popular_bar)
	bars.add_child(box_pop)

	# Estabilidade Emocional de Dante
	var box_emo := HBoxContainer.new()
	box_emo.add_theme_constant_override("separation", 4)
	box_emo.add_child(_label("EMOCIONAL:", 14, Color("#00A2FF"), FONTE_MONO))
	estabilidade_bar = _criar_barra(Color("#00A2FF"))
	box_emo.add_child(estabilidade_bar)
	bars.add_child(box_emo)

	lbl_step = _label("", 17, Color("#d7c9aa"), FONTE_MONO)
	lbl_step.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_step)

	# Painel de Transmissão Analógica do Vilão
	var broadcast := _panel(_ca("#11131c", 0.98), Color("#ff4b4b"))
	broadcast.custom_minimum_size = Vector2(0, 130)
	root.add_child(broadcast)
	var bm := _margin(16)
	broadcast.add_child(bm)
	lbl_vilao = _label("", 26, Color("#fff4d6"), FONTE)
	lbl_vilao.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_vilao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_vilao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bm.add_child(lbl_vilao)

	lbl_dante = _label("", 20, Color("#54d6ff"), FONTE)
	lbl_dante.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_dante.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(lbl_dante)

	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 8)
	choices_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(choices_box)

	lbl_reacao = _label("", 18, Color("#ffe28a"), FONTE)
	lbl_reacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_reacao.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(lbl_reacao)

	lbl_feedback = _label("", 16, Color("#ff4b4b"), FONTE_MONO)
	lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(lbl_feedback)

	# QTE Panel
	qte_panel = _panel(_ca("#16090b", 0.98), Color("#ff4b4b"))
	qte_panel.visible = false
	qte_panel.custom_minimum_size = Vector2(0, 100)
	root.add_child(qte_panel)
	
	qte_draw_control = Control.new()
	qte_draw_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	qte_draw_control.draw.connect(_desenhar_qte_heartbeat)
	qte_panel.add_child(qte_draw_control)

	final_box = VBoxContainer.new()
	final_box.add_theme_constant_override("separation", 10)
	root.add_child(final_box)


func _criar_barra(cor: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 50
	bar.custom_minimum_size = Vector2(160, 18)
	bar.show_percentage = true
	bar.add_theme_font_override("font", FONTE_MONO)
	bar.add_theme_font_size_override("font_size", 10)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.05, 0.04, 0.06)
	bar.add_theme_stylebox_override("background", sb_bg)
	
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = cor
	bar.add_theme_stylebox_override("fill", sb_fg)
	
	return bar


func _atualizar_barras() -> void:
	regime_bar.value = regime
	popular_bar.value = popular
	estabilidade_bar.value = estabilidade_emocional
	
	if estabilidade_emocional <= 0.0:
		if not panic_active:
			panic_active = true
			lbl_feedback.text = "ALERTA: DANTE ESTÁ DESESTABILIZADO. EFICÁCIA DE ARGUMENTOS CAIU."
			lbl_feedback.add_theme_color_override("font_color", Color("#ff4b4b"))
			_shake(15.0, 0.35)
	else:
		panic_active = false
		lbl_feedback.text = ""


func _mostrar_tutorial() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 95
	add_child(overlay)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.90)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1060, 650)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = (get_viewport_rect().size - panel.custom_minimum_size) * 0.5
	panel.size = panel.custom_minimum_size
	panel.add_theme_stylebox_override("panel", _stylebox(Color("#0d0b12"), Color("#ffe28a"), 4, 8))
	overlay.add_child(panel)

	var margin := _margin(38)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	var title_lbl := _label("CONFRONTO DE ARGUMENTOS & FOCO", 38, Color("#ffe28a"), FONTE)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_lbl)

	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 14)
	box.add_child(steps)
	steps.add_child(_tutorial_card("1", "Ache a Manipulação", "Identifique a falácia política na retórica do ditador para expor sua contradição.", Color("#ff8066")))
	steps.add_child(_tutorial_card("2", "Apresente Fatos", "Use evidências cívicas coletadas. Errar enfraquece sua estabilidade mental.", Color("#54d6ff")))
	steps.add_child(_tutorial_card("3", "Estabilidade Emocional", "Mantenha o autocontrole. Se vacilar, a TV militar terá interferência de pânico.", Color("#7bd88f")))

	var note := _label("Defenda os princípios democráticos, preserve o equilíbrio mental e encare a verdade sobre Usina Velha.", 23, Color("#f5ead7"), FONTE)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)

	var btn := _button("INVADIR A TRANSMISSÃO", Color("#ffe28a"), 24)
	btn.custom_minimum_size = Vector2(330, 62)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func():
		_play(sfx_click, 1.0)
		overlay.queue_free()
		_iniciar_ato()
	)
	box.add_child(btn)


func _tutorial_card(number: String, title_text: String, body_text: String, color: Color) -> PanelContainer:
	var panel := _panel(_ca("#17131d", 0.98), color)
	panel.custom_minimum_size = Vector2(300, 250)
	var margin_c := _margin(16)
	panel.add_child(margin_c)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	margin_c.add_child(box)

	var number_label := _label(number, 36, color, FONTE_MONO)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(number_label)
	var title_lbl := _label(title_text, 25, Color("#fff4d6"), FONTE)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(title_lbl)
	var body := _label(body_text, 18, Color("#d7c9aa"), FONTE)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(body)
	return panel


func _iniciar_ato() -> void:
	_limpar(final_box)
	qte_panel.visible = false
	
	if popular >= MAX_INFLUENCE or regime >= MAX_INFLUENCE or act_index >= ACTS.size():
		_finalizar_confronto()
		return

	# Checa se é o momento do Golpe Emocional (Morte dos pais no Ato 4, índice 3)
	if act_index == 3 and step == "debate":
		_iniciar_golpe_emocional()
		return

	step = "manipulacao"
	act_score = 0
	selected_manipulation = ""
	selected_proof = ""
	
	var act: Dictionary = ACTS[act_index] as Dictionary
	lbl_step.text = "DEBATE CIVICO - ATO " + str(act_index + 1) + "/" + str(ACTS.size())
	lbl_vilao.text = "\"" + str(act["fala"]) + "\""
	lbl_dante.text = "Exponha a falácia retórica do Coronel na transmissão ao vivo."
	lbl_reacao.text = "A multidão lá fora assiste com atenção."
	
	dante_sprite.texture = DANTE_TEX
	vilao_sprite.texture = VILAO_TEX
	_atualizar_barras()
	_mostrar_manipulacoes(act)
	_vilao_bounce()


func _mostrar_manipulacoes(act: Dictionary) -> void:
	_limpar(choices_box)
	for item_data in act["manipulacoes"]:
		var item: Dictionary = item_data as Dictionary
		var id: String = str(item["id"])
		choices_box.add_child(_choice_panel(str(item["nome"]), str(item["texto"]), Color("#ff8066"), func(): _selecionar_manipulacao(id)))


func _selecionar_manipulacao(id: String) -> void:
	_play(sfx_click, 1.0)
	_dante_bounce()
	selected_manipulation = id
	var act: Dictionary = ACTS[act_index] as Dictionary
	
	if id == str(act["manipulacao"]):
		act_score += 1
		lbl_dante.text = "Você desmascarou o truque dele. Apresente os fatos para provar."
	else:
		var penalty = 15.0 if not panic_active else 25.0
		estabilidade_emocional = max(0.0, estabilidade_emocional - penalty)
		regime = mini(MAX_INFLUENCE, regime + 8)
		lbl_dante.text = "Sua retórica falhou. O Coronel Antônio dobra a mentira e abala seu foco."
		_shake(9.0, 0.3)
		
	step = "prova"
	_atualizar_barras()
	_mostrar_provas(act)


func _mostrar_provas(act: Dictionary) -> void:
	_limpar(choices_box)
	for proof_id_data in act["provas"]:
		var proof_id: String = str(proof_id_data)
		var proof: Dictionary = PROOFS[proof_id] as Dictionary
		choices_box.add_child(_choice_panel(str(proof["nome"]), str(proof["texto"]), Color("#54d6ff"), func(): _selecionar_prova(proof_id)))


func _selecionar_prova(id: String) -> void:
	_play(sfx_click, 1.0)
	_dante_bounce()
	selected_proof = id
	var act: Dictionary = ACTS[act_index] as Dictionary
	
	if id == str(act["prova"]):
		act_score += 1
		lbl_dante.text = "Fatos estabelecidos. Sustente o argumento com o Princípio Democrático."
	else:
		var penalty = 15.0 if not panic_active else 25.0
		estabilidade_emocional = max(0.0, estabilidade_emocional - penalty)
		regime = mini(MAX_INFLUENCE, regime + 8)
		lbl_dante.text = "A prova foi fraca. O Coronel mantém a insolência."
		_shake(8.0, 0.28)
		
	step = "principio"
	_atualizar_barras()
	_mostrar_principios(act)


func _mostrar_principios(act: Dictionary) -> void:
	_limpar(choices_box)
	for principle_id_data in act["principios"]:
		var principle_id: String = str(principle_id_data)
		var principle: Dictionary = PRINCIPLES[principle_id] as Dictionary
		choices_box.add_child(_choice_panel(str(principle["nome"]), str(principle["texto"]), Color("#7bd88f"), func(): _selecionar_principio(principle_id)))


func _selecionar_principio(id: String) -> void:
	_play(sfx_click, 1.0)
	_dante_bounce()
	var act: Dictionary = ACTS[act_index] as Dictionary
	if id == str(act["principio"]):
		act_score += 1
		
	_resolver_ato()


func _resolver_ato() -> void:
	_limpar(choices_box)
	var act: Dictionary = ACTS[act_index] as Dictionary
	
	# Modificação de pontuação final proporcional ao acerto do pilar
	var mult = 0.5 if panic_active else 1.0
	
	if act_score >= 3:
		popular = mini(MAX_INFLUENCE, popular + int(24 * mult))
		regime = maxi(0, regime - 12)
		estabilidade_emocional = min(100.0, estabilidade_emocional + 15.0)
		dante_sprite.texture = DANTE_FALA_TEX
		vilao_sprite.texture = VILAO_RAIVA_TEX
		lbl_dante.text = str(act["resposta"])
		lbl_reacao.text = str(act["reacao"])
		_play(sfx_hit, 1.2)
		_dante_atacar()
		_vilao_damage() # Tremor forte e piscada vermelha pelo sucesso
	elif act_score == 2:
		popular = mini(MAX_INFLUENCE, popular + int(12 * mult))
		regime = maxi(0, regime - 4)
		lbl_dante.text = "Dante fez um bom argumento, mas sem fechar todas as brechas cívicas."
		lbl_reacao.text = "A multidão lá fora está inquieta."
		_shake(6.0, 0.2)
	else:
		popular = maxi(0, popular - 12)
		regime = mini(MAX_INFLUENCE, regime + 16)
		dante_sprite.texture = DANTE_TEX
		vilao_sprite.texture = VILAO_RINDO_TEX
		lbl_dante.text = "A lógica falhou inteiramente diante da força repressiva do Coronel."
		lbl_reacao.text = "Um silêncio tenso toma as ruas."
		_play(sfx_stinger, 1.0)
		
		# Flash azul/vermelho de erro no Dante
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(dante_sprite, "modulate", Color(5.0, 0.2, 0.2), 0.08)
		tw.chain().tween_property(dante_sprite, "modulate", Color.WHITE, 0.15)
		_shake(10.0, 0.3)

	_atualizar_barras()
	await get_tree().create_timer(4.5).timeout
	
	act_index += 1
	_iniciar_ato()


# ══════════════════════════════════════════════
#  SISTEMA DE GOLPE EMOCIONAL (PARENTS TRUTH & QTE)
# ══════════════════════════════════════════════

func _iniciar_golpe_emocional() -> void:
	step = "heartbeat_qte"
	qte_successes = 0
	qte_pulse_pos = 0.0
	
	lbl_step.text = "GOLPE PSICOLOGICO - MANTER A CALMA!"
	lbl_vilao.text = "Dante... seu pai era um tolo fraco. Ele preferiu ser um 'mártir' na antiga usina militar a colaborar com a minha paz civica. Eu mesmo ordenei que cortassem a energia dos reatores... com ele preso lá dentro."
	lbl_dante.text = "Seus batimentos cardíacos estão acelerados! RESPIRE FUNDO. Pressione ESPAÇO no tempo exato do pulso (caixa alvo verde) para se recompor!"
	lbl_reacao.text = "A tensão sobe ao nível máximo no estúdio de transmissão!"
	
	vilao_sprite.texture = VILAO_RINDO_TEX
	dante_sprite.texture = DANTE_TEX
	_play(sfx_stinger, 1.0)
	_vilao_bounce()
	
	_limpar(choices_box)
	qte_panel.visible = true


func _sucesso_heartbeat() -> void:
	step = "debate"
	qte_panel.visible = false
	
	popular = mini(MAX_INFLUENCE, popular + 25)
	regime = maxi(0, regime - 20)
	estabilidade_emocional = 100.0 # Restaura totalmente o foco de Dante!
	
	dante_sprite.texture = DANTE_FALA_TEX
	vilao_sprite.texture = VILAO_ASSUSTADO_TEX
	
	lbl_dante.text = "Você se conteve com extrema clareza e altivez moral: 'Você os tirou de mim para tentar calar a cidade. Mas a verdade cívica sobre os seus crimes não morre em um reator. O povo de Usina Velha agora escuta ao vivo!'"
	lbl_reacao.text = "A multidão ruge em aplausos ensurdecedores do lado de fora!"
	
	_play(sfx_hit, 1.25)
	_shake(20.0, 0.5) # Efeito massivo de sucesso de impacto!
	_atualizar_barras()
	
	await get_tree().create_timer(5.0).timeout
	act_index += 1
	_iniciar_ato()


func _desenhar_qte_heartbeat() -> void:
	var size = qte_draw_control.size
	
	# Desenha ripples de acerto/erro
	if qte_ripple_alpha > 0.0:
		var center_pt = Vector2(size.x * 0.51, size.y * 0.5)
		var rip_color = Color("#00FF66", qte_ripple_alpha * 0.5) if qte_successes > 0 else Color("#ff3333", qte_ripple_alpha * 0.5)
		qte_draw_control.draw_circle(center_pt, qte_ripple_radius, Color(rip_color, 0.08), true)
		qte_draw_control.draw_circle(center_pt, qte_ripple_radius, rip_color, false, 3.5)
		qte_draw_control.draw_circle(center_pt, qte_ripple_radius * 0.6, Color(rip_color, qte_ripple_alpha * 0.2), false, 1.5)

	# Desenha a caixa alvo no centro
	var target_color = Color(0, 1.0, 0.4, 0.15)
	if int(Time.get_ticks_msec() / 200) % 2 == 0:
		target_color = Color(0, 1.0, 0.4, 0.3)
	qte_draw_control.draw_rect(Rect2(size.x * 0.45, 0, size.x * 0.13, size.y), target_color, true)
	qte_draw_control.draw_rect(Rect2(size.x * 0.45, 0, size.x * 0.13, size.y), Color("#00FF66", 0.6), false, 2.0)
	
	# Linha horizontal central
	qte_draw_control.draw_line(Vector2(0, size.y / 2), Vector2(size.x, size.y / 2), Color(0, 0.6, 0.2, 0.35), 2.0)
	
	# Desenha a onda EKG de batimento cardíaco verde fluorescente dinâmica
	var points = PackedVector2Array()
	var steps = 80
	for i in range(steps):
		var t = float(i) / (steps - 1)
		var x = t * size.x
		var y = size.y / 2.0
		
		# O Spike fica fixo no centro do alvo (t=0.51) para o jogador alinhar visualmente
		var dist_to_center = abs(t - 0.51)
		if dist_to_center < 0.06:
			y -= sin((t - 0.45) * PI / 0.12) * size.y * 0.42
		points.append(Vector2(x, y))
		
	for i in range(points.size() - 1):
		# Efeito Neon duplo
		qte_draw_control.draw_line(points[i], points[i+1], Color("#00FF66", 0.18), 6.0)
		qte_draw_control.draw_line(points[i], points[i+1], Color("#00FF66", 0.8), 2.5)
		qte_draw_control.draw_line(points[i], points[i+1], Color.WHITE, 1.0)
		
	# Linha do cursor vermelho móvel
	var cursor_x = qte_pulse_pos * size.x
	qte_draw_control.draw_line(Vector2(cursor_x, 0), Vector2(cursor_x, size.y), Color("#ff3333", 0.8), 3.0)
	
	# Indicador de acertos
	var success_txt = "ESTABILIDADE DO RITMO CARDIACO: " + str(qte_successes) + "/3 ACERTOS (ESPACO NO ALVO)"
	qte_draw_control.draw_string(FONTE_MONO, Vector2(20, size.y - 12), success_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#00FF66"))

# ══════════════════════════════════════════════
#  HELPERS VISUAIS DE COMBATE DE PORTRAITS
# ══════════════════════════════════════════════

func _dante_bounce() -> void:
	if not dante_sprite: return
	var tw = create_tween()
	tw.tween_property(dante_sprite, "offset_top", -565, 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(dante_sprite, "offset_top", -540, 0.12).set_ease(Tween.EASE_IN)

func _vilao_bounce() -> void:
	if not vilao_sprite: return
	var tw = create_tween()
	tw.tween_property(vilao_sprite, "offset_top", -585, 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(vilao_sprite, "offset_top", -560, 0.12).set_ease(Tween.EASE_IN)

func _dante_atacar() -> void:
	if not dante_sprite: return
	var start_x = dante_sprite.offset_left
	var target_x = start_x + 95.0
	var tw = create_tween()
	tw.tween_property(dante_sprite, "offset_left", target_x, 0.06).set_ease(Tween.EASE_OUT)
	tw.tween_property(dante_sprite, "offset_left", start_x, 0.18).set_ease(Tween.EASE_IN)

func _vilao_damage() -> void:
	if not vilao_sprite: return
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(vilao_sprite, "modulate", Color(10.0, 0.1, 0.1), 0.08)
	tw.chain().tween_property(vilao_sprite, "modulate", Color.WHITE, 0.15)
	_shake(22.0, 0.45)


# ══════════════════════════════════════════════
#  FALHAS E CONCLUSÕES DO CONFRONTO
# ══════════════════════════════════════════════

func _finalizar_confronto() -> void:
	_limpar(choices_box)
	_limpar(final_box)
	qte_panel.visible = false
	step = "final_choices"
	
	if popular >= regime:
		lbl_step.text = "A CIDADE RECONHECEU A MANIPULAÇÃO"
		lbl_vilao.text = "\"Isso... isso não pode estar acontecendo...\""
		vilao_sprite.texture = VILAO_ASSUSTADO_TEX
		dante_sprite.texture = DANTE_FALA_TEX
		lbl_dante.text = "A multidão cercou as portas do Palácio Municipal e exige uma decisão sobre o ditador desarmado."
		lbl_reacao.text = "Lembre-se: democracia não pode nascer como vingança pessoal."
		_mostrar_escolha_final()
	else:
		lbl_step.text = "O REGIME MANTEVE O CONTROLE DA MENTE"
		lbl_vilao.text = "\"A ordem cívica prevalece sob qualquer desobediência pacífica.\""
		vilao_sprite.texture = VILAO_RINDO_TEX
		lbl_dante.text = "Dante recua para a antiga usina industrial. A resistência civil sobrevive sob as cinzas de Usina Velha."
		lbl_reacao.text = "Final fraco desbloqueado. O medo ainda governa a praça."
		_registrar_resultado("derrota")
		final_box.add_child(_botao_final("SEGUIR PARA O FINAL"))


func _mostrar_escolha_final() -> void:
	for choice_data in FINAL_CHOICES:
		var choice: Dictionary = choice_data as Dictionary
		var btn: Button = _button(str(choice["titulo"]) + "\n" + str(choice["desc"]), Color("#ffe28a"), 20)
		btn.custom_minimum_size = Vector2(0, 68)
		btn.pressed.connect(func(): _escolha_final(choice))
		final_box.add_child(btn)


func _escolha_final(choice: Dictionary) -> void:
	_play(sfx_click, 1.0)
	popular = clamp(popular + int(choice["delta"]), 0, MAX_INFLUENCE)
	_registrar_resultado(str(choice["resultado"]))
	_limpar(final_box)
	
	lbl_dante.text = _texto_resultado(str(choice["resultado"]))
	lbl_reacao.text = "A cidade registra esta decisao como marco da reconstrucao civica."
	await GameState.mostrar_registro_democratico(_registro_final_por_resultado(str(choice["resultado"])))
	final_box.add_child(_botao_final("SEGUIR PARA O FINAL"))


func _registro_final_por_resultado(resultado: String) -> Dictionary:
	match resultado:
		"democratica":
			return {
				"fase": "Fase Final - Palacio",
				"conceito": "Devido processo legal, justica civil e limites democraticos",
				"evidencia": "O jogador escolheu julgamento publico com provas, juri e direito de defesa.",
				"impacto": "A cidade rompeu com o autoritarismo sem repetir a logica da vinganca.",
				"reflexao": "Uma democracia forte nasce quando ate o inimigo responde perante a lei."
			}
		"institucional":
			return {
				"fase": "Fase Final - Palacio",
				"conceito": "Reconstrucao institucional e transicao de poder",
				"evidencia": "O jogador escolheu deter o ditador e entregar a decisao as instituicoes civis.",
				"impacto": "A cidade abriu caminho para restaurar leis, freios e responsabilidades publicas.",
				"reflexao": "Instituicoes democraticas precisam limitar o poder antes que ele volte a se concentrar."
			}
		"fragil":
			return {
				"fase": "Fase Final - Palacio",
				"conceito": "Memoria, justica e risco de impunidade",
				"evidencia": "O jogador escolheu o exilio, evitando confronto imediato sem enfrentar plenamente os crimes.",
				"impacto": "A cidade ganhou tempo, mas manteve feridas politicas sem reparacao clara.",
				"reflexao": "Evitar violencia e importante, mas democracia tambem precisa de memoria e responsabilizacao."
			}
		"vingativa":
			return {
				"fase": "Fase Final - Palacio",
				"conceito": "Estado de direito e perigo da vinganca coletiva",
				"evidencia": "O jogador escolheu retaliacao popular, substituindo julgamento por punicao imediata.",
				"impacto": "O regime caiu, mas a comunidade viu que vencer sem principios pode gerar nova violencia.",
				"reflexao": "Democracia nao e apenas derrotar tiranos; e impedir que a justica vire vinganca."
			}
	return {
		"fase": "Fase Final - Palacio",
		"conceito": "Convivencia democratica e consciencia civica",
		"evidencia": "O jogador concluiu o confronto final entre propaganda, provas e principios.",
		"impacto": "A cidade avaliou os caminhos possiveis para reconstruir a vida coletiva.",
		"reflexao": "Direitos dependem de participacao, memoria e responsabilidade publica."
	}


func _registrar_resultado(resultado: String) -> void:
	GameState.resultado_final = resultado
	GameState.pontuacao_final["popular"] = popular
	GameState.pontuacao_final["regime"] = regime
	GameState.pontuacao_final["atos"] = act_index
	GameState.confianca += _delta_confianca(resultado)
	GameState.registrar_escolha("Concluiu a ultima transmissao: " + resultado, _delta_confianca(resultado))


func _delta_confianca(resultado: String) -> int:
	match resultado:
		"democratica": return 4
		"institucional": return 2
		"fragil": return -1
		"vingativa": return -4
		"derrota": return -3
	return 0


func _texto_resultado(resultado: String) -> String:
	match resultado:
		"democratica":
			return "O ditador será julgado com ampla defesa, provas e júri civil. A democracia nasce sem espelhar o autoritarismo do opressor."
		"institucional":
			return "O ditador é detido e entregue à transição provisória das instituições de Usina Velha."
		"fragil":
			return "O Coronel é mandado ao exílio. A praça permanece inquieta, num equilíbrio instável de forças."
		"vingativa":
			return "A multidão executa o líder sob linchamento público imediato. O medo cai, mas a tirania do caos apenas começou."
	return ""


# ══════════════════════════════════════════════
#  AUXILIARES VISUAIS & EFEITOS CRT E GLITCH
# ══════════════════════════════════════════════

func _desenhar_fx() -> void:
	var size = fx_layer.size
	
	# 1. Scanlines analógicas de TV CRT sobre toda a tela
	var scanline_color = Color(0.0, 0.0, 0.0, 0.16)
	for y in range(0, int(size.y), 4):
		fx_layer.draw_line(Vector2(0, y), Vector2(size.x, y), scanline_color, 1.5)
		
	# 2. Glitch analógico se o pânico estiver ativo
	if panic_active:
		var noise_color = Color(0.8, 0.0, 0.0, 0.08 + abs(sin(glitch_phase * 12.0)) * 0.08)
		fx_layer.draw_rect(Rect2(Vector2.ZERO, size), noise_color, true)
		
		var num_glitches = int(abs(sin(glitch_phase * 6.0)) * 3)
		for i in range(num_glitches):
			var gy = randf_range(0.0, size.y)
			var gh = randf_range(6.0, 24.0)
			fx_layer.draw_rect(Rect2(0, gy, size.x, gh), Color(0.85, 0.1, 0.1, 0.14), true)


func _shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_time = duration


func _on_dicionario_pressed() -> void:
	_play(sfx_click, 1.0)
	var overlay = CanvasLayer.new()
	overlay.layer = 98
	add_child(overlay)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	overlay.add_child(bg)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 580)
	panel.set_anchors_preset(PRESET_CENTER)
	panel.grow_horizontal = GROW_DIRECTION_BOTH
	panel.grow_vertical = GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	sb.border_width_left = 3; sb.border_width_top = 3
	sb.border_width_right = 3; sb.border_width_bottom = 3
	sb.border_color = Color("#54d6ff")
	sb.corner_radius_top_left = 12; sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12; sb.corner_radius_bottom_right = 12
	sb.shadow_size = 22
	sb.shadow_color = Color("#54d6ff", 0.16)
	panel.add_theme_stylebox_override("panel", sb)
	bg.add_child(panel)
	
	var margin = _margin(24)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "DICIONARIO DE FALACIAS RETORICAS"
	title.add_theme_font_override("font", FONTE)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#54d6ff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 12)
	list_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)
	
	var falacias = [
		{"nome": "Paternalismo Autoritario", "desc": "Tratar o povo como incapaz ou imaturo para justificar que o lider tome todas as decisoes e mantenha o controle absoluto.", "cor": "#ff8066"},
		{"nome": "Censura (Ordem Disfarcada)", "desc": "Silenciar informacoes ou meios de comunicacao alternativos sob o pretexto de 'proteger a paz' ou 'manter a estabilidade social'.", "cor": "#ff8066"},
		{"nome": "Concentracao de Poder", "desc": "Alegar que um lider forte deve decidir sozinho, dispensando contrapesos, leis ou julgamentos para ter mais 'eficiencia'.", "cor": "#ffa240"},
		{"nome": "Criminalizacao da Participacao", "desc": "Rotular manifestacoes civicas legitimas, protestos organizados ou ativismo pacifico como 'desordem' ou 'crime contra a patria'.", "cor": "#ff4b4b"},
		{"nome": "Criacao de Inimigo Interno", "desc": "Dividir a sociedade entre obedientes (cidadãos corretos) e traidores (quem discorda), para desviar a atencao de problemas reais.", "cor": "#ff2d2d"},
		{"nome": "Vitimismo do Poder", "desc": "Fazer com que o regime ou governante autoritario se coloque como o verdadeiro 'perseguido' ou 'martir' para anular criticas.", "cor": "#ff4ba0"},
		{"nome": "Falsa Escolha (Falso Dilema)", "desc": "Apresentar a discussao como se existissem apenas duas opcoes extremas (Ex: 'ou o meu governo, ou o caos absoluto'), omitindo outras vias democráticas.", "cor": "#bda6ff"},
		{"nome": "Apelo ao Medo (Ad Baculum)", "desc": "Instigar panico ou exagerar ameacas catastróficas para que a populacao prefira abrir mao de direitos basicos em troca de protecao.", "cor": "#ffd447"},
		{"nome": "Ridicularizacao (Sarcasmo)", "desc": "Atacar a pessoa do oponente com insultos ou piadas ironicas para desviar o foco e evitar responder com fatos e argumentos.", "cor": "#a2a8b3"}
	]
	
	for fal in falacias:
		var item_panel = PanelContainer.new()
		var sb_item = StyleBoxFlat.new()
		sb_item.bg_color = Color(0.11, 0.09, 0.15, 0.95)
		sb_item.border_width_left = 3
		sb_item.border_color = Color(fal["cor"])
		sb_item.corner_radius_top_right = 6; sb_item.corner_radius_bottom_right = 6
		sb_item.content_margin_left = 12; sb_item.content_margin_right = 12
		sb_item.content_margin_top = 8; sb_item.content_margin_bottom = 8
		item_panel.add_theme_stylebox_override("panel", sb_item)
		list_vbox.add_child(item_panel)
		
		var item_vbox = VBoxContainer.new()
		item_vbox.add_theme_constant_override("separation", 4)
		item_panel.add_child(item_vbox)
		
		var lbl_name = _label(fal["nome"].to_upper(), 18, Color(fal["cor"]), FONTE_MONO)
		item_vbox.add_child(lbl_name)
		
		var lbl_desc = Label.new()
		lbl_desc.text = fal["desc"]
		lbl_desc.add_theme_font_override("font", FONTE)
		lbl_desc.add_theme_font_size_override("font_size", 16)
		lbl_desc.add_theme_color_override("font_color", Color("#ede6d8"))
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		item_vbox.add_child(lbl_desc)
		
	var btn_close = Button.new()
	btn_close.text = "VOLTAR AO CONFRONTO"
	btn_close.custom_minimum_size = Vector2(220, 45)
	btn_close.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn_close.add_theme_font_override("font", FONTE)
	btn_close.add_theme_font_size_override("font_size", 20)
	btn_close.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color(0.0, 0.45, 0.7, 0.95)
	sb_close.corner_radius_top_left = 6; sb_close.corner_radius_top_right = 6
	sb_close.corner_radius_bottom_left = 6; sb_close.corner_radius_bottom_right = 6
	btn_close.add_theme_stylebox_override("normal", sb_close)
	btn_close.pressed.connect(func():
		_play(sfx_click, 1.0)
		overlay.queue_free()
	)
	vbox.add_child(btn_close)


func _choice_panel(nome: String, desc: String, borda: Color, callback: Callable) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb_p = _stylebox(Color("#131118", 0.94), borda, 2, 6)
	panel.add_theme_stylebox_override("panel", sb_p)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)
	
	var lbl_name := _label(nome.to_upper(), 18, borda, FONTE_MONO)
	lbl_name.custom_minimum_size = Vector2(200, 0)
	lbl_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	hbox.add_child(lbl_name)
	
	var lbl_desc := _label(desc, 16, Color("#d7c9aa"), FONTE)
	lbl_desc.size_flags_horizontal = SIZE_EXPAND_FILL
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	hbox.add_child(lbl_desc)
	
	var btn := Button.new()
	btn.text = " SELECIONAR "
	btn.custom_minimum_size = Vector2(120, 36)
	btn.size_flags_vertical = SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 16)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(callback)
	
	var sb_btn = _stylebox(Color("#181b22"), borda, 1, 4)
	var sb_btn_h = _stylebox(borda, borda, 1, 4)
	btn.add_theme_stylebox_override("normal", sb_btn)
	btn.add_theme_stylebox_override("hover", sb_btn_h)
	btn.add_theme_stylebox_override("pressed", sb_btn_h)
	hbox.add_child(btn)
	
	return panel


func _botao_final(texto_btn: String) -> Button:
	var btn := Button.new()
	btn.text = texto_btn
	btn.custom_minimum_size = Vector2(300, 52)
	btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 22)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb_n = _stylebox(Color(0.1, 0.45, 0.2, 0.9), Color("#62ff86"), 2, 6)
	var sb_h = _stylebox(Color(0.15, 0.6, 0.25, 0.95), Color("#62ff86"), 3, 6)
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	
	btn.pressed.connect(func():
		_play(sfx_click, 1.0)
		_concluir_jogo()
	)
	return btn


func _concluir_jogo() -> void:
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false
	FadeManager.carregar_cena("res://ASSETS/CENAS/TelaFinal.tscn")


func _play(player: AudioStreamPlayer, pitch: float) -> void:
	if player:
		player.pitch_scale = pitch
		player.play()


func _limpar(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _button(texto_btn: String, cor: Color, tamanho: int) -> Button:
	var btn := Button.new()
	btn.text = texto_btn
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", tamanho)
	btn.add_theme_color_override("font_color", Color("#21180f"))
	btn.add_theme_color_override("font_hover_color", Color("#000000"))
	btn.add_theme_stylebox_override("normal", _stylebox(cor, Color("#2b2118"), 2, 6))
	btn.add_theme_stylebox_override("hover", _stylebox(cor.lightened(0.18), Color("#fff4d6"), 2, 6))
	btn.add_theme_stylebox_override("pressed", _stylebox(cor.darkened(0.16), Color("#fff4d6"), 2, 6))
	return btn


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


func _panel(bg: Color, border: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _stylebox(bg, border, 2, 6))
	return p


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
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
