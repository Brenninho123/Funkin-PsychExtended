package audio;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.media.SoundMixer;
import openfl.media.SoundTransform;

class AudioAPI
{
	public static inline final MAX_VOLUME:Float    = 1.0;
	public static inline final MIN_VOLUME:Float    = 0.0;
	public static inline final DEFAULT_PITCH:Float = 1.0;

	public static var masterVolume(default, set):Float = 1.0;
	public static var masterPan(default, set):Float    = 0.0;
	public static var masterMuted(default, set):Bool   = false;

	public static var musicVolume(default, set):Float  = 1.0;
	public static var sfxVolume(default, set):Float    = 1.0;
	public static var vocalVolume(default, set):Float  = 1.0;

	static var _duckTween:FlxTween  = null;
	static var _fadeTween:FlxTween  = null;
	static var _crossTween:FlxTween = null;

	static var _registeredSounds:Array<FlxSound>  = [];
	static var _registeredMusic:Array<FlxSound>   = [];
	static var _registeredVocals:Array<FlxSound>  = [];

	static var _eqLow:Float   = 1.0;
	static var _eqMid:Float   = 1.0;
	static var _eqHigh:Float  = 1.0;

	static var _reverbWet:Float = 0.0;
	static var _chorusWet:Float = 0.0;

	static var _recordingBuffer:Array<Float> = [];
	static var _isRecording:Bool = false;
	static var _recordSampleRate:Int = 44100;
	static var _recordStartTime:Float = 0.0;

	static var _initialized:Bool = false;

	public static function init():Void
	{
		if (_initialized) return;
		_initialized = true;
		loadPrefs();
		_applyMasterTransform();
	}

	public static function loadPrefs():Void
	{
		if (ClientPrefs.data == null) return;
		masterVolume = ClientPrefs.data.masterVolume != null ? ClientPrefs.data.masterVolume : 1.0;
		musicVolume  = ClientPrefs.data.musicVolume  != null ? ClientPrefs.data.musicVolume  : 1.0;
		sfxVolume    = ClientPrefs.data.sfxVolume    != null ? ClientPrefs.data.sfxVolume    : 1.0;
		vocalVolume  = ClientPrefs.data.vocalVolume  != null ? ClientPrefs.data.vocalVolume  : 1.0;
		masterMuted  = ClientPrefs.data.masterMuted  != null ? ClientPrefs.data.masterMuted  : false;
	}

	public static function savePrefs():Void
	{
		if (ClientPrefs.data == null) return;
		ClientPrefs.data.masterVolume = masterVolume;
		ClientPrefs.data.musicVolume  = musicVolume;
		ClientPrefs.data.sfxVolume    = sfxVolume;
		ClientPrefs.data.vocalVolume  = vocalVolume;
		ClientPrefs.data.masterMuted  = masterMuted;
		ClientPrefs.saveSettings();
	}

	static function _applyMasterTransform():Void
	{
		var vol:Float = masterMuted ? 0.0 : _clamp(masterVolume, 0.0, 1.0);
		SoundMixer.soundTransform = new SoundTransform(vol, _clamp(masterPan, -1.0, 1.0));
	}

	public static function registerSound(snd:FlxSound, bus:String = 'sfx'):Void
	{
		if (snd == null) return;
		switch (bus.toLowerCase())
		{
			case 'music':
				_registeredMusic.push(snd);
				_applyBus(snd, musicVolume);
			case 'vocals':
				_registeredVocals.push(snd);
				_applyBus(snd, vocalVolume);
			default:
				_registeredSounds.push(snd);
				_applyBus(snd, sfxVolume);
		}
	}

	public static function unregisterSound(snd:FlxSound):Void
	{
		_registeredSounds.remove(snd);
		_registeredMusic.remove(snd);
		_registeredVocals.remove(snd);
	}

	static function _applyBus(snd:FlxSound, busVol:Float):Void
	{
		if (snd == null) return;
		snd.volume = _clamp(busVol, 0.0, 1.0);
	}

