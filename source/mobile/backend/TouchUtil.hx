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

	private static var _lastTouchID:Int = -1;
	private static var _tapCooldown:Float = 0;
	private static inline var TAP_DELAY:Float = 0.08;

	public static function update(elapsed:Float):Void
	{
		if (_tapCooldown > 0)
			_tapCooldown -= elapsed;
	}

	public static function overlaps(object:FlxObject, ?camera:FlxCamera):Bool
	{
		if (object == null)
			return false;

		var cam = camera != null ? camera : object.camera;

		for (touch in FlxG.touches.list)
		{
			if (touch == null)
				continue;

			if (touch.overlaps(object, cam))
				return true;
		}

		return false;
	}

	public static function overlapsComplex(object:FlxObject, ?camera:FlxCamera):Bool
	{
		if (object == null)
			return false;

		var point = FlxPoint.get();

		if (camera == null)
		{
			for (cam in object.cameras)
			{
				for (touch in FlxG.touches.list)
				{
					if (touch == null)
						continue;

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
				if (touch == null)
					continue;

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

	public static function overlapsOnce(object:FlxObject, ?camera:FlxCamera):Bool
	{
		if (_tapCooldown > 0)
			return false;

		var cam = camera != null ? camera : object.camera;

		for (touch in FlxG.touches.list)
		{
			if (touch == null)
				continue;

			if (touch.justPressed && touch.overlaps(object, cam))
			{
				_lastTouchID = touch.touchPointID;
				_tapCooldown = TAP_DELAY;
				return true;
			}
		}

		return false;
	}

	public static function getTouchesOn(object:FlxObject, ?camera:FlxCamera):Array<FlxTouch>
	{
		var result:Array<FlxTouch> = [];

		if (object == null)
			return result;

		var cam = camera != null ? camera : object.camera;

		for (touch in FlxG.touches.list)
		{
			if (touch == null)
				continue;

			if (touch.overlaps(object, cam))
				result.push(touch);
		}

		return result;
	}

	public static function getPinchDistance():Float
	{
		var valid:Array<FlxTouch> = [];

		for (touch in FlxG.touches.list)
		{
			if (touch != null && touch.pressed)
				valid.push(touch);
		}

		if (valid.length < 2)
			return 0;

		var t1 = valid[0];
		var t2 = valid[1];

		var dx = t1.screenX - t2.screenX;
		var dy = t1.screenY - t2.screenY;

		return Math.sqrt(dx * dx + dy * dy);
	}

	public static function getCentroid():FlxPoint
	{
		var sx:Float = 0;
		var sy:Float = 0;
		var count:Int = 0;

		for (touch in FlxG.touches.list)
		{
			if (touch == null)
				continue;

			sx += touch.screenX;
			sy += touch.screenY;
			count++;
		}

		if (count == 0)
			return FlxPoint.get(0, 0);

		return FlxPoint.get(sx / count, sy / count);
	}

	@:noCompletion
	private static function get_pressed():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch != null && touch.pressed)
				return true;
		}

		return false;
	}

	@:noCompletion
	private static function get_justPressed():Bool
	{
		if (_tapCooldown > 0)
			return false;

		for (touch in FlxG.touches.list)
		{
			if (touch == null)
				continue;

			if (touch.justPressed)
			{
				if (_lastTouchID == touch.touchPointID)
					return false;

				_lastTouchID = touch.touchPointID;
				_tapCooldown = TAP_DELAY;

				return true;
			}
		}

		return false;
	}

	@:noCompletion
	private static function get_justReleased():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch != null && touch.justReleased)
				return true;
		}

		return false;
	}

	@:noCompletion
	private static function get_released():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch != null && touch.released)
				return true;
		}

		return false;
	}

	@:noCompletion
	private static function get_touch():Null<FlxTouch>
	{
		for (touch in FlxG.touches.list)
		{
			if (touch != null)
				return touch;
		}

		return null;
	}

	@:noCompletion
	private static function get_touchCount():Int
	{
		var count:Int = 0;

		for (touch in FlxG.touches.list)
		{
			if (touch != null)
				count++;
		}

		return count;
	}

	@:noCompletion
	private static function get_hasTouches():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch != null)
				return true;
		}

		return false;
	}
}
