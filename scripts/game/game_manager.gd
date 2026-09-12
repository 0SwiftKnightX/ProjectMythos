extends Node

enum Context { HOME_WORLD, BUILD_AREA, LOBBY }
var current_context := Context.HOME_WORLD
var home_world: Node3D
var build_area: Node3D
var lobby: Node3D

func register_contexts(home: Node3D, build: Node3D, social_lobby: Node3D) -> void:
	home_world = home
	build_area = build
	lobby = social_lobby
	set_context(Context.HOME_WORLD)

func set_context(context: Context) -> void:
	current_context = context
	home_world.visible = context == Context.HOME_WORLD
	build_area.visible = context == Context.BUILD_AREA
	lobby.visible = context == Context.LOBBY
