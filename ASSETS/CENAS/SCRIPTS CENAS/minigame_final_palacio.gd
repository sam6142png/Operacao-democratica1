extends Control

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const FONTE_MONO = preload("res://ASSETS/FONTES/dogicapixel.ttf")
const BG_TEX = preload("res://ASSETS/SPRITES/FUNDOS/O Comandante das Ruínas.png")
var DANTE_TEX: Texture2D
var DANTE_FALA_TEX: Texture2D
const VILAO_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/Vilão/cara maléfica sem fundo.png")
const VILAO_RAIVA_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/Vilão/raiva sem fundo.png")
const VILAO_ASSUSTADO_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/Vilão/assustado sem fundo.png")
const VILAO_RINDO_TEX = preload("res://ASSETS/SPRITES/PERSONAGENS/Vilão/rindo com um tim meio irônico sem fundo.png")
const CLICK_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesClick.mp3")
const HOVER_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesHover.mp3")
const HIT_SOUND = preload("res://ASSETS/SOUNDS/FSX/Impacto/impacto_radio_militar.mp3")
const STINGER_SOUND = preload("res://ASSETS/SOUNDS/FSX/Tensao/stinger_tensao.mp3")
const HEARTBEAT_ANX = preload("res://ASSETS/SOUNDS/FSX/Tensao/heartbeat_ansiedade.mp3")

const MAX_INFLUENCE: int = 100
const QTE_TIME: float = 6.0

