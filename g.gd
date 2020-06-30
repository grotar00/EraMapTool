# ============================================= # ============================================= #
# Global variables and data convert functions
# ============================================= # ============================================= #
extends Node

# Signals are listened by other nodes
signal rotate_colors	# Select next color in row
signal select_colors	# Select picked color
signal destroy_pointers	# Destroy col/row pointers
signal destroy_previews	# Destroy drawing hints

var WEB = false				# Flag for browser version
# Paste inside <body> of index.html to intrcept page scrolling with mouse wheel:
#<script>
#	window.addEventListener("wheel", function(e){
#		e.preventDefault();
#		}, {passive: false} );
#</script>

var root					# Root node (is assigned in root.gd)
var iopan = true			# State of I/O panel (true=shown)
var debug = 0				# You guess

var DAY = 0					# Global day of year
var season					# Season (round(DAY / 30))
var day						# Day of season (DAY % 30)
var mix						# Color blend ratio
var prob					# Effect probability
var s33d					# Template for seeded random
var Noise = []				# Array for storing perlin noise values 1…100
var nBias = 0				# Defines range of Noise to be read

# Foliage color mix ratio by season days
var curves = [	0.45,0.35,0.25,0.17,0.10,0.04,0.01,
				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
				0.01,0.04,0.10,0.17,0.25,0.35,0.45]
# Effects probability factor by season days
var curvee = [	0.25,0.30,0.37,0.45,0.55,0.66,0.76,0.85,0.93,0.97,0.99,
				1,1,1,1,1,1,1,1,1,1,
				0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1]

var step = 14				# Symbol size (grid)
var mpos = Vector2(0, 0)	# Mouse position (updates on event)
var size = Vector2(64, 42)	# Map dimensions
var snap = Vector2(0, 0)	# Highlighted cell (x*2;y)
var ncol = 0				# ID of currently selected number
var last = Vector2(0, 0)	# Coords of last edited cell
var draw = null				# Next click will draw a line or rect
var line = false			# Is drawing a line

var pick = 0				# Is alt pressed (pick color/symbol)
var bias = 0				# Is shift pressed (shift half cell)
var warp = 0				# Is ctrl pressed (pop/push)
var mode = true				# Apply just symbol or symbol & color mode
var mark = false			# Flags display
var grid = true				# Grid display
var hold = true				# Is drawing just on click
var diff = false			# Change only color or only symbol
var dots = false			# Draw dots instead of spaces (easy indication)

var select = false			# Selecting rect to drag
var drag = false			# Dragging a rect

var lock = false			# Whether picker is opened or camera active
var queue_unlock = false	# Next click will unlock editing
var timestop = false

# Current brush (call as g.b from any other script)
var b = "□"
# Current color (call as g.c from any other script)
var c = "#FFFFFF"

var Location = []	# Map state array for symbols (crucial)
var ColArray = []	# Map state array for colors (crucial)

var History = []	# Actions log
var hSize = 24		# Actions log size (up to N undos); each state is about 60K symbols and 60Kb memory use
var hPos = 0		# Undo position
var progress = 0	# Actions since last save
var area = ""		# Name of imported file

var regionb = []	# Selection fragment with symbols
var regionc = []	# Selection fragment with colors
var regiond = Vector2(0, 0) # Array size (x and y negative if anchor is bottom right corner)
var regionp			# RichTextLabel node for preview

