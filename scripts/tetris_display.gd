class_name TetrisDisplay, "res://assets/images/block.png"
extends Node 

signal shape_spawned
signal shape_landed

const WIDTH := 10
const TOP := 2
const HEIGHT := 20
const BOTTOM := 1

# next 3 constants stores base information about all shapes in according  
# order [0] - I, [1] - J, [2] - L, [3] - O, [4] - S, [5] - Z, [6] - T
const SHAPES := [
	[[Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1)], [Vector2(2, 0), Vector2(2, 1), Vector2(2, 2), Vector2(2, 3)], [Vector2(0, 2), Vector2(1, 2), Vector2(2, 2), Vector2(3, 2)], [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(1, 3)]],
	[[Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)], [Vector2(1, 0), Vector2(2, 0), Vector2(1, 1), Vector2(1, 2)], [Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(2, 2)], [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(0, 2)]],
	[[Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(2, 0)], [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(2, 2)], [Vector2(0, 1), Vector2(0, 2), Vector2(1, 1), Vector2(2, 1)], [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(1, 2)]],
	[[Vector2(1, 0), Vector2(1, 1), Vector2(2, 0), Vector2(2, 1)], [Vector2(1, 0), Vector2(1, 1), Vector2(2, 0), Vector2(2, 1)], [Vector2(1, 0), Vector2(1, 1), Vector2(2, 0), Vector2(2, 1)], [Vector2(1, 0), Vector2(1, 1), Vector2(2, 0), Vector2(2, 1)]],
	[[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(2, 0)], [Vector2(1, 0), Vector2(1, 1), Vector2(2, 1), Vector2(2, 2)], [Vector2(1, 1), Vector2(2, 1), Vector2(1, 2), Vector2(0, 2)], [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 2)]],
	[[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)], [Vector2(1, 1), Vector2(1, 2), Vector2(2, 0), Vector2(2, 1)], [Vector2(0, 1), Vector2(1, 1), Vector2(1, 2), Vector2(2, 2)], [Vector2(0, 1), Vector2(0, 2), Vector2(1, 1), Vector2(1, 0)]],
	[[Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)], [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(2, 1)], [Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(1, 2)], [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(0, 1)]],
]
# stores all shapes with all their rotation variants
# 1-st demension - shapes itself
# 2-nd demension - rotated shapes ([0] - "flat", left -> right = clockwise)
# 3-rd demension - blocks of shapes
const COLORS := [
	Color(0.16, 0.96, 0.85, 1),
	Color(0.24, 0.76, 1, 1),
	Color(1, 0.58, 0.13, 1),
	Color(0.97, 1, 0.17, 1),
	Color(0, 1, 0.2, 1),
	Color(0.96, 0.21, 0.21, 1),
	Color(0.63, 0.19, 1, 1),
]
# stores colors for each shape
const CENTERS := [
	Vector2(1.5, 1),
	Vector2(1, 0.5),
	Vector2(1, 0.5),
	Vector2(1.5, 0.5),
	Vector2(1, 0.5),
	Vector2(1, 0.5),
	Vector2(1, 0.5),
]
# stores centers of each "flat" (with index 0) shape

var next_shape := randi() % 7
# stores index of the next shape to spawn 
var falling_shape: Array
# stores current falling shape (with all rotation variants)
var shape_rotation: int
# stores index of rotation variant of falling_shape
var shape_offset: Vector2
# stores falling_shape origin offset relatively display_matrix origin
var shape_color: Color
# stores color of the falling_shape

var display_matrix: Array
# represent tetris display with matrix, where each cell have his own condition
# 0 - empty cell
# 1 - falling block
# 2 - landed block
# 3 - bottom cell
var color_matrix: Array
# copy of display_matrix, where each block has color instead of condition 

# matrix functions ---------------------------------

func _init() -> void:
	for i in TOP + HEIGHT:
		display_matrix.append([])
		color_matrix.append([])
		for j in WIDTH:
			display_matrix[i].append(0)
			color_matrix[i].append(0)
	display_matrix.append([3, 3, 3, 3, 3, 3, 3, 3, 3, 3])
	color_matrix.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])


func store_shape_in_matrixes(condition: int, color=0) -> void:
	for block in falling_shape[shape_rotation]:
		var x: int = block.x + shape_offset.x
		var y: int = block.y + shape_offset.y
		display_matrix[y][x] = condition
		color_matrix[y][x] = color


func get_matrix_to_draw() -> Array:
	var buffer := []
	for i in range(TOP, TOP + HEIGHT):
		buffer.append([])
		for j in WIDTH:
			buffer[i - TOP].append({
				"condition": display_matrix[i][j],
				"color": color_matrix[i][j]})
	return buffer


# shape_offset functions ---------------------------

func is_colliding_x(dir: int) -> bool:
	for block in falling_shape[shape_rotation]:
		var x: int = block.x + shape_offset.x + dir
		var y: int = block.y + shape_offset.y
		if x >= WIDTH or x < 0 or display_matrix[y][x] > 1:
			return true
	return false


func get_offset_y_to_drop() -> int:
	var x: int = shape_offset.x
	var y: int = shape_offset.y
	while true:
		for block in falling_shape[shape_rotation]:
			var next_pos: int = display_matrix[block.y + y + 1][block.x + x]
			if next_pos > 1:
				return y - TOP
		y += 1
	return y - TOP # needed only to avoid parser exception


