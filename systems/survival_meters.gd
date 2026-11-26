class_name SurvivalMeters
extends RefCounted

## The four numbers in the status bar, 0-100 like Survival Kids showed them.
## Look-book rates only: they drain slowly so the numbers visibly move.

const MAXIMUM := 100
const SECONDS_PER_WATER_POINT := 6.0
const SECONDS_PER_HUNGER_POINT := 9.0
const SECONDS_PER_FATIGUE_POINT_WHILE_WALKING := 4.0

var health := 100
var hunger := 80
var water := 60
var fatigue := 90

var water_timer := 0.0
var hunger_timer := 0.0
var fatigue_timer := 0.0


func tick(delta: float, is_walking: bool) -> void:
	water_timer += delta
	hunger_timer += delta
	if is_walking:
		fatigue_timer += delta

	if water_timer >= SECONDS_PER_WATER_POINT:
		water_timer = 0.0
		water = maxi(water - 1, 0)
	if hunger_timer >= SECONDS_PER_HUNGER_POINT:
		hunger_timer = 0.0
		hunger = maxi(hunger - 1, 0)
	if fatigue_timer >= SECONDS_PER_FATIGUE_POINT_WHILE_WALKING:
		fatigue_timer = 0.0
		fatigue = maxi(fatigue - 1, 0)


func eat(amount: int) -> void:
	hunger = mini(hunger + amount, MAXIMUM)


func rest(amount: int) -> void:
	fatigue = mini(fatigue + amount, MAXIMUM)
