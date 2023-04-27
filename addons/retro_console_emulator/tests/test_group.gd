extends Node

func test():
	for test_script in get_children():
		if &"test" in test_script:
			test_script.test()
