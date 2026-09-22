class_name BuildTouchInput
extends Node

@export var camera: Camera3D
@export var build_manager: BuildManager
@export var build_plane_y := 0.0
var _dragging := false

func _ready() -> void:
	if camera == null:
		camera = get_parent().get_node_or_null("BuildCamera") as Camera3D
	if build_manager == null:
		build_manager = get_parent().get_node_or_null("BuildManager") as BuildManager

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.current_context == GameManager.Context.BUILD_AREA:
		return
	if event is InputEventScreenTouch:
		_dragging = event.pressed
		if event.pressed:
			_handle_press(event.position)
	if event is InputEventScreenDrag and _dragging and build_manager.selected_part != null:
		build_manager.move_selected(_screen_to_build_plane(event.position))

func _handle_press(screen_position: Vector2) -> void:
	var from := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * 100.0)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider := hit.collider as Node
		var part := _find_part(collider)
		if part != null:
			build_manager.selected_part = part
			return
	build_manager.place_part(_screen_to_build_plane(screen_position))

func _screen_to_build_plane(screen_position: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	if is_zero_approx(direction.y):
		return origin
	return origin + direction * ((build_plane_y - origin.y) / direction.y)

func _find_part(node: Node) -> ConstructionPart:
	while node != null:
		if node is ConstructionPart:
			return node
		node = node.get_parent()
	return null
