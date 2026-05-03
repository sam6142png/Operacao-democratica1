extends Control

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const TEX_LIVRO = preload("res://ASSETS/SPRITES/PROPS/LivroAberto.png")

const TODAS_PAGINAS = [
	{
		"texto": "Todo cidadão tem direito à educação gratuita e de qualidade.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "A educação é um direito fundamental garantido pela Constituição."
	},
	{
		"texto": "É dever do cidadão votar nas eleições e participar da vida política.",
		"resposta": "dever",
		"adulterada": false,
		"explicacao": "Participar da vida política é um dever cívico de todo cidadão."
	},
	{
		"texto": "O governo pode censurar qualquer informação que julgue perigosa para a ordem pública.",
		"resposta": "adulterada",
		"adulterada": true,
		"explicacao": "⚠ VERSÃO ADULTERADA DO REGIME! A liberdade de informação é um direito fundamental."
	},
	{
		"texto": "Todo cidadão tem direito à liberdade de expressão e manifestação pacífica.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "A liberdade de expressão é um pilar fundamental da democracia."
	},
	{
		"texto": "É dever do cidadão respeitar e preservar o patrimônio público e comunitário.",
		"resposta": "dever",
		"adulterada": false,
		"explicacao": "Preservar o patrimônio público é responsabilidade de todos os cidadãos."
	},
	{
		"texto": "O Estado tem o dever de garantir saúde, moradia e segurança a todos os cidadãos.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "Saúde, moradia e segurança são direitos sociais garantidos pelo Estado."
	},
	{
		"texto": "Cidadãos que discordarem do governo devem ser realocados para zonas de trabalho forçado.",
		"resposta": "adulterada",
		"adulterada": true,
		"explicacao": "⚠ VERSÃO ADULTERADA DO REGIME! Nenhum cidadão pode ser punido por discordar do governo."
	},
	{
		"texto": "É dever do cidadão pagar impostos para financiar serviços públicos coletivos.",
		"resposta": "dever",
		"adulterada": false,
		"explicacao": "O pagamento de impostos é um dever que sustenta os serviços públicos de todos."
	},
	{
		"texto": "Todo cidadão tem direito a um julgamento justo e à presunção de inocência.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "O direito a um julgamento justo é garantia fundamental do Estado de Direito."
	},
	{
		"texto": "O regime tem autoridade para suspender eleições em períodos de instabilidade social.",
		"resposta": "adulterada",
		"adulterada": true,
		"explicacao": "⚠ VERSÃO ADULTERADA DO REGIME! Eleições são direito inalienável do povo e não podem ser suspensas."
	}
]

# Fases de dificuldade
const TEMPO_FASE2 = 20.0
const TEMPO_FASE3 = 12.0
const MAX_ERROS = 3

var paginas_embaralhadas: Array = []
var pagina_atual: int = 0
var acertos: int = 0
var erros: int = 0
var esta_arrastando: bool = false
var pos_original_pagina: Vector2
var timer_restante: float = 0.0
var usar_timer: bool = false
var aguardando_proxima: bool = false
var minigame_iniciado: bool = false

@onready var texto_pagina: Label        = %TextoPagina
@onready var pagina_card: PanelContainer = %PaginaCard
@onready var feedback: Label            = %Feedback
@onready var progresso: Label           = %Progresso
@onready var explicacao: PanelContainer = %Explicacao
@onready var texto_explicacao: Label    = %TextoExplicacao
@onready var botao_direito: Button      = %BotaoDireito
@onready var botao_dever: Button        = %BotaoDever
@onready var botao_adulterada: Button   = %BotaoAdulterada
@onready var zona_esquerda: Control     = %ZonaEsquerda
@onready var zona_direita: Control      = %ZonaDireita
@onready var pagina_container: Control  = %PaginaContainer
@onready var label_timer: Label         = %LabelTimer
@onready var label_erros: Label         = %LabelErros
@onready var label_dir_txt: Label       = %LabelDireito
@onready var label_dev_txt: Label       = %LabelDever

var zona_baixo: Control
var painel_intro: PanelContainer
var painel_outro: PanelContainer

func _ready() -> void:
	pos_original_pagina = pagina_container.position
	_aplicar_tema_vintage()
	_criar_zonas_e_paineis()
	
	# Conectar botões para fallback
	botao_direito.pressed.connect(func(): _avaliar("direito"))
	botao_dever.pressed.connect(func(): _avaliar("dever"))
	botao_adulterada.pressed.connect(func(): _avaliar("adulterada"))
	
	_mostrar_intro()

