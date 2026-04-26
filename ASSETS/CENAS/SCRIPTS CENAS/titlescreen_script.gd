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
var painel_ativo: Panel = null
var rastro_fogo: CPUParticles2D
var menu_container: MarginContainer
var vbox_botoes: VBoxContainer

# Tipografia Exclusiva para Botões Principais
var dogica_font = preload("res://ASSETS/FONTES/determination.ttf")

# Cores Neon (Premium/Cyberpunk)
const C_NEON_LARANJA = Color("#FF8C00")
const C_NEON_VERMELHO = Color("#FF2222")
const C_NEON_VERDE = Color("#22FF55")

const BASE_X = 100.0

# === ESTADO DAS CONFIGURAÇÕES ===
var config = {
	"tela_cheia": 1, # 1 = Ligado (Fullscreen)
	"resolucao": 1,
	"idioma": 0, # 0=PT, 1=EN, 2=ES, 3=FR
	"vol_musica": 50.0,
	"vol_sfx": 50.0
}
var ui_refs = {}

# === IDIOMAS ===
const IDIOMAS_NOME = ["Português (BR)", "English", "Español", "Français"]
const IDIOMAS_LOCALE = ["pt", "en", "es", "fr"]
const TELA_CHEIA_OPCOES = {
	"pt": ["Ligado", "Desligado"],
	"en": ["On", "Off"],
	"es": ["Activado", "Desactivado"],
	"fr": ["Activé", "Désactivé"]
}
var TR = {
	"jogar":        {"pt": "Jogar",          "en": "Play",           "es": "Jugar",          "fr": "Jouer"},
	"opcoes":       {"pt": "Opções",         "en": "Options",        "es": "Opciones",       "fr": "Options"},
	"creditos":     {"pt": "Créditos",       "en": "Credits",        "es": "Créditos",       "fr": "Crédits"},
	"sair":         {"pt": "Sair",           "en": "Quit",           "es": "Salir",          "fr": "Quitter"},
	"config_titulo":{"pt": "CONFIGURAÇÕES",  "en": "SETTINGS",       "es": "CONFIGURACIÓN",  "fr": "PARAMÈTRES"},
	"musica":       {"pt": "Música",         "en": "Music",          "es": "Música",         "fr": "Musique"},
	"sfx":          {"pt": "Efeitos Sonoros","en": "Sound Effects",  "es": "Efectos de Sonido","fr": "Effets Sonores"},
	"tela_cheia":   {"pt": "Tela Cheia",     "en": "Fullscreen",     "es": "Pantalla Completa","fr": "Plein Écran"},
	"resolucao":    {"pt": "Resolução",      "en": "Resolution",     "es": "Resolución",     "fr": "Résolution"},
	"idioma":       {"pt": "Idioma",         "en": "Language",       "es": "Idioma",         "fr": "Langue"},
	"voltar":       {"pt": "Voltar",         "en": "Back",           "es": "Volver",         "fr": "Retour"},
	"restaurar":    {"pt": "Restaurar Padrões","en": "Restore Defaults","es": "Restaurar",   "fr": "Par Défaut"},
	"aplicar":      {"pt": "Aplicar",        "en": "Apply",          "es": "Aplicar",        "fr": "Appliquer"},
	"cred_titulo":  {"pt": "CRÉDITOS",       "en": "CREDITS",        "es": "CRÉDITOS",       "fr": "CRÉDITS"},
	"sair_pergunta":{"pt": "Deseja cancelar a missão\ne parar de lutar?", "en": "Do you want to abort the mission\nand stop fighting?", "es": "¿Deseas cancelar la misión\ny dejar de luchar?", "fr": "Voulez-vous annuler la mission\net arrêter de lutter ?"},
	"sair_sim":     {"pt": "Amarelar (Sair)","en": "Chicken Out (Quit)","es": "Cobardear (Salir)","fr": "Abandonner (Quitter)"},
	"sair_nao":     {"pt": "Continuar a Luta","en": "Keep Fighting",  "es": "Seguir Luchando","fr": "Continuer le Combat"},
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
	var locale = IDIOMAS_LOCALE[config["idioma"]]
	if TR.has(chave) and TR[chave].has(locale):
		return TR[chave][locale]
	return chave

func _ready() -> void:
	botoes = [jogar_botao, opcoes_botao, creditos_botao, sair_botao]
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
	_aplicar_todas_configuracoes()

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
	if not menu_container:
		menu_container = MarginContainer.new()
		menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		menu_container.add_theme_constant_override("margin_left", 120)
		menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(menu_container)
		
		vbox_botoes = VBoxContainer.new()
		vbox_botoes.add_theme_constant_override("separation", 30)
		vbox_botoes.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		vbox_botoes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		menu_container.add_child(vbox_botoes)
	
	for btn in botoes:
		if btn.get_parent() != vbox_botoes:
			if btn.get_parent(): btn.get_parent().remove_child(btn)
			vbox_botoes.add_child(btn)
		
		btn.custom_minimum_size = Vector2(400, 85)
		btn.pivot_offset = btn.custom_minimum_size / 2.0
	
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
	neon_cursor.size = Vector2(450, 3) # Mais condizente com o novo tamanho dos botões
	neon_cursor.color = C_NEON_LARANJA
	neon_cursor.modulate.a = 0.0 # Garantir invisibilidade inicial
	neon_cursor.z_index = -1
	add_child(neon_cursor)

func _configurar_botoes() -> void:
	for btn in botoes:
		_aplicar_estilo_principal(btn, C_NEON_LARANJA)

func _aplicar_estilo_principal(btn: Button, cor_destaque: Color) -> void:
	btn.add_theme_font_override("font", dogica_font)
	btn.add_theme_font_size_override("font_size", 34) # Maior impacto visual
	
	var estilo_normal = StyleBoxFlat.new()
	estilo_normal.bg_color = Color(0.02, 0.02, 0.02, 0.85) # Escuro muito limpo
	estilo_normal.border_width_left = 1
	estilo_normal.border_width_right = 1
	estilo_normal.border_width_top = 1
	estilo_normal.border_width_bottom = 1
	estilo_normal.border_color = Color(1.0, 1.0, 1.0, 0.15) # Borda sutil de repouso
	estilo_normal.corner_radius_top_left = 8
	estilo_normal.corner_radius_top_right = 8
	estilo_normal.corner_radius_bottom_right = 8
	estilo_normal.corner_radius_bottom_left = 8
	
	# Espaçamento interno (Padding) muito mais confortável e premium
	estilo_normal.content_margin_left = 40
	estilo_normal.content_margin_right = 40
	estilo_normal.content_margin_top = 18
	estilo_normal.content_margin_bottom = 18
	
	var estilo_hover = estilo_normal.duplicate()
	estilo_hover.border_color = cor_destaque
	estilo_hover.border_width_left = 2
	estilo_hover.border_width_right = 2
	estilo_hover.border_width_top = 2
	estilo_hover.border_width_bottom = 2
	estilo_hover.shadow_color = cor_destaque
	estilo_hover.shadow_color.a = 0.35
	estilo_hover.shadow_size = 20
	
	btn.add_theme_stylebox_override("normal", estilo_normal)
	btn.add_theme_stylebox_override("hover", estilo_hover)
	btn.add_theme_stylebox_override("pressed", estilo_hover)
	btn.add_theme_stylebox_override("focus", estilo_hover)
	
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	
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
	
	var cor_btn = btn.get_meta("cor_neon")
	var pos_x_orig = btn.get_meta("pos_original_x")
	var pos_y_glob = btn.get_meta("pos_global_y")
	var cursor_y = pos_y_glob + (btn.size.y / 2.0) - 2.0
	
	# Neon cursor segue a posição GLOBAL Y para ser preciso
	var tw_cursor = create_tween().set_parallel(true)
	neon_cursor.color = cor_btn
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

func _aplicar_todas_configuracoes() -> void:
	_tocar_clique()
	
	# Fullscreen
	if config["tela_cheia"] == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	# Resolução (Só tem efeito visual claro se estiver no modo Janela)
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
	
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		get_window().size = res
		# Centraliza de forma perfeita no monitor atual (Suporte a múltiplos monitores)
		var tela_atual = DisplayServer.window_get_current_screen()
		var pos_tela = DisplayServer.screen_get_position(tela_atual)
		var tam_tela = DisplayServer.screen_get_size(tela_atual)
		get_window().position = pos_tela + (tam_tela / 2) - (res / 2)

	# Idioma
	TranslationServer.set_locale(IDIOMAS_LOCALE[config["idioma"]])
	_aplicar_idioma()
	
	# Os volumes já aplicam real-time, mas garantimos aqui
	_aplicar_volume("Musica", config["vol_musica"])
	_aplicar_volume("SFX", config["vol_sfx"])
	
	_fechar_modal() # Feedback de conclusão

func _restaurar_padroes() -> void:
	_tocar_deslize()
	config = {
		"tela_cheia": 0, 
		"resolucao": 1, 
		"idioma": 0,
		"vol_musica": 50.0,
		"vol_sfx": 50.0
	}
	
	# Atualiza Visuais imediatamente
	ui_refs["vol_musica"].value = 50.0
	ui_refs["vol_sfx"].value = 50.0
	
	ui_refs["tela_cheia"].text = TELA_CHEIA_OPCOES[IDIOMAS_LOCALE[config["idioma"]]][0]
	ui_refs["resolucao"].text = "1920x1080"
	ui_refs["idioma"].text = IDIOMAS_NOME[0]
	
	_aplicar_idioma()
	
	_aplicar_volume("Musica", 50.0)
	_aplicar_volume("SFX", 50.0)

# ────────────────────────────────────────────────────────

func _criar_paineis() -> void:
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
	
	# ===================== MODAL DE OPÇÕES =====================
	painel_opcoes = Panel.new()
	painel_opcoes.add_theme_stylebox_override("panel", estilo_modal)
	painel_opcoes.size = Vector2(850, 700)
	painel_opcoes.position = (viewport_size - painel_opcoes.size) / 2.0
	painel_opcoes.pivot_offset = painel_opcoes.size / 2.0
	painel_opcoes.z_index = 50
	painel_opcoes.hide()
	add_child(painel_opcoes)
	
	var op_margin = MarginContainer.new()
	op_margin.add_theme_constant_override("margin_top", 40)
	op_margin.add_theme_constant_override("margin_bottom", 40)
	op_margin.add_theme_constant_override("margin_left", 60)
	op_margin.add_theme_constant_override("margin_right", 60)
	op_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_opcoes.add_child(op_margin)
	
	var op_vbox = VBoxContainer.new()
	op_vbox.add_theme_constant_override("separation", 20)
	op_margin.add_child(op_vbox)
	
	var lbl_opcoes = Label.new()
	lbl_opcoes.text = "CONFIGURAÇÕES"
	lbl_opcoes.add_theme_font_size_override("font_size", 42)
	lbl_opcoes.add_theme_color_override("font_color", Color("#FFFFFF"))
	lbl_opcoes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	op_vbox.add_child(lbl_opcoes)
	
	var sep1 = Control.new()
	sep1.custom_minimum_size.y = 20
	op_vbox.add_child(sep1)
	
	# Sliders Funcionais
	var sl_musica = _criar_slider(op_vbox, "vol_musica", _t("musica"))
	var sl_sfx = _criar_slider(op_vbox, "vol_sfx", _t("sfx"))
	tr_refs["lbl_musica"] = sl_musica.get_parent().get_child(0)
	tr_refs["lbl_sfx"] = sl_sfx.get_parent().get_child(0)
	
	# Seletores Funcionais
	var sel_tela = _criar_seletor(op_vbox, "tela_cheia", _t("tela_cheia"), TELA_CHEIA_OPCOES[IDIOMAS_LOCALE[config["idioma"]]])
	_criar_seletor(op_vbox, "resolucao", _t("resolucao"), ["2560x1440", "1920x1080", "1600x900", "1366x768", "1280x720", "1024x576", "854x480"])
	var sel_idioma = _criar_seletor(op_vbox, "idioma", _t("idioma"), IDIOMAS_NOME)
	
	tr_refs["lbl_opcoes_titulo"] = lbl_opcoes
	tr_refs["lbl_tela_cheia"] = sel_tela.get_child(0)
	tr_refs["lbl_resolucao"] = op_vbox.get_child(op_vbox.get_child_count() - 3).get_child(0) # Pegando o penúltimo seletor (resolucao)
	tr_refs["lbl_idioma"] = sel_idioma.get_child(0)
	
	# Corrigindo a referência da resolução pois usei get_child_count
	# Vamos fazer de forma mais limpa:
	tr_refs["lbl_resolucao"] = op_vbox.get_child(6).get_child(0) # resolucao é o 7º elemento (índice 6)
	
	var sep_bottom = Control.new()
	sep_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	
	
	# ===================== MODAL DE CRÉDITOS =====================
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
	
	# ... (texto BBCode será atualizado no _aplicar_idioma)
	
	scroll.add_child(rtl)
	
	var btn_voltar_cr = _criar_botao_generico(_t("voltar"), C_NEON_LARANJA)
	btn_voltar_cr.pressed.connect(_fechar_modal)
	btn_voltar_cr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cr_vbox.add_child(btn_voltar_cr)
	tr_refs["btn_voltar_cr"] = btn_voltar_cr
	
	# ===================== MODAL DE SAIR =====================
	painel_sair = Panel.new()
	var estilo_sair = estilo_modal.duplicate()
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
	
	var btn_continuar = _criar_botao_generico(_t("sair_nao"), C_NEON_VERDE)
	btn_continuar.pressed.connect(_fechar_modal)
	hbox_sair.add_child(btn_continuar)
	tr_refs["btn_sair_nao"] = btn_continuar

# Utils Visuais de Componentes e Funcionalidade de Settings
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

func _criar_seletor(pai: Control, chave_config: String, titulo: String, opcoes: Array) -> HBoxContainer:
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
	)
	btn_dir.pressed.connect(func():
		_tocar_deslize()
		var i = config[chave_config] + 1
		if i >= opcoes.size(): i = 0
		config[chave_config] = i
		valor.text = opcoes[i]
	)
	
	btn_esq.mouse_entered.connect(func(): _on_hover_container_btn(btn_esq))
	btn_esq.mouse_exited.connect(func(): _on_unhover_container_btn(btn_esq))
	btn_dir.mouse_entered.connect(func(): _on_hover_container_btn(btn_dir))
	btn_dir.mouse_exited.connect(func(): _on_unhover_container_btn(btn_dir))
	
	container.add_child(seletor)
	pai.add_child(container)
	return container