# base game functions ------------------------------

func spawn_shape() -> void:
	falling_shape = SHAPES[next_shape]
	shape_color = COLORS[next_shape]
	shape_rotation = 0 
	next_shape = randi() % 7
	shape_offset = Vector2(rand_range(2, 5) as int, 0) 
	# roughtly a middle part of display
	store_shape_in_matrixes(1, shape_color)
	emit_signal("shape_spawned", SHAPES[next_shape][0], 
			CENTERS[next_shape], COLORS[next_shape])
	# run _draw_next_shape() in Main-node


func row_completing() -> Dictionary:
	var draw_data := { 
		"matrix": get_matrix_to_draw(), 
		# snapshot of matrix BEFORE "completing"
		"completed_rows": [] 
		# indexes of completed rows
	}
	var ind := -BOTTOM # reversed "cursor" index
	var end := -(BOTTOM + HEIGHT) # reversed max index (height)
	var ind_offset := 0 
	# stores offset of ind-variable after each row completing - its   
	# NECESSARY for proper completed rows indexes calculation (chunks 
	# of "above" blocks IMMEDIATE "shift" down BEFORE each of completed
	# rows indexes were calculated)
	
	while ind >= end: 
		# iterates in reverse order along y-axis thought whole display_matrix
		ind -= 1
		
		if display_matrix[ind].max() == 0: # check row is empty
			return draw_data
		if display_matrix[ind].min() == 2: # check row is completed
			var completer_row_ind := ind - ind_offset + HEIGHT + BOTTOM
			draw_data["completed_rows"].append(completer_row_ind)
			
			ind_offset += 1
			
			for row_ind in display_matrix.size():
				# iterates in reverse order along y-axis thought whole 
				# display_matrix started from row above completed row
				row_ind = -(row_ind + 1) + ind # reverse "above" row index 
				if display_matrix[row_ind].max() == 0: # check row is empty
					break
				if 2 in display_matrix[row_ind]: # check row is not empty
					display_matrix[row_ind + 1] = display_matrix[row_ind]
					color_matrix[row_ind + 1] = color_matrix[row_ind]
					display_matrix[row_ind] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
					color_matrix[row_ind] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
			
			ind += 1 
			# shift "cursor" back to check just fallen bottom row
	return draw_data # needed only to avoid parser exception


func is_game_over() -> bool:
	for ind in TOP:
		if 2 in display_matrix[ind]:
			return true
	return false


# shape movement functions -------------------------

func fall() -> void:
	for block in falling_shape[shape_rotation]:
		var x: int = block.x + shape_offset.x
		var y: int  = block.y + shape_offset.y + 1
		var next_pos: int = display_matrix[y][x]
		if next_pos > 1:
			store_shape_in_matrixes(2, shape_color)
			emit_signal("shape_landed", row_completing())
			# run _landing_process() in Main-node 
			return
	store_shape_in_matrixes(0)
	shape_offset.y += 1
	store_shape_in_matrixes(1, shape_color)


func rotate() -> void:
	store_shape_in_matrixes(0)
	shape_rotation = (shape_rotation + 1) % 4
	if is_colliding_x(0):
		shape_rotation = (shape_rotation - 1) % 4
	store_shape_in_matrixes(1, shape_color)


func move_horizontally(dir: int) -> void:
	if !is_colliding_x(dir):
		store_shape_in_matrixes(0)
		shape_offset.x += dir
		store_shape_in_matrixes(1, shape_color)


func drop() -> void:
	store_shape_in_matrixes(0)
	shape_offset.y = get_offset_y_to_drop() + TOP
	store_shape_in_matrixes(1, shape_color)


# for debug ----------------------------------------

func get_matrix_in_text(flag: String="") -> String:
	var text := ""
	for i in range(TOP, TOP + HEIGHT):
		if flag == "console":
			print(display_matrix[i])
		text += str(display_matrix[i]) + '\n'
	return text


func show_all_shapes_in_text() -> void:
	var all_shapes := []
	for shape in SHAPES:
		for rotation_var in shape:
			var matrix := [
				[0, 0, 0, 0],
				[0, 0, 0, 0],
				[0, 0, 0, 0],
				[0, 0, 0, 0]
			]
			for block in rotation_var:
				matrix[block.y][block.x] = 1
			all_shapes.append(matrix)
	var cursor := 0
	for j in 7:
		print("---shape " + str(j + 1) + "---")
		for i in 4:
			print(str(all_shapes[cursor][i]) + " "
			+ str(all_shapes[cursor + 1][i]) + " "
			+ str(all_shapes[cursor + 2][i]) + " "
			+ str(all_shapes[cursor + 3][i]))
		cursor += 4


# deprecated ---------------------------------------

#func clamp_offset_x() -> void:
#	for block in falling_shape[shape_rotation]:
#		var x = block.x + shape_offset.x
#		if x >= WIDTH:
#			shape_offset.x += WIDTH - 1 - x
#		elif x < 0:
#			shape_offset.x += -x

#func is_row_completed() -> void:
#	for row_ind in display_matrix.size():
#		for rev_row_ind in display_matrix.slice(0, row_ind - 1).size():
#			rev_row_ind = -(rev_row_ind + 1) - (display_matrix.size() - row_ind)
#			# magic - reverse order of indexes regarding index of completed row
