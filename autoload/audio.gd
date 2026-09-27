extends Node
## Global audio: synthesized sound effects and background music (no audio files needed).
## Songs are rendered on worker threads at startup so the game never hitches.

const SFX_VOICES: int = 8
const MUSIC_VOLUME_DB: float = -10.0
const SFX_VOLUME_DB: float = -4.0

var _sfx: Dictionary[String, AudioStreamWAV] = {}
var _songs: Dictionary[String, AudioStreamWAV] = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music_player: AudioStreamPlayer
var _wanted_song: String = ""
var _tasks: Array[int] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in SFX_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = SFX_VOLUME_DB
		add_child(voice)
		_voices.append(voice)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = MUSIC_VOLUME_DB
	add_child(_music_player)
	_build_sound_effects()
	for song_name: String in Synth.SONGS.keys():
		_tasks.append(WorkerThreadPool.add_task(_render_song.bind(song_name), false, "Render song " + song_name))


func _exit_tree() -> void:
	for task: int in _tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	for voice: AudioStreamPlayer in _voices:
		voice.stop()
		voice.stream = null
	_music_player.stop()
	_music_player.stream = null
	_songs.clear()
	_sfx.clear()


## Plays a sound effect by name, e.g. Audio.sfx("jump").
func sfx(sound_name: String, pitch: float = 1.0) -> void:
	if not _sfx.has(sound_name):
		push_warning("Unknown sound: " + sound_name)
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = _sfx[sound_name]
	voice.pitch_scale = pitch
	voice.play()


## Starts a looping song (see Synth.SONGS). An empty name stops the music.
func play_music(song_name: String) -> void:
	if song_name == _wanted_song and _music_player.playing:
		return
	_wanted_song = song_name
	_music_player.stop()
	if song_name != "" and _songs.has(song_name):
		_music_player.stream = _songs[song_name]
		_music_player.play()


func stop_music() -> void:
	play_music("")


func _render_song(song_name: String) -> void:
	var pcm: PackedByteArray = Synth.render_song(song_name)
	_on_song_rendered.call_deferred(song_name, pcm)


func _on_song_rendered(song_name: String, pcm: PackedByteArray) -> void:
	_songs[song_name] = Synth.make_stream(pcm, true)
	if _wanted_song == song_name and not _music_player.playing:
		_music_player.stream = _songs[song_name]
		_music_player.play()


func _add(sound_name: String, samples: PackedFloat32Array) -> void:
	_sfx[sound_name] = Synth.make_stream(Synth.to_pcm16(samples))


func _build_sound_effects() -> void:
	_add("jump", Synth.sweep(Synth.Wave.SQUARE, 320.0, 700.0, 0.13, 0.28, 0.25))
	_add("dust", Synth.mix(Synth.sweep(Synth.Wave.SINE, 1568.0, 1568.0, 0.07, 0.35), Synth.arpeggio(Synth.Wave.SINE, PackedStringArray(["R0", "E6", "B6"]), 0.05, 0.3)))
	_add("stomp", Synth.mix(Synth.sweep(Synth.Wave.SQUARE, 520.0, 140.0, 0.14, 0.3, 0.5), Synth.sweep(Synth.Wave.NOISE, 1.0, 1.0, 0.06, 0.2)))
	_add("hurt", Synth.sweep(Synth.Wave.SQUARE, 480.0, 200.0, 0.3, 0.3, 0.5))
	_add("oops", Synth.arpeggio(Synth.Wave.TRIANGLE, PackedStringArray(["G4", "E4", "C4", "C3"]), 0.14, 0.5))
	_add("fly", Synth.arpeggio(Synth.Wave.SINE, PackedStringArray(["C5", "E5", "G5", "C6", "E6", "G6"]), 0.06, 0.4))
	_add("fly_end", Synth.arpeggio(Synth.Wave.SINE, PackedStringArray(["G5", "E5", "C5"]), 0.08, 0.35))
	_add("bump", Synth.mix(Synth.sweep(Synth.Wave.TRIANGLE, 200.0, 120.0, 0.1, 0.5), Synth.arpeggio(Synth.Wave.SINE, PackedStringArray(["R0", "C6", "G6"]), 0.06, 0.3)))
	_add("thud", Synth.sweep(Synth.Wave.TRIANGLE, 160.0, 90.0, 0.08, 0.5))
	_add("heart", Synth.arpeggio(Synth.Wave.SINE, PackedStringArray(["C6", "E6", "G6", "C7"]), 0.07, 0.35))
	_add("checkpoint", Synth.arpeggio(Synth.Wave.SINE, PackedStringArray(["G5", "C6", "E6"]), 0.11, 0.4))
	_add("bloom", Synth.mix(Synth.sweep(Synth.Wave.SINE, 500.0, 1700.0, 0.35, 0.3), Synth.arpeggio(Synth.Wave.SINE, PackedStringArray(["C6", "G6", "C7"]), 0.1, 0.2)))
	_add("spring", Synth.sweep(Synth.Wave.SINE, 200.0, 900.0, 0.22, 0.45))
	_add("goal", Synth.arpeggio(Synth.Wave.SQUARE, PackedStringArray(["C5", "E5", "G5", "C6", "R0", "G5", "C6", "C6", "C6"]), 0.11, 0.25))
	_add("menu_move", Synth.sweep(Synth.Wave.SINE, 880.0, 990.0, 0.04, 0.25))
	_add("menu_select", Synth.arpeggio(Synth.Wave.SINE, PackedStringArray(["E5", "B5"]), 0.06, 0.35))
	_add("pause", Synth.arpeggio(Synth.Wave.SINE, PackedStringArray(["C6", "G5"]), 0.06, 0.3))