var Half = []		# List of known 1-byte characters
# Generate dependancies from Flags using CODE : INDEX
var Index = []
# Color samples for editor, are converted to Dict on runtime
# INDEX : RGB
var Pallet = [	[255,255,255],
				[200,200,200],
				[160,160,160],
				[120,120,120],
				[ 80, 80, 80],
				[ 40, 40, 40],
				[ 20, 20, 20],
				[ 10, 10, 10],
				[ 80,160,240],
				[ 60,120,180],
				[ 40, 80,120],
				[ 20, 40, 60],
				[120,200,120],
				[ 90,150, 90],
				[ 60,100, 60],
				[ 30, 50, 30],
				[100,100, 60],
				[ 80, 60, 40],
				[ 70, 40, 30],
				[ 90, 30,  0],
				[120,150,180],
				[ 60, 90,120],
				[120,100, 80],
				[200,160,120],
				[140, 70, 60],
				[250,180,210],
				[240,150,140],
				[120, 60,250],
				[150,120,210],
				[180, 90,210],
				[120,140,240],
				[  0,120,240],
				[210, 60, 90],
				[180, 20, 30],
				[240,220,120],
				[240,150, 80],
				[150,200,255],
				[140,240,120],
				[ 30,  0, 30],
				[ 60,  0, 60],
				[120,  0,120],
				[ 60,  0,  0],
				[120,  0,  0],
				[240,  0,  0],	
				[  0, 60,  0],
				[  0,120,  0],
				[  0,240,  0],
				[  0,  0, 60],
				[  0,  0,120],
				[  0,  0,240],
				[  0, 30, 30],
				[  0, 60, 60],
				[  0,120,120],
				[ 30, 30,  0],
				[ 60, 60,  0],
				[120,120,  0]]
# Dynamic color
# INDEX : RGB, RAW, MARKER RGB, ID
var Flags = {	"white":	[[255,255,255],[],[255,255,255],255],	# Pure white not affected by time stop
				"def":		[[200,200,200],[],[  0,  0,  0],0  ],	# Calls RESETCOLOR()
				"call":		[[255,255,255],[],[  0,255,255],2  ],	# Calls GETMAP() for each adjacent digit
				"debug":	[[255,180,220],[],[255,  0,  0],3  ],
				"floral":	[[120,200,120],[],[ 20,180, 40],23 ],	# Tree crown light
				"floran":	[[ 90,150, 90],[],[ 20,180, 40],22 ],	# Tree crown
				"florad":	[[ 60,100, 60],[],[ 20,180, 40],21 ],	# Tree crown dark
				"floras":	[[ 30, 50, 30],[],[ 20,180, 40],20 ],	# Tree crown in shadow
				"bambool":	[[150,150,  0],[],[120,160,  0],33 ],	# Bamboo light
				"bamboon":	[[ 75, 75,  0],[],[120,160,  0],32 ],	# Bamboo
				"bambood":	[[ 45, 45,  0],[],[120,160,  0],31 ],	# Bamboo dark
				"bamboos":	[[ 20, 20,  0],[],[120,160,  0],30 ],	# Bamboo in shadow
				"sakural":	[[240,150,200],[],[255,100,200],43 ],	# Cherry tree crown light
				"sakuran":	[[210,100,150],[],[255,100,200],42 ],	# Cherry tree crown
				"sakurad":	[[160, 60,100],[],[255,100,200],41 ],	# Cherry tree crown dark
				"sakuras":	[[ 90, 40, 60],[],[255,100,200],40 ],	# Cherry tree crown in shadow
				"framel":	[[120,120,  0],[],[255,255,  0],9  ],	# Frame light
				"framen":	[[ 60, 60,  0],[],[255,255,  0],8  ],	# Frame
				"framed":	[[ 30, 30,  0],[],[255,255,  0],7  ],	# Frame dark
				"flower":	[[210,150,240],[],[224,  0,255],71 ],	# Spawns flower of random shape and color (ρ, ф)
				"flowers":	[[140,100,160],[],[200,  0,220],70 ],	# Spawns group of flowers of random color (∴, ∵, ･:, :･)
				"water":	[[ 80,160,220],[],[  0,  0,255],12 ],	# Empty water cell for lily/fish spawn
				"tides":	[[ 60,180,200],[],[  0,120,210],11 ],	# Random strong waves (~, ～)
				"still":	[[ 40,200,180],[],[  0,150,180],10 ],	# Random still waves (~, ～)
				"spray":	[[210,220,210],[],[180,255,240],15 ],	# Waterfall bottom
				"steam":	[[180,190,180],[],[220,220,220],16 ],	# Bathhouse, hotsprings
				"flame":	[[240,210, 90],[],[240,160, 80],17 ],	# Fire
				"ground":	[[220,150, 80],[],[120, 60,  0],64 ],	# Empty cell for foliage/snow/petals spawn
				"paving":	[[ 42, 42, 42],[],[ 60, 60, 60],62 ]}	# Empty cell for foliage/snow/petals spawn (shadow)
