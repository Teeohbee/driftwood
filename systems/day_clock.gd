class_name DayClock
extends RefCounted

## Island time. One game minute is half a real second, so a day is 12 real
## minutes. A year is four seasons of seven days. Weather is rolled per day
## from the save's seed, so it is the same every time you load.

const REAL_SECONDS_PER_GAME_MINUTE := 0.5
const MINUTES_PER_DAY := 1440
const DAYS_PER_SEASON := 7
const WAKE_HOUR := 6
const DUSK_HOUR := 18
const NIGHT_HOUR := 20
const DAWN_HOUR := 5

## Minutes since midnight before day 1.
var total_minutes := float(WAKE_HOUR * 60)
var weather_seed := 1


func advance(real_seconds: float) -> void:
	total_minutes += real_seconds / REAL_SECONDS_PER_GAME_MINUTE


func day() -> int:
	return int(total_minutes / MINUTES_PER_DAY) + 1


func minute_of_day() -> float:
	return fmod(total_minutes, MINUTES_PER_DAY)


func hour() -> int:
	return int(minute_of_day() / 60)


func time_text() -> String:
	var minutes := int(minute_of_day())
	return "%d:%02d" % [minutes / 60, (minutes % 60) / 10 * 10]


func season_index() -> int:
	return ((day() - 1) / DAYS_PER_SEASON) % 4


func season() -> String:
	return Palettes.SEASONS[season_index()]


func day_of_season() -> int:
	return (day() - 1) % DAYS_PER_SEASON + 1


func year() -> int:
	return (day() - 1) / (DAYS_PER_SEASON * 4) + 1


func is_night() -> bool:
	return hour() >= NIGHT_HOUR or hour() < DAWN_HOUR


## How dark it is, 0 (day) to 3 (deep night), in hard steps like a palette fade.
func darkness_step() -> int:
	var hour_now := minute_of_day() / 60.0
	if hour_now >= 21.0 or hour_now < 4.0:
		return 3
	if hour_now >= 20.0 or hour_now < 4.5:
		return 2
	if hour_now >= 19.0 or hour_now < 5.0:
		return 1
	return 0


func can_sleep() -> bool:
	return hour() >= DUSK_HOUR or hour() < DAWN_HOUR


## Jumps to the next morning. Returns how many mornings passed (usually 1).
func sleep_until_morning() -> int:
	var day_before := day()
	var next_morning := float((day() - 1) * MINUTES_PER_DAY + WAKE_HOUR * 60)
	if next_morning <= total_minutes:
		next_morning += MINUTES_PER_DAY
	total_minutes = next_morning
	return day() - day_before


## "clear", "cloudy", "rain" or "storm". Spring and autumn are wetter.
func weather() -> String:
	return weather_on(day())


func weather_on(day_number: int) -> String:
	if day_number == 1:
		return "clear"
	var roll := absi(hash(weather_seed * 7919 + day_number * 104729)) % 100
	var rain_chance: int = [30, 15, 40, 20][((day_number - 1) / DAYS_PER_SEASON) % 4]
	if roll < rain_chance / 3:
		return "storm"
	if roll < rain_chance:
		return "rain"
	if roll < rain_chance + 20:
		return "cloudy"
	return "clear"


func is_raining() -> bool:
	var today := weather()
	return today == "rain" or today == "storm"
