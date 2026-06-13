extends Control

const GAME_SCENE = "res://ASSETS/CENAS/game_scene.tscn"

@onready var jogar_botao: Button = $JogarBotao
@onready var opcoes_botao: Button = $OpçõesBotao
@onready var creditos_botao: Button = $CréditosBotao
@onready var sair_botao: Button = $SairBotao

var botoes: Array = []
var overlay: ColorRect
var neon_cursor: ColorRect
var modal_dimmer: ColorRect

var painel_opcoes: Panel
var painel_creditos: Panel
var painel_sair: Panel
var painel_personalizar: Panel
var painel_modo: Panel
var painel_ativo: Panel = null
var rastro_fogo: CPUParticles2D
var menu_container: MarginContainer
var vbox_botoes: VBoxContainer
var _current_tb_idx: int = 0

# Tipografia Exclusiva para Botões Principais
@onready var dogica_font = preload("res://ArticaPro-Bold.ttf")

# Cores Neon (Premium/Cyberpunk)
const C_NEON_LARANJA = Color("#FF8C00")
const C_NEON_VERMELHO = Color("#FF2222")
const C_NEON_VERDE = Color("#22FF55")

const BASE_X = 100.0

# === ESTADO DAS CONFIGURAÇÕES ===
var config = {
	"tela_cheia": 1 if OS.has_feature("web") else 0, # 0 = Ligado (Fullscreen), 1 = Desligado (Janela)
	"resolucao": 1,
	"vol_musica": 50.0,
	"vol_sfx": 50.0,
	"vel_dialogos": 1.0, # multiplicador: 1.0 = normal, 2.0 = máximo
	"auto_avanco": 0,
	"auto_avanco_delay": 2.5,
	"pular_lidos": 1,
	"tamanho_fonte": 0,
}
var ui_refs = {}

const LOCALE_PADRAO = "pt"
const TELA_CHEIA_OPCOES = ["Ligado", "Desligado"]
var TR = {
	"jogar":        {"pt": "Novo Jogo",      "en": "New Game",       "es": "Nuevo Juego",    "fr": "Nouveau Jeu"},
	"continuar":    {"pt": "Continuar",      "en": "Continue",       "es": "Continuar",      "fr": "Continuer"},
	"personalizar": {"pt": "Personalizar",   "en": "Customize",      "es": "Personalizar",   "fr": "Personnaliser"},
	"opcoes":       {"pt": "Opções",         "en": "Options",        "es": "Opciones",       "fr": "Options"},
	"creditos":     {"pt": "Créditos",       "en": "Credits",        "es": "Créditos",       "fr": "Crédits"},
	"sair":         {"pt": "Sair",           "en": "Quit",           "es": "Salir",          "fr": "Quitter"},
	"config_titulo":{"pt": "CONFIGURAÇÕES",  "en": "SETTINGS",       "es": "CONFIGURACIÓN",  "fr": "PARAMÈTRES"},
	"musica":       {"pt": "Música",         "en": "Music",          "es": "Música",         "fr": "Musique"},
	"sfx":          {"pt": "Efeitos Sonoros","en": "Sound Effects",  "es": "Efectos de Sonido","fr": "Effets Sonores"},
	"tela_cheia":   {"pt": "Tela Cheia",     "en": "Fullscreen",     "es": "Pantalla Completa","fr": "Plein Écran"},
	"resolucao":    {"pt": "Resolução",      "en": "Resolution",     "es": "Resolución",     "fr": "Résolution"},
	"vel_dialogos": {"pt": "Velocidade dos Diálogos", "en": "Dialogue Speed", "es": "Velocidad de Diálogos", "fr": "Vitesse des Dialogues"},
	"auto_avanco":      {"pt": "Auto-Avanço de Diálogos", "en": "Auto-Advance Dialogue"},
	"auto_avanco_delay":{"pt": "Intervalo de Avanço",      "en": "Advance Delay"},
	"pular_lidos":      {"pt": "Pular Diálogos Lidos Apenas", "en": "Skip Read Dialogue Only"},
	"tamanho_fonte":    {"pt": "Tamanho da Fonte",         "en": "Font Size"},
	"desligado":        {"pt": "Desligado", "en": "Off"},
	"ligado":           {"pt": "Ligado", "en": "On"},
	"nao":              {"pt": "Não", "en": "No"},
	"sim":              {"pt": "Sim", "en": "Yes"},
	"normal":           {"pt": "Normal", "en": "Normal"},
	"grande":           {"pt": "Grande", "en": "Large"},
	"muito_grande":     {"pt": "Muito Grande", "en": "Extra Large"},
	"voltar":       {"pt": "Voltar",         "en": "Back",           "es": "Volver",         "fr": "Retour"},
	"restaurar":    {"pt": "Restaurar Padrões","en": "Restore Defaults","es": "Restaurar",   "fr": "Par Défaut"},
	"aplicar":      {"pt": "Aplicar",        "en": "Apply",          "es": "Aplicar",        "fr": "Appliquer"},
	"cred_titulo":  {"pt": "CRÉDITOS",       "en": "CREDITS",        "es": "CRÉDITOS",       "fr": "CRÉDITS"},
	"sair_pergunta":{"pt": "Deseja cancelar a missão\ne parar de lutar?", "en": "Do you want to abort the mission\nand stop fighting?", "es": "¿Deseas cancelar la misión\ny dejar de luchar?", "fr": "Voulez-vous annuler la mission\net arrêter de lutter ?"},
	"sair_sim":     {"pt": "Amarelar (Sair)","en": "Chicken Out (Quit)","es": "Cobardear (Salir)","fr": "Abandonner (Quitter)"},
	"sair_nao":     {"pt": "Continuar a Luta","en": "Keep Fighting",  "es": "Seguir Luchando","fr": "Continuar le Combat"},
	"direitos":     {"pt": "Todos os direitos reservados.", "en": "All rights reserved.", "es": "Todos los derechos reservados.", "fr": "Tous droits réservés."},
	"equipe":       {"pt": "EQUIPE DE DESENVOLVIMENTO", "en": "DEVELOPMENT TEAM", "es": "EQUIPO DE DESARROLLO", "fr": "ÉQUIPE DE DÉVELOPPEMENT"},
	"prog":         {"pt": "Programação e Liderança", "en": "Programming & Leadership", "es": "Programación y Liderazgo", "fr": "Programmation et Direction"},
	"vice":         {"pt": "Vice Liderança", "en": "Vice Leadership", "es": "Vice Liderazgo", "fr": "Vice Direction"},
	"roteiro":      {"pt": "ROTEIRO & NARRATIVA", "en": "SCRIPT & NARRATIVE", "es": "GUIÓN & NARRATIVA", "fr": "SCÉNARIO & RÉCIT"},
	"arte":         {"pt": "ARTE & DESIGN", "en": "ART & DESIGN", "es": "ARTE & DISEÑO", "fr": "ART & DESIGN"},
	"audio":        {"pt": "ÁUDIO", "en": "AUDIO", "es": "AUDIO", "fr": "AUDIO"},
	"sound_design": {"pt": "Sound Designer", "en": "Sound Designer", "es": "Sound Designer", "fr": "Sound Designer"}
}
var tr_refs = {} # Refs para labels/botões traduzíveis
# =================================

func _t(chave: String) -> String:
	if TR.has(chave) and TR[chave].has(LOCALE_PADRAO):
		return TR[chave][LOCALE_PADRAO]
	return chave

func _ready() -> void:
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").stop_music(0.5)

	# Sincronizar do GameState carregado
	if typeof(GameState) != TYPE_NIL:
		for key in config.keys():
			if key in GameState:
				config[key] = GameState.get(key)

	# Criar o botão Continuar dinamicamente
	var btn_continuar = Button.new()
	btn_continuar.text = "Continuar"
	btn_continuar.name = "ContinuarBotao"
	btn_continuar.pressed.connect(_on_continuar_pressed)
	
	if not GameState.has_save():
		btn_continuar.hide()
		
	# Criar o botão Personalizar dinamicamente
	var btn_personalizar = Button.new()
	btn_personalizar.text = "Personalizar"
	btn_personalizar.name = "PersonalizarBotao"
	btn_personalizar.pressed.connect(_on_personalizar_pressed)
	
	# Salva a posição original do botão Jogar como referência de ancoragem
	var pos_ancora = jogar_botao.position
	
	botoes = [btn_continuar, jogar_botao, btn_personalizar, opcoes_botao, creditos_botao, sair_botao]
	
	# Criar container organizado para evitar sobreposição
	menu_container = MarginContainer.new()
	menu_container.position = pos_ancora
	menu_container.add_theme_constant_override("margin_top", -100 if GameState.has_save() else 0)
	add_child(menu_container)
	
	vbox_botoes = VBoxContainer.new()
	vbox_botoes.add_theme_constant_override("separation", 20)
	menu_container.add_child(vbox_botoes)
	
	for btn in botoes:
		if btn.get_parent(): btn.get_parent().remove_child(btn)
		vbox_botoes.add_child(btn)
	
	Input.set_custom_mouse_cursor(null)
	
	_criar_overlay()
	_criar_dimmer()
	_criar_neon_cursor()
	_criar_rastro_fogo()
	_iniciar_breathing_background()
	_alinhar_botoes()
	_configurar_botoes()
	_conectar_sinais()
	_criar_paineis()
	_aplicar_idioma()
	_aplicar_todas_configuracoes(true)