func _aplicar_tema_vintage() -> void:
	# Cores base
	var cor_fundo_hud = Color("#F4E4BC") # Papel envelhecido
	var cor_texto_escuro = Color("#3A2A1A") # Tinta sépia/marrom escura
	var cor_borda = Color("#8B5A2B") # Marrom madeira
	
	# Alterar fundo da tela para dar mais contraste
	if has_node("Fundo"):
		get_node("Fundo").color = Color("#0A0A0C") # Quase preto
		
	# HUDBase
	if has_node("HUDBase"):
		var hud = get_node("HUDBase") as Panel
		var style_hud = StyleBoxFlat.new()
		style_hud.bg_color = cor_fundo_hud
		style_hud.border_width_bottom = 4
		style_hud.border_color = cor_borda
		hud.add_theme_stylebox_override("panel", style_hud)
		
	# Fonte e Cores dos Textos
	for lbl in [texto_pagina, feedback, progresso, texto_explicacao, label_timer, label_erros, label_dir_txt, label_dev_txt]:
		if lbl: 
			lbl.add_theme_font_override("font", FONTE)
			lbl.add_theme_color_override("font_color", cor_texto_escuro)
			
	# Melhorar legibilidade do Feedback
	if feedback:
		feedback.add_theme_color_override("font_outline_color", Color.BLACK)
		feedback.add_theme_constant_override("outline_size", 4)
		feedback.add_theme_font_size_override("font_size", 28)
			
	# Configurar o Card para parecer um Livro/Papel
	if pagina_card:
		var style_card = StyleBoxTexture.new()
		style_card.texture = TEX_LIVRO
		style_card.texture_margin_left = 90
		style_card.texture_margin_right = 90
		style_card.texture_margin_top = 90
		style_card.texture_margin_bottom = 90
		pagina_card.add_theme_stylebox_override("panel", style_card)
		
		# Travar o tamanho do container para não esticar a imagem
		pagina_card.custom_minimum_size = Vector2(700, 480)
		pagina_card.set_deferred("size", Vector2(700, 480))
		
		# Aumentar contraste do texto
		texto_pagina.add_theme_color_override("font_color", Color("#111111"))
		texto_pagina.add_theme_font_size_override("font_size", 24)

	# Explicacao fundo
	if explicacao:
		var style_exp = StyleBoxFlat.new()
		style_exp.bg_color = Color("#F4E4BC")
		style_exp.border_width_left = 3
		style_exp.border_width_top = 3
		style_exp.border_width_right = 3
		style_exp.border_width_bottom = 3
		style_exp.border_color = cor_borda
		style_exp.corner_radius_top_left = 5
		style_exp.corner_radius_top_right = 5
		style_exp.corner_radius_bottom_left = 5
		style_exp.corner_radius_bottom_right = 5
		explicacao.add_theme_stylebox_override("panel", style_exp)
		
	# Botões
	for btn in [botao_direito, botao_dever, botao_adulterada]:
		if btn: 
			btn.add_theme_font_override("font", FONTE)
			btn.add_theme_font_size_override("font_size", 20)
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color("#D4C49C")
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = cor_borda
			sb.corner_radius_top_left = 5
			sb.corner_radius_top_right = 5
			sb.corner_radius_bottom_left = 5
			sb.corner_radius_bottom_right = 5
			btn.add_theme_stylebox_override("normal", sb)
			btn.add_theme_color_override("font_color", cor_texto_escuro)
			
	# Atualizar textos fixos
	botao_adulterada.text = "[ REJEITAR ]"
	
	label_dir_txt.text = "⬅ DIREITO"
	label_dir_txt.add_theme_font_size_override("font_size", 40)
	label_dir_txt.add_theme_color_override("font_color", Color("#FFFFFF"))
	label_dir_txt.add_theme_color_override("font_outline_color", Color.BLACK)
	label_dir_txt.add_theme_constant_override("outline_size", 6)
	
	label_dev_txt.text = "DEVER ➡"
	label_dev_txt.add_theme_font_size_override("font_size", 40)
	label_dev_txt.add_theme_color_override("font_color", Color("#FFFFFF"))
	label_dev_txt.add_theme_color_override("font_outline_color", Color.BLACK)
	label_dev_txt.add_theme_constant_override("outline_size", 6)
	
	label_erros.text = "ERROS: 0/3"
	progresso.text = "PÁGINA: 0/10"
	label_timer.text = "TEMPO:"

