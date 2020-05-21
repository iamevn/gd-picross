tool
extends CenterContainer

const enums = preload("enum.gd")
const util = preload("util.gd")
const checks = preload("res://Puzzle/checks.gd")
const CellState = enums.CellState
const Sides = enums.Sides


const debug_puzzles = [
	{top = "5|5|1,1|1,1|3", side = "5|2,1|5|2|2"},
	{
		top = "0|4|6|8|9|10|10|10|2,7|2,5|3,3|2,3|2,3|4|0",
		side = "0|0|3,3|5,5|8,1,2|7,1|8,2|9,3|11|9|7|5|3|1|0",
	},
	{top = "1|2|3|4|5", side = "1,1|4|3|3|2"},
]

export var raw_clues_top = debug_puzzles[2].top setget top_clue_set
export var raw_clues_side = debug_puzzles[2].side setget side_clue_set

var clues = {
	top = [[1]],
	side = [[1]],
}

const BORDER_EDGE_WIDTH = 0
const INNER_EDGE_WIDTH = 0
const HELPER_EDGE_WIDTH = 1
const HELPER_GRID_SIZE = 5

export var CORRECT_HINT_COLOR = Color(0.078431, 0.454902, 0.054902) # 14740E


signal grid_reset(grid_container)

# handle inspector changing clues mid-run
func top_clue_set(new_raw_clues):
	if not get_node("."):
		return
	if new_raw_clues == raw_clues_top:
		return
	if clue_set(Sides.TOP, new_raw_clues):
		reset_grid()


func side_clue_set(new_raw_clues):
	if not get_node("."):
		return
	if new_raw_clues == raw_clues_side:
		return
	if clue_set(Sides.SIDE, new_raw_clues):
	  reset_grid()


func clue_set(side, new_raw_clues):
	var new_clues = null
	match side:
		Sides.TOP:
			clues.top = parse_clue(new_raw_clues)
			raw_clues_top = new_raw_clues
			new_clues = clues.top
		Sides.SIDE:
			clues.side = parse_clue(new_raw_clues)
			raw_clues_side = new_raw_clues
			new_clues = clues.side
		_:
			print("unknown side: %s" % side)
			return false
	return reset_hints(side, new_clues)


func reset_hints(side, new_clues):
	var hints_container = null
	match side:
		Sides.TOP:
			hints_container = $VBoxContainer/VHintsMargin/VHints
		Sides.SIDE:
			hints_container = $VBoxContainer/HBoxContainer/HHintsMargin/HHints
		_:
			print("unknown side: ", side)
			return false
	assert(hints_container)
	# clear hints container, add hints within subcontainers
	for child in hints_container.get_children():
		hints_container.remove_child(child)
		child.queue_free()
	
	for clue in new_clues:
		hints_container.add_child(new_clue(side, clue))
	return true


func new_clue(side, clue):
	var hints = null
	match side:
		Sides.TOP:
			hints = VBoxContainer.new()
			hints.add_constant_override("separation", 6)
		Sides.SIDE:
			hints = HBoxContainer.new()
			hints.add_constant_override("separation", 8)
			
	hints.rect_min_size = Vector2(32, 32)
	hints.alignment = BoxContainer.ALIGN_END
	for hint in clue:
		hints.add_child(new_hint(hint))
	return hints


func new_hint(hint) -> Label:
	var hint_label = Label.new() as Label
	hint_label.text = str(hint)
	hint_label.align = Label.ALIGN_CENTER
	hint_label.valign = Label.VALIGN_CENTER
	return hint_label


func reset_grid():
	var width = len(clues.top)
	var height = len(clues.side)
	if width * height == 0:
		print("not deleting all cells")
		return
	var grid_container = find_node("GridContainer")
	grid_container.columns = width
	while len(grid_container.get_children()) > width * height:
		# delete them
		var child = grid_container.get_child(0)
		grid_container.remove_child(child)
		child.queue_free()
	while len(grid_container.get_children()) < width * height:
		# duplicate them
		var child = $BaseGridSquare.duplicate()
		child.connect("cell_changed", self, "check_clues")
		child.visible = true
		grid_container.add_child(child)
	assign_coords(width, height)
	grid_edges()
	emit_signal("grid_reset", grid_container)


func parse_clue(raw_clue: String) -> Array:
	pass
	var res = []
	for clue in raw_clue.split("|"):
		var hints = []
		if not clue:
			hints.append(0)
		else:
			for hint in clue.split(","):
				hints.append(int(hint))
		res.append(hints)
				
	return res


func assign_coords(width, _height):
	var grid_container = find_node("GridContainer")
	var cells = grid_container.get_children()
	
	for i in range(len(cells)):
		var cell = cells[i]
		cell.coord.x = i % width
		cell.coord.y = i / width


func grid_edges():
	var grid = find_node("GridContainer")
	var width = grid.columns
	var height = grid.get_child_count() / width
	var cells = grid.get_children()
	
	for i in range(width * height):
		var cell = cells[i]
		var widths = {
			left = INNER_EDGE_WIDTH,
			top = INNER_EDGE_WIDTH,
			right = INNER_EDGE_WIDTH,
			bottom = INNER_EDGE_WIDTH,
		}
		
		var coord = {
			x = i % width,
			y = i / width,
		}
		
		# edge of 5x5 grid
		if coord.y % HELPER_GRID_SIZE == 0:
			widths.top = HELPER_EDGE_WIDTH
		if coord.y % HELPER_GRID_SIZE == HELPER_GRID_SIZE - 1:
			widths.bottom = HELPER_EDGE_WIDTH
		if coord.x % HELPER_GRID_SIZE == 0:
			widths.left = HELPER_EDGE_WIDTH
		if coord.x % HELPER_GRID_SIZE == HELPER_GRID_SIZE - 1:
			widths.right = HELPER_EDGE_WIDTH
		
		# outer edges
		if coord.y == 0:
			widths.top = BORDER_EDGE_WIDTH
		if coord.y == height - 1:
			widths.bottom = BORDER_EDGE_WIDTH
		if coord.x == 0:
			widths.left = BORDER_EDGE_WIDTH
		if coord.x == width - 1:
			widths.right = BORDER_EDGE_WIDTH
		
		
		set_frames(cell, widths.left, widths.top, widths.right, widths.bottom)