func _process(_delta: float) -> void:
	if rastro_fogo:
		rastro_fogo.global_position = get_global_mouse_position()

func _iniciar_breathing_background() -> void:
	if has_node("bg"):
		var bg = $bg
		# Garante que o fundo cubra tudo sem barras pretas e SEM REPETIR
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
		
		# Centraliza o pivô para escalar a partir do centro
		bg.pivot_offset = bg.size / 2.0
		var t = create_tween().set_loops()
		t.tween_property(bg, "scale", Vector2(1.02, 1.02), 15.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(bg, "scale", Vector2(1.0, 1.0), 15.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
		# Restaurando brilho original para a arte popar!
		bg.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _alinhar_botoes() -> void:
	for btn in botoes:
		btn.custom_minimum_size = Vector2(400, 70)
		btn.pivot_offset = Vector2(200, 35)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_constant_override("h_separation", 15)
	
	if has_node("bg"):
		var bg = $bg
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	
	# Salva posições originais para animações
	await get_tree().process_frame
	for btn in botoes:
		btn.set_meta("pos_original_x", btn.position.x)
		btn.set_meta("pos_global_y", btn.global_position.y)

func _criar_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	add_child(overlay)

func _criar_dimmer() -> void:
	modal_dimmer = ColorRect.new()
	modal_dimmer.color = Color(0, 0, 0, 0)
	modal_dimmer.anchors_preset = Control.PRESET_FULL_RECT
	modal_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_dimmer.z_index = 45 # Logo atrás dos modais
	add_child(modal_dimmer)

func _criar_rastro_fogo() -> void:
	rastro_fogo = CPUParticles2D.new()
	add_child(rastro_fogo)
	
	rastro_fogo.amount = 45
	rastro_fogo.lifetime = 0.6
	rastro_fogo.explosiveness = 0.05
	rastro_fogo.randomness = 0.8
	rastro_fogo.local_coords = false # Rastro fica no mundo
	rastro_fogo.draw_order = CPUParticles2D.DRAW_ORDER_LIFETIME
	
	# Forma das partículas
	rastro_fogo.direction = Vector2(0, -1)
	rastro_fogo.spread = 25.0
	rastro_fogo.gravity = Vector2(0, -150) # Sobe como fogo
	rastro_fogo.initial_velocity_min = 20.0
	rastro_fogo.initial_velocity_max = 50.0
	rastro_fogo.angular_velocity_min = -100.0
	rastro_fogo.angular_velocity_max = 100.0
	
	# Escala (diminuindo)
	rastro_fogo.scale_amount_min = 2.0
	rastro_fogo.scale_amount_max = 5.0
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0.2))
	rastro_fogo.scale_amount_curve = curve
	
	rastro_fogo.lifetime = 0.8
	
	# Cores (Degradê de Fogo Neon)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color("#FFEE00")) # Amarelo núcleo
	gradient.add_point(0.3, Color("#FF8C00")) # Laranja chama
	gradient.add_point(0.7, Color("#FF2222")) # Vermelho borda
	gradient.add_point(1.0, Color("#FF2222", 0)) # Transparente no fim
	rastro_fogo.color_ramp = gradient
	
	# Mistura aditiva para brilhar
	rastro_fogo.preprocess = 0.1
	rastro_fogo.z_index = -5 # ATRÁS DE TUDO para não bugar a visão da UI

func _criar_neon_cursor() -> void:
	neon_cursor = ColorRect.new()
	neon_cursor.size = Vector2(420, 3) 
	neon_cursor.color = C_NEON_LARANJA
	neon_cursor.modulate.a = 0.0 # Garantir invisibilidade inicial
	neon_cursor.z_index = -1
	add_child(neon_cursor)

func _configurar_botoes() -> void:
	for btn in botoes:
		if btn.name == "ContinuarBotao":
			_aplicar_estilo_principal(btn, C_NEON_VERDE)
		elif btn.name == "PersonalizarBotao":
			_aplicar_estilo_principal(btn, Color("#54d6ff"))
		else:
			_aplicar_estilo_principal(btn, C_NEON_LARANJA)

func _aplicar_estilo_principal(btn: Button, cor_destaque: Color) -> void:
	btn.add_theme_font_override("font", dogica_font)
	
	# Hierarquia Harmônica de Tamanhos
	var f_size = 38 # Padrão para os principais
	if btn.name in ["OpçõesBotao", "CréditosBotao", "PersonalizarBotao"]: f_size = 28
	if btn.name == "SairBotao": f_size = 22
	
	btn.add_theme_font_size_override("font_size", f_size)
	
	# === ESTILO NORMAL (Glassmorphism + Achatado) ===
	var estilo_normal = StyleBoxFlat.new()
	estilo_normal.bg_color = Color(1.0, 1.0, 1.0, 0.06) # Translúcido como vidro fosco
	estilo_normal.border_width_left = 1
	estilo_normal.border_width_right = 1
	estilo_normal.border_width_top = 1
	estilo_normal.border_width_bottom = 1
	estilo_normal.border_color = Color(1.0, 1.0, 1.0, 0.15)
	estilo_normal.corner_radius_top_left = 6
	estilo_normal.corner_radius_top_right = 6
	estilo_normal.corner_radius_bottom_right = 6
	estilo_normal.corner_radius_bottom_left = 6
	
	# Margens reduzidas para ficarem mais finos e elegantes
	estilo_normal.content_margin_left = 35
	estilo_normal.content_margin_right = 35
	estilo_normal.content_margin_top = 16
	estilo_normal.content_margin_bottom = 16
	
	# === ESTILO HOVER (Preenchimento Tátil Sólido) ===
	var estilo_hover = estilo_normal.duplicate()
	estilo_hover.bg_color = cor_destaque # O fundo inteiro vira Laranja/Verde
	estilo_hover.border_color = cor_destaque
	estilo_hover.border_width_left = 2
	estilo_hover.border_width_right = 2
	estilo_hover.border_width_top = 2
	estilo_hover.border_width_bottom = 2
	estilo_hover.shadow_color = cor_destaque
	estilo_hover.shadow_color.a = 0.5
	estilo_hover.shadow_size = 25
	
	btn.add_theme_stylebox_override("normal", estilo_normal)
	btn.add_theme_stylebox_override("hover", estilo_hover)
	btn.add_theme_stylebox_override("pressed", estilo_hover)
	btn.add_theme_stylebox_override("focus", estilo_hover)
	
	# Dinâmica de Contraste na Fonte:
	# Branca no estado normal. Preta no hover (para ler em cima do fundo colorido)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.05, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(0.05, 0.05, 0.05, 1.0))
	
	btn.set_meta("cor_neon", cor_destaque)

func _aplicar_estilo_neon(btn: Button, cor_neon: Color, compacto: bool = false) -> void:
	var estilo_vazio = StyleBoxEmpty.new()
	var pad = 10 if compacto else 30
	estilo_vazio.content_margin_left = pad
	estilo_vazio.content_margin_right = pad
	estilo_vazio.content_margin_top = 10
	estilo_vazio.content_margin_bottom = 10
	
	var estilo_glow = StyleBoxFlat.new()
	estilo_glow.bg_color = Color(0.0, 0.0, 0.0, 0.75) # Fundo forte para destaque
	estilo_glow.draw_center = true
	
	estilo_glow.border_width_left = 2
	estilo_glow.border_width_right = 2
	estilo_glow.border_width_top = 2
	estilo_glow.border_width_bottom = 2
	
	estilo_glow.corner_radius_top_left = 6
	estilo_glow.corner_radius_top_right = 6
	estilo_glow.corner_radius_bottom_right = 6
	estilo_glow.corner_radius_bottom_left = 6
	estilo_glow.border_color = cor_neon
	
	estilo_glow.shadow_color = cor_neon
	estilo_glow.shadow_color.a = 0.45
	estilo_glow.shadow_size = 14
	
	estilo_glow.content_margin_left = pad
	estilo_glow.content_margin_right = pad
	estilo_glow.content_margin_top = 10
	estilo_glow.content_margin_bottom = 10
	
	btn.add_theme_stylebox_override("normal", estilo_vazio)
	btn.add_theme_stylebox_override("hover", estilo_glow)
	btn.add_theme_stylebox_override("pressed", estilo_glow)
	btn.add_theme_stylebox_override("focus", estilo_glow)
	
	btn.add_theme_color_override("font_color", Color("#999999"))
	btn.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	btn.add_theme_color_override("font_pressed_color", Color("#FFFFFF"))
	btn.add_theme_color_override("font_focus_color", Color("#FFFFFF"))
	
	btn.set_meta("cor_neon", cor_neon)

