tool
extends MarginContainer

# set margin so that the outter edge of the grid doesn't overhang to the left
func _on_HHintsMargin_resized():
	var margin = get_node("../HBoxContainer/HHintsMargin") as MarginContainer
	add_constant_override("margin_left", margin.rect_size.x)
