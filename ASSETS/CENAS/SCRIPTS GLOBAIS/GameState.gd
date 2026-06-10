extends Node

const SAVE_FILE = "user://autosave.json"
const SETTINGS_FILE = "user://settings.json"

signal confianca_changed(novo_valor: int, delta: int)

# --- Configurações Globais ---
var vol_musica: float = 50.0
var vol_sfx: float = 50.0
var vel_dialogos: float = 1.0
var tela_cheia: int = 0
var resolucao: int = 1
var auto_avanco: int = 0
var auto_avanco_delay: float = 2.5
var pular_lidos: int = 1
var tamanho_fonte: int = 0

# --- Modo Minigames ---
var is_minigame_mode: bool = false
var minigame_atual_idx: int = 0

# --- Variáveis de Estado ---
var reputacao: int = 0
var confianca: int = 0:
	set(val):
		var delta = val - confianca
		confianca = val
		confianca_changed.emit(confianca, delta)

var fase_atual: int = 1
var acertos_paginas_fase1: int = 0
var adulterada_identificada_fase1: bool = false
var cena_atual: String = "res://ASSETS/CENAS/game_scene.tscn"
var timeline_atual: String = ""
## Quando true, game_scene deve rodar iniciar_sequencia_fase() (retorno de minigame).
var aguardando_sequencia_fase: bool = false

var decisoes_fase_1 = {
	"falou_com_velho": false,
	"ajudou_vila": false
}
var decisoes_fase_2 = {}
var fase2_passo: String = "inicio"
var fase3_passo: String = "inicio"
var fase4_passo: String = "praca"
var cartas_final_desbloqueadas: Array[String] = []
var aliados_final: Dictionary = {}
var resultado_final: String = ""
var pontuacao_final: Dictionary = {}
var registros_democraticos: Array[Dictionary] = []

# --- Conquistas e Customização ---
var conquistas_desbloqueadas: Dictionary = {
	"historiador": false,      # Completou Fase 1
	"radio_perfeito": false,  # Decifrou rádio sem errar na Fase 2
	"escola_ok": false,        # Completou Fase 3 (Escola)
	"praca_pacifica": false,  # Completou Fase 4 (Praça) com Segurança > 80% e sem violência
	"fim_democratico": false, # Final da Rota Democrática
	"fim_qualquer": false     # Concluiu o jogo em qualquer rota
}
var skin_dante_selecionada: String = "padrao" # "padrao", "estudante", "diplomata", "revolucionario"
var estilo_textbox_selecionado: String = "res://ASSETS/DIALOGIC/STYLES/Base_testebox.tres"

# Log de escolhas para exibir no menu de pausa
# Cada entrada: {"texto": "...", "delta": +1 ou -1}
var log_escolhas: Array = []

func registrar_escolha(texto: String, delta: int):
	log_escolhas.append({"texto": texto, "delta": delta})


func registrar_registro_democratico(fase: String, conceito: String, evidencia: String, impacto: String, reflexao: String) -> Dictionary:
	var registro := {
		"fase": fase,
		"conceito": conceito,
		"evidencia": evidencia,
		"impacto": impacto,
		"reflexao": reflexao
	}
	for i in range(registros_democraticos.size()):
		if str(registros_democraticos[i].get("fase", "")) == fase:
			registros_democraticos[i] = registro
			return registro
	registros_democraticos.append(registro)
	return registro


func mostrar_registro_democratico(registro: Dictionary) -> void:
	registrar_registro_democratico(
		str(registro.get("fase", "")),
		str(registro.get("conceito", "")),
		str(registro.get("evidencia", "")),
		str(registro.get("impacto", "")),
		str(registro.get("reflexao", ""))
	)
	salvar_jogo(false)
	await _mostrar_painel_registro_democratico(registro)


