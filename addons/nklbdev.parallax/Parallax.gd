tool
extends Node2D
class_name Parallax

const _max_arrow_size: float = 6.0
const _line_width: float = 1.4
const _arrow_points = PoolVector2Array([Vector2.ZERO, Vector2(-1, 0.5),	Vector2(-1, -0.5)])
var _draw_color: Color
var _draw_enabled_color: Color
var _draw_disabled_color: Color

enum ProcessMode {
	PROCESS = 0,
	PHYSICS_PROCESS = 1
}

export(bool) var enabled: bool = true setget _set_enabled
func _set_enabled(value: bool):
	if enabled == value:
		return
	enabled = value
	_update_position()
	_update_draw_color()

export(bool) var enabled_in_editor: bool = false setget _set_enabled_in_editor
func _set_enabled_in_editor(value: bool):
	if enabled_in_editor == value:
		return
	enabled_in_editor = value
	if Engine.editor_hint and not enabled_in_editor:
		position = Vector2.ZERO
	else:
		_update_position()

export(Vector2) var motion_scale: Vector2 = Vector2.ZERO setget _set_motion_scale
func _set_motion_scale(value: Vector2):
	if motion_scale == value:
		return
	motion_scale = value
	_update_position()

export(Vector2) var motion_offset: Vector2 = Vector2.ZERO setget _set_motion_offset
func _set_motion_offset(value: Vector2):
	if motion_offset == value:
		return
	motion_offset = value
	_update_position()

export(ProcessMode) var process_mode: int = ProcessMode.PROCESS

func _update_position() -> void:
	if enabled and (enabled_in_editor or not Engine.editor_hint) and is_inside_tree():
		var parent = get_parent()
		if parent is Node2D:
			var screen_center_local = (parent.get_viewport_transform() * parent.get_global_transform()) \
				.affine_inverse().xform(get_viewport().size / 2)
			position = screen_center_local * parent.global_scale * motion_scale * parent.global_scale + motion_offset
	update()

func _process(_delta: float) -> void:
	if process_mode == ProcessMode.PROCESS:
		_update_position()

func _physics_process(delta: float) -> void:
	if process_mode == ProcessMode.PHYSICS_PROCESS:
		_update_position()

func _draw():
	if Engine.editor_hint or get_tree().debug_collisions_hint:
		_draw_arrow(-position, -motion_offset)
		_draw_arrow(-motion_offset, Vector2.ZERO, true)

func _enter_tree():
	ProjectSettings.connect("project_settings_changed", self, "_on_project_settings_changed")
	_on_project_settings_changed()

func _exit_tree():
	ProjectSettings.disconnect("project_settings_changed", self, "_on_project_settings_changed")

func _update_draw_color():
	_draw_color = _draw_enabled_color if enabled else _draw_disabled_color

func _on_project_settings_changed():
	_draw_enabled_color = ProjectSettings.get_setting("debug/shapes/collision/shape_color") as Color
	var gray = _draw_enabled_color.v
	_draw_disabled_color = Color(gray, gray, gray)
	_update_draw_color()

func _draw_arrow(from: Vector2, to: Vector2, with_triangle: bool = false) -> void:
	from = from.rotated(-rotation) / scale
	to = to.rotated(-rotation) / scale
	draw_circle(from, 2.5, _draw_color)
	if not with_triangle:
		draw_line(from, to, _draw_color, _line_width)
		return
	var distance = from.distance_to(to)
	var arrow_size = clamp(distance * 2 / 3, _line_width, _max_arrow_size)

	var path = to - from
	if distance < _line_width:
		arrow_size = distance
	else:
		draw_line(from, to - path.normalized() * arrow_size, _draw_color, _line_width)

	draw_colored_polygon((Transform2D(0, to) * Transform2D() \
		.scaled(Vector2.ONE * arrow_size) \
		.rotated(path.angle())) \
		.xform(_arrow_points), _draw_color)
