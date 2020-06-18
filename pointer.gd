# ============================================= # ============================================= #
# Row/col pointers on left and top of canvas
# Handling row/col shifting and coloring
# ============================================= # ============================================= #
extends Control

var axisx = true
var num = 0

# ============================================= # ============================================= #
# Init
# ============================================= # ============================================= #
func _ready():
	_on_Label_mouse_exited()

# ============================================= # ============================================= #
func _on_Label_mouse_entered():
	set_modulate(Color(1,.6,0))

# ============================================= # ============================================= #
func _on_Label_mouse_exited():
	set_modulate(Color(.5,.6,.5))

# ============================================= # ============================================= #
func _on_Control_gui_input(event):
	if Input.is_action_just_pressed("middle_click"):
		g.root.Transcribe()
	if Input.is_action_pressed("middle_click"):
		if !g.IsHover(self):
			_on_Label_mouse_exited()
		if !num: # ×
			g.root.ResetArrays()
			g.root.ResetColors()
		elif axisx:
			for i in range(g.size.y):
				g.root.Draw(g.snap.x, i, "　")
				g.root.Colour(g.snap.x, i, "def")
		elif !g.bias:
			for i in range(g.size.x):
				g.root.Draw(i * 2, g.snap.y, "　")
				g.root.Colour(i, g.snap.y, "def")
		g.root.DrawMap()
	if !(event is InputEventMouseButton and event.doubleclick):
		return
	if Input.is_action_pressed("right_click") and g.warp:
			Shift(axisx, false)
			return
	# Double clicked
	if Input.is_action_pressed("left_click"):
		if g.warp:
			Shift(axisx, true)
			return
		elif !num: # ×
			g.root.ResetArrays(g.b)
		elif axisx:
			for i in range(g.size.y):
				g.root.Draw(g.snap.x, i)
		elif !g.bias:
			for i in range(g.size.x * (1 + g.IsHalf(g.b))):
				g.root.Draw(i * (2 - g.IsHalf(g.b)), g.snap.y)
	# Double clicked
	if Input.is_action_pressed("left_click") and g.mode or Input.is_action_pressed("right_click"):
		if !num: # ×
			g.root.ResetColors(g.c)
		elif axisx:
			for i in range(g.size.y):
				g.root.Colour(g.snap.x, i)
		elif !g.bias:
			for i in g.ColArray[g.snap.y].size():
				if g.ColArray[g.snap.y][i]:
					g.ColArray[g.snap.y][i] = g.c
	g.root.DrawMap()
	g.root.Transcribe()

