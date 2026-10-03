class_name Synth
extends RefCounted
## A tiny chiptune synthesizer. It builds every sound effect and song in code at startup.

enum Wave { SQUARE, TRIANGLE, SINE, NOISE }

const RATE: int = 22050

const NOTE_OFFSETS: Dictionary[String, int] = {
	"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6,
	"Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11,
}

const MEADOW_LEAD: String = "C5:0.5 E5:0.5 G5:1 E5:0.5 G5:0.5 A5:1 G5:0.5 E5:0.5 C5:1 D5:1 R:1 F5:0.5 A5:0.5 C6:1 A5:0.5 G5:0.5 F5:1 E5:0.5 G5:0.5 E5:0.5 D5:0.5 C5:2 C5:0.5 E5:0.5 G5:1 E5:0.5 G5:0.5 C6:1 B5:0.5 A5:0.5 G5:1 E5:1 R:1 F5:0.5 E5:0.5 D5:0.5 F5:0.5 E5:0.5 D5:0.5 C5:0.5 D5:0.5 C5:3 R:1"
const MEADOW_BASS: String = "C3:1 G3:1 C3:1 G3:1 A2:1 E3:1 A2:1 E3:1 F2:1 C3:1 F2:1 C3:1 G2:1 D3:1 G2:1 D3:1 C3:1 G3:1 C3:1 G3:1 E3:1 B3:1 E3:1 B3:1 G2:1 D3:1 G2:1 D3:1 C3:1 G3:1 C3:2"

const WOODS_LEAD: String = "A4:1 C5:0.5 E5:0.5 D5:1 C5:1 E5:1.5 D5:0.5 C5:1 A4:1 G4:1 B4:0.5 D5:0.5 C5:1 B4:1 A4:3 R:1 A4:1 C5:0.5 E5:0.5 A5:1 G5:1 E5:1.5 G5:0.5 E5:1 D5:1 C5:0.5 D5:0.5 E5:1 D5:0.5 C5:0.5 B4:1 A4:3 R:1"
const WOODS_BASS: String = "A2:1 E3:1 A3:1 E3:1 F2:1 C3:1 F3:1 C3:1 G2:1 D3:1 G3:1 D3:1 A2:1 E3:1 A3:1 E3:1 A2:1 E3:1 A3:1 E3:1 C3:1 G3:1 C4:1 G3:1 G2:1 D3:1 G3:1 D3:1 A2:1 E3:1 A2:2"

const BEACH_LEAD: String = "G4:0.5 B4:0.5 D5:1 B4:0.5 D5:0.5 E5:1 D5:0.5 B4:0.5 G4:1 A4:1 R:1 C5:0.5 E5:0.5 G5:1 E5:0.5 C5:0.5 D5:1 B4:0.5 G4:0.5 A4:1 B4:1 R:1 G4:0.5 B4:0.5 D5:1 G5:1 F#5:0.5 E5:0.5 D5:1 E5:0.5 F#5:0.5 G5:1 R:1 E5:0.5 D5:0.5 C5:0.5 B4:0.5 A4:1 C5:1 B4:0.5 A4:0.5 G4:3"
const BEACH_BASS: String = "G2:1 D3:1 G2:1 D3:1 D3:1 A2:1 D3:1 F#3:1 C3:1 G2:1 C3:1 E3:1 G2:1 D3:1 D3:1 F#2:1 G2:1 B2:1 D3:1 B2:1 D3:1 A2:1 D3:1 A2:1 C3:1 G2:1 A2:1 D3:1 G2:1 D3:1 G2:2"

const CAVES_LEAD: String = "D5:1 F5:1 A5:1.5 G5:0.5 F5:1 E5:1 D5:2 C5:1 E5:1 G5:1.5 F5:0.5 E5:1 C5:1 A4:2 Bb4:1 D5:1 F5:1 A5:1 G5:1.5 F5:0.5 E5:2 F5:1 E5:1 D5:1 C#5:1 D5:3 R:1"
const CAVES_BASS: String = "D3:1 A3:1 D4:1 A3:1 D3:1 A3:1 D4:1 A3:1 C3:1 G3:1 C4:1 G3:1 A2:1 E3:1 A3:1 E3:1 Bb2:1 F3:1 Bb3:1 F3:1 C3:1 G3:1 C4:1 G3:1 A2:1 E3:1 A3:1 C#4:1 D3:1 A3:1 D3:2"

