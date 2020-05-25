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
	var new_state = null
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				new_state = toggle(CellState.FILLED)
				get_parent().set_mouse(new_state, new_state == CellState.FILLED)
			BUTTON_RIGHT:
				new_state = toggle(CellState.CROSSED)
				get_parent().set_mouse(new_state, new_state == CellState.CROSSED)
			BUTTON_MIDDLE:
				new_state = toggle(CellState.MARKED)
				get_parent().set_mouse(new_state, new_state == CellState.MARKED)
			_:
				print("Unknown grid_square_input %s", event.as_text())
	elif event is InputEventMouseButton and not event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				get_parent().release_mouse(CellState.FILLED)
			BUTTON_RIGHT:
				get_parent().release_mouse(CellState.CROSSED)
			BUTTON_MIDDLE:
				get_parent().release_mouse(CellState.MARKED)
			_:
				pass


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


func _on_BaseGridSquare_mouse_entered():
	return
	print("mouse entered (%s, %s)" % [coord.x, coord.y])
	var mouse_state = get_parent().get_mouse()
	if not mouse_state.last_pressed == null:
		print("continuing %s %s (%s, %s)" % [mouse_state.last_op, mouse_state.last_pressed, coord.x, coord.y])
		set_continue(mouse_state.last_op == "set", mouse_state.last_pressed)


func _process(delta):
	if not visible:
		return
	if get_global_rect().has_point(get_global_mouse_position()):
		var mouse_state = get_parent().get_mouse()
		if not mouse_state.last_pressed == null:
			set_continue(mouse_state.last_op == "set", mouse_state.last_pressed)
