# ============================================= # ============================================= #
# FPS counter in top right corner
# ============================================= # ============================================= #
extends Label

var bitmap = preload("res://digits.tres")	# Template for bitmap font

# ============================================= # ============================================= #
# Define bitmap font
func _ready():
	var bmfont = BitmapFont.new()
	bmfont.add_texture(bitmap)
	for i in 10:
		bmfont.add_char(48 + i, 0, Rect2(5 * i, 0, 5, 7))
	
	set("custom_fonts/font", bmfont)

# ============================================= # ============================================= #
# Hide counter on click, revoke it "=" key
func _on_FPS_gui_input(event):
	if Input.is_action_just_pressed("left_click"):
		set_visible(false)