# Color dictionary for legacy format
# INDEX : RGB, HEX (for export as generic color)
var Legacy = {
			"chalk":		[255,255,255],
			"def":			[200,200,200],
			"stone":		[160,160,160],
			"asphalt":		[120,120,120],
			"granite":		[80,80,80],
			"basalt":		[40,40,40],
			"coal":			[20,20,20],
			"space":		[10,10,10],
			"water_light":	[80,160,240],
			"water":		[60,120,180],
			"water_dark":	[40,80,120],
			"water_darker":	[20,40,60],
			"plant_light":	[120,200,120],
			"plant":		[90,150,90],
			"plant_dark":	[60,100,60],
			"plant_darker":	[30,50,30],
			"dirt":			[120,100,80],
			"quag":			[100,100,60],
			"wood":			[80,60,40],
			"mahogany":		[90,30,0],
			"steel":		[120,150,180],
			"iron":			[60,90,120],
			"sand":			[200,160,120],
			"brick":		[140,70,60],
			"candy":		[250,180,210],
			"peach":		[240,150,140],
			"eggplant":		[120,60,250],
			"viola":		[150,120,210],
			"iris":			[180,90,210],
			"lilac":		[120,140,240],
			"cinnabar":		[210,60,90],
			"lapis":		[0,120,240],
			"cherry":		[180,20,30],
			"choco":		[70,40,30],
			"lemon":		[240,220,120],
			"orange":		[240,150,80],
			"diamond":		[150,200,255],
			"peridot":		[140,240,120],
			"purple_dark":	[30,0,30],
			"purple":		[60,0,60],
			"purple_light":	[120,0,120],
			"red_dark":		[60,0,0],
			"red":			[120,0,0],
			"red_light":	[240,0,0],	
			"green_dark":	[0,60,0],
			"green":		[0,120,0],
			"green_light":	[0,240,0],
			"blue_dark":	[0,0,60],
			"blue":			[0,0,120],
			"blue_light":	[0,0,240],
			"azure_dark":	[0,30,30],
			"azure":		[0,60,60],
			"azure_light":	[0,120,120],
			"yellow_dark":	[30,30,0],
			"yellow":		[60,60,0],
			"yellow_light":	[120,120,0]}
var HexTable = "0123456789ABCDEFF"
# Fast pick a symbol by pressing following keys
var FramNarr = {KEY_KP_1 : "└",
				KEY_KP_2 : "┬",
				KEY_KP_3 : "┘",
				KEY_KP_4 : "┤",
				KEY_KP_5 : "┼",
				KEY_KP_6 : "├",
				KEY_KP_7 : "┌",
				KEY_KP_8 : "┴",
				KEY_KP_9 : "┐",
				KEY_KP_0 : "―",
				KEY_KP_ADD : "｜",
				KEY_KP_DIVIDE : "／",
				KEY_KP_MULTIPLY : "＼"}
var FramBold = {KEY_KP_1 : "┗",
				KEY_KP_2 : "┳",
				KEY_KP_3 : "┛",
				KEY_KP_4 : "┫",
				KEY_KP_5 : "╋",
				KEY_KP_6 : "┣",
				KEY_KP_7 : "┏",
				KEY_KP_8 : "┻",
				KEY_KP_9 : "┓",
				KEY_KP_0 : "━",
				KEY_KP_ADD : "┃"}
var DigiKeys = {KEY_0 : "0",
				KEY_1 : "1",
				KEY_2 : "2",
				KEY_3 : "3",
				KEY_4 : "4",
				KEY_5 : "5",
				KEY_6 : "6",
				KEY_7 : "7",
				KEY_8 : "8",
				KEY_9 : "9",
				KEY_MINUS : "-",
				KEY_COMMA : ",",
				KEY_PERIOD : ".",
				KEY_SLASH : "/",
				KEY_BRACELEFT : "[",
				KEY_BRACERIGHT : "]",
				KEY_APOSTROPHE : "\'"}
