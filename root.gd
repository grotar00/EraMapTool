# ============================================= # ============================================= #
# UI GENERATION, I/O PROCESSING, MAP EDITING
# ============================================= # ============================================= #
extends Control

# Declaring nodes - UI elements
onready var BG = $BG
onready var Map = $Map
onready var Tin = $TEInput
onready var Tout = $TEOutput
onready var Tera = $TEEmuera
onready var MapName = $MapNameBox/MapName
onready var Lock = $Lock
onready var BMark = $BrushMarker
onready var CMark = $ColorMarker
onready var Pointers = $Pointers
onready var Palette = $PALETTE
onready var Menu = $MENU
onready var Jar = $JAR/TBrushes
onready var Grid = $Grid
onready var Season = $Season
onready var SeasonLock = $Season/Lock
onready var Debug = $Debug
onready var Godot = $Godot
onready var Discord = $Discord
onready var fps = $FPS
# Declaring nodes - Data control buttons
onready var Hide = $Hide/Button
onready var IClear = $IO/IClear
onready var ILoad = $IO/ILoad
onready var IClip = $IO/IClip
onready var OSave = $IO/OSave
onready var OExpo = $IO/OExpo
onready var OLoad = $IO/OLoad
onready var OClip = $IO/OClip
onready var ESave = $IO/ESave
onready var EExpo = $IO/EExpo
onready var EFunc = $IO/EFunc
onready var EClip = $IO/EClip

# Initializing node templates
var pointer = preload("res://pointer.tscn")			# Row/column pointers
var color_sample = preload("res://color.tscn")		# Color sample
var color_text = preload("res://color_text.tscn")	# Label inside color sample
var color_picker = preload("res://picker.tscn")		# Color picker
var Picker	# Placeholder for color picker node when its spawned

var doubleClicked = [false, false]	# 0 is reset each tick, 1 within Transcribe block
var exChara = [[],[]]	# Temp for last symbol input (rewrites on LMB)
var exColor = [[],[]]	# Temp for last color input (rewrites on RMB)

var VirtualClipboard	# Multipurpose buffer

# ============================================= # ============================================= #
# Procedural generation samples
# 				 Winter				 Spring				 Summer				 Autumn				 Snow
var foliage_l = [Color( 90, 75, 30), Color(160,210,100), Color( 80,180, 90), Color(180,150, 30), Color(255,255,255)]
var foliage_n = [Color( 75, 60, 20), Color(130,180, 80), Color( 50,160, 70), Color(150,110, 20), Color(235,235,235)]
var foliage_d = [Color( 60, 45, 15), Color(100,150, 60), Color( 35,140, 50), Color(120, 70, 15), Color(210,210,210)]
var foliage_s = [Color( 45, 30, 10), Color( 60,120, 40), Color(  0,100, 30), Color( 60, 40, 10), Color(150,150,150)]
var bamboo_l = [Color( 90, 75, 30), Color(120,120,  0), Color(100,140, 75), Color(140,140, 60), Color(255,255,255)]
var bamboo_n = [Color( 75, 60, 20), Color( 75, 75,  0), Color( 80,100, 60), Color(100,100, 45), Color(235,235,235)]
var bamboo_d = [Color( 60, 45, 15), Color( 45, 45,  0), Color( 50, 60, 45), Color( 70, 70, 30), Color(210,210,210)]
var bamboo_s = [Color( 45, 30, 10), Color( 20, 20,  0), Color( 20, 30, 15), Color( 40, 40, 15), Color(150,150,150)]
var sakura_l = [Color( 50, 30, 20), Color(240,150,200), Color(100, 60, 90), Color( 90, 75, 50), Color(255,255,255)]
var sakura_n = [Color( 40, 25, 15), Color(210,100,150), Color( 80, 40, 70), Color( 75, 60, 40), Color(235,235,235)]
var sakura_d = [Color( 30, 20, 10), Color(160, 60,100), Color( 60, 30, 55), Color( 60, 45, 30), Color(210,210,210)]
var sakura_s = [Color( 20, 10,  5), Color( 90, 40, 60), Color( 40, 20, 35), Color( 45, 30, 20), Color(150,150,150)]
var shrooms = [".:", "･:", ":.", ":･", ".･", "･.", "｡･", "｡･", "∴", "∵"]
var shroomc = ["#909", "#603", "#900", "#630", "#930", "#FC3"]
var leavess = ["、", "` ", " `", "´", "' ", " '", ", ", " ,"]
var leavesc = ["#960", "#C60", "#F60", "#FC3", "#630"]
var petalsc = ["#F9C", "#F6C", "#F9F"]
var liliess = ["○", "｡ ", " ｡", "o ", "o ", " o", " o", "о", "о"]
var liliesc = ["#093", "#090", "#390"]
var ripples = ["～", "~ ", " ~", "∽", "ー", "- ", " -"]
var ripplec = ["#479", "#368", "#257", "#146"]
var puddles = ["○", "◎"]
var glaciac = ["#FFF", "#EEE", "#DDD"] 
var flowers = ["ρ", "ρ", "ρ", "ф", "ф", "＊", "γ"]
var flowerc = ["#FF9", "#FFF", "#FFF", "#60F", "#909", "#F39", "#F33"]

# Convert data above to raw format
func FlagsAssets2Raw():
	for i in 5:
		foliage_s[i] = g.RGB2RAW(foliage_s[i])
		foliage_d[i] = g.RGB2RAW(foliage_d[i])
		foliage_n[i] = g.RGB2RAW(foliage_n[i])
		foliage_l[i] = g.RGB2RAW(foliage_l[i])
		bamboo_s[i] = g.RGB2RAW(bamboo_s[i])
		bamboo_d[i] = g.RGB2RAW(bamboo_d[i])
		bamboo_n[i] = g.RGB2RAW(bamboo_n[i])
		bamboo_l[i] = g.RGB2RAW(bamboo_l[i])
		sakura_s[i] = g.RGB2RAW(sakura_s[i])
		sakura_d[i] = g.RGB2RAW(sakura_d[i])
		sakura_n[i] = g.RGB2RAW(sakura_n[i])
		sakura_l[i] = g.RGB2RAW(sakura_l[i])
	for i in shroomc.size():
		shroomc[i] = g.HEX2RAW(shroomc[i])
	for i in leavesc.size():
		leavesc[i] = g.HEX2RAW(leavesc[i])
	for i in petalsc.size():
		petalsc[i] = g.HEX2RAW(petalsc[i])
	for i in liliesc.size():
		liliesc[i] = g.HEX2RAW(liliesc[i])
	for i in glaciac.size():
		glaciac[i] = g.HEX2RAW(glaciac[i])
	for i in flowerc.size():
		flowerc[i] = g.HEX2RAW(flowerc[i])
	for i in ripplec.size():
		ripplec[i] = g.HEX2RAW(ripplec[i])
		
# ============================================= # ============================================= #
# Init
# ============================================= # ============================================= #
func _ready():
	g.root = self
	Picker = color_picker.instance()
	
	# Show notification for web version
	if g.WEB:
		Tin.text = "Input JSON／ERACODE"
		OExpo.disabled = true
		EExpo.disabled = true
		
		g.lock = true
		Hide.disabled = true
		var warningPan = Panel.new()
		var warningLbl = Label.new()
		var warningBtn = Button.new()
		warningPan.rect_size = Vector2(360,120)
		warningPan.rect_position = Vector2(520 - 180, 320 - 60)
		warningLbl.rect_size = Vector2(350,90)
		warningLbl.rect_position = Vector2(5, 5)
		warningLbl.text = str(	"This is experimental browser version of Era Map Tool.\n",
								"Please consider that most controls rely on use of RMB and ",
								"may conflict with enabled mouse gestures.\nAlso make sure ",
								"you've opened this editor in new tab so progress won't be ",
								"lost if you press back accidently.")
		warningLbl.autowrap = true
		warningBtn.rect_size = Vector2(100,20)
		warningBtn.rect_position = Vector2(130, 95)
		warningBtn.text = "OK, thanks"
		warningPan.add_child(warningLbl)
		warningPan.add_child(warningBtn)
		warningBtn.connect("pressed", g, "Toggle", ["lock"])
		warningBtn.connect("pressed", warningPan, "queue_free")
		add_child(warningPan)		
		
	get_tree().connect("files_dropped", self, "DragAndDrop")
	Tin.connect("mouse_exited", Tin, "deselect")
	Tin.connect("mouse_exited", Tin, "release_focus")
	Hide.connect("toggled", self, "TransformWindow")
	IClear.connect("pressed", Tin, "set_text", [""])
	ILoad.connect("pressed", self, "LoadData", ["input"])
	IClip.connect("pressed", self, "ClipData", ["input"])
	OSave.connect("pressed", self, "SaveData", ["output"])
	OExpo.connect("pressed", self, "ExportData", ["output"])
	OLoad.connect("pressed", self, "LoadData", ["output"])
	OClip.connect("pressed", self, "ClipData", ["output"])
	ESave.connect("pressed", self, "SaveData", ["era"])
	EExpo.connect("pressed", self, "ExportData", ["era"])
	EFunc.connect("pressed", self, "PrintMap")
	EClip.connect("pressed", self, "ClipData", ["era"])
	MapName.connect("text_changed", self, "RenameArea")
	MapName.get_parent().connect("mouse_exited", MapName, "deselect")
	MapName.get_parent().connect("mouse_exited", MapName, "release_focus")
	Season.connect("value_changed", g, "Season", [])
	Season.connect("mouse_exited", Season, "release_focus")
	Discord.connect("pressed", OS, "shell_open", ["https://discord.gg/7MAArwP"])
	Godot.connect("pressed", OS, "shell_open", ["https://godotengine.org"])
	SeasonLock.connect("toggled", Season, "set_editable", [])
	SeasonLock.connect("pressed", g, "Toggle", ["seaslbl"])	
	
#	Map.set("custom_colors/font_data/antialiased", false)
#	Map.set("custom_colors/font_data/use_filter", true)
#	Map.set("custom_colors/font_data/use_filter", false)
	
	FlagsAssets2Raw()
	ResetArrays()
	ResetColors()
	GeneratePointers()
	GenerateColors()
	GenerateControls()
	ShrinkMarker()
	DrawMap()
	Transcribe()
	SaveReminder()
	g.Toggle("seaslbl")
	Jar.ParseMatch(g.b)
	
