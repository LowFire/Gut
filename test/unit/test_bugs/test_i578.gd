extends GutTest

class InputSingletonTracker:
	extends Node
	var pressed_frames = []
	var just_pressed_count = 0
	var just_released_count = 0

	var _frame_counter = 0

	func _process(delta):
		_frame_counter += 1

		if(Input.is_action_just_pressed("jump")):
			just_pressed_count += 1

		if(Input.is_action_just_released("jump")):
			just_released_count += 1

		if Input.is_action_pressed("jump"):
			pressed_frames.append(_frame_counter)

class TestInputSingleton:
	extends "res://addons/gut/test.gd"
	var _sender = InputSender.new(Input)

	func before_all():
		InputMap.add_action("jump")

	func after_all():
		InputMap.erase_action("jump")

	func after_each():
		_sender.release_all()
		# Wait for key release to be processed. Otherwise the key release is
		# leaked to the next test and it detects an extra key release.
		await wait_frames(1)
		_sender.clear()

	func test_raw_input_press():
		var r = add_child_autofree(InputSingletonTracker.new())

		Input.action_press("jump")
		await wait_frames(10)
		Input.action_release("jump")

		assert_gt(r.pressed_frames.size(), 1, 'input size')
	
	func test_input_sender_press():
		var r = add_child_autofree(InputSingletonTracker.new())

		_sender.action_down("jump").hold_for('10f')
		await wait_for_signal(_sender.idle, 5)

		print(r.pressed_frames.size())
		assert_gt(r.pressed_frames.size(), 1, 'input size')

	func test_input_sender_just_pressed():
		var r = add_child_autofree(InputSingletonTracker.new())
		
		_sender.action_down("jump").hold_for("20f")
		await wait_frames(5)

		assert_eq(r.just_pressed_count, 1, 'just pressed once')
		assert_eq(r.just_released_count, 0, 'not released yet')

	func test_input_sender_just_released():
		var r = add_child_autofree(InputSingletonTracker.new())
		
		_sender.action_down("jump").hold_for('5f')
		await wait_for_signal(_sender.idle, 10)

		assert_eq(r.just_pressed_count, 1, 'just pressed once')
		assert_eq(r.just_released_count, 1, 'released key once')