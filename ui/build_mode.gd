class_name BuildMode
extends Node2D

## The hammer's menu. A strip of pieces at the bottom with their costs;
## a blinking box shows where it will go. Left/right picks, up/down moves
## the spot, A builds, B closes. The last entry takes a piece down.

const REMOVE := "remove"

var world: World
var target_cell := Vector2i.ZERO
var choice_index := 0
var message := ""
var seconds_open := 0.0
## True when the next A release should not build: after moving the spot
## with A held, or the press that opened this menu.
var ignore_next_release := false


func entries() -> Array:
	return BuildCatalog.ORDER + [REMOVE]


func open_for(cell: Vector2i) -> void:
	target_cell = cell
	message = ""
	visible = true
	ignore_next_release = Input.is_action_pressed("action_a")
	world.set_mode(World.Mode.BUILD)
	Sound.play("menu_open")
	world.hint_once("first_build", ["BUILD MODE. LEFT/RIGHT: PIECE.", "HOLD A + ARROWS: MOVE THE SPOT.", "A: BUILD. B: DONE."])


func close() -> void:
	visible = false
	world.set_mode(World.Mode.PLAY)


func _ready() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible or world.mode != World.Mode.BUILD:
		return
	seconds_open += delta
	queue_redraw()
	var horizontal := int(Input.is_action_just_pressed("move_right")) - int(Input.is_action_just_pressed("move_left"))
	var vertical := int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("move_up"))
	if Input.is_action_pressed("action_a") and (horizontal != 0 or vertical != 0):
		target_cell += Vector2i(horizontal, vertical)
		target_cell = target_cell.clamp(world.player.cell() - Vector2i(3, 3), world.player.cell() + Vector2i(3, 3))
		message = ""
		ignore_next_release = true
		return
	if horizontal != 0:
		choice_index = wrapi(choice_index + horizontal, 0, entries().size())
		message = ""
		Sound.play("menu_move")
	if vertical != 0:
		target_cell += Vector2i(0, vertical)
		target_cell = target_cell.clamp(world.player.cell() - Vector2i(3, 3), world.player.cell() + Vector2i(3, 3))
	if Input.is_action_just_released("action_a"):
		if ignore_next_release:
			ignore_next_release = false
		else:
			build_here()
	elif Input.is_action_just_pressed("action_b") or Input.is_action_just_pressed("start"):
		close()


func build_here() -> void:
	var entry: String = entries()[choice_index]
	if entry == REMOVE:
		var removed := Building.dismantle(world, target_cell)
		message = "TOOK DOWN THE %s." % BuildCatalog.piece(removed)["name"] if removed != "" else "NOTHING TO TAKE DOWN."
		Sound.play("chop" if removed != "" else "merge_fail")
		return
	var problem := Building.placement_problem(world, entry, target_cell)
	if problem != "":
		message = problem
		Sound.play("merge_fail")
		return
	Building.place(world, entry, target_cell)
	message = "BUILT A %s!" % BuildCatalog.piece(entry)["name"]
	Sound.play("build")
	if entry == "beacon":
		world.hint_once("beacon_built", ["THE BEACON IS READY.", "LIGHT IT WITH A TORCH ONE NIGHT."])
	if entry == "raft":
		close()
		world.say(["THE RAFT BOBS ON THE WAVES.", "PRESS A ON IT TO CLIMB ABOARD."])


func _draw() -> void:
	if not visible:
		return
	var canvas := world.get_viewport().get_canvas_transform()
	var cell_screen := canvas * Vector2(target_cell * 16)
	var entry: String = entries()[choice_index]
	var is_ok := entry == REMOVE or Building.placement_problem(world, entry, target_cell) == ""
	if int(seconds_open / 0.2) % 2 == 0:
		draw_rect(Rect2(cell_screen, Vector2(16, 16)), UiDraw.paper() if is_ok else Palettes.sprite_color("emote", 2), false, 1.0)
	var panel := Rect2(0, 96, 256, 32)
	draw_rect(panel, UiDraw.paper())
	draw_rect(Rect2(0, 96, 256, 1), UiDraw.ink())
	UiDraw.text(self, "<", Vector2(2, 104))
	UiDraw.text(self, ">", Vector2(248, 104))
	if entry == REMOVE:
		UiDraw.text(self, "TAKE DOWN (HALF BACK)", Vector2(12, 100))
	else:
		var piece := BuildCatalog.piece(entry)
		UiDraw.text(self, piece["name"], Vector2(12, 100))
		var left := 12.0
		var cost: Dictionary = piece["cost"]
		for item_id in cost:
			UiDraw.item_icon(self, item_id, Vector2(left, 109))
			var have := world.save.inventory.count_of(item_id)
			UiDraw.text(self, "%d/%d" % [have, cost[item_id]], Vector2(left + 17, 113), UiDraw.ink() if have >= cost[item_id] else UiDraw.dim())
			left += 50
	if message != "":
		PixelFont.draw_outlined_text(self, message, Vector2(4, 84), UiDraw.paper(), UiDraw.ink())
