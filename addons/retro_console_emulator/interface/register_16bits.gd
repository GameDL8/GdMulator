class_name Register16bits extends RefCounted

var value: int = 0
var name := StringName()

func _init(p_name: StringName):
	assert(p_name != StringName())
	name = p_name
