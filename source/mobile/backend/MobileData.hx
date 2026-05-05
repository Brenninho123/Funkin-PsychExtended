package mobile.backend;

import haxe.Json;
import haxe.io.Path;
import openfl.utils.Assets;
import flixel.math.FlxPoint;
import flixel.util.FlxSave;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

class MobileData
{
	public static var actionModes:Map<String, TouchButtonsData> = new Map();
	public static var dpadModes:Map<String, TouchButtonsData>   = new Map();
	public static var extraActions:Map<String, ExtraActions>    = new Map();

	public static var forcedMode:Null<Int> = null;
	public static var save:FlxSave;

	public static var mode(get, set):Int;

	public static function init():Void
	{
		save = new FlxSave();
		save.bind('MobileControls', CoolUtil.getSavePath());

		readDirectory(Paths.getSharedPath('mobile/DPadModes'),    dpadModes);
		readDirectory(Paths.getSharedPath('mobile/ActionModes'),  actionModes);

		#if MODS_ALLOWED
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'mobile/'))
		{
			readDirectory(Path.join([folder, 'DPadModes']),   dpadModes);
			readDirectory(Path.join([folder, 'ActionModes']), actionModes);
		}
		#end

		for (data in ExtraActions.createAll())
			extraActions.set(data.getName(), data);
	}

	public static function setTouchPadCustom(touchPad:TouchPad):Void
	{
		if (save.data.buttons == null)
			save.data.buttons = new Array();

		var i:Int = 0;
		for (button in touchPad)
		{
			save.data.buttons[i] = FlxPoint.get(button.x, button.y);
			i++;
		}

		save.flush();
	}

	public static function getTouchPadCustom(touchPad:TouchPad):TouchPad
	{
		if (save.data.buttons == null)
			return touchPad;

		var i:Int = 0;
		for (button in touchPad)
		{
			var saved = save.data.buttons[i];
			if (saved != null)
			{
				button.x = saved.x;
				button.y = saved.y;
			}
			i++;
		}

		return touchPad;
	}

	public static function setButtonsColors(buttonsInstance:Dynamic):Dynamic
	{
		var data:Dynamic = ClientPrefs.data.dynamicColors ? ClientPrefs.data : ClientPrefs.defaultData;

		var noteButtons:Array<Dynamic> = [
			buttonsInstance.buttonLeft,
			buttonsInstance.buttonDown,
			buttonsInstance.buttonUp,
			buttonsInstance.buttonRight
		];

		for (i in 0...noteButtons.length)
		{
			var btn = noteButtons[i];
			if (btn == null) continue;

			var color:Int = data.arrowRGB[i][0];
			btn.color = color;

			if (btn.label != null)
			{
				btn.label.color = color;
				btn.label.updateColorTransform();
			}
		}

		return buttonsInstance;
	}

	public static function readDirectory(folder:String, map:Map<String, TouchButtonsData>):Void
	{
		folder = folder.contains(':') ? folder.split(':')[1] : folder;

		#if MODS_ALLOWED
		if (!FileSystem.exists(folder)) return;
		#end

		for (file in Paths.readDirectory(folder))
		{
			var filePath     = file.contains(':') ? file.split(':')[1] : file;
			var fullPath     = Path.join([folder, Path.withoutDirectory(file)]);
			var ext          = Path.extension(filePath);
			var key          = Path.withoutExtension(Path.withoutDirectory(filePath));

			if (ext != 'json') continue;

			var content:String =
				#if MODS_ALLOWED
				File.getContent(fullPath);
				#else
				Assets.getText(fullPath);
				#end

			if (content == null || content.length == 0) continue;

			try
			{
				var parsed:TouchButtonsData = cast Json.parse(content);
				map.set(key, parsed);
			}
			catch (e)
			{
				trace('MobileData: failed to parse $fullPath — $e');
			}
		}
	}

	public static function reset():Void
	{
		if (save != null)
		{
			save.data.mobileControlsMode = 3;
			save.data.buttons = null;
			save.flush();
		}
	}

	static function set_mode(value:Int):Int
	{
		if (save != null)
		{
			save.data.mobileControlsMode = value;
			save.flush();
		}
		return value;
	}

	static function get_mode():Int
	{
		if (forcedMode != null)
			return forcedMode;

		if (save == null)
			return 3;

		if (save.data.mobileControlsMode == null)
		{
			save.data.mobileControlsMode = 3;
			save.flush();
		}

		return save.data.mobileControlsMode;
	}
}

typedef TouchButtonsData =
{
	buttons:Array<ButtonsData>
}

typedef ButtonsData =
{
	var button:String;
	var graphic:String;
	var x:Float;
	var y:Float;
	var color:String;
}

enum ExtraActions
{
	SINGLE;
	DOUBLE;
	NONE;
}
