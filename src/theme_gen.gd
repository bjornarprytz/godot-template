@tool
extends ProgrammaticTheme
const UPDATE_ON_SAVE = true

@export var palette = preload("res://my_palette.tres")

func setup():
	set_save_path("res://generated/global_theme.tres")


var button_color = palette.primary
var button_hover_color = button_color.darkened(0.1)
var button_pressed_color = button_color.darkened(0.15)
var button_border_color = palette.accent
var default_border_width = 4 
var default_corner_radius = 5
var default_content_margins = content_margins(45, 35)

var panel_texture = preload("res://assets/panel-texture.png")

var default_font = preload("res://assets/fonts/Tiny5-Regular.ttf")
var default_font_size = 32

var title_font = preload("res://assets/fonts/Jersey15-Regular.ttf")
var title_font_size = 64

func define_theme():
	define_default_font(default_font)
	define_default_font_size(default_font_size)
		
	var button_style = stylebox_flat({
		bg_color = button_color,

		border_color = button_border_color,

		content_margin_ = default_content_margins,
		border_ = border_width(default_border_width),
		corner_ = corner_radius(default_corner_radius)
	})

	var button_hover_style = inherit(button_style, {
		bg_color = button_hover_color
	})

	var button_pressed_style = inherit(button_style, {
		bg_color = button_pressed_color
	})
	
	define_style("PanelContainer", {
		panel = stylebox_texture({
			texture = panel_texture,
			texture_margin_ = texture_margins(9),
			content_margin_ = default_content_margins,
			axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT,
			axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
			
		})
	})

	define_style("Button", {
		normal = button_style,
		hover = button_hover_style,
		pressed = button_pressed_style,
	})
	
	define_variant_style("Title", "RichTextLabel", {
		normal_font = title_font,
		normal_font_size = title_font_size
	})
