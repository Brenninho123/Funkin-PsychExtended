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
import flixel.util.FlxColor;

import haxe.io.Path;
import haxe.Timer;

import openfl.Assets;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.display.Sprite;
import openfl.display.StageQuality;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
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
@:cppFileCode('
	#include <windows.h>
	#include <winuser.h>
')
#end

class Main extends Sprite
{
	public static inline final ENGINE_NAME:String = "Psych Extended";

	public static inline final GAME_WIDTH:Int = 1280;
	public static inline final GAME_HEIGHT:Int = 720;

	public static inline final DEFAULT_FPS:Int = 60;
	public static inline final MAX_FPS:Int = 240;
	public static inline final MIN_FPS:Int = 30;

	public static inline final MEMORY_LIMIT_MB:Float = 1024;

	public static var fpsCounter:FPSCounter;

	public static var focused:Bool = true;
	public static var minimized:Bool = false;
	public static var initialized:Bool = false;

	public static var deltaMultiplier:Float = 1.0;
	public static var elapsedTime:Float = 0.0;

	public static var lowMemoryMode:Bool = false;
	public static var dynamicFramerate:Bool = true;

	public static var stateStartTime:Float = 0;

	#if mobile
	public static inline final PLATFORM:String = "Mobile";
	#else
	public static inline final PLATFORM:String = "Desktop";
	#end

	private var gameConfig = {
		width: GAME_WIDTH,
		height: GAME_HEIGHT,
		initialState: TitleState,
		zoom: -1.0,
		framerate: DEFAULT_FPS,
		skipSplash: true,
		startFullscreen: false
	};

	static var gcTimer:FlxTimer;
	static var perfTimer:FlxTimer;

	static var memoryPeak:Float = 0;
	static var lastMemory:Float = 0;

	static var fpsDropFrames:Int = 0;
	static var lastFrameTime:Float = 0;

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
		setupWindowsOptimizations();
		#end

		if (stage != null)
			initialize();
		else
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
	}

	function onAdded(e:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAdded);
		initialize();
	}

	function initialize():Void
	{
		if (initialized)
			return;

		initialized = true;

		setupGame();
		setupEngine();
		setupPerformanceSystems();
		setupSignals();
		setupFocusEvents();
		setupFPSCounter();
		setupAudio();
		setupMemoryManager();
		setupStage();
		setupPlatformStuff();
		setupAdvancedSystems();

		stateStartTime = Timer.stamp();
	}

	function setupGame():Void
	{
		#if (openfl <= "9.2.0")
		var sw = Lib.current.stage.stageWidth;
		var sh = Lib.current.stage.stageHeight;

		if (gameConfig.zoom == -1.0)
		{
			var ratioX = sw / gameConfig.width;
			var ratioY = sh / gameConfig.height;

			gameConfig.zoom = Math.min(ratioX, ratioY);

			gameConfig.width = Math.ceil(sw / gameConfig.zoom);
			gameConfig.height = Math.ceil(sh / gameConfig.zoom);
		}
		#else
		gameConfig.zoom = 1;
		#end

		#if LUA_ALLOWED
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call));
		#end

		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();
		#end

		var game = new FlxGame(
			gameConfig.width,
			gameConfig.height,
			#if COPYSTATE_ALLOWED !CopyState.checkExistingFiles() ? CopyState : #end gameConfig.initialState,
			#if (flixel < "5.0.0") gameConfig.zoom, #end
			gameConfig.framerate,
			gameConfig.framerate,
			gameConfig.skipSplash,
			gameConfig.startFullscreen
		);

		addChild(game);
	}

	function setupStage():Void
	{
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		Lib.current.stage.quality = StageQuality.LOW;

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
	}

	function setupFPSCounter():Void
	{
		fpsCounter = new FPSCounter(10, 3, FlxColor.WHITE);
		addChild(fpsCounter);

		fpsCounter.visible = ClientPrefs.data.showFPS;
	}

	function setupAudio():Void
	{
		AudioAPI.init();
		AudioAPI.loadPrefs();
	}

	function setupPlatformStuff():Void
	{
		#if mobile
		LimeSystem.allowScreenTimeout = false;
		FlxG.scaleMode = new MobileScaleMode();
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if linux
		Lib.current.stage.window.setIcon(Image.fromFile("icon.png"));
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end
	}

	function setupSignals():Void
	{
		FlxG.signals.gameResized.add(onResize);
		FlxG.signals.preStateSwitch.add(onPreStateSwitch);
		FlxG.signals.postStateSwitch.add(onPostStateSwitch);

		Application.current.window.onClose.add(onClose);
	}

	function setupFocusEvents():Void
	{
		Lib.current.stage.addEventListener(FocusEvent.FOCUS_IN, function(_)
		{
			focused = true;
			minimized = false;

			FlxG.game.focusLostFramerate = DEFAULT_FPS;

			if (FlxG.sound.music != null && ClientPrefs.data.autoPause)
			{
				FlxG.sound.music.resume();
				AudioAPI.resumeAll();
			}

			#if mobile
			LimeSystem.allowScreenTimeout = false;
			#end
		});

		Lib.current.stage.addEventListener(FocusEvent.FOCUS_OUT, function(_)
		{
			focused = false;
			minimized = true;

			FlxG.game.focusLostFramerate = 10;

			#if mobile
			LimeSystem.allowScreenTimeout = true;
			#end
		});

		#if desktop
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		#end
	}

	function setupPerformanceSystems():Void
	{
		lastFrameTime = Timer.stamp();

		perfTimer = new FlxTimer();
		perfTimer.start(1 / 30, function(_)
		{
			var current = Timer.stamp();
			var delta = current - lastFrameTime;

			lastFrameTime = current;

			elapsedTime = delta;
			deltaMultiplier = delta * DEFAULT_FPS;

			checkPerformance();
		}, 0);
	}

	function setupMemoryManager():Void
	{
		gcTimer = new FlxTimer();

		gcTimer.start(15, function(_)
		{
			var mem = getMemoryMB();

			if (mem > memoryPeak)
				memoryPeak = mem;

			if (mem > MEMORY_LIMIT_MB)
			{
				forceGC();

				lowMemoryMode = true;

				clearUnusedAssets();
			}

			if (mem > lastMemory + 32)
			{
				#if cpp
				cpp.NativeGc.run(false);
				#end

				OpenFlSystem.gc();
			}

			lastMemory = mem;

		}, 0);
	}

	function setupAdvancedSystems():Void
	{
		FlxGraphic.defaultPersist = true;
		FlxGraphic.destroyOnNoUse = false;

		FlxG.fixedTimestep = false;

		if (dynamicFramerate)
			optimizeFPS();
	}

	function setupEngine():Void
	{
		trace("===============================");
		trace(ENGINE_NAME);
		trace("Platform: " + PLATFORM);
		trace("Memory: " + Std.int(getMemoryMB()) + " MB");
		trace("===============================");
	}

	#if windows
	function setupWindowsOptimizations():Void
	{
		@:functionCode('
			SetProcessDPIAware();
			DisableProcessWindowsGhosting();
			timeBeginPeriod(1);
		')
	}
	#end

	function optimizeFPS():Void
	{
		var fps = ClientPrefs.data.framerate;

		if (fps < MIN_FPS)
			fps = MIN_FPS;

		if (fps > MAX_FPS)
			fps = MAX_FPS;

		FlxG.updateFramerate = fps;
		FlxG.drawFramerate = fps;
	}

	function checkPerformance():Void
	{
		if (FlxG.drawFramerate < 50)
			fpsDropFrames++;
		else
			fpsDropFrames = 0;

		if (fpsDropFrames > 120)
		{
			lowMemoryMode = true;

			FlxTween.globalManager.clear();

			forceGC();

			fpsDropFrames = 0;
		}
	}

	function clearUnusedAssets():Void
	{
		try
		{
			Assets.cache.clear("songs");
			Assets.cache.clear("music");
			Assets.cache.clear("sounds");

			FlxG.bitmap.clearUnused();

			forceGC();
		}
		catch (_) {}
	}

	function onResize(w:Int, h:Int):Void
	{
		var scale = Math.min(
			Lib.current.stage.stageWidth / FlxG.width,
			Lib.current.stage.stageHeight / FlxG.height
		);

		if (fpsCounter != null)
			fpsCounter.positionFPS(10, 3, scale);

		if (FlxG.game != null)
			resetSpriteCache(FlxG.game);

		if (FlxG.cameras != null)
		{
			for (cam in FlxG.cameras.list)
			{
				if (cam != null)
					resetSpriteCache(cam.flashSprite);
			}
		}
	}

	function onPreStateSwitch():Void
	{
		FlxTimer.globalManager.clear();
		FlxTween.globalManager.clear();

		try
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
		}
		catch (_) {}

		forceGC();
	}

	function onPostStateSwitch():Void
	{
		if (fpsCounter != null)
			fpsCounter.visible = ClientPrefs.data.showFPS;

		AudioAPI.loadPrefs();

		stateStartTime = Timer.stamp();

		forceGC();
	}

	function onKeyUp(e:KeyboardEvent):Void
	{
		#if desktop

		if (Controls.instance.justReleased("fullscreen"))
			FlxG.fullscreen = !FlxG.fullscreen;

		if (Controls.instance.justReleased("volume_mute"))
			AudioAPI.toggleMute();

		if (Controls.instance.justReleased("screenshot"))
			takeScreenshot();

		#end
	}

	function onClose():Void
	{
		ClientPrefs.saveSettings();
		AudioAPI.savePrefs();

		#if DISCORD_ALLOWED
		if (DiscordClient.isInitialized)
			DiscordClient.shutdown();
		#end

		AntiCrasher.clearLog();

		forceGC();
	}

	public static function takeScreenshot():Void
	{
		#if sys

		try
		{
			var bmp = new BitmapData(FlxG.width, FlxG.height, false);

			bmp.draw(Lib.current.stage);

			var png = bmp.encode(
				new Rectangle(0, 0, FlxG.width, FlxG.height),
				new PNGEncoderOptions()
			);

			var date = Date.now();

			var file = 'shot_${date.getTime()}.png';

			if (!sys.FileSystem.exists("screenshots"))
				sys.FileSystem.createDirectory("screenshots");

			sys.io.File.saveBytes('screenshots/$file', png);
		}
		catch (_) {}

		#end
	}

	public static function setFPS(fps:Int):Void
	{
		fps = Std.int(FlxMath.bound(fps, MIN_FPS, MAX_FPS));

		FlxG.updateFramerate = fps;
		FlxG.drawFramerate = fps;

		ClientPrefs.data.framerate = fps;
	}

	public static function setQuality(high:Bool):Void
	{
		Lib.current.stage.quality = high ? StageQuality.HIGH : StageQuality.LOW;
	}

	public static function forceGC():Void
	{
		OpenFlSystem.gc();

		#if cpp
		cpp.NativeGc.run(true);
		cpp.NativeGc.compact();
		#end

		#if hl
		hl.Gc.major();
		#end
	}

	public static function getMemoryMB():Float
	{
		return OpenFlSystem.totalMemory / 1024 / 1024;
	}

	public static function getUptime():Float
	{
		return Timer.stamp() - stateStartTime;
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		if (sprite == null)
			return;

		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}