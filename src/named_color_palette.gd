class_name NamedColorPalette
extends ColorPalette

@export var primary: Color = Color("1446A0"):
	set(value):
		primary = value
		_update_colors()

@export var secondary: Color = Color("DB3069"):
	set(value):
		secondary = value
		_update_colors()
@export var accent: Color = Color("F5D547"):
	set(value):
		accent = value
		_update_colors()
@export var background: Color = Color("3C3C3B"):
	set(value):
		background = value
		_update_colors()
@export var foreground: Color = Color("EBEBD3"):
	set(value):
		foreground = value
		_update_colors()
@export var highlight: Color = Color("539987"):
	set(value):
		highlight = value
		_update_colors()

@export var extra_colors: PackedColorArray = []:
	set(value):
		extra_colors = value
		_update_colors()

func _update_colors():
	colors = _get_colors()

func _get_colors() -> Array:
	var my_colors = [
		primary,
		secondary,
		accent,
		background,
		foreground,
		highlight
	]
	my_colors += extra_colors
	return my_colors