func _conectar_sinais() -> void:
	jogar_botao.pressed.connect(_on_jogar_pressed)
	opcoes_botao.pressed.connect(_on_opcoes_pressed)
	creditos_botao.pressed.connect(_on_creditos_pressed)
	sair_botao.pressed.connect(_on_sair_pressed)
	
	for btn in botoes:
		btn.mouse_entered.connect(func(): _on_hover_btn(btn))
		btn.mouse_exited.connect(func(): _on_unhover_btn(btn))

# ── HOVER E INTERAÇÃO (NEON CURSOR) ─────────────────────────
func _on_hover_btn(btn: Button) -> void:
	if has_node("SomHover"):
		$SomHover.pitch_scale = randf_range(0.95, 1.05)
		$SomHover.play()
	
	var cor_btn = btn.get_meta("cor_neon") if btn.has_meta("cor_neon") else C_NEON_LARANJA
	var pos_x_orig = btn.get_meta("pos_original_x") if btn.has_meta("pos_original_x") else btn.position.x
	var pos_y_glob = btn.get_meta("pos_global_y") if btn.has_meta("pos_global_y") else btn.global_position.y
	var cursor_y = pos_y_glob + (btn.size.y / 2.0) - 2.0
	
	# Neon cursor segue a posição GLOBAL Y para ser preciso
	var tw_cursor = create_tween().set_parallel(true)
	neon_cursor.color = cor_btn
	tw_cursor.tween_property(neon_cursor, "size:x", btn.size.x, 0.1)
	tw_cursor.tween_property(neon_cursor, "global_position:y", cursor_y, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw_cursor.tween_property(neon_cursor, "global_position:x", vbox_botoes.global_position.x - 25.0, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw_cursor.tween_property(neon_cursor, "modulate:a", 0.6, 0.15)
	
	# Botão: desliza dentro do container
	var tw = create_tween().set_parallel(true)
	tw.tween_property(btn, "position:x", pos_x_orig + 18.0, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "modulate", Color(1.15, 1.1, 1.0, 1.0), 0.15)

func _on_unhover_btn(btn: Button) -> void:
	var pos_x_orig = btn.get_meta("pos_original_x")
	var tw_cursor = create_tween()
	tw_cursor.tween_property(neon_cursor, "modulate:a", 0.0, 0.25)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(btn, "position:x", pos_x_orig, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.2)
# ────────────────────────────────────────────────────────

# ── SONS E LÓGICA DE CONFIGURAÇÕES ────────────────────────────────────────────────
func _tocar_clique() -> void:
	if has_node("SomClique"):
		$SomClique.pitch_scale = randf_range(0.95, 1.05)
		$SomClique.play()

func _tocar_deslize() -> void:
	if has_node("SomDeslize"):
		$SomDeslize.pitch_scale = randf_range(0.95, 1.02)
		$SomDeslize.play()

func _tocar_fechar() -> void:
	if has_node("SomFechar"):
		$SomFechar.pitch_scale = randf_range(0.95, 1.02)
		$SomFechar.play()

func _aplicar_volume(bus_name: String, value: float) -> void:
	var linear_vol = value / 100.0
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	if linear_vol == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_vol))

func _aplicar_todas_configuracoes(silent: bool = false) -> void:
	if not silent:
		_tocar_clique()
	
	# Fullscreen
	# No Web, não podemos entrar em tela cheia na inicialização (sem interação do usuário)
	if OS.has_feature("web") and silent:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		config["tela_cheia"] = 1
		if typeof(GameState) != TYPE_NIL:
			GameState.tela_cheia = 1
	else:
		if config["tela_cheia"] == 0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	# Resolução (Só tem efeito visual claro se estiver no modo Janela e não for Web)
	var res_map = {
		0: Vector2i(2560, 1440),
		1: Vector2i(1920, 1080),
		2: Vector2i(1600, 900),
		3: Vector2i(1366, 768),
		4: Vector2i(1280, 720),
		5: Vector2i(1024, 576),
		6: Vector2i(854, 480)
	}
	var res = res_map.get(config["resolucao"], Vector2i(1920, 1080))
	
	if not OS.has_feature("web") and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		get_window().size = res
		# Centraliza de forma perfeita no monitor atual (Suporte a múltiplos monitores)
		var tela_atual = DisplayServer.window_get_current_screen()
		var pos_tela = DisplayServer.screen_get_position(tela_atual)
		var tam_tela = DisplayServer.screen_get_size(tela_atual)
		get_window().position = pos_tela + Vector2i((tam_tela - res) / 2.0)

	TranslationServer.set_locale(LOCALE_PADRAO)
	_aplicar_idioma()
	
	# Copia configurações para o GameState global e persiste em arquivo
	if typeof(GameState) != TYPE_NIL:
		GameState.vol_musica = config["vol_musica"]
		GameState.vol_sfx = config["vol_sfx"]
		GameState.vel_dialogos = config["vel_dialogos"]
		GameState.tela_cheia = config["tela_cheia"]
		GameState.resolucao = config["resolucao"]
		GameState.auto_avanco = config["auto_avanco"]
		GameState.auto_avanco_delay = config["auto_avanco_delay"]
		GameState.pular_lidos = config["pular_lidos"]
		GameState.tamanho_fonte = config["tamanho_fonte"]
		GameState.aplicar_configuracoes_globais()
		GameState.salvar_configuracoes()
	
	if not silent:
		_fechar_modal() # Feedback de conclusão


func _restaurar_padroes() -> void:
	_tocar_deslize()
	config = {
		"tela_cheia": 1 if OS.has_feature("web") else 0,
		"resolucao": 1,
		"vol_musica": 50.0,
		"vol_sfx": 50.0,
		"vel_dialogos": 1.0,
		"auto_avanco": 0,
		"auto_avanco_delay": 2.5,
		"pular_lidos": 1,
		"tamanho_fonte": 0,
	}
	
	# Atualiza Visuais imediatamente
	ui_refs["vol_musica"].value = 50.0
	ui_refs["vol_sfx"].value = 50.0
	ui_refs["vel_dialogos"].value = 1.0
	ui_refs["auto_avanco_delay"].value = 2.5
	
	ui_refs["tela_cheia"].text = TELA_CHEIA_OPCOES[config["tela_cheia"]]
	ui_refs["resolucao"].text = "1920x1080"
	
	_aplicar_idioma()
	
	if ui_refs.has("auto_avanco_delay_container"):
		ui_refs["auto_avanco_delay_container"].visible = false
	
	if typeof(GameState) != TYPE_NIL:
		GameState.vol_musica = 50.0
		GameState.vol_sfx = 50.0
		GameState.vel_dialogos = 1.0
		GameState.tela_cheia = config["tela_cheia"]
		GameState.resolucao = 1
		GameState.auto_avanco = 0
		GameState.auto_avanco_delay = 2.5
		GameState.pular_lidos = 1
		GameState.tamanho_fonte = 0
		GameState.aplicar_configuracoes_globais()
		GameState.salvar_configuracoes()

# ────────────────────────────────────────────────────────

