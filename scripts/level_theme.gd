class_name LevelTheme
extends RefCounted
## Color palette and art style for one environment.

var id: String = "meadow"
var style: String = "grass"
var sky_top: Color
var sky_bottom: Color
var top: Color
var top_dark: Color
var fill: Color
var fill_dark: Color
var speck: Color
var platform: Color
var platform_dark: Color
var hazard: Color
var hazard_tip: Color
var accents: Array[Color] = []


static func create(theme_id: String) -> LevelTheme:
	var t := LevelTheme.new()
	t.id = theme_id
	match theme_id:
		"woods":
			t.style = "moss"
			t.sky_top = Color(0.1, 0.07, 0.24)
			t.sky_bottom = Color(0.5, 0.28, 0.55)
			t.top = Color(0.33, 0.78, 0.62)
			t.top_dark = Color(0.2, 0.52, 0.47)
			t.fill = Color(0.33, 0.22, 0.33)
			t.fill_dark = Color(0.24, 0.15, 0.26)
			t.speck = Color(0.55, 1.0, 0.85)
			t.platform = Color(0.93, 0.4, 0.6)
			t.platform_dark = Color(0.66, 0.22, 0.44)
			t.hazard = Color(0.42, 0.25, 0.55)
			t.hazard_tip = Color(0.85, 0.65, 1.0)
			t.accents = [Color(0.45, 1.0, 0.9), Color(1.0, 0.55, 0.85), Color(0.55, 0.75, 1.0), Color(1.0, 0.9, 0.5)]
		"sky":
			t.style = "cloud"
			t.sky_top = Color(0.1, 0.12, 0.36)
			t.sky_bottom = Color(1.0, 0.72, 0.62)
			t.top = Color(1.0, 1.0, 1.0)
			t.top_dark = Color(0.86, 0.84, 0.98)
			t.fill = Color(0.94, 0.93, 1.0)
			t.fill_dark = Color(0.78, 0.75, 0.95)
			t.speck = Color(1.0, 0.95, 0.75)
			t.platform = Color(1.0, 0.83, 0.42)
			t.platform_dark = Color(0.86, 0.6, 0.26)
			t.hazard = Color(0.45, 0.52, 0.9)
			t.hazard_tip = Color(0.9, 0.97, 1.0)
			t.accents = [Color(1.0, 0.9, 0.45), Color(1.0, 0.65, 0.8), Color(0.6, 0.9, 1.0), Color(0.85, 0.75, 1.0)]
		_:
			t.id = "meadow"
			t.style = "grass"
			t.sky_top = Color(0.42, 0.72, 0.98)
			t.sky_bottom = Color(0.86, 0.96, 1.0)
			t.top = Color(0.47, 0.82, 0.36)
			t.top_dark = Color(0.3, 0.63, 0.28)
			t.fill = Color(0.74, 0.52, 0.33)
			t.fill_dark = Color(0.6, 0.4, 0.25)
			t.speck = Color(0.63, 0.43, 0.27)
			t.platform = Color(0.85, 0.63, 0.4)
			t.platform_dark = Color(0.6, 0.41, 0.25)
			t.hazard = Color(0.5, 0.3, 0.38)
			t.hazard_tip = Color(0.95, 0.88, 0.8)
			t.accents = [Color(1.0, 0.6, 0.75), Color(1.0, 0.9, 0.4), Color(1.0, 1.0, 1.0), Color(0.75, 0.6, 1.0)]
	return t
