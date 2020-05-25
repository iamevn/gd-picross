extends GridContainer

var mouse_state = {
	last_pressed = null,
	last_op = "set",
}

func set_mouse(last_pressed, last_op_set):
	print("set_mouse")
	mouse_state.last_pressed = last_pressed
	mouse_state.last_op = "set" if last_op_set else "clear"


func release_mouse(which_released):
	if which_released == mouse_state.last_pressed:
		print("released_mouse")
		mouse_state.last_pressed = null


func get_mouse():
	return mouse_state