func _criar_painel_opcoes() -> void:
	# Painel Base para Modais Centrais
	var estilo_modal = StyleBoxFlat.new()
	estilo_modal.bg_color = Color(0.05, 0.05, 0.05, 0.95)
	estilo_modal.border_width_left = 2
	estilo_modal.border_width_right = 2
	estilo_modal.border_width_top = 2
	estilo_modal.border_width_bottom = 2
	estilo_modal.corner_radius_top_left = 12
	estilo_modal.corner_radius_top_right = 12
	estilo_modal.corner_radius_bottom_right = 12
	estilo_modal.corner_radius_bottom_left = 12
	estilo_modal.border_color = C_NEON_LARANJA
	estilo_modal.shadow_color = C_NEON_LARANJA
	estilo_modal.shadow_color.a = 0.25
	estilo_modal.shadow_size = 25
	
	var viewport_size = Vector2(1920, 1080)
	
	painel_opcoes = Panel.new()
	painel_opcoes.add_theme_stylebox_override("panel", estilo_modal)
	painel_opcoes.size = Vector2(850, 700)
	painel_opcoes.position = (viewport_size - painel_opcoes.size) / 2.0
	painel_opcoes.pivot_offset = painel_opcoes.size / 2.0
	painel_opcoes.z_index = 50
	painel_opcoes.hide()
	add_child(painel_opcoes)
	
	var op_margin = MarginContainer.new()
	op_margin.add_theme_constant_override("margin_top", 30)
	op_margin.add_theme_constant_override("margin_bottom", 30)
	op_margin.add_theme_constant_override("margin_left", 60)
	op_margin.add_theme_constant_override("margin_right", 60)
	op_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_opcoes.add_child(op_margin)
	
	var op_vbox = VBoxContainer.new()
	op_vbox.add_theme_constant_override("separation", 15)
	op_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	op_margin.add_child(op_vbox)
	
	var lbl_opcoes = Label.new()
	lbl_opcoes.text = "CONFIGURAÇÕES"
	lbl_opcoes.add_theme_font_size_override("font_size", 42)
	lbl_opcoes.add_theme_color_override("font_color", Color("#FFFFFF"))
	lbl_opcoes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	op_vbox.add_child(lbl_opcoes)
	
	var sep1 = ColorRect.new()
	sep1.custom_minimum_size = Vector2(0, 2)
	sep1.color = Color(1, 1, 1, 0.15)
	op_vbox.add_child(sep1)
	
	# ScrollContainer no meio para evitar estouro da caixa
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	op_vbox.add_child(scroll)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.add_theme_constant_override("separation", 18)
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_vbox)
	
	var sl_musica = _criar_slider(scroll_vbox, "vol_musica", _t("musica"))
	var sl_sfx = _criar_slider(scroll_vbox, "vol_sfx", _t("sfx"))
	tr_refs["lbl_musica"] = sl_musica.get_parent().get_child(0)
	tr_refs["lbl_sfx"] = sl_sfx.get_parent().get_child(0)
	
	var sl_vel = _criar_slider_vel_dialogos(scroll_vbox)
	tr_refs["lbl_vel_dialogos"] = sl_vel.get_child(0)
	
	var sel_tela = _criar_seletor(scroll_vbox, "tela_cheia", _t("tela_cheia"), TELA_CHEIA_OPCOES)
	var sel_resolucao = _criar_seletor(scroll_vbox, "resolucao", _t("resolucao"), ["2560x1440", "1920x1080", "1600x900", "1366x768", "1280x720", "1024x576", "854x480"])
	
	tr_refs["lbl_opcoes_titulo"] = lbl_opcoes
	tr_refs["lbl_tela_cheia"] = sel_tela.get_child(0)
	tr_refs["lbl_resolucao"] = sel_resolucao.get_child(0)
	
	# Novos Seletores (Narrativos do Tópico 1)
	var sl_delay_container: VBoxContainer = null
	
	# Auto-Avanço
	var sel_auto = _criar_seletor(scroll_vbox, "auto_avanco", _t("auto_avanco"), [_t("desligado"), _t("ligado")], func(v):
		if is_instance_valid(sl_delay_container):
			sl_delay_container.visible = (v == 1)
	)
	tr_refs["lbl_auto_avanco"] = sel_auto.get_child(0)
	ui_refs["auto_avanco"] = sel_auto.get_child(1).get_child(1)
	
	sl_delay_container = _criar_slider_auto_avanco_delay(scroll_vbox)
	tr_refs["lbl_auto_avanco_delay"] = sl_delay_container.get_child(0)
	ui_refs["auto_avanco_delay_container"] = sl_delay_container
	sl_delay_container.visible = (config["auto_avanco"] == 1)
	
	# Pular lidos apenas
	var sel_pular = _criar_seletor(scroll_vbox, "pular_lidos", _t("pular_lidos"), [_t("nao"), _t("sim")])
	tr_refs["lbl_pular_lidos"] = sel_pular.get_child(0)
	ui_refs["pular_lidos"] = sel_pular.get_child(1).get_child(1)
	
	# Tamanho da fonte
	var sel_fonte = _criar_seletor(scroll_vbox, "tamanho_fonte", _t("tamanho_fonte"), [_t("normal"), _t("grande"), _t("muito_grande")])
	tr_refs["lbl_tamanho_fonte"] = sel_fonte.get_child(0)
	ui_refs["tamanho_fonte"] = sel_fonte.get_child(1).get_child(1)
	
	# Rodapé Fixo fora do ScrollContainer
	var sep_bottom = ColorRect.new()
	sep_bottom.custom_minimum_size = Vector2(0, 2)
	sep_bottom.color = Color(1, 1, 1, 0.15)
	op_vbox.add_child(sep_bottom)
	
	var hbox_opcoes_btns = HBoxContainer.new()
	hbox_opcoes_btns.add_theme_constant_override("separation", 20)
	op_vbox.add_child(hbox_opcoes_btns)
	
	var btn_voltar_op = _criar_botao_generico(_t("voltar"), C_NEON_LARANJA)
	btn_voltar_op.pressed.connect(_fechar_modal)
	hbox_opcoes_btns.add_child(btn_voltar_op)
	tr_refs["btn_voltar_op"] = btn_voltar_op
	
	var btn_restaurar = _criar_botao_generico(_t("restaurar"), C_NEON_LARANJA)
	btn_restaurar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_restaurar.pressed.connect(_restaurar_padroes)
	hbox_opcoes_btns.add_child(btn_restaurar)
	tr_refs["btn_restaurar"] = btn_restaurar
	
	var btn_aplicar = _criar_botao_generico(_t("aplicar"), C_NEON_VERDE)
	btn_aplicar.pressed.connect(_aplicar_todas_configuracoes)
	hbox_opcoes_btns.add_child(btn_aplicar)
	tr_refs["btn_aplicar"] = btn_aplicar

func _criar_painel_creditos() -> void:
	var estilo_modal = painel_opcoes.get_theme_stylebox("panel").duplicate()
	var viewport_size = Vector2(1920, 1080)
	
	painel_creditos = Panel.new()
	painel_creditos.add_theme_stylebox_override("panel", estilo_modal)
	painel_creditos.size = Vector2(850, 700)
	painel_creditos.position = (viewport_size - painel_creditos.size) / 2.0
	painel_creditos.pivot_offset = painel_creditos.size / 2.0
	painel_creditos.z_index = 50
	painel_creditos.hide()
	add_child(painel_creditos)
	
	var cr_margin = MarginContainer.new()
	cr_margin.add_theme_constant_override("margin_top", 40)
	cr_margin.add_theme_constant_override("margin_bottom", 40)
	cr_margin.add_theme_constant_override("margin_left", 60)
	cr_margin.add_theme_constant_override("margin_right", 60)
	cr_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_creditos.add_child(cr_margin)
	
	var cr_vbox = VBoxContainer.new()
	cr_vbox.add_theme_constant_override("separation", 20)
	cr_margin.add_child(cr_vbox)
	
	var lbl_cred = Label.new()
	lbl_cred.text = "CRÉDITOS"
	lbl_cred.add_theme_font_size_override("font_size", 42)
	lbl_cred.add_theme_color_override("font_color", Color("#FFFFFF"))
	lbl_cred.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr_vbox.add_child(lbl_cred)
	tr_refs["lbl_cred_titulo"] = lbl_cred
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cr_vbox.add_child(scroll)
	
	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rtl.fit_content = true
	tr_refs["rtl_creditos"] = rtl
	scroll.add_child(rtl)
	
	var btn_voltar_cr = _criar_botao_generico(_t("voltar"), C_NEON_LARANJA)
	btn_voltar_cr.pressed.connect(_fechar_modal)
	btn_voltar_cr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cr_vbox.add_child(btn_voltar_cr)
	tr_refs["btn_voltar_cr"] = btn_voltar_cr
	
func _criar_painel_sair() -> void:
	var viewport_size = Vector2(1920, 1080)
	painel_sair = Panel.new()
	
	var estilo_sair = painel_opcoes.get_theme_stylebox("panel").duplicate()
	estilo_sair.border_color = C_NEON_VERMELHO
	estilo_sair.shadow_color = C_NEON_VERMELHO
	painel_sair.add_theme_stylebox_override("panel", estilo_sair)
	
	painel_sair.size = Vector2(700, 300)
	painel_sair.position = (viewport_size - painel_sair.size) / 2.0
	painel_sair.pivot_offset = painel_sair.size / 2.0
	painel_sair.z_index = 60
	painel_sair.hide()
	add_child(painel_sair)
	
	var sa_vbox = VBoxContainer.new()
	sa_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sa_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	sa_vbox.add_theme_constant_override("separation", 50)
	painel_sair.add_child(sa_vbox)
	
	var lbl_sair = Label.new()
	lbl_sair.text = _t("sair_pergunta")
	lbl_sair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sair.add_theme_font_size_override("font_size", 32)
	lbl_sair.add_theme_color_override("font_color", Color("#FFFFFF"))
	sa_vbox.add_child(lbl_sair)
	tr_refs["lbl_sair_pergunta"] = lbl_sair
	
	var hbox_sair = HBoxContainer.new()
	hbox_sair.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_sair.add_theme_constant_override("separation", 40)
	sa_vbox.add_child(hbox_sair)
	
	var btn_amarelar = _criar_botao_generico(_t("sair_sim"), C_NEON_VERMELHO)
	btn_amarelar.pressed.connect(func():
		_tocar_clique()
		get_tree().quit()
	)
	hbox_sair.add_child(btn_amarelar)
	tr_refs["btn_sair_sim"] = btn_amarelar
	
	var btn_nao = _criar_botao_generico(_t("sair_nao"), C_NEON_VERDE)
	btn_nao.pressed.connect(_fechar_modal)
	hbox_sair.add_child(btn_nao)
	tr_refs["btn_sair_nao"] = btn_nao

