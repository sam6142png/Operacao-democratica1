extends Control

const FONTE_TITULO = preload("res://ArticaPro-Bold.ttf")
const FONTE_PADRAO = preload("res://ASSETS/FONTES/determination.ttf")
const FONTE_MONO = preload("res://ASSETS/FONTES/dogicapixel.ttf")

# Sons
var sfx_click: AudioStreamPlayer
var sfx_hover: AudioStreamPlayer
var sfx_slide: AudioStreamPlayer
var sfx_close: AudioStreamPlayer

# Sequência de Minijogos Educativos
const MINIGAMES = [
	{
		"name": "Livro de Direitos (Fase 1)",
		"scene": "res://ASSETS/CENAS/minigame_paginas.tscn",
		"context": "O regime militar confiscou e adulterou as leis com propagandas autoritárias.",
		"objective": "Classificar cada página do livro corretamente para restaurar a verdade cívica.",
		"mechanics": "Analisar as páginas e arrastá-las ou clicar para classificar como Direito, Dever ou Propaganda.",
		"victory": "Classificar 10 páginas corretamente sem estourar o limite de erros.",
		"defeat": "Cometer 4 erros de classificação ou deixar o tempo limite da página esgotar.",
		"controls": "Mouse para arrastar as páginas ou clicar nos botões inferiores."
	},
	{
		"name": "Sintonia de Rádio (Fase 2)",
		"scene": "res://ASSETS/CENAS/minigame_radio.tscn",
		"context": "A rádio clandestina sob censura precisa enviar a mensagem cifrada da resistência civil.",
		"objective": "Sintonizar as frequências secretas e decifrar as ondas criptografadas.",
		"mechanics": "Ajustar os botões de sintonia e o deslocamento de sinal (shift) para limpar o osciloscópio.",
		"victory": "Sintonizar e decifrar as 3 transmissões da rádio livre.",
		"defeat": "Esgotar a bateria ou o tempo de decodificação.",
		"controls": "Mouse para girar os botões e ajustar os sliders de sintonização."
	},
	{
		"name": "Sinal Escolar (Fase 3)",
		"scene": "res://ASSETS/CENAS/minigame_escola.tscn",
		"context": "Os alto-falantes da escola estão sob controle militar para doutrinação e censura.",
		"objective": "Sintonizar os canais de microfone, transmissão e antena para a frequência da Rádio Livre.",
		"mechanics": "Ajustar os botões de amplitude e frequência para alinhar os sinais verde e vermelho no osciloscópio.",
		"victory": "Sintonizar com sucesso todos os 3 canais de comunicação da rádio.",
		"defeat": "Esgotar o tempo limite de sintonia, disparando alarmes e alertando os guardas.",
		"controls": "Mouse para arrastar e ajustar os sliders de controle da onda."
	},
	{
		"name": "Infiltração Tática (Fase 4)",
		"scene": "res://ASSETS/CENAS/minigame_praca.tscn",
		"context": "Dante precisa invadir o Palácio Municipal pela entrada de serviço secreta, contornando a segurança do Coronel Antônio.",
		"objective": "Desarmar a fechadura eletrônica combinando os conhecimentos adquiridos ao longo da jornada.",
		"mechanics": "Filtrar propaganda do regime, decodificar cifra de César e sintonizar a frequência de acoplamento do sinal no osciloscópio.",
		"victory": "Resolver as 3 etapas lógicas de segurança para liberar as travas e abrir o portão.",
		"defeat": "Desafio focado em persistência e raciocínio cívico.",
		"controls": "Mouse para escolher opções de texto, interagir com a roda de cifras e mover sliders."
	},
	{
		"name": "Debate no Palácio (Fase Final)",
		"scene": "res://ASSETS/CENAS/minigame_final_palacio.tscn",
		"context": "O Coronel Antônio foi encurralado na sala de controle do Palácio Municipal.",
		"objective": "Refutar as mentiras e forçar a rendição do ditador perante a lei e julgamento cívico.",
		"mechanics": "Escolher os argumentos corretos contra a propaganda oficial e manter a calma no batimento cardíaco (QTE).",
		"victory": "Desarmar as defesas do Coronel e convencer a cidade a seguir o devido processo legal.",
		"defeat": "Esgotar a estabilidade emocional de Dante ou perder o apoio popular.",
		"controls": "Mouse para escolher os argumentos, Barra de Espaço para manter a calma no QTE."
	}
]

# Diálogo de Introdução de Dante
const INTRO_DIALOGUE = [
	{
		"text": "Olá! Eu sou o Dante, líder da resistência de Usina Velha.",
		"sprite": "neutro.png"
	},
	{
		"text": "Bem-vindo ao Modo Minigames! Esta é uma experiência focada 100% na jogabilidade e no aprendizado.",
		"sprite": "Falando (boca aberta).png"
	},
	{
		"text": "Aqui, você não jogará as missões de história ou os diálogos de exploração livre da campanha.",
		"sprite": "Pensativo confuso (mão no queixo).png"
	},
	{
		"text": "Além disso, nenhuma ação realizada aqui afetará o seu save da campanha principal.",
		"sprite": "Sorrindo aliviado (leve sorriso).png"
	},
	{
		"text": "Seu objetivo é concluir cada um dos minigames educativos em sequência até o confronto final.",
		"sprite": "Bravo determinado.png"
	},
	{
		"text": "Prepare-se! Vamos começar com o nosso primeiro desafio cívico.",
		"sprite": "Bravo determinado.png"
	}
]

var diálogo_idx: int = 0
var painel_dialogo: PanelContainer
var dante_sprite_rect: TextureRect
var dialogo_lbl: Label
var dialogo_continuar_lbl: Label
var blocker: Control
var _transicionando: bool = false

# UI Principal da Explicação
var painel_explicação: PanelContainer
var expl_titulo: Label
var expl_grid: VBoxContainer
var btn_iniciar: Button
var btn_menu: Button

func _ready() -> void:
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").play_default_music()

	# Parar e ocultar medidor de confiança da história
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false

	_configurar_audio()
	_construir_fundo()
	
	# Verificar progresso
	var idx = GameState.minigame_atual_idx
	if idx >= MINIGAMES.size():
		_mostrar_vitoria_final()
	elif idx == 0 and diálogo_idx < INTRO_DIALOGUE.size():
		_construir_painel_dialogo()
		_mostrar_proximo_dialogo()
	else:
		_construir_painel_explicacao(idx)

func _configurar_audio() -> void:
	sfx_click = AudioStreamPlayer.new()
	sfx_click.stream = load("res://ASSETS/SOUNDS/FSX/BotoesClick.mp3")
	sfx_click.bus = "SFX"
	add_child(sfx_click)
	
	sfx_hover = AudioStreamPlayer.new()
	sfx_hover.stream = load("res://ASSETS/SOUNDS/FSX/BotoesHover.mp3")
	sfx_hover.bus = "SFX"
	add_child(sfx_hover)
	
	sfx_slide = AudioStreamPlayer.new()
	sfx_slide.stream = load("res://ASSETS/SOUNDS/FSX/SlideMenu.mp3")
	sfx_slide.bus = "SFX"
	add_child(sfx_slide)
	
	sfx_close = AudioStreamPlayer.new()
	sfx_close.stream = load("res://ASSETS/SOUNDS/FSX/MenuClose.mp3")
	sfx_close.bus = "SFX"
	add_child(sfx_close)

func _play_sfx(sfx: AudioStreamPlayer) -> void:
	if sfx:
		sfx.pitch_scale = randf_range(0.95, 1.05)
		sfx.play()

func _construir_fundo() -> void:
	# Fundo escuro premium
	var bg = ColorRect.new()
	bg.color = Color("#070609")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Efeito de grade cibernética translúcida
	var grade = Control.new()
	grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.draw.connect(func():
		var size_rect = grade.size
		for x in range(0, int(size_rect.x), 80):
			grade.draw_line(Vector2(x, 0), Vector2(x, size_rect.y), Color("#54d6ff", 0.02), 1.0)
		for y in range(0, int(size_rect.y), 80):
			grade.draw_line(Vector2(0, y), Vector2(size_rect.x, y), Color("#54d6ff", 0.02), 1.0)
	)
	add_child(grade)

# === PAINEL DE DIÁLOGO INTRODUTÓRIO ===

func _construir_painel_dialogo() -> void:
	var viewport_size = Vector2(1920, 1080)
	
	# Container invisível para bloquear cliques
	blocker = Control.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_mostrar_proximo_dialogo()
	)
	add_child(blocker)
	
	# Dante Sprite (Ancorado no canto inferior esquerdo)
	dante_sprite_rect = TextureRect.new()
	dante_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dante_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dante_sprite_rect.size = Vector2(500, 750)
	dante_sprite_rect.position = Vector2(120, viewport_size.y - dante_sprite_rect.size.y + 40)
	dante_sprite_rect.modulate.a = 0
	add_child(dante_sprite_rect)
	
	# Textbox na parte inferior
	painel_dialogo = PanelContainer.new()
	painel_dialogo.size = Vector2(1100, 240)
	painel_dialogo.position = Vector2(viewport_size.x - painel_dialogo.size.x - 120, viewport_size.y - painel_dialogo.size.y - 80)
	painel_dialogo.pivot_offset = painel_dialogo.size / 2.0
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#0c0b11", 0.94)
	sb.border_width_left = 3; sb.border_width_top = 3
	sb.border_width_right = 3; sb.border_width_bottom = 3
	sb.border_color = Color("#FF8C00") # Neon Laranja
	sb.corner_radius_top_left = 12; sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12; sb.corner_radius_bottom_right = 12
	sb.shadow_size = 25
	sb.shadow_color = Color("#FF8C00", 0.14)
	painel_dialogo.add_theme_stylebox_override("panel", sb)
	add_child(painel_dialogo)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	painel_dialogo.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Nome de quem fala
	var name_lbl = Label.new()
	name_lbl.text = "DANTE"
	name_lbl.add_theme_font_override("font", FONTE_TITULO)
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color("#FF8C00"))
	vbox.add_child(name_lbl)
	
	# Texto principal
	dialogo_lbl = Label.new()
	dialogo_lbl.add_theme_font_override("font", FONTE_PADRAO)
	dialogo_lbl.add_theme_font_size_override("font_size", 25)
	dialogo_lbl.add_theme_color_override("font_color", Color.WHITE)
	dialogo_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogo_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(dialogo_lbl)
	
	# Pílula de continuar
	dialogo_continuar_lbl = Label.new()
	dialogo_continuar_lbl.text = "[Clique para avançar]"
	dialogo_continuar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogo_continuar_lbl.add_theme_font_override("font", FONTE_MONO)
	dialogo_continuar_lbl.add_theme_font_size_override("font_size", 13)
	dialogo_continuar_lbl.add_theme_color_override("font_color", Color("#8f8875"))
	vbox.add_child(dialogo_continuar_lbl)
	
	# Efeito elástico ao aparecer
	painel_dialogo.modulate.a = 0
	painel_dialogo.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(painel_dialogo, "modulate:a", 1.0, 0.35)
	tw.tween_property(painel_dialogo, "scale", Vector2.ONE, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _input(event: InputEvent) -> void:
	if _transicionando:
		return
	if painel_dialogo and painel_dialogo.visible:
		if event.is_action_pressed("dialogic_default_action") or event.is_action_pressed("ui_accept"):
			_mostrar_proximo_dialogo()

func _mostrar_proximo_dialogo() -> void:
	if _transicionando:
		return
		
	if diálogo_idx >= INTRO_DIALOGUE.size():
		_transicionando = true
		# Encerrar diálogo e carregar explicação
		_play_sfx(sfx_close)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(painel_dialogo, "modulate:a", 0.0, 0.25)
		tw.tween_property(dante_sprite_rect, "modulate:a", 0.0, 0.25)
		await tw.finished
		
		if is_instance_valid(painel_dialogo):
			painel_dialogo.queue_free()
		if is_instance_valid(dante_sprite_rect):
			dante_sprite_rect.queue_free()
		if is_instance_valid(blocker):
			blocker.queue_free()
			
		_construir_painel_explicacao(0)
		return
		
	var dados = INTRO_DIALOGUE[diálogo_idx]
	_play_sfx(sfx_slide)
	
	# Atualizar texto
	dialogo_lbl.text = dados["text"]
	
	# Atualizar sprite com skin dinâmica
	var sprite_path = GameState.obter_caminho_sprite_dante(dados["sprite"])
	dante_sprite_rect.texture = load(sprite_path)
	
	# Micro-animação de pulo e fade in no sprite
	dante_sprite_rect.pivot_offset = dante_sprite_rect.size / 2.0
	var tw_sprite = create_tween().set_parallel(true)
	dante_sprite_rect.scale = Vector2(0.96, 0.96)
	tw_sprite.tween_property(dante_sprite_rect, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	tw_sprite.tween_property(dante_sprite_rect, "modulate:a", 0.95, 0.2)
	
	diálogo_idx += 1

# === TELA DE EXPLICAÇÃO DO MINIJOGO ===

func _construir_painel_explicacao(idx: int) -> void:
	var dados = MINIGAMES[idx]
	var viewport_size = Vector2(1920, 1080)
	
	# Painel Base (Glassmorphic)
	painel_explicação = PanelContainer.new()
	painel_explicação.size = Vector2(1280, 720)
	painel_explicação.position = (viewport_size - painel_explicação.size) / 2.0
	painel_explicação.pivot_offset = painel_explicação.size / 2.0
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#060509", 0.94)
	sb.border_width_left = 3; sb.border_width_top = 3
	sb.border_width_right = 3; sb.border_width_bottom = 3
	sb.border_color = Color("#54d6ff") # Neon Ciano
	sb.corner_radius_top_left = 16; sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16; sb.corner_radius_bottom_right = 16
	sb.shadow_size = 30
	sb.shadow_color = Color("#54d6ff", 0.16)
	painel_explicação.add_theme_stylebox_override("panel", sb)
	add_child(painel_explicação)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	painel_explicação.add_child(margin)
	
	var vbox_main = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 24)
	margin.add_child(vbox_main)
	
	# Título do Desafio
	expl_titulo = Label.new()
	expl_titulo.text = ("DESAFIO CÍVICO " + str(idx + 1) + ": " + dados["name"]).to_upper()
	expl_titulo.add_theme_font_override("font", FONTE_TITULO)
	expl_titulo.add_theme_font_size_override("font_size", 34)
	expl_titulo.add_theme_color_override("font_color", Color("#54d6ff"))
	expl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(expl_titulo)
	
	var div = ColorRect.new()
	div.custom_minimum_size.y = 2
	div.color = Color("#54d6ff", 0.25)
	vbox_main.add_child(div)
	
	# Conteúdo Split: Dante à esquerda | Informações à direita
	var hbox_split = HBoxContainer.new()
	hbox_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_split.add_theme_constant_override("separation", 35)
	vbox_main.add_child(hbox_split)
	
	# Esquerda: Dante Avatar
	var col_dante = VBoxContainer.new()
	col_dante.custom_minimum_size = Vector2(320, 0)
	col_dante.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_split.add_child(col_dante)
	
	var panel_portrait = PanelContainer.new()
	panel_portrait.custom_minimum_size = Vector2(280, 280)
	var sb_pr = StyleBoxFlat.new()
	sb_pr.bg_color = Color("#111018")
	sb_pr.border_width_left = 1; sb_pr.border_width_top = 1
	sb_pr.border_width_right = 1; sb_pr.border_width_bottom = 1
	sb_pr.border_color = Color("#54d6ff", 0.3)
	sb_pr.corner_radius_top_left = 8; sb_pr.corner_radius_top_right = 8
	sb_pr.corner_radius_bottom_left = 8; sb_pr.corner_radius_bottom_right = 8
	panel_portrait.add_theme_stylebox_override("panel", sb_pr)
	col_dante.add_child(panel_portrait)
	
	var sprite_avatar = TextureRect.new()
	sprite_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var avatar_img = GameState.obter_caminho_sprite_dante("neutro.png")
	if idx == 4:
		avatar_img = GameState.obter_caminho_sprite_dante("Bravo determinado.png")
	sprite_avatar.texture = load(avatar_img)
	panel_portrait.add_child(sprite_avatar)
	
	var lbl_dante_tag = Label.new()
	lbl_dante_tag.text = "DANTE\n[Líder Civico]"
	lbl_dante_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_dante_tag.add_theme_font_override("font", FONTE_MONO)
	lbl_dante_tag.add_theme_font_size_override("font_size", 14)
	lbl_dante_tag.add_theme_color_override("font_color", Color("#ffe28a"))
	col_dante.add_child(lbl_dante_tag)
	
	# Direita: Detalhes do Desafio
	var col_info = VBoxContainer.new()
	col_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_info.add_theme_constant_override("separation", 12)
	hbox_split.add_child(col_info)
	
	# Grid explicativo
	expl_grid = VBoxContainer.new()
	expl_grid.add_theme_constant_override("separation", 10)
	col_info.add_child(expl_grid)
	
	_adicionar_item_expl("CONTEXTO", dados["context"], Color("#bda6ff"))
	_adicionar_item_expl("OBJETIVO", dados["objective"], Color("#ffa240"))
	_adicionar_item_expl("MECÂNICAS", dados["mechanics"], Color("#62ff86"))
	_adicionar_item_expl("CONDIÇÃO DE VITÓRIA", dados["victory"], Color("#22FF55"))
	_adicionar_item_expl("CONDIÇÃO DE DERROTA", dados["defeat"], Color("#ff4b4b"))
	_adicionar_item_expl("CONTROLES", dados["controls"], Color("#54d6ff"))
	
	var div2 = ColorRect.new()
	div2.custom_minimum_size.y = 1
	div2.color = Color(1, 1, 1, 0.1)
	vbox_main.add_child(div2)
	
	# Botões na base
	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 50)
	vbox_main.add_child(hbox_btns)
	
	btn_menu = Button.new()
	btn_menu.text = "VOLTAR AO MENU"
	btn_menu.custom_minimum_size = Vector2(300, 58)
	btn_menu.add_theme_font_override("font", FONTE_TITULO)
	btn_menu.add_theme_font_size_override("font_size", 20)
	_aplicar_estilo_neon_secundario(btn_menu, Color("#FF8C00"))
	hbox_btns.add_child(btn_menu)
	
	btn_iniciar = Button.new()
	btn_iniciar.text = "INICIAR DESAFIO"
	btn_iniciar.custom_minimum_size = Vector2(300, 58)
	btn_iniciar.add_theme_font_override("font", FONTE_TITULO)
	btn_iniciar.add_theme_font_size_override("font_size", 20)
	_aplicar_estilo_neon_secundario(btn_iniciar, Color("#62ff86"))
	hbox_btns.add_child(btn_iniciar)
	
	# Conexões
	btn_menu.pressed.connect(func():
		_play_sfx(sfx_click)
		GameState.is_minigame_mode = false
		FadeManager.carregar_cena("res://title_screen.tscn")
	)
	
	btn_iniciar.pressed.connect(func():
		_play_sfx(sfx_click)
		if has_node("/root/MusicManager"):
			get_node("/root/MusicManager").play_default_music()
		FadeManager.carregar_cena(dados["scene"])
	)
	
	btn_menu.mouse_entered.connect(func(): _on_hover_btn(btn_menu))
	btn_menu.mouse_exited.connect(func(): _on_unhover_btn(btn_menu))
	btn_iniciar.mouse_entered.connect(func(): _on_hover_btn(btn_iniciar))
	btn_iniciar.mouse_exited.connect(func(): _on_unhover_btn(btn_iniciar))
	
	# Efeito elástico ao entrar
	painel_explicação.modulate.a = 0
	painel_explicação.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(painel_explicação, "modulate:a", 1.0, 0.35)
	tw.tween_property(painel_explicação, "scale", Vector2.ONE, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _adicionar_item_expl(titulo: String, desc: String, cor_destaque: Color) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	expl_grid.add_child(hbox)
	
	# Badge
	var panel_badge = PanelContainer.new()
	panel_badge.custom_minimum_size = Vector2(200, 0)
	var sb_bd = StyleBoxFlat.new()
	sb_bd.bg_color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 0.08)
	sb_bd.border_width_left = 1; sb_bd.border_width_top = 1
	sb_bd.border_width_right = 1; sb_bd.border_width_bottom = 1
	sb_bd.border_color = Color(cor_destaque, 0.4)
	sb_bd.corner_radius_top_left = 6; sb_bd.corner_radius_top_right = 6
	sb_bd.corner_radius_bottom_left = 6; sb_bd.corner_radius_bottom_right = 6
	sb_bd.content_margin_left = 8; sb_bd.content_margin_right = 8
	sb_bd.content_margin_top = 4; sb_bd.content_margin_bottom = 4
	panel_badge.add_theme_stylebox_override("panel", sb_bd)
	hbox.add_child(panel_badge)
	
	var lbl_badge = Label.new()
	lbl_badge.text = titulo
	lbl_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_badge.add_theme_font_override("font", FONTE_MONO)
	lbl_badge.add_theme_font_size_override("font_size", 12)
	lbl_badge.add_theme_color_override("font_color", cor_destaque)
	panel_badge.add_child(lbl_badge)
	
	# Descrição
	var lbl_desc = Label.new()
	lbl_desc.text = desc
	lbl_desc.add_theme_font_override("font", FONTE_PADRAO)
	lbl_desc.add_theme_font_size_override("font_size", 18)
	lbl_desc.add_theme_color_override("font_color", Color("#ede6d8"))
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl_desc)