# ============================================= # ============================================= #
# Control
# ============================================= # ============================================= #
func _input(event):
	if !Jar.has_focus():
		if Input.is_action_just_pressed("pick"):		# Alt down
			g.pick = 1
			GeneratePointers()
		elif Input.is_action_just_released("pick"):		# Alt up
			g.pick = 0
			GeneratePointers()
		if Input.is_action_just_pressed("bias") and	\
		!g.draw and !g.line:							# Shift down
			g.bias = 1
			if !g.drag:
				Menu.get_node("bias").set_pressed(g.bias)
				GeneratePointers()
		elif Input.is_action_just_released("bias"):		# Shift up
			g.bias = 0
			if !g.drag:
				Menu.get_node("bias").set_pressed(g.bias)
				GeneratePointers()
		if Input.is_action_just_pressed("warp"):		# Ctrl down
			g.warp = 1
			GeneratePointers()
		elif Input.is_action_just_released("warp"):		# Ctrl up
			g.warp = 0
			GeneratePointers()
		if Input.is_action_just_pressed("mode"):		# Space
			g.mode = !g.mode	
			Menu.get_node("mode").set_pressed(g.mode)
		if Input.is_action_just_pressed("select_space"):# Ctrl+Q
			if g.IsHalf(g.b):
				Jar.ParseMatch("　")
			else:
				Jar.ParseMatch(" ")
		if Input.is_action_just_pressed("undo"):		# Ctrl+Z
			Undo()
		if Input.is_action_just_pressed("redo"):		# Alt+Z
			Redo()
		if Input.is_action_just_pressed("iopanel"):		# Tab
			if !g.WEB: Hide.set_pressed(!Hide.is_pressed())
		if Input.is_action_just_pressed("fps_counter"):	# Ctrl+= / =
			fps.set_visible(!fps.is_visible())
		if Input.is_action_just_released("grid_fade"):	# Alt+G
			var gmod = Grid.get_modulate()
			Grid.set_modulate(gmod + Color(0,0,0,.025))
			if gmod.a > .07:
				Grid.set_modulate(Color(1,1,1,.03))
		if Input.is_action_just_released("timelapse"):	# Alt+O
			g.StartCapture()
		if Input.is_action_just_pressed("diff"):		# Ctrl+D / F1
			g.Toggle("diff")
			Menu.get_node("diff").set_pressed(g.diff)
		if Input.is_action_just_pressed("hold"):		# Ctrl+H / F2
			g.Toggle("hold")
			Menu.get_node("hold").set_pressed(g.hold)
		if Input.is_action_just_pressed("mark"):		# Ctrl+F / F3
			g.Toggle("mark")
			Menu.get_node("mark").set_pressed(g.mark)
		if Input.is_action_just_pressed("grid"):		# Ctrl+G / F4
			g.Toggle("grid")
			Menu.get_node("grid").set_pressed(g.grid)
		if Input.is_action_just_pressed("fix_array"):	# Ctrl+U
			FixArray()
		if Input.is_action_just_pressed("capture"):		# Ctrl+P
			g.Capture()
		if Input.is_action_just_pressed("export_era"):	# Ctrl+E
			ExportData("era")
		if Input.is_action_just_pressed("export_json"):	# Ctrl+S
			ExportData("output")
		if Input.is_action_just_pressed("pick_default"):# Ctrl+W
			g.c = "def"
			g.emit_signal("select_colors")
		if Input.is_action_just_pressed("minimize"):	# Ctrl+R
			OS.set_window_minimized(true)
		if Input.is_action_just_pressed("draw_shape"):	# Ctrl+A
			if !g.draw:
				g.draw = "rect"
			elif g.draw == "rect":
				g.draw = "fill"
			elif g.draw == "fill":
				g.draw = null
				g.emit_signal("destroy_previews")
			TintCursor(true)
		if Input.is_action_just_pressed("print_map"):	# Ctrl+M
			PrintMap()
		if Input.is_action_just_pressed("za_warudo"):	# Ctrl+I
			g.timestop = !g.timestop
			DrawMap(false, true)
		if Input.is_action_just_pressed("show_spaces"):	# Ctrl+B
			g.Toggle("dots")
			DrawMap()
		if Input.is_action_just_pressed("DEBUG"):
			pass
	
	if Input.is_action_pressed("scroll_down") and !g.IsHover(Jar) and g.mpos.x < 1080:
		g.ncol += 1
		if g.ncol >= g.Pallet.size() + g.Flags.size() + 1:
			g.ncol = 0
		g.emit_signal("rotate_colors")
	elif Input.is_action_pressed("scroll_up") and !g.IsHover(Jar) and g.mpos.x < 1080:
		g.ncol -= 1
		if g.ncol < 0:
			g.ncol = g.Pallet.size() + g.Flags.size()
		g.emit_signal("rotate_colors")
			
	if event is InputEventMouseButton and event.doubleclick:
		doubleClicked[0] = true
		doubleClicked[1] = true
		
	if event is InputEventKey and event.pressed and !MapName.has_focus() and !g.lock and !g.warp:
		var ev = event.scancode
		if ev in g.DigiKeys:
			Jar.ParseMatch(g.DigiKeys[ev])
		elif ev in g.CharKeys:
			if !g.pick and !g.bias:
				Jar.ParseMatch(g.CharKeys[ev])
			elif !g.pick:
				Jar.ParseMatch(g.CharKeys[ev].to_upper())
		elif ev in g.FramNarr:
			Jar.ParseMatch(g.FramNarr[ev])
	
	if Season.is_editable():
		if Input.is_action_pressed("ui_left"):
			g.DAY -= 1
			if g.DAY < 0:
				g.DAY = 119
			g.Season(g.DAY)
			Season.value = g.DAY
		if Input.is_action_pressed("ui_right"):
			g.DAY += 1
			if g.DAY > 119:
				g.DAY = 0
			g.Season(g.DAY)
			Season.value = g.DAY
		if Input.is_action_just_pressed("ui_up"):
			var sea = floor(g.DAY/30)
			if sea == 3: sea = -1
			g.DAY = (sea + 1) * 30
			g.Season(g.DAY)
			Season.value = g.DAY
		if Input.is_action_just_pressed("ui_down"):
			var sea = floor(g.DAY/30)
			if sea == 0: sea = 4
			g.DAY = (sea - 1) * 30
			g.Season(g.DAY)
			Season.value = g.DAY
	
