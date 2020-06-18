# ============================================= # ============================================= #
# Compact manual in the right panel
# ============================================= # ============================================= #
extends Label

var page = 0
# Hint text can be edited from inspector, uses "@" symbol as page deimiter
export(String, MULTILINE) var pages = "========== PAGE 1/3 ==========\nLMB.......Assign char\nRMB.......Assign color\nLMBx2.....Swap char on match\nRMBx2.....Swap color on match\nMMB.......Clear cell\nWheel.....Navigate palette\nShift.....Toggle bias draw\nCtrl......Toggle pop/push:\n          LMB | RMB | X1 | X2\nAlt+LMB...Pick symbol sample\nAlt+RMB...Pick color sample\nCtrl+Q....Swap space width\nCtrl+W....Select def color\nCtrl+E....Export .ERB\nCtrl+S....Export .json (Save)\nCtrl+D....Toggle swap filter\n          (char | char & col)\nCtrl+F....Toggle drawing mode:\n          (char | char & col)\nCtrl+G....Toggle grid (Alt+G)\nCtrl+H....Toggle drawing mode:\n          (click | hold)\nCtrl+R....Minimize window\nCtrl+P....Save screen\nCtrl+Z....Undo action\nAlt+Z.....Redo action@========== PAGE 2/3 ==========\nTab.......Toggle this panel\nA-Z|1-9...Select symbol, hold\n          Shift for uppercase\nNumPad....Select frame symbol\n          1-9 cross elements\n          0+/* line elements\nCtrl+O....Screencap through\n          days 1-120 (laggy)\n[!] Double click row/column\npointers to fill a line\n[!] Double click x pointer in\ncorner to fill whole canvas\n[!] Double click row/column\npointer with Ctrl to pop/push\n[!] Click character table to\ntype or paste a custom symbol\n[!] RMB wide color sample to\nopen a color picker window\n[!] Custom colors may be\nstored within picker popup\n[!] Don't worry to color\nempty cells - they stay def\n[!] Load empty text field\nto reset the map\n[!] Backup often\n[¡] Cirno stronk@========== PAGE 3/3 ==========\nMISC AND EXPERIMENTAL CONTROL:\n\nAlt+G.....Change grid opacity\nCtrl+A....Draw line/rect/fill\n          from last edited cell\n          towards clicked cell\nCtrl+I....Invert map colors\n\n[!] Drag&drop an image to use\nits colors for a map draft\nCtrl+M....Export current map\n          state as 64x42 PNG"
				
# ============================================= # ============================================= #
func _ready():
	pages = pages.split("@")
	set_text(pages[0])

# ============================================= # ============================================= #
func _on_Hint_gui_input(event):
	if Input.is_action_just_pressed("left_click"):
		page = (page + 1) * int(page < 2)
		set_text(pages[page])

# ============================================= # ============================================= #
func _on_Hint_mouse_entered():
	set_modulate(Color(1.1,1.1,1.1))

# ============================================= # ============================================= #
func _on_Hint_mouse_exited():
	set_modulate(Color(1,1,1))
