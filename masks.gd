# ============================================= # ============================================= #
# Flags markers, indicate characters with special colors (foliage, water, etc.) 
# ============================================= # ============================================= #
extends Node2D

var tone
var flick = 0

# ============================================= # ============================================= #
# Init
# ============================================= # ============================================= #
func _ready():
	pass # Replace with function body.

# ============================================= # ============================================= #
# Draws mask squares under map
# ============================================= # ============================================= #
func _draw():
	if g.mark:
		for idy in g.size.y:
			for idx in g.size.x*2:
				if g.ColArray[idy][idx] in g.Flags: #and (g.Location[idy][idx] or !g.IsHalf(g.Location[idy][idx-1])):
					tone = g.Flags.get(g.ColArray[idy][idx])[2]
					tone.a = 0.5
					draw_rect(Rect2(11+idx*g.step/2, 9+idy*g.step, g.step/2, g.step), tone)

# ============================================= # ============================================= #
# Always
# ============================================= # ============================================= #
func _process(delta):
	if g.mark:
		flick += delta * 3.0	# Flicker amplitude
		if flick >= 360: flick = 0	# cos = -1...1
		set_modulate(Color(1, 1, 1, 0.75 + cos(flick)/4.0))	# If markers shown - flicker from 50% to 150%
	update()