# === ESTRUTURAS DE DADOS DO DEBATE ===
const PROOFS: Dictionary = {
	"radio": {"nome": "Prova da Rádio", "texto": "A transmissão interceptada prova censura e mentiras oficiais."},
	"livro": {"nome": "Direitos e Deveres do Povo", "texto": "O livro prova que as liberdades civis existiam antes da ditadura."},
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
var golpe_emocional_concluido: bool = false
var ekg_peak_pos: float = 1.0
var peak_hit_in_this_cycle: bool = false
var selected_evidence_id: String = ""

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
var lbl_vilao: RichTextLabel
var lbl_dante: Label
var lbl_reacao: Label
var choices_box: VBoxContainer
var qte_panel: PanelContainer
var qte_draw_control: Control
var final_box: VBoxContainer
var dante_sprite: TextureRect
var vilao_sprite: TextureRect
var lbl_feedback: Label

# Audio & Camera Director State
var sfx_click: AudioStreamPlayer
var sfx_hover: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_stinger: AudioStreamPlayer
var heartbeat_player: AudioStreamPlayer

var talk_timer: float = 0.0
var is_dante_talking: bool = false
var is_vilao_talking: bool = false
var camera_zoom: float = 1.0
var camera_offset: Vector2 = Vector2.ZERO
var ekg_bpm: float = 75.0
var overlay_vignette: ColorRect


func _ready() -> void:
	DANTE_TEX = load(GameState.obter_caminho_sprite_dante("Bravo determinado.png"))
	DANTE_FALA_TEX = load(GameState.obter_caminho_sprite_dante("Falando (boca aberta).png"))
	randomize()
	_configurar_audio()
	_configurar_estado_inicial()
	_montar_cena()
	await FadeManager.mostrar_intro_fase(0, "Está tão calado, o gato comeu sua língua?")
	_mostrar_tutorial()


func _process(delta: float) -> void:
	glitch_phase += delta
	
	# Interpolação suave do Zoom e Deslocamento da Câmera
	camera_zoom = lerpf(camera_zoom, 1.0, delta * 3.0)
	camera_offset = camera_offset.lerp(Vector2.ZERO, delta * 3.0)
	
	# Animação labial dos retratos
	if is_dante_talking or is_vilao_talking:
		talk_timer += delta * 12.0
		var mouth_open = int(talk_timer) % 2 == 0
		if is_dante_talking:
			dante_sprite.texture = DANTE_FALA_TEX if mouth_open else DANTE_TEX
		if is_vilao_talking:
			var base_vilao = VILAO_TEX
			if act_index == 1:
				base_vilao = VILAO_RINDO_TEX
			elif act_index == 2:
				base_vilao = VILAO_RAIVA_TEX
			elif act_index == 3:
				base_vilao = VILAO_RINDO_TEX
			vilao_sprite.texture = VILAO_RINDO_TEX if mouth_open else base_vilao

	# Sistema de Shake e Diretor de Câmera
	if main_panel:
		var base_pos = Vector2(310, 34)
		var final_pos = base_pos + camera_offset
		if shake_time > 0.0:
			shake_time = max(0.0, shake_time - delta)
			var shake_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
			final_pos += shake_offset
		main_panel.position = final_pos
		main_panel.scale = main_panel.scale.lerp(Vector2.ONE * camera_zoom, delta * 6.0)
		main_panel.pivot_offset = main_panel.size / 2.0

	# Escalonamento dos retratos para acompanhar o Zoom
	if dante_sprite:
		var target_scale = Vector2.ONE * (1.0 + (camera_zoom - 1.0) * 0.45)
		dante_sprite.scale = dante_sprite.scale.lerp(target_scale, delta * 6.0)
		dante_sprite.pivot_offset = Vector2(dante_sprite.size.x / 2.0, dante_sprite.size.y)
	if vilao_sprite:
		var target_scale = Vector2.ONE * (1.0 + (camera_zoom - 1.0) * 0.45)
		vilao_sprite.scale = vilao_sprite.scale.lerp(target_scale, delta * 6.0)
		vilao_sprite.pivot_offset = Vector2(vilao_sprite.size.x / 2.0, vilao_sprite.size.y)

	# Tremor do pânico emocional
	if panic_active:
		if lbl_vilao:
			lbl_vilao.position = Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0))
		if lbl_dante:
			lbl_dante.position = Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0))
			
	# Atualiza o QTE de respiração (EKG Deslizante)
	if step == "heartbeat_qte":
		if heartbeat_player and not heartbeat_player.playing:
			heartbeat_player.play()
		if heartbeat_player:
			var target_pitch = 1.0 + (1.0 - (estabilidade_emocional / 100.0)) * 0.45
			heartbeat_player.pitch_scale = lerpf(heartbeat_player.pitch_scale, target_pitch, delta * 2.0)
			var target_vol = -15.0 + (1.0 - (estabilidade_emocional / 100.0)) * 12.0
			heartbeat_player.volume_db = lerpf(heartbeat_player.volume_db, target_vol, delta * 2.0)

		# Dificuldade do batimento cardíaco (aceleração do QTE com base na perda de estabilidade)
		var qte_speed = 1.0 + (1.0 - (estabilidade_emocional / 100.0)) * 0.8
		ekg_peak_pos -= delta * qte_speed
		
		# Verifica se a onda passou da janela de acerto sem ser acertada
		var janela = _obter_janela_qte()
		if ekg_peak_pos < (janela[0] - 0.02) and not peak_hit_in_this_cycle:
			# Miss automático por deixar passar!
			peak_hit_in_this_cycle = true
			qte_successes = 0
			estabilidade_emocional = max(0.0, estabilidade_emocional - 12.0)
			_play(sfx_stinger, 1.0)
			_shake(12.0, 0.3)
			_screen_flash(Color(1, 0.2, 0.2, 0.2), 0.3)
			
			qte_ripple_radius = 5.0
			qte_ripple_alpha = 1.0
			var tw_rip = create_tween()
			tw_rip.set_parallel(true)
			tw_rip.tween_property(self, "qte_ripple_radius", 180.0, 0.4).set_ease(Tween.EASE_OUT)
			tw_rip.tween_property(self, "qte_ripple_alpha", 0.0, 0.4)
			_atualizar_barras()
			
		if ekg_peak_pos < 0.0:
			ekg_peak_pos = 1.0
			peak_hit_in_this_cycle = false
			
		if qte_draw_control:
			qte_draw_control.queue_redraw()
	else:
		if heartbeat_player and heartbeat_player.playing:
			heartbeat_player.volume_db = lerpf(heartbeat_player.volume_db, -40.0, delta * 4.0)
			if heartbeat_player.volume_db <= -38.0:
				heartbeat_player.stop()

	if fx_layer:
		fx_layer.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if step != "heartbeat_qte" or not event.is_pressed():
		return
		
	# Tecla ESPAÇO no tempo do EKG
	if event.is_action_pressed("ui_accept"):
		var janela = _obter_janela_qte()
		if ekg_peak_pos >= janela[0] and ekg_peak_pos <= janela[1] and not peak_hit_in_this_cycle:
			qte_successes += 1
			peak_hit_in_this_cycle = true
			_play(sfx_click, 1.25)
			
			# Ripple de sucesso verde
			qte_ripple_radius = 5.0
			qte_ripple_alpha = 1.0
			var tw_rip = create_tween()
			tw_rip.set_parallel(true)
			tw_rip.tween_property(self, "qte_ripple_radius", 220.0, 0.45).set_ease(Tween.EASE_OUT)
			tw_rip.tween_property(self, "qte_ripple_alpha", 0.0, 0.45)
			
			# Avança o pico levemente para que passe da janela de acerto
			ekg_peak_pos = janela[0] - 0.05
			
			if qte_successes >= 3:
				_sucesso_heartbeat()
		else:
			# Miss/Double hit/Errado
			qte_successes = 0 # Reinicia o combo se errar
			peak_hit_in_this_cycle = true # Impede miss automático redundante neste ciclo
			estabilidade_emocional = max(0.0, estabilidade_emocional - 15.0)
			_play(sfx_stinger, 1.0)
			_shake(15.0, 0.35)
			_screen_flash(Color(1, 0.2, 0.2, 0.25), 0.35)
			
			# Ripple de erro vermelho
			qte_ripple_radius = 5.0
			qte_ripple_alpha = 1.0
			var tw_rip = create_tween()
			tw_rip.set_parallel(true)
			tw_rip.tween_property(self, "qte_ripple_radius", 220.0, 0.45).set_ease(Tween.EASE_OUT)
			tw_rip.tween_property(self, "qte_ripple_alpha", 0.0, 0.45)
			
			# Se errou, acelera o pico para sair da janela
			if ekg_peak_pos > janela[0]:
				ekg_peak_pos = janela[0] - 0.05
				
			_atualizar_barras()


func _configurar_audio() -> void:
	sfx_click = _audio(CLICK_SOUND)
	sfx_hover = _audio(HOVER_SOUND)
	sfx_hit = _audio(HIT_SOUND)
	sfx_stinger = _audio(STINGER_SOUND)
	heartbeat_player = _audio(HEARTBEAT_ANX)


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
	lbl_vilao = RichTextLabel.new()
	lbl_vilao.bbcode_enabled = true
	lbl_vilao.custom_minimum_size = Vector2(0, 100)
	lbl_vilao.add_theme_font_override("normal_font", FONTE)
	lbl_vilao.add_theme_font_size_override("normal_font_size", 24)
	lbl_vilao.add_theme_color_override("default_color", Color("#fff4d6"))
	lbl_vilao.scroll_active = false
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
	_limpar(choices_box)
	qte_panel.visible = false
	
	if popular >= MAX_INFLUENCE or regime >= MAX_INFLUENCE or act_index >= ACTS.size():
		_finalizar_confronto()
		return

	# Checa se é o momento do Golpe Emocional (Morte dos pais no Ato 4, índice 3)
	if act_index == 3 and not golpe_emocional_concluido:
		_iniciar_golpe_emocional()
		return

	step = "debate"
	act_score = 0
	selected_evidence_id = ""
	
	var act: Dictionary = ACTS[act_index] as Dictionary
	lbl_step.text = "TRIBUNAL DA VERDADE - ATO " + str(act_index + 1) + "/" + str(ACTS.size())
	
	# O Vilão começa falando no debate
	is_vilao_talking = true
	is_dante_talking = false
	camera_zoom = 1.05
	camera_offset = Vector2(50.0, 0.0)
	_definir_fala_vilao(str(act["fala"]))
	
	lbl_dante.text = "Abra o Dossiê de Evidências para encontrar a prova cívica contra o Coronel."
	lbl_reacao.text = "A multidão lá fora assiste à transmissão com atenção."
	
	dante_sprite.texture = DANTE_TEX
	vilao_sprite.texture = VILAO_TEX
	_atualizar_barras()
	_mostrar_opcoes_debate()
	_vilao_bounce()


