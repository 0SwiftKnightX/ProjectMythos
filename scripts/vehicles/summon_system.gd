extends Node

var _builder := BlueprintBuilder.new()

func summon(blueprint_id: String, parent: Node, summon_transform: Transform3D) -> PhysicsVehicle:
	var blueprint := BlueprintManager.load_blueprint(blueprint_id)
	if blueprint == null:
		push_error("Cannot summon unknown blueprint: %s" % blueprint_id)
		return null
	return _builder.build_runtime(blueprint, parent, summon_transform)