# Utils Visuais de Componentes e Funcionalidade de Settings

func _criar_slider_vel_dialogos(pai: Control) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	var lbl = Label.new()
	lbl.text = _t("vel_dialogos")
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color("#CCCCCC"))
	container.add_child(lbl)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)
	
	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(0, 30)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 1.0
	slider.max_value = 2.0
	slider.step = 0.1
	slider.value = config["vel_dialogos"]
	ui_refs["vel_dialogos"] = slider
	hbox.add_child(slider)
	
	var lbl_valor = Label.new()
	lbl_valor.text = "%.1fx" % config["vel_dialogos"]
	lbl_valor.add_theme_font_size_override("font_size", 22)
	lbl_valor.add_theme_color_override("font_color", Color("#FF8C00"))
	lbl_valor.custom_minimum_size.x = 55
	lbl_valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(lbl_valor)
	
	slider.value_changed.connect(func(v: float):
		config["vel_dialogos"] = v
		lbl_valor.text = "%.1fx" % v
		TimelineManager.set_velocidade_dialogos(v)
	)
	
	pai.add_child(container)
	return container


func _criar_slider(pai: Control, chave_config: String, titulo: String) -> HSlider:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	var lbl = Label.new()
	lbl.text = titulo
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color("#CCCCCC"))
	container.add_child(lbl)
	
	var slider = HSlider.new()
	slider.custom_minimum_size.y = 30
	slider.value = config[chave_config]
	ui_refs[chave_config] = slider
	
	slider.value_changed.connect(func(v: float):
		config[chave_config] = v
		if chave_config == "vol_musica": _aplicar_volume("Musica", v)
		elif chave_config == "vol_sfx": _aplicar_volume("SFX", v)
	)
	
	container.add_child(slider)
	pai.add_child(container)
	return slider

func _criar_seletor(pai: Control, chave_config: String, titulo: String, opcoes: Array, on_value_changed: Callable = Callable()) -> HBoxContainer:
	var container = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = titulo
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color("#CCCCCC"))
	container.add_child(lbl)
	
	var seletor = HBoxContainer.new()
	seletor.add_theme_constant_override("separation", 15)
	var btn_esq = Button.new()
	btn_esq.text = " < "
	btn_esq.add_theme_font_size_override("font_size", 24)
	_aplicar_estilo_neon(btn_esq, C_NEON_LARANJA, true)
	seletor.add_child(btn_esq)
	
	var valor = Label.new()
	var idx = config[chave_config]
	valor.text = opcoes[idx]
	ui_refs[chave_config] = valor # Guardar ref para restaurar
	valor.add_theme_font_size_override("font_size", 24)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	valor.custom_minimum_size.x = 220
	seletor.add_child(valor)
	
	var btn_dir = Button.new()
	btn_dir.text = " > "
	btn_dir.add_theme_font_size_override("font_size", 24)
	_aplicar_estilo_neon(btn_dir, C_NEON_LARANJA, true)
	seletor.add_child(btn_dir)
	
	# LOGICA CÍCLICA
	btn_esq.pressed.connect(func():
		_tocar_deslize()
		var i = config[chave_config] - 1
		if i < 0: i = opcoes.size() - 1
		config[chave_config] = i
		valor.text = opcoes[i]
		if on_value_changed.is_valid():
			on_value_changed.call(i)
	)
	btn_dir.pressed.connect(func():
		_tocar_deslize()
		var i = config[chave_config] + 1
		if i >= opcoes.size(): i = 0
		config[chave_config] = i
		valor.text = opcoes[i]
		if on_value_changed.is_valid():
			on_value_changed.call(i)
	)
	
	btn_esq.mouse_entered.connect(func(): _on_hover_container_btn(btn_esq))
	btn_esq.mouse_exited.connect(func(): _on_unhover_container_btn(btn_esq))
	btn_dir.mouse_entered.connect(func(): _on_hover_container_btn(btn_dir))
	btn_dir.mouse_exited.connect(func(): _on_unhover_container_btn(btn_dir))
	
	container.add_child(seletor)
	pai.add_child(container)
	return container


func _criar_slider_auto_avanco_delay(pai: Control) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	var lbl = Label.new()
	lbl.text = _t("auto_avanco_delay")
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color("#CCCCCC"))
	container.add_child(lbl)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)
	
	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(0, 30)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 1.0
	slider.max_value = 5.0
	slider.step = 0.1
	slider.value = config["auto_avanco_delay"]
	ui_refs["auto_avanco_delay"] = slider
	hbox.add_child(slider)
	
	var lbl_valor = Label.new()
	lbl_valor.text = "%.1fs" % config["auto_avanco_delay"]
	lbl_valor.add_theme_font_size_override("font_size", 22)
	lbl_valor.add_theme_color_override("font_color", Color("#FF8C00"))
	lbl_valor.custom_minimum_size.x = 65
	lbl_valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(lbl_valor)
	
	slider.value_changed.connect(func(v: float):
		config["auto_avanco_delay"] = v
		lbl_valor.text = "%.1fs" % v
		if typeof(GameState) != TYPE_NIL and "auto_avanco_delay" in GameState:
			GameState.auto_avanco_delay = v
			if typeof(TimelineManager) != TYPE_NIL:
				TimelineManager.aplicar_config_auto_advance_global()
	)
	
	pai.add_child(container)
	return container