# ============================================= # ============================================= #
# Always
# ============================================= # ============================================= #
func _process(delta):
	UpdateFPS()
	BMark.set_visible(false)	# Unhide cell marker
	# [!!!] Define coordinates of highlighted cell
	g.snap = Vector2(floor((g.mpos[0] - 12) / (g.step / 2)), floor((g.mpos[1] - 9) / g.step))
	g.Restrict()	# Solve out of bounds issue for g.snap
	Debug.set_text(str(g.snap.x, ":", g.snap.y))
	
	if g.select:
		SelectShape()
		if !g.IsHover(Lock, Vector2(-1, +1)):
			g.emit_signal("destroy_previews")
			g.lock = false
			g.select = null
		return
	elif g.drag:
		MoveRegion()
		return

	if g.IsHover(Tin) and Input.is_action_just_pressed("left_click"):
		Tin.select_all()
	
	if g.IsHover(Picker) and Input.is_action_just_pressed("left_click"):
		Picker.Activate()
	
	if Season.has_focus():
		return
		
	if !g.IsHover(Lock) or g.bias and (g.snap.x == 0 or g.snap.x == g.size.x * 2 - 1):
		Debug.set_text(str("-:-"))
		if g.line or g.draw or g.select:
			g.emit_signal("destroy_previews")
			g.line = null
			g.draw = null
	else:
		if Input.is_action_just_released("left_click") or Input.is_action_just_released("right_click") or \
		Input.is_action_just_released("middle_click"):
			if !g.lock:
				SaveReminder(1)
				Transcribe()
				MergeSpaces()
				if doubleClicked[1]:
					g.History.remove(1)
					g.History.push_back(null)
					doubleClicked[1] = false
			elif g.queue_unlock:
				g.lock = false
				
		if !g.lock:
			BMark.set_position(Vector2((g.snap.x + 1 + int(g.IsHalf(g.b)) + (fmod(g.snap.x + 1 - g.bias, 2.0)) * \
			int(!g.IsHalf(g.b))) * g.step/2, g.snap.y * g.step + g.step) + Vector2(-3, -6))
			ShrinkMarker()
			BMark.set_visible(true)
			
			if !g.warp:
				if Input.is_action_just_pressed("back_click"):
					g.last = g.snap
					if !g.IsHalf(g.b) and fmod(g.last.x, 2) != g.bias:
						g.last.x -= 1
					g.lock = true
					g.select = true		
					SelectShape()
				elif Input.is_action_just_pressed("forth_click"):
					g.last = g.snap
					if !g.IsHalf(g.b) and fmod(g.last.x, 2) != g.bias:
						g.last.x -= 1
					g.line = true
					DrawShape("line")
					TintCursor()
					return
				
			if g.draw:
				DrawShape(g.draw)
				return
			elif g.line:
				DrawShape("line")
				return
			
			if Input.is_action_just_pressed("left_click") or Input.is_action_just_pressed("right_click"):
				if g.Location[g.snap.y][g.snap.x]:
					exChara.push_front(g.Location[g.snap.y][g.snap.x])
				elif !g.Location[g.snap.y][g.snap.x]:
					exChara.push_front(g.Location[g.snap.y][g.snap.x - 1])
				exChara.pop_back()
				exColor.push_front(g.ColArray[g.snap.y][g.snap.x])
				exColor.pop_back()
			
			# ============================================= #
			# On left hold/click if not in pick mode
			if Input.is_action_pressed("left_click") and g.hold and !g.pick and !g.warp or Input.is_action_just_pressed("left_click"):		
				if doubleClicked[0] and !g.warp:
					Undo() # Neglect single click before double click
					# For each cell in array
					for row in g.Location.size():
						for col in g.Location[row].size() - 1 + g.IsHalf(g.b):
							# If symbol match AND (full match mode [off] OR color match)
							if !g.IsNull(col, row) and g.IsEqual(g.Location[row][col], exChara[1]) and \
							(g.diff or !g.diff and g.IsEqual(g.ColArray[row][col], exColor[1])):
								# A space appears when replacing 2B with 1B, draw another 1B instead
								if g.IsHalf(g.b) and g.IsFull(g.Location[row][col]):
									Draw(col + 1, row)
									if g.mode:
										Colour(col + 1, row)
								Draw(col, row)
								if g.mode:
									Colour(col, row)
					DrawMap()
				elif g.warp and g.snap.x < g.size.x * 2 - 2:
					var nextNull = int(!bool(g.Location[g.snap.y][g.snap.x + 1]))
					if g.IsHalf(g.b) and g.snap.x + nextNull < g.size.x * 2 - 2:
						# if last element is 2-byte symbol - free 2 cells
						if !g.Location[g.snap.y].back():
							g.Location[g.snap.y].pop_back()
							g.Location[g.snap.y].pop_back()
							g.Location[g.snap.y].push_back(" ")
							g.ColArray[g.snap.y].pop_back()
							g.ColArray[g.snap.y].pop_back()
							g.ColArray[g.snap.y].push_back("def")
						# otherwise free just 1 cell
						else:
							g.Location[g.snap.y].pop_back()
							g.ColArray[g.snap.y].pop_back()
						g.Location[g.snap.y].insert(g.snap.x - 1 + nextNull, " ")
						g.ColArray[g.snap.y].insert(g.snap.x - 1 + nextNull, "def")
					if !g.IsHalf(g.b) and g.snap.x + nextNull < g.size.x * 2 - 2:
						# if penult element is 2-byte symbol - free 3 cells
						if !g.Location[g.snap.y][-2]:
							g.Location[g.snap.y].pop_back()
							g.Location[g.snap.y].pop_back()
							g.Location[g.snap.y].pop_back()
							g.Location[g.snap.y].push_back(" ")
							g.ColArray[g.snap.y].pop_back()
							g.ColArray[g.snap.y].pop_back()
							g.ColArray[g.snap.y].pop_back()
							g.ColArray[g.snap.y].push_back("def")
						# otherwise free just 2 cell
						else:
							g.Location[g.snap.y].pop_back()
							g.Location[g.snap.y].pop_back()
							g.ColArray[g.snap.y].pop_back()
							g.ColArray[g.snap.y].pop_back()
						g.Location[g.snap.y].insert(g.snap.x - 1 + nextNull, "")
						g.Location[g.snap.y].insert(g.snap.x - 1 + nextNull, "　")
						g.ColArray[g.snap.y].insert(g.snap.x - 1 + nextNull, "def")
						g.ColArray[g.snap.y].insert(g.snap.x - 1 + nextNull, "def")
					DrawMap()
				elif g.pick:
					g.b = g.Location[g.snap.y][g.snap.x]
					if g.mode:
						g.c = g.ColArray[g.snap.y][g.snap.x]
						g.emit_signal("select_colors")
					if !g.b:
						g.b = g.Location[g.snap.y][g.snap.x - 1]
						if g.mode:
							g.c = g.ColArray[g.snap.y][g.snap.x - 1]
							g.emit_signal("select_colors")
						if !g.b:	# If two adjacent nulls due some bug - reset to single space
							g.b = " "
					Jar.Transcribe()
					Jar.ParseMatch()
				else:
					# Draw at x or at x - 1 if 2-byte symbol input at right half of highlighted cell
					Draw(g.snap.x - int(g.bias != fmod(g.snap.x, 2) and !g.IsHalf(g.b)))
					if g.mode:
						Colour(g.snap.x - int(g.bias != fmod(g.snap.x, 2) and !g.IsHalf(g.b)))
					DrawMap()
					
			# ============================================= #
			elif Input.is_action_pressed("right_click") and g.hold and !g.warp or Input.is_action_just_pressed("right_click"):				
				if doubleClicked[0] and !g.warp:
					Undo()
					# For each cell in array
					for row in g.ColArray.size():
						for col in g.ColArray[row].size() - 1 + g.IsHalf(g.b):
							# If color match AND (full match mode [off] OR symbol match)
							if !g.IsNull(col, row) and g.IsEqual(g.ColArray[row][col], exColor[1]) and \
							(g.diff or !g.diff and g.IsEqual(g.Location[row][col], exChara[1])):
								Colour(col, row)
				elif g.warp and g.snap.x < g.size.x * 2 - 1:
					var nextNull = int(!bool(g.Location[g.snap.y][g.snap.x + 1]))
					# FULL on FULL
					if g.IsFull(g.b) and g.IsFull(g.snap.x, g.snap.y):
						g.Location[g.snap.y].remove(g.snap.x)
						g.Location[g.snap.y].remove(g.snap.x)
						g.Location[g.snap.y].push_back("　")
						g.Location[g.snap.y].push_back("")
						g.ColArray[g.snap.y].remove(g.snap.x)
						g.ColArray[g.snap.y].remove(g.snap.x)
						g.ColArray[g.snap.y].push_back("def")
						g.ColArray[g.snap.y].push_back("def")
					#FULL on NULL
					elif g.IsFull(g.b) and g.IsNull(g.snap.x, g.snap.y):
						g.Location[g.snap.y].remove(g.snap.x - 1)
						g.Location[g.snap.y].remove(g.snap.x - 1)
						g.Location[g.snap.y].push_back("　")
						g.Location[g.snap.y].push_back("")
						g.ColArray[g.snap.y].remove(g.snap.x - 1)
						g.ColArray[g.snap.y].remove(g.snap.x - 1)
						g.ColArray[g.snap.y].push_back("def")
						g.ColArray[g.snap.y].push_back("def")
					# FULL ON HALF
					elif g.IsFull(g.b) and g.IsHalf(g.snap.x, g.snap.y):
						if g.IsHalf(g.snap.x + 1, g.snap.y):
							g.Location[g.snap.y].remove(g.snap.x)
							g.ColArray[g.snap.y].remove(g.snap.x)
							g.Location[g.snap.y].remove(g.snap.x)
							g.ColArray[g.snap.y].remove(g.snap.x)
							g.Location[g.snap.y].push_back("　")
							g.Location[g.snap.y].push_back("")
							g.Location[g.snap.y].push_back(" ")
							g.ColArray[g.snap.y].push_back("def")
							g.ColArray[g.snap.y].push_back("def")
							g.ColArray[g.snap.y].push_back("def")
						else:
							g.Location[g.snap.y].remove(g.snap.x)
							g.Location[g.snap.y].remove(g.snap.x)
							g.Location[g.snap.y].remove(g.snap.x)
							g.ColArray[g.snap.y].remove(g.snap.x)
							g.ColArray[g.snap.y].remove(g.snap.x)
							g.ColArray[g.snap.y].remove(g.snap.x)
							g.Location[g.snap.y].push_back("　")
							g.Location[g.snap.y].push_back("")
							g.ColArray[g.snap.y].push_back("def")
							g.ColArray[g.snap.y].push_back("def")						
					# HALF on FULL
					elif g.IsHalf(g.b) and g.IsFull(g.snap.x, g.snap.y):
						g.Location[g.snap.y][g.snap.x + 1] = " "
						g.Location[g.snap.y].remove(g.snap.x)
						g.Location[g.snap.y].push_back(" ")
						g.ColArray[g.snap.y][g.snap.x + 1] = "def"
						g.ColArray[g.snap.y].remove(g.snap.x)
						g.ColArray[g.snap.y].push_back("def")
					# HALF on NULL
					elif g.IsHalf(g.b) and g.IsNull(g.snap.x, g.snap.y):
						g.Location[g.snap.y][g.snap.x - 1] = " "
						g.Location[g.snap.y].remove(g.snap.x)
						g.Location[g.snap.y].push_back(" ")
						g.ColArray[g.snap.y][g.snap.x - 1] = "def"
						g.ColArray[g.snap.y].remove(g.snap.x)
						g.ColArray[g.snap.y].push_back("def")
					# HALF on HALF
					elif g.IsHalf(g.b):
						g.Location[g.snap.y].remove(g.snap.x)
						g.Location[g.snap.y].push_back(" ")
						g.ColArray[g.snap.y].remove(g.snap.x)
						g.ColArray[g.snap.y].push_back("def")
					DrawMap()
				elif g.pick:
					g.c = g.ColArray[g.snap.y][g.snap.x]
					g.emit_signal("select_colors")
				else:
					Colour(g.snap.x - int(g.bias != fmod(g.snap.x, 2) and !g.IsHalf(g.b)))
					DrawMap()
			
			# ============================================= #
			elif Input.is_action_pressed("middle_click") and g.hold or Input.is_action_just_pressed("middle_click"):
				var space
				if g.IsHalf(g.b):
					space = " "
					# Merge two half-spaces to a single space
					if g.Location[g.snap.y][g.snap.x + 1] == " " and g.bias != fmod(g.snap.x, 2) or \
					g.Location[g.snap.y][g.snap.x - 1] == " " and g.bias == fmod(g.snap.x, 2):
						space = "　"
				else:
					space = "　"
				Draw(g.snap.x - int(g.bias != fmod(g.snap.x, 2) and !g.IsHalf(g.b)), g.snap.y, space)
				Colour(g.snap.x - int(g.bias != fmod(g.snap.x, 2) and !g.IsHalf(g.b)), g.snap.y, "def")
				DrawMap()
			
			# ============================================= #
			elif Input.is_action_just_pressed("back_click") and g.warp:
				for y in range(g.snap.y, g.Location.size() - 1):
					# ?[D|0]?
					if !g.IsHalf(g.b) and g.bias == fmod(g.snap.x, 2):
						# ?[?|X]?
						if g.Location[y + 1][g.snap.x + 1]:
							Draw(g.snap.x + 1, y, g.Location[y + 1][g.snap.x + 1])
							Colour(g.snap.x + 1, y, g.ColArray[y + 1][g.snap.x + 1])
					# ?[?|D]0
					elif !g.IsHalf(g.b) and g.bias != fmod(g.snap.x, 2):
						# ?[X|?]?
						if g.Location[y + 1][g.snap.x - 1]:
							Draw(g.snap.x - 1, y, g.Location[y + 1][g.snap.x - 1])
							Colour(g.snap.x - 1, y, g.ColArray[y + 1][g.snap.x - 1])
						# D[0|?]?
						else:
							Draw(g.snap.x - 2, y, g.Location[y + 1][g.snap.x - 2])
							Colour(g.snap.x - 2, y, g.ColArray[y + 1][g.snap.x - 2])
					# ?[X]?
					if g.Location[y + 1][g.snap.x]:
						Draw(g.snap.x, y, g.Location[y + 1][g.snap.x])
						Colour(g.snap.x, y, g.ColArray[y + 1][g.snap.x])
					# D[0]?
					else:
						Draw(g.snap.x - 1, y, g.Location[y + 1][g.snap.x - 1])
						Colour(g.snap.x - 1, y, g.ColArray[y + 1][g.snap.x - 1])
				# Empty clicked cell
				if g.IsHalf(g.b):
					Draw(g.snap.x, g.size.y - 1, " ")
				else:
					Draw(g.snap.x, g.size.y - 1, "　")
				Colour(g.snap.x, g.size.y - 1, "def")
				
				Transcribe()
				DrawMap()
			
			# ============================================= #
			elif Input.is_action_just_pressed("forth_click") and g.warp:
				for y in range(g.Location.size() - 1, g.snap.y, -1):
					# ?[D|0]?
					if !g.IsHalf(g.b) and g.bias == fmod(g.snap.x, 2):
						# ?[?|X]?
						if g.Location[y - 1][g.snap.x + 1]:
							Draw(g.snap.x + 1, y, g.Location[y - 1][g.snap.x + 1])
							Colour(g.snap.x + 1, y, g.ColArray[y - 1][g.snap.x + 1])
					# ?[?|D]0
					elif !g.IsHalf(g.b) and g.bias != fmod(g.snap.x, 2):
						# ?[X|?]?
						if g.Location[y - 1][g.snap.x - 1]:
							Draw(g.snap.x - 1, y, g.Location[y - 1][g.snap.x - 1])
							Colour(g.snap.x - 1, y, g.ColArray[y - 1][g.snap.x - 1])
						# D[0|?]?
						else:
							Draw(g.snap.x - 2, y, g.Location[y - 1][g.snap.x - 2])
							Colour(g.snap.x - 2, y, g.ColArray[y - 1][g.snap.x - 2])
					# ?[X]?
					if g.Location[y - 1][g.snap.x]:
						Draw(g.snap.x, y, g.Location[y - 1][g.snap.x])
						Colour(g.snap.x, y, g.ColArray[y - 1][g.snap.x])
					# D[0]?
					else:
						Draw(g.snap.x - 1, y, g.Location[y - 1][g.snap.x - 1])
						Colour(g.snap.x - 1, y, g.ColArray[y - 1][g.snap.x - 1])
				# Empty clicked cell
				if g.IsHalf(g.b):
					Draw(g.snap.x, g.snap.y, " ")
				else:
					Draw(g.snap.x, g.snap.y, "　")
				Colour(g.snap.x, g.snap.y, "def")
				
				Transcribe()
				DrawMap()
	doubleClicked[0] = false

# ============================================= # ============================================= #
# Monitor window condition
# ============================================= # ============================================= #
func _notification(action):
	if action == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		if g.bias:	g.Toggle("bias")	
		if g.pick:	g.Toggle("pick")	# Prevent pick clipping on alt+tab 
	#elif action == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
	#    pass
		
# ============================================= # ============================================= #
# Save last action in history log
# ============================================= # ============================================= #
func Transcribe(pop=true):	# pop=true: pop last state, add new one		pop=false: rewrite first
	# If undid some actions - move current and consequent states to array beginning
	if g.hPos:	# If undoed - make current save slot a first one
		for i in g.hPos: 
			g.History.pop_front()
			g.History.push_back(null)
	# If state already stored in first slot - do nothing (click duplicating glitch)
	if g.History[0] and g.History[0][0] == g.Location and g.History[0][1] == g.ColArray:
		return
	# Copy character and color matrices
	var new = [g.Location.duplicate(true), g.ColArray.duplicate(true)]
	if pop:
		g.History.pop_back()
		g.History.push_front(new)
	else:
		g.History[0] = new
	g.hPos = 0

# ============================================= # ============================================= #
# Revert to previous map state stored in actions history
# ============================================= # ============================================= #
func Undo():
	g.hPos += 1
	if g.hPos >= g.hSize:
		g.hPos = g.hSize - 1
	elif !g.History[g.hPos]:
		g.hPos -= 1
		return
	g.Location = g.History[g.hPos][0].duplicate(true)
	g.ColArray = g.History[g.hPos][1].duplicate(true)
	DrawMap()

# ============================================= # ============================================= #
# Restore to newer map state stored in actions history
# ============================================= # ============================================= #
func Redo():
	g.hPos -= 1
	if g.hPos < 0:
		g.hPos = 0
	elif !g.History[g.hPos]:
		#g.hPos += 1
		return
	g.Location = g.History[g.hPos][0].duplicate(true)
	g.ColArray = g.History[g.hPos][1].duplicate(true)
	DrawMap()
	
# ============================================= # ============================================= #
# Generate buttons
# ============================================= # ============================================= #
func GenerateControls():
	var names = ["bias", "mode", "diff", "mark", "grid", "hold"]
	for i in range(0, names.size()):
		var ibutton = TextureButton.new()
		var hints = [	"[SHIFT] Bias draw (in between cells)",
						"[SPACE] Toggle color mode",
						"[F1][Ctrl+D] Match mode\nOFF - replace if symbol AND color match\nON - replace if symbol OR color match",
						"[F2][Ctrl+F] Highlights cells with assigned dynamic color",
						"[F3][Ctrl+G] Display grid for 2-byte space\n[Alt+G] Change grid opacity",
						"[F4][Ctrl+H] Toggle click/hold drawing"]
		ibutton.set_toggle_mode(true)
		ibutton.set_tooltip(hints[i])
		ibutton.set_name(names[i])
		ibutton.set_normal_texture(load(str("res://", names[i], "0.png")))
		ibutton.set_pressed_texture(load(str("res://", names[i], "1.png")))
		ibutton.connect("pressed", g, "Toggle", [names[i]])
		ibutton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		Menu.add_child(ibutton)
	
	Menu.get_node("bias").set_pressed(g.bias)
	Menu.get_node("mode").set_pressed(g.mode)
	Menu.get_node("diff").set_pressed(g.diff)
	Menu.get_node("hold").set_pressed(g.hold)
	Menu.get_node("mark").set_pressed(g.mark)
	Menu.get_node("grid").set_pressed(g.grid)

