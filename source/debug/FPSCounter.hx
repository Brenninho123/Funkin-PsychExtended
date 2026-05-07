package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;

class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int;
	public var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;

	static var _platform:String = _detectPlatform();

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		positionFPS(x, y);

		currentFPS = 0;
		selectable  = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat('_sans', 14, color);
		autoSize = openfl.text.TextFieldAutoSize.LEFT;
		multiline = false;
		text = 'FPS: --';

		times = [];
	}

	var deltaTimeout:Float = 0.0;

	private override function __enterFrame(deltaTime:Float):Void
	{
		if (deltaTimeout > 1000)
		{
			deltaTimeout = 0.0;
			return;
		}

		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		deltaTimeout += deltaTime;
	}

	public dynamic function updateText():Void
	{
		var mem = flixel.util.FlxStringUtil.formatBytes(memoryMegas);
		text = 'FPS: $currentFPS  •  Memory: $mem  •  System: $_platform';

		if (currentFPS >= FlxG.drawFramerate * 0.75)
			textColor = 0xFFFFFFFF;
		else if (currentFPS >= FlxG.drawFramerate * 0.5)
			textColor = 0xFFFFCC00;
		else
			textColor = 0xFFFF4444;
	}

	inline function get_memoryMegas():Float
		return cast(OpenFlSystem.totalMemory, UInt);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1)
	{
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
	}

	static function _detectPlatform():String
	{
		#if windows  return 'Windows'; #end
		#if mac      return 'macOS';   #end
		#if linux    return 'Linux';   #end
		#if android  return 'Android'; #end
		#if ios      return 'iOS';     #end
		#if html5    return 'Browser'; #end
		#if switch   return 'Switch';  #end
		return LimeSystem.platformName != null ? LimeSystem.platformName : 'Unknown';
	}
}
