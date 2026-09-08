extends Node
## タイトル画面用のBGM。著作権のある音源は一切使わず、AudioStreamGeneratorで
## 波形を自前で合成して再生する、完全オリジナルの短いループ曲。
## イ短調(Aマイナー)のメロディに低音のドローンを重ね、RPGの冒険感を狙った構成。

@onready var player: AudioStreamPlayer = $Player

const MIX_RATE := 44100.0
const MELODY_AMPLITUDE := 0.16
const BASS_AMPLITUDE := 0.10
const NOTE_DURATION := 0.32

## イ短調の音階を使った、上昇アルペジオ→下降で締める16音のオリジナルメロディ(Hz)。0.0は休符。
const MELODY := [
	220.00, 261.63, 329.63, 440.00, 329.63, 261.63, 349.23, 329.63,
	293.66, 261.63, 0.0,    220.00, 329.63, 440.00, 523.25, 0.0,
]

## メロディに厚みを出すための低音ドローン(2小節ごとにA2→F2で和声を動かす)。
const BASS := [110.00, 110.00, 87.31, 87.31]
const BASS_NOTE_SPAN := 4 # MELODYが何音進むごとにBASSを切り替えるか

var _melody_phase := 0.0
var _bass_phase := 0.0
var _note_index := 0
var _note_time := 0.0
var _playback: AudioStreamGeneratorPlayback

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.5
	player.stream = generator
	player.play()
	_playback = player.get_stream_playback()
	_fill_buffer()

func _process(_delta: float) -> void:
	_fill_buffer()

func _fill_buffer() -> void:
	if not _playback:
		return

	var frames_to_fill := _playback.get_frames_available()
	for i in frames_to_fill:
		var melody_freq: float = MELODY[_note_index]
		var bass_freq: float = BASS[(_note_index / BASS_NOTE_SPAN) % BASS.size()]

		# メロディ: 矩形波でチップチューンらしいはっきりした音色にする。
		var sample := 0.0
		if melody_freq > 0.0:
			var mt: float = fmod(_melody_phase, 1.0)
			sample += (1.0 if mt < 0.5 else -1.0) * MELODY_AMPLITUDE
			_melody_phase += melody_freq / MIX_RATE

		# ベース: 三角波でやわらかく低音を支える。
		var bt: float = fmod(_bass_phase, 1.0)
		sample += (absf(bt - 0.5) * 4.0 - 1.0) * BASS_AMPLITUDE
		_bass_phase += bass_freq / MIX_RATE

		_playback.push_frame(Vector2(sample, sample))

		_note_time += 1.0 / MIX_RATE
		if _note_time >= NOTE_DURATION:
			_note_time = 0.0
			_note_index = (_note_index + 1) % MELODY.size()
			_melody_phase = 0.0
