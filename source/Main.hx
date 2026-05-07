package;

import audio.AudioAPI;
import debug.AntiCrasher;
import debug.FPSCounter;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.display.StageQuality;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.FocusEvent;
import openfl.system.System as OpenFlSystem;

import lime.app.Application;
import lime.system.System as LimeSystem;

import states.TitleState;
import mobile.backend.MobileScaleMode;

#if COPYSTATE_ALLOWED
import states.CopyState;
#end

#if linux
import lime.graphics.Image;
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

#if windows
@:cppFileCode('#include <windows.h>\n#include <winuser.h>')
#end

class Main extends Sprite
{
	static inline final GAME_WIDTH:Int    = 1280;
	static inline final GAME_HEIGHT:Int   = 720;
	static inline final FRAMERATE:Int     = 60;
	static inline final MAX_FRAMERATE:Int = 240;
	static inline final MIN_FRAMERATE:Int = 60;
	static inline final MAX_MEMORY_MB:Float = 768.0;

	var game = {
		width:          GAME_WIDTH,
		height:         GAME_HEIGHT,
		initialState:   TitleState,
		zoom:           -1.0,
		framerate:      FRAMERATE,
		skipSplash:     true,
		startFullscreen: false
	};

	public static var fpsVar:FPSCounter;

	public static var focused:Bool    = true;
	public static var suspended:Bool  = false;

	#if mobile
	public static final platform:String = "Mobile";
	#else
	public static final platform:String = "Desktop";
	#end

