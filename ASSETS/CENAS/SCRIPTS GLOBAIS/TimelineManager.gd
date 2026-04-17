extends Node

func tocar_dialogo(nome):
	Dialogic.start(nome)
	await Dialogic.timeline_ended
