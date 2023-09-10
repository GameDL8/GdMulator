class_name RegisterFlags extends RefCounted


signal flags_changed(old_value, new_value)


var value: int:
	set = set_value,
	get = get_value
var name := StringName()

func _init(p_name: StringName):
	assert(p_name != StringName())
	name = p_name

func set_value(new_flags_bitmask):
	var old_value = value
	value = new_flags_bitmask
	if old_value != value:
		flags_changed.emit(old_value, value)

func get_value():
	return value