const PEAKS_LEAD: String = "D5:0.5 F#5:0.5 A5:1 A5:0.5 B5:0.5 A5:1 F#5:0.5 D5:0.5 E5:1 F#5:1 R:1 G5:0.5 F#5:0.5 E5:1 B4:1 E5:0.5 F#5:0.5 G5:1 F#5:0.5 E5:0.5 A5:2 D5:0.5 F#5:0.5 A5:1 D6:1 C#6:0.5 B5:0.5 A5:1 G5:0.5 F#5:0.5 E5:1 R:1 G5:1 F#5:0.5 E5:0.5 A5:1 C#5:1 D5:3 R:1"
const PEAKS_BASS: String = "D3:1 A3:1 D3:1 A3:1 A2:1 E3:1 A2:1 E3:1 E3:1 B3:1 E3:1 B3:1 A2:1 E3:1 A2:1 C#3:1 D3:1 A3:1 D3:1 A3:1 G2:1 D3:1 A2:1 E3:1 G2:1 D3:1 A2:1 E3:1 D3:1 A2:1 D3:2"

const ORCHARD_LEAD: String = "C5:0.5 F5:0.5 A5:1 G5:0.5 F5:0.5 G5:1 A5:0.5 G5:0.5 F5:1 D5:1 R:1 Bb4:0.5 D5:0.5 F5:1 E5:0.5 D5:0.5 C5:1 A4:0.5 C5:0.5 F5:1 E5:1 R:1 C5:0.5 F5:0.5 A5:1 C6:1 Bb5:0.5 A5:0.5 G5:1 F5:0.5 G5:0.5 A5:1 R:1 Bb5:0.5 A5:0.5 G5:0.5 F5:0.5 E5:1 G5:1 F5:3 R:1"
const ORCHARD_BASS: String = "F2:1 C3:1 F3:1 C3:1 Bb2:1 F3:1 D3:1 F3:1 C3:1 G3:1 E3:1 G3:1 F2:1 C3:1 A2:1 C3:1 F2:1 C3:1 F3:1 C3:1 Bb2:1 F3:1 C3:1 G3:1 F2:1 C3:1 C3:1 G3:1 C3:1 G2:1 F2:2"

const CANDY_LEAD: String = "G5:0.5 E5:0.5 G5:0.5 E5:0.5 C6:1 G5:1 A5:0.5 G5:0.5 F5:0.5 E5:0.5 D5:1 R:1 F5:0.5 D5:0.5 F5:0.5 D5:0.5 B5:1 F5:1 G5:0.5 F5:0.5 E5:0.5 D5:0.5 C5:1 R:1 E5:0.5 G5:0.5 C6:0.5 E6:0.5 D6:1 C6:1 A5:0.5 C6:0.5 B5:0.5 A5:0.5 G5:1 R:1 F5:0.5 A5:0.5 G5:0.5 E5:0.5 D5:0.5 F5:0.5 E5:0.5 D5:0.5 C5:2 R:2"
const CANDY_BASS: String = "C3:1 G3:1 C3:1 G3:1 F2:1 C3:1 G2:1 D3:1 G2:1 D3:1 G2:1 D3:1 C3:1 G3:1 C3:1 G3:1 C3:1 G3:1 E3:1 G3:1 A2:1 E3:1 G2:1 D3:1 F2:1 C3:1 G2:1 D3:1 C3:1 G2:1 C3:2"

const FALLS_LEAD: String = "A4:1 D5:1 F#5:1.5 E5:0.5 D5:1 E5:1 F#5:2 G5:1 F#5:0.5 E5:0.5 D5:1 B4:1 C#5:1 D5:1 E5:2 A4:1 D5:1 F#5:1.5 A5:0.5 B5:1 A5:1 F#5:2 G5:1 F#5:0.5 E5:0.5 F#5:1 E5:1 D5:3 R:1"
const FALLS_BASS: String = "D3:1 A3:1 F#3:1 A3:1 D3:1 A3:1 F#3:1 A3:1 G2:1 D3:1 B2:1 D3:1 A2:1 E3:1 C#3:1 E3:1 D3:1 A3:1 F#3:1 A3:1 B2:1 F#3:1 D3:1 F#3:1 G2:1 D3:1 A2:1 E3:1 D3:1 A2:1 D3:2"

