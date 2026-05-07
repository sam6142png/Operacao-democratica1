extends Node

signal dialogo_iniciado(nome: String)
signal dialogo_finalizado(nome: String)

var esta_tocando: bool = false

func _ready():
	# Configura o Dialogic para avançar as falas automaticamente
	if Dialogic.has_subsystem("Inputs"):
		var inputs = Dialogic.Inputs
		if inputs.auto_advance:
			inputs.auto_advance.enabled_forced = true
			# Tempo fixo de espera após o texto terminar (em segundos)
			inputs.auto_advance.fixed_delay = 1.2
			# Velocidade baseada nos caracteres (opcional, para naturalidade)
			inputs.auto_advance.per_character_delay = 0.05

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
	
	# Limpa o estado interno para evitar erros de referências órfãs
	if Dialogic.has_subsystem("Portraits"):
		var portraits = Dialogic.Portraits
		if portraits.has_method("leave_all_characters"):
			portraits.leave_all_characters()
	
	# Aguarda um frame para garantir que os nós foram removidos
	if get_tree():
		await get_tree().process_frame

func tocar_dialogo(nome: String):
	if esta_tocando:
		push_warning("[TimelineManager] Já existe um diálogo em execução. Aguardando...")
		await dialogo_finalizado
	
	# Se por acaso o Dialogic tiver algo rodando (ex: restaurado de um save), encerramos e esperamos
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
		await Dialogic.timeline_ended
		await get_tree().process_frame
	
	Dialogic.paused = false
	
	esta_tocando = true
	GameState.timeline_atual = nome
	dialogo_iniciado.emit(nome)
	print("[TimelineManager] Iniciando: ", nome)
	
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
		GameState.salvar_jogo()
		Dialogic.Save.save("autosave")
		dialogo_finalizado.emit(nome)
		print("[TimelineManager] Finalizado e salvo: ", nome)
	else:
		esta_tocando = false
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
