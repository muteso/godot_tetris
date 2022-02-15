extends Node

var SHOW_SHADOW := true
var SHOW_DISPLAY_GRID := false
var PLAY_MUSIC := false
var PLAY_SOUNDS := false

var HIGH_SCORE_TABLE := {"1st": 0, "2nd": 0, "3rd": 0}


func _ready() -> void: 
	var file := File.new()
	if not file.file_exists("user://save"):
		var data := {
			"SHOW_SHADOW": SHOW_SHADOW,
			"SHOW_DISPLAY_GRID": SHOW_DISPLAY_GRID,
			"PLAY_MUSIC": PLAY_MUSIC,
			"PLAY_SOUNDS": PLAY_SOUNDS,
			"HIGH_SCORE_TABLE": HIGH_SCORE_TABLE,
		}
		file.open("user://save", File.WRITE)
		file.store_line(var2str(data))
		file.close()
	else: # actual load_settings-function
		file.open("user://save", File.READ)
		var data: Dictionary = str2var(file.get_as_text())
		file.close()
		SHOW_SHADOW = data["SHOW_SHADOW"]
		SHOW_DISPLAY_GRID = data["SHOW_DISPLAY_GRID"]
		PLAY_MUSIC = data["PLAY_MUSIC"]
		PLAY_SOUNDS = data["PLAY_SOUNDS"]
		HIGH_SCORE_TABLE = data["HIGH_SCORE_TABLE"]


func save_settings() -> void:
	# this function is used in Main-node when starting a game and in
	# GUI-node when toggling a settings buttons
	var data := {
		"SHOW_SHADOW": SHOW_SHADOW,
		"SHOW_DISPLAY_GRID": SHOW_DISPLAY_GRID,
		"PLAY_MUSIC": PLAY_MUSIC,
		"PLAY_SOUNDS": PLAY_SOUNDS,
		"HIGH_SCORE_TABLE": HIGH_SCORE_TABLE,
	}
	var file := File.new()
	file.open("user://save", File.WRITE)
	file.store_line(var2str(data))
	file.close()


func set_high_score(score: int) -> void:
	var buffer: int 
	# stores previous value of examined position for "shifting" under-positions
	if score > HIGH_SCORE_TABLE["1st"]:
		buffer = HIGH_SCORE_TABLE["1st"]
		HIGH_SCORE_TABLE["1st"] = score
		score = buffer
	if score > HIGH_SCORE_TABLE["2nd"]:
		buffer = HIGH_SCORE_TABLE["2nd"]
		HIGH_SCORE_TABLE["2nd"] = score
		score = buffer
	if score > HIGH_SCORE_TABLE["3rd"]:
		HIGH_SCORE_TABLE["3rd"] = score
