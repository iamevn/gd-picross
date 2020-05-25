extends Node2D
# Hook up resize events to scale the puzzle's size and keep it centered
func _ready():
	var vp = self.get_viewport()
	vp.connect("size_changed", self, "_viewport_size_changed")

func _viewport_size_changed():
	$PuzzleBuilder.rect_size = get_viewport_rect().size
	
