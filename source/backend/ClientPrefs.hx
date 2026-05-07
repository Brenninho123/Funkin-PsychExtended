package backend;

import audio.AudioAPI;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import states.TitleState;

@:structInit class SaveVariables
{
	public var extraButtons:String      = "NONE";
	public var hitboxPos:Bool           = true;
	public var dynamicColors:Bool       = true;
	public var controlsAlpha:Float      = FlxG.onMobile ? 0.6 : 0.0;
	public var screensaver:Bool         = false;
	public var wideScreen:Bool          = false;
	public var hitboxType:String        = "Gradient";
	public var popUpRating:Bool         = true;
	public var vsync:Bool               = false;
	public var gameOverVibration:Bool   = false;

	#if android
	public var storageType:String       = "EXTERNAL_MEDIA";
	#end

	public var downScroll:Bool          = false;
	public var middleScroll:Bool        = false;
	public var opponentStrums:Bool      = true;
	public var showFPS:Bool             = true;
	public var flashing:Bool            = true;
	public var autoPause:Bool           = true;
	public var antialiasing:Bool        = true;
	public var noteSkin:String          = 'Default';
	public var splashSkin:String        = 'Psych';
	public var splashAlpha:Float        = 0.6;
	public var lowQuality:Bool          = false;
	public var shaders:Bool             = true;
	public var cacheOnGPU:Bool          = #if !switch false #else true #end;
	public var framerate:Int            = 60;
	public var camZooms:Bool            = true;
	public var hideHud:Bool             = false;
	public var noteOffset:Int           = 0;

	public var masterVolume:Float       = 1.0;
	public var musicVolume:Float        = 1.0;
	public var sfxVolume:Float          = 1.0;
	public var vocalVolume:Float        = 1.0;
	public var masterMuted:Bool         = false;

	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];

	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
	];

	public var ghostTapping:Bool        = true;
	public var timeBarType:String       = 'Time Left';
	public var scoreZoom:Bool           = true;
	public var noReset:Bool             = false;
	public var healthBarAlpha:Float     = 1.0;
	public var hitsoundVolume:Float     = 0.0;
	public var pauseMusic:String        = 'Tea Time';
	public var checkForUpdates:Bool     = true;
	public var comboStacking:Bool       = true;

	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed'  => 1.0,
		'scrolltype'   => 'multiplicative',
		'songspeed'    => 1.0,
		'healthgain'   => 1.0,
		'healthloss'   => 1.0,
		'instakill'    => false,
		'practice'     => false,
		'botplay'      => false,
		'opponentplay' => false
	];

	public var comboOffset:Array<Int>   = [0, 0, 0, 0];
	public var ratingOffset:Int         = 0;
	public var sickWindow:Int           = 45;
	public var goodWindow:Int           = 90;
	public var badWindow:Int            = 135;
	public var safeFrames:Float         = 10;
	public var guitarHeroSustains:Bool  = true;
	public var discordRPC:Bool          = true;
}

class ClientPrefs
{
	public static var data:SaveVariables        = {};
	public static var defaultData:SaveVariables = {};