func _criar_zonas_e_paineis() -> void:
	# Zona Baixo (Descarte)
	zona_baixo = Control.new()
	zona_baixo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	zona_baixo.offset_top = -250
	zona_baixo.modulate = Color(0.8, 0.2, 0.2, 0.0) # Transparente no inicio
	add_child(zona_baixo)
	move_child(zona_baixo, 1)
	
	var label_baixo = Label.new()
	label_baixo.text = "⬇ DESCARTAR FALSO ⬇"
	label_baixo.add_theme_font_override("font", FONTE)
	label_baixo.add_theme_font_size_override("font_size", 40)
	label_baixo.add_theme_color_override("font_color", Color("#FFFFFF"))
	label_baixo.add_theme_color_override("font_outline_color", Color.BLACK)
	label_baixo.add_theme_constant_override("outline_size", 6)
	label_baixo.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label_baixo.offset_bottom = -100
	zona_baixo.add_child(label_baixo)
	
	# Painel Intro
	painel_intro = _criar_painel_sobreposicao()
	var titulo_intro = Label.new()
	titulo_intro.text = "ANÁLISE DE DOCUMENTOS"
	titulo_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_intro.add_theme_font_override("font", FONTE)
	titulo_intro.add_theme_font_size_override("font_size", 32)
	painel_intro.get_child(0).add_child(titulo_intro)
	
	var desc_intro = Label.new()
	desc_intro.text = "Arraste para ESQUERDA os Direitos.\nArraste para DIREITA os Deveres.\nArraste para BAIXO as páginas falsas do regime.\n\nVocê só pode errar 3 vezes."
	desc_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_intro.add_theme_font_override("font", FONTE)
	desc_intro.add_theme_font_size_override("font_size", 20)
	painel_intro.get_child(0).add_child(desc_intro)
	
	var btn_iniciar = Button.new()
	btn_iniciar.text = "COMEÇAR ANÁLISE"
	btn_iniciar.add_theme_font_override("font", FONTE)
	btn_iniciar.custom_minimum_size = Vector2(250, 60)
	btn_iniciar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_iniciar.pressed.connect(func():
		painel_intro.visible = false
		_iniciar_rodada()
	)
	painel_intro.get_child(0).add_child(btn_iniciar)
	add_child(painel_intro)
	
	# Painel Outro
	painel_outro = _criar_painel_sobreposicao()
	painel_outro.visible = false
	add_child(painel_outro)

func _criar_painel_sobreposicao() -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(600, 400)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#F4E4BC")
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.border_color = Color("#8B5A2B")
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	p.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	p.add_child(vbox)
	return p

func _mostrar_intro() -> void:
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false
	pagina_container.visible = false
	explicacao.visible = false
	feedback.text = ""
	painel_intro.visible = true

func _iniciar_rodada() -> void:
	pagina_container.visible = true
	minigame_iniciado = true
	paginas_embaralhadas = TODAS_PAGINAS.duplicate()
	paginas_embaralhadas.shuffle()
	pagina_atual = 0
	acertos = 0
	erros = 0
	aguardando_proxima = false
	label_erros.text = "ERROS: 0/" + str(MAX_ERROS)
	label_timer.text = ""
	_carregar_pagina(0)

func _carregar_pagina(idx: int) -> void:
	if idx >= paginas_embaralhadas.size():
		_mostrar_outro()
		return

	var pagina = paginas_embaralhadas[idx]
	texto_pagina.text = pagina["texto"]
	progresso.text = "PÁGINA: " + str(idx + 1) + "/" + str(paginas_embaralhadas.size())
	label_erros.text = "ERROS: " + str(erros) + "/" + str(MAX_ERROS)

	# IMPORTANTE: Removido o "spoiler" de cor que denunciava as cartas falsas imediatamente!
	texto_pagina.add_theme_color_override("font_color", Color("#111111"))

	FadeManager.fade_in()
	pagina_container.position = pos_original_pagina + Vector2(0, 500)
	pagina_container.modulate.a = 0.0
	pagina_container.rotation = 0.0
	pagina_container.scale = Vector2(1, 1)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pagina_container, "position", pos_original_pagina, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pagina_container, "modulate:a", 1.0, 0.4)
	
	feedback.text = "Lendo..."
	feedback.add_theme_color_override("font_color", Color("#F4E4BC"))
	explicacao.visible = false
	aguardando_proxima = false
	
	_configurar_timer()

