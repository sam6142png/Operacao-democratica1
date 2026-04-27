extends Control

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

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

func _ready() -> void:
	_aplicar_fonte()
	pos_original_pagina = pagina_container.position
	_iniciar_rodada()
	
	# Conectar botões
	botao_direito.pressed.connect(func(): _avaliar("direito"))
	botao_dever.pressed.connect(func(): _avaliar("dever"))
	botao_adulterada.pressed.connect(func(): _avaliar("adulterada"))

func _aplicar_fonte() -> void:
	for lbl in [texto_pagina, feedback, progresso, texto_explicacao,
		label_timer, label_erros, label_dir_txt, label_dev_txt]:
		if lbl: lbl.add_theme_font_override("font", FONTE)
	for btn in [botao_direito, botao_dever, botao_adulterada]:
		if btn: btn.add_theme_font_override("font", FONTE)

func _iniciar_rodada() -> void:
	paginas_embaralhadas = TODAS_PAGINAS.duplicate()
	paginas_embaralhadas.shuffle()
	pagina_atual = 0
	acertos = 0
	erros = 0
	aguardando_proxima = false
	label_erros.text = "LOG_DE_ERROS: 0/" + str(MAX_ERROS)
	label_timer.text = ""
	_carregar_pagina(0)

func _carregar_pagina(idx: int) -> void:
	if idx >= paginas_embaralhadas.size():
		_finalizar_minigame()
		return

	var pagina = paginas_embaralhadas[idx]
	texto_pagina.text = pagina["texto"]
	progresso.text = "FLUXO_DE_DADOS: " + str(idx + 1) + "/" + str(paginas_embaralhadas.size())
	label_erros.text = "LOG_DE_ERROS: " + str(erros) + "/" + str(MAX_ERROS)

	# Cor do texto baseada na fase
	if pagina["adulterada"]:
		texto_pagina.add_theme_color_override("font_color", Color("#E699FF"))
	else:
		texto_pagina.add_theme_color_override("font_color", Color("#FFFFFF"))

	# Reset visual com animação de entrada
	pagina_container.position = pos_original_pagina + Vector2(0, 500)
	pagina_container.modulate.a = 0.0
	pagina_container.rotation = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pagina_container, "position", pos_original_pagina, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pagina_container, "modulate:a", 1.0, 0.4)
	
	feedback.text = "ESTABILIDADE_DE_ESCANEAMENTO: 100%"
	feedback.add_theme_color_override("font_color", Color("#00D5FF"))
	explicacao.visible = false
	aguardando_proxima = false
	
	_configurar_timer()

func _configurar_timer() -> void:
	match GameState.fase_atual:
		1: usar_timer = false
		2:
			usar_timer = true
			timer_restante = TEMPO_FASE2
		3:
			usar_timer = true
			timer_restante = TEMPO_FASE3
	
	label_timer.visible = usar_timer

func _process(delta: float) -> void:
	if aguardando_proxima: return
	
	if usar_timer:
		timer_restante -= delta
		label_timer.text = "TEMPO_RESTANTE: " + str(int(timer_restante)) + "s"
		if timer_restante <= 5.0:
			label_timer.add_theme_color_override("font_color", Color("#FF4444") if Engine.get_frames_drawn() % 30 < 15 else Color("#FFFFFF"))
		if timer_restante <= 0:
			_avaliar("timeout")

	# Arrastar
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		if pagina_container.get_global_rect().has_point(mouse_pos) or esta_arrastando:
			esta_arrastando = true
			pagina_container.global_position = mouse_pos - pagina_container.size / 2
			
			# Inclinação baseada no movimento
			var offset_x = pagina_container.position.x - pos_original_pagina.x
			pagina_container.rotation = lerp(pagina_container.rotation, deg_to_rad(offset_x / 20.0), 0.2)
			
			var pos_centro = pagina_container.global_position + pagina_container.size / 2
			zona_esquerda.modulate.a = 0.6 if zona_esquerda.get_global_rect().has_point(pos_centro) else 0.2
			zona_direita.modulate.a = 0.6 if zona_direita.get_global_rect().has_point(pos_centro) else 0.2

	elif esta_arrastando:
		esta_arrastando = false
		var rect_esq = zona_esquerda.get_global_rect()
		var rect_dir = zona_direita.get_global_rect()
		var pos_centro = pagina_container.global_position + pagina_container.size / 2
		
		if rect_esq.has_point(pos_centro):
			_avaliar("direito")
		elif rect_dir.has_point(pos_centro):
			_avaliar("dever")
		else:
			_voltar_centro()
		
		zona_esquerda.modulate.a = 0.2
		zona_direita.modulate.a = 0.2

