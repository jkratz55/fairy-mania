class_name LevelData
extends Resource
## One level. The layout is plain text (one character per 32x32 tile) so it is easy to edit.
##
## Legend:
##   .  empty                  #  solid ground         =  one-way platform
##   P  player start           G  goal gate            C  checkpoint lantern
##   o  pixie dust             h  heart                *  pixie bloom (instant flight)
##   ?  star block (bump it)   T  bouncy spring         S  hint sign (text from `signs`, left to right)
##   g  walking enemy          f  flying enemy (up/down) b  flying enemy (left/right)
##   ^  thorns                 M  moving platform (left/right)   V  moving platform (up/down)

@export var title: String = "New Level"
@export var subtitle: String = ""
@export_enum("meadow", "woods", "beach", "caves", "peaks", "orchard", "candy", "falls", "sky") var theme: String = "meadow"
@export var music: String = "meadow"
@export var signs: PackedStringArray = PackedStringArray()
@export_multiline var layout: String = ""