func _mostrar_opcoes_debate() -> void:
	_limpar(choices_box)
	
	var btn_dossie := Button.new()
	btn_dossie.text = " ▸ ABRIR DOSSIÊ DE EVIDÊNCIAS "
	btn_dossie.custom_minimum_size = Vector2(0, 52)
	btn_dossie.add_theme_font_override("font", FONTE)
	btn_dossie.add_theme_font_size_override("font_size", 20)
	btn_dossie.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb_n = _stylebox(Color("#142238", 0.94), Color("#54d6ff"), 2, 6)
	var sb_h = _stylebox(Color("#1d3152", 0.98), Color("#54d6ff"), 3, 6)
	btn_dossie.add_theme_stylebox_override("normal", sb_n)
	btn_dossie.add_theme_stylebox_override("hover", sb_h)
	btn_dossie.add_theme_stylebox_override("pressed", sb_h)
	
	btn_dossie.mouse_entered.connect(func():
		if sfx_hover: sfx_hover.play()
	)
	btn_dossie.pressed.connect(_on_abrir_dossie_pressed)
	choices_box.add_child(btn_dossie)


func _on_abrir_dossie_pressed() -> void:
	_play(sfx_click, 1.0)
	_abrir_dossie()


func _abrir_dossie() -> void:
	selected_evidence_id = ""
	
	var overlay = CanvasLayer.new()
	overlay.layer = 97
	add_child(overlay)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	overlay.add_child(bg)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(960, 620)
	panel.set_anchors_preset(PRESET_CENTER)
	panel.grow_horizontal = GROW_DIRECTION_BOTH
	panel.grow_vertical = GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.12, 0.99)
	sb.border_width_left = 3; sb.border_width_top = 3
	sb.border_width_right = 3; sb.border_width_bottom = 3
	sb.border_color = Color("#54d6ff")
	sb.corner_radius_top_left = 12; sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12; sb.corner_radius_bottom_right = 12
	sb.shadow_size = 22
	sb.shadow_color = Color("#54d6ff", 0.16)
	panel.add_theme_stylebox_override("panel", sb)
	bg.add_child(panel)
	
	var margin = _margin(20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "DOSSIÊ DE EVIDÊNCIAS COLETADAS"
	title.add_theme_font_override("font", FONTE)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#ffe28a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(_divisor())
	
	var pages_hbox = HBoxContainer.new()
	pages_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	pages_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(pages_hbox)
	
	# Página Esquerda: Lista de Evidências
	var left_page = VBoxContainer.new()
	left_page.size_flags_horizontal = SIZE_EXPAND_FILL
	left_page.add_theme_constant_override("separation", 8)
	pages_hbox.add_child(left_page)
	
	var left_hdr = _label("PROVAS FÍSICAS E DEPOIMENTOS", 12, Color("#a2a8b3"), FONTE_MONO)
	left_page.add_child(left_hdr)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_page.add_child(scroll)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	list_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)
	
	# Divisor Central
	var spine = ColorRect.new()
	spine.custom_minimum_size = Vector2(2, 0)
	spine.color = Color("#54d6ff", 0.2)
	pages_hbox.add_child(spine)
	
	# Página Direita: Detalhes da Prova e Ação
	var right_page = PanelContainer.new()
	right_page.size_flags_horizontal = SIZE_EXPAND_FILL
	var sb_right = StyleBoxFlat.new()
	sb_right.bg_color = Color(0.12, 0.1, 0.16, 0.6)
	sb_right.corner_radius_top_left = 6; sb_right.corner_radius_top_right = 6
	sb_right.corner_radius_bottom_left = 6; sb_right.corner_radius_bottom_right = 6
	sb_right.content_margin_left = 16; sb_right.content_margin_right = 16
	sb_right.content_margin_top = 16; sb_right.content_margin_bottom = 16
	right_page.add_theme_stylebox_override("panel", sb_right)
	pages_hbox.add_child(right_page)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 12)
	right_page.add_child(detail_vbox)
	
	var lbl_detail_title = _label("SELECIONE UMA PROVA", 18, Color("#ffe28a"), FONTE_MONO)
	detail_vbox.add_child(lbl_detail_title)
	
	var lbl_detail_tag = _label("", 14, Color("#54d6ff"), FONTE_MONO)
	detail_vbox.add_child(lbl_detail_tag)
	
	var lbl_detail_desc = RichTextLabel.new()
	lbl_detail_desc.bbcode_enabled = true
	lbl_detail_desc.size_flags_vertical = SIZE_EXPAND_FILL
	lbl_detail_desc.add_theme_font_override("normal_font", FONTE)
	lbl_detail_desc.add_theme_font_size_override("normal_font_size", 16)
	lbl_detail_desc.add_theme_color_override("default_color", Color("#ede6d8"))
	detail_vbox.add_child(lbl_detail_desc)
	lbl_detail_desc.text = "Selecione uma evidência da lista à esquerda para analisar seus detalhes e apresentá-la para refutar a alegação do Coronel Antônio."
	
	# Botões de Ação na base da página direita
	var action_hbox = HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 10)
	detail_vbox.add_child(action_hbox)
	
	var btn_present = Button.new()
	btn_present.text = "APRESENTAR EVIDÊNCIA!"
	btn_present.custom_minimum_size = Vector2(200, 42)
	btn_present.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_present.add_theme_font_override("font", FONTE)
	btn_present.add_theme_font_size_override("font_size", 18)
	btn_present.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	btn_present.disabled = true
	
	var sb_pres_n = StyleBoxFlat.new()
	sb_pres_n.bg_color = Color(0.1, 0.45, 0.2, 0.9)
	sb_pres_n.corner_radius_top_left = 6; sb_pres_n.corner_radius_top_right = 6
	sb_pres_n.corner_radius_bottom_left = 6; sb_pres_n.corner_radius_bottom_right = 6
	btn_present.add_theme_stylebox_override("normal", sb_pres_n)
	action_hbox.add_child(btn_present)
	
	# Dados das Provas
	var provas_dossie = [
		{
			"id": "livro",
			"nome": "Livro 'Direitos e Deveres do Povo' (Fase 1)",
			"tag": "[LEGISLAÇÃO / DIREITOS]",
			"desc": "A constituição histórica e o livro de Direitos e Deveres do Povo recuperado na Vila do Açude Seco. Prova que em Usina Velha a soberania pertence ao povo, as liberdades de expressão e reunião são invioláveis, e o voto direto é garantido por lei.",
			"cor": "#ffe28a"
		},
		{
			"id": "radio",
			"nome": "Gravação da Rádio (Fase 2)",
			"tag": "[MÍDIA / CENSURA]",
			"desc": "Fita cassete contendo a transmissão militar de rádio oficial interceptada. Mostra ordens explícitas do Coronel Antônio para censurar notícias regionais, ocultar abusos de poder e propagar falsas narrativas de estabilidade.",
			"cor": "#ff8066"
		},
		{
			"id": "escola",
			"nome": "Jornal Clandestino (Fase 3)",
			"tag": "[DEPOIMENTOS / ESCOLA]",
			"desc": "A edição impressa do jornal estudantil de oposição. Contém relatos detalhados de alunos e professores documentando a repressão diária, ameaças e as tentativas do regime de substituir o ensino livre por obediência cega.",
			"cor": "#54d6ff"
		},
		{
			"id": "praca",
			"nome": "Manifesto da Praça (Fase 2)",
			"tag": "[DEMOCRACIA / SOBERANIA]",
			"desc": "O manifesto assinado em conjunto pelos cidadãos de Usina Velha na Praça Central. Demonstra o desejo do povo pela participação cívica pacífica, eleições livres e o fim imediato do autoritarismo.",
			"cor": "#7bd88f"
		}
	]
	
	var update_evidence_details = func(idx: int):
		var prv = provas_dossie[idx]
		selected_evidence_id = prv["id"]
		lbl_detail_title.text = prv["nome"].to_upper()
		lbl_detail_title.add_theme_color_override("font_color", Color(prv["cor"]))
		lbl_detail_tag.text = prv["tag"]
		lbl_detail_tag.add_theme_color_override("font_color", Color(prv["cor"]).lightened(0.2))
		lbl_detail_desc.text = prv["desc"]
		btn_present.disabled = false
		_play(sfx_click, 1.1)

	for i in range(provas_dossie.size()):
		var prv = provas_dossie[i]
		var btn_prv := Button.new()
		btn_prv.text = " ▣  " + prv["nome"]
		btn_prv.custom_minimum_size = Vector2(0, 44)
		btn_prv.size_flags_horizontal = SIZE_EXPAND_FILL
		btn_prv.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn_prv.add_theme_font_override("font", FONTE)
		btn_prv.add_theme_font_size_override("font_size", 16)
		btn_prv.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		
		var sb_item = StyleBoxFlat.new()
		sb_item.bg_color = Color(0.12, 0.10, 0.18, 0.8)
		sb_item.border_width_left = 3
		sb_item.border_color = Color(prv["cor"])
		btn_prv.add_theme_stylebox_override("normal", sb_item)
		
		var sb_item_h = StyleBoxFlat.new()
		sb_item_h.bg_color = Color(0.18, 0.15, 0.25, 0.95)
		sb_item_h.border_width_left = 4
		sb_item_h.border_color = Color(prv["cor"])
		btn_prv.add_theme_stylebox_override("hover", sb_item_h)
		btn_prv.add_theme_stylebox_override("pressed", sb_item_h)
		
		btn_prv.mouse_entered.connect(func():
			if sfx_hover: sfx_hover.play()
		)
		btn_prv.pressed.connect(update_evidence_details.bind(i))
		list_vbox.add_child(btn_prv)
		
	# Botão de fechar (voltar ao debate)
	var btn_close = Button.new()
	btn_close.text = "FECHAR DOSSIÊ"
	btn_close.custom_minimum_size = Vector2(160, 42)
	btn_close.add_theme_font_override("font", FONTE)
	btn_close.add_theme_font_size_override("font_size", 18)
	btn_close.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color(0.35, 0.35, 0.35, 0.8)
	sb_close.corner_radius_top_left = 6; sb_close.corner_radius_top_right = 6
	sb_close.corner_radius_bottom_left = 6; sb_close.corner_radius_bottom_right = 6
	btn_close.add_theme_stylebox_override("normal", sb_close)
	action_hbox.add_child(btn_close)
	
	btn_close.pressed.connect(func():
		_play(sfx_click, 1.0)
		overlay.queue_free()
	)
	
	btn_present.pressed.connect(func():
		_play(sfx_click, 1.2)
		overlay.queue_free()
		_apresentar_evidencia(selected_evidence_id)
	)


