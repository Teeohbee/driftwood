class_name Toasts
extends Node2D

## Short messages that stack above the status bar, "+1 STICK" style.

const SECONDS_SHOWN := 1.8
const MAXIMUM_SHOWN := 4

var messages: Array = []


func show_message(text: String) -> void:
	messages.append({"text": text, "seconds": SECONDS_SHOWN})
	while messages.size() > MAXIMUM_SHOWN:
		messages.pop_front()


func _process(delta: float) -> void:
	for message in messages:
		message["seconds"] -= delta
	messages = messages.filter(func(message: Dictionary) -> bool: return message["seconds"] > 0.0)
	queue_redraw()


func _draw() -> void:
	for message_index in messages.size():
		var message: Dictionary = messages[messages.size() - 1 - message_index]
		var top := StatusBar.TOP - 11 - message_index * 10
		PixelFont.draw_outlined_text(self, message["text"], Vector2(4, top), UiDraw.paper(), UiDraw.ink())