# === TELA DE VITÓRIA FINAL ===

func _mostrar_vitoria_final() -> void:
	var viewport_size = Vector2(1920, 1080)
	
	# Painel de Vitória
	var panel_vitoria = PanelContainer.new()
	panel_vitoria.size = Vector2(1000, 600)
	panel_vitoria.position = (viewport_size - panel_vitoria.size) / 2.0
	panel_vitoria.pivot_offset = panel_vitoria.size / 2.0
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#07060a", 0.96)
	sb.border_width_left = 3; sb.border_width_top = 3
	sb.border_width_right = 3; sb.border_width_bottom = 3
	sb.border_color = Color("#22FF55") # Neon Verde de Sucesso
	sb.corner_radius_top_left = 16; sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16; sb.corner_radius_bottom_right = 16
	sb.shadow_size = 30
	sb.shadow_color = Color("#22FF55", 0.16)
	panel_vitoria.add_theme_stylebox_override("panel", sb)
	add_child(panel_vitoria)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 45)
	margin.add_theme_constant_override("margin_bottom", 45)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	panel_vitoria.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	var lbl_concluido = Label.new()
	lbl_concluido.text = "PARABÉNS, LÍDER CÍVICO!"
	lbl_concluido.add_theme_font_override("font", FONTE_TITULO)
	lbl_concluido.add_theme_font_size_override("font_size", 38)
	lbl_concluido.add_theme_color_override("font_color", Color("#22FF55"))
	lbl_concluido.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_concluido)
	
	var div = ColorRect.new()
	div.custom_minimum_size.y = 2
	div.color = Color("#22FF55", 0.3)
	vbox.add_child(div)
	
	var trophy_lbl = Label.new()
	trophy_lbl.text = "🏆"
	trophy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophy_lbl.add_theme_font_size_override("font_size", 64)
	vbox.add_child(trophy_lbl)
	
	# Resumo da conquista
	var lbl_texto = Label.new()
	lbl_texto.text = "Você concluiu com sucesso a sequência completa dos minijogos cívicos da resistência de Usina Velha!\n\nSeu conhecimento em direitos, deveres constitucionais, liberdade de informação e due process legal garantiu que a democracia fosse restaurada sem se espelhar no autoritarismo."
	lbl_texto.add_theme_font_override("font", FONTE_PADRAO)
	lbl_texto.add_theme_font_size_override("font_size", 22)
	lbl_texto.add_theme_color_override("font_color", Color("#cbd7e8"))
	lbl_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(lbl_texto)
	
	var btn_final = Button.new()
	btn_final.text = "RETORNAR AO MENU PRINCIPAL"
	btn_final.custom_minimum_size = Vector2(480, 60)
	btn_final.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_final.add_theme_font_override("font", FONTE_TITULO)
	btn_final.add_theme_font_size_override("font_size", 20)
	_aplicar_estilo_neon_secundario(btn_final, Color("#22FF55"))
	vbox.add_child(btn_final)
	
	btn_final.pressed.connect(func():
		_play_sfx(sfx_click)
		GameState.is_minigame_mode = false
		GameState.minigame_atual_idx = 0
		FadeManager.carregar_cena("res://title_screen.tscn")
	)
	
	btn_final.mouse_entered.connect(func(): _on_hover_btn(btn_final))
	btn_final.mouse_exited.connect(func(): _on_unhover_btn(btn_final))
	
	# Efeito elástico
	panel_vitoria.modulate.a = 0
	panel_vitoria.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(panel_vitoria, "modulate:a", 1.0, 0.4)
	tw.tween_property(panel_vitoria, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# === STYLING HELPERS ===

func _aplicar_estilo_neon_secundario(btn: Button, cor: Color) -> void:
	# Estilo Glassmorphic
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 1.0, 1.0, 0.05)
	normal.border_width_left = 1; normal.border_width_right = 1
	normal.border_width_top = 1; normal.border_width_bottom = 1
	normal.border_color = Color(1.0, 1.0, 1.0, 0.15)
	normal.corner_radius_top_left = 6; normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6; normal.corner_radius_bottom_left = 6
	
	normal.content_margin_left = 20; normal.content_margin_right = 20
	normal.content_margin_top = 12; normal.content_margin_bottom = 12
	
	# Estilo Hover
	var hover = normal.duplicate()
	hover.bg_color = cor
	hover.border_color = cor
	hover.border_width_left = 2; hover.border_width_right = 2
	hover.border_width_top = 2; hover.border_width_bottom = 2
	hover.shadow_color = cor
	hover.shadow_color.a = 0.5
	hover.shadow_size = 20
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)
	
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.05, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(0.05, 0.05, 0.05, 1.0))

func _on_hover_btn(btn: Button) -> void:
	_play_sfx(sfx_hover)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "modulate", Color(1.1, 1.1, 1.1), 0.15)

func _on_unhover_btn(btn: Button) -> void:
	var tw = create_tween().set_parallel(true)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.15)
