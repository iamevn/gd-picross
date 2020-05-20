tool
extends CenterContainer

const CellState = preload("res://Puzzle/BaseGridSquare.gd").CellState
enum Sides {TOP, SIDE, BOTTOM, RSIDE}

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


# line completed?
# |-Y: highlight line
# \-N: possible to satisfy clues given current state?
#   |-N: unhighlight line
#   \-Y: are any clues completed and unambiguous?
#     |-Y: highlight those clues
#     \-N: unhighlight those clues
func check_clue(clue, cells, hints_container):
	var cells_s = cells2str(cells)
	assert(len(cells_s) == len(cells))
	var clue_check = check_each_clue(clue, cells_s)
	assert(len(clue_check) == len(clue))
	for i in range(len(clue_check)):
		if clue_check[i]:
			set_label_color(hints_container.get_child(i), CORRECT_HINT_COLOR)
		else:
			set_label_color(hints_container.get_child(i), "")


func cells2str(cells):
	var s = ""
	
	for cell in cells:
		match(cell.state):
			CellState.EMPTY:
				s += "_"
			CellState.FILLED:
				s += "O"
			CellState.CROSSED:
				s += "X"
			CellState.MARKED:
				s += "_"
	
	return s


# check if line completely matches clue
func check_line_completed(clue: Array, cells_s: String):
	var regex_string = "^[_X]*O{%s}" % clue[0]
	if len(clue) > 1:
		for n in clue.slice(1, -1):
			regex_string += "[_X]+O{%s}" % n
	regex_string += "[_X]*$"
	var pattern = RegEx.new()
	pattern.compile(regex_string)
#	print("checking complete pattern %s on %s" % [pattern.get_pattern(), cells_s])
	return pattern.search(cells_s)


# check if line incompletely matches clue
func check_line_possible(clue: Array, cells_s: String):
	var regex_string = "^[_X]*[O_]{%s}" % clue[0]
	if len(clue) > 1:
		for n in clue.slice(1, -1):
			regex_string += "[_X]+[O_]{%s}" % n
	regex_string += "[_X]*$"
	var pattern = RegEx.new()
	pattern.compile(regex_string)
#	print("checking partial pattern %s on %s" % [pattern.get_pattern(), cells_s])
	return pattern.search(cells_s)


# if there's only one clue, check that it is matched and return that cell true/false
# if the line is completed return each cell true
# if the line is impossible return each cell false
# for each clue, check that it could fit the line and return true/false for each cell
# 
# TODO: optimize so that regex patterns are only built once when the clue is set
func check_each_clue(clue: Array, cells_s: String) -> Array:
	if len(clue) == 1:
		return [check_line_completed(clue, cells_s)]
	var checked := []
	if check_line_completed(clue, cells_s):
		for n in range(len(clue)):
			checked += [true]
	elif not check_line_possible(clue, cells_s):
		for n in range(len(clue)):
			checked += [false]
	else:
		for i in range(len(clue)):
			checked += [check_single_subclue(i, clue, cells_s)]
	return checked


func check_single_subclue(i: int, clue: Array, cells_s: String) -> bool:
	var clue_count := len(clue)
	var last_clue_idx := clue_count - 1
	var regex_string := ""
	# check if i fits
	match i:
		0: #first clue, match against left edge, soft match rest of clues
			regex_string += "^(?<pre>(?:[_X]*X)?)(?<posn>O{%s})X[_X]*[O_]{%s}" % [clue[0], clue[1]]
			if clue_count > 2:
				for n in clue.slice(2, -1):
					regex_string += "[_X]+[O_]{%s}" % n
			regex_string += "[_X]*$"
		last_clue_idx: #last clue, match against right edge, soft match rest of clues
			regex_string += "^(?<pre>[_X]*[O_]{%s}" % clue[0]
			if clue_count > 2:
				for n in clue.slice(1, -2):
					regex_string += "[_X]+[O_]{%s}" % n
			regex_string += "[_X]*X)(?<posn>O{%s})(?:X[_X]*)?$" % clue[-1]
		_: #middle clue, idk, just check that it's in there?
			#probably needs more than is easy to do with regex
			regex_string += "^(?<pre>"
			for j in range(len(clue)):
				if j == i:
					regex_string += "X)(?<posn>O{%s})X" % clue[j]
				elif j == 0:
					regex_string += "[_X]*[O_]{%s}" % clue[j]
				elif j == i + 1:
					regex_string += "[_X]*[O_]{%s}" % clue[j]
				else:
					regex_string += "[_X]+[O_]{%s}" % clue[j]
			regex_string += "[X_]*$"
	var pattern := RegEx.new()
	pattern.compile(regex_string)