func _aplicar_idioma() -> void:
	# Botões Principais
	jogar_botao.text = _t("jogar")
	opcoes_botao.text = _t("opcoes")
	creditos_botao.text = _t("creditos")
	sair_botao.text = _t("sair")
	
	for btn in botoes:
		if btn.name == "PersonalizarBotao":
			btn.text = _t("personalizar")
		elif btn.name == "ContinuarBotao":
			btn.text = _t("continuar")
	
	# Opções
	if tr_refs.has("lbl_opcoes_titulo"): tr_refs["lbl_opcoes_titulo"].text = _t("config_titulo")
	if tr_refs.has("lbl_musica"): tr_refs["lbl_musica"].text = _t("musica")
	if tr_refs.has("lbl_sfx"): tr_refs["lbl_sfx"].text = _t("sfx")
	if tr_refs.has("lbl_vel_dialogos"): tr_refs["lbl_vel_dialogos"].text = _t("vel_dialogos")
	if tr_refs.has("lbl_tela_cheia"): tr_refs["lbl_tela_cheia"].text = _t("tela_cheia")
	if tr_refs.has("lbl_resolucao"): tr_refs["lbl_resolucao"].text = _t("resolucao")
	if tr_refs.has("lbl_auto_avanco"): tr_refs["lbl_auto_avanco"].text = _t("auto_avanco")
	if tr_refs.has("lbl_auto_avanco_delay"): tr_refs["lbl_auto_avanco_delay"].text = _t("auto_avanco_delay")
	if tr_refs.has("lbl_pular_lidos"): tr_refs["lbl_pular_lidos"].text = _t("pular_lidos")
	if tr_refs.has("lbl_tamanho_fonte"): tr_refs["lbl_tamanho_fonte"].text = _t("tamanho_fonte")
	
	if tr_refs.has("btn_voltar_op"): tr_refs["btn_voltar_op"].text = _t("voltar")
	if tr_refs.has("btn_restaurar"): tr_refs["btn_restaurar"].text = _t("restaurar")
	if tr_refs.has("btn_aplicar"): tr_refs["btn_aplicar"].text = _t("aplicar")
	
	# Atualizar o texto do seletor de tela cheia (Ligado/Desligado)
	var sel_tela_val = ui_refs["tela_cheia"]
	sel_tela_val.text = TELA_CHEIA_OPCOES[config["tela_cheia"]]
	
	# Atualizar seletores novos
	if ui_refs.has("auto_avanco"):
		ui_refs["auto_avanco"].text = _t("ligado") if config["auto_avanco"] == 1 else _t("desligado")
	if ui_refs.has("pular_lidos"):
		ui_refs["pular_lidos"].text = _t("sim") if config["pular_lidos"] == 1 else _t("nao")
	if ui_refs.has("tamanho_fonte"):
		var font_opts = [_t("normal"), _t("grande"), _t("muito_grande")]
		ui_refs["tamanho_fonte"].text = font_opts[config["tamanho_fonte"]]
	
	# Créditos
	if tr_refs.has("lbl_cred_titulo"): tr_refs["lbl_cred_titulo"].text = _t("cred_titulo")
	if tr_refs.has("btn_voltar_cr"): tr_refs["btn_voltar_cr"].text = _t("voltar")
	
	if tr_refs.has("rtl_creditos"):
		var rtl = tr_refs["rtl_creditos"]
		var creditos_texto = """[center]
[color=#FF8C00][font_size=32]%s[/font_size][/color]

[font_size=24]%s[/font_size]
[color=#FFFFFF][font_size=28]Victor Manoel[/font_size][/color]

[font_size=24]%s[/font_size]
[color=#FFFFFF][font_size=28]Samuel Moura[/font_size][/color]

[color=#FF8C00][font_size=32]%s[/font_size][/color]

[color=#FFFFFF][font_size=28]Nicolly Alves
Heitor Tudes[/font_size][/color]

[color=#FF8C00][font_size=32]%s[/font_size][/color]

[color=#FFFFFF][font_size=28]Caike Aguiar
Ana Érica[/font_size][/color]
[color=#FFFFFF][font_size=28]Samuel Moura[/font_size][/color]

[color=#FF8C00][font_size=32]%s[/font_size][/color]

[font_size=24]%s[/font_size]
[color=#FFFFFF][font_size=28]Yara Oliveira[/font_size][/color]

[font_size=20]
Operação Democrática
%s
[/font_size]
[/center]""" % [
			_t("equipe"), _t("prog"), _t("vice"), _t("roteiro"), 
			_t("arte"), _t("audio"), _t("sound_design"), _t("direitos")
		]
		rtl.text = creditos_texto
	
	# Sair
	if tr_refs.has("lbl_sair_pergunta"): tr_refs["lbl_sair_pergunta"].text = _t("sair_pergunta")
	if tr_refs.has("btn_sair_sim"): tr_refs["btn_sair_sim"].text = _t("sair_sim")
	if tr_refs.has("btn_sair_nao"): tr_refs["btn_sair_nao"].text = _t("sair_nao")

func _criar_botao_generico(texto: String, cor: Color) -> Button:
	var btn = Button.new()
	btn.text = texto
	btn.add_theme_font_size_override("font_size", 26)
	_aplicar_estilo_neon(btn, cor)
	btn.mouse_entered.connect(func(): _on_hover_container_btn(btn))
	btn.mouse_exited.connect(func(): _on_unhover_container_btn(btn))
	return btn

# Hover secundário p/ containers (escala ao invés de min_size)
func _on_hover_container_btn(btn: Button) -> void:
	if has_node("SomHover"):
		$SomHover.pitch_scale = randf_range(0.95, 1.05)
		$SomHover.play()
	btn.pivot_offset = btn.size / 2.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "modulate", Color(1.2, 1.15, 1.0, 1.0), 0.12)

func _on_unhover_container_btn(btn: Button) -> void:
	var tw = create_tween().set_parallel(true)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.15)


# Lógica Moderna de Modal Central
func _criar_paineis() -> void:
	_criar_painel_opcoes()
	_criar_painel_creditos()
	_criar_painel_sair()
	_criar_painel_personalizar()
	_criar_painel_modo()

