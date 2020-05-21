tool
extends Sprite

export var wrap_around = true

var coords = {
	x = 0,
	y = 0,
}

var grid_container: GridContainer = null
var grid_dims := {
	x = 5,
	y = 5,
}
var grid_cell_size := {
	x = 32,
	y = 32,
}

func _grid_reset(grid: GridContainer):
	grid_container = grid
	grid_dims.x =  grid.columns
	grid_dims.y = grid.get_child_count() / grid.columns

	print("got grid_reset, dims: %s, size: %s" % [grid_dims, grid_cell_size])


func passed_input(event: InputEvent):
	# TODO: use actions instead
	if event.is_pressed():
		match [event.as_text(), event.is_pressed()]:
			["Left", true]:
				coords.x -= 1
			["Right", true]:
				coords.x += 1
			["Up", true]:
				coords.y -= 1
			["Down", true]:
				coords.y += 1
			_:
				print("Unknown event: %s %s" % [event.as_text(), "down" if event.is_pressed() else "up"])
	stay_inside_grid()


func _process(delta):
	stay_inside_grid()
	self.position.x = coords.x * grid_cell_size.x
	self.position.y = coords.y * grid_cell_size.y


func stay_inside_grid():
	var right_edge = grid_dims.x - 1
	var bottom_edge = grid_dims.y - 1
	if coords.x < 0:
		coords.x = right_edge if wrap_around else grid_dims.x
	if coords.y < 0:
		coords.y = bottom_edge if wrap_around else 0
	if coords.x >= grid_dims.x:
		coords.x = 0 if wrap_around else right_edge
	if coords.y >= grid_dims.y:
		coords.y = 0 if wrap_around else bottom_edge
