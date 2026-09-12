class_name MobileUI
extends Control

signal enter_build
signal exit_build
signal place_block
signal place_propeller
signal rotate_left
signal rotate_right
signal delete_selected
signal duplicate_selected
signal save
signal load_starter
signal play
signal summon

func _ready() -> void:
	for button in get_tree().get_nodes_in_group("mobile_action"):
		button.pressed.connect(_handle_action.bind(button.name))

func _handle_action(action: String) -> void:
	match action:
		"EnterBuild": enter_build.emit()
		"ExitBuild": exit_build.emit()
		"Block": place_block.emit()
		"Propeller": place_propeller.emit()
		"RotateLeft": rotate_left.emit()
		"RotateRight": rotate_right.emit()
		"Delete": delete_selected.emit()
		"Duplicate": duplicate_selected.emit()
		"Save": save.emit()
		"LoadStarter": load_starter.emit()
		"Play": play.emit()
		"Summon": summon.emit()
