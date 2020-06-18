# ============================================= # ============================================= #
# Color samples
# ============================================= # ============================================= #
extends Control

var num = 0						# item number in palette
var hex = "#000"				# HEX value
var rgb = Color(255, 255, 255)	# RGB value
var raw = Color(1, 1, 1)		# RAW color

# ============================================= # ============================================= #
func _ready():
	# Position marker on default color sample when scene starts
	if rgb == g.Flags.get("def")[0]:
		g.root.CMark.set_position(g.root.Palette.get_position() + get_position())
	# Generate tooltip based on hex/tag and rgb values
	get_child(0).set_tooltip(str(hex, ": [", rgb.r, ",", rgb.g, ",", rgb.b, "]"))

# ============================================= # ============================================= #
# If clicked while hovered
func _on_ColorRect_gui_input(event):
	if Input.is_action_just_pressed("left_click"):
		Activate()

# ============================================= # ============================================= #
# Set sample size
func Resize(arg=Vector2(16,16)):
	get_child(0).set_size(arg)

# ============================================= # ============================================= #
# Set sample color
func SetColor(arg=null):
	if arg and arg[0] + arg[1] + arg[2] > 3:	# If 255 RGB given
		raw = g.RGB2RAW(arg)
	else:
		raw = g.RGB2RAW(rgb)
	get_child(0).set_frame_color(raw)

# ============================================= # ============================================= #
func PickIfID(id=g.c):
	if id == hex:
		Activate()

# ============================================= # ============================================= #
func PickIfNum(id=g.ncol):
	if id == num:
		Activate()

# ============================================= # ============================================= #
# Make selected color current
func Activate():
	g.c = hex
	g.ncol = num
	g.root.CMark.set_position(g.root.Palette.get_position() + get_position())
	# Shift frame's right points to match sample width
	g.root.CMark.set_point_position(1, Vector2(get_child(0).rect_size.x, 0))
	g.root.CMark.set_point_position(2, Vector2(get_child(0).rect_size.x, get_child(0).rect_size.y))
	# Match pointer's color with sample
	g.root.TintCursor(true)
