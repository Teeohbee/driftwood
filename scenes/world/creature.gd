class_name Creature
extends Node2D

## Every animal, the cave guardian and the hermit. Position is the middle of
## the feet. Side-on sprites face right and flip to face left.

const CREATURES := {
	"crab": {"hp": 2, "speed": 14.0, "damage": 0, "drops": {"raw_meat": 1}, "wander": 20.0, "sideways": true},
	"boar": {"hp": 8, "speed": 22.0, "charge_speed": 70.0, "damage": 12, "drops": {"raw_meat": 2, "hide": 1}, "wander": 40.0, "hostile": true, "sight": 56.0},
	"snake": {"hp": 3, "speed": 10.0, "damage": 8, "drops": {}, "wander": 12.0, "hostile": true, "sight": 20.0},
	"monkey": {"hp": 99, "speed": 30.0, "damage": 0, "drops": {}, "wander": 30.0, "tame_food": ["fruit", "roast_fruit", "berries"], "feeds_to_tame": 3},
	"goat": {"hp": 99, "speed": 16.0, "damage": 0, "drops": {}, "wander": 32.0, "tame_food": ["fruit", "berries", "seeds", "yam", "melon", "squash", "beans"], "feeds_to_tame": 3, "product": "milk"},
	"hen": {"hp": 99, "speed": 18.0, "damage": 0, "drops": {}, "wander": 24.0, "tame_food": ["seeds", "berries", "beans"], "feeds_to_tame": 2, "product": "egg"},
	"bat": {"hp": 2, "speed": 34.0, "damage": 6, "drops": {}, "wander": 30.0, "hostile": true, "sight": 64.0, "flies": true},
	"guardian": {"hp": 30, "speed": 24.0, "charge_speed": 110.0, "damage": 20, "drops": {"claw": 1}, "wander": 0.0, "hostile": true, "sight": 200.0, "size": 32},
	"hermit": {"hp": 99, "speed": 0.0, "damage": 0, "drops": {}, "wander": 0.0},
}

const FRAME_SECONDS := 0.22
const HURT_SECONDS := 0.5
const STUN_SECONDS := 1.8

signal hurt_player(amount: int, from_position: Vector2)

var kind := ""
var spawn_cell := Vector2i.ZERO
var health := 1
var home_position := Vector2.ZERO
var exact_position := Vector2.ZERO
var facing_right := true
var sprite: Sprite2D
var frame_timer := 0.0
var think_timer := 0.0
var target_position := Vector2.ZERO
var hurt_timer := 0.0
var knockback := Vector2.ZERO
var state := "wander"
var state_timer := 0.0
var charge_direction := Vector2.ZERO
var is_tamed := false
var is_companion := false
## Set by the world.
var is_area_blocked: Callable
var player: Player


func setup(creature_kind: String, cell: Vector2i) -> void:
	kind = creature_kind
	spawn_cell = cell
	name = "%s_%d_%d" % [kind, cell.x, cell.y]
	health = info()["hp"]
	position = Vector2(cell.x * 16 + 8, cell.y * 16 + 14)
	home_position = position
	exact_position = position
	target_position = position
	sprite = Sprite2D.new()
	sprite.centered = false
	var texture: Texture2D = load("res://art/sprites/%s.png" % kind)
	var frame_count: int = PixelArt.sprite(kind)["frames"].size()
	sprite.texture = texture
	sprite.hframes = frame_count
	sprite.offset = Vector2(-texture.get_width() / frame_count / 2, -texture.get_height() + 2)
	add_child(sprite)
	think_timer = randf_range(0.2, 1.5)


func info() -> Dictionary:
	return CREATURES[kind]


func id() -> String:
	return "%s_%d_%d" % [kind, spawn_cell.x, spawn_cell.y]


func is_hostile() -> bool:
	return info().get("hostile", false)


func size() -> int:
	return info().get("size", 16)


func interaction_area() -> Rect2:
	var half := size() / 2.0
	return Rect2(position - Vector2(half, size() - 2), Vector2(size(), size()))


func body_area() -> Rect2:
	return interaction_area().grow(-3)


func _process(delta: float) -> void:
	animate(delta)
	if hurt_timer > 0.0:
		hurt_timer -= delta
		sprite.visible = int(hurt_timer / 0.06) % 2 == 0 or hurt_timer <= 0.0
		move_by(knockback * delta)
		knockback = knockback.move_toward(Vector2.ZERO, 300 * delta)
		update_position()
		return
	match kind:
		"boar":
			think_charger(delta)
		"guardian":
			think_guardian(delta)
		"snake", "bat":
			think_chaser(delta)
		"hermit":
			pass
		_:
			if is_companion:
				think_companion(delta)
			else:
				think_wanderer(delta)
	update_position()
	touch_player()


func animate(delta: float) -> void:
	if sprite.hframes <= 1:
		return
	var is_moving := state != "rest" and state != "stunned"
	if kind == "bat" or is_moving:
		frame_timer += delta
		if frame_timer >= FRAME_SECONDS:
			frame_timer = 0.0
			sprite.frame = (sprite.frame + 1) % sprite.hframes


func update_position() -> void:
	position = exact_position.round()
	sprite.flip_h = not facing_right


func move_by(step: Vector2) -> bool:
	var moved := false
	for axis_step in [Vector2(step.x, 0), Vector2(0, step.y)]:
		if axis_step == Vector2.ZERO:
			continue
		var destination: Vector2 = exact_position + axis_step
		var flies: bool = info().get("flies", false)
		if flies or is_area_blocked.is_null() or not is_area_blocked.call(feet_rectangle_at(destination)):
			exact_position = destination
			moved = true
	if absf(step.x) > 0.01:
		facing_right = step.x > 0
	return moved