# ============================================= # ============================================= #
# Pop/add lines/rows on ctrl+click
# ============================================= # ============================================= #
func Shift(isx=1, add=1):
	var sat = g.snap.x #(num - 1) * 2
	if isx and add and sat < g.size.x * 2 - 2:
		for i in range(g.size.y):
			var nextNull = int(!bool(g.Location[i][sat + 1]))
			if g.IsHalf(g.b) and sat in range(1, g.size.x * 2 - 2): #sat + nextNull < sat * 2 - 2:
				# if last element is 2-byte symbol - free 2 cells
				if !g.Location[i].back():
					g.Location[i].pop_back()
					g.Location[i].pop_back()
					g.Location[i].push_back(" ")
					g.ColArray[i].pop_back()
					g.ColArray[i].pop_back()
					g.ColArray[i].push_back("def")
				# otherwise free just 1 cell
				else:
					g.Location[i].pop_back()
					g.ColArray[i].pop_back()
				g.Location[i].insert(sat - 1 + nextNull, " ")
				g.ColArray[i].insert(sat - 1 + nextNull, "def")
			if !g.IsHalf(g.b) and sat in range(1, g.size.x * 2 - 2): #sat + nextNull < sat * 2 - 2:
				# if penult element is 2-byte symbol - free 3 cells
				if !g.Location[i][-2]:
					g.Location[i].pop_back()
					g.Location[i].pop_back()
					g.Location[i].pop_back()
					g.Location[i].push_back(" ")
					g.ColArray[i].pop_back()
					g.ColArray[i].pop_back()
					g.ColArray[i].pop_back()
					g.ColArray[i].push_back("def")
				# otherwise free just 2 cell
				else:
					g.Location[i].pop_back()
					g.Location[i].pop_back()
					g.ColArray[i].pop_back()
					g.ColArray[i].pop_back()
				g.Location[i].insert(sat - 1 + nextNull, "")
				g.Location[i].insert(sat - 1 + nextNull, "　")
				g.ColArray[i].insert(sat - 1 + nextNull, "def")
				g.ColArray[i].insert(sat - 1 + nextNull, "def")
	elif isx and !add:
		for i in range(g.size.y):
			var nextNull = int(!bool(g.Location[i][sat + 1]))
			# FULL on FULL
			if !g.IsHalf(g.b) and nextNull:
				g.Location[i].remove(sat)
				g.Location[i].remove(sat)
				g.Location[i].push_back("　")
				g.Location[i].push_back("")
				g.ColArray[i].remove(sat)
				g.ColArray[i].remove(sat)
				g.ColArray[i].push_back("def")
				g.ColArray[i].push_back("def")
			#FULL on NULL
			elif !g.IsHalf(g.b) and !g.Location[i][sat]:
				g.Location[i].remove(sat - 1)
				g.Location[i].remove(sat - 1)
				g.Location[i].push_back("　")
				g.Location[i].push_back("")
				g.ColArray[i].remove(sat - 1)
				g.ColArray[i].remove(sat - 1)
				g.ColArray[i].push_back("def")
				g.ColArray[i].push_back("def")
			# HALF on FULL
			elif g.IsHalf(g.b) and nextNull:
				g.Location[i][sat + 1] = " "
				g.Location[i].remove(sat)
				g.Location[i].push_back(" ")
				g.ColArray[i][sat + 1] = "def"
				g.ColArray[i].remove(sat)
				g.ColArray[i].push_back("def")
			# HALF on NULL
			elif g.IsHalf(g.b) and !g.Location[i][sat]:
				g.Location[i][sat - 1] = " "
				g.Location[i].remove(sat)
				g.Location[i].push_back(" ")
				g.ColArray[i][sat - 1] = "def"
				g.ColArray[i].remove(sat)
				g.ColArray[i].push_back("def")
			# HALF on HALF
			elif g.IsHalf(g.b):
				g.Location[i].remove(sat)
				g.Location[i].push_back(" ")
				g.ColArray[i].remove(sat)
				g.ColArray[i].push_back("def")
	elif !isx and add:
		sat = num - 1
		if sat >= g.size.y - 1: return
		g.Location.pop_back()
		g.ColArray.pop_back()
		g.Location.insert(sat, g.Location[sat].duplicate())
		g.ColArray.insert(sat, g.ColArray[sat].duplicate())
		for i in g.size.x:
			g.Location[sat][i * 2] = "　"
			g.Location[sat][i * 2 + 1] = ""
			g.ColArray[sat][i * 2] = "def"
			g.ColArray[sat][i * 2 + 1] = "def"
	elif !isx and !add:
		sat = num - 1
		if sat >= g.size.y - 1: return
		g.Location.remove(sat)
		g.ColArray.remove(sat)
		g.Location.insert(g.size.y - 1, g.Location[sat].duplicate())
		g.ColArray.insert(g.size.y - 1, g.ColArray[sat].duplicate())
		for i in g.size.x:
			g.Location[g.size.y - 1][i * 2] = "　"
			g.Location[g.size.y - 1][i * 2 + 1] = ""
			g.ColArray[g.size.y - 1][i * 2] = "def"
			g.ColArray[g.size.y - 1][i * 2 + 1] = "def"
	g.root.DrawMap()
	g.root.Transcribe()