func _configurar_timer() -> void:
	match GameState.fase_atual:
		1: 
			# Ativando o timer na fase 1 também
			usar_timer = true
			timer_restante = 30.0
		2:
			usar_timer = true
			timer_restante = TEMPO_FASE2
		3:
			usar_timer = true
			timer_restante = TEMPO_FASE3
	
	label_timer.visible = usar_timer

func _process(delta: float) -> void:
	if not minigame_iniciado or aguardando_proxima: return
	
	if usar_timer:
		timer_restante -= delta
		label_timer.text = "TEMPO: " + str(int(timer_restante)) + "s"
		if timer_restante <= 5.0:
			# Usa get_ticks_msec para piscar independente do framerate
			var piscar = (Time.get_ticks_msec() % 500) > 250
			label_timer.add_theme_color_override("font_color", Color("#FF3333") if piscar else Color("#3A2A1A"))
		if timer_restante <= 0:
			_avaliar("timeout")

	# Arrastar
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		if pagina_container.get_global_rect().has_point(mouse_pos) or esta_arrastando:
			esta_arrastando = true
			pagina_container.global_position = mouse_pos - pagina_container.size / 2.0
			
			# Inclinação baseada no movimento X
			var offset_x = pagina_container.position.x - pos_original_pagina.x
			pagina_container.rotation = lerp(pagina_container.rotation, deg_to_rad(offset_x / 15.0), 0.2)
			
			# Escala baseada no movimento Y (para dar a sensação de aproximar do lixo)
			var offset_y = pagina_container.position.y - pos_original_pagina.y
			if offset_y > 0:
				var scale_factor = 1.0 - clamp(offset_y / 1000.0, 0.0, 0.3)
				pagina_container.scale = Vector2(scale_factor, scale_factor)
			else:
				pagina_container.scale = Vector2(1, 1)
			
			var pos_centro = pagina_container.global_position + pagina_container.size / 2.0
			zona_esquerda.modulate.a = 0.6 if zona_esquerda.get_global_rect().has_point(pos_centro) else 0.2
			zona_direita.modulate.a = 0.6 if zona_direita.get_global_rect().has_point(pos_centro) else 0.2
			zona_baixo.modulate.a = 0.6 if zona_baixo.get_global_rect().has_point(pos_centro) else 0.0

	elif esta_arrastando:
		esta_arrastando = false
		var rect_esq = zona_esquerda.get_global_rect()
		var rect_dir = zona_direita.get_global_rect()
		var rect_baixo = zona_baixo.get_global_rect()
		var pos_centro = pagina_container.global_position + pagina_container.size / 2.0
		
		if rect_baixo.has_point(pos_centro):
			_avaliar("adulterada")
		elif rect_esq.has_point(pos_centro):
			_avaliar("direito")
		elif rect_dir.has_point(pos_centro):
			_avaliar("dever")
		else:
			_voltar_centro()
		
		zona_esquerda.modulate.a = 0.2
		zona_direita.modulate.a = 0.2
		zona_baixo.modulate.a = 0.0

func _voltar_centro() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pagina_container, "position", pos_original_pagina, 0.4).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(pagina_container, "rotation", 0.0, 0.3)
	tween.tween_property(pagina_container, "scale", Vector2(1, 1), 0.3)

