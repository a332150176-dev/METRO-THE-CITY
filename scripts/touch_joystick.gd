extends Control
class_name TouchJoystick

signal value_changed(value: Vector2)

@export var outer_radius: float = 76.0
@export var knob_radius: float = 27.0
var value: Vector2 = Vector2.ZERO
var active_touch: int = -1
var mouse_active: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(170, 170)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1:
			active_touch = event.index
			_update_from_position(event.position)
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			_set_value(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_from_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_active = event.pressed
		if mouse_active:
			_update_from_position(event.position)
		else:
			_set_value(Vector2.ZERO)
	elif event is InputEventMouseMotion and mouse_active:
		_update_from_position(event.position)

func _update_from_position(position: Vector2) -> void:
	var offset := position - size * 0.5
	var radius := maxf(1.0, outer_radius)
	_set_value(offset.limit_length(radius) / radius)

func _set_value(next_value: Vector2) -> void:
	value = next_value
	value_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, outer_radius, Color(0.04, 0.08, 0.13, 0.44))
	draw_arc(center, outer_radius, 0.0, TAU, 48, Color(0.78, 0.88, 0.96, 0.55), 3.0, true)
	draw_circle(center + value * outer_radius, knob_radius, Color(0.92, 0.96, 1.0, 0.86))
	draw_arc(center + value * outer_radius, knob_radius, 0.0, TAU, 32, Color(0.12, 0.22, 0.34, 0.8), 2.0, true)