	public static var keyBinds:Map<String, Array<FlxKey>> = [
		'note_up'      => [W,         UP],
		'note_left'    => [A,         LEFT],
		'note_down'    => [S,         DOWN],
		'note_right'   => [D,         RIGHT],
		'ui_up'        => [W,         UP],
		'ui_left'      => [A,         LEFT],
		'ui_down'      => [S,         DOWN],
		'ui_right'     => [D,         RIGHT],
		'accept'       => [SPACE,     ENTER],
		'back'         => [BACKSPACE, ESCAPE],
		'pause'        => [ENTER,     ESCAPE],
		'reset'        => [R],
		'volume_mute'  => [ZERO],
		'volume_up'    => [NUMPADPLUS,  PLUS],
		'volume_down'  => [NUMPADMINUS, MINUS],
		'debug_1'      => [SEVEN],
		'debug_2'      => [EIGHT],
		'fullscreen'   => [F11]
	];

	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'    => [DPAD_UP,    Y],
		'note_left'  => [DPAD_LEFT,  X],
		'note_down'  => [DPAD_DOWN,  A],
		'note_right' => [DPAD_RIGHT, B],
		'ui_up'      => [DPAD_UP,    LEFT_STICK_DIGITAL_UP],
		'ui_left'    => [DPAD_LEFT,  LEFT_STICK_DIGITAL_LEFT],
		'ui_down'    => [DPAD_DOWN,  LEFT_STICK_DIGITAL_DOWN],
		'ui_right'   => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		'accept'     => [A,     START],
		'back'       => [B],
		'pause'      => [START],
		'reset'      => [BACK]
	];

	public static var mobileBinds:Map<String, Array<MobileInputID>> = [
		'note_up'    => [NOTE_UP,    UP2],
		'note_left'  => [NOTE_LEFT,  LEFT2],
		'note_down'  => [NOTE_DOWN,  DOWN2],
		'note_right' => [NOTE_RIGHT, RIGHT2],
		'ui_up'      => [UP,   NOTE_UP],
		'ui_left'    => [LEFT, NOTE_LEFT],
		'ui_down'    => [DOWN, NOTE_DOWN],
		'ui_right'   => [RIGHT,NOTE_RIGHT],
		'accept'     => [A],
		'back'       => [B],
		'pause'      => [#if android NONE #else P #end],
		'reset'      => [NONE]
	];

	public static var defaultMobileBinds:Map<String, Array<MobileInputID>>   = null;
	public static var defaultKeys:Map<String, Array<FlxKey>>                 = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>>   = null;

	public static function resetKeys(?controller:Null<Bool> = null):Void
	{
		if (controller != true)
			for (key in keyBinds.keys())
				if (defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());

		if (controller != false)
			for (button in gamepadBinds.keys())
				if (defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
	}

	public static function clearInvalidKeys(key:String):Void
	{
		var kb = keyBinds.get(key);
		var gb = gamepadBinds.get(key);
		var mb = mobileBinds.get(key);
		while (kb != null && kb.contains(NONE))  kb.remove(NONE);
		while (gb != null && gb.contains(NONE))  gb.remove(NONE);
		while (mb != null && mb.contains(NONE))  mb.remove(NONE);
	}

	public static function loadDefaultKeys():Void
	{
		defaultKeys         = keyBinds.copy();
		defaultButtons      = gamepadBinds.copy();
		defaultMobileBinds  = mobileBinds.copy();
	}

	public static function saveSettings():Void
	{
		for (key in Reflect.fields(data))
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

		#if ACHIEVEMENTS_ALLOWED
		Achievements.save();
		#end

		FlxG.save.flush();

		var ctrlSave:FlxSave = new FlxSave();
		ctrlSave.bind('controls_v3', CoolUtil.getSavePath());
		ctrlSave.data.keyboard = keyBinds;
		ctrlSave.data.gamepad  = gamepadBinds;
		ctrlSave.data.mobile   = mobileBinds;
		ctrlSave.flush();

		AudioAPI.savePrefs();
	}

	public static function loadPrefs():Void
	{
		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();
		#end

		for (key in Reflect.fields(data))
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));

		if (Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = data.autoPause;

		if (FlxG.save.data.framerate == null)
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 240));
		}
		#end

		if (data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate   = data.framerate;
		}
		else
		{
			FlxG.drawFramerate   = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		if (FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}

		if (FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute   != null) FlxG.sound.muted  = FlxG.save.data.mute;

		#if DISCORD_ALLOWED
		DiscordClient.check();
		#end

		var ctrlSave:FlxSave = new FlxSave();
		ctrlSave.bind('controls_v3', CoolUtil.getSavePath());

		if (ctrlSave.data.keyboard != null)
		{
			var loaded:Map<String, Array<FlxKey>> = ctrlSave.data.keyboard;
			for (ctrl => keys in loaded)
				if (keyBinds.exists(ctrl)) keyBinds.set(ctrl, keys);
		}

		if (ctrlSave.data.gamepad != null)
		{
			var loaded:Map<String, Array<FlxGamepadInputID>> = ctrlSave.data.gamepad;
			for (ctrl => keys in loaded)
				if (gamepadBinds.exists(ctrl)) gamepadBinds.set(ctrl, keys);
		}

		if (ctrlSave.data.mobile != null)
		{
			var loaded:Map<String, Array<MobileInputID>> = ctrlSave.data.mobile;
			for (ctrl => keys in loaded)
				if (mobileBinds.exists(ctrl)) mobileBinds.set(ctrl, keys);
		}

		reloadVolumeKeys();
		AudioAPI.loadPrefs();
	}

	inline public static function getGameplaySetting(name:String, ?defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if (!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue;
	}

	public static function reloadVolumeKeys():Void
	{
		TitleState.muteKeys       = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys   = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?turnOn:Bool = true):Void
	{
		var empty:Array<FlxKey> = [];
		var active = !Controls.instance.mobileC && turnOn;
		FlxG.sound.muteKeys       = active ? TitleState.muteKeys       : empty;
		FlxG.sound.volumeDownKeys = active ? TitleState.volumeDownKeys : empty;
		FlxG.sound.volumeUpKeys   = active ? TitleState.volumeUpKeys   : empty;
	}
}
