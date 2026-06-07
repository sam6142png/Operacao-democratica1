extends Node

signal dialogo_iniciado(nome: String)
signal dialogo_finalizado(nome: String)

var esta_tocando: bool = false

# Tempo base da caixa de diálogo (multiplicado pelo fator de velocidade)
const AUTO_ADVANCE_FIXED_DELAY_BASE := 2.8
const AUTO_ADVANCE_PER_CHARACTER_BASE := 0.09
const TEXT_SPEED_BASE := 1.0

# Timelines onde a velocidade é travada em 1x (cenas de impacto narrativo)
const TIMELINES_PROTEGIDAS := [
	"Intro_Narrativa",
	"fase2_reacao_final",
	"fase3_escola_conclusao",
]

var _vel_dialogos: float = 1.0
var _timeline_atual_nome: String = ""


func _ready() -> void:
	_aplicar_config_auto_advance()


## Define o multiplicador de velocidade dos diálogos (1.0 = normal, 2.0 = máximo).
## Salva para ser reutilizado em cada timeline.
func set_velocidade_dialogos(vel: float) -> void:
	_vel_dialogos = clampf(vel, 1.0, 2.0)
	_aplicar_config_auto_advance()


func _timeline_esta_protegida(nome: String) -> bool:
	for protegida in TIMELINES_PROTEGIDAS:
		if nome.contains(protegida):
			return true
	return false


func _aplicar_config_auto_advance() -> void:
	if not Dialogic.has_subsystem("Inputs"):
		return
	var inputs = Dialogic.Inputs
	if not inputs.auto_advance:
		return
	
	var vel := 1.0 if _timeline_esta_protegida(_timeline_atual_nome) else _vel_dialogos
	var fator_delay := vel * vel
	
	inputs.auto_advance.enabled_forced = true
	inputs.auto_advance.fixed_delay = AUTO_ADVANCE_FIXED_DELAY_BASE / fator_delay
	inputs.auto_advance.per_character_delay = AUTO_ADVANCE_PER_CHARACTER_BASE / fator_delay
	
	# Acelera também o "typing" do texto para o 2x ficar realmente perceptível.
	if Dialogic.has_subsystem("Settings"):
		Dialogic.Settings.text_speed = TEXT_SPEED_BASE / vel
	if Dialogic.has_subsystem("Text"):
		Dialogic.Text.update_text_speed()

func parar_tudo():
	esta_tocando = false
	# Encerra qualquer timeline ativa imediatamente ignorando animações de saída
	Dialogic.end_timeline(true)
	
	# Limpa todos os subsistemas do Dialogic (incluindo Choices e UI)
	Dialogic.clear()
	
	# Força parada do timer visual de escolhas
	if has_node("/root/ChoiceTimer"):
		get_node("/root/ChoiceTimer").forcar_parar()
	
	# Força ocultação do layout se ainda estiver visível
	if Dialogic.has_subsystem("Styles"):
		if Dialogic.Styles.has_active_layout_node():
			var layout = Dialogic.Styles.get_layout_node()
			if layout:
				layout.hide()
				if layout.get_parent():
					layout.get_parent().remove_child(layout)
				layout.queue_free()
		if get_tree().has_meta("dialogic_layout_node"):
			get_tree().remove_meta("dialogic_layout_node")
	
	# Limpa o estado interno para evitar erros de referências órfãs
	if Dialogic.has_subsystem("Portraits"):
		var portraits = Dialogic.Portraits
		if portraits.has_method("leave_all_characters"):
			portraits.leave_all_characters()
	
	# Aguarda um frame para garantir que os nós foram removidos
	if get_tree():
		await get_tree().process_frame

func tocar_dialogo(nome: String, salvar_ao_final: bool = true):
	if esta_tocando:
		push_warning("[TimelineManager] Já existe um diálogo em execução. Aguardando...")
		await dialogo_finalizado
	
	# Se por acaso o Dialogic tiver algo rodando (ex: restaurado de um save), encerramos e esperamos
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
		await Dialogic.timeline_ended
		await get_tree().process_frame
	
	Dialogic.paused = false
	_aplicar_config_auto_advance()
	
	esta_tocando = true
	_timeline_atual_nome = nome
	GameState.timeline_atual = nome
	_aplicar_config_auto_advance()
	dialogo_iniciado.emit(nome)
	print("[TimelineManager] Iniciando: ", nome)
	
	# Garante que o estilo de caixa de texto selecionado seja carregado no Dialogic
	if GameState.estilo_textbox_selecionado != "":
		Dialogic.Styles.load_style(GameState.estilo_textbox_selecionado)
		
	# Inicia a timeline
	var timeline = Dialogic.start(nome)
	
	if timeline:
		await Dialogic.timeline_ended
		
		# GUARDA CRÍTICA: Se esta_tocando já é false, significa que parar_tudo()
		# foi chamado (ex: jogador voltou ao menu). NÃO devemos salvar aqui,
		# pois isso sobrescreveria o save manual do jogador com dados vazios.
		if not esta_tocando:
			print("[TimelineManager] Timeline interrompida (menu). Save preservado.")
			dialogo_finalizado.emit(nome)
			return
		
		esta_tocando = false
		_timeline_atual_nome = ""
		GameState.limpar_timeline_ativa()
		if salvar_ao_final:
			GameState.salvar_jogo()
			Dialogic.Save.save("autosave")
		dialogo_finalizado.emit(nome)
		print("[TimelineManager] Finalizado", " e salvo: " if salvar_ao_final else ": ", nome)
	else:
		esta_tocando = false
		_timeline_atual_nome = ""
		dialogo_finalizado.emit(nome)
		push_error("[TimelineManager] Erro ao carregar: " + nome)

# Atalhos para variáveis do Dialogic
func definir_var(caminho: String, valor):
	Dialogic.VAR.set_variable(caminho, valor)

func obter_var(caminho: String):
	return Dialogic.VAR.get_variable(caminho)

func ajustar_reputacao(delta: int = 1):
	var atual = obter_var("Game.Reputacao")
	if atual == null: atual = 0
	definir_var("Game.Reputacao", atual + delta)
	print("[TimelineManager] Reputação ajustada: ", atual + delta)
