package;

import audio.AudioAPI;
import debug.FPSCounter;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import lime.system.System as LimeSystem;
import lime.app.Application;
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

class Main extends Sprite
{
	var game = {
		width:          1280,
		height:         720,
		initialState:   TitleState,
		zoom:           -1.0,
		framerate:      60,
		skipSplash:     true,
		startFullscreen: false
	};

	public static var fpsVar:FPSCounter;

	#if mobile
	public static final platform:String = "Mobile";
	#else
	public static final platform:String = "Desktop";
	#end

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
		@:functionCode("
			#include <windows.h>
			#include <winuser.h>
			setProcessDPIAware();
			DisableProcessWindowsGhosting();
		")
		#end

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?e:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		#if (openfl <= "9.2.0")
		var stageWidth:Int  = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth  / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom   = Math.min(ratioX, ratioY);
			game.width  = Math.ceil(stageWidth  / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
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

		addChild(new FlxGame(
			game.width, game.height,
			#if COPYSTATE_ALLOWED !CopyState.checkExistingFiles() ? CopyState : #end game.initialState,
			#if (flixel < "5.0.0") game.zoom, #end
			game.framerate, game.framerate,
			game.skipSplash, game.startFullscreen
		));

		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);

		Lib.current.stage.align     = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		if (fpsVar != null)
			fpsVar.visible = ClientPrefs.data.showFPS;

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
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

		FlxG.signals.gameResized.add(_onGameResized);
	}

	function _onGameResized(w:Int, h:Int):Void
	{
		var scale = Math.min(
			Lib.current.stage.stageWidth  / FlxG.width,
			Lib.current.stage.stageHeight / FlxG.height
		);

		if (fpsVar != null)
			fpsVar.positionFPS(10, 3, scale);

		if (FlxG.cameras != null)
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
		#end
	}

	static function _resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap     = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
