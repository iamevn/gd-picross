tool
# misc utility functions
const enums = preload("enum.gd")
const CellState = enums.CellState

static func cells2str(cells: Array) -> String:
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


static func set_all_label_color(label_container, color):
	for label in label_container.get_children():
		set_label_color(label, color)


static func set_label_color(label, color):
	label.add_color_override("font_color", color)