func _apresentar_evidencia(id: String) -> void:
	var act: Dictionary = ACTS[act_index] as Dictionary
	if id == str(act["prova"]):
		act_score = 3
	else:
		act_score = 0
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
		
		is_dante_talking = true
		is_vilao_talking = false
		camera_zoom = 1.10
		camera_offset = Vector2(-70.0, 0.0)
		
		_play(sfx_hit, 1.2)
		_dante_atacar()
		_vilao_damage() # Tremor forte e piscada vermelha pelo sucesso
		_instanciar_projetil_retorico("REFUTADO!", Color("#62ff86"))
		_screen_flash(Color(1, 1, 1, 0.4), 0.4)
	else:
		popular = maxi(0, popular - 12)
		regime = mini(MAX_INFLUENCE, regime + 16)
		estabilidade_emocional = max(0.0, estabilidade_emocional - 20.0)
		dante_sprite.texture = DANTE_TEX
		vilao_sprite.texture = VILAO_RINDO_TEX
		
		var falhas = [
			"Você tenta sustentar suas ideias com jornais clandestinos que ninguém lê, Dante. A realidade da usina não liga para panfletos rasgados.",
			"Essa fita gravada não muda nada. A transmissão da rádio é o que mantém a população calma e obediente. Quem controla o sinal controla a ordem.",
			"Esse livro é apenas papel velho de um passado lento. As decisões eficientes de Usina Velha são tomadas com canetas e fuzis, não com páginas antigas.",
			"Você e seu manifesto não passam de um punhado de rebeldes sem rumo. O progresso econômico exige silêncio, não discussões na praça."
		]
		lbl_dante.text = "Sua retórica falhou. O Coronel Antônio dobra a mentira e abala seu foco."
		lbl_vilao.text = "[center]\"" + falhas[act_index] + "\"[/center]"
		lbl_reacao.text = "Um silêncio tenso toma as ruas."
		
		is_dante_talking = false
		is_vilao_talking = true
		camera_zoom = 1.08
		camera_offset = Vector2(70.0, 0.0)
		
		_play(sfx_stinger, 1.0)
		_shake(12.0, 0.3)
		_screen_flash(Color(1, 0.2, 0.2, 0.3), 0.4)
		
		# Flash vermelho no Dante
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(dante_sprite, "modulate", Color(5.0, 0.2, 0.2), 0.08)
		tw.chain().tween_property(dante_sprite, "modulate", Color.WHITE, 0.15)
		
	_atualizar_barras()
	await get_tree().create_timer(4.5).timeout
	
	is_dante_talking = false
	is_vilao_talking = false
	act_index += 1
	_iniciar_ato()