var CharKeys = {KEY_A : "a",
				KEY_B : "b",
				KEY_C : "c",
				KEY_D : "d",
				KEY_E : "e",
				KEY_F : "f",
				KEY_G : "g",
				KEY_H : "h",
				KEY_I : "i",
				KEY_G : "g",
				KEY_H : "h",
				KEY_I : "i",
				KEY_J : "j",
				KEY_K : "k",
				KEY_L : "l",
				KEY_M : "m",
				KEY_N : "n",
				KEY_O : "o",
				KEY_P : "p",
				KEY_Q : "q",
				KEY_R : "r",
				KEY_S : "s",
				KEY_T : "t",
				KEY_U : "u",
				KEY_V : "v",
				KEY_W : "w",
				KEY_X : "x",
				KEY_Y : "y",
				KEY_Z : "z"}
					
# ============================================= # ============================================= #
# Init
# ============================================= # ============================================= #
func _ready():
	randomize() # Comment it to get same random each run
	
	# Generate array from HexTable
#	var hextmp = []
#	for chara in HexTable:
#		hextmp.append(chara)
#	HexTable = hextmp
	
	# Generate 1-byte characters array from a pool
	for i in " ~`1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()[]{}-_=+.,;:№\\/|<>'\"｡･｢｣ﾄﾐｴｮﾖﾛ☺☻ﾞﾘﾉ╔╦╗╠╬╣╚╩╝═║":
		Half.append(i)
	
	# Create ID : INDEX for flags for map load function
	Index.resize(256)
	for key in Flags:
		Index[int(Flags[key][3])] = key

	# ID: [RGB, RAW]
	for key in Legacy:
		Legacy[key] = [ARR2COL(Legacy[key]), RGB2RAW(Legacy[key])]
	
	# Adds raw colors to Flags
	# ID: [RGB, RAW, MARKER]
	for key in Flags:
		Flags.get(key)[0] = ARR2COL(Flags.get(key)[0])
		Flags.get(key)[1] = RGB2RAW(Flags.get(key)[0])
		Flags.get(key)[2] = RGB2RAW(Flags.get(key)[2])
	
	# Convert Pallet to Dictionary of
	# ID: [RGB, RAW]
	var pal = {}
	for key in Pallet.size():
		pal[RGB2HEX(Pallet[key])] = [ARR2COL(Pallet[key]), RGB2RAW(Pallet[key])]
	Pallet = pal
	
	# Clear actions history
	for i in hSize:
		History.append(null)
	
	# Noise map
	var noisesrc = File.new()
	noisesrc.open("res://noise.tres", noisesrc.READ)
	var noise = noisesrc.get_as_text()
	noisesrc.close()
	noise = noise.split("\n")
	for i in noise.size():
		Noise.append(noise[i].split_floats(","))

# ============================================= # ============================================= #
# Always
# ============================================= # ============================================= #
func _process(delta):
	# Update mouse coordinates each tick
	mpos = get_viewport().get_mouse_position()

# ============================================= # ============================================= #
# Generates random integer from 0 to X or from 1 to X
# ============================================= # ============================================= #
func R(num, zero=true):
	if !num:
		return 0
	if zero:	# 0...num
		return randi() % num
	else:		# 1...num
		return randi() % num + 1

# ============================================= # ============================================= #
# Returns true if probabilyty (P = 0…100) hits
# ============================================= # ============================================= #
func P(num):
	return bool(num >= randi() % 100 + 1)

# ============================================= # ============================================= #
# Pick array random element
# ============================================= # ============================================= #
func ARR(arr):
	return arr[R(arr.size())]

# ============================================= # ============================================= #
# Prints content of a variable for debug
# ============================================= # ============================================= #
func Print(arg):
	var result
	if typeof(arg) == TYPE_ARRAY:
		result = ""
		for y in arg.size():
			var line = ""
			for x in arg[y].size():
				line += str(arg[y][x])
			result += line + "\n"
	else:
		result = arg
	print(result)	# [!] NOT temporary print