# ============================================= # ============================================= #
# Generate row/col pointers and x pointer
# ============================================= # ============================================= #
func GeneratePointers():
	g.emit_signal("destroy_pointers")
	var ipointer = pointer.instance()
	ipointer.get_child(0).set_text("X")
	ipointer.set_size(Vector2(10, 10))
	ipointer.set_position(Vector2(2, -2))
	ipointer.num = 0
	Pointers.add_child(ipointer)
	for i in range(1, g.size.x + 1 - g.bias):
		ipointer = pointer.instance()
		ipointer.get_child(0).set_text(str(i))
		ipointer.set_position(Vector2(i * g.step + g.bias * g.step/2, -2))
		ipointer.axisx = true
		ipointer.num = i
		g.connect("destroy_pointers", ipointer, "queue_free")
		Pointers.add_child(ipointer)
	for i in range(1, g.size.y + 1):
		ipointer = pointer.instance()
		ipointer.get_child(0).set_text(str(i))
		ipointer.set_position(Vector2(2, i * g.step - 5))
		ipointer.axisx = false
		ipointer.num = i
		g.connect("destroy_pointers", ipointer, "queue_free")
		Pointers.add_child(ipointer)

# ============================================= # ============================================= #
# Generate colors in palette from g.Pallet and g.Flags
# ============================================= # ============================================= #
func GenerateColors():
	var w = 10
	var h = 24
	var gap = 16
	var select = [0,0,w,0,w,h,0,h,0,0]
#	var frame = [0,0,w,0,w,h,w,h+1,w,h,0,h,0,0]
	var frame = [1,0,w-1,0,w-1,h-1,w-1,h,w-1,h-1,0,h-1,0,0] # Narrow
#	var frame = [-1,0,w,0,w,h,w,h+1,w,h,-1,h,-1,0] # Wide
	var hintc = Color(.1,.1,.1)
	var Special = {	"white" : "a",
					"def" : "0",
					"call" : "C",
					"debug" : "$",
					"floras" : "林",
					"florad" : "林",
					"floran" : "林",
					"floral" : "林",
					"bamboos" : "ﾄﾄ",
					"bambood" : "竹",
					"bamboon" : "竹",
					"bambool" : "竹",
					"sakuras" : "火",
					"sakurad" : "火",
					"sakuran" : "火",
					"sakural" : "火",
					"framed" : "□",
					"framen" : "□",
					"framel" : "□",
					"rocks" : "R",
					"rockd" : "R",
					"rockn" : "R",
					"rockl" : "R",
					"flower" : "Ф",
					"flowers" : "ф",
					"water" : "~\no",
					"tides" : "~\n~",
					"still" : "~\n-",
					"spray" : "∴",
					"steam" : "∫",
					"flame" : "F",
					"ground" : "G",
					"paving" : "P"}
	
	for pt in range(0, select.size(), 2):
		CMark.add_point(Vector2(select[pt], select[pt+1]))
	CMark.set_position(Palette.get_position())
	
	var order = 0
	for i in g.Pallet:
		var sample = color_sample.instance()
		sample.set_custom_minimum_size(Vector2(gap, 16))
		sample.num = order
		sample.hex = i
		sample.rgb = g.Pallet.get(i)[0]
		sample.raw = g.Pallet.get(i)[1]
		sample.Resize(Vector2(w,h))
		sample.SetColor(sample.rgb)
		g.connect("rotate_colors", sample, "PickIfNum")
		g.connect("select_colors", sample, "PickIfID")
		
		if sample.rgb == g.Flags.get("def")[0]:
			var label = color_text.instance()
			label.set_text("0")
			label.set_size(Vector2(w,h))
			label.set("custom_colors/font_color", hintc)
			sample.add_child(label)
		Palette.add_child(sample)
		order += 1
	
	var separatorA = Control.new()
	separatorA.rect_min_size = Vector2(9,h)
	separatorA.set_mouse_filter(MOUSE_FILTER_IGNORE)
	Palette.add_child(separatorA)
	
	Palette.add_child(Picker)
	Picker.num = order
	g.connect("rotate_colors", Picker, "PickIfNum")
	g.connect("select_colors", Picker, "PickIfID")
	order += 1
	
	var separatorB = Control.new()
	separatorB.rect_min_size = Vector2(15,h)
	separatorB.set_mouse_filter(MOUSE_FILTER_IGNORE)
	Palette.add_child(separatorB)
	
	for i in g.Flags:
		var sample = color_sample.instance()
		sample.set_custom_minimum_size(Vector2(gap, 16))
		sample.num = order
		sample.hex = i
		sample.rgb = g.Flags.get(i)[0]
		sample.raw = g.Flags.get(i)[1]
		sample.Resize(Vector2(w,h))
		sample.SetColor(sample.rgb)
		g.connect("rotate_colors", sample, "PickIfNum")
		g.connect("select_colors", sample, "PickIfID")
		
		var outline = Line2D.new()
		for pt in range(0, frame.size(), 2):
			outline.add_point(Vector2(frame[pt], frame[pt+1]))
			outline.set_default_color(g.Flags.get(i)[2])
			outline.set_joint_mode(Line2D.LINE_CAP_BOX)
			outline.set_width(1)
		sample.add_child(outline)
		
		if Special.has(i):
			var label = color_text.instance()
			label.set_text(Special.get(i))
			label.set_size(Vector2(w,h))
			label.set("custom_colors/font_color", hintc)
			if sample.hex in ["floras", "bamboos", "sakuras", "framed", "paving"]:
				label.set("custom_colors/font_color", Color(.7,.7,.7))
			# Center wide symbols except letters Ф, ф
			if !g.IsHalf(Special.get(i)) and !Special.get(i) in ["Ф", "ф"]:
				label.rect_position += Vector2(-1, 0)
			sample.add_child(label)
		
		Palette.add_child(sample)
		order += 1

# ============================================= # ============================================= #
# Update selection frame and create char & col arrays when selection finished
# ============================================= # ============================================= #
func SelectShape():
	g.emit_signal("destroy_previews")
	# Apply selected region
	if Input.is_action_just_released("back_click"):
		var dota = Vector2(g.last.x, g.last.y)	# First point (static) last edited cell
		var dotb = Vector2(g.snap.x, g.snap.y)	# Last point (dynamic) highlighted cell
		
		# If 2-byte brush, adds or subtracts 1 from X coord to cover entire cell
		if g.IsFull(g.b):										# bias [0|0][0|0][0|0]
			if dota.x > dotb.x:	# odd  [0|1][0|1][0|1]
				dota.x += g.IsEqual(g.bias, g.IsOdd(g.last.x))	# Expand right
				dotb.x -= g.IsEqual(g.bias, g.IsEven(g.snap.x))	# Expand left
			else:				# even [1|0][1|0][1|0]
				dotb.x += g.IsEqual(g.bias, g.IsOdd(g.snap.x))	# Expand right
				dota.x -= g.IsEqual(g.bias, g.IsEven(g.last.x))	# Expand left
		var dmin = Vector2([dota.x, dotb.x].min(), [dota.y, dotb.y].min())
		var dmax = Vector2([dota.x, dotb.x].max(), [dota.y, dotb.y].max())
		
		# Selection out of field isn't allowed but check just in case
		if 	dmin.x >= 0 and dmax.x < g.size.x * 2 and \
			dmin.y >= 0 and dmax.y < g.size.y:
			# Prepare empty arrays to write selected symbols&colors
			g.regionb.clear()
			g.regionc.clear()
			for y in range(dmin.y, dmax.y + 1):
				var lineb = []
				var linec = []
				for x in range(dmin.x, dmax.x + 1):
					# If margin symbol is a half of 2-byte pair and can't be stored, write half-space instead
#					if  x == dmin.x and g.IsNull(g.Location[y][x]) or \
#						x == dmax.x and g.IsFull(g.Location[y][x]):
#						lineb.append(" ")
					lineb.append(g.Location[y][x])
					linec.append(g.ColArray[y][x])
				g.regionb.append(lineb)
				g.regionc.append(linec)
			g.select = false
			if g.regionb.size() > 0 and g.regionb[0].size() > 0:
				CreateRegion(dota, dotb, g.IsOdd([dota.y, dotb.y].min()))
				g.drag = true
			else:
				g.lock = false
	# Cancel selection
	elif Input.is_action_just_released("left_click") or Input.is_action_just_released("right_click"):
		g.select = false
		g.lock = false
	# Update selection frame
	else:
		DrawHinter(0, 0, "select")

# ============================================= # ============================================= #
# Create preview of selected region out of Map node to move around
# ============================================= # ============================================= #
func CreateRegion(dota, dotb, shift=0):
	g.regionp = Control.new()
	var map = Map.duplicate()
	g.connect("destroy_previews", g.regionp, "queue_free")
	map.clear()
	var excol = null
	var cha
	var raw
	
	for row in g.regionb.size():
		for col in g.regionb[row].size():
			cha = g.regionb[row][col]
			if col == 0 and !cha: cha = " "
			if !g.IsEqual(g.regionc[row][col], excol):
				excol = g.regionc[row][col]
				if excol in g.Flags:
					raw = g.Flags.get(excol)[1]
				elif excol in g.Pallet:
					raw = g.Pallet.get(excol)[1]
				else:
					raw = Color(excol)
				map.push_color(raw)
			map.add_text(cha)
		map.newline()
	g.regiond.x = dotb.x - dota.x
	g.regiond.y = dotb.y - dota.y
	map.rect_position.x += (dota.x - dotb.x) * int(dota.x < dotb.x) * g.step / 2
	map.rect_position.y += (dota.y - dotb.y) * int(dota.y < dotb.y) * g.step
	map.rect_position -= (Vector2(11, 8))	# Why
	
	var frame = Line2D.new()
	frame.add_point(Vector2(0, 0))
	frame.add_point(Vector2(g.regionb[0].size() * g.step / 2, 0))
	frame.add_point(Vector2(g.regionb[0].size() * g.step / 2, g.regionb.size() * g.step))
	frame.add_point(Vector2(0, g.regionb.size() * g.step))
	frame.add_point(Vector2(0, 0))
	frame.set_default_color(Color(.3, .4, .3))
	frame.set_joint_mode(Line2D.LINE_CAP_BOX)
	frame.set_width(1)
	map.add_child(frame)
		
	g.regionp.add_child(map)
	Map.add_child(g.regionp)
	g.regionp.rect_position = Vector2(g.snap.x * g.step / 2, g.snap.y * g.step)

# ============================================= # ============================================= #
# Move clone preview after the cursor and apply it when clicked
# ============================================= # ============================================= #
func MoveRegion():
	var x = g.snap.x	# Initial x is highlighted cell (half)
	var y = g.snap.y	# Initial y is highlighted cell
	
	# Left border limiting
	if 		g.snap.x < 0 + (g.regionb[0].size() - 1) * int(g.regiond.x > 0):
		x = 0 + (g.regionb[0].size() - 1) * int(g.regiond.x > 0)
	# Right border limiting
	elif 	g.snap.x >= g.size.x * 2 - (g.regionb[0].size() - 1) * int(g.regiond.x < 0):
		x = g.size.x * 2 - 1 - (g.regionb[0].size() - 1) * int(g.regiond.x < 0)
	# Top border limiting
	if 		g.snap.y < 0 + (g.regionb.size() - 1) * int(g.regiond.y > 0):
		y = 0 + (g.regionb.size() - 1) * int(g.regiond.y > 0)
	# Bottom border limiting
	elif 	g.snap.y >= g.size.y - (g.regionb.size() - 1) * int(g.regiond.y < 0):
		y = g.size.y - 1 - (g.regionb.size() - 1) * int(g.regiond.y < 0)
	
	g.regionp.rect_position = Vector2(x * g.step / 2, y * g.step)
	
	if Input.is_action_just_pressed("left_click"):
		ApplyRegion()
		if !g.bias:
			g.emit_signal("destroy_previews")
			g.drag = false
			g.queue_unlock = true
	elif Input.is_action_just_pressed("right_click"):
		g.emit_signal("destroy_previews")
		g.drag = false
		g.queue_unlock = true

