extends Node

const block := preload("res://assets/images/block.png")
const nogrid := preload("res://assets/images/nogrid_texture.png")
const grid := preload("res://assets/images/grid_texture.png")
const beep_snd := preload("res://assets/sounds/beep.wav")
const cmpl_row_snd := preload("res://assets/sounds/cmpl_row.mp3")
const drop_snd := preload("res://assets/sounds/drop.wav")

const BLOCK := 20
# stores blocks edge size in pixels

export(int) var gap_duration = 2
# stores duration between horizontal movement steps in frames

var time: Timer
var tetris: TetrisDisplay

var velocity: float
# stores fall velocity in secs
var latency: float 
# stores letency after left or right button being pressed in secs
var latency_treshold: float
# stores letency treshold after which shape continue to move

var lvl_up := 0
# stores lines for level-up
var score := 0
var total_lines := 0
var level := 0 setget set_level

func set_level(val: int) -> void:
	level = val
	velocity = pow((0.8 - ((level - 1) * 0.007)), (level - 1))
	latency_treshold = velocity / 3

var completing_processing := false setget set_completing_processing
# switcher for a pause to play "completing" vanish animation of rows

func set_completing_processing(val: bool) -> void:
	completing_processing = val
	if completing_processing:
		time.stop()
	else:
		time.start(velocity)

onready var display := $GUI/Layer1/Display
onready var display_next := $GUI/Layer1/InfoBar/NextShape

onready var beep_play := $Sounds/Beep
onready var cmpl_row_play := $Sounds/CompletedRow
onready var drop_play := $Sounds/Drop


func _ready() -> void:
	randomize()


# input control ------------------------------------

func _physics_process(delta: float) -> void:
	if !tetris or !time or completing_processing:
		return
	
	var left_just_pressed := Input.is_action_just_pressed("ui_left")
	var right_just_pressed := Input.is_action_just_pressed("ui_right")
	var left_just_released := Input.is_action_just_released("ui_left")
	var right_just_released := Input.is_action_just_released("ui_right")
	var left_pressed := Input.is_action_pressed("ui_left")
	var right_pressed := Input.is_action_pressed("ui_right")
	
	if left_just_pressed or right_just_pressed:
		latency = 0
		beep_play.play(0)
	if left_just_released or right_just_released :
		latency = 0
	if left_pressed or right_pressed:
		var dir := Input.get_axis("ui_left", "ui_right")
		var gap_ended: int = get_tree().get_frame() % gap_duration == 0
		
		if latency == 0 or (latency >= latency_treshold and gap_ended):
			tetris.move_horizontally(dir)
			draw_display()
		latency += delta
	
	if Input.is_action_just_pressed("ui_up"):
		beep_play.play(0)
		tetris.rotate()
		draw_display()
	
	if Input.is_action_just_pressed("ui_down"):
		beep_play.play(0)
		_update_display_on_timeout()
		time.start(velocity * 0.05)
	if Input.is_action_just_released("ui_down"):
		time.start(velocity)
	
	if Input.is_action_just_pressed("ui_select"):
		drop_play.play(0.5)
		tetris.drop()
		time.start(velocity)
		_update_display_on_timeout()
	
	if Input.is_action_just_pressed("ui_cancel"):
		restart_game()


# start-end game functions -----------------------------

func _on_GUI_new_game() -> void:
	$GUI/Layer2/PauseBox.can_pause = true # activate pause "key"
	
	if Settings.SHOW_DISPLAY_GRID: # activate grid appearence on display
		display.texture = grid
		display.expand = true
		display.stretch_mode = 2
	
	$Sounds/MainTheme.playing = Settings.PLAY_MUSIC # activate music
	
	if Settings.PLAY_SOUNDS: # activate sounds
		beep_play.stream = beep_snd
		cmpl_row_play.stream = cmpl_row_snd
		drop_play.stream = drop_snd
	else:
		beep_play.stream = null
		cmpl_row_play.stream = null
		drop_play.stream = null
	
	self.level += 1 # trigger level-value setter-function
	
	time = Timer.new() # create necessary timer-object
	add_child(time)
	time.connect("timeout", self, "_update_display_on_timeout")
	
	time.start(velocity)
	
	tetris = TetrisDisplay.new() # create necessary custom tetris-object
	add_child(tetris)
	tetris.connect("shape_spawned", self, "_draw_next_shape")
	tetris.connect("shape_landed", self, "_landing_process")
	
	tetris.spawn_shape()
	draw_display() 


