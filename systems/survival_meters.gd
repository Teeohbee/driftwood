class_name SurvivalMeters
extends RefCounted

## Health, hunger, water and fatigue, 0-100 like Survival Kids showed them.
## Fatigue counts down: 100 is wide awake, 0 is dead on your feet.
## Time is in game minutes (one game minute is half a real second).

const MAXIMUM := 100.0
const WATER_PER_MINUTE := 100.0 / 1200.0
const HUNGER_PER_MINUTE := 100.0 / 1800.0
const FATIGUE_PER_MINUTE := 100.0 / 2000.0
const EXTRA_FATIGUE_PER_MINUTE_WALKING := 100.0 / 2400.0
const STARVING_HEALTH_PER_MINUTE := 0.2
const HEALING_PER_MINUTE := 0.05
const RESTED_DRAIN_FACTOR := 0.5

var health := 100.0
var hunger := 80.0
var water := 70.0
var fatigue := 100.0
## Game minutes of the Rested buff left. Rested meters drain at half speed.
var rested_minutes := 0.0


func tick(minutes: float, is_walking: bool) -> void:
	var drain := RESTED_DRAIN_FACTOR if is_rested() else 1.0
	water = maxf(water - WATER_PER_MINUTE * minutes * drain, 0.0)
	hunger = maxf(hunger - HUNGER_PER_MINUTE * minutes * drain, 0.0)
	var tiring := FATIGUE_PER_MINUTE + (EXTRA_FATIGUE_PER_MINUTE_WALKING if is_walking else 0.0)
	fatigue = maxf(fatigue - tiring * minutes * drain, 0.0)
	rested_minutes = maxf(rested_minutes - minutes, 0.0)
	if hunger <= 0.0 or water <= 0.0:
		health = maxf(health - STARVING_HEALTH_PER_MINUTE * minutes, 0.0)
	elif hunger > 40.0 and water > 40.0:
		health = minf(health + HEALING_PER_MINUTE * minutes, MAXIMUM)


func apply(effects: Dictionary) -> void:
	health = clampf(health + effects.get("health", 0), 0.0, MAXIMUM)
	hunger = clampf(hunger + effects.get("hunger", 0), 0.0, MAXIMUM)
	water = clampf(water + effects.get("water", 0), 0.0, MAXIMUM)
	fatigue = clampf(fatigue + effects.get("fatigue", 0), 0.0, MAXIMUM)


func eat(amount: int) -> void:
	apply({"hunger": amount})


func rest(amount: int) -> void:
	apply({"fatigue": amount})


func exert(amount: float) -> void:
	fatigue = maxf(fatigue - amount, 0.0)


func hurt(amount: float) -> void:
	health = maxf(health - amount, 0.0)


func is_exhausted() -> bool:
	return fatigue <= 0.0


func is_dead() -> bool:
	return health <= 0.0


func is_rested() -> bool:
	return rested_minutes > 0.0


## A night's sleep. Shelter (a roof or bed) restores more; comfort sets how
## long the Rested buff lasts the next day.
func sleep(is_sheltered: bool, comfort: int) -> void:
	hunger = maxf(hunger - 15.0, 0.0)
	water = maxf(water - 20.0, 0.0)
	fatigue = MAXIMUM if is_sheltered else 70.0
	health = minf(health + (25.0 if is_sheltered else 10.0), MAXIMUM)
	if is_sheltered:
		rested_minutes = (4 + comfort) * 60.0


func shown(value: float) -> int:
	return ceili(value)


func to_data() -> Dictionary:
	return {"health": health, "hunger": hunger, "water": water, "fatigue": fatigue, "rested_minutes": rested_minutes}


func load_data(data: Dictionary) -> void:
	health = data.get("health", 100.0)
	hunger = data.get("hunger", 80.0)
	water = data.get("water", 70.0)
	fatigue = data.get("fatigue", 100.0)
	rested_minutes = data.get("rested_minutes", 0.0)
