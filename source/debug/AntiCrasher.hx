package debug;

import flixel.FlxG;
import flixel.util.FlxTimer;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class AntiCrasher
{
	static var _initialized:Bool = false;
	static var _logPath:String   = 'crash_log.txt';
	static var _maxMemoryMB:Float = 512.0;
	static var _memCheckTimer:FlxTimer = null;
	static var _lastErrors:Array<String> = [];
	static var _maxErrorLog:Int = 50;
	static var _onCrash:String->Void = null;

	public static function init(?maxMemoryMB:Float = 512.0, ?onCrash:String->Void):Void
	{
		if (_initialized) return;
		_initialized  = true;
		_maxMemoryMB  = maxMemoryMB;
		_onCrash      = onCrash;

		_hookUncaughtErrors();
		_hookNativeErrors();
		_startMemoryWatcher();
		_startStateWatcher();
	}

	static function _hookUncaughtErrors():Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
			UncaughtErrorEvent.UNCAUGHT_ERROR,
			function(e:UncaughtErrorEvent)
			{
				e.preventDefault();
				e.stopImmediatePropagation();
				_handle('UncaughtError', Std.string(e.error));
			}
		);
	}

	static function _hookNativeErrors():Void
	{
		#if cpp
		cpp.vm.Gc.setMinimumFreeSpace(4 * 1024 * 1024);
		untyped __cpp__('
			struct CrashHandler {
				static void handle(const char* msg) {
					printf("[AntiCrasher] Native crash: %s\\n", msg);
				}
			};
		');
		#end
	}

	static function _startMemoryWatcher():Void
	{
		if (_memCheckTimer != null) return;
		_memCheckTimer = new FlxTimer();
		_memCheckTimer.start(3.0, function(_)
		{
			_checkMemory();
			_checkAudio();
			_checkCamera();
			_checkState();
		}, 0);
	}

	static function _startStateWatcher():Void
	{
		FlxG.signals.preStateSwitch.add(function()
		{
			_safeCall(function()
			{
				if (FlxG.sound.music != null && FlxG.sound.music.playing)
					FlxG.sound.music.stop();
			}, 'preStateSwitch music stop');

			_safeCall(function()
			{
				FlxG.cameras.reset();
			}, 'preStateSwitch camera reset');
		});

		FlxG.signals.postStateSwitch.add(function()
		{
			_safeCall(function()
			{
				if (FlxG.cameras.list.length == 0)
					FlxG.cameras.reset();
			}, 'postStateSwitch camera check');

			_safeCall(function()
			{
				#if cpp
				cpp.NativeGc.run(false);
				#end
			}, 'postStateSwitch GC');
		});
	}

	static function _checkMemory():Void
	{
		var memMB:Float = openfl.system.System.totalMemory / 1024 / 1024;
		if (memMB >= _maxMemoryMB * 0.9)
		{
			_log('MemoryWarning', 'Memory at ${Math.round(memMB)} MB / ${_maxMemoryMB} MB limit');
			_freeMemory();
		}

		if (memMB >= _maxMemoryMB)
		{
			_handle('MemoryLimit', 'Memory exceeded ${_maxMemoryMB} MB (${Math.round(memMB)} MB used)');
			_freeMemory();
			_safeStateReload();
		}
	}

	static function _checkAudio():Void
	{
		_safeCall(function()
		{
			if (FlxG.sound.music != null && Math.isNaN(FlxG.sound.music.time))
			{
				_log('AudioCorrupt', 'Music time is NaN, stopping');
				FlxG.sound.music.stop();
			}

			if (FlxG.sound.music != null && FlxG.sound.music.volume < 0)
			{
				_log('AudioVolume', 'Music volume was negative, resetting');
				FlxG.sound.music.volume = 0;
			}
		}, 'audio check');
	}

	static function _checkCamera():Void
	{
		_safeCall(function()
		{
			if (FlxG.cameras == null || FlxG.cameras.list == null) return;

			for (cam in FlxG.cameras.list)
			{
				if (cam == null) continue;

				if (Math.isNaN(cam.x) || Math.isNaN(cam.y))
				{
					_log('CameraNaN', 'Camera position was NaN, resetting');
					cam.x = 0;
					cam.y = 0;
				}

				if (Math.isNaN(cam.zoom) || cam.zoom <= 0)
				{
					_log('CameraZoom', 'Camera zoom was invalid (${cam.zoom}), resetting');
					cam.zoom = 1.0;
				}

				if (Math.isNaN(cam.alpha) || cam.alpha < 0)
				{
					_log('CameraAlpha', 'Camera alpha was invalid, resetting');
					cam.alpha = 1.0;
				}
			}
		}, 'camera check');
	}

	static function _checkState():Void
	{
		_safeCall(function()
		{
			if (FlxG.state == null)
			{
				_handle('NullState', 'FlxG.state is null, switching to TitleState');
				MusicBeatState.switchState(new states.TitleState());
			}
		}, 'state check');
	}

	static function _freeMemory():Void
	{
		_safeCall(function()
		{
			openfl.system.System.gc();
			#if cpp
			cpp.NativeGc.run(true);
			cpp.NativeGc.compact();
			#end
			#if hl
			hl.Gc.major();
			#end
		}, 'freeMemory');
	}

	static function _safeStateReload():Void
	{
		_safeCall(function()
		{
			if (FlxG.state != null)
			{
				var state = FlxG.state;
				FlxG.resetState();
			}
		}, 'safeStateReload');
	}

	static function _handle(type:String, message:String):Void
	{
		var full = '[AntiCrasher][$type] $message';
		_log(type, message);

		if (_onCrash != null)
			_safeCall(function() { _onCrash(full); }, 'onCrash callback');

		_safeCall(function()
		{
			if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
			{
				var s = cast(FlxG.state, MusicBeatState);
				if (s != null) FlxG.resetState();
			}
		}, 'state reset after handle');
	}

	static function _log(type:String, message:String):Void
	{
		var entry = '[${_timestamp()}][$type] $message';

		if (_lastErrors.length >= _maxErrorLog)
			_lastErrors.shift();
		_lastErrors.push(entry);

		#if sys
		_safeCall(function()
		{
			var dir = 'logs';
			if (!FileSystem.exists(dir)) FileSystem.createDirectory(dir);

			var path = dir + '/' + _logPath;
			var existing = FileSystem.exists(path) ? File.getContent(path) : '';
			File.saveContent(path, existing + entry + '\n');
		}, 'log write');
		#end
	}

	static function _safeCall(fn:Void->Void, context:String = ''):Void
	{
		try { fn(); }
		catch (e:Dynamic)
		{
			var msg = '[AntiCrasher][SafeCallFailed][$context] ${Std.string(e)}';
			if (_lastErrors.length < _maxErrorLog)
				_lastErrors.push(msg);
		}
	}

	static function _timestamp():String
	{
		var d = Date.now();
		var pad = function(n:Int) return n < 10 ? '0$n' : '$n';
		return '${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}';
	}

	public static function getLog():Array<String>
		return _lastErrors.copy();

	public static function clearLog():Void
		_lastErrors = [];

	public static function setMaxMemory(mb:Float):Void
		_maxMemoryMB = mb;

	public static function isInitialized():Bool
		return _initialized;

	public static function safeSwitch(state:flixel.FlxState):Void
	{
		_safeCall(function()
		{
			_freeMemory();
			MusicBeatState.switchState(state);
		}, 'safeSwitch');
	}

	public static function safeOpenSubState(parent:MusicBeatState, sub:flixel.FlxSubState):Void
	{
		if (parent == null || sub == null) return;
		_safeCall(function() { parent.openSubState(sub); }, 'safeOpenSubState');
	}

	public static function safePlay(sound:flixel.sound.FlxSound, ?restart:Bool = false):Void
	{
		if (sound == null) return;
		_safeCall(function()
		{
			if (!sound.playing || restart) sound.play(restart);
		}, 'safePlay');
	}

	public static function safeStop(sound:flixel.sound.FlxSound):Void
	{
		if (sound == null) return;
		_safeCall(function() { sound.stop(); }, 'safeStop');
	}

	public static function wrapUpdate(fn:Float->Void):Float->Void
	{
		return function(elapsed:Float)
		{
			_safeCall(function() { fn(elapsed); }, 'wrapUpdate');
		};
	}
}