# ============================================= # ============================================= #
# Paste selected region content to main arrays
# ============================================= # ============================================= #
func ApplyRegion():
	var pivot = [	int(g.regionp.get_child(0).rect_position.x + 11 != 0),
					int(g.regionp.get_child(0).rect_position.y + 8 != 0)]
	var pasteatx
	var pasteaty
	
	var anchorx = g.snap.x
	var anchory = g.snap.y
	
	# Snap region to borders if paste coordinates are out of bounds
	if g.regiond.x > 0 and anchorx < abs(g.regiond.x):
		anchorx = abs(g.regiond.x)
	elif g.regiond.x < 0 and anchorx > g.size.x * 2 - 1 - abs(g.regiond.x):
		anchorx = g.size.x * 2 - 1 - abs(g.regiond.x)
	if g.regiond.y > 0 and anchory < abs(g.regiond.y):
		anchory = abs(g.regiond.y)
	elif g.regiond.y < 0 and anchory > g.size.y - 1 - abs(g.regiond.y):
		anchory = g.size.y - 1 - abs(g.regiond.y)
	# [!] Editor throws out of range warning sometimes but things seem to work anyway
	
	for y in g.regionb.size():
		for x in g.regionb[y].size():
			pasteatx = anchorx + x - g.regiond.x * int(g.regiond.x > 0)
			pasteaty = anchory + y - g.regiond.y * int(g.regiond.y > 0)
			if pasteatx in range(0, g.size.x * 2) and pasteaty in range(0, 42):
				# SAFE METHOD
				if g.regionb[y][x]:	# Not "" cell after 2-byte
					Draw(pasteatx, pasteaty, g.regionb[y][x])
					Colour(pasteatx, pasteaty, g.regionc[y][x])
				# DIRECT ARRAY EDIT
				# First and last characters aren't breaking 2-byte pair
#				if !(x == 0 and !g.regionb[y][x] and g.Location[pasteaty][pasteatx]) and \
#				!(x == g.regionb[y].size() and !g.IsHalf(g.regionb[y][x] and \
#				(g.IsHalf(g.Location[pasteaty][pasteatx]) or !g.Location[pasteaty][pasteatx]))):
#					g.Location[pasteaty][pasteatx] = g.regionb[y][x]
#					g.ColArray[pasteaty][pasteatx] = g.regionc[y][x]
	Transcribe()
	DrawMap()
	
# ============================================= # ============================================= #
# DRAW COLOR
# ============================================= # ============================================= #
func Colour(x=g.snap.x, y=g.snap.y, col=g.c):
	g.last = Vector2(x, y)
	
	# Prevent coloring empty cells unless it's flag
	if (g.Location[y][x] in [" ", "　"] or
	!g.Location[y][x] and g.Location[y][x - 1] in [" ", "　"]) and \
	!(col in g.Flags):
		col = "def"

	if g.IsHalf(g.b):				#	_S↓
		if g.IsNull(x, y):			# | D|0 |  |
			g.COL(x - 1, y, "def")	#	_S↓
		elif g.IsFull(x, y):		# |  |D0|  |
			g.COL(x + 1, y, "def")	#	 S↓
		g.COL(x, y, col)			# |  |? |  |
		return
	elif g.IsNull(x, y):			#	D0↓
		g.COL(x - 1, y, "def")		# | D|0?|  |
		if g.IsFull(x + 1, y):		#	D0↓
			g.COL(x + 2, y, "def")	# | D|0D|0 |
	elif g.IsHalf(x, y):			#	D0↓
		if g.IsFull(x + 1, y):		# |  |SD|0 |
			g.COL(x + 2, y, "def")
	g.COL(x, y, col)				#	D0↓
	g.COL(x + 1, y, col)			# |  |D0|  |
		
# ============================================= # ============================================= #
# DRAW SYMBOL
# ============================================= # ============================================= #
func Draw(x=g.snap.x, y=g.snap.y, sym=g.b):
	g.last = Vector2(x, y)
		
	if g.IsHalf(sym):				#	_S↓
		if g.IsNull(x, y):			# | D|0 |  |
			g.LOC(x - 1, y, " ")	#	S_↓
		elif g.IsFull(x, y):		# |  |D0|  |
			g.LOC(x + 1, y, " ")	#	 S↓
		g.LOC(x, y, sym)			# |  |? |  |
		return
	elif g.IsNull(x, y):			#	D0↓
		g.LOC(x - 1, y, " ")		# | D|0?|  |
		if g.IsFull(x + 1, y):		#	D0↓
			g.LOC(x + 2, y, " ")	# | D|0D|0 |
	elif g.IsHalf(x, y):			#	D0↓
		if g.IsFull(x + 1, y):		# |  |SD|0 |
			g.LOC(x + 2, y, " ")
	g.LOC(x, y, sym)				#	D0↓
	g.LOC(x + 1, y, "")				# |  |D0|  |
	
# ============================================= # ============================================= #
# Draw line, rect, or fill when next click is performed starting from last edited cell
# mode: 1 = draw | 2 = draw and color | 3 = color
# ============================================= # ============================================= #
func DrawShape(shape="line", mode=0):
	g.emit_signal("destroy_previews")
	var queue_quit = false
	var dota = Vector2(g.last.x, g.last.y)
	var dotb = Vector2(g.snap.x, g.snap.y)
	# 1 = cell to the right, -1 = cell to the left
	var adjacent = 1 - 2 * int(bool(g.bias != fmod(dotb.x, 2)))
	var ratio = abs((dota.x - dotb.x)/(dota.y - dotb.y + 0.01 * int(dota.y - dotb.y == 0)))
	var step
	
	if Input.is_action_just_pressed("right_click"):
		queue_quit = true
	
	if shape == "line":
		# Ortho vertical
		if dota.x == dotb.x or dota.x == dotb.x + adjacent or \
		Input.is_action_pressed("bias") and ratio + g.IsHalf(g.b) <= 2:
			step = 1 - 2 * int(bool(dota.y > dotb.y))
			for y in range(dota.y, dotb.y + step, step):
				if Input.is_action_just_released("forth_click"):
					Draw(dota.x, y)
					if g.mode:
						Colour(dota.x, y)
					queue_quit = true
			DrawHinter(0, 0, "ortho_v")
		# Ortho horizontal
		elif dota.y == dotb.y or Input.is_action_pressed("bias"):
			step = 1 - 2 * int(bool(dota.x > dotb.x))
			for x in range(dota.x, dotb.x + step, step * 2):
				if Input.is_action_just_released("forth_click"):
					Draw(x, dota.y)
					if g.IsHalf(g.b):
						Draw(x + step, dota.y)
					if g.mode:
						Colour(x, dota.y)
						if g.IsHalf(g.b):
							Colour(x + step, dota.y)
					queue_quit = true
			DrawHinter(0, 0, "ortho_h")
		# Diagonal
		else:
			var i = 0
			# Tends horizontally (x diff > y diff)
			if ratio + g.IsHalf(g.b) > 2:
				# Store coords for 2 halfs of a cell
				var lastx = [0, 0]
				var polar = 1 - 2 * int(bool(dota.y > dotb.y))
				var y = 0
				step = 1 - 2 * int(bool(dota.x > dotb.x))
				for x in range(dota.x, dotb.x + step, step * 2):
					y = dota.y + round(i * (1.0/ratio)) * polar
					DrawHinter(x, y, "line")
					if g.IsHalf(g.b):
						DrawHinter(x + step, y, "line")
					if Input.is_action_just_released("forth_click"):
						Draw(x, y)
						if g.IsHalf(g.b):
							Draw(x + step, y)
						if g.mode:
							Colour(x, y)
							if g.IsHalf(g.b):
								Colour(x + step, y)
						queue_quit = true
					# 1 = cell to the right, -1 = cell to the left
					adjacent = 1 - 2 * int(bool(g.bias != fmod(x, 2)))
					lastx = [x, x + adjacent]
					i += 2
			# Tends vertically (x diff < y diff)
			else:
				var polar = 1 - 2 * int(bool(dota.x > dotb.x))
				var x = 0
				step = 1 - 2 * int(bool(dota.y > dotb.y))
				for y in range(dota.y, dotb.y + step, step):
					x = dota.x + round(i * (ratio)) * polar
					x -= g.IsEqual(g.bias, g.IsEven(x)) * g.IsFull(g.b)
					DrawHinter(x, y, "line")
					if Input.is_action_just_released("forth_click"):
						Draw(x, y)
						if g.mode:
							Colour(x, y)
						queue_quit = true
					i += 1
	
	elif shape == "rect":
		# Horizontal lines
		step = 1 - 2 * int(bool(dota.x > dotb.x))
		for x in range(dota.x, dotb.x + step, step * 2):
			if Input.is_action_just_pressed("left_click"):
				Draw(x, dota.y)
				Draw(x, dotb.y)
				if g.IsHalf(g.b):
					Draw(x + step, dota.y)
					Draw(x + step, dotb.y)
				queue_quit = true
			if Input.is_action_just_pressed("right_click") or Input.is_action_just_pressed("left_click") and g.mode:
				Colour(x, dota.y)
				Colour(x, dotb.y)
				if g.IsHalf(g.b):
					Colour(x + step, dota.y)
					Colour(x + step, dotb.y)
				queue_quit = true
		# Vertical lines
		step = 1 - 2 * int(bool(dota.y > dotb.y))
		for y in range(dota.y, dotb.y + step, step):
			if Input.is_action_just_pressed("left_click"):
				Draw(dota.x - g.IsEqual(g.bias, g.IsEven(dota.x)), y)
				Draw(dotb.x - g.IsEqual(g.bias, g.IsEven(dotb.x)), y)
				queue_quit = true
			if Input.is_action_just_pressed("right_click") or Input.is_action_just_pressed("left_click") and g.mode:
				Colour(dota.x - g.IsEqual(g.bias, g.IsEven(dota.x)), y)
				Colour(dotb.x - g.IsEqual(g.bias, g.IsEven(dotb.x)), y)
				queue_quit = true
		DrawHinter(0, 0, "rect")
	
	elif shape == "fill":
		step = 1 - 2 * int(bool(dota.y > dotb.y))
		for y in range(dota.y, dotb.y + step, step):
			step = 1 - 2 * int(bool(dota.x > dotb.x))
			for x in range(dota.x, dotb.x + step, step * 2):
				if Input.is_action_just_pressed("left_click"):
					Draw(x, y)
					if g.IsHalf(g.b):
						Draw(x + step, y)
					queue_quit = true
				if Input.is_action_just_pressed("right_click") or Input.is_action_just_pressed("left_click") and g.mode:
					Colour(x, y)
					if g.IsHalf(g.b):
						Colour(x + step, y)
					queue_quit = true
		DrawHinter(0, 0, "fill")
	
	if queue_quit:
		g.draw = null
		g.line = false
		g.emit_signal("destroy_previews")
		Transcribe()
		DrawMap()		
		TintCursor(true)