# ============================================= # ============================================= #
# Functions for safe symbol and color assignment (throw error if x or y out of range)
# ============================================= # ============================================= #
func LOC(x=g.snap.x, y=g.snap.y, ch=" "):
	if !x in range(0, g.size.x * 2):
		Print(str("X out of range in row ", y))
		return
	Location[y][x] = ch

func COL(x=g.snap.x, y=g.snap.y, cl=g.c):
	if !x in range(0, g.size.x * 2):
		Print(str("X out of range in row ", y))
		return
	ColArray[y][x] = cl

# ============================================= # ============================================= #
# Fix out of bounds values for snap.x and snap.y
# ============================================= # ============================================= #
func Restrict():
	if snap.x < 0: snap.x = 0
	elif snap.x > size.x * 2 - 1: snap.x = size.x * 2 - 1
	if snap.y < 0: snap.y = 0
	elif snap.y > size.y - 1: snap.y = size.y - 1
	
# ============================================= # ============================================= #
# Character check (takes string or [x,y] of Location array)
# First compare to catalog, then double check via utf8 size
# ============================================= # ============================================= #
func IsHalf(x, y=0):
	if typeof(x) == TYPE_STRING:
		return int(x in Half or x.to_utf8().size() == 1)
	elif x in range(0, size.x * 2) and y in range(0, size.y):
		return int(Location[y][x] in Half or Location[y][x].to_utf8().size() == 1)
	
func IsFull(x, y=0):
	if typeof(x) == TYPE_STRING:
		return 1 - int(x in Half or x.to_utf8().size() == 1)
	elif x in range(0, size.x * 2) and y in range(0, size.y):
		return 1 - int(Location[y][x] in Half or Location[y][x].to_utf8().size() == 1)

func IsNull(x, y=0):
	if typeof(x) == TYPE_STRING:
		return int(x == "")
	elif x in range(0, size.x * 2) and y in range(0, size.y):
		return int(Location[y][x] == "" or Location[y][x] == null)

func IsEven(num):
	return 1 - int(fmod(num, 2))

func IsOdd(num):
	return int(fmod(num, 2))

func IsEqual(op1, op2):
	if typeof(op1) == typeof(op2) and op1 == op2:	# Exception different data types
		return 1
	return 0

func IsIndex(value):
	if str(value).is_valid_integer() and int(value) in range(0, 256):
		return true
	return false	
	
# ============================================= # ============================================= #
# Check if node is hovered
# ============================================= # ============================================= #
func IsHover(obj, offset=Vector2(0, 0)):
	var pos = obj.get_global_transform_with_canvas().get_origin() + offset
	if g.mpos.x in range(pos.x, pos.x + obj.get_size().x) && \
	g.mpos.y in range(pos.y, pos.y + obj.get_size().y):
		return true

# ============================================= # ============================================= #
# Revert param
# ============================================= # ============================================= #
func Toggle(par):
	if par == "bias":
		bias = 1 - bias
	if par == "mode":
		mode = !mode
	if par == "mark":
		mark = !mark
	if par == "grid":
		grid = !grid
		g.root.Grid.set_visible(grid)
	if par == "hold":
		hold = !hold
	if par == "diff":
		diff = !diff
	if par == "pick":
		pick = 1 - pick
	if par == "warp":
		warp = 1 - warp
	if par == "dots":
		dots = !dots
	if par == "lock":
		lock = !lock
	if par == "seaslbl":
		root.Season.get_node("Label").set("custom_colors/font_color", Color(.3,.3,.3))
		root.Season.get_node("Label").set_text("[Procedural OFF]")
		root.DrawMap()
		if root.SeasonLock.is_pressed():
			root.Season.get_node("Label").set("custom_colors/font_color", Color(1,1,1))
			root.Season.get_node("Label").set_text("1[←][→] 30[↑][↓]")