const SKY_LEAD: String = "F5:1 A5:1 C6:1 A5:1 G5:1 A5:0.5 G5:0.5 F5:1 D5:1 Bb4:1 D5:1 F5:1 D5:0.5 F5:0.5 E5:2 C5:2 F5:1 A5:1 C6:1 D6:1 C6:1 A5:0.5 F5:0.5 G5:2 Bb5:1 A5:1 G5:1 E5:1 F5:3 R:1"
const SKY_BASS: String = "F2:1 C3:1 F3:1 C3:1 D2:1 A2:1 D3:1 A2:1 A#2:1 F3:1 A#2:1 F3:1 C3:1 G3:1 C3:1 G3:1 F2:1 C3:1 F3:1 C3:1 F2:1 C3:1 F3:1 C3:1 A#2:1 F3:1 C3:1 G3:1 F2:1 C3:1 F2:2"

## Song definitions: tempo, note strings and instrument choices.
const SONGS: Dictionary[String, Dictionary] = {
	"title": {"bpm": 84.0, "lead": MEADOW_LEAD, "bass": MEADOW_BASS, "lead_wave": Wave.SINE, "lead_octave": 12, "drums": false},
	"meadow": {"bpm": 112.0, "lead": MEADOW_LEAD, "bass": MEADOW_BASS, "lead_wave": Wave.SQUARE, "lead_octave": 0, "drums": true},
	"woods": {"bpm": 94.0, "lead": WOODS_LEAD, "bass": WOODS_BASS, "lead_wave": Wave.TRIANGLE, "lead_octave": 0, "drums": true},
	"beach": {"bpm": 120.0, "lead": BEACH_LEAD, "bass": BEACH_BASS, "lead_wave": Wave.TRIANGLE, "lead_octave": 0, "drums": true},
	"caves": {"bpm": 84.0, "lead": CAVES_LEAD, "bass": CAVES_BASS, "lead_wave": Wave.SINE, "lead_octave": 0, "drums": true},
	"peaks": {"bpm": 128.0, "lead": PEAKS_LEAD, "bass": PEAKS_BASS, "lead_wave": Wave.SQUARE, "lead_octave": 0, "drums": true},
	"orchard": {"bpm": 108.0, "lead": ORCHARD_LEAD, "bass": ORCHARD_BASS, "lead_wave": Wave.TRIANGLE, "lead_octave": 0, "drums": true},
	"candy": {"bpm": 132.0, "lead": CANDY_LEAD, "bass": CANDY_BASS, "lead_wave": Wave.SQUARE, "lead_octave": 0, "drums": true},
	"falls": {"bpm": 96.0, "lead": FALLS_LEAD, "bass": FALLS_BASS, "lead_wave": Wave.SINE, "lead_octave": 0, "drums": true},
	"sky": {"bpm": 100.0, "lead": SKY_LEAD, "bass": SKY_BASS, "lead_wave": Wave.SINE, "lead_octave": 0, "drums": true},
}


static func note_to_midi(note: String) -> int:
	var octave: int = int(note.right(1))
	var name: String = note.left(note.length() - 1)
	return 12 * (octave + 1) + NOTE_OFFSETS.get(name, 0)


static func midi_to_freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## Parses "C5:1 E5:0.5 R:1" into (midi, beats) pairs. Rests use midi = -1.
static func parse_notes(text: String) -> Array[Vector2]:
	var notes: Array[Vector2] = []
	for token: String in text.split(" ", false):
		var parts: PackedStringArray = token.split(":")
		var beats: float = float(parts[1])
		var midi: float = -1.0 if parts[0] == "R" else float(note_to_midi(parts[0]))
		notes.append(Vector2(midi, beats))
	return notes


static func oscillate(wave: Wave, phase: float, duty: float = 0.5) -> float:
	var p: float = phase - floorf(phase)
	match wave:
		Wave.SQUARE:
			return 1.0 if p < duty else -1.0
		Wave.TRIANGLE:
			return 4.0 * absf(p - 0.5) - 1.0
		Wave.NOISE:
			return randf() * 2.0 - 1.0
	return sin(p * TAU)


## A single tone that slides from f_start to f_end, with a soft attack and decay.
static func sweep(wave: Wave, f_start: float, f_end: float, duration: float, volume: float = 0.5, duty: float = 0.5) -> PackedFloat32Array:
	var count: int = int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase: float = 0.0
	for i: int in count:
		var t: float = float(i) / float(count)
		var freq: float = lerpf(f_start, f_end, t)
		var attack: float = minf(1.0, float(i) / (0.004 * RATE))
		var env: float = attack * (1.0 - t) * (1.0 - t * 0.3)
		samples[i] = oscillate(wave, phase, duty) * volume * env
		phase += freq / RATE
	return samples


