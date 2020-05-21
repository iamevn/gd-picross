tool
extends TextureButton

const enums = preload("enum.gd")
const CellState = enums.CellState

var state = CellState.EMPTY
signal cell_changed(cell)

var coord = {x=-1, y=-1}

func cycle(forwards=true):
	match state:
		CellState.EMPTY:
			state = CellState.FILLED if forwards else CellState.CROSSED
		CellState.FILLED:
			state = CellState.CROSSED if forwards else CellState.EMPTY
		CellState.CROSSED:
			state = CellState.EMPTY if forwards else CellState.FILLED
		CellState.MARKED:
			state = CellState.EMPTY if forwards else CellState.CROSSED
	$FillSprite.set_frame(state)


func set_state(new_state):
	state = new_state
	$FillSprite.set_frame(state)
	emit_signal("cell_changed", self.coord)
	return new_state


func set_state_soft(new_state):
	match [state, new_state]:
		[CellState.FILLED, CellState.FILLED]:
			return set_state(CellState.EMPTY)
		[CellState.FILLED, CellState.EMPTY]:
			return set_state(CellState.EMPTY)
		[CellState.FILLED, CellState.CROSSED]:
			return set_state(CellState.EMPTY)
		[CellState.FILLED, CellState.MARKED]:
			return null
		[CellState.EMPTY, CellState.FILLED]:
			return set_state(CellState.FILLED)
		[CellState.EMPTY, CellState.EMPTY]:
			return set_state(CellState.EMPTY)
		[CellState.EMPTY, CellState.CROSSED]:
			return set_state(CellState.CROSSED)
		[CellState.EMPTY, CellState.MARKED]:
			return set_state(CellState.MARKED)
		[CellState.CROSSED, CellState.FILLED]:
			return set_state(CellState.EMPTY)
		[CellState.CROSSED, CellState.EMPTY]:
			return set_state(CellState.EMPTY)
		[CellState.CROSSED, CellState.CROSSED]:
			return set_state(CellState.EMPTY)
		[CellState.CROSSED, CellState.MARKED]:
			return null
		[CellState.MARKED, CellState.FILLED]:
			return set_state(CellState.FILLED)
		[CellState.MARKED, CellState.EMPTY]:
			return set_state(CellState.EMPTY)
		[CellState.MARKED, CellState.CROSSED]:
			return set_state(CellState.CROSSED)
		[CellState.MARKED, CellState.MARKED]:
			return set_state(CellState.EMPTY)


func toggle(tstate):
	if state == tstate:
		return set_state(CellState.EMPTY)
	else:
		return set_state(tstate)


func _on_TextureRect_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				toggle(CellState.FILLED)
			BUTTON_RIGHT:
				toggle(CellState.CROSSED)
			_:
				print("Unknown grid_square_input %s", event.as_text())


func set_continue(set: bool, what: int):
	match [set, what]:
		[true, CellState.FILLED]:
			# fill empty and marked
			if state == CellState.EMPTY or state == CellState.MARKED:
				set_state(CellState.FILLED)
		[true, CellState.EMPTY]:
			# clear everything
			set_state(CellState.EMPTY)
		[true, CellState.CROSSED]:
			# cross empty and marked
			if state == CellState.EMPTY or state == CellState.MARKED:
				set_state(CellState.CROSSED)
		[true, CellState.MARKED]:
			# mark empty
			if state == CellState.EMPTY:
				set_state(CellState.MARKED)
		[false, CellState.FILLED]:
			# clear everything
			set_state(CellState.EMPTY)
		[false, CellState.EMPTY]:
			# clear everything
			set_state(CellState.EMPTY)
		[false, CellState.CROSSED]:
			# clear everything
			set_state(CellState.EMPTY)
		[false, CellState.MARKED]:
			# clear marked
			if state == CellState.MARKED:
				set_state(CellState.EMPTY)
	return state
