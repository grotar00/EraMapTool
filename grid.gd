# ============================================= # ============================================= #
# Grid of the edit field
# ============================================= # ============================================= #
extends Control

var offset = Vector2(0, 0)

# ============================================= # ============================================= #
func _ready():
	update() # Same as _draw()

# ============================================= # ============================================= #
func _draw():
	for col in g.size.x + 1:
		draw_line(Vector2(col * g.step, 0) + offset, Vector2(col * g.step, g.size.y * g.step) + offset, Color(1,1,1))
	for row in g.size.y + 1:
		draw_line(Vector2(0, row * g.step) + offset, Vector2(g.size.x * g.step, row * g.step) + offset, Color(1,1,1,.6))
