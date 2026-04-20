extends Node

func tocar_dialogo(nome: String):
	Dialogic.start(nome)
	
	# Verifica se a timeline iniciou corretamente. 
	# Se falhar (ex: erro de exportação do Dialogic), o jogo não trava pra sempre.
	if Dialogic.current_timeline != null:
		await Dialogic.timeline_ended
	else:
		push_error("Dialogic falhou ao iniciar a timeline: " + nome)