func _avaliar(escolha: String) -> void:
	if aguardando_proxima: return
	aguardando_proxima = true
	esta_arrastando = false # Previne que a próxima carta seja puxada imediatamente
	
	var pagina = paginas_embaralhadas[pagina_atual]
	var _sucesso = false

	if escolha == "timeout":
		erros += 1
		GameState.confianca -= 1
		_feedback_visual(false, "TEMPO ESGOTADO!")
	elif pagina["adulterada"] and escolha == "adulterada":
		_sucesso = true
		acertos += 1
		GameState.confianca += 2
		_feedback_visual(true, "DESCARTADO COM SUCESSO")
	elif not pagina["adulterada"] and escolha == pagina["resposta"]:
		_sucesso = true
		acertos += 1
		GameState.confianca += 1
		_feedback_visual(true, "CLASSIFICAÇÃO CORRETA")
	elif pagina["adulterada"] and escolha != "adulterada":
		erros += 1
		GameState.confianca -= 2
		_feedback_visual(false, "ATENÇÃO! PÁGINA ADULTERADA APROVADA!")
	else:
		erros += 1
		GameState.confianca -= 1
		_feedback_visual(false, "CLASSIFICAÇÃO INCORRETA")

	_mostrar_explicacao(pagina["explicacao"])
	label_erros.text = "ERROS: " + str(erros) + "/" + str(MAX_ERROS)

	# Animação de saída da carta baseada na escolha
	var offset_saida = Vector2(0, 0)
	var angulo = 0
	var scale_final = 1.0
	
	if escolha == "direito": 
		offset_saida = Vector2(-1500, 0)
		angulo = -45
	elif escolha == "dever": 
		offset_saida = Vector2(1500, 0)
		angulo = 45
	elif escolha == "adulterada":
		offset_saida = Vector2(0, 1000)
		scale_final = 0.2
	else:
		offset_saida = Vector2(0, 1000)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pagina_container, "position", pagina_container.position + offset_saida, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(pagina_container, "modulate:a", 0.0, 0.5)
	tween.tween_property(pagina_container, "rotation", deg_to_rad(angulo), 0.6)
	tween.tween_property(pagina_container, "scale", Vector2(scale_final, scale_final), 0.6)

	if erros >= MAX_ERROS:
		await get_tree().create_timer(1.5).timeout
		_mostrar_gameover()
		return

	await get_tree().create_timer(1.2).timeout
	pagina_atual += 1
	_carregar_pagina(pagina_atual)

func _feedback_visual(vitoria: bool, texto: String) -> void:
	feedback.text = texto
	feedback.add_theme_color_override("font_color", Color("#00FF88") if vitoria else Color("#FF4444"))
	
	if not vitoria:
		var pos_orig = position
		var tween_shake = create_tween()
		for i in 6:
			var rand_pos = pos_orig + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			tween_shake.tween_property(self, "position", rand_pos, 0.05)
		tween_shake.tween_property(self, "position", pos_orig, 0.05)

func _mostrar_explicacao(txt: String) -> void:
	explicacao.visible = true
	texto_explicacao.text = txt
	explicacao.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(explicacao, "modulate:a", 1.0, 0.3)

func _mostrar_gameover() -> void:
	minigame_iniciado = false
	explicacao.visible = false
	
	for child in painel_outro.get_child(0).get_children():
		child.queue_free()
		
	var titulo = Label.new()
	titulo.text = "ANÁLISE INTERROMPIDA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", FONTE)
	titulo.add_theme_color_override("font_color", Color("#B22222"))
	titulo.add_theme_font_size_override("font_size", 32)
	painel_outro.get_child(0).add_child(titulo)
	
	var btn = Button.new()
	btn.text = "TENTAR NOVAMENTE"
	btn.add_theme_font_override("font", FONTE)
	btn.custom_minimum_size = Vector2(250, 60)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func():
		painel_outro.visible = false
		_iniciar_rodada()
	)
	painel_outro.get_child(0).add_child(btn)
	painel_outro.visible = true

func _mostrar_outro() -> void:
	minigame_iniciado = false
	explicacao.visible = false
	
	for child in painel_outro.get_child(0).get_children():
		child.queue_free()
		
	var titulo = Label.new()
	titulo.text = "ANÁLISE CONCLUÍDA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", FONTE)
	titulo.add_theme_color_override("font_color", Color("#228B22"))
	titulo.add_theme_font_size_override("font_size", 32)
	painel_outro.get_child(0).add_child(titulo)
	
	var desc = Label.new()
	desc.text = "Páginas validadas: " + str(acertos) + "\nErros cometidos: " + str(erros) + "\n\nA confiança da cidade foi impactada de acordo com as suas escolhas."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_override("font", FONTE)
	desc.add_theme_color_override("font_color", Color("#3A2A1A"))
	desc.add_theme_font_size_override("font_size", 20)
	painel_outro.get_child(0).add_child(desc)
	
	var btn = Button.new()
	btn.text = "CONTINUAR"
	btn.add_theme_font_override("font", FONTE)
	btn.custom_minimum_size = Vector2(250, 60)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _finalizar_minigame())
	painel_outro.get_child(0).add_child(btn)
	
	painel_outro.visible = true

func _finalizar_minigame() -> void:
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = true
		
	if GameState.fase_atual == 1: GameState.fase_atual = 2
	FadeManager.carregar_cena("res://ASSETS/CENAS/game_scene.tscn")
