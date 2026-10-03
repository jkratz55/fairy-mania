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
		"beach":
			t.style = "sand"
			t.sky_top = Color(0.25, 0.62, 0.95)
			t.sky_bottom = Color(1.0, 0.9, 0.75)
			t.top = Color(1.0, 0.89, 0.62)
			t.top_dark = Color(0.9, 0.74, 0.46)
			t.fill = Color(0.93, 0.72, 0.47)
			t.fill_dark = Color(0.78, 0.55, 0.36)
			t.speck = Color(0.99, 0.84, 0.6)
			t.platform = Color(0.74, 0.57, 0.42)
			t.platform_dark = Color(0.5, 0.36, 0.26)
			t.hazard = Color(0.4, 0.26, 0.55)
			t.hazard_tip = Color(0.92, 0.78, 1.0)
			t.accents = [Color(1.0, 0.55, 0.55), Color(0.4, 0.9, 0.95), Color(1.0, 0.85, 0.35), Color(1.0, 0.95, 0.88)]
		"caves":
			t.style = "crystal"
			t.sky_top = Color(0.05, 0.04, 0.12)
			t.sky_bottom = Color(0.17, 0.1, 0.3)
			t.top = Color(0.44, 0.4, 0.66)
			t.top_dark = Color(0.31, 0.27, 0.5)
			t.fill = Color(0.21, 0.18, 0.33)
			t.fill_dark = Color(0.12, 0.1, 0.22)
			t.speck = Color(0.5, 0.92, 1.0)
			t.platform = Color(0.45, 0.85, 0.95)
			t.platform_dark = Color(0.25, 0.55, 0.78)
			t.hazard = Color(0.95, 0.38, 0.58)
			t.hazard_tip = Color(1.0, 0.86, 0.93)
			t.accents = [Color(0.4, 0.95, 1.0), Color(1.0, 0.5, 0.8), Color(1.0, 0.85, 0.4), Color(0.72, 0.56, 1.0)]
		"peaks":
			t.style = "snow"
			t.sky_top = Color(0.42, 0.58, 0.92)
			t.sky_bottom = Color(0.98, 0.86, 0.9)
			t.top = Color(0.97, 0.98, 1.0)
			t.top_dark = Color(0.76, 0.84, 0.96)
			t.fill = Color(0.52, 0.58, 0.73)
			t.fill_dark = Color(0.37, 0.41, 0.58)
			t.speck = Color(0.68, 0.74, 0.87)
			t.platform = Color(0.72, 0.9, 1.0)
			t.platform_dark = Color(0.45, 0.66, 0.88)
			t.hazard = Color(0.55, 0.78, 0.98)
			t.hazard_tip = Color(1.0, 1.0, 1.0)
			t.accents = [Color(0.6, 0.85, 1.0), Color(1.0, 0.6, 0.72), Color(1.0, 1.0, 1.0), Color(0.75, 0.65, 1.0)]
		"orchard":
			t.style = "leaf"
			t.sky_top = Color(0.45, 0.6, 0.92)
			t.sky_bottom = Color(1.0, 0.84, 0.6)
			t.top = Color(0.95, 0.62, 0.26)
			t.top_dark = Color(0.8, 0.42, 0.18)
			t.fill = Color(0.56, 0.37, 0.26)
			t.fill_dark = Color(0.42, 0.26, 0.19)
			t.speck = Color(0.68, 0.48, 0.34)
			t.platform = Color(0.6, 0.4, 0.27)
			t.platform_dark = Color(0.42, 0.27, 0.17)
			t.hazard = Color(0.52, 0.6, 0.25)
			t.hazard_tip = Color(1.0, 0.95, 0.7)
			t.accents = [Color(0.93, 0.26, 0.26), Color(1.0, 0.78, 0.25), Color(1.0, 0.52, 0.2), Color(0.7, 0.4, 0.62)]
		"candy":
			t.style = "frosting"
			t.sky_top = Color(0.6, 0.55, 0.95)
			t.sky_bottom = Color(1.0, 0.82, 0.9)
			t.top = Color(1.0, 0.74, 0.86)
			t.top_dark = Color(0.93, 0.52, 0.72)
			t.fill = Color(0.56, 0.34, 0.26)
			t.fill_dark = Color(0.4, 0.23, 0.19)
			t.speck = Color(1.0, 0.95, 0.9)
			t.platform = Color(0.98, 0.83, 0.56)
			t.platform_dark = Color(0.84, 0.6, 0.36)
			t.hazard = Color(1.0, 0.62, 0.2)
			t.hazard_tip = Color(1.0, 1.0, 0.95)
			t.accents = [Color(1.0, 0.45, 0.65), Color(0.5, 0.85, 1.0), Color(1.0, 0.9, 0.4), Color(0.55, 0.92, 0.65)]
		"falls":
			t.style = "falls"
			t.sky_top = Color(0.36, 0.68, 0.98)
			t.sky_bottom = Color(0.86, 0.97, 0.96)
			t.top = Color(0.4, 0.82, 0.5)
			t.top_dark = Color(0.24, 0.62, 0.42)
			t.fill = Color(0.47, 0.54, 0.64)
			t.fill_dark = Color(0.34, 0.39, 0.52)
			t.speck = Color(0.6, 0.67, 0.76)
			t.platform = Color(0.45, 0.78, 0.4)
			t.platform_dark = Color(0.28, 0.56, 0.3)
			t.hazard = Color(0.62, 0.4, 0.78)
			t.hazard_tip = Color(0.96, 0.82, 1.0)
			t.accents = [Color(1.0, 0.5, 0.52), Color(1.0, 0.82, 0.4), Color(0.5, 0.85, 1.0), Color(0.76, 0.6, 1.0)]
		"castle":
			t.style = "castle"
			t.sky_top = Color(0.1, 0.07, 0.22)
			t.sky_bottom = Color(0.34, 0.2, 0.44)
			t.top = Color(0.58, 0.48, 0.76)
			t.top_dark = Color(0.42, 0.33, 0.6)
			t.fill = Color(0.34, 0.28, 0.48)
			t.fill_dark = Color(0.22, 0.18, 0.34)
			t.speck = Color(0.27, 0.22, 0.4)
			t.platform = Color(0.6, 0.52, 0.78)
			t.platform_dark = Color(0.4, 0.33, 0.58)
			t.hazard = Color(0.48, 0.3, 0.72)
			t.hazard_tip = Color(0.95, 0.75, 1.0)
			t.accents = [Color(1.0, 0.82, 0.4), Color(1.0, 0.55, 0.8), Color(0.55, 0.85, 1.0), Color(0.75, 0.55, 1.0)]
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
