extends Control

# Tela de Final de Demonstração

func _ready():
	# Escurecer o fundo gradualmente
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 2.0)
	
	_criar_interface()

func _criar_interface():
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)
	
	var titulo = Label.new()
	titulo.text = "FIM DA DEMONSTRAÇÃO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)
	
	var desc = Label.new()
	desc.text = "Obrigado por jogar a versão base de Operação Democrática.\nSuas decisões foram salvas."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	var btn_voltar = Button.new()
	btn_voltar.text = "VOLTAR AO MENU PRINCIPAL"
	btn_voltar.custom_minimum_size = Vector2(300, 60)
	btn_voltar.pressed.connect(func(): 
		get_tree().change_scene_to_file("res://title_screen.tscn")
	)
	vbox.add_child(btn_voltar)