func feet_rectangle_at(feet_position: Vector2) -> Rect2:
	var width := size() * 0.6
	return Rect2(feet_position - Vector2(width / 2, 5), Vector2(width, 5))


func walk_towards(goal: Vector2, speed: float, delta: float) -> bool:
	var offset := goal - exact_position
	if offset.length() < 1.0:
		return true
	var moved := move_by(offset.normalized() * minf(speed * delta, offset.length()))
	return not moved


func think_wanderer(delta: float) -> void:
	think_timer -= delta
	if think_timer <= 0.0:
		think_timer = randf_range(1.0, 3.0)
		var wander: float = info()["wander"]
		if info().get("sideways", false):
			target_position = home_position + Vector2(randf_range(-wander, wander), 0)
		else:
			target_position = home_position + Vector2(randf_range(-wander, wander), randf_range(-wander, wander) * 0.5)
	var is_stuck := walk_towards(target_position, info()["speed"], delta)
	if is_stuck:
		target_position = exact_position


## Boars amble about, then lower their heads and charge if you come close.
func think_charger(delta: float) -> void:
	state_timer -= delta
	var to_player := player.exact_position - exact_position if player != null else Vector2(9999, 0)
	match state:
		"wander":
			think_wanderer(delta)
			if to_player.length() < info()["sight"]:
				state = "warn"
				state_timer = 0.6
				facing_right = to_player.x > 0
		"warn":
			if state_timer <= 0.0:
				state = "charge"
				state_timer = 1.2
				charge_direction = to_player.normalized()
		"charge":
			var is_blocked := not move_by(charge_direction * info()["charge_speed"] * delta)
			if state_timer <= 0.0 or is_blocked:
				state = "rest"
				state_timer = 1.4
		"rest":
			if state_timer <= 0.0:
				state = "wander"


## Snakes lunge if you step close; bats flutter straight at you.
func think_chaser(delta: float) -> void:
	var to_player := player.exact_position - exact_position if player != null else Vector2(9999, 0)
	if to_player.length() < info()["sight"]:
		var wobble := Vector2(sin(Time.get_ticks_msec() / 120.0), cos(Time.get_ticks_msec() / 150.0)) * 10.0 if kind == "bat" else Vector2.ZERO
		walk_towards(player.exact_position + wobble, info()["speed"] * (1.6 if kind == "snake" else 1.0), delta)
	else:
		think_wanderer(delta)


## The guardian sidles to line up with you, then charges. Hitting a wall stuns
## it, and only a stunned guardian can be hurt. Light makes it flinch.
func think_guardian(delta: float) -> void:
	if player == null:
		return
	state_timer -= delta
	var to_player := player.exact_position - exact_position
	match state:
		"wander":
			state = "sidle"
			state_timer = 1.5
		"sidle":
			walk_towards(Vector2(player.exact_position.x, exact_position.y), info()["speed"], delta)
			if state_timer <= 0.0:
				state = "warn"
				state_timer = 0.5
		"warn":
			if state_timer <= 0.0:
				state = "charge"
				state_timer = 2.0
				charge_direction = to_player.normalized()
		"charge":
			var is_blocked := not move_by(charge_direction * info()["charge_speed"] * delta)
			if is_blocked:
				state = "stunned"
				state_timer = STUN_SECONDS
			elif state_timer <= 0.0:
				state = "sidle"
				state_timer = 1.2
		"stunned":
			sprite.frame = 1
			if state_timer <= 0.0:
				state = "sidle"
				state_timer = 1.5


func is_vulnerable() -> bool:
	return kind != "guardian" or state == "stunned"


## Follows the castaway around, a few steps behind.
func think_companion(delta: float) -> void:
	if player == null:
		return
	var distance := exact_position.distance_to(player.exact_position)
	if distance > 160.0:
		exact_position = player.exact_position + Vector2(-12, 4)
		return
	if distance > 24.0:
		var is_stuck := walk_towards(player.exact_position, info()["speed"] * (1.8 if distance > 60.0 else 1.0), delta)
		if is_stuck and distance > 80.0:
			exact_position = player.exact_position + Vector2(-12, 4)
	elif fmod(Time.get_ticks_msec() / 1000.0, 4.0) < 0.05:
		facing_right = not facing_right


func touch_player() -> void:
	if player == null or not is_hostile() or info()["damage"] <= 0:
		return
	if state == "stunned" or state == "rest":
		return
	if body_area().intersects(player.feet_rectangle_at(player.exact_position).grow(2)):
		hurt_player.emit(info()["damage"], exact_position)
		if kind == "boar" and state == "charge":
			state = "rest"
			state_timer = 1.4


## Returns true if this hit killed it.
func take_hit(damage: int, from_position: Vector2) -> bool:
	if hurt_timer > 0.0:
		return false
	if not is_vulnerable():
		return false
	health -= damage
	hurt_timer = HURT_SECONDS
	knockback = (exact_position - from_position).normalized() * 90.0
	if kind == "guardian":
		knockback = Vector2.ZERO
		state = "sidle"
		state_timer = 1.0
	if is_hostile() and kind == "boar":
		state = "rest"
		state_timer = 0.8
	return health <= 0


func drops() -> Dictionary:
	return info()["drops"]