	static function _refreshBus(bus:Array<FlxSound>, vol:Float):Void
	{
		for (snd in bus)
			if (snd != null) snd.volume = _clamp(vol, 0.0, 1.0);
	}

	public static function setMusicVolume(vol:Float, ?duration:Float = 0.0):Void
	{
		if (duration > 0)
		{
			var from = musicVolume;
			FlxTween.num(from, vol, duration, {ease: FlxEase.quadOut}, function(v:Float)
			{
				musicVolume = v;
			});
		}
		else
			musicVolume = vol;
	}

	public static function setSFXVolume(vol:Float, ?duration:Float = 0.0):Void
	{
		if (duration > 0)
		{
			var from = sfxVolume;
			FlxTween.num(from, vol, duration, {ease: FlxEase.quadOut}, function(v:Float)
			{
				sfxVolume = v;
			});
		}
		else
			sfxVolume = vol;
	}

	public static function setVocalVolume(vol:Float, ?duration:Float = 0.0):Void
	{
		if (duration > 0)
		{
			var from = vocalVolume;
			FlxTween.num(from, vol, duration, {ease: FlxEase.quadOut}, function(v:Float)
			{
				vocalVolume = v;
			});
		}
		else
			vocalVolume = vol;
	}

	public static function fadeIn(?duration:Float = 1.0, ?targetVol:Float = 1.0):Void
	{
		if (_fadeTween != null) { _fadeTween.cancel(); _fadeTween = null; }
		masterVolume = 0.0;
		_applyMasterTransform();
		_fadeTween = FlxTween.num(0.0, _clamp(targetVol, 0.0, 1.0), duration, {ease: FlxEase.quadOut}, function(v:Float)
		{
			masterVolume = v;
		});
	}

	public static function fadeOut(?duration:Float = 1.0, ?onComplete:Void->Void):Void
	{
		if (_fadeTween != null) { _fadeTween.cancel(); _fadeTween = null; }
		var from = masterVolume;
		_fadeTween = FlxTween.num(from, 0.0, duration, {ease: FlxEase.quadIn}, function(v:Float)
		{
			masterVolume = v;
			if (v <= 0.0 && onComplete != null) onComplete();
		});
	}

