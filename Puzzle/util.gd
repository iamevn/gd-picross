tool
# misc utility functions
const enums = preload("enum.gd")
const CellState = enums.CellState


static func cells2str(cells: Array) -> String:
	var s := ""

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


static func set_all_label_color(label_container: Node, color: Color) -> void:
	for label in label_container.get_children():
		set_label_color(label, color)


static func set_label_color(label: Label, color: Color) -> void:
	label.add_color_override("font_color", color)


static func map_bool(arr: Array) -> Array:
	var ret := []
	for e in arr:
		ret += [not not e]
	return ret


static func invert_string(s: String) -> String:
	var ret := ""
	for i in range(len(s) - 1, -1, -1):
		ret += s[i]
	return ret
