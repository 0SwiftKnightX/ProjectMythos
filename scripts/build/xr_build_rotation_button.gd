class_name XRBuildRotationButton
extends XRToolsInteractableArea

@export var axis := Vector3.UP
@export var direction := 1

func _ready() -> void:
    pointer_event.connect(_on_pointer_event)

func _on_pointer_event(event: XRToolsPointerEvent) -> void:
    if event.event_type == XRToolsPointerEvent.Type.PRESSED:
        var build_manager := get_tree().get_first_node_in_group("build_manager") as BuildManager
        if build_manager:
            build_manager.rotate_selected_axis(axis, direction)
