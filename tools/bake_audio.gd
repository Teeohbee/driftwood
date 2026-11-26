extends SceneTree

## Synthesises every sound effect and music loop into res://audio/*.wav,
## Game Boy style: two pulse channels, a wave (triangle) channel and noise.
##
##   godot --headless --path . -s tools/bake_audio.gd
##
## Music is written as text below: one chord per bar, and a melody of 16
## steps per bar ("E5" plays a note, "." holds it, "-" is silence).
## Bass, arpeggio and drums are generated from the chords.

const SAMPLE_RATE := 22050
const NOTE_NAMES := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

## [wave, start frequency, end frequency, seconds, volume, duty]
## wave is "pulse", "triangle" or "noise". Several parts play one after another.
const EFFECTS := {
	"blip": [["pulse", 880, 880, 0.03, 0.25, 0.5]],
	"type": [["pulse", 1200, 1200, 0.012, 0.08, 0.5]],
	"menu_move": [["pulse", 990, 990, 0.025, 0.2, 0.25]],
	"menu_confirm": [["pulse", 880, 880, 0.04, 0.25, 0.5], ["pulse", 1320, 1320, 0.06, 0.25, 0.5]],
	"menu_back": [["pulse", 660, 440, 0.07, 0.22, 0.5]],
	"menu_open": [["pulse", 523, 523, 0.04, 0.22, 0.25], ["pulse", 784, 784, 0.05, 0.22, 0.25]],
	"pickup": [["pulse", 1046, 1046, 0.04, 0.25, 0.5], ["pulse", 1568, 1568, 0.07, 0.25, 0.5]],
	"fanfare": [["pulse", 523, 523, 0.09, 0.3, 0.5], ["pulse", 659, 659, 0.09, 0.3, 0.5], ["pulse", 784, 784, 0.09, 0.3, 0.5], ["pulse", 1046, 1046, 0.3, 0.3, 0.5]],
	"merge": [["pulse", 392, 784, 0.12, 0.3, 0.25], ["pulse", 1046, 1046, 0.05, 0.3, 0.5], ["pulse", 1318, 1318, 0.15, 0.3, 0.5]],
	"merge_fail": [["pulse", 220, 180, 0.15, 0.3, 0.5]],
	"eat": [["noise", 3000, 3000, 0.05, 0.25, 0.5], ["noise", 2000, 2000, 0.05, 0.2, 0.5], ["noise", 3000, 3000, 0.05, 0.25, 0.5]],
	"drink": [["triangle", 300, 600, 0.08, 0.5, 0.5], ["triangle", 350, 700, 0.08, 0.5, 0.5]],
	"chop": [["noise", 1500, 600, 0.1, 0.4, 0.5]],
	"mine": [["pulse", 1800, 1200, 0.04, 0.25, 0.125], ["noise", 4000, 2000, 0.08, 0.3, 0.5]],
	"cut": [["noise", 6000, 3000, 0.07, 0.3, 0.5]],
	"clang": [["pulse", 1400, 1300, 0.12, 0.25, 0.125], ["pulse", 700, 650, 0.1, 0.2, 0.125]],
	"swing": [["noise", 5000, 2000, 0.06, 0.18, 0.5]],
	"hit": [["noise", 2000, 500, 0.08, 0.4, 0.5], ["pulse", 200, 100, 0.06, 0.3, 0.5]],
	"hurt": [["pulse", 400, 150, 0.2, 0.35, 0.5]],
	"defeat": [["noise", 3000, 300, 0.3, 0.4, 0.5]],
	"collapse": [["pulse", 392, 392, 0.2, 0.3, 0.5], ["pulse", 330, 330, 0.2, 0.3, 0.5], ["pulse", 262, 200, 0.5, 0.3, 0.5]],
	"sleep": [["triangle", 523, 523, 0.25, 0.5, 0.5], ["triangle", 392, 392, 0.25, 0.5, 0.5], ["triangle", 262, 262, 0.5, 0.5, 0.5]],
	"door": [["noise", 800, 400, 0.15, 0.3, 0.5]],
	"splash": [["noise", 3000, 800, 0.25, 0.35, 0.5]],
	"bite": [["pulse", 1568, 1568, 0.05, 0.3, 0.5], ["pulse", 1568, 1568, 0.05, 0.0, 0.5], ["pulse", 1568, 1568, 0.05, 0.3, 0.5]],
	"fire": [["noise", 1200, 2500, 0.3, 0.3, 0.5]],
	"sizzle": [["noise", 7000, 5000, 0.35, 0.25, 0.5]],
	"build": [["noise", 1000, 1000, 0.05, 0.4, 0.5], ["noise", 1000, 1000, 0.04, 0.0, 0.5], ["noise", 1200, 1200, 0.05, 0.4, 0.5]],
	"open": [["pulse", 300, 600, 0.12, 0.25, 0.25]],
	"rustle": [["noise", 4000, 6000, 0.12, 0.2, 0.5]],
	"dig": [["noise", 900, 500, 0.1, 0.35, 0.5]],
	"season": [["pulse", 784, 784, 0.12, 0.25, 0.5], ["pulse", 988, 988, 0.12, 0.25, 0.5], ["pulse", 1175, 1175, 0.12, 0.25, 0.5], ["pulse", 1568, 1568, 0.4, 0.25, 0.25]],
	"start": [["pulse", 1046, 1046, 0.06, 0.3, 0.5], ["pulse", 1568, 1568, 0.2, 0.3, 0.5]],
	"companion": [["pulse", 1400, 1800, 0.05, 0.2, 0.25], ["pulse", 1600, 2100, 0.06, 0.2, 0.25]],
}