func _voltar_centro() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pagina_container, "position", pos_original_pagina, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pagina_container, "rotation", 0.0, 0.3)

func _avaliar(escolha: String) -> void:
	if aguardando_proxima: return
	aguardando_proxima = true
	
	var pagina = paginas_embaralhadas[pagina_atual]
	var sucesso = false

	if escolha == "timeout":
		erros += 1
		GameState.confianca -= 1
		_feedback_visual(false, "⚠ TIMEOUT: PERDA_DE_DADOS_DETECTADA")
	elif pagina["adulterada"] and escolha == "adulterada":
		sucesso = true
		acertos += 1
		GameState.confianca += 2
		_feedback_visual(true, "✔ DADOS_CORROMPIDOS_IDENTIFICADOS")
	elif not pagina["adulterada"] and escolha == pagina["resposta"]:
		sucesso = true
		acertos += 1
		GameState.confianca += 1
		_feedback_visual(true, "✔ ESTABILIDADE_DE_DADOS_CONFIRMADA")
	elif pagina["adulterada"] and escolha != "adulterada":
		erros += 1
		GameState.confianca -= 2
		_feedback_visual(false, "✖ ERRO_CRÍTICO: MALWARE_DETECTADO")
	else:
		erros += 1
		GameState.confianca -= 1
		_feedback_visual(false, "✖ ERRO_DE_CLASSIFICAÇÃO")

	_mostrar_explicacao(pagina["explicacao"])
	label_erros.text = "LOG_DE_ERROS: " + str(erros) + "/" + str(MAX_ERROS)

	# Animação de saída da carta
	var offset_saida = Vector2(0, -1000)
	if escolha == "direito": offset_saida = Vector2(-1500, 0)
	elif escolha == "dever": offset_saida = Vector2(1500, 0)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pagina_container, "position", pagina_container.position + offset_saida, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(pagina_container, "modulate:a", 0.0, 0.5)
	tween.tween_property(pagina_container, "rotation", deg_to_rad(45 if escolha == "dever" else -45), 0.8)

	if erros >= MAX_ERROS:
		await get_tree().create_timer(1.5).timeout
		_reiniciar()
		return

	await get_tree().create_timer(1.2).timeout
	pagina_atual += 1
	_carregar_pagina(pagina_atual)

func _feedback_visual(vitoria: bool, texto: String) -> void:
	feedback.text = texto
	feedback.add_theme_color_override("font_color", Color("#00FF88") if vitoria else Color("#FF4444"))
	
	# Shake de tela se erro
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

func _reiniciar() -> void:
	feedback.text = "REINICIALIZAÇÃO_NECESSÁRIA... ACESSO_NEGADO"
	feedback.add_theme_color_override("font_color", Color("#FF4444"))
	explicacao.visible = false
	await get_tree().create_timer(2.0).timeout
	_iniciar_rodada()

func _finalizar_minigame() -> void:
	feedback.text = "DESCRIPTOGRAFIA_CONCLUÍDA: 100%"
	feedback.add_theme_color_override("font_color", Color("#00FF88"))
	await get_tree().create_timer(1.5).timeout
	
	if GameState.fase_atual == 1: GameState.fase_atual = 2
	get_tree().change_scene_to_file("res://ASSETS/CENAS/game_scene.tscn")
