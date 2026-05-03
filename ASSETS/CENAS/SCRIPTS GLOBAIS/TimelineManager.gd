extends Node

signal dialogo_iniciado(nome: String)
signal dialogo_finalizado(nome: String)

var esta_tocando: bool = false

func parar_tudo():
	esta_tocando = false
	# Encerra qualquer timeline ativa
	Dialogic.end_timeline()
	
	# Limpa o estado interno para evitar erros de referências órfãs (EncodedObjectAsID)
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
	
	# Garante que não há nada rodando antes de começar
	Dialogic.end_timeline()
	Dialogic.paused = false
	
	# Garante que o motor processou o frame anterior
	await get_tree().process_frame
	
	esta_tocando = true
	GameState.timeline_atual = nome
	dialogo_iniciado.emit(nome)
	print("[TimelineManager] Iniciando: ", nome)
	
	# Inicia a timeline
	var timeline = Dialogic.start(nome)
	
	if timeline:
		await Dialogic.timeline_ended
		esta_tocando = false
		GameState.salvar_jogo() # Salva no slot_atual por padrão
		Dialogic.Save.save("slot_" + str(GameState.slot_atual)) # Salva o estado interno do Dialogic no slot correto
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
