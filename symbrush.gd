# ======================================================= #
# Brush selector, operating current brush and history
# ======================================================= #
extends TextEdit

export(int) var step
var cols = 10	# palette width
var hinter		# if mouse overlays
var select		# ColorRect node
var focus		# ColorRect node
var History

# ============================================= # ============================================= #
# Init
# ============================================= # ============================================= #
func _ready():
	step = get_font("font").size # Set cell size to 14 px
	History = ["　","　","　","　","　","　"]
	Transcribe()
	
	# Disable antialiasing
	get_font("font").font_data.antialiased = false
	get_font("font").use_filter = true
	get_font("font").use_filter = false
	
	# Color rect to display over hovered cell
	hinter = ColorRect.new()
	hinter.set_frame_color(Color(1,1,1,.3))	# Light gray
	hinter.set_visible(false)
	hinter.set_mouse_filter(1)
	add_child(hinter)
	
	# Color rect to display over selected cell
	select = ColorRect.new()
	select.set_frame_color(Color(1,.8,.4,.5))	# Yellow
	select.set_visible(false)
	select.set_mouse_filter(1)
	add_child(select)
	
	# H0 node shows current brush, H1-H5 show previous ones and may be clicked to switch back
	for i in 5:
		get_parent().get_node(str("H", i+1)).get_child(0).connect("pressed", self, "Transcribe", [i+1])
		get_parent().get_node(str("H", i+1)).get_child(0).connect("pressed", self, "ParseMatch")
	
	connect("text_changed", self, "Refresh")
	update()
	
# ============================================= # ============================================= #
# Always
# ============================================= # ============================================= #
func _process(delta):
	if g.IsHover(self):	# If mouse over palette
		focus = true	# Toggle flag to remove focus when unhovered
		var content = get_text()
		var hover		# Temp to store hovered brush
		var cells = 0	# Current in-row position
		var shift = 0	# Current row
		var size		# ==0.5 if single byte
		shift -= get_v_scroll()
		for ch in range(content.length()):
			size = 1 - 0.5 * int(g.IsHalf(content[ch].to_lower()))
			if cells + size > cols || content[ch] == "\n":
				cells = 0
				shift += 1
			if content[ch] != "\n":	
				cells += size
			if g.mpos.x - get_global_transform_with_canvas().get_origin().x in range(cells * step - step * size, cells * step) && \
			g.mpos.y - get_global_transform_with_canvas().get_origin().y in range(shift * step, shift * step + step):
				Hinter(1, 0, Vector2(cells * step - step * size, shift * step + 1), size)
				hover = content[ch]
				break
				
		if Input.is_action_just_pressed("left_click") and hover:
			g.b = hover
			if g.b == ";":
				g.b = " "
			Hinter(1, 1, Vector2(cells * step - step * size, shift * step + 1), size)
			Transcribe()
			
	elif focus:
		Hinter()
		deselect()
		release_focus()

# ============================================= # ============================================= #
# Draws grid cell for each element
# ============================================= # ============================================= #
func _draw():
	var vo = -get_v_scroll() * g.step
	var content = get_text()
	var size			# ==0.5 if single byte
	var pos = [0, 0]	# row and col position
	for ch in range(content.length()):
		size = 1 - 0.5 * int(g.IsHalf(content[ch].to_lower()))
		if pos[0] + size > cols || content[ch] == "\n" || \
		content[ch - 1] == " " && content[ch] != " " && CalcWidth(content.substr(ch, 18).split("\n")[0]) > 10 - pos[0]:
			pos[0] = 0
			pos[1] += 1
		if content[ch] != "\n":	
			pos[0] += size
			draw_rect(Rect2(pos[0] * step, pos[1] * step + vo, step * (-size), step), Color(pos[0]/cols,1-pos[0]/cols,1,.33), false)
	draw_line(Vector2(1, 0) + Vector2(0, vo), Vector2(1, (pos[1] + 1) * step) + Vector2(0, vo), Color(1/cols, 1-1/cols,1,.33))

# ============================================= # ============================================= #
# Pick active brush and redraw grid
# ============================================= # ============================================= #
func Refresh():
	ParseMatch()
	update()

# ============================================= # ============================================= #
# Return string width in bytes/2
# ============================================= # ============================================= #
func CalcWidth(string):
	var width = 0
	for sym in string:
		width += 1 - 0.5 * int(g.IsHalf(sym.to_lower()))
	return width
	
# ============================================= # ============================================= #
# Move/toggle hinter/select markers
# ============================================= # ============================================= #
func Hinter(comm=0, item=0, pos=0, width=1):
	hinter.set_visible(false)
	if comm:
		if item:
			select.set_size(Vector2(step * width - 1, step - 1))
			select.set_visible(true)
			if pos:
				select.set_position(pos)
		else:
			hinter.set_size(Vector2(step * width - 1, step - 1))
			if hinter.get_position() != select.get_position():
				hinter.set_visible(true)
			if pos:
				hinter.set_position(pos)
	elif item:
		select.set_visible(false)

# ============================================= # ============================================= #
# Updates brush history pushing current one in front and removing last entry
# ============================================= # ============================================= #
func Transcribe(num=0):
	if !num and History[0] == g.b:
		return
	if num:
		g.b = History[num]
		History.push_front(History[num])
	else:
		History.push_front(g.b)
	History.pop_back()
	for i in 6:
		get_parent().get_node(str("H", i)).set_text(History[i])
		if !i:
			get_parent().get_node(str("H", i)).add_color_override("font_color_shadow", Color(0,0,0))
			get_parent().get_node(str("H", i)).get_child(0).set_default_color(Color(1,1,1))
			get_parent().get_node(str("H", i)).get_child(0).set_points(
			[Vector2(0, 1), Vector2(0, 24), Vector2(23, 24), Vector2(23, 0), Vector2(0, 0)])
			if g.IsHalf(History[i].to_lower()):
				get_parent().get_node(str("H", i)).add_color_override("font_color_shadow", Color(1,0,0))
				get_parent().get_node(str("H", i)).get_child(0).set_default_color(Color(1,0,0))
				get_parent().get_node(str("H", i)).get_child(0).set_points(
				[Vector2(4, 1), Vector2(4, 24), Vector2(19, 24), Vector2(19, 0), Vector2(4, 0)])

# ============================================= # ============================================= #
# Searches active brush in grid and highlights the cell
# ============================================= # ============================================= #
func ParseMatch(arg=false):
	if arg:
		g.b = arg
	var content = get_text()
	var size
	var pos = [0, 0]
	for ch in range(content.length()):
		size = 1 - 0.5 * int(g.IsHalf(content[ch].to_lower()))
		if content[ch] == g.b:
			if pos[0] + size > cols:
				pos[0] = 0
				pos[1] += 1
			Hinter(1, 1, Vector2(pos[0] * step, pos[1] * step + 1), size)
			return
		if pos[0] + size > cols || content[ch] == "\n":
			pos[0] = 0
			pos[1] += 1
		if content[ch] != "\n":	
			pos[0] += size
	set_text(str(get_text(), g.b))	# If no match (char deleted) add char