# ============================================= # ============================================= #
# Draw preview for line/rect/fill action
# ============================================= # ============================================= #
func DrawHinter(x, y, shape=null):
	if shape == "fill":
		var addx = int(bool(g.last.x > g.snap.x))
		var addy = int(bool(g.last.y > g.snap.y))
		var posx = [g.last.x + addx * 2 - int(!g.IsHalf(g.b) and g.bias != fmod(g.last.x, 2)), g.snap.x - int(!g.IsHalf(g.b) and g.bias != fmod(g.snap.x, 2))]
		var posy = [g.last.y + addy, g.snap.y]
		var dimx = posx.max() - posx.min() + (1 - addx) + (1 - addx) * int(!g.IsHalf(g.b))
		var dimy = posy.max() - posy.min() + (1 - addy)
		
		var hinter = ColorRect.new()
		hinter.rect_size = Vector2(dimx * g.step / 2, dimy * g.step)
		hinter.rect_position = Vector2(posx.min() * g.step / 2, posy.min() * g.step)
		hinter.color = Color(0.9, 1.0, 0.9, 0.1)
		g.connect("destroy_previews", hinter, "queue_free")
		Lock.add_child(hinter)
	elif shape == "rect":
		var addx = int(bool(g.last.x > g.snap.x))
		#var addy = int(bool(g.last.y > g.snap.y))
		var posx = [g.last.x - int(!g.IsHalf(g.b) and g.bias != fmod(g.last.x, 2)), g.snap.x - int(!g.IsHalf(g.b) and g.bias != fmod(g.snap.x, 2))]
		var posy = [g.last.y, g.snap.y]
		# ￣ ; |< ; ＿ ; >|
		var poss = [[posx.min(), posy.min()],
					[posx.min(), posy.min() + 1],
					[posx.min(), posy.max()],
					[posx.max(), posy.min() + 1]]
		var dims = [[posx.max() - posx.min() - int(g.IsHalf(g.b)) + 2, 1],
					[2 - g.IsHalf(g.b), posy.max() - posy.min() - 1],
					[posx.max() - posx.min() - int(g.IsHalf(g.b)) + 2, 1],
					[2 - g.IsHalf(g.b), posy.max() - posy.min() - 1]]
		#var cols = [Color(1,0,0,.3), Color(0,1,0,.3), Color(0,0,1,.3), Color(1,1,1,.3)]
		for i in 4:
			var hinter = ColorRect.new()
			hinter.rect_size = Vector2(dims[i][0] * g.step / 2, dims[i][1] * g.step)
			hinter.rect_position = Vector2(poss[i][0] * g.step / 2, poss[i][1] * g.step)
			hinter.color = Color(0.9, 1.0, 0.9, 0.1)
			g.connect("destroy_previews", hinter, "queue_free")
			Lock.add_child(hinter)
	elif shape == "line":
		if !g.IsHalf(g.b) and y == g.snap.y and int(Input.is_action_pressed("bias")) != fmod(x, 2):
			return
		var hinter = ColorRect.new()
		hinter.rect_size = Vector2(g.step / (1 + int(g.IsHalf(g.b))), g.step)
		hinter.rect_position = Vector2(x * g.step/2, y * g.step)
		hinter.color = Color(0.9, 1.0, 0.9, 0.1)
		g.connect("destroy_previews", hinter, "queue_free")
		Lock.add_child(hinter)
	elif shape == "ortho_h" or shape == "ortho_v":
		var dim = Vector2(g.snap.x - g.last.x, g.snap.y - g.last.y)
		var pos = Vector2(g.last.x, g.last.y)
		var ori = Vector2(int(dim.x < 0), int(dim.y < 0))
		var hinter = ColorRect.new()
		if shape == "ortho_h":
			hinter.rect_size = Vector2(abs(dim.x / 2 * g.step) + ori.x * g.step, g.step)
			hinter.rect_position = Vector2((pos.x + dim.x * ori.x) / 2 * g.step, pos.y * g.step)
		else:
			hinter.rect_size = Vector2(g.step - g.step * 0.5 * g.IsHalf(g.b), abs(dim.y * g.step) + ori.y * g.step)
			hinter.rect_position = Vector2(pos.x / 2 * g.step, (pos.y + dim.y * ori.y) * g.step)
		hinter.color = Color(0.9, 1.0, 0.9, 0.1)
		g.connect("destroy_previews", hinter, "queue_free")
		Lock.add_child(hinter)
	elif shape == "select":
		var addx = int(g.last.x > g.snap.x)
		var addy = int(g.last.y > g.snap.y)
		var posx = [g.last.x - int(g.IsFull(g.b) and g.bias == g.IsEven(g.last.x)) + addx * (2 - g.IsHalf(g.b)),
					g.snap.x - int(g.IsFull(g.b) and g.bias == g.IsEven(g.snap.x)) - addx * (2 - g.IsHalf(g.b)) + 2 - g.IsHalf(g.b)]
		var posy = [g.last.y + addy,
					g.snap.y - addy + 1]
		# 79; 93; 31; 17
		var poss = [[posx.min(), posy.min()],
					[posx.max(), posy.min()],
					[posx.max(), posy.max()],
					[posx.min(), posy.max()]]
		
		var frame = Line2D.new()
		frame.add_point(Vector2(poss[0][0] * g.step / 2, poss[0][1] * g.step))
		frame.add_point(Vector2(poss[1][0] * g.step / 2, poss[1][1] * g.step))
		frame.add_point(Vector2(poss[2][0] * g.step / 2, poss[2][1] * g.step))
		frame.add_point(Vector2(poss[3][0] * g.step / 2, poss[3][1] * g.step))
		frame.add_point(Vector2(poss[0][0] * g.step / 2, poss[0][1] * g.step))
		frame.set_default_color(Color(.75, 0, 1))
		frame.set_joint_mode(Line2D.LINE_CAP_BOX)
		frame.set_width(1)
		g.connect("destroy_previews", frame, "queue_free")
		Lock.add_child(frame)
		
# ============================================= # ============================================= #
# UPDATE MAP
# ============================================= # ============================================= #
func DrawMap(rand=false, inv=false):
	Map.clear()
	BG.set_frame_color(Color(0, 0, 0))
	if !inv:
		g.timestop = false
	var excol = null
	var cha
	var col
	var raw
	for row in g.Location.size():
		for bar in g.Location[row].size():
			cha = g.Location[row][bar]
			if cha:								# Do not compute on null cells
				col = g.ColArray[row][bar]
				if cha == " " and g.dots:		# Highlight spaces mode
					cha = "･"
					col = Color(1,1,0)
					raw = col
					Map.push_color(raw)
				elif rand and col in g.Flags:	# Season slider
					var replace = Dynamic(cha, col, bar, row)
					cha = replace[0]
					raw = replace[1]
					Map.push_color(raw)
				elif !g.IsEqual(col, excol):	# Regular mapdraw
					if col in g.Pallet:
						raw = g.Pallet.get(col)[1]
					elif col in g.Flags:
						raw = g.Flags.get(col)[1]
					else:
						raw = Color(col)
					if g.timestop and col != "white":
						raw = Color(1,1,1,2) - raw
						BG.set_frame_color(Color("01183C"))
					Map.push_color(raw)
				excol = col
				Map.add_text(cha)
		Map.newline()

# ============================================= # ============================================= #
# Calculate season and day specific variables
# ============================================= # ============================================= #
func DayStat():
	g.season = floor(g.DAY/30)		# Current season (0...3) 1...4 in TW
	g.day = fmod(g.DAY,30)			# Current day of season (0...29) 1...30 in TW
	g.mix = g.curves[g.day]			# Foliage color blend ratio (0...1)
	g.prob = g.curvee[g.day] * 100	# Effect probability for season dependent flags (0...100)
	g.s33d = g.R(80)				# NOISE y shift (generate at dawn)
			