func mostrar_resumo_transicao_fase(_fase_anterior: int, dados: Dictionary) -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 120
	get_tree().root.add_child(overlay)

	# Reprodução de estática de rádio analógica em loop (estilo transmissão clandestina)
	var sfx_static := AudioStreamPlayer.new()
	sfx_static.stream = load("res://ASSETS/SOUNDS/radio_antena.mp3")
	sfx_static.volume_db = -8.0
	overlay.add_child(sfx_static)
	sfx_static.play()
	sfx_static.finished.connect(sfx_static.play)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1000, 600)
	panel.add_theme_stylebox_override("panel", _registro_stylebox(Color("#0d1014", 0.98), Color("#FF8C00"), 3, 10, 20, Color("#FF8C00", 0.12)))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	var title := _registro_label("CONSOLIDAÇÃO DA MISSÃO", 32, Color("#FF8C00"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	root.add_child(_registro_linha())

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 30)
	root.add_child(columns)

	# Coluna Esquerda: O que foi feito/aprendido
	var col_left := VBoxContainer.new()
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_left.add_theme_constant_override("separation", 12)
	columns.add_child(col_left)

	var left_title := _registro_label(str(dados.get("titulo_fase", "RESUMO DA FASE")).to_upper(), 20, Color("#62ff86"))
	left_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_left.add_child(left_title)

	var left_panel := PanelContainer.new()
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_stylebox_override("panel", _registro_stylebox(Color("#151820", 0.94), Color("#62ff86"), 2, 8))
	col_left.add_child(left_panel)

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_top", 14)
	left_margin.add_theme_constant_override("margin_bottom", 14)
	left_margin.add_theme_constant_override("margin_left", 16)
	left_margin.add_theme_constant_override("margin_right", 16)
	left_panel.add_child(left_margin)

	var left_text := _registro_label(str(dados.get("aprendido", "")), 18, Color("#f5ead7"))
	left_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	left_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_margin.add_child(left_text)

	# Coluna Direita: Próximo nível, objetivos e lições
	var col_right := VBoxContainer.new()
	col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_right.add_theme_constant_override("separation", 12)
	columns.add_child(col_right)

	var right_title := _registro_label(str(dados.get("titulo_proximo", "PRÓXIMO NÍVEL")).to_upper(), 20, Color("#54d6ff"))
	right_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_right.add_child(right_title)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _registro_stylebox(Color("#151820", 0.94), Color("#54d6ff"), 2, 8))
	col_right.add_child(right_panel)

	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_top", 14)
	right_margin.add_theme_constant_override("margin_bottom", 14)
	right_margin.add_theme_constant_override("margin_left", 16)
	right_margin.add_theme_constant_override("margin_right", 16)
	right_panel.add_child(right_margin)

	var right_text := _registro_label(str(dados.get("objetivos", "")), 18, Color("#f5ead7"))
	right_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_margin.add_child(right_text)

	var btn := Button.new()
	btn.text = "AVANÇAR PARA A PRÓXIMA FASE"
	btn.custom_minimum_size = Vector2(360, 54)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color("#21180f"))
	btn.add_theme_stylebox_override("normal", _registro_stylebox(Color("#FF8C00"), Color("#2b2118"), 2, 6))
	btn.add_theme_stylebox_override("hover", _registro_stylebox(Color("#ffb04f"), Color("#FF8C00"), 2, 6))
	root.add_child(btn)

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await btn.pressed
	var tw_fade := create_tween().set_parallel(true)
	tw_fade.tween_property(sfx_static, "volume_db", -80.0, 0.4)
	tw_fade.tween_property(panel, "modulate:a", 0.0, 0.3)
	await tw_fade.finished
	overlay.queue_free()



