extends ColorRect

var can_pause := false


func _input(event: InputEvent) -> void:
	if event.is_action("ui_pause") and event.is_pressed() and can_pause:
		visible = !visible
		get_tree().paused = visible


#func _process(_delta: float) -> void:
#	if Input.is_action_just_pressed("ui_pause") and can_pause:
#		visible = !visible
#		get_tree().paused = visible
