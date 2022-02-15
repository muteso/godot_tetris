extends Control

signal new_game

onready var animation := $AnimationPlayer

onready var info_bar := $Layer1/InfoBar
onready var score_table := $Layer1/HighScoreTable
onready var first := $Layer1/HighScoreTable/"1st"
onready var second := $Layer1/HighScoreTable/"2nd"
onready var third := $Layer1/HighScoreTable/"3rd"

onready var play_but := $Layer1/StartBox/Play
onready var shadow_but := $Layer1/StartBox/VBoxContainer/ShowShadow/CheckBox
onready var grid_but := $Layer1/StartBox/VBoxContainer/ShowGrid/CheckBox
onready var music_but := $Layer1/StartBox/VBoxContainer/PlayMusic/CheckBox
onready var sounds_but := $Layer1/StartBox/VBoxContainer/PlaySounds/CheckBox


func _ready() -> void:
	animation.play("start_box_appear")

func sync_settings() -> void:
	shadow_but.pressed = Settings.SHOW_SHADOW
	grid_but.pressed = Settings.SHOW_DISPLAY_GRID
	music_but.pressed = Settings.PLAY_MUSIC
	sounds_but.pressed = Settings.PLAY_SOUNDS
	first.text = "1-st place - " + str(Settings.HIGH_SCORE_TABLE["1st"])
	second.text = "2-nd place - " + str(Settings.HIGH_SCORE_TABLE["2nd"])
	third.text = "3-rd place - " + str(Settings.HIGH_SCORE_TABLE["3rd"])


func _on_Play_button_up() -> void:
	emit_signal("new_game")
	animation.play("start_box_disappear")


func _on_SHOW_SHADOW_toggled(button_pressed: bool) -> void:
	Settings.SHOW_SHADOW = button_pressed
	Settings.save_settings()


func _on_SHOW_GRID_toggled(button_pressed: bool) -> void:
	Settings.SHOW_DISPLAY_GRID = button_pressed
	Settings.save_settings()


func _on_PLAY_MUSIC_toggled(button_pressed: bool) -> void:
	Settings.PLAY_MUSIC = button_pressed
	Settings.save_settings()


func _on_PLAY_SOUNDS_toggled(button_pressed: bool):
	Settings.PLAY_SOUNDS = button_pressed
	Settings.save_settings()