func _mostrar_painel_registro_democratico(registro: Dictionary) -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 120
	get_tree().root.add_child(overlay)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.84)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 540)
	panel.add_theme_stylebox_override("panel", _registro_stylebox(Color("#0d1014", 0.98), Color("#ffe28a"), 3, 8, 18, Color("#ffe28a", 0.16)))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var title := _registro_label("REGISTRO DEMOCRATICO ADICIONADO", 34, Color("#ffe28a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var fase := _registro_label(str(registro.get("fase", "")).to_upper(), 18, Color("#62ff86"))
	fase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(fase)

	root.add_child(_registro_linha())
	root.add_child(_registro_bloco("CONCEITO", str(registro.get("conceito", "")), Color("#54d6ff")))
	root.add_child(_registro_bloco("EVIDENCIA", str(registro.get("evidencia", "")), Color("#ffe28a")))
	root.add_child(_registro_bloco("IMPACTO", str(registro.get("impacto", "")), Color("#62ff86")))

	var reflexao := _registro_label(str(registro.get("reflexao", "")), 21, Color("#f5ead7"))
	reflexao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reflexao.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(reflexao)

	var btn := Button.new()
	btn.text = "CONTINUAR"
	btn.custom_minimum_size = Vector2(260, 54)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color("#21180f"))
	btn.add_theme_stylebox_override("normal", _registro_stylebox(Color("#ffe28a"), Color("#2b2118"), 2, 6))
	btn.add_theme_stylebox_override("hover", _registro_stylebox(Color("#fff4d6"), Color("#ffe28a"), 2, 6))
	root.add_child(btn)

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await btn.pressed
	overlay.queue_free()


func _registro_bloco(titulo: String, texto: String, cor: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _registro_stylebox(Color("#151820", 0.94), cor, 2, 6))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var lbl_titulo := _registro_label(titulo, 15, cor)
	box.add_child(lbl_titulo)
	var lbl_texto := _registro_label(texto, 20, Color("#f5ead7"))
	lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(lbl_texto)
	return panel


func _registro_label(texto: String, tamanho: int, cor: Color) -> Label:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", tamanho)
	lbl.add_theme_color_override("font_color", cor)
	return lbl


func _registro_linha() -> ColorRect:
	var linha := ColorRect.new()
	linha.color = Color("#ffe28a", 0.24)
	linha.custom_minimum_size = Vector2(0, 2)
	return linha


func _registro_stylebox(bg: Color, border: Color, border_width: int = 0, radius: int = 0, shadow_size: int = 0, shadow_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_width
	sb.border_width_top = border_width
	sb.border_width_right = border_width
	sb.border_width_bottom = border_width
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.shadow_size = shadow_size
	sb.shadow_color = shadow_color
	return sb

# --- Lógica de Salvamento ---

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func salvar_jogo(capturar_cena_atual: bool = true):
	if is_minigame_mode:
		# Não sobrescreve o save da campanha principal
		return
	# 1. Captura contexto da cena atual
	if capturar_cena_atual and get_tree() and get_tree().current_scene:
		var scene = get_tree().current_scene
		var s_name = scene.name.to_lower()
		# Evita salvar se estivermos em menus ou telas de transição
		if "title" not in s_name and "menu" not in s_name and "tela" not in s_name:
			cena_atual = scene.scene_file_path
	
	# 2. Captura estado do diálogo
	if aguardando_sequencia_fase:
		timeline_atual = ""
	elif Dialogic.current_timeline:
		timeline_atual = extrair_nome_timeline(Dialogic.current_timeline.resource_path)
	else:
		timeline_atual = ""
	
	# 3. Prepara o pacote de dados
	var save_data = {
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"reputacao": reputacao,
		"confianca": confianca,
		"fase_atual": fase_atual,
		"acertos_paginas_fase1": acertos_paginas_fase1,
		"adulterada_identificada_fase1": adulterada_identificada_fase1,
		"cena_atual": cena_atual,
		"timeline_atual": timeline_atual,
		"aguardando_sequencia_fase": aguardando_sequencia_fase,
		"decisoes_fase_1": decisoes_fase_1,
		"decisoes_fase_2": decisoes_fase_2,
		"fase2_passo": fase2_passo,
		"fase3_passo": fase3_passo,
		"fase4_passo": fase4_passo,
		"cartas_final_desbloqueadas": cartas_final_desbloqueadas,
		"aliados_final": aliados_final,
		"resultado_final": resultado_final,
		"pontuacao_final": pontuacao_final,
		"registros_democraticos": registros_democraticos,
		"log_escolhas": log_escolhas,
		"conquistas_desbloqueadas": conquistas_desbloqueadas,
		"skin_dante_selecionada": skin_dante_selecionada,
		"estilo_textbox_selecionado": estilo_textbox_selecionado
	}
	
	# 4. Salva o arquivo JSON principal
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		
		# 5. Salva o estado interno profundo do Dialogic (variáveis internas, posição do texto)
		Dialogic.Save.save("autosave")
		print("[GameState] Jogo salvo com sucesso.")


func desbloquear_conquista(id: String) -> void:
	if conquistas_desbloqueadas.has(id) and not conquistas_desbloqueadas[id]:
		conquistas_desbloqueadas[id] = true
		salvar_jogo(false)
		criar_toast_conquista(id)


func criar_toast_conquista(id: String) -> void:
	var info_conquistas = {
		"historiador": {"titulo": "Guardião da Memória", "desc": "Fase 1: Recuperou o Livro de Direitos."},
		"radio_perfeito": {"titulo": "Verdade nas Ondas", "desc": "Fase 2: Decifrou a rádio sem falhar."},
		"escola_ok": {"titulo": "Voz da Escola", "desc": "Fase 3: Libertou os alto-falantes."},
		"praca_pacifica": {"titulo": "Líder Pacífico", "desc": "Fase 4: Marchou pacificamente."},
		"fim_democratico": {"titulo": "Vontade do Povo", "desc": "Final: Garantiu o julgamento cívico."},
		"fim_qualquer": {"titulo": "Coração da Resistência", "desc": "Final: Concluiu a jornada por Usina Velha."}
	}
	
	if not info_conquistas.has(id):
		return
		
	var dados = info_conquistas[id]
	
	var toast_layer := CanvasLayer.new()
	toast_layer.layer = 150
	get_tree().root.add_child(toast_layer)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 95)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#0c0b11")
	sb.border_width_left = 4
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color("#FF8C00")
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.shadow_size = 12
	sb.shadow_color = Color("#FF8C00", 0.15)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	
	var viewport_width = toast_layer.get_viewport().get_visible_rect().size.x
	var target_x = viewport_width - panel.custom_minimum_size.x - 20
	panel.position = Vector2(target_x, -120)
	panel.modulate.a = 0.0
	toast_layer.add_child(panel)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)
	
	var lbl_icone := Label.new()
	lbl_icone.text = "🏆"
	lbl_icone.add_theme_font_size_override("font_size", 30)
	lbl_icone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl_icone)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)
	
	var FONTE_PADRAO = load("res://ASSETS/FONTES/determination.ttf")
	var FONTE_MONO = load("res://ASSETS/FONTES/dogicapixel.ttf")
	
	var lbl_desbloqueio := Label.new()
	lbl_desbloqueio.text = "CONQUISTA DESBLOQUEADA!"
	lbl_desbloqueio.add_theme_color_override("font_color", Color("#FF8C00"))
	lbl_desbloqueio.add_theme_font_size_override("font_size", 10)
	if FONTE_MONO: lbl_desbloqueio.add_theme_font_override("font", FONTE_MONO)
	vbox.add_child(lbl_desbloqueio)
	
	var lbl_titulo := Label.new()
	lbl_titulo.text = dados["titulo"]
	lbl_titulo.add_theme_color_override("font_color", Color.WHITE)
	lbl_titulo.add_theme_font_size_override("font_size", 20)
	if FONTE_PADRAO: lbl_titulo.add_theme_font_override("font", FONTE_PADRAO)
	vbox.add_child(lbl_titulo)
	
	var lbl_desc := Label.new()
	lbl_desc.text = dados["desc"]
	lbl_desc.add_theme_color_override("font_color", Color("#8f8875"))
	lbl_desc.add_theme_font_size_override("font_size", 14)
	if FONTE_PADRAO: lbl_desc.add_theme_font_override("font", FONTE_PADRAO)
	vbox.add_child(lbl_desc)
	
	var sfx := AudioStreamPlayer.new()
	sfx.stream = load("res://ASSETS/SOUNDS/FSX/BotoesClick.mp3")
	var victory_sfx = load("res://ASSETS/SOUNDS/FSX/Tensao/stinger_tensao.mp3")
	if victory_sfx:
		sfx.stream = victory_sfx
	sfx.volume_db = -5.0
	sfx.pitch_scale = 1.3
	toast_layer.add_child(sfx)
	sfx.play()
	
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "position:y", 40.0, 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(panel, "modulate:a", 1.0, 0.35)
	
	await get_tree().create_timer(4.5).timeout
	
	var tw_out = panel.create_tween().set_parallel(true)
	tw_out.tween_property(panel, "position:x", viewport_width + 50.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw_out.tween_property(panel, "modulate:a", 0.0, 0.3)
	await tw_out.finished
	
	toast_layer.queue_free()


func obter_caminho_sprite_dante(nome_sprite: String) -> String:
	if skin_dante_selecionada == "padrao":
		return "res://ASSETS/SPRITES/PERSONAGENS/PROTA/" + nome_sprite
		
	var caminho_custom = "res://ASSETS/SPRITES/PERSONAGENS/PROTA/" + skin_dante_selecionada + "/" + nome_sprite
	if FileAccess.file_exists(caminho_custom):
		return caminho_custom
		
	return "res://ASSETS/SPRITES/PERSONAGENS/PROTA/" + nome_sprite


func aplicar_estilizacao_dialogic() -> void:
	if estilo_textbox_selecionado != "":
		if Dialogic.Styles.has_active_layout_node():
			Dialogic.Styles.load_style(estilo_textbox_selecionado)
		else:
			Dialogic.current_state_info["style"] = estilo_textbox_selecionado
			Dialogic.current_state_info["base_style"] = estilo_textbox_selecionado
			ProjectSettings.set_setting("dialogic/layout/default_style", estilo_textbox_selecionado)
	
	var char_res = load("res://ASSETS/DIALOGIC/CHARACTER/PROTA.dch")
	if not char_res or not "portraits" in char_res:
		return
		
	var portraits: Dictionary = char_res.portraits
	for port_name in portraits.keys():
		var port_data = portraits[port_name]
		var img_path = ""
		if port_data.has("export_overrides") and port_data["export_overrides"].has("image"):
			img_path = port_data["export_overrides"]["image"]
		elif port_data.has("image"):
			img_path = port_data["image"]
			
		if not img_path.is_empty():
			var file_name = img_path.get_file()
			var custom_img = obter_caminho_sprite_dante(file_name)
			
			if port_data.has("export_overrides"):
				port_data["export_overrides"]["image"] = custom_img
			else:
				port_data["image"] = custom_img


func limpar_timeline_ativa() -> void:
	timeline_atual = ""


func extrair_nome_timeline(caminho: String) -> String:
	if caminho.is_empty():
		return ""
	if "://" in caminho:
		return caminho.get_file().get_basename()
	return caminho


func limpar_save_dialogic() -> void:
	if Dialogic.has_subsystem("Save"):
		Dialogic.Save.reset_slot("autosave")


func preparar_modo_minigames() -> void:
	is_minigame_mode = true
	minigame_atual_idx = 0
	confianca = 50
	pontuacao_final = {"bonus_praca": 15}
	aliados_final = {}
	cartas_final_desbloqueadas = []



func preparar_transicao_minigame(caminho_cena: String) -> void:
	await TimelineManager.parar_tudo()
	limpar_timeline_ativa()
	aguardando_sequencia_fase = false
	limpar_save_dialogic()
	cena_atual = caminho_cena
	salvar_jogo(false)
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").stop_music(1.2)


## Encerra Dialogic, marca retorno à game_scene e troca de cena (fluxo pós-minigame).
func retornar_para_game_scene_apos_minigame() -> void:
	if is_minigame_mode:
		await TimelineManager.parar_tudo()
		limpar_timeline_ativa()
		limpar_save_dialogic()
		Dialogic.paused = false
		minigame_atual_idx += 1
		if has_node("/root/MusicManager"):
			get_node("/root/MusicManager").play_default_music()
		await FadeManager.carregar_cena("res://ASSETS/CENAS/minigames_mode_controller.tscn")
		return

	await TimelineManager.parar_tudo()
	limpar_timeline_ativa()
	limpar_save_dialogic()
	aguardando_sequencia_fase = true
	Dialogic.paused = false
	cena_atual = "res://ASSETS/CENAS/game_scene.tscn"
	salvar_jogo(false)
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").play_default_music()
	await FadeManager.carregar_cena(cena_atual)
	await get_tree().process_frame
	_garantir_sequencia_fase_na_cena_atual()

const CENA_MINIGAME_PAGINAS: String = "res://ASSETS/CENAS/minigame_paginas.tscn"


## Atalho secreto: estado mínimo da fase 1 + minigame de páginas (pula intro e timelines).
func atalho_ir_minigame_paginas() -> void:
	ChoiceTimer.forcar_parar()
	fase_atual = 1
	fase2_passo = "inicio"
	fase3_passo = "inicio"
	acertos_paginas_fase1 = 0
	adulterada_identificada_fase1 = false
	await preparar_transicao_minigame(CENA_MINIGAME_PAGINAS)
	await FadeManager.carregar_cena(CENA_MINIGAME_PAGINAS)


func _garantir_sequencia_fase_na_cena_atual() -> void:
	var cena: Node = get_tree().current_scene
	if cena and cena.has_method("_tentar_iniciar_sequencia"):
		cena.call_deferred("_tentar_iniciar_sequencia")


# --- Lógica de Carregamento ---

func continuar_jogo():
	if not has_save():
		push_error("[GameState] Tentativa de carregar save inexistente.")
		return
		
	# 1. Carrega os dados básicos do JSON para a memória
	_carregar_dados_json()
	
	# 2. Inicia a transição visual
	# Usamos o FadeManager para trocar de cena com tela de loading/sabia que
	await FadeManager.carregar_cena(cena_atual)
	
	# 3. A cena agora mudou. Esperamos um pouco para o carregamento do Dialogic
	# O Dialogic precisa que o layout da nova cena esteja pronto
	await get_tree().process_frame
	
	if aguardando_sequencia_fase:
		timeline_atual = ""
		print("[GameState] Retomando sequência de fase após minigame...")
		_garantir_sequencia_fase_na_cena_atual()
	elif timeline_atual != "":
		print("[GameState] Retomando estado preciso do Dialogic...")
		# Carregamos o estado completo. O Dialogic 2 cuida de reabrir a timeline 
		# no índice exato (current_event_idx) que foi salvo no state.txt.
		Dialogic.Save.load("autosave")

func _carregar_dados_json():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(content) == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				reputacao = data.get("reputacao", 0)
				confianca = data.get("confianca", 0)
				fase_atual = data.get("fase_atual", 1)
				acertos_paginas_fase1 = data.get("acertos_paginas_fase1", 0)
				adulterada_identificada_fase1 = data.get("adulterada_identificada_fase1", false)
				decisoes_fase_1 = data.get("decisoes_fase_1", decisoes_fase_1)
				decisoes_fase_2 = data.get("decisoes_fase_2", decisoes_fase_2)
				fase2_passo = data.get("fase2_passo", "inicio")
				fase3_passo = data.get("fase3_passo", "inicio")
				fase4_passo = data.get("fase4_passo", "praca")
				cartas_final_desbloqueadas.clear()
				for carta_final in data.get("cartas_final_desbloqueadas", []):
					cartas_final_desbloqueadas.append(str(carta_final))
				aliados_final = data.get("aliados_final", {})
				resultado_final = data.get("resultado_final", "")
				pontuacao_final = data.get("pontuacao_final", {})
				registros_democraticos.clear()
				for registro in data.get("registros_democraticos", []):
					if typeof(registro) == TYPE_DICTIONARY:
						registros_democraticos.append(registro)
				log_escolhas = data.get("log_escolhas", [])
				cena_atual = data.get("cena_atual", "res://ASSETS/CENAS/game_scene.tscn")
				timeline_atual = data.get("timeline_atual", "")
				aguardando_sequencia_fase = data.get("aguardando_sequencia_fase", false)
				
				# Carregar conquistas e skins
				var saved_conquistas = data.get("conquistas_desbloqueadas", {})
				for key in saved_conquistas.keys():
					if conquistas_desbloqueadas.has(key):
						conquistas_desbloqueadas[key] = saved_conquistas[key]
				
				skin_dante_selecionada = data.get("skin_dante_selecionada", "padrao")
				estilo_textbox_selecionado = data.get("estilo_textbox_selecionado", "res://ASSETS/DIALOGIC/STYLES/Base_testebox.tres")
				
				aplicar_estilizacao_dialogic()
				print("[GameState] Dados JSON carregados na memória.")

func reset_save():
	# Limpa tudo
	reputacao = 0
	confianca = 0
	fase_atual = 1
	acertos_paginas_fase1 = 0
	adulterada_identificada_fase1 = false
	decisoes_fase_1 = {"falou_com_velho": false, "ajudou_vila": false}
	decisoes_fase_2 = {}
	fase2_passo = "inicio"
	fase3_passo = "inicio"
	fase4_passo = "praca"
	cartas_final_desbloqueadas = []
	aliados_final = {}
	resultado_final = ""
	pontuacao_final = {}
	registros_democraticos = []
	cena_atual = "res://ASSETS/CENAS/game_scene.tscn"
	timeline_atual = ""
	aguardando_sequencia_fase = false
	log_escolhas = []
	

	# Encerra processos ativos
	await TimelineManager.parar_tudo()
	
	# Salva o estado "limpo" para sobrescrever o anterior
	salvar_jogo()
	print("[GameState] Save resetado com sucesso.")


func _ready() -> void:
	carregar_configuracoes()


func carregar_configuracoes() -> void:
	if FileAccess.file_exists(SETTINGS_FILE):
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(content) == OK:
				var data = json.get_data()
				if typeof(data) == TYPE_DICTIONARY:
					vol_musica = data.get("vol_musica", vol_musica)
					vol_sfx = data.get("vol_sfx", vol_sfx)
					vel_dialogos = data.get("vel_dialogos", vel_dialogos)
					tela_cheia = data.get("tela_cheia", tela_cheia)
					resolucao = data.get("resolucao", resolucao)
					auto_avanco = data.get("auto_avanco", auto_avanco)
					auto_avanco_delay = data.get("auto_avanco_delay", auto_avanco_delay)
					pular_lidos = data.get("pular_lidos", pular_lidos)
					tamanho_fonte = data.get("tamanho_fonte", tamanho_fonte)
	aplicar_configuracoes_globais()


func salvar_configuracoes() -> void:
	var save_data = {
		"vol_musica": vol_musica,
		"vol_sfx": vol_sfx,
		"vel_dialogos": vel_dialogos,
		"tela_cheia": tela_cheia,
		"resolucao": resolucao,
		"auto_avanco": auto_avanco,
		"auto_avanco_delay": auto_avanco_delay,
		"pular_lidos": pular_lidos,
		"tamanho_fonte": tamanho_fonte
	}
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("[GameState] Configurações salvas com sucesso.")


func aplicar_configuracoes_globais() -> void:
	aplicar_volume("Musica", vol_musica)
	aplicar_volume("SFX", vol_sfx)
	
	if typeof(TimelineManager) != TYPE_NIL:
		TimelineManager.set_velocidade_dialogos(vel_dialogos)
		TimelineManager.aplicar_config_auto_advance_global()
	
	if Dialogic.has_subsystem("Inputs"):
		var inputs = Dialogic.Inputs
		if inputs.auto_skip:
			inputs.auto_skip.disable_on_unread_text = (pular_lidos == 1)
			
	if Dialogic.has_subsystem("Styles") and Dialogic.Styles.has_active_layout_node():
		var layout = Dialogic.Styles.get_layout_node()
		if layout:
			_atualizar_estilos_recursivo(layout)


func _atualizar_estilos_recursivo(node: Node) -> void:
	if node.has_method("_apply_text_settings"):
		node._apply_text_settings()
	for child in node.get_children():
		_atualizar_estilos_recursivo(child)


func aplicar_volume(bus_name: String, value: float) -> void:
	var linear_vol = value / 100.0
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	if linear_vol == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_vol))