func restart_game() -> void:
	Settings.set_high_score(score)
	Settings.save_settings()
	get_tree().reload_current_scene()


# engine processing functions ----------------------

func _update_display_on_timeout() -> void:
	tetris.fall()
	if not completing_processing:
		draw_display()


func _landing_process(draw_data: Dictionary) -> void:
	var completed_rows: int = draw_data["completed_rows"].size()
	if completed_rows:
		cmpl_row_play.play(0)
		
		self.completing_processing = true
		# "interrupt" _update_display_on_timeout()-function via setter-
		# function right before draw_display()-function call 
		
		draw_display(draw_data["matrix"], false)
		# draw displays snapshot BEFORE the actual rows "completing"
		yield(draw_vanish_anim(draw_data["completed_rows"]), "completed")
		# draw rows "completing"-animation
		
		self.completing_processing = false
		# resume normal drawing behavior via setter-function
		
		cmpl_row_play.stop()
		
		match completed_rows:
			1: score += 100
			2: score += 300
			3: score += 700
			4: score += 1500
		$GUI/Layer1/InfoBar/Score.text = "Score:\n" + str(score)
		
		total_lines += completed_rows
		$GUI/Layer1/InfoBar/Lines.text = "Lines: " + str(total_lines)
		
		lvl_up += completed_rows
		if lvl_up >= 10:
			lvl_up -= 10
			self.level += 1
		$GUI/Layer1/InfoBar/Level.text = "Level: " + str(level)
	
	if tetris.is_game_over():
		restart_game()
	
	time.start(velocity) 
	# prevents endless accelerated fall when holding "ui_down"-action
	tetris.spawn_shape()
	draw_display()


# drawing functions --------------------------------

func draw_block(group: String, orig_x: float, orig_y: float,
		x: float, y: float, color: Color) -> void:
	var sprite := Sprite.new()
	sprite.add_to_group(group)
	sprite.offset = Vector2(10, 10)
	sprite.global_position = Vector2(orig_x + x * BLOCK, orig_y + y * BLOCK)
	sprite.texture = block
	sprite.modulate = color
	$GUI/Layer1.add_child(sprite)


func draw_display(matrix: Array=tetris.get_matrix_to_draw(), 
		draw_shadow: bool=true) -> void:
	get_tree().call_group("blocks", "queue_free")
	for y_ind in matrix.size():
		for x_ind in matrix[y_ind].size():
			if matrix[y_ind][x_ind]["condition"] != 0:
				var x_origin: float = display.rect_position.x
				var y_origin: float = display.rect_position.y
				var color: Color = matrix[y_ind][x_ind]["color"]
				draw_block("blocks", x_origin, y_origin, x_ind, y_ind, color)
	if Settings.SHOW_SHADOW and draw_shadow:
		var shape: Array = tetris.falling_shape[tetris.shape_rotation]
		for blk in shape:
			var x: float = tetris.shape_offset.x + blk.x
			var y: float = tetris.get_offset_y_to_drop() + blk.y
			var x_origin: float = display.rect_position.x
			var y_origin: float = display.rect_position.y
			var color := Color(1, 1, 1, 0.3)
			if y_origin <= y_origin + y * BLOCK: 
				# draw blocks only inside GUI-display
				draw_block("blocks", x_origin, y_origin, x, y, color)


func _draw_next_shape(next_shape: Array, 
		center: Vector2, color: Color) -> void:
	get_tree().call_group("next_shape", "queue_free")
	for blk in next_shape:
		blk -= (center + Vector2(0.5, 0.5))
		var x_origin: float = (display_next.rect_global_position.x + 
				display_next.rect_size.x / 2)
		var y_origin: float = (display_next.rect_global_position.y + 
				display_next.rect_size.y / 2)
		draw_block("next_shape", x_origin, y_origin, blk.x, blk.y, color)


func draw_vanish_anim(completed_rows: Array) -> void:
	yield(get_tree(), "idle_frame") # needed for "yielding" this function
	var blocks := get_tree().get_nodes_in_group("blocks")
	for local_x in tetris.WIDTH:
		for local_y in completed_rows:
			var x: float = display.rect_position.x + local_x * BLOCK
			var y: float = display.rect_position.y + local_y * BLOCK
			var vanish_position := Vector2(x, y)
			for blk in blocks:
				if blk.position == vanish_position:
					blk.visible = false
		yield(get_tree().create_timer(0.1), "timeout")