## Quick arpeggio of notes (e.g. ["C5", "E5", "G5"]).
static func arpeggio(wave: Wave, notes: PackedStringArray, note_length: float, volume: float = 0.4) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for note: String in notes:
		if note.begins_with("R"):
			var rest := PackedFloat32Array()
			rest.resize(int(note_length * RATE))
			out.append_array(rest)
			continue
		var f: float = midi_to_freq(float(note_to_midi(note)))
		out.append_array(sweep(wave, f, f, note_length, volume, 0.25))
	return out


static func mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := a.duplicate() if a.size() >= b.size() else b.duplicate()
	var other := b if a.size() >= b.size() else a
	for i: int in other.size():
		out[i] += other[i]
	return out


static func to_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	return data


static func make_stream(pcm: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = pcm
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = pcm.size() / 2
	return stream


static func _render_voice(buffer: PackedFloat32Array, notes: Array[Vector2], samples_per_beat: float, wave: Wave, volume: float, transpose: int, duty: float, vibrato: float) -> void:
	var cursor: float = 0.0
	for note: Vector2 in notes:
		var length: int = int(note.y * samples_per_beat)
		if note.x >= 0.0:
			var freq: float = midi_to_freq(note.x + transpose)
			var sounding: int = int(float(length) * 0.9)
			var phase: float = 0.0
			var start: int = int(cursor)
			for i: int in sounding:
				var index: int = start + i
				if index >= buffer.size():
					break
				var attack: float = minf(1.0, float(i) / (0.01 * RATE))
				var release: float = minf(1.0, float(sounding - i) / (0.03 * RATE))
				var decay: float = 0.55 + 0.45 * exp(-float(i) / (0.25 * RATE))
				var lfo: float = 1.0 + vibrato * sin(float(i) / RATE * TAU * 5.5)
				buffer[index] += oscillate(wave, phase, duty) * volume * attack * release * decay
				phase += freq * lfo / RATE
		cursor += float(length)


static func _render_drums(buffer: PackedFloat32Array, samples_per_beat: float) -> void:
	var beats: int = int(float(buffer.size()) / samples_per_beat)
	for beat: int in beats:
		var start: int = int(float(beat) * samples_per_beat)
		if beat % 2 == 0:
			# Soft kick: a short sine that drops in pitch.
			var kick: PackedFloat32Array = sweep(Wave.SINE, 140.0, 45.0, 0.12, 0.35)
			for i: int in kick.size():
				if start + i < buffer.size():
					buffer[start + i] += kick[i]
		# Gentle hi-hat on every off-beat.
		var hat_start: int = start + int(samples_per_beat * 0.5)
		var hat: PackedFloat32Array = sweep(Wave.NOISE, 1.0, 1.0, 0.03, 0.06)
		for i: int in hat.size():
			if hat_start + i < buffer.size():
				buffer[hat_start + i] += hat[i]


## Renders a looping song to 16-bit PCM. Safe to call from a worker thread.
static func render_song(song_name: String) -> PackedByteArray:
	var song: Dictionary = SONGS[song_name]
	var bpm: float = song["bpm"]
	var samples_per_beat: float = 60.0 / bpm * RATE
	var lead: Array[Vector2] = parse_notes(song["lead"])
	var bass: Array[Vector2] = parse_notes(song["bass"])
	var total_beats: float = 0.0
	for note: Vector2 in lead:
		total_beats += note.y
	var count: int = int(total_beats * samples_per_beat)

	var lead_buffer := PackedFloat32Array()
	lead_buffer.resize(count)
	var lead_wave: Wave = song["lead_wave"]
	var lead_volume: float = 0.16 if lead_wave == Wave.SQUARE else 0.3
	_render_voice(lead_buffer, lead, samples_per_beat, lead_wave, lead_volume, song["lead_octave"], 0.25, 0.006)
	# Dreamy echo on the melody (3/4 of a beat later).
	var delay: int = int(samples_per_beat * 0.75)
	for i: int in range(delay, count):
		lead_buffer[i] += lead_buffer[i - delay] * 0.3

	var buffer := PackedFloat32Array()
	buffer.resize(count)
	_render_voice(buffer, bass, samples_per_beat, Wave.TRIANGLE, 0.32, 0, 0.5, 0.0)
	if song["drums"]:
		_render_drums(buffer, samples_per_beat)

	var peak: float = 0.01
	for i: int in count:
		buffer[i] += lead_buffer[i]
		peak = maxf(peak, absf(buffer[i]))
	var gain: float = 0.8 / peak
	for i: int in count:
		buffer[i] *= gain
	return to_pcm16(buffer)