func _aplicar_idioma() -> void:
	# Botões Principais
	jogar_botao.text = _t("jogar")
	opcoes_botao.text = _t("opcoes")
	creditos_botao.text = _t("creditos")
	sair_botao.text = _t("sair")
	
	# Opções
	if tr_refs.has("lbl_opcoes_titulo"): tr_refs["lbl_opcoes_titulo"].text = _t("config_titulo")
	if tr_refs.has("lbl_musica"): tr_refs["lbl_musica"].text = _t("musica")
	if tr_refs.has("lbl_sfx"): tr_refs["lbl_sfx"].text = _t("sfx")
	if tr_refs.has("lbl_tela_cheia"): tr_refs["lbl_tela_cheia"].text = _t("tela_cheia")
	if tr_refs.has("lbl_resolucao"): tr_refs["lbl_resolucao"].text = _t("resolucao")
	if tr_refs.has("lbl_idioma"): tr_refs["lbl_idioma"].text = _t("idioma")
	
	if tr_refs.has("btn_voltar_op"): tr_refs["btn_voltar_op"].text = _t("voltar")
	if tr_refs.has("btn_restaurar"): tr_refs["btn_restaurar"].text = _t("restaurar")
	if tr_refs.has("btn_aplicar"): tr_refs["btn_aplicar"].text = _t("aplicar")
	
	# Atualizar o texto do seletor de tela cheia (Ligado/Desligado)
	var sel_tela_val = ui_refs["tela_cheia"]
	sel_tela_val.text = TELA_CHEIA_OPCOES[IDIOMAS_LOCALE[config["idioma"]]][config["tela_cheia"]]
	
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
	if painel_ativo != null: return
	_tocar_clique()
	for btn in botoes:
		btn.disabled = true
		
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_opcoes_pressed() -> void:
	_abrir_modal(painel_opcoes)

func _on_creditos_pressed() -> void:
	_abrir_modal(painel_creditos)

func _on_sair_pressed() -> void:
	_abrir_modal(painel_sair)