	static var _gcTimer:FlxTimer  = null;
	static var _lastMemMB:Float   = 0.0;
	static var _initDone:Bool     = false;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		cpp.NativeGc.run(true);
		#end
	}

	public function new()
	{
		super();

		#if android
		StorageUtil.requestPermissions();
		#end

		#if mobile
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end

		backend.CrashHandler.init();

		#if windows
		_applyWindowsFlags();
		#end

		if (stage != null)
			_init();
		else
			addEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
	}

	#if windows
	function _applyWindowsFlags():Void
	{
		@:functionCode('
			setProcessDPIAware();
			DisableProcessWindowsGhosting();
		')
	}
	#end

	function _onAddedToStage(e:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
		_init();
	}

	function _init():Void
	{
		if (_initDone) return;
		_initDone = true;
		_setupGame();
	}

	function _setupGame():Void
	{
		#if (openfl <= "9.2.0")
		var sw:Int = Lib.current.stage.stageWidth;
		var sh:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var rx:Float = sw / game.width;
			var ry:Float = sh / game.height;
			game.zoom   = Math.min(rx, ry);
			game.width  = Math.ceil(sw / game.zoom);
			game.height = Math.ceil(sh / game.zoom);
		}
		#else
		if (game.zoom == -1.0) game.zoom = 1.0;
		#end

		#if LUA_ALLOWED
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call));
		#end

		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();
		#end

		var flxGame = new FlxGame(
			game.width, game.height,
			#if COPYSTATE_ALLOWED !CopyState.checkExistingFiles() ? CopyState : #end game.initialState,
			#if (flixel < "5.0.0") game.zoom, #end
			game.framerate, game.framerate,
			game.skipSplash, game.startFullscreen
		);
		addChild(flxGame);

		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);

		Lib.current.stage.align     = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		Lib.current.stage.quality   = StageQuality.LOW;

		if (fpsVar != null)
			fpsVar.visible = ClientPrefs.data.showFPS;

		#if linux
		Lib.current.stage.window.setIcon(Image.fromFile('icon.png'));
		#end

		#if desktop
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, _onKeyUp);
		#end

		#if html5
		FlxG.autoPause     = false;
		FlxG.mouse.visible = false;
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if mobile
		LimeSystem.allowScreenTimeout = false;
		FlxG.scaleMode = new MobileScaleMode();
		#end

		AudioAPI.init();

		AntiCrasher.init(MAX_MEMORY_MB, function(msg:String)
		{
			#if sys
			try { CoolUtil.showPopUp(msg, 'AntiCrasher'); } catch (_) {}
			#end
		});

		_setupFocusHandlers();
		_setupGCScheduler();
		_setupVSync();

		FlxG.signals.gameResized.add(_onGameResized);
		FlxG.signals.preStateSwitch.add(_onPreStateSwitch);
		FlxG.signals.postStateSwitch.add(_onPostStateSwitch);

		Application.current.window.onClose.add(_onWindowClose);
	}

	function _setupFocusHandlers():Void
	{
		Lib.current.stage.addEventListener(FocusEvent.FOCUS_IN, function(_)
		{
			focused  = true;
			suspended = false;

			if (FlxG.sound.music != null && ClientPrefs.data.autoPause)
			{
				FlxG.sound.music.resume();
				AudioAPI.resumeAll();
			}

			FlxG.game.focusLostFramerate = FRAMERATE;

			#if mobile
			LimeSystem.allowScreenTimeout = false;
			#end
		});

		Lib.current.stage.addEventListener(FocusEvent.FOCUS_OUT, function(_)
		{
			focused   = false;
			suspended = true;

			FlxG.game.focusLostFramerate = 10;

			#if mobile
			LimeSystem.allowScreenTimeout = true;
			#end
		});
	}

	function _setupGCScheduler():Void
	{
		_gcTimer = new FlxTimer();
		_gcTimer.start(30.0, function(_)
		{
			var memMB:Float = OpenFlSystem.totalMemory / 1024 / 1024;

			if (memMB > _lastMemMB + 50)
			{
				#if cpp
				cpp.NativeGc.run(false);
				#end
				openfl.system.System.gc();
			}

			_lastMemMB = memMB;
		}, 0);
	}

	function _setupVSync():Void
	{
		#if sys
		var vFile = (StorageUtil.rootDir != null ? StorageUtil.rootDir : '') + 'vsync.txt';
		try
		{
			if (sys.FileSystem.exists(vFile))
			{
				var val = sys.io.File.getContent(vFile).trim();
				if (val == 'true')
					Lib.current.stage.window.vsync = true;
			}
		}
		catch (_) {}
		#end
	}

	function _onPreStateSwitch():Void
	{
		FlxTimer.globalManager.clear();
		FlxTween.globalManager.clear();

		if (FlxG.sound.music != null)
		{
			try { FlxG.sound.music.stop(); } catch (_) {}
		}

		try { FlxG.cameras.reset(); } catch (_) {}

		#if cpp
		cpp.NativeGc.run(false);
		#end
	}

	function _onPostStateSwitch():Void
	{
		if (FlxG.cameras == null || FlxG.cameras.list == null || FlxG.cameras.list.length == 0)
		{
			try { FlxG.cameras.reset(); } catch (_) {}
		}

		if (fpsVar != null)
			fpsVar.visible = ClientPrefs.data.showFPS;

		AudioAPI.loadPrefs();

		#if cpp
		cpp.NativeGc.run(true);
		#end

		openfl.system.System.gc();
	}

	function _onGameResized(w:Int, h:Int):Void
	{
		var scale = Math.min(
			Lib.current.stage.stageWidth  / FlxG.width,
			Lib.current.stage.stageHeight / FlxG.height
		);

		if (fpsVar != null)
			fpsVar.positionFPS(10, 3, scale);

		if (FlxG.cameras != null && FlxG.cameras.list != null)
			for (cam in FlxG.cameras.list)
				if (cam != null && cam.filters != null)
					_resetSpriteCache(cam.flashSprite);

		if (FlxG.game != null)
			_resetSpriteCache(FlxG.game);
	}

	function _onKeyUp(e:KeyboardEvent):Void
	{
		#if desktop
		if (Controls.instance.justReleased('fullscreen'))
			FlxG.fullscreen = !FlxG.fullscreen;

		if (Controls.instance.justReleased('volume_mute'))
			AudioAPI.toggleMute();
		#end
	}

	function _onWindowClose():Void
	{
		AudioAPI.savePrefs();
		ClientPrefs.saveSettings();

		#if DISCORD_ALLOWED
		if (DiscordClient.isInitialized)
			DiscordClient.shutdown();
		#end

		AntiCrasher.clearLog();
	}

	static function _resetSpriteCache(sprite:Sprite):Void
	{
		if (sprite == null) return;
		@:privateAccess
		{
			sprite.__cacheBitmap     = null;
			sprite.__cacheBitmapData = null;
		}
	}

	public static function forceGC():Void
	{
		openfl.system.System.gc();
		#if cpp
		cpp.NativeGc.run(true);
		cpp.NativeGc.compact();
		#end
		#if hl
		hl.Gc.major();
		#end
	}

	public static function getMemoryMB():Float
		return OpenFlSystem.totalMemory / 1024 / 1024;

	public static function setFramerate(fps:Int):Void
	{
		var clamped = Std.int(FlxMath.bound(fps, MIN_FRAMERATE, MAX_FRAMERATE));
		FlxG.updateFramerate = clamped;
		FlxG.drawFramerate   = clamped;
		ClientPrefs.data.framerate = clamped;
	}

	public static function setQuality(high:Bool):Void
	{
		Lib.current.stage.quality = high ? StageQuality.HIGH : StageQuality.LOW;
	}

	public static function takeScreenshot():Void
	{
		#if sys
		try
		{
			var bmd = new openfl.display.BitmapData(FlxG.width, FlxG.height, false);
			bmd.draw(Lib.current.stage);
			var png  = bmd.encode(new openfl.geom.Rectangle(0, 0, FlxG.width, FlxG.height),
				new openfl.display.PNGEncoderOptions());
			var date = Date.now();
			var name = 'screenshot_${date.getFullYear()}${date.getMonth()+1}${date.getDate()}_${date.getHours()}${date.getMinutes()}${date.getSeconds()}.png';
			var dir  = 'screenshots';
			if (!sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir);
			sys.io.File.saveBytes('$dir/$name', png);
		}
		catch (_) {}
		#end
	}
}