# ============================================= # ============================================= #
# Replace drawn symbol or color depending on current season, day or random
# Returns pair of symbol & color to display
# [!] Every non-foliage flag output must print either one 2-byte symbol or two 1-byte symbols
# ============================================= # ============================================= #
func Dynamic(argb, argc, x=-1, y=-1):
	# Flags to be replaced with empty cell if not occured
	var empty = ["ground", "water", "tides", "still", "steam", "flower", "flowers"]
	# Skip default flags (reset color, always white, getmap)
	if argc in ["def", "white", "call", "framel", "framen", "framed", "frames"]:
		return [argb, g.ID2RAW(argc)]
		
	var cha = argb	# Store symbol to return
	var col = argc	# Store color to return
		
	if argc == "floras":		# Foliage in shadow
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = foliage_s[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(foliage_s[g.season], foliage_s[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(foliage_s[g.season], foliage_s[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	elif argc == "florad":		# Foliage dark
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = foliage_d[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(foliage_d[g.season], foliage_d[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(foliage_d[g.season], foliage_d[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	elif argc == "floran":		# Foliage normal
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = foliage_n[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(foliage_n[g.season], foliage_n[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(foliage_n[g.season], foliage_n[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	elif argc == "floral":		# Foliage light
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = foliage_l[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(foliage_l[g.season], foliage_l[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(foliage_l[g.season], foliage_l[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	
	elif argc == "bamboos":		# Foliage in shadow
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = bamboo_s[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(bamboo_s[g.season], bamboo_s[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(bamboo_s[g.season], bamboo_s[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	elif argc == "bambood":		# Foliage dark
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = bamboo_d[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(bamboo_d[g.season], bamboo_d[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(bamboo_d[g.season], bamboo_d[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	elif argc == "bamboon":		# Foliage normal
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = bamboo_n[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(bamboo_n[g.season], bamboo_n[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(bamboo_n[g.season], bamboo_n[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	elif argc == "bambool":		# Foliage light
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = bamboo_l[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(bamboo_l[g.season], bamboo_l[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(bamboo_l[g.season], bamboo_l[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	
	elif argc == "sakuras":		# Foliage in shadow
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = sakura_s[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(sakura_s[g.season], sakura_s[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(sakura_s[g.season], sakura_s[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	elif argc == "sakurad":		# Foliage dark
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = sakura_d[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(sakura_d[g.season], sakura_d[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(sakura_d[g.season], sakura_d[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	elif argc == "sakuran":		# Foliage normal
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = sakura_n[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(sakura_n[g.season], sakura_n[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(sakura_n[g.season], sakura_n[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	elif argc == "sakural":		# Foliage light
		if g.season == 0 and g.Noise[y + g.nBias][x] < g.prob:
			col = sakura_l[4]	# If snow covered
		elif g.day < 15:		# 1st half of season - mix current && previous
			col = g.Mix(sakura_l[g.season], sakura_l[g.season - 1 + 4 * int(g.season==0)])
		else:					# 2nd half of season - mix current && next
			col = g.Mix(sakura_l[g.season], sakura_l[g.season + 1 - 4 * int(g.season==3)])
		return [cha, col]
	
	# SEASON DEPENDENT FLAGS
	cha = "　"					# Print free cell if check == TRUE
	if g.P(100 - g.prob):		# Perform time depending probability check
		pass					# FALSE == proceed to flag checks
	elif argc == "ground" or argc == "paving":
		if argc == "paving":	# If paving - restore original char
			cha = argb
		if g.season == 0:		# Winter
			if g.P(60):			# 60% chance		snow piles
				cha = g.ARR(shrooms)
				col = g.ARR(glaciac)
				if g.P(10):		# 10% chance (6%)	random branches
					cha = g.ARR(leavess)
					col = Color(.20,.13,  0)
				elif g.P(5):	# 5% chance (3%)	rare flower
					cha = g.ARR(shrooms)
					col = g.ARR(liliesc)
		elif g.season == 1: 	# Spring
			if g.P(25):			# 25% chance		grass
				cha = g.ARR(shrooms)
				col = g.ARR(liliesc)
				if g.P(20):		# 20% chance (5%)	leaves
					cha = g.ARR(leavess)
			# > INPUT CHERRY BLOSSOM CODE <
			if g.day >= 15 and g.day < 18:	# Day specific %
				if g.P(5 + (18 - g.day) * 15):	#	petals
					cha = g.ARR(leavess)
					col = g.ARR(petalsc)
			# > INPUT RAIN OCCURANCE CODE <
			if g.day == 12 and g.P(5) or \
			g.day == 20 and g.P(3):				#	puddles
				cha = g.ARR(puddles)
				col = g.ARR(ripplec)
		elif g.season == 2: 	# Summer
			if g.P(20):			# 20% chance		grass
				cha = g.ARR(shrooms)
				col = g.ARR(liliesc)
		elif g.season == 3: 	# Autumn
			if g.P(30):			# 30% chance		foliage
				cha = g.ARR(leavess)
				col = g.ARR(leavesc)
				if g.P(7):		# 2% chance			shrooms
					cha = g.ARR(shrooms)
					col = g.ARR(shroomc)
	elif argc == "flower" or argc == "flowers":
		if g.season == 0 and g.P(1):	# Winter	1%
			cha = g.ARR(flowers)
			col = Color(.80,1.0,.60)
		elif g.season == 1 and g.P(30):	# Spring	30%
			cha = g.ARR(flowers)
			col = g.ARR(flowerc)
		elif g.season == 2 and g.P(20):	# Summer	20%
			cha = g.ARR(flowers)
			col = g.ARR(flowerc)
	else:								# Keep original color for not listed flag
		col = g.ID2RAW(argc)
	
	# SEASON INDEPENDENT FLAGS
	if argc == "steam":
		if g.P(60):				# 60% chance		steam
			cha = g.ARR(["∫", "∬"])
			col = Color(.5,.5,.5)
	elif argc == "water":
		col = g.ARR(ripplec)	# Get random tone for water
		# If not winter and NOISE val at x|y is between 48 and 52 - print lily
		if g.season != 0 and g.Noise[y + g.nBias][x] in range(48, 52):
			cha = liliess[fmod(g.Noise[y + g.nBias][x], liliess.size())]
			col = liliesc[fmod(g.Noise[y + g.nBias][x], liliesc.size())]
			if g.season == 3:	# If autumn - step color to withered
				col = g.Mix(foliage_d[3], col)	# Get autumn flora dark as reference
				# Remove lilies one by one till day 15, remove all from day 15
				if g.Noise[y + g.nBias + 30][x] < g.prob or g.day > 15:
					cha = "　"
		elif g.season != 0 and g.P(30):	# If not lily spawn - print ~~~ with 30% probability
			cha = g.ARR(ripples)
		if g.season == 0 and g.P(12):
			cha = g.ARR(["- "," -","= "," =","_ "," _","￣","￣"])
			col = Color(0.4, 0.5, 0.6)
	elif argc == "tides":
		# Read each 3rd line of NOISE flattening pattern vertically
		if g.season != 0 and g.Noise[y*3 + g.s33d][x] < 45:		# 45% (NOISE val at x|y less than 45)
			cha = g.ARR(ripples)
			col = g.ARR(ripplec)
		if g.season == 0 and g.P(8):
			cha = g.ARR(["- "," -","= "," =","_ "," _","￣","￣"])
			col = Color(0.4, 0.5, 0.6)
	elif argc == "still":
		cha = g.ARR(ripples)
		col = g.ARR(ripplec) + Color(-.1,+.1,0)	# Add tone to water color (-r,+g)
	elif argc == "spray":
		cha = g.ARR(["∴", "∵", "･.", ".･"])		# Animate with random symbols
		col = g.ARR([Color(1,1,1), Color(.9,.9,.9), Color(.8,.8,.8)])
		
	if typeof(col) == TYPE_STRING:	# Convert non raw color to raw color
		col = g.ID2RAW(col)
		
	return [cha, col]				# Output

# ============================================= # ============================================= #
# Generate symbol array according field size (x*2;y)
# ============================================= # ============================================= #
func ResetArrays(sym="　"):
	g.Location.clear()
	for row in range(g.size.y):
		var bline = []
		for i in range(g.size.x * (1 + int(g.IsHalf(sym)))):
			bline.append(sym)
			if !g.IsHalf(sym):
				bline.append("")
		g.Location.append(bline)

# ============================================= # ============================================= #
# Generate color array according field size (x*2;y)
# ============================================= # ============================================= #
func ResetColors(col="def"):
	g.ColArray.clear()
	for row in range(g.size.y):
		var cline = []
		for i in range(g.size.x):
			cline.append(col)
			cline.append(col)
		g.ColArray.append(cline)

# ============================================= # ============================================= #
# Set marker half g.size if brush is 1-byte symbol
# ============================================= # ============================================= #
func ShrinkMarker(arg=69):
	if arg != 69:
		BMark.set_size(Vector2(g.step * (1 - 0.5 * arg), g.step) + Vector2(1, 1))
	else:
		BMark.set_size(Vector2(g.step * (1 - 0.5 * int(g.IsHalf(g.b))), g.step) + Vector2(1, 1))

# ============================================= # ============================================= #
# [Experimental] Check lines size and fix them if length doesn't match g.size.x * 2
# ============================================= # ============================================= #
func FixArray():
	for line in range(g.Location.size()):
		var diff = g.Location[line].size() - g.size.x * 2
		if diff > 0:
			for i in diff:
				g.Location[line].pop_back()
				g.ColArray[line].pop_back()
		else:
			for i in abs(diff):
				g.Location[line].push_back(" ")
				g.ColArray[line].push_back("default")

# ============================================= # ============================================= #
# Replace adjacent 1-byte spaces of same color with single 2-byte space
# ============================================= # ============================================= #
func MergeSpaces():
	for line in g.Location.size():
		for sym in g.Location[line].size() - 1:
			if g.Location[line][sym] == " " and g.Location[line][sym + 1] == " " and \
			g.ColArray[line][sym] == g.ColArray[line][sym + 1]:
				g.Location[line][sym] = "　"
				g.Location[line][sym + 1] = ""
				
# ============================================= # ============================================= #
# Color cursor when color is picked
# arg - tint cursor to current g.c
# shape - use hint image
# ============================================= # ============================================= #
func TintCursor(arg=false):
	var img = load("res://cursor_pointer.png")
	if g.draw:
		img = load(str("res://cursor_", g.draw,".png"))
	if g.line:
		img = load(str("res://cursor_line.png"))
	var tex = ImageTexture.new()
	var tint = Color(1, 1, 1)
	if arg:
		img.lock()
		if g.c in g.Flags:	# Is g.c string
			tint = g.Flags.get(g.c)[1]
		else:
			tint = g.ID2RAW(g.c)
		var frame = bool(tint[0] + tint[1] + tint[2] < 0.3)
		for y in img.get_size().y:
			for x in img.get_size().x:
				if img.get_pixel(x, y) == Color(1, 1, 1, 1):
					img.set_pixel(x, y, tint)
				if frame and img.get_pixel(x, y) == Color(0, 0, 0, 1):
					img.set_pixel(x, y, Color(.6, .6, .6, 1))
		img.unlock()
	tex.create_from_image(img, 0)
	Input.set_custom_mouse_cursor(tex, CURSOR_ARROW, Vector2(0, 5))

# ============================================= # ============================================= #
# Update map state from JSON string
# ============================================= # ============================================= #
func LoadData(win, draw=true):
	g.nBias = g.R(150)
	var Dict # Temp JSON container
	# Read from upper field
	if win == "input":
		if Tin.get_text() == "":
			ResetArrays()
			ResetColors()
			if draw:
				DrawMap()
				g.area = ""
				MapName.text = ""
				RenameArea()
			Transcribe()
			return false
		Dict = parse_json(Tin.get_text())
		if !Dict:
			if !TryLoadERA(Tin.text):
				Tin.text = "ERROR:\nJSON corrupted"
			return false
	# Read from middle field
	elif win == "output":
		Dict = parse_json(Tout.get_text())
		if !Dict:
			Tout.text = "ERROR:\nJSON corrupted"
			return false
	# Read as legacy Construct 2 format
	if Dict.get("c2array"):		
		var col
		var row
		var content = Dict.get("data")
		for i in range(Dict.get("data").size()):
			col = fmod(i, g.size.x)
			row = floor(i / g.size.x)
			if !content[i][0][0]:	# Read empty entry as 2-byte space
				g.Location[row][col * 2] = "　"
				g.Location[row][col * 2 + 1] = ""
				g.ColArray[row][col * 2] = "def"
				g.ColArray[row][col * 2 + 1] = "def"
			else:	# If has value
				g.Location[row][col * 2] = content[i][0][0].left(1) # Read first (or only) symbol in entry
				if g.Legacy.has(content[i][1][0]):	# If has color data
					g.ColArray[row][col * 2] = g.RGB2HEX(g.Legacy.get(content[i][1][0])[0])
				else:
					g.ColArray[row][col * 2] = "def"
				if g.IsHalf(content[i][0][0].left(1)):	# First symbol is half
					if content[i][0][0].length() > 1:
						g.Location[row][col * 2 + 1] = content[i][0][0].right(1)
						if g.Legacy.has(content[i][1][0]):
							g.ColArray[row][col * 2 + 1] = g.RGB2HEX(g.Legacy.get(content[i][1][0])[0])
						else:
							g.ColArray[row][col * 2 + 1] = "def"
					else:
						g.Location[row][col * 2 + 1] = " "
						g.ColArray[row][col * 2 + 1] = "def"
				else:	# First symbol is 2-byte
					g.Location[row][col * 2 + 1] = ""
					if g.Legacy.has(content[i][1][0]):
						g.ColArray[row][col * 2 + 1] = g.RGB2HEX(g.Legacy.get(content[i][1][0])[0])
					else:
						g.ColArray[row][col * 2 + 1] = "def"
	# Read as regular JSON
	elif Dict.get("0"):
		var color
		for line in g.size.y:
			for item in Dict.get(str(line)).size():
				g.Location[line][item] = Dict.get(str(line))[item][0]
				color = Dict.get(str(line))[item][1]
				# Resetcolor
				if color == "0":
					g.ColArray[line][item] = "def"
				# Hex or flag index
				elif color in g.Pallet or color in g.Flags or color.left(1) in ["0", "#"]:
					g.ColArray[line][item] = color
				# Numeric ID or undefined
				else:
					var index = g.Index[int(color)]
					if index:
						g.ColArray[line][item] = index
					else:
						g.ColArray[line][item] = "def"
	if draw:
		DrawMap()
		Transcribe()
		SaveReminder(0)	# Reset actions counter
	
	return true

# ============================================= # ============================================= #
# Generate map state string in JSON or ERA format
# ============================================= # ============================================= #
func SaveData(win):
	if win == "output":
		var Export = {}
		var line = []
		for y in g.size.y:
			for x in g.size.x * 2:
				line.append([g.Location[y][x], g.ColArray[y][x]])
			Export[y] = line
			line = []
		Tout.set_text(to_json(Export).replace("]],", "]],\n").replace("{", "{\n").replace("}", "\n}"))
		SaveReminder(0)	# Reset actions counter
	elif win == "era" or win == "input":
		var Location
		var ColArray
		var Dimensions
		Location = g.Location.duplicate(true)	# Temp for clean array
		ColArray = g.ColArray.duplicate(true)	# Temp with color data
		Dimensions = Location.duplicate(true)	# Map array with empty cells trimmed
		
		for y in Dimensions.size():	# Stripping empty space from each line back
			while Dimensions[y] and (Dimensions[y][-1] == "　" or Dimensions[y][-1] == ""):
				Dimensions[y].pop_back()
		for y in Dimensions.size():	# Stripping empty lines from array back
			while Dimensions and !Dimensions[-1]:
				Dimensions.pop_back()
		if !Dimensions:
			return
		
		var lines = ""
		var linec = ""
		var Exports = []	# Array with all symbol lines
		var Exportc = []	# Array with all color lines
		var Export = []		# Array to keep track of empty lines
		
		var dels = "​"		# Symbol delimiter (zero-width space)
		var delc = ","		# Color delimiter

		var call = "call"	# "call getmap" flag name
		var callc = ";CALL"	# Endline comment for lines with getmap
		var callw = false	# Add endline comment
		
		# For each line	
		for y in Dimensions.size():
			# [!] If changed, remember to double new identifiers in TryLoadERA() 
			lines = str("AA:", "0".trim_prefix(str(int(y < 10))), y, " = ")	# Characters row format
			linec = str("FF:", "0".trim_prefix(str(int(y < 10))), y, " = ")	# Colors row format
			var hasCall = "" # Extra text for lines containing call flag
			var rows = ""
			var rowc = ""

			# For each entry in row array
			for x in Dimensions[y].size():
				# If !null
				if Location[y][x]:
					# Color
					var col = ColArray[y][x]
					# Symbol
					rows += Location[y][x]
					if x < Dimensions[y].size() - 1:
						# If symbols are not paired together due to call flag
						if !(Location[y][x+1] and col == call and ColArray[y][x+1] == call):
							rows += dels # Add zero width space delimiter for AA row
					# Color
					if (x > 0 and col != ColArray[y][x-1]) or x == 0:	# Different from last entry
						if col in g.Flags:
							# INDEX
#							rowc += str(g.Flags.get(col)[3])
							# NAME
							rowc += col
						else:
							rowc += g.Num20x(col)
					if x < Dimensions[y].size() - 1:	#if x <= Dimensions[y].size() - 1:
						# Isn't last entry and both current && next != call
						if !(x < Dimensions[y].size() - 2 and Location[y][x+1] and \
						col == call and ColArray[y][x+1] == call):
							rowc += delc # Add comma delimiter for FF row
						if callw and col == call:
							hasCall = callc

			# Clumsy method to strip invisible symbols
			# off lines by converting lines to arrays and back
			# =====
			rows = Array(rows.split(dels))
			rowc = Array(rowc.split(delc))
			while rows and rows[rows.size() - 1] in ["​", " ", "　"]:
				rows.pop_back()
				rowc.pop_back()

			if rows:
				rows = g.ARR2STR(rows,"​")
				rowc = g.ARR2STR(rowc)
				Export.append(1)
			else:
				rows = ""
				rowc = ""
				Export.append(0)
			# =====
			
			lines += rows + hasCall + "\n".left(int(y != g.size.y - 1) * 2)
			linec += rowc + hasCall + "\n".left(int(y != g.size.y - 1) * 2)
			Exports.append(lines)
			Exportc.append(linec)
#			g.DebugExport(Exports, y)

		# Remove all empty lines from the end
		while Export and Export[Export.size() - 1] == 0:
			Export.pop_back()
			Exports.pop_back()
			Exportc.pop_back()
		
		Exports = g.ARR2STR(Exports, "")
		Exportc = g.ARR2STR(Exportc, "")
			
		if win == "input":
			Tin.set_text(str(Exports, "\n\n", Exportc))
			return
		Tera.set_text(str(Exports, "\n\n", Exportc))
			
# ============================================= # ============================================= #
# Copy JSON string to clipboard or paste it from clipboard
# ============================================= # ============================================= #
func ClipData(win):
	if win == "input":
		Tin.set_text(OS.get_clipboard())
	elif win == "output" and Tout.text and Tout.text != "Output JSON":
		OS.set_clipboard(Tout.text)
	elif win == "era" and Tera.text and Tera.text != "Output ERACODE":
		OS.set_clipboard(Tera.text)

# ============================================= # ============================================= #
# Save map state as JSON or ERA format within exported file
# ============================================= # ============================================= #
func ExportData(win, batch=false):
	var content
	var prefix
	var format
	if win == "input":
		SaveData("input")
		content = Tin.text
		prefix = "ERA_"
		format = ".ERB"
	elif win == "output":
		SaveData("output")
		content = Tout.text
		if content.length() < 12:
			Tout.set_text("Nothing to export!")
			return
		prefix = "JSON_"
		format = ".json"
		SaveReminder(0)	# Reset actions counter
	elif win == "era":
		SaveData("era")
		content = Tera.text
		if content.length() < 15:
			Tera.set_text("Nothing to export!")
			return
		prefix = "ERA_"
		format = ".ERB"
	
	var path = OS.get_executable_path().get_base_dir().replace("\\", "/") + "/"
	var time = str(	"0".trim_prefix(str(int(OS.get_time().hour < 10))), OS.get_time().hour, "",
					"0".trim_prefix(str(int(OS.get_time().minute < 10))), OS.get_time().minute, "",
					"0".trim_prefix(str(int(OS.get_time().second < 10))), OS.get_time().second)
	var nick = prefix + time
	if g.area and !g.area in ["ERA_", "JSON_"]:
		nick = g.area + " [" + time + "]"
	if batch:	path += "Batch/"
	
	var file = File.new()
	file.open(str(path, nick, format), file.WRITE)
	file.store_string(content)
	file.close()

# ============================================= # ============================================= #
# Load ERA
# ============================================= # ============================================= #
func TryLoadERA(text, draw=true):
	var lines = text.split("\n")
	var Location = []
	var ColArray = []
	var delimcha = "​"	# Zero-width space
	var delimcol = ","
	
	var regex = RegEx.new()
	var result
	regex.compile("\\t?\\w*:\\d*\\s?=\\s?(.*)")			# Remove row header, i.e. "    AA:42 = "

	for i in lines:
		if i.strip_edges(1,0).left(2) in ["CH", "AA"]:	# If line is symbols row
			result = regex.search(i.split(";")[0])		# Get rid of endline comment
			if result:
				Location.append(result.get_string(1).split(delimcha))	# Get array of splitted symbols
		if i.strip_edges(1,0).left(2) in ["CL", "FF", "MC", "MA"]:
			result = regex.search(i.split(";")[0])
			if result:
				ColArray.append(result.get_string(1).split(delimcol))	# Get array of splitted colors
	
	if !Location:
		Tin.text = "ERROR:\nMap data not found"
		return false
	if Location.size() > 42:
		Tin.text = "ERROR:\nMap boundaries exceeded by\ncharacter data"
		return false
	if ColArray and Location.size() != ColArray.size():	# If color array provided but small
		Tin.text = "ERROR:\nSize mismatch of character\nand color data"
		return false
	
	ResetArrays()
	ResetColors()
	
	for row in Location.size():
		var point = 0		# position in g.Location
		var excol = "def"	# last color
		var color			# current color
		if Location[row].size() == 1:	# Vanilla map, no delimiter
			var line = Location[row][0]
			Location[row] = []
			if line.length() > g.size.x * 2:
				Tin.text = str("ERROR:\nToo much elements in line ", row)
				return false
			else:
				for i in line.length():
					Location[row].append(line[i])
		if Location[row].size() > g.size.x * 2:	# Too much symbols in row
			Tin.text = str("ERROR:\nToo much elements in line ", row)
			return false
		for col in Location[row].size():	# For each entry in row
			if Location[row][col].length() == 1:
				Draw(point, row, Location[row][col])
			else:
				Draw(point, row, Location[row][col].substr(0, 1))
				if point < 127:
					Draw(point + 1, row, Location[row][col].substr(1, 1))
			if ColArray:	# Color data provided
				color = ColArray[row][col].replace("0x", "#")
				if color.to_lower() in ["0", "r", "reset", "default", "def"]: color = "def"
				elif color.to_lower() in ["1", "255", "a", "fff", "albedo", "white"]: color = "white"
				elif color.to_lower() in ["2", "getmap", "go", "call"]: color = "call"
				elif g.IsIndex(color): color = g.Index[int(color)]
				if !color: color = excol
				g.ColArray[row][point] = color
				if point < 127 and g.IsFull(Location[row][col]):
					g.ColArray[row][point+1] = color
				excol = color
			point += 2 - g.IsHalf(Location[row][col])
			if point >= g.size.x * 2: break
			
	if draw:
		DrawMap()
		SaveReminder(0)
		OS.move_window_to_foreground()
	return true
		
# ============================================= # ============================================= #
# Processing files D&Dd over window
# ============================================= # ============================================= #	
func DragAndDrop(src, screen):
	var fileNew = File.new()
	if src[0].get_extension().to_lower() in ["jpg", "jpeg", "png", "bmp"]:
		MapPrint(src[0])
	elif src.size() == 1:
		fileNew.open(src[0], fileNew.READ)
		var text = fileNew.get_as_text()
		fileNew.close()
		if !parse_json(text):
			Tin.text = "ERROR:\nFile doesn't contain map data\nor JSON corrupted"
			if TryLoadERA(text):
				ExtractAreaName(src[0])
				Tin.text = text
			return
		Tin.text = text
		SaveReminder(0)	# Reset actions counter
		OS.move_window_to_foreground()
		
		ExtractAreaName(src[0])
		
		OS.set_window_title(str(ProjectSettings.get_setting("application/config/name"), " - ", g.area))
		LoadData("input")
	
	else: # Instant batch convert
		# Store map variables
		var tempareaname = g.area
		VirtualClipboard = [g.Location.duplicate(true), g.ColArray.duplicate(true), tempareaname]
		
		# Creates "/Batch" folder if it doesn't exist yet to store files
		var path = OS.get_executable_path().get_base_dir().replace("\\", "/")
		var dir = Directory.new()
		if !dir.dir_exists(path.plus_file("Batch")):
			dir.open(path)
			path += "/Batch/"
			dir.make_dir(path)

		var filesCount = 0
		for file in src.size():
			fileNew.open(src[file], fileNew.READ)
			var text = fileNew.get_as_text()
			fileNew.close()
			
			ExtractAreaName(src[file])

			Tin.text = text
			if LoadData("input", false) or TryLoadERA(text):
				filesCount += 1
				ExportData("input", true)			
				PrintMap(true)
			
		Tin.text = str("OK:\n", filesCount, " files converted to .ERB")
		
		# Restore map state
		g.Location = VirtualClipboard[0]
		g.ColArray = VirtualClipboard[1]
		g.area = VirtualClipboard[2]
		DrawMap()

# ============================================= # ============================================= #
# Strip filename from path, extension and timestamp
# ============================================= # ============================================= #
func ExtractAreaName(path):
	g.area = path.split("\\")[-1].split(".")[0]
	var regex = RegEx.new()
	regex.compile("[0-9\\[\\]]{0,}$")
	var result = regex.search(g.area)
	if result:
		g.area = g.area.trim_suffix(result.get_string(0)).rstrip("_ ")
		MapName.set_text(g.area)
		OS.set_window_title(str(ProjectSettings.get_setting("application/config/name"), " - ", g.area))

# ============================================= # ============================================= #
# Change area/file name when name is entered in MapName box
# ============================================= # ============================================= #
func RenameArea(text=null):
	var cursor = MapName.cursor_get_column()
	if !text:
		text = MapName.get_text().replace("\n", "")
	if text.length() > 26:
		MapName.set_text(g.area)
		MapName.cursor_set_column(cursor - 1)
		return
	else:
		MapName.set_text(text)
		g.area = text
		MapName.cursor_set_column(cursor)
	if text:
		OS.set_window_title(str(ProjectSettings.get_setting("application/config/name"), " - ", g.area))
	else:
		OS.set_window_title(str(ProjectSettings.get_setting("application/config/name")))
	
# ============================================= # ============================================= #
# Show/hide I/O panel
# ============================================= # ============================================= #
func TransformWindow(ignore=0):
	g.iopan = !g.iopan
	Hide.release_focus()
	if g.iopan:
		OS.set_window_size(Vector2(1280, 640))
	else:
		OS.set_window_size(Vector2(1080, 640))

# ============================================= # ============================================= #
# Keep track of activity and remind to save progress
# ============================================= # ============================================= #
func SaveReminder(add=-1):
	if add == 0:
		g.progress = 0
	elif add == 1:
		g.progress += 1
	if g.progress > 200:
		MapName.modulate = Color(1.2, 0.8, 0.8)
		Hide.modulate = Color(1.2, 0.8, 0.8)
		return
	var mod = Color(0.8 + g.progress/1000.0, 1.0 - g.progress/1000.0, 0.8)
	MapName.modulate = mod
	Hide.modulate = mod

# ============================================= # ============================================= #
# Save map colors to an image
# ============================================= # ============================================= #
func PrintMap(batch=false):
	var map = Image.new()
	map.create(g.size.x * 2, g.size.y * 2, false, Image.FORMAT_RGB8)
	map.fill(Color(0,0,0))

	map.lock()
	var color
	for y in g.size.y:
		for x in g.size.x * 2:
			color = g.ColArray[y][x]
			if !color in ["def", "call", "white", "ground"]:
				color = g.ID2RAW(color)
				map.set_pixel(x, y * 2, color)
				map.set_pixel(x, y * 2 + 1, color)
	map.unlock()
	
	var path = OS.get_executable_path().get_base_dir().replace("\\", "/") + "/"
	var time = str(	"0".trim_prefix(str(int(OS.get_time().hour < 10))), OS.get_time().hour, "",
					"0".trim_prefix(str(int(OS.get_time().minute < 10))), OS.get_time().minute, "",
					"0".trim_prefix(str(int(OS.get_time().second < 10))), OS.get_time().second)
	var nick = "MAP_" + time
	if g.area:	nick = g.area + " [" + time + "]"
	if batch:	path += "Batch/"

	map.save_png(str(path, nick, ".png"))
	
	Tin.text = "OK\nPNG thumbnail saved\nat application folder"

# ============================================= # ============================================= #
# Generate map from an image
# ============================================= # ============================================= #
func MapPrint(src):
	var img = Image.new()
	img.load(src)
	
	ResetArrays("■")
	if img.get_size() != Vector2(g.size.x, g.size.y):
		img.resize(g.size.x, g.size.y, 0)
	img.lock()
	var color
	var precision = 20.0	# round colors to 0.05 to reduce lag
	
	var palette = []
	for y in img.get_height():
		for x in img.get_width():
			color = img.get_pixel(x, y)
			if !color in palette:
				palette.append(color)

	for y in img.get_height():
		for x in img.get_width():
			color = img.get_pixel(x, y)
			if palette.size() > 100:	# If more than 60 shades
				if palette.size() > 1000:
					precision = 5 # round to 0.2
				color = Color(
				round(color.r * precision) / precision,
				round(color.g * precision) / precision,
				round(color.b * precision) / precision)
			# Less than rgb[10,10,10]
			if color.r < 0.039 and color.g < 0.039 and color.b < 0.039:
				color = "def"
				g.Location[y][x * 2] = "　"
				g.Location[y][x * 2 + 1] = ""
			else:
				color = g.RAW2HEX(color)
			g.ColArray[y][x * 2] = color
			g.ColArray[y][x * 2 + 1] = color
	img.unlock()
	DrawMap()

# ============================================= # ============================================= #
# Update current frames per second for tiny counter in top right corner
# ============================================= # ============================================= #
func UpdateFPS():
	var val = Engine.get_frames_per_second()
	fps.text = str(val)
	if val >= 60:
		fps.modulate = Color(0, 1, 0)
	elif val >= 30:
		fps.modulate = Color(1, 1, 0)
	elif val >= 15:
		fps.modulate = Color(1, .5, 0)
	else:
		fps.modulate = Color(1, 0, 0)