func _abrir_modal(modal: Panel) -> void:
	if painel_ativo != null: return
	_tocar_clique()
	_tocar_deslize()
	painel_ativo = modal
	# Dimmer On
	modal_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw_dim = create_tween()
	tw_dim.tween_property(modal_dimmer, "color:a", 0.78, 0.35).set_ease(Tween.EASE_OUT)
	# Desabilita botões do menu
	for btn in botoes:
		btn.disabled = true
		var tw_hide = create_tween()
		tw_hide.tween_property(btn, "modulate:a", 0.3, 0.25)
	# Pop-up elástico do Modal
	modal.show()
	modal.modulate.a = 0.0
	modal.scale = Vector2(0.7, 0.7)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(modal, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(modal, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

func _fechar_modal() -> void:
	if painel_ativo == null: return
	_tocar_fechar()
	var p = painel_ativo
	painel_ativo = null
	# Dimmer Off
	modal_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw_dim = create_tween()
	tw_dim.tween_property(modal_dimmer, "color:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	# Restaura botões
	for btn in botoes:
		btn.disabled = false
		var tw_show = create_tween()
		tw_show.tween_property(btn, "modulate:a", 1.0, 0.25)
	# Fecha com scale down + fade rápido
	var tween = create_tween().set_parallel(true)
	tween.tween_property(p, "scale", Vector2(0.85, 0.85), 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(p, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func(): p.hide())

func _on_jogar_pressed() -> void:
	_abrir_modal(painel_modo)

func _on_continuar_pressed() -> void:
	GameState.continuar_jogo()

func _iniciar_partida(modo: String) -> void:
	_tocar_clique()
	
	# 1. Preparar os dados ANTES da transição
	await TimelineManager.parar_tudo()
	
	if modo == "novo":
		await GameState.reset_save()
	else:
		GameState.carregar_jogo()
	
	# 2. Transição visual
	for btn in botoes:
		btn.disabled = true
	
	var cena_para_carregar = "res://ASSETS/CENAS/game_scene.tscn"
	if modo == "carregar":
		cena_para_carregar = GameState.cena_atual
		
	FadeManager.carregar_cena(cena_para_carregar)

func _on_opcoes_pressed() -> void:
	_abrir_modal(painel_opcoes)

func _on_creditos_pressed() -> void:
	_abrir_modal(painel_creditos)

func _on_sair_pressed() -> void:
	_abrir_modal(painel_sair)


func _criar_painel_modo() -> void:
	var estilo_modal = painel_opcoes.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	estilo_modal.border_color = C_NEON_LARANJA
	estilo_modal.shadow_color = C_NEON_LARANJA
	
	var viewport_size = Vector2(1920, 1080)
	painel_modo = Panel.new()
	painel_modo.add_theme_stylebox_override("panel", estilo_modal)
	painel_modo.size = Vector2(980, 560)
	painel_modo.position = (viewport_size - painel_modo.size) / 2.0
	painel_modo.pivot_offset = painel_modo.size / 2.0
	painel_modo.z_index = 50
	painel_modo.hide()
	add_child(painel_modo)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_modo.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "SELECIONE O MODO DE JOGO"
	lbl_titulo.add_theme_font_override("font", dogica_font)
	lbl_titulo.add_theme_font_size_override("font_size", 34)
	lbl_titulo.add_theme_color_override("font_color", Color.WHITE)
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_titulo)
	
	var divisor = ColorRect.new()
	divisor.custom_minimum_size.y = 2
	divisor.color = Color(C_NEON_LARANJA, 0.3)
	vbox.add_child(divisor)
	
	var hbox_modos = HBoxContainer.new()
	hbox_modos.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_modos.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox_modos)
	
	# ---- MODO HISTÓRIA ----
	var col_historia = VBoxContainer.new()
	col_historia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_historia.add_theme_constant_override("separation", 15)
	hbox_modos.add_child(col_historia)
	
	var btn_historia = Button.new()
	btn_historia.text = "MODO HISTÓRIA"
	btn_historia.custom_minimum_size = Vector2(0, 75)
	btn_historia.add_theme_font_override("font", dogica_font)
	btn_historia.add_theme_font_size_override("font_size", 22)
	_aplicar_estilo_neon(btn_historia, C_NEON_VERDE)
	col_historia.add_child(btn_historia)
	
	var lbl_desc_historia = Label.new()
	lbl_desc_historia.text = "Experiência clássica e completa. Contém diálogos detalhados, exploração de cenários, cutscenes, escolhas narrativas permanentes e sistema de salvamento."
	lbl_desc_historia.add_theme_font_size_override("font_size", 17)
	lbl_desc_historia.add_theme_color_override("font_color", Color("#cbd7e8"))
	lbl_desc_historia.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_desc_historia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_historia.add_child(lbl_desc_historia)
	
	# ---- MODO MINIGAMES ----
	var col_minigames = VBoxContainer.new()
	col_minigames.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_minigames.add_theme_constant_override("separation", 15)
	hbox_modos.add_child(col_minigames)
	
	var btn_minigames = Button.new()
	btn_minigames.text = "MODO MINIGAMES"
	btn_minigames.custom_minimum_size = Vector2(0, 75)
	btn_minigames.add_theme_font_override("font", dogica_font)
	btn_minigames.add_theme_font_size_override("font_size", 22)
	_aplicar_estilo_neon(btn_minigames, Color("#54d6ff"))
	col_minigames.add_child(btn_minigames)
	
	var lbl_desc_minigames = Label.new()
	lbl_desc_minigames.text = "Experiência rápida focada em jogabilidade. Uma sequência direta dos minigames educativos, sem exploração livre ou salvamento da campanha."
	lbl_desc_minigames.add_theme_font_size_override("font_size", 17)
	lbl_desc_minigames.add_theme_color_override("font_color", Color("#cbd7e8"))
	lbl_desc_minigames.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_desc_minigames.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_minigames.add_child(lbl_desc_minigames)
	
	var divisor2 = ColorRect.new()
	divisor2.custom_minimum_size.y = 1
	divisor2.color = Color(1, 1, 1, 0.1)
	vbox.add_child(divisor2)
	
	var btn_voltar = _criar_botao_generico("VOLTAR", C_NEON_LARANJA)
	btn_voltar.custom_minimum_size = Vector2(240, 50)
	btn_voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_voltar.pressed.connect(_fechar_modal)
	vbox.add_child(btn_voltar)
	
	btn_historia.pressed.connect(func():
		_fechar_modal()
		if typeof(GameState) != TYPE_NIL:
			GameState.is_minigame_mode = false
		_iniciar_partida("novo")
	)
	
	btn_minigames.pressed.connect(func():
		_fechar_modal()
		if typeof(GameState) != TYPE_NIL:
			GameState.preparar_modo_minigames()
		_iniciar_modo_minigames()
	)
	
	btn_historia.mouse_entered.connect(func(): _on_hover_container_btn(btn_historia))
	btn_historia.mouse_exited.connect(func(): _on_unhover_container_btn(btn_historia))
	btn_minigames.mouse_entered.connect(func(): _on_hover_container_btn(btn_minigames))
	btn_minigames.mouse_exited.connect(func(): _on_unhover_container_btn(btn_minigames))

func _iniciar_modo_minigames() -> void:
	_tocar_clique()
	for btn in botoes:
		btn.disabled = true
	FadeManager.carregar_cena("res://ASSETS/CENAS/minigames_mode_controller.tscn")


func _on_personalizar_pressed() -> void:
	if is_instance_valid(painel_personalizar):
		painel_personalizar.name = "painel_personalizar_old"
		painel_personalizar.queue_free()
	_criar_painel_personalizar()
	_abrir_modal(painel_personalizar)


func _criar_painel_personalizar() -> void:
	var estilo_modal = painel_opcoes.get_theme_stylebox("panel").duplicate()
	estilo_modal.border_color = Color("#54d6ff")
	estilo_modal.shadow_color = Color("#54d6ff")
	
	var viewport_size = Vector2(1920, 1080)
	
	painel_personalizar = Panel.new()
	painel_personalizar.add_theme_stylebox_override("panel", estilo_modal)
	painel_personalizar.size = Vector2(1100, 750)
	painel_personalizar.position = (viewport_size - painel_personalizar.size) / 2.0
	painel_personalizar.pivot_offset = painel_personalizar.size / 2.0
	painel_personalizar.z_index = 50
	painel_personalizar.hide()
	add_child(painel_personalizar)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 35)
	margin.add_theme_constant_override("margin_bottom", 35)
	margin.add_theme_constant_override("margin_left", 45)
	margin.add_theme_constant_override("margin_right", 45)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_personalizar.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "PERSONALIZAÇÃO & CONQUISTAS"
	lbl_titulo.add_theme_font_size_override("font_size", 38)
	lbl_titulo.add_theme_color_override("font_color", Color("#54d6ff"))
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_titulo)
	
	var divisor = ColorRect.new()
	divisor.custom_minimum_size.y = 2
	divisor.color = Color("#54d6ff", 0.3)
	vbox.add_child(divisor)
	
	var hbox_paginas = HBoxContainer.new()
	hbox_paginas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_paginas.add_theme_constant_override("separation", 24)
	vbox.add_child(hbox_paginas)
	
	# --- PÁGINA ESQUERDA: CONQUISTAS ---
	var col_left = VBoxContainer.new()
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.add_theme_constant_override("separation", 10)
	hbox_paginas.add_child(col_left)
	
	var lbl_hdr_conquistas = Label.new()
	lbl_hdr_conquistas.text = "CONQUISTAS CÍVICAS"
	lbl_hdr_conquistas.add_theme_font_size_override("font_size", 18)
	lbl_hdr_conquistas.add_theme_color_override("font_color", Color("#ffe28a"))
	col_left.add_child(lbl_hdr_conquistas)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col_left.add_child(scroll)
	
	var list_conquistas = VBoxContainer.new()
	list_conquistas.add_theme_constant_override("separation", 10)
	list_conquistas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_conquistas)
	
	# Preencher conquistas
	var info_conquistas = [
		{"id": "historiador", "titulo": "Guardião da Memória", "desc": "Fase 1: Recuperou o Livro de Direitos do Povo.", "recompensa": "Desbloqueia Estilo 'Xilogravura do Cariri'"},
		{"id": "radio_perfeito", "titulo": "Verdade nas Ondas", "desc": "Fase 2: Decifrou a rádio sem falhar.", "recompensa": "Desbloqueia Estilo 'Neon Hacker'"},
		{"id": "escola_ok", "titulo": "Voz da Escola", "desc": "Fase 3: Interceptou e libertou os alto-falantes.", "recompensa": ""},
		{"id": "praca_pacifica", "titulo": "Líder Pacífico", "desc": "Fase 4: Concluiu a Praça sem violência e com Segurança > 80%.", "recompensa": "Desbloqueia Estilo 'Renda & Jangada'"},
		{"id": "fim_democratico", "titulo": "Vontade do Povo", "desc": "Final: Julgou o ditador sob a lei e ampla defesa.", "recompensa": "Desbloqueia Estilo 'Palácio Dourado'"},
		{"id": "fim_qualquer", "titulo": "Coração da Resistência", "desc": "Final: Concluiu a jornada em qualquer rota.", "recompensa": ""}
	]
	
	for conq in info_conquistas:
		var conq_panel = PanelContainer.new()
		var desbloqueada: bool = GameState.conquistas_desbloqueadas.get(conq["id"], false)
		
		var conq_sb = StyleBoxFlat.new()
		conq_sb.bg_color = Color("#111018") if desbloqueada else Color("#09090c")
		conq_sb.border_width_left = 3
		conq_sb.border_color = Color("#22ff55") if desbloqueada else Color("#444444")
		conq_sb.content_margin_left = 10
		conq_sb.content_margin_right = 10
		conq_sb.content_margin_top = 8
		conq_sb.content_margin_bottom = 8
		conq_panel.add_theme_stylebox_override("panel", conq_sb)
		
		var conq_hbox = HBoxContainer.new()
		conq_hbox.add_theme_constant_override("separation", 10)
		conq_panel.add_child(conq_hbox)
		
		var conq_ico = Label.new()
		conq_ico.text = "🏆" if desbloqueada else "🔒"
		conq_ico.add_theme_font_size_override("font_size", 22)
		conq_hbox.add_child(conq_ico)
		
		var conq_vbox = VBoxContainer.new()
		conq_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		conq_hbox.add_child(conq_vbox)
		
		var conq_lbl_title = Label.new()
		conq_lbl_title.text = conq["titulo"]
		conq_lbl_title.add_theme_font_override("font", dogica_font)
		conq_lbl_title.add_theme_font_size_override("font_size", 16)
		conq_lbl_title.add_theme_color_override("font_color", Color("#22ff55") if desbloqueada else Color("#888888"))
		conq_vbox.add_child(conq_lbl_title)
		
		var conq_lbl_desc = Label.new()
		if conq["recompensa"] != "":
			conq_lbl_desc.text = conq["desc"] + "\n[RECOMPENSA: " + conq["recompensa"] + "]"
		else:
			conq_lbl_desc.text = conq["desc"]
		conq_lbl_desc.add_theme_font_size_override("font_size", 13)
		conq_lbl_desc.add_theme_color_override("font_color", Color("#d7c9aa") if desbloqueada else Color("#555555"))
		conq_lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		conq_vbox.add_child(conq_lbl_desc)
		
		list_conquistas.add_child(conq_panel)
		
	# --- DIVISOR CENTRAL ---
	var spine = ColorRect.new()
	spine.custom_minimum_size = Vector2(2, 0)
	spine.color = Color("#54d6ff", 0.2)
	hbox_paginas.add_child(spine)
	
	# --- PÁGINA DIREITA: CUSTOMIZAÇÃO ---
	var col_right = VBoxContainer.new()
	col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_right.add_theme_constant_override("separation", 24)
	hbox_paginas.add_child(col_right)
	
	var lbl_hdr_armario = Label.new()
	lbl_hdr_armario.text = "ESTILOS E INTERFACE"
	lbl_hdr_armario.add_theme_font_size_override("font_size", 18)
	lbl_hdr_armario.add_theme_color_override("font_color", Color("#ffe28a"))
	col_right.add_child(lbl_hdr_armario)
	
	var lbl_desc_estilos = Label.new()
	lbl_desc_estilos.text = "Aqui você pode personalizar a aparência das caixas de texto e da tipografia dos diálogos do jogo. Desbloqueie novos estilos realizando feitos importantes e conquistando conquistas cívicas."
	lbl_desc_estilos.add_theme_font_size_override("font_size", 15)
	lbl_desc_estilos.add_theme_color_override("font_color", Color("#cbd7e8"))
	lbl_desc_estilos.autowrap_mode = TextServer.AUTOWRAP_WORD
	col_right.add_child(lbl_desc_estilos)
	
	# Seleção de Caixa de Texto (Estilo)
	var lbl_sel_tb = Label.new()
	lbl_sel_tb.text = "SELECIONAR ESTILO DA CAIXA DE TEXTO"
	lbl_sel_tb.add_theme_font_size_override("font_size", 15)
	lbl_sel_tb.add_theme_color_override("font_color", Color("#8f8875"))
	col_right.add_child(lbl_sel_tb)
	
	var tb_options = [
		{"nome": "Clássico Usina", "caminho": "res://ASSETS/DIALOGIC/STYLES/Base_testebox.tres", "cond": "", "conq_id": ""},
		{"nome": "Xilogravura Cariri [Cariri]", "caminho": "res://ASSETS/DIALOGIC/STYLES/XilografiaCariri.tres", "cond": "Bloqueado: Conclua a Busca pelo Livro (Fase 1)", "conq_id": "historiador"},
		{"nome": "Renda & Jangada [Jangada]", "caminho": "res://ASSETS/DIALOGIC/STYLES/JangadaRenda.tres", "cond": "Bloqueado: Conclua a Praça (Fase 4) pacificamente", "conq_id": "praca_pacifica"},
		{"nome": "Neon Hacker [Hacker]", "caminho": "res://ASSETS/DIALOGIC/STYLES/NeonHacker.tres", "cond": "Bloqueado: Decifre a rádio sem falhar (Fase 2)", "conq_id": "radio_perfeito"},
		{"nome": "Palácio Dourado [Palacio]", "caminho": "res://ASSETS/DIALOGIC/STYLES/PalacioDourado.tres", "cond": "Bloqueado: Rota de Julgamento Civil no final", "conq_id": "fim_democratico"}
	]
	
	var tb_descriptions = {
		"res://ASSETS/DIALOGIC/STYLES/Base_testebox.tres": "O estilo clássico e padrão de Usina Velha, com visual retrô e limpo.",
		"res://ASSETS/DIALOGIC/STYLES/XilografiaCariri.tres": "Inspirado na arte tradicional da xilogravura e na estética da literatura de cordel.",
		"res://ASSETS/DIALOGIC/STYLES/JangadaRenda.tres": "Estilo estético e poético inspirado nas rendas cearenses e na navegação das jangadas.",
		"res://ASSETS/DIALOGIC/STYLES/NeonHacker.tres": "Estilo tecnológico e futurista, com temática cyberpunk de invasão e frequências neon.",
		"res://ASSETS/DIALOGIC/STYLES/PalacioDourado.tres": "Estilo solene com detalhes dourados e tipografia clássica, representando a justiça cívica."
	}
	
	_current_tb_idx = 0
	for i in range(tb_options.size()):
		if tb_options[i]["caminho"] == GameState.estilo_textbox_selecionado:
			_current_tb_idx = i
			
	var tb_selector = HBoxContainer.new()
	tb_selector.add_theme_constant_override("separation", 10)
	col_right.add_child(tb_selector)
	
	var btn_tb_esq = Button.new()
	btn_tb_esq.text = " < "
	btn_tb_esq.add_theme_font_size_override("font_size", 20)
	_aplicar_estilo_neon(btn_tb_esq, Color("#54d6ff"), true)
	tb_selector.add_child(btn_tb_esq)
	
	var lbl_tb_nome = Label.new()
	lbl_tb_nome.text = tb_options[_current_tb_idx]["nome"]
	lbl_tb_nome.add_theme_font_size_override("font_size", 20)
	lbl_tb_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tb_nome.custom_minimum_size.x = 240
	tb_selector.add_child(lbl_tb_nome)
	
	var btn_tb_dir = Button.new()
	btn_tb_dir.text = " > "
	btn_tb_dir.add_theme_font_size_override("font_size", 20)
	_aplicar_estilo_neon(btn_tb_dir, Color("#54d6ff"), true)
	tb_selector.add_child(btn_tb_dir)
	
	# Descrição do estilo ativo
	var lbl_desc_style_ativo = Label.new()
	lbl_desc_style_ativo.add_theme_font_size_override("font_size", 16)
	lbl_desc_style_ativo.add_theme_color_override("font_color", Color("#a5b4fc"))
	lbl_desc_style_ativo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc_style_ativo.autowrap_mode = TextServer.AUTOWRAP_WORD
	col_right.add_child(lbl_desc_style_ativo)
	
	# Feedback de bloqueio / instruções
	var lbl_armario_feedback = Label.new()
	lbl_armario_feedback.text = ""
	lbl_armario_feedback.add_theme_font_size_override("font_size", 14)
	lbl_armario_feedback.add_theme_color_override("font_color", Color("#ff4b4b"))
	lbl_armario_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_armario_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD
	col_right.add_child(lbl_armario_feedback)
	
	# Funções de atualização local
	var verificar_selecoes = func():
		lbl_armario_feedback.text = ""
		var tb = tb_options[_current_tb_idx]
		lbl_desc_style_ativo.text = tb_descriptions.get(tb["caminho"], "")
		if tb["conq_id"] != "" and not GameState.conquistas_desbloqueadas.get(tb["conq_id"], false):
			lbl_armario_feedback.text = tb["cond"]
			
	verificar_selecoes.call()
	
	btn_tb_esq.pressed.connect(func():
		_tocar_deslize()
		_current_tb_idx = _current_tb_idx - 1
		if _current_tb_idx < 0: _current_tb_idx = tb_options.size() - 1
		lbl_tb_nome.text = tb_options[_current_tb_idx]["nome"]
		var tb = tb_options[_current_tb_idx]
		var unlocked = tb["conq_id"] == "" or GameState.conquistas_desbloqueadas.get(tb["conq_id"], false)
		if unlocked:
			GameState.estilo_textbox_selecionado = tb["caminho"]
			GameState.aplicar_estilizacao_dialogic()
			GameState.salvar_jogo(false)
		verificar_selecoes.call()
	)
	
	btn_tb_dir.pressed.connect(func():
		_tocar_deslize()
		_current_tb_idx = _current_tb_idx + 1
		if _current_tb_idx >= tb_options.size(): _current_tb_idx = 0
		lbl_tb_nome.text = tb_options[_current_tb_idx]["nome"]
		var tb = tb_options[_current_tb_idx]
		var unlocked = tb["conq_id"] == "" or GameState.conquistas_desbloqueadas.get(tb["conq_id"], false)
		if unlocked:
			GameState.estilo_textbox_selecionado = tb["caminho"]
			GameState.aplicar_estilizacao_dialogic()
			GameState.salvar_jogo(false)
		verificar_selecoes.call()
	)
	
	var btn_fechar_pers = _criar_botao_generico("FECHAR PERSONALIZAÇÃO", Color("#54d6ff"))
	btn_fechar_pers.pressed.connect(_fechar_modal)
	btn_fechar_pers.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_fechar_pers)
	
	# Adiciona aos botões de hover para consistência de áudio/escala
	btn_tb_esq.mouse_entered.connect(func(): _on_hover_container_btn(btn_tb_esq))
	btn_tb_esq.mouse_exited.connect(func(): _on_unhover_container_btn(btn_tb_esq))
	btn_tb_dir.mouse_entered.connect(func(): _on_hover_container_btn(btn_tb_dir))
	btn_tb_dir.mouse_exited.connect(func(): _on_unhover_container_btn(btn_tb_dir))
	btn_fechar_pers.mouse_entered.connect(func(): _on_hover_container_btn(btn_fechar_pers))
	btn_fechar_pers.mouse_exited.connect(func(): _on_unhover_container_btn(btn_fechar_pers))