# ============================================= # ============================================= #
# [AA, AB, AC] -> "AA;AB;AC" (with del == ";")
# ============================================= # ============================================= #
func ARR2STR(arr, del=","):
	var string = ""
	for i in arr:
		string += i + del
	return string.trim_suffix(del)

# ============================================= # ============================================= #
# [255, 255, 255] -> Color(255, 255, 255)
# ============================================= # ============================================= #
func ARR2COL(arr):
	if arr.size() == 3:
		return Color(arr[0], arr[1], arr[2])
	return Color(1, 0, 0)

# ============================================= # ============================================= #
# Color(1.0, 1.0, 1.0) -> Color(255, 255, 255)
# ============================================= # ============================================= #
func RAW2RGB(raw):
	return Color(round(raw.r * 255.0), round(raw.g * 255.0), round(raw.b * 255.0))

# ============================================= # ============================================= #
# [1.0, 1.0, 1.0] -> #FFF / #FFFFFF
# ============================================= # ============================================= #
func RAW2HEX(raw, short=false):
	return str("#", raw.to_html(false))
		
# ============================================= # ============================================= #
# [255, 255, 255] -> #FFF / #FFFFFF
# ============================================= # ============================================= #
func RGB2HEX(rgb, short=false):
	var hex = "#"
	for i in 3:	# for r, g anb b
		if short:
			hex += HexTable[round((rgb[i]) / 16)]
		else:
			var cent = floor((rgb[i]) / 16)
			hex += HexTable[cent]
			hex += HexTable[fmod(rgb[i], 16)]
	return hex

# ============================================= # ============================================= #
# #FFF / #FFFFFF -> Color(255, 255, 255)
# ============================================= # ============================================= #
func HEX2RGB(hex):
	var rgb = Color(0, 1, 1)
	if hex.left(1) == "#" or hex.left(2) == "0x":
		hex = hex.lstrip("#").trim_prefix("0x")
		if hex.length() == 3:
			rgb.r = HexTable.find(hex.substr(0, 1).to_upper()) * 16 + HexTable.find(hex.substr(1, 1).to_upper())
			rgb.g = HexTable.find(hex.substr(1, 1).to_upper()) * 16 + HexTable.find(hex.substr(1, 1).to_upper())
			rgb.b = HexTable.find(hex.substr(2, 1).to_upper()) * 16 + HexTable.find(hex.substr(1, 1).to_upper())
		if hex.length() == 6:
			rgb.r = HexTable.find(hex.substr(0, 1).to_upper()) * 16 + HexTable.find(hex.substr(2, 1).to_upper())
			rgb.g = HexTable.find(hex.substr(2, 1).to_upper()) * 16 + HexTable.find(hex.substr(4, 1).to_upper())
			rgb.b = HexTable.find(hex.substr(4, 1).to_upper()) * 16 + HexTable.find(hex.substr(6, 1).to_upper())
	return rgb

# ============================================= # ============================================= #
# #FFF / #FFFFFF -> Color(1, 1, 1)
# ============================================= # ============================================= #
func HEX2RAW(hex):
	return Color(hex)
	
# ============================================= # ============================================= #
# [255, 255, 255] / Color(255, 255, 255) -> Color(1, 1, 1)
# ============================================= # ============================================= #
func RGB2RAW(rgb):
	var raw = Color(1, 0, 0)
	if typeof(rgb) == TYPE_COLOR or typeof(rgb) == TYPE_ARRAY and rgb.size() == 3:
		raw = Color(rgb[0]/255.0, rgb[1]/255.0, rgb[2]/255.0)
	return raw
	
# ============================================= # ============================================= #
# Get color index and return raw color if there is match
# ============================================= # ============================================= #
func ID2RAW(index):
	if typeof(index) != TYPE_STRING:
		return Color(1, 0, 1)
	var raw
	if Flags.get(index):
		raw = Flags.get(index)[1]
	elif Legacy.get(index):
		raw = Legacy.get(index)[1]
	elif Pallet.get(index):
		raw = Pallet.get(index)[1]
	else:
		raw = HEX2RAW(index)
	return raw

