extends Node

# Estado Global do Jogo
# Resetado para começar o desenvolvimento da Fase 2 do zero

signal confianca_changed(novo_valor: int, delta: int)

var reputacao: int = 0
var confianca: int = 0:
	set(val):
		var delta = val - confianca
		confianca = val
		confianca_changed.emit(confianca, delta)
var fase_atual: int = 1
var acertos_paginas_fase1: int = 0
var adulterada_identificada_fase1: bool = false

# Dicionário para persistência de decisões importantes
var decisoes_fase_1 = {
	"falou_com_velho": false,
	"ajudou_vila": false
}

var decisoes_fase_2 = {
	# A definir
}
