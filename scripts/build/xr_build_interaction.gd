class_name XRBuildInteraction
extends Node3D

@export var build_manager: BuildManager
@export var construction_root: Node3D
@export var collision_mask: int = 5

var _last_valid_transform: Dictionary = {}
var _invalid_parts: Dictionary = {}

func _ready() -> void:
    if build_manager:
        build_manager.add_to_group("build_manager")
    if construction_root:
        construction_root.child_entered_tree.connect(_on_part_added)
        for child in construction_root.get_children():
            _watch_part(child)

func _physics_process(_delta: float) -> void:
    if construction_root == null:
        return
    for child in construction_root.get_children():
        var part := child as ConstructionPart
        if part == null:
            continue
        if part.is_picked_up():
            _snap_held_part(part)
            _update_preview(part)
        elif not _invalid_parts.has(part):
            _update_preview(part)

func _on_part_added(node: Node) -> void:
    _watch_part(node)

func _watch_part(node: Node) -> void:
    var part := node as ConstructionPart
    if part == null:
        return
    if not part.picked_up.is_connected(_on_part_picked_up):
        part.picked_up.connect(_on_part_picked_up)
    if not part.dropped.is_connected(_on_part_dropped):
        part.dropped.connect(_on_part_dropped)

func _on_part_picked_up(part: XRToolsPickable) -> void:
    var construction_part := part as ConstructionPart
    if construction_part == null:
        return
    if build_manager:
        build_manager.selected_part = construction_part
    _last_valid_transform[construction_part] = construction_part.global_transform

func _on_part_dropped(part: XRToolsPickable) -> void:
    var construction_part := part as ConstructionPart
    if construction_part == null:
        return
    _snap_held_part(construction_part)
    if not _is_valid(construction_part):
        if _last_valid_transform.has(construction_part):
            construction_part.global_transform = _last_valid_transform[construction_part]
        _set_invalid(construction_part, false)
    else:
        _last_valid_transform[construction_part] = construction_part.global_transform
    _update_preview(construction_part)

func _snap_held_part(part: ConstructionPart) -> void:
    var snapped := GridSnapSystem.snap_world_position(part.global_position)
    if build_manager:
        build_manager.move_selected(snapped)
    else:
        part.global_position = snapped

func _is_valid(part: ConstructionPart) -> bool:
    var space_state := get_world_3d().direct_space_state
    return BuildPlacementValidator.is_position_valid(
        part,
        part.global_position,
        part.global_transform.basis,
        space_state,
        collision_mask
    )

func _update_preview(part: ConstructionPart) -> void:
    var valid := _is_valid(part)
    _set_invalid(part, not valid)

func _set_invalid(part: ConstructionPart, invalid: bool) -> void:
    if _invalid_parts.get(part, false) == invalid:
        return
    _invalid_parts[part] = invalid
    var mesh := part.get_node_or_null("Mesh") as MeshInstance3D
    if mesh == null:
        return
    if invalid:
        var red := StandardMaterial3D.new()
        red.albedo_color = Color(1.0, 0.05, 0.05, 0.72)
        red.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        red.emission_enabled = true
        red.emission = Color(1.0, 0.0, 0.0)
        red.emission_energy_multiplier = 2.0
        mesh.material_override = red
    else:
        mesh.material_override = null
