extends Node

signal dialogo_iniciado(nome: String)
signal dialogo_finalizado(nome: String)

var esta_tocando: bool = false

func tocar_dialogo(nome: String):
	if esta_tocando:
		push_warning("[TimelineManager] Já existe um diálogo em execução. Aguardando...")
		await dialogo_finalizado
	
	# Garante que o motor processou o frame anterior
	await get_tree().process_frame
	
	esta_tocando = true
	dialogo_iniciado.emit(nome)
	print("[TimelineManager] Iniciando: ", nome)
	
	var timeline = Dialogic.start(nome)
	
	if timeline:
		await Dialogic.timeline_ended
		esta_tocando = false
		dialogo_finalizado.emit(nome)
		print("[TimelineManager] Finalizado: ", nome)
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