func _iniciar_golpe_emocional() -> void:
	step = "heartbeat_qte"
	qte_successes = 0
	ekg_peak_pos = 1.0
	peak_hit_in_this_cycle = false
	
	lbl_step.text = "GOLPE PSICOLOGICO - MANTER A CALMA!"
	
	is_vilao_talking = true
	is_dante_talking = false
	camera_zoom = 1.08
	camera_offset = Vector2(60.0, 0.0)
	lbl_vilao.text = "[center]Dante... seu pai era um tolo fraco. Ele preferiu ser um 'mártir' na antiga usina militar a colaborar com a minha paz civica. Eu mesmo ordenei que cortassem a energia dos reatores... com ele preso lá dentro.[/center]"
	
	lbl_dante.text = "Seus batimentos cardíacos estão acelerados! RESPIRE FUNDO. Pressione ESPAÇO no tempo exato em que o pico da onda passar pelo retículo neon verde à esquerda!"
	lbl_reacao.text = "A tensão sobe ao nível máximo no estúdio de transmissão!"
	
	vilao_sprite.texture = VILAO_RINDO_TEX
	dante_sprite.texture = DANTE_TEX
	_play(sfx_stinger, 1.0)
	_vilao_bounce()
	
	_limpar(choices_box)
	qte_panel.visible = true


func _sucesso_heartbeat() -> void:
	golpe_emocional_concluido = true
	step = "debate"
	qte_panel.visible = false
	
	popular = mini(MAX_INFLUENCE, popular + 25)
	regime = maxi(0, regime - 20)
	estabilidade_emocional = 100.0 # Restaura totalmente o foco de Dante!
	
	dante_sprite.texture = DANTE_FALA_TEX
	vilao_sprite.texture = VILAO_ASSUSTADO_TEX
	
	is_dante_talking = true
	is_vilao_talking = false
	camera_zoom = 1.10
	camera_offset = Vector2(-75.0, 0.0)
	
	lbl_dante.text = "Você se conteve com extrema clareza e altivez moral: 'Você os tirou de mim para tentar calar a cidade. Mas a verdade cívica sobre os seus crimes não morre indevidamente em um reator. O povo de Usina Velha agora escuta ao vivo!'"
	lbl_reacao.text = "A multidão ruge em aplausos ensurdecedores do lado de fora!"
	
	_play(sfx_hit, 1.25)
	_shake(20.0, 0.5) # Efeito massivo de sucesso de impacto!
	_screen_flash(Color(1, 1, 1, 0.5), 0.5)
	_instanciar_projetil_retorico("VERDADE REVELADA!", Color("#62ff86"))
	_atualizar_barras()
	
	await get_tree().create_timer(5.0).timeout
	
	is_dante_talking = false
	is_vilao_talking = false
	# Do NOT increment act_index here! We want to play Act 4 now!
	_iniciar_ato()