const SONGS := {
	"island": {
		"tempo": 132, "drums": "x.o.x.o.x.o.x.oo",
		"chords": ["C", "F", "G", "C", "Am", "F", "G", "C"],
		"melody": [
			"E5 . G5 . A5 . G5 . E5 . D5 . C5 . . .",
			"D5 . F5 . A5 . . . G5 . F5 . D5 . . .",
			"B4 . D5 . G5 . F5 . D5 . B4 . G4 . . .",
			"C5 . E5 . G5 . C6 . . . . . - - - -",
			"A4 . C5 . E5 . A5 . G5 . E5 . C5 . . .",
			"F5 . E5 . D5 . C5 . A4 . C5 . F5 . . .",
			"G5 . . . F5 . E5 . D5 . . . B4 . . .",
			"C5 . . . . . . . - - - - G4 . B4 .",
		],
	},
	"title": {
		"tempo": 92, "drums": "x.......x.......",
		"chords": ["Am", "F", "C", "G", "Am", "F", "G", "G"],
		"melody": [
			"E5 . . . . . D5 . C5 . . . B4 . . .",
			"A4 . . . . . . . C5 . D5 . . . . .",
			"E5 . . . G5 . . . E5 . . . D5 . C5 .",
			"D5 . . . . . . . - - - - - - - -",
			"E5 . . . . . D5 . C5 . . . B4 . . .",
			"A4 . . . C5 . . . F5 . . . E5 . . .",
			"D5 . . . . . B4 . G4 . . . . . . .",
			"- - - - - - - - - - - - - - - -",
		],
	},
	"cave": {
		"tempo": 80, "drums": "o...............",
		"chords": ["Am", "Am", "Dm", "E", "Am", "Am", "F", "E"],
		"melody": [
			"A4 . . . - - - - C5 . . . B4 . . .",
			"- - - - - - - - E4 . . . - - - -",
			"D5 . . . - - - - F5 . . . E5 . . .",
			"G#4 . . . . . . . - - - - - - - -",
			"A4 . . . - - - - E5 . . . D5 . . .",
			"C5 . . . . . . . - - - - - - - -",
			"F4 . . . A4 . . . C5 . . . A4 . . .",
			"B4 . . . . . . . G#4 . . . . . . .",
		],
	},
	"ending": {
		"tempo": 100, "drums": "x...o...x...o...",
		"chords": ["F", "G", "Em", "Am", "F", "G", "C", "C"],
		"melody": [
			"A5 . . . G5 . . . F5 . . . C5 . . .",
			"D5 . . . G5 . . . B4 . . . D5 . . .",
			"E5 . . . G5 . . . B5 . . . G5 . . .",
			"A5 . . . . . . . E5 . . . C5 . . .",
			"F5 . . . A5 . . . C6 . . . A5 . . .",
			"B5 . . . A5 . . . G5 . . . D5 . . .",
			"E5 . . . . . . . G5 . . . . . . .",
			"C5 . . . . . . . - - - - - - - -",
		],
	},
}

