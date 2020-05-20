tool
extends Sprite

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
	
func _unhandled_input(event: InputEvent):
	# TODO: use actions instead
	if event.is_pressed():
		match event.as_text():
			"Left":
				coords.x -= 1
			"Right":
				coords.x += 1
			"Up":
				coords.y -= 1
			"Down":
				coords.y += 1
			_:
				print("Unknown event: %s" % event.as_text())
	stay_inside_grid()


func _process(delta):
#	if grid_container:
#		grid_dims.x =  grid_container.columns
#		grid_dims.y = grid_container.get_child_count() / grid_container.columns
#
#		grid_cell_size.x = grid_container.rect_size.x / grid_dims.x
#		grid_cell_size.y = grid_container.rect_size.y / grid_dims.y

	stay_inside_grid()
	self.position.x = coords.x * grid_cell_size.x
	self.position.y = coords.y * grid_cell_size.y


func stay_inside_grid():
	if coords.x < 0:
		coords.x = 0
	if coords.y < 0:
		coords.y = 0
	if coords.x >= grid_dims.x:
		coords.x = grid_dims.x - 1
	if coords.y >= grid_dims.y:
		coords.y = grid_dims.y - 1
		