func set_frames(cell, left, top, right, bottom):
	set_frame(cell, Sides.SIDE, left)
	set_frame(cell, Sides.TOP, top)
	set_frame(cell, Sides.RSIDE, right)
	set_frame(cell, Sides.BOTTOM, bottom)


func set_frame(cell, side, width):
	var frame_sprite = null
	match side:
		Sides.SIDE:
			frame_sprite = cell.get_child(2)
		Sides.TOP:
			frame_sprite = cell.get_child(3)
		Sides.RSIDE:
			frame_sprite = cell.get_child(4)
		Sides.BOTTOM:
			frame_sprite = cell.get_child(5)
		_:
			print("unknown side: %s" % side)
			return false
	frame_sprite.set_frame(width)


func check_clues(coord):
#	print("checking! (%s, %s)" % [coord.x, coord.y])
	var all_cells = find_node("GridContainer").get_children()
	var hints_container = null
	var cells = null
	var clue = null
	var width = len(clues.top)
	for side in [Sides.TOP, Sides.SIDE]:
		match side:
			Sides.TOP:
				hints_container = $VBoxContainer/VHintsMargin/VHints.get_child(coord.x)
				clue = clues.top[coord.x]
				cells = []
				for y in range(len(clues.top)):
#					print("+%s (%s, %s)" % [coord.x + y * width, coord.x, y])
					cells.append(all_cells[coord.x + y * width])
			Sides.SIDE:
				hints_container = $VBoxContainer/HBoxContainer/HHintsMargin/HHints.get_child(coord.y)
				clue = clues.side[coord.y]
				cells = []
				for x in range(len(clues.side)):
#					print("+%s (%s, %s)" % [x + coord.y * width, x, coord.y])
					cells.append(all_cells[x + coord.y * width])
		check_clue(clue, cells, hints_container)


func check_clue(clue, cells, hints_container):
	var cells_s = util.cells2str(cells)
	assert(len(cells_s) == len(cells))
	var clue_check = checks.check_each_clue(clue, cells_s)
	assert(len(clue_check) == len(clue))
	for i in range(len(clue_check)):
		if clue_check[i]:
			util.set_label_color(hints_container.get_child(i), CORRECT_HINT_COLOR)
		else:
			util.set_label_color(hints_container.get_child(i), "")


# Called when the node enters the scene tree for the first time.
func _ready():
	checks._test()
	clue_set(Sides.TOP, raw_clues_top)
	clue_set(Sides.SIDE, raw_clues_side)
	self.connect("grid_reset", find_node("Cursor"), "_grid_reset")
	reset_grid()

var key_state = {
	last_pressed = null,
	last_op = "set",
}

func _input(event: InputEvent):
	var cursor = find_node("Cursor")
	var cursor_cell = get_cell(cursor.coords.x, cursor.coords.y)
	match event.as_text():
		"Up", "Down", "Left", "Right":
			cursor.passed_input(event)
			cursor_cell = get_cell(cursor.coords.x, cursor.coords.y)
			if not key_state.last_pressed == null:
				print("continuing %s %s" % [key_state.last_op, key_state.last_pressed])
				cursor_cell.set_continue(key_state.last_op == "set", key_state.last_pressed)
		"Z":
			if event.is_pressed() and key_state.last_pressed == null:
				var new_state = cursor_cell.set_state_soft(CellState.FILLED)
				if new_state == CellState.FILLED:
					key_state.last_op = "set"
				elif new_state == CellState.EMPTY:
					key_state.last_op = "clear"
				key_state.last_pressed = CellState.FILLED
			elif not event.is_pressed() and key_state.last_pressed == CellState.FILLED:
				key_state.last_pressed = null
		"X":
			if event.is_pressed() and key_state.last_pressed == null:
				var new_state = cursor_cell.set_state_soft(CellState.CROSSED)
				if new_state == CellState.CROSSED:
					key_state.last_op = "set"
				elif new_state == CellState.EMPTY:
					key_state.last_op = "clear"
				key_state.last_pressed = CellState.CROSSED
			elif not event.is_pressed() and key_state.last_pressed == CellState.CROSSED:
				key_state.last_pressed = null
		"C":
			if event.is_pressed() and key_state.last_pressed == null:
				var new_state = cursor_cell.set_state_soft(CellState.MARKED)
				if new_state == CellState.MARKED:
					key_state.last_op = "set"
				elif new_state == CellState.EMPTY:
					key_state.last_op = "clear"
				elif new_state == null:
					pass
				key_state.last_pressed = CellState.MARKED
				
			elif not event.is_pressed() and key_state.last_pressed == CellState.MARKED:
				key_state.last_pressed = null


func get_cell(x, y):
	var all_cells = find_node("GridContainer").get_children()
	var width = len(clues.top)
	return all_cells[x + y * width]
