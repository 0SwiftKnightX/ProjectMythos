extends Node3D

@onready var home_world: Node3D = $HomeWorld
@onready var build_area: Node3D = $BuildArea
@onready var lobby: Node3D = $Lobby
@onready var build_manager: BuildManager = $BuildArea/BuildManager
@onready var ui: Control = $MobileUI

func _ready() -> void:
	GameManager.register_contexts(home_world, build_area, lobby)
	build_manager.new_blueprint("Starter Craft")
	ui.enter_build.connect(func(): GameManager.set_context(GameManager.Context.BUILD_AREA))
	ui.exit_build.connect(func(): GameManager.set_context(GameManager.Context.HOME_WORLD))
	ui.place_block.connect(func(): build_manager.select_part_type("block_1m"))
	ui.place_propeller.connect(func(): build_manager.select_part_type("propeller"))
	ui.rotate_left.connect(func(): build_manager.rotate_selected(-1))
	ui.rotate_right.connect(func(): build_manager.rotate_selected(1))
	ui.delete_selected.connect(build_manager.delete_selected)
	ui.duplicate_selected.connect(build_manager.duplicate_selected)
	ui.save.connect(build_manager.save_active_blueprint)
	ui.load_starter.connect(func(): build_manager.load_blueprint("starter_flyer"))
	ui.play.connect(build_manager.test_current_vehicle)
	ui.summon.connect(_summon_active)

func _summon_active() -> void:
	if build_manager.active_blueprint == null:
		return
	build_manager.save_active_blueprint()
	SummonSystem.summon(build_manager.active_blueprint.id, home_world, Transform3D(Basis.IDENTITY, Vector3(0.0, 2.0, -4.0)))
