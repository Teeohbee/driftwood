class_name SeasonCard
extends Node2D

## A Harvest Moon style title card when a new season starts.

const SECONDS_SHOWN := 2.6

var season := "spring"
var year := 1
var seconds := 0.0


func _process(delta: float) -> void:
	seconds += delta
	queue_redraw()
	if seconds > SECONDS_SHOWN:
		queue_free()


func _draw() -> void:
	var drop := minf(seconds / 0.3, 1.0)
	var top := roundf(-30 + 70 * drop)
	UiDraw.box(self, Rect2(48, top, 160, 30))
	UiDraw.centred_text(self, season.to_upper(), top + 7)
	UiDraw.centred_text(self, "YEAR %d" % year, top + 17, UiDraw.dim())