func _desenhar_qte_heartbeat() -> void:
	var size = qte_draw_control.size
	
	# 1. Desenhar a grade do osciloscópio CRT verde neon de fundo
	var grid_color = Color(0, 0.45, 0.15, 0.08)
	for x in range(0, int(size.x), 20):
		qte_draw_control.draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for y in range(0, int(size.y), 20):
		qte_draw_control.draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
	
	# Desenha ripples de acerto/erro centrados no retículo
	if qte_ripple_alpha > 0.0:
		var center_pt = Vector2(size.x * 0.25, size.y * 0.5)
		var rip_color = Color("#00FF66", qte_ripple_alpha * 0.5) if qte_successes > 0 else Color("#ff3333", qte_ripple_alpha * 0.5)
		qte_draw_control.draw_circle(center_pt, qte_ripple_radius, Color(rip_color, 0.08), true)
		qte_draw_control.draw_circle(center_pt, qte_ripple_radius, rip_color, false, 3.5)
		qte_draw_control.draw_circle(center_pt, qte_ripple_radius * 0.6, Color(rip_color, qte_ripple_alpha * 0.2), false, 1.5)

	# Desenha a caixa alvo ao redor do retículo
	var janela = _obter_janela_qte()
	var target_x = janela[0] * size.x
	var target_w = (janela[1] - janela[0]) * size.x
	
	var target_color = Color(0, 1.0, 0.4, 0.12)
	if int(Time.get_ticks_msec() / 200) % 2 == 0:
		target_color = Color(0, 1.0, 0.4, 0.25)
	qte_draw_control.draw_rect(Rect2(target_x, 0, target_w, size.y), target_color, true)
	qte_draw_control.draw_rect(Rect2(target_x, 0, target_w, size.y), Color("#00FF66", 0.5), false, 2.0)
	
	# Linha do retículo alvo (vertical verde neon brilhante)
	qte_draw_control.draw_line(Vector2(size.x * 0.25, 0), Vector2(size.x * 0.25, size.y), Color("#00FF66", 0.8), 2.0)
	
	# Linha horizontal central
	qte_draw_control.draw_line(Vector2(0, size.y / 2), Vector2(size.x, size.y / 2), Color(0, 0.6, 0.2, 0.35), 2.0)
	
	# Desenha a onda EKG de batimento cardíaco verde fluorescente dinâmica
	var points = PackedVector2Array()
	var steps = 120
	for i in range(steps):
		var t = float(i) / (steps - 1)
		var x = t * size.x
		var y = size.y / 2.0
		
		# CRT noise grain
		y += randf_range(-0.6, 0.6)
		
		var dist_to_peak = t - ekg_peak_pos
		if abs(dist_to_peak) < 0.08:
			var amp_factor = 0.4 + (1.0 - (estabilidade_emocional / 100.0)) * 0.2
			if dist_to_peak < -0.04:
				var local_t = (dist_to_peak + 0.08) / 0.04
				y += sin(local_t * PI) * size.y * 0.08
			elif dist_to_peak < 0.04:
				var local_t = (dist_to_peak + 0.04) / 0.08
				y -= sin(local_t * PI) * size.y * amp_factor
			else:
				var local_t = (dist_to_peak - 0.04) / 0.04
				y += sin(local_t * PI) * size.y * 0.08
				
		points.append(Vector2(x, y))
		
	for i in range(points.size() - 1):
		qte_draw_control.draw_line(points[i], points[i+1], Color("#00FF66", 0.18), 6.0)
		qte_draw_control.draw_line(points[i], points[i+1], Color("#00FF66", 0.8), 2.5)
		qte_draw_control.draw_line(points[i], points[i+1], Color.WHITE, 1.0)
		
	# Indicador de acertos e BPM
	ekg_bpm = lerpf(ekg_bpm, 72.0 + (100.0 - estabilidade_emocional) * 1.1 + randf_range(-2, 2), 0.1)
	var success_txt = "COMPOSURA: " + str(qte_successes) + "/3 BATIMENTOS ESTAVEIS"
	var bpm_txt = "FREQ. CARD: " + str(int(ekg_bpm)) + " BPM"
	var bpm_col = Color("#00FF66") if estabilidade_emocional > 40.0 else Color("#ff3333")
	
	qte_draw_control.draw_string(FONTE_MONO, Vector2(20, size.y - 12), success_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#00FF66"))
	qte_draw_control.draw_string(FONTE_MONO, Vector2(size.x - 220, size.y - 12), bpm_txt, HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, bpm_col)


func _screen_flash(color: Color, duration: float) -> void:
	var flash := ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	
	var tw = flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)
	tw.tween_callback(flash.queue_free)


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
		lbl_vilao.text = "[center]\"Isso... isso não pode estar acontecendo...\"[/center]"
		vilao_sprite.texture = VILAO_ASSUSTADO_TEX
		dante_sprite.texture = DANTE_FALA_TEX
		lbl_dante.text = "A multidão cercou as portas do Palácio Municipal e exige uma decisão sobre o ditador desarmado."
		lbl_reacao.text = "Lembre-se: democracia não pode nascer como vingança pessoal."
		_mostrar_escolha_final()
	else:
		lbl_step.text = "O REGIME MANTEVE O CONTROLE DA MENTE"
		lbl_vilao.text = "[center]\"A ordem cívica prevalece sob qualquer desobediência pacífica.\"[/center]"
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
	
	GameState.desbloquear_conquista("fim_qualquer")
	if resultado == "democratica":
		GameState.desbloquear_conquista("fim_democratico")


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
	panel.custom_minimum_size = Vector2(880, 620)
	panel.set_anchors_preset(PRESET_CENTER)
	panel.grow_horizontal = GROW_DIRECTION_BOTH
	panel.grow_vertical = GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.08, 0.99)
	sb.border_width_left = 3; sb.border_width_top = 3
	sb.border_width_right = 3; sb.border_width_bottom = 3
	sb.border_color = Color("#54d6ff")
	sb.corner_radius_top_left = 12; sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12; sb.corner_radius_bottom_right = 12
	sb.shadow_size = 22
	sb.shadow_color = Color("#54d6ff", 0.16)
	panel.add_theme_stylebox_override("panel", sb)
	bg.add_child(panel)
	
	var margin = _margin(20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Cabeçalho do Livro
	var title = Label.new()
	title.text = "MANUAL DE DEFESA RETÓRICA CÍVICA"
	title.add_theme_font_override("font", FONTE)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#ffe28a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Separador
	vbox.add_child(_divisor())
	
	# Layout de duas páginas (Livro Aberto)
	var pages_hbox = HBoxContainer.new()
	pages_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	pages_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(pages_hbox)
	
	# --- PÁGINA ESQUERDA: LISTA ---
	var left_page = VBoxContainer.new()
	left_page.size_flags_horizontal = SIZE_EXPAND_FILL
	left_page.add_theme_constant_override("separation", 8)
	pages_hbox.add_child(left_page)
	
	var left_hdr = _label("ÍNDICE DE TÁTICAS DE CONTROLE", 12, Color("#a2a8b3"), FONTE_MONO)
	left_page.add_child(left_hdr)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_page.add_child(scroll)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 6)
	list_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)
	
	# --- DIVISOR CENTRAL (COLUNA DO LIVRO) ---
	var spine = ColorRect.new()
	spine.custom_minimum_size = Vector2(2, 0)
	spine.color = Color("#54d6ff", 0.2)
	pages_hbox.add_child(spine)
	
	# --- PÁGINA DIREITA: DETALHE ---
	var right_page = PanelContainer.new()
	right_page.size_flags_horizontal = SIZE_EXPAND_FILL
	var sb_right = StyleBoxFlat.new()
	sb_right.bg_color = Color(0.08, 0.07, 0.12, 0.6)
	sb_right.corner_radius_top_left = 6; sb_right.corner_radius_top_right = 6
	sb_right.corner_radius_bottom_left = 6; sb_right.corner_radius_bottom_right = 6
	sb_right.content_margin_left = 16; sb_right.content_margin_right = 16
	sb_right.content_margin_top = 16; sb_right.content_margin_bottom = 16
	right_page.add_theme_stylebox_override("panel", sb_right)
	pages_hbox.add_child(right_page)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 12)
	right_page.add_child(detail_vbox)
	
	var lbl_detail_title = _label("SELECIONE UMA FALÁCIA", 18, Color("#ffe28a"), FONTE_MONO)
	detail_vbox.add_child(lbl_detail_title)
	
	var lbl_detail_desc = RichTextLabel.new()
	lbl_detail_desc.bbcode_enabled = true
	lbl_detail_desc.size_flags_vertical = SIZE_EXPAND_FILL
	lbl_detail_desc.add_theme_font_override("normal_font", FONTE)
	lbl_detail_desc.add_theme_font_size_override("normal_font_size", 16)
	lbl_detail_desc.add_theme_color_override("default_color", Color("#ede6d8"))
	detail_vbox.add_child(lbl_detail_desc)
	lbl_detail_desc.text = "Clique em qualquer uma das falácias políticas na página esquerda para estudar seu mecanismo de controle, exemplos e os princípios democráticos para combatê-la."
	
	# Dados das Falácias
	var falacias = [
		{"nome": "Paternalismo Autoritário", "desc": "Tratar o povo como incapaz ou imaturo para justificar que o líder tome todas as decisões e mantenha o controle absoluto.", "ex": "\"O povo não sabe discernir sobre economia, deixe que eu decido por vocês.\"", "defesa": "Pensamento Crítico, Educação Cívica e Participação Popular.", "cor": "#ff8066"},
		{"nome": "Censura (Ordem Disfarçada)", "desc": "Silenciar informações ou meios de comunicação alternativos sob o pretexto de 'proteger a paz' ou 'manter a estabilidade social'.", "ex": "\"As transmissões alternativas criam discórdia desnecessária em nossa cidade pacífica.\"", "defesa": "Liberdade de Expressão e Imprensa Independente.", "cor": "#ff8066"},
		{"nome": "Concentração de Poder", "desc": "Alegar que um líder forte deve decidir sozinho, dispensando contrapesos, leis ou julgamentos para ter mais 'eficiência'.", "ex": "\"A justiça comum é muito lenta; um bom governante deve ter o controle de tudo para agir.\"", "defesa": "Divisão de Poderes e Constituição Cívica.", "cor": "#ffa240"},
		{"nome": "Criminalização da Participação", "desc": "Rotular manifestações cívicas legítimas, protestos organizados ou ativismo pacífico como 'desordem' ou 'crime contra a pátria'.", "ex": "\"Quem caminha na praça é baderneiro e inimigo do progresso.\"", "defesa": "Direito de Reunião e Devido Processo.", "cor": "#ff4b4b"},
		{"nome": "Falso Dilema", "desc": "Apresentar a discussão como se existissem apenas duas opções extremas (Ex: ou meu governo autoritário, ou o caos absoluto), omitindo outras vias democráticas.", "ex": "\"Ou vocês aceitam o meu comando rigoroso, ou a anarquia destruirá Usina Velha.\"", "defesa": "Pluralismo Político e Debate de Alternativas.", "cor": "#bda6ff"},
		{"nome": "Apelo ao Medo (Ad Baculum)", "desc": "Instigar pânico ou exagerar ameaças catastróficas para que a população prefira abrir mão de direitos básicos em troca de proteção.", "ex": "\"A usina explodirá se permitirem que comitês civis interfiram na nossa operação militar.\"", "defesa": "Transparência Pública e Dignidade Humana.", "cor": "#ffd447"}
	]
	
	var update_details = func(idx: int):
		var fal = falacias[idx]
		lbl_detail_title.text = fal["nome"].to_upper()
		lbl_detail_title.add_theme_color_override("font_color", Color(fal["cor"]))
		
		var body_txt = "[color=#a2a8b3]DEFINIÇÃO:[/color]\n" + fal["desc"] + "\n\n"
		body_txt += "[color=#ff9c40]EXEMPLO PRÁTICO DO OPRESSOR:[/color]\n[i]" + fal["ex"] + "[/i]\n\n"
		body_txt += "[color=#62ff86]PILAR DE RESISTÊNCIA CÍVICA:[/color]\n" + fal["defesa"]
		lbl_detail_desc.text = body_txt
		_play(sfx_click, 1.1)

	for i in range(falacias.size()):
		var fal = falacias[i]
		var btn_fal := Button.new()
		btn_fal.text = " ▸  " + fal["nome"]
		btn_fal.custom_minimum_size = Vector2(0, 40)
		btn_fal.size_flags_horizontal = SIZE_EXPAND_FILL
		btn_fal.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn_fal.add_theme_font_override("font", FONTE)
		btn_fal.add_theme_font_size_override("font_size", 16)
		btn_fal.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		
		var sb_item = StyleBoxFlat.new()
		sb_item.bg_color = Color(0.10, 0.08, 0.15, 0.8)
		sb_item.border_width_left = 3
		sb_item.border_color = Color(fal["cor"])
		btn_fal.add_theme_stylebox_override("normal", sb_item)
		
		var sb_item_h = StyleBoxFlat.new()
		sb_item_h.bg_color = Color(0.16, 0.13, 0.22, 0.95)
		sb_item_h.border_width_left = 4
		sb_item_h.border_color = Color(fal["cor"])
		btn_fal.add_theme_stylebox_override("hover", sb_item_h)
		btn_fal.add_theme_stylebox_override("pressed", sb_item_h)
		
		btn_fal.mouse_entered.connect(func():
			if sfx_hover: sfx_hover.play()
		)
		
		# Conecta clique para atualizar os detalhes da página direita
		btn_fal.pressed.connect(update_details.bind(i))
		list_vbox.add_child(btn_fal)
		
	# Botão de Voltar
	var btn_close = Button.new()
	btn_close.text = "VOLTAR AO DEBATE"
	btn_close.custom_minimum_size = Vector2(220, 42)
	btn_close.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn_close.add_theme_font_override("font", FONTE)
	btn_close.add_theme_font_size_override("font_size", 20)
	btn_close.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color(0.0, 0.45, 0.7, 0.95)
	sb_close.corner_radius_top_left = 6; sb_close.corner_radius_top_right = 6
	sb_close.corner_radius_bottom_left = 6; sb_close.corner_radius_bottom_right = 6
	btn_close.add_theme_stylebox_override("normal", sb_close)
	
	btn_close.mouse_entered.connect(func():
		if sfx_hover: sfx_hover.play()
	)
	
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
	
	btn.mouse_entered.connect(func():
		if sfx_hover:
			sfx_hover.play()
	)
	
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
	
	btn.mouse_entered.connect(func():
		if sfx_hover:
			sfx_hover.play()
	)
	
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
	
	btn.mouse_entered.connect(func():
		if sfx_hover:
			sfx_hover.play()
	)
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


# === AAA HELPERS ===

func _obter_janela_qte() -> Array[float]:
	var centro = 0.25
	var base_metade_largura = 0.065
	var metade_largura = base_metade_largura * (0.4 + 0.6 * (estabilidade_emocional / 100.0))
	return [centro - metade_largura, centro + metade_largura]


func _instanciar_projetil_retorico(texto_proj: String, cor_proj: Color) -> void:
	var proj := Label.new()
	proj.text = texto_proj
	proj.add_theme_font_override("font", FONTE)
	proj.add_theme_font_size_override("font_size", 28)
	proj.add_theme_color_override("font_color", cor_proj)
	proj.add_theme_color_override("font_shadow_color", Color.BLACK)
	proj.add_theme_constant_override("shadow_offset_x", 3)
	proj.add_theme_constant_override("shadow_offset_y", 3)
	
	var start_pos = Vector2(240, 360)
	var end_pos = Vector2(get_viewport_rect().size.x - 240, 320)
	proj.position = start_pos
	proj.scale = Vector2(0.2, 0.2)
	proj.pivot_offset = Vector2(100, 15)
	layer.add_child(proj)
	
	var tw = proj.create_tween()
	tw.set_parallel(true)
	tw.tween_property(proj, "position", end_pos, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(proj, "scale", Vector2(1.5, 1.5), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(proj, "scale", Vector2(0.1, 0.1), 0.2).set_delay(0.1)
	tw.chain().tween_callback(proj.queue_free)


func _definir_fala_vilao(txt: String) -> void:
	var final_txt = txt
	if act_index == 0:
		final_txt = final_txt.replace("incapaz", "[color=#ff5c5c]incapaz[/color]")
		final_txt = final_txt.replace("decido por todos", "[color=#ff9c40]decido por todos[/color]")
	elif act_index == 1:
		final_txt = final_txt.replace("imprensa livre", "[color=#ff5c5c]imprensa livre[/color]")
		final_txt = final_txt.replace("controle da rádio", "[color=#ff9c40]controle da rádio[/color]")
	elif act_index == 2:
		final_txt = final_txt.replace("leis antigas", "[color=#ff5c5c]leis antigas[/color]")
		final_txt = final_txt.replace("decidir sozinho", "[color=#ff9c40]decidir sozinho[/color]")
	elif act_index == 3:
		final_txt = final_txt.replace("vandalismo", "[color=#ff5c5c]vandalismo[/color]")
		final_txt = final_txt.replace("inimigo do progresso", "[color=#ff9c40]inimigo do progresso[/color]")
	
	lbl_vilao.text = "[center]" + final_txt + "[/center]"


func _divisor() -> ColorRect:
	var div = ColorRect.new()
	div.color = Color("#ffe28a", 0.2)
	div.custom_minimum_size = Vector2(0, 2)
	return div
