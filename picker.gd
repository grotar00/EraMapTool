# ============================================= # ============================================= #
# Custom color sample with color picker
# ============================================= # ============================================= #
extends Control

var num = 0						# item number in palette
var hex = "#000"				# HEX value
var rgb = Color(255, 255, 255)	# RGB value
var raw = Color(1, 1, 1)		# RAW color

var wait_for_release = false

onready var ColPicker = get_node("ColorPickerButton")
onready var Btn = get_node("Button")

# ============================================= # ============================================= #
func _ready():
	Btn.connect("pressed", self, "ToggleLock")
	ColPicker.connect("popup_closed", self, "QueueLock")
	ColPicker.connect("color_changed", self, "UpdateColor")
	UpdateColor(ColPicker.color)

# ============================================= # ============================================= #
func QueueLock():
	UpdateColor(ColPicker.color)
	Btn.set_pressed(false)
	Activate()
	g.queue_unlock = true

# ============================================= # ============================================= #
func ToggleLock(arg=true):
	if ColPicker.get_popup().is_visible():
		UpdateColor(ColPicker.color)
		ColPicker.get_popup().hide()
		Activate()
		g.queue_unlock = true
	else:
		ColPicker.get_popup().popup_centered()
		ColPicker.get_popup().set_position(Vector2(600, 152))
		g.lock = true
		Activate()

# ============================================= # ============================================= #
func UpdateColor(newcol):
	raw = newcol
	rgb = g.RAW2RGB(raw)
	hex = g.RGB2HEX(rgb)
	Btn.set_tooltip(str(hex, ": [", rgb.r, ",", rgb.g, ",", rgb.b, "]"))
	g.root.TintCursor(true)
	
# ============================================= # ============================================= #
func Resize(arg=Vector2(16,16)):
	#ColPicker.set_size(arg)
	return

# ============================================= # ============================================= #
func SetColor(arg=null):
	if arg and arg[0] + arg[1] + arg[2] > 3:	# If 255 RGB given
		raw = g.RGB2RAW(arg)
	else:
		raw = g.RGB2RAW(rgb)
	ColPicker.set_frame_color(raw)

# ============================================= # ============================================= #
func PickIfID(id=g.c):
	if !(id in g.Pallet) and !(id in g.Flags):
		if id != hex:
			ColPicker.get_picker().add_preset(raw)
			UpdateColor(g.HEX2RAW(id))
			ColPicker.get_picker().set_pick_color(raw)
			ColPicker.set_pick_color(raw)
			Activate()

# ============================================= # ============================================= #
func PickIfNum(id=g.ncol):
	if id == num:
		Activate()

# ============================================= # ============================================= #
func Activate():
	g.c = hex
	g.ncol = num
	g.root.CMark.set_position(g.root.Palette.get_position() + get_position())
	# Shift right frame points to match sample width
	g.root.CMark.set_point_position(1, Vector2(rect_size.x, 0))
	g.root.CMark.set_point_position(2, Vector2(rect_size.x, 24))
	g.root.TintCursor(true)