# ============================================= # ============================================= #
# Mix 2 colors with ratio of g.mix
# ============================================= # ============================================= #
func Mix(col1, col2):
	return Color(col1.r * (1 - g.mix) + col2.r * g.mix,
				 col1.g * (1 - g.mix) + col2.g * g.mix,
				 col1.b * (1 - g.mix) + col2.b * g.mix)
				
# ============================================= # ============================================= #
# Update label and redraw map
# ============================================= # ============================================= #
func Season(arg=DAY):
	var sea = ["Winter", "Spring", "Summer", "Autumn"]
	DAY = arg
	root.DayStat()
	root.Season.get_child(0).set_text(str(fmod(arg, 30) + 1, " day of ", sea[floor(arg/30)]))
	root.DrawMap(true)

# ============================================= # ============================================= #
# Automatic screen capture for each day in order (Winter 1 to Autumn 30)
# ============================================= # ============================================= #
func StartCapture():
	root.SeasonLock.set_pressed(true)
	root.SeasonLock.set_disabled(true)
	Toggle("seaslbl")
	root.Season.set_editable(false)
	
	var sea = ["Winter", "Spring", "Summer", "Autumn"]
	var title = ProjectSettings.get_setting("application/config/name")
	if area: title += " - " + area
	
	lock = true
	root.Picker.get_child(0).set_disabled(true)
	OS.set_window_title(str(title, "     [hold >Esc< to cancel]"))
	
	var dir = Directory.new()
	#var path = ProjectSettings.globalize_path(dir.get_current_dir())
	var path = OS.get_executable_path().get_base_dir().replace("\\", "/") + "/"
	dir.open(path)
	path += "Timelapse/"
	dir.make_dir(path)

	var capture
	var timeout = 0.25	# Delay between frames, 0.25 takes ~30s total
	if grid: Toggle("grid")
	if dots: Toggle("dots")
	for i in 120:
		if Input.is_action_pressed("ui_cancel"):
			lock = false
			root.Picker.get_child(0).set_disabled(false)
			OS.set_window_title(title)
			break
		DAY = i
		root.DayStat()
		root.Season.get_child(0).set_text(str(fmod(DAY, 30) + 1, " day of ", sea[floor(DAY/30)]))
		root.Season.set_value(DAY)
		root.DrawMap(true)
		yield(get_tree().create_timer(timeout), "timeout")	# Increase if shooting too fast
		capture = get_viewport().get_texture().get_data()
		capture.flip_y()
		capture.crop(910, 600)
		capture.save_png(str(path, "day", "00".left(3 - str(DAY).length()), DAY, ".png"))
	
	lock = false
	root.Picker.get_child(0).set_disabled(false)
	OS.set_window_title(title)
	
	root.Season.set_editable(true)
	Toggle("seaslbl")
	root.SeasonLock.set_disabled(false)

# ============================================= # ============================================= #
# Save screenshot as PNG to appdata
# ============================================= # ============================================= #
func Capture():
	var capture = get_viewport().get_texture().get_data()
	var path = OS.get_executable_path().get_base_dir().replace("\\", "/") + "/"
	var time = str(	"0".trim_prefix(str(int(OS.get_time().hour < 10))), OS.get_time().hour, "",
					"0".trim_prefix(str(int(OS.get_time().minute < 10))), OS.get_time().minute, "",
					"0".trim_prefix(str(int(OS.get_time().second < 10))), OS.get_time().second)
	var nick = "SCR_" + time
	if area: nick = g.area + " [" + time + "]"
	capture.flip_y()
	capture.crop(910, 600)
	capture.save_png(str(path, nick, ".png"))

# ============================================= # ============================================= #
# Get color in format #FFFFFF and return 0xFFFFFF
# ============================================= # ============================================= #
func Num20x(string):
	return string.replace("#", "0x")

# ============================================= # ============================================= #
# Export txt file with array content
# ============================================= # ============================================= #
func DebugExport(array, fname="debug"):
	var file = File.new()
	file.open(str("D:\\Myrmex\\Desktop\\" + str(fname) + ".txt"), File.WRITE)
	file.store_line(str(array))
	file.close()
