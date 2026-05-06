package mobile.backend;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;

class TouchUtil
{
	public static var pressed(get, never):Bool;
	public static var justPressed(get, never):Bool;
	public static var justReleased(get, never):Bool;
	public static var released(get, never):Bool;
	public static var touch(get, never):Null<FlxTouch>;
	public static var touchCount(get, never):Int;
	public static var hasTouches(get, never):Bool;

	public static function overlaps(object:FlxObject, ?camera:FlxCamera):Bool
	{
		if (object == null) return false;
		var cam = camera != null ? camera : object.camera;
		for (touch in FlxG.touches.list)
			if (touch != null && touch.overlaps(object, cam))
				return true;
		return false;
	}

	public static function overlapsComplex(object:FlxObject, ?camera:FlxCamera):Bool
	{
		if (object == null) return false;

		var point = FlxPoint.get();

		if (camera == null)
		{
			for (cam in object.cameras)
			{
				for (touch in FlxG.touches.list)
				{
					if (touch == null) continue;
					@:privateAccess touch.getWorldPosition(cam, point);
					@:privateAccess
					if (object.overlapsPoint(point, true, cam))
					{
						point.put();
						return true;
					}
				}
			}
		}
		else
		{
			for (touch in FlxG.touches.list)
			{
				if (touch == null) continue;
				@:privateAccess touch.getWorldPosition(camera, point);
				@:privateAccess
				if (object.overlapsPoint(point, true, camera))
				{
					point.put();
					return true;
				}
			}
		}

		point.put();
		return false;
	}

	public static function overlapsPressed(object:FlxObject, ?camera:FlxCamera):Bool
		return pressed && overlaps(object, camera);

	public static function overlapsJustPressed(object:FlxObject, ?camera:FlxCamera):Bool
		return justPressed && overlaps(object, camera);

	public static function overlapsJustReleased(object:FlxObject, ?camera:FlxCamera):Bool
		return justReleased && overlaps(object, camera);

	public static function getTouchesOn(object:FlxObject, ?camera:FlxCamera):Array<FlxTouch>
	{
		if (object == null) return [];
		var cam = camera != null ? camera : object.camera;
		var result:Array<FlxTouch> = [];
		for (touch in FlxG.touches.list)
			if (touch != null && touch.overlaps(object, cam))
				result.push(touch);
		return result;
	}

	public static function getPinchDistance():Float
	{
		var list = FlxG.touches.list;
		if (list.length < 2) return 0;
		var t1 = list[0];
		var t2 = list[1];
		var dx = t1.screenX - t2.screenX;
		var dy = t1.screenY - t2.screenY;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public static function getSwipeDelta(?touch:FlxTouch):FlxPoint
	{
		var t = touch != null ? touch : get_touch();
		if (t == null) return FlxPoint.get(0, 0);
		return FlxPoint.get(t.deltaScreenX, t.deltaScreenY);
	}

	public static function getCentroid():FlxPoint
	{
		var list = FlxG.touches.list;
		if (list.length == 0) return FlxPoint.get(0, 0);
		var sx:Float = 0;
		var sy:Float = 0;
		for (t in list) { sx += t.screenX; sy += t.screenY; }
		return FlxPoint.get(sx / list.length, sy / list.length);
	}

	@:noCompletion
	private static function get_pressed():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch != null && touch.pressed) return true;
		return false;
	}

	@:noCompletion
	private static function get_justPressed():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch != null && touch.justPressed) return true;
		return false;
	}

	@:noCompletion
	private static function get_justReleased():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch != null && touch.justReleased) return true;
		return false;
	}

	@:noCompletion
	private static function get_released():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch != null && touch.released) return true;
		return false;
	}

	@:noCompletion
	private static function get_touch():Null<FlxTouch>
	{
		for (touch in FlxG.touches.list)
			if (touch != null) return touch;
		return null;
	}

	@:noCompletion
	private static function get_touchCount():Int
		return FlxG.touches.list.length;

	@:noCompletion
	private static function get_hasTouches():Bool
		return FlxG.touches.list.length > 0;
}
