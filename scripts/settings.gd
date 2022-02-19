extends Node

var show_shadow := true
var show_display_grid := false
var play_music := false
var play_sounds := false

var high_score_table := {"1st": 0, "2nd": 0, "3rd": 0}


func _ready() -> void: 
	var file := File.new()
	if not file.file_exists("user://save"):
		var data := {
			"show_shadow": show_shadow,
			"show_display_grid": show_display_grid,
			"play_music": play_music,
			"play_sounds": play_sounds,
			"high_score_table": high_score_table,
		}
		file.open("user://save", File.WRITE)
		file.store_line(var2str(data))
		file.close()
	else: # actual load_settings-function
		file.open("user://save", File.READ)
		var data: Dictionary = str2var(file.get_as_text())
		file.close()
		show_shadow = data["show_shadow"]
		show_display_grid = data["show_display_grid"]
		play_music = data["play_music"]
		play_sounds = data["play_sounds"]
		high_score_table = data["high_score_table"]


func save_settings() -> void:
	# this function is used in Main-node when starting a game and in
	# GUI-node when toggling a settings buttons
	var data := {
		"show_shadow": show_shadow,
		"show_display_grid": show_display_grid,
		"play_music": play_music,
		"play_sounds": play_sounds,
		"high_score_table": high_score_table,
	}
	var file := File.new()
	file.open("user://save", File.WRITE)
	file.store_line(var2str(data))
	file.close()


func set_high_score(score: int) -> void:
	var buffer: int 
	# stores previous value of examined position for "shifting" under-positions
	if score > high_score_table["1st"]:
		buffer = high_score_table["1st"]
		high_score_table["1st"] = score
		score = buffer
	if score > high_score_table["2nd"]:
		buffer = high_score_table["2nd"]
		high_score_table["2nd"] = score
		score = buffer
	if score > high_score_table["3rd"]:
		high_score_table["3rd"] = score
