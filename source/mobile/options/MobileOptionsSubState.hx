package mobile.options;

import mobile.backend.MobileScaleMode;
import mobile.backend.StorageUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import options.BaseOptionsMenu;
import options.Option;

class MobileOptionsSubState extends BaseOptionsMenu
{
	#if android
	var storageTypes:Array<String>  = ["EXTERNAL_DATA", "EXTERNAL_OBB", "EXTERNAL_MEDIA", "EXTERNAL"];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	final lastStorageType:String    = ClientPrefs.data.storageType;
	#end

	final exControlTypes:Array<String> = ["NONE", "SINGLE", "DOUBLE"];
	final hintOptions:Array<String>    = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];

	var topBar:FlxSprite;
	var accentLine:FlxSprite;
	var bottomBar:FlxSprite;
	var titleLabel:FlxText;
	var scanline:FlxSprite;
	var scanlineY:Float = 0;

	var option:Option;

	public function new()
	{
		#if android
		if (!externalPaths.contains('\n'))
			storageTypes = storageTypes.concat(externalPaths);
		#end

		title    = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu';

		option = new Option('Extra Controls',
			'How many extra buttons do you want?\nUseful for Lua/HScript mechanics.',
			'extraButtons', 'string', exControlTypes);
		addOption(option);

		option = new Option('Controls Opacity',
			'Adjust the opacity of mobile buttons.\nDon\'t set it to 0 or you\'ll lose them!',
			'controlsAlpha', 'percent');
		option.scrollSpeed = 1;
		option.minValue    = 0.001;
		option.maxValue    = 1;
		option.changeValue = 0.1;
		option.decimals    = 1;
		option.onChange    = function()
		{
			if (touchPad != null) touchPad.alpha = curOption.getValue();
			ClientPrefs.toggleVolumeKeys();
		};
		addOption(option);

		#if mobile
		option = new Option('Allow Screensaver',
			'Let your phone sleep when inactive.\n(Timeout depends on phone settings)',
			'screensaver', 'bool');
		option.onChange = function()
		{
			lime.system.System.allowScreenTimeout = curOption.getValue();
		};
		addOption(option);

		option = new Option('Wide Screen Mode',
			'Stretch the game to fill your whole screen.\nWarning: may break mods that resize cameras.',
			'wideScreen', 'bool');
		option.onChange = function()
		{
			FlxG.scaleMode = new MobileScaleMode();
		};
		addOption(option);
		#end

		if (MobileData.mode == 3)
		{
			option = new Option('Hitbox Design',
				'Choose how your hitbox should look.',
				'hitboxType', 'string', hintOptions);
			addOption(option);

			option = new Option('Hitbox Position',
				'Checked = hitbox at bottom.\nUnchecked = hitbox at top.',
				'hitboxPos', 'bool');
			addOption(option);
		}

		option = new Option('Dynamic Controls Color',
			'Tint mobile controls to match your note colors.\n(Only visible during gameplay)',
			'dynamicColors', 'bool');
		addOption(option);

		#if android
		option = new Option('Storage Type',
			'Which folder should the game use?\nWarning: changing this will delete the old folder!',
			'storageType', 'string', storageTypes);
		addOption(option);
		#end

		super();
	}

	override function create()
	{
		super.create();
		_buildDecor();
		_playEnterAnim();
	}

	function _buildDecor()
	{
		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 50, 0xDD0D0D1A);
		topBar.scrollFactor.set();
		topBar.y = -50;
		add(topBar);

		accentLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 3, 0xFF00D4FF);
		accentLine.scrollFactor.set();
		accentLine.y = -3;
		add(accentLine);

		bottomBar = new FlxSprite(0, FlxG.height - 28).makeGraphic(FlxG.width, 28, 0xDD0D0D1A);
		bottomBar.scrollFactor.set();
		bottomBar.y = FlxG.height;
		add(bottomBar);

		titleLabel = new FlxText(12, 14, 0, 'MOBILE OPTIONS', 16);
		titleLabel.setFormat('VCR OSD Mono', 16, 0xFF00D4FF, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleLabel.borderSize = 1.5;
		titleLabel.scrollFactor.set();
		titleLabel.alpha = 0;
		titleLabel.y = -30;
		add(titleLabel);

		scanline = new FlxSprite(0, 0).makeGraphic(FlxG.width, 3, 0x0CFFFFFF);
		scanline.scrollFactor.set();
		add(scanline);
	}

	function _playEnterAnim()
	{
		FlxTween.tween(topBar,     {y: 0},                  0.45, {ease: FlxEase.expoOut});
		FlxTween.tween(accentLine, {y: 50},                 0.45, {ease: FlxEase.expoOut, startDelay: 0.04});
		FlxTween.tween(bottomBar,  {y: FlxG.height - 28},   0.45, {ease: FlxEase.expoOut, startDelay: 0.04});
		FlxTween.tween(titleLabel, {y: 14, alpha: 1},        0.45, {ease: FlxEase.expoOut, startDelay: 0.1});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_animateScanline(elapsed);
		_animateAccent(elapsed);
	}

	function _animateScanline(elapsed:Float)
	{
		scanlineY += 80 * elapsed;
		if (scanlineY > FlxG.height) scanlineY = -3;
		if (scanline != null) scanline.y = scanlineY;
	}

	function _animateAccent(elapsed:Float)
	{
		if (accentLine == null) return;
		var pulse = (Math.sin(haxe.Timer.stamp() * 2) + 1) / 2;
		accentLine.alpha = 0.7 + pulse * 0.3;
	}

	#if android
	function onStorageChange():Void
	{
		StorageUtil.changeStorageType(ClientPrefs.data.storageType);

		var lastPath = StorageType.fromStrForce(lastStorageType) + '/';
		try
		{
			if (ClientPrefs.data.storageType != "EXTERNAL")
				Sys.command('rm', ['-rf', lastPath]);
		}
		catch (e:haxe.Exception)
			trace('MobileOptionsSubState: failed to remove old directory — ${e.message}');
	}
	#end

	override public function destroy()
	{
		#if android
		if (ClientPrefs.data.storageType != lastStorageType)
		{
			onStorageChange();
			CoolUtil.showPopUp(
				'Storage type changed!\nThe game needs to restart now.\nPress OK to close.',
				'Notice!'
			);
			lime.system.System.exit(0);
			return;
		}
		#end

		super.destroy();
	}
}