#	var matches = pattern.search_all(cells_s)
#	return len(matches) == 1
	var i_match := pattern.search(cells_s)
	if not i_match:
		return false
	var i_match_idx := len(i_match.get_string("pre"))
#	assert(not i_match)
	# have: clue i fits at position x
	# want: only clue i fits at position x
	
	# for each other clue, check if clues before and after that clue fit in the string before and after the original match
	var pre_cells := cells_s.substr(0, i_match_idx)
	var post_cells := cells_s.substr(i_match_idx + clue[i])
#	print("clues:%s" % [clue])
#	print("pre:  %s" % pre_cells)
#	print("post: %s" % post_cells)
	for j in range(len(clue)):
		if j == i or clue[j] != clue[i]:
#			print("%s is i" % j)
			continue
		elif j == 0:
#			print(clue.slice(j + 1, len(clue) - 1))
			if check_line_possible(clue.slice(j + 1, len(clue) - 1), post_cells):
#				print("%s fits" % j)
				return false
#			print("%s doesn't fit" % j)
		elif j == len(clue) - 1:
#			print(clue.slice(0, j - 1))
			if check_line_possible(clue.slice(0, j - 1), pre_cells):
#				print("%s fits" % j)
				return false
#			print("%s doesn't fit" % j)
		else:
#			print(clue.slice(0, j - 1), clue.slice(j + 1, len(clue) - 1))
			if check_line_possible(clue.slice(0, j - 1), pre_cells) and check_line_possible(clue.slice(j + 1, len(clue) - 1), post_cells):
#				print("%s fits" % j)
				return false
#			print("%s doesn't fit" % j)
	return true


func set_all_label_color(label_container, color):
	for label in label_container.get_children():
		set_label_color(label, color)


func set_label_color(label, color):
	label.add_color_override("font_color", color)


func _test_check_each_clue(clue: Array, cells_s: String, expected: Array):
	assert(len(clue) == len(expected))
	var result := check_each_clue(clue, cells_s)
	if result == expected:
		# print("Pass!\n")
		return true
	else:
		print("######\nClue: %s\nCells: %s\nExpected: %s" % [clue, cells_s, expected])
		print("Failed, got: %s" % [result])
		return false


func invert_string(s: String) -> String:
	var ret := ""
	for i in range(len(s) - 1, -1, -1):
		ret += s[i]
	return ret

func _test():
	var test_cases := [
		{
			clue = [1, 1, 1],
			cells_s = "OXO_O_",
			expected = [true, true, true],
		},
		{
			clue = [1, 1, 1],
			cells_s = "______",
			expected = [false, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "OX____",
			expected = [true, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "O_____",
			expected = [false, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "XOX___",
			expected = [true, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "_OX___",
			expected = [false, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "OXXX__",
			expected = [false, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "__XOX_",
			expected = [false, true, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "__XOX___",
			expected = [false, false, false],
		},
		{
			clue = [1, 4],
			cells_s = "_XOX_______",
			expected = [true, false],
		},
		{
			clue = [1, 1, 1, 1],
			cells_s = "__XOX______",
			expected = [false, false, false, false],
		},
		{
			clue = [1, 1, 1, 1],
			cells_s = "____XOXOXOX",
			expected = [false, true, true, true],
		},
		{
			clue = [1, 1, 1, 1],
			cells_s = "XX_XXOXOXOX",
			expected = [false, true, true, true],
		},
		{
			clue = [1, 1, 1, 1],
			cells_s = "___XXOXOXOX",
			expected = [false, true, true, true],
		},
	]
	var reversed_test_cases := []
	for test_case in test_cases:
		var reversed_case := {
			clue = test_case.clue.duplicate(),
			cells_s = invert_string(test_case.cells_s),
			expected = test_case.expected.duplicate(),
		}
		reversed_case.clue.invert()
		reversed_case.expected.invert()
		reversed_test_cases.append(reversed_case)
	var passed := 0
	var failed := 0
	for test_case in test_cases: #+ reversed_test_cases:
		var result = _test_check_each_clue(test_case.clue, test_case.cells_s, test_case.expected)
		if result:
			passed += 1
		else:
			failed += 1

# Called when the node enters the scene tree for the first time.
func _ready():
	_test()
	clue_set(Sides.TOP, raw_clues_top)
	clue_set(Sides.SIDE, raw_clues_side)
	self.connect("grid_reset", find_node("Cursor"), "_grid_reset")
	reset_grid()