	public static function crossfade(from:FlxSound, to:FlxSound, ?duration:Float = 1.5):Void
	{
		if (from == null && to == null) return;
		if (_crossTween != null) { _crossTween.cancel(); _crossTween = null; }

		if (to != null && !to.playing)
		{
			to.volume = 0.0;
			to.play();
		}

		var startFromVol:Float = from != null ? from.volume : 0.0;
		var startToVol:Float   = musicVolume;

		_crossTween = FlxTween.num(0.0, 1.0, duration, {ease: FlxEase.sineInOut}, function(t:Float)
		{
			if (from != null) from.volume = _clamp(startFromVol * (1.0 - t), 0.0, 1.0);
			if (to   != null) to.volume   = _clamp(startToVol  * t,          0.0, 1.0);
		});

		FlxTween.num(0.0, 1.0, duration, {ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				if (from != null) { from.stop(); from.volume = startFromVol; }
			}
		}, function(_) {});
	}

	public static function duck(?amount:Float = 0.3, ?duration:Float = 0.2, ?holdTime:Float = 1.0, ?releaseDuration:Float = 0.4):Void
	{
		if (_duckTween != null) { _duckTween.cancel(); _duckTween = null; }

		var original = musicVolume;
		var target   = _clamp(musicVolume * amount, 0.0, 1.0);

		_duckTween = FlxTween.num(original, target, duration, {ease: FlxEase.quadOut}, function(v:Float)
		{
			_refreshBus(_registeredMusic, v);
		});

		new flixel.util.FlxTimer().start(duration + holdTime, function(_)
		{
			FlxTween.num(target, original, releaseDuration, {ease: FlxEase.quadIn}, function(v:Float)
			{
				_refreshBus(_registeredMusic, v);
			});
		});
	}

	public static function stopDuck():Void
	{
		if (_duckTween != null) { _duckTween.cancel(); _duckTween = null; }
		_refreshBus(_registeredMusic, musicVolume);
	}

	public static function mute():Void   { masterMuted = true;  }
	public static function unmute():Void { masterMuted = false; }
	public static function toggleMute():Void { masterMuted = !masterMuted; }

	public static function setEQ(?low:Float = 1.0, ?mid:Float = 1.0, ?high:Float = 1.0):Void
	{
		_eqLow  = _clamp(low,  0.0, 2.0);
		_eqMid  = _clamp(mid,  0.0, 2.0);
		_eqHigh = _clamp(high, 0.0, 2.0);
		_applyEQ();
	}

	public static function eqPreset(preset:String):Void
	{
		switch (preset.toLowerCase())
		{
			case 'bass boost':   setEQ(1.8, 1.0, 0.8);
			case 'treble boost': setEQ(0.8, 1.0, 1.8);
			case 'vocal boost':  setEQ(0.9, 1.6, 1.1);
			case 'flat':         setEQ(1.0, 1.0, 1.0);
			case 'cinema':       setEQ(1.4, 1.2, 0.9);
			case 'game':         setEQ(1.2, 1.0, 1.3);
			default:             setEQ(1.0, 1.0, 1.0);
		}
	}

	static function _applyEQ():Void
	{
		var combined = (_eqLow + _eqMid + _eqHigh) / 3.0;
		combined = _clamp(combined, 0.0, 1.0);
		var transform = SoundMixer.soundTransform;
		if (transform != null)
		{
			transform.volume = _clamp(masterVolume * combined, 0.0, 1.0);
			SoundMixer.soundTransform = transform;
		}
	}

	public static function setReverb(wet:Float):Void
		_reverbWet = _clamp(wet, 0.0, 1.0);

	public static function setChorus(wet:Float):Void
		_chorusWet = _clamp(wet, 0.0, 1.0);

	public static function playWithPitch(snd:FlxSound, pitch:Float = 1.0):Void
	{
		if (snd == null) return;
		snd.pitch = _clamp(pitch, 0.1, 4.0);
		if (!snd.playing) snd.play();
	}

	public static function playWithDelay(snd:FlxSound, delay:Float):Void
	{
		if (snd == null) return;
		new flixel.util.FlxTimer().start(delay, function(_) { if (snd != null) snd.play(); });
	}

	public static function playLooped(snd:FlxSound, ?vol:Float = 1.0):Void
	{
		if (snd == null) return;
		snd.volume = _clamp(vol, 0.0, 1.0);
		snd.looped = true;
		snd.play();
	}

	public static function stopAll():Void
	{
		for (snd in _registeredSounds)  if (snd != null) snd.stop();
		for (snd in _registeredMusic)   if (snd != null) snd.stop();
		for (snd in _registeredVocals)  if (snd != null) snd.stop();
	}

	public static function pauseAll():Void
	{
		for (snd in _registeredSounds)  if (snd != null && snd.playing) snd.pause();
		for (snd in _registeredMusic)   if (snd != null && snd.playing) snd.pause();
		for (snd in _registeredVocals)  if (snd != null && snd.playing) snd.pause();
	}

	public static function resumeAll():Void
	{
		for (snd in _registeredSounds)  if (snd != null) snd.resume();
		for (snd in _registeredMusic)   if (snd != null) snd.resume();
		for (snd in _registeredVocals)  if (snd != null) snd.resume();
	}

	public static function startRecording(?sampleRate:Int = 44100):Void
	{
		if (_isRecording) return;
		_isRecording       = true;
		_recordSampleRate  = sampleRate;
		_recordStartTime   = haxe.Timer.stamp();
		_recordingBuffer   = [];
	}

	public static function stopRecording():Array<Float>
	{
		if (!_isRecording) return [];
		_isRecording = false;
		var result   = _recordingBuffer.copy();
		_recordingBuffer = [];
		return result;
	}

	public static function pushRecordingSample(sample:Float):Void
	{
		if (!_isRecording) return;
		_recordingBuffer.push(_clamp(sample, -1.0, 1.0));
	}

	public static function getRecordingDuration():Float
	{
		if (!_isRecording) return 0.0;
		return haxe.Timer.stamp() - _recordStartTime;
	}

	public static function isRecording():Bool
		return _isRecording;

	public static function exportRecordingWAV(buffer:Array<Float>, ?filename:String = 'recording.wav'):Bool
	{
		#if sys
		try
		{
			var numSamples  = buffer.length;
			var byteRate    = _recordSampleRate * 2;
			var dataSize    = numSamples * 2;
			var totalSize   = 44 + dataSize;

			var bytes = new haxe.io.BytesOutput();
			bytes.writeString('RIFF');
			bytes.writeInt32(totalSize - 8);
			bytes.writeString('WAVE');
			bytes.writeString('fmt ');
			bytes.writeInt32(16);
			bytes.writeUInt16(1);
			bytes.writeUInt16(1);
			bytes.writeInt32(_recordSampleRate);
			bytes.writeInt32(byteRate);
			bytes.writeUInt16(2);
			bytes.writeUInt16(16);
			bytes.writeString('data');
			bytes.writeInt32(dataSize);

			for (sample in buffer)
			{
				var s = Std.int(_clamp(sample, -1.0, 1.0) * 32767);
				bytes.writeUInt16(s < 0 ? s + 65536 : s);
			}

			sys.io.File.saveBytes(filename, bytes.getBytes());
			return true;
		}
		catch (_) { return false; }
		#else
		return false;
		#end
	}

	public static function getInfo():Dynamic
	{
		return {
			masterVolume:    masterVolume,
			masterMuted:     masterMuted,
			masterPan:       masterPan,
			musicVolume:     musicVolume,
			sfxVolume:       sfxVolume,
			vocalVolume:     vocalVolume,
			eqLow:           _eqLow,
			eqMid:           _eqMid,
			eqHigh:          _eqHigh,
			reverbWet:       _reverbWet,
			chorusWet:       _chorusWet,
			isRecording:     _isRecording,
			registeredSFX:   _registeredSounds.length,
			registeredMusic: _registeredMusic.length,
			registeredVocals:_registeredVocals.length
		};
	}

	public static function reset():Void
	{
		stopAll();
		if (_duckTween  != null) { _duckTween.cancel();  _duckTween  = null; }
		if (_fadeTween  != null) { _fadeTween.cancel();  _fadeTween  = null; }
		if (_crossTween != null) { _crossTween.cancel(); _crossTween = null; }
		_registeredSounds  = [];
		_registeredMusic   = [];
		_registeredVocals  = [];
		_recordingBuffer   = [];
		_isRecording       = false;
		masterVolume = 1.0;
		musicVolume  = 1.0;
		sfxVolume    = 1.0;
		vocalVolume  = 1.0;
		masterMuted  = false;
		masterPan    = 0.0;
		_eqLow = _eqMid = _eqHigh = 1.0;
		_applyMasterTransform();
	}

	static inline function _clamp(v:Float, min:Float, max:Float):Float
		return v < min ? min : v > max ? max : v;

	static function set_masterVolume(v:Float):Float
	{
		masterVolume = _clamp(v, 0.0, 1.0);
		_applyMasterTransform();
		return masterVolume;
	}

	static function set_masterPan(v:Float):Float
	{
		masterPan = _clamp(v, -1.0, 1.0);
		_applyMasterTransform();
		return masterPan;
	}

	static function set_masterMuted(v:Bool):Bool
	{
		masterMuted = v;
		_applyMasterTransform();
		return masterMuted;
	}

	static function set_musicVolume(v:Float):Float
	{
		musicVolume = _clamp(v, 0.0, 1.0);
		_refreshBus(_registeredMusic, musicVolume);
		return musicVolume;
	}

	static function set_sfxVolume(v:Float):Float
	{
		sfxVolume = _clamp(v, 0.0, 1.0);
		_refreshBus(_registeredSounds, sfxVolume);
		return sfxVolume;
	}

	static function set_vocalVolume(v:Float):Float
	{
		vocalVolume = _clamp(v, 0.0, 1.0);
		_refreshBus(_registeredVocals, vocalVolume);
		return vocalVolume;
	}
}
