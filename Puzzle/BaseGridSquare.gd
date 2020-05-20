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


func toggle(tstate):
	if state == tstate:
		set_state(CellState.EMPTY)
	else:
		set_state(tstate)
	

func _on_TextureRect_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
#			print("LMB pressed")
#			cycle(true)
			toggle(CellState.FILLED)
		if event.button_index == BUTTON_RIGHT:
#			print("RMB pressed")
#			cycle(false)
			toggle(CellState.CROSSED)
		emit_signal("cell_changed", self.coord)