const CHORD_TONES := {
	"C": ["C", "E", "G"], "F": ["F", "A", "C"], "G": ["G", "B", "D"], "Am": ["A", "C", "E"],
	"Dm": ["D", "F", "A"], "E": ["E", "G#", "B"], "Em": ["E", "G", "B"],
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://audio")
	for effect_name in EFFECTS:
		save_wav(effect_name, render_effect(EFFECTS[effect_name]), false)
	for song_name in SONGS:
		save_wav("music_%s" % song_name, render_song(SONGS[song_name]), true)
	print("Baked %d effects and %d songs" % [EFFECTS.size(), SONGS.size()])
	quit()


static func frequency_of(note: String) -> float:
	var name := note.left(note.length() - 1)
	var octave := int(note.right(1))
	var semitone := NOTE_NAMES.find(name)
	var midi := 12 * (octave + 1) + semitone
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## One sample of a channel at a phase (0-1 per cycle).
static func wave_value(wave: String, phase: float, duty: float, noise_state: Array) -> float:
	match wave:
		"pulse":
			return 1.0 if fmod(phase, 1.0) < duty else -1.0
		"triangle":
			var position := fmod(phase, 1.0)
			# Stepped into 16 levels like the GB wave channel.
			return floorf((1.0 - 4.0 * absf(position - 0.5)) * 8.0) / 8.0
		_:
			return noise_state[0]


func render_effect(parts: Array) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	var noise_state := [0.0]
	for part in parts:
		var wave: String = part[0]
		var sample_count := int(part[3] * SAMPLE_RATE)
		var phase := 0.0
		var noise_phase := 0.0
		for sample_index in sample_count:
			var progress := float(sample_index) / sample_count
			var frequency: float = lerpf(part[1], part[2], progress)
			phase += frequency / SAMPLE_RATE
			noise_phase += frequency / SAMPLE_RATE
			if noise_phase >= 1.0:
				noise_phase -= 1.0
				noise_state[0] = randf_range(-1.0, 1.0)
			var envelope := 1.0 - progress * 0.7
			samples.append(wave_value(wave, phase, part[5], noise_state) * part[4] * envelope)
	return samples


func render_song(song: Dictionary) -> PackedFloat32Array:
	var seconds_per_step: float = 60.0 / song["tempo"] / 4.0
	var samples_per_step := int(seconds_per_step * SAMPLE_RATE)
	var chords: Array = song["chords"]
	var total_steps: int = chords.size() * 16
	var samples := PackedFloat32Array()
	samples.resize(total_steps * samples_per_step)
	samples.fill(0.0)
	var melody_steps := []
	for bar in song["melody"]:
		melody_steps.append_array(String(bar).split(" ", false))
	render_melody(samples, melody_steps, samples_per_step)
	for bar_index in chords.size():
		var tones: Array = CHORD_TONES[chords[bar_index]]
		var bar_start := bar_index * 16
		for step in 16:
			# Bass on the wave channel: root on the beat, fifth on the off-beat.
			if step % 4 == 0:
				var bass_note: String = (tones[0] if step % 8 == 0 else tones[2]) + "2"
				add_tone(samples, (bar_start + step) * samples_per_step, samples_per_step * 3, frequency_of(bass_note), "triangle", 0.28, 0.5)
			# Arpeggio on the second pulse channel, quiet and thin.
			if step % 2 == 0:
				var arpeggio_note: String = tones[(step / 2) % 3] + "4"
				add_tone(samples, (bar_start + step) * samples_per_step, samples_per_step, frequency_of(arpeggio_note), "pulse", 0.05, 0.125)
			var drum: String = song["drums"][step]
			if drum == "x":
				add_tone(samples, (bar_start + step) * samples_per_step, samples_per_step / 3, 9000.0, "noise", 0.06, 0.5)
			elif drum == "o":
				add_tone(samples, (bar_start + step) * samples_per_step, samples_per_step / 2, 2500.0, "noise", 0.12, 0.5)
	return samples


func render_melody(samples: PackedFloat32Array, steps: Array, samples_per_step: int) -> void:
	var step_index := 0
	while step_index < steps.size():
		var token: String = steps[step_index]
		if token == "-" or token == ".":
			step_index += 1
			continue
		var length := 1
		while step_index + length < steps.size() and steps[step_index + length] == ".":
			length += 1
		add_tone(samples, step_index * samples_per_step, length * samples_per_step, frequency_of(token), "pulse", 0.13, 0.5 if length > 2 else 0.25)
		step_index += length


func add_tone(samples: PackedFloat32Array, start: int, length: int, frequency: float, wave: String, volume: float, duty: float) -> void:
	var phase := 0.0
	var noise_state := [0.0]
	var noise_phase := 0.0
	for offset in length:
		var index := start + offset
		if index >= samples.size():
			return
		phase += frequency / SAMPLE_RATE
		noise_phase += frequency / SAMPLE_RATE
		if noise_phase >= 1.0:
			noise_phase -= 1.0
			noise_state[0] = randf_range(-1.0, 1.0)
		var progress := float(offset) / length
		var envelope := 1.0 - progress * (0.9 if wave == "noise" else 0.4)
		# A tiny gap at the end of each note so repeats are heard.
		if length - offset < 120:
			envelope *= (length - offset) / 120.0
		samples[index] += wave_value(wave, phase, duty, noise_state) * volume * envelope


func save_wav(sound_name: String, samples: PackedFloat32Array, is_loop: bool) -> void:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in samples.size():
		bytes.encode_s16(index * 2, int(clampf(samples[index], -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	if is_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()
	var error := stream.save_to_wav("res://audio/%s.wav" % sound_name)
	if error != OK:
		printerr("Could not save %s (error %d)" % [sound_name, error])
