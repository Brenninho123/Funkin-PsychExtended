package options;

import states.MainMenuState;
import backend.StageData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import mobile.substates.MobileControlSelectSubState;

#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals and UI',
		'Gameplay',
		#if mobile
		'Mobile Options'
		#end
	];

	var optionColors:Array<Int> = [
		0xFF4FC3F7,
		0xFFF48FB1,
		0xFF81C784,
		0xFF80DEEA,
		0xFFCE93D8,
		0xFFFFCC02,
		0xFFFF7043
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var onPlayState:Bool  = false;

	var bg:FlxSprite;
	var bgGrid:FlxSprite;
	var vignette:FlxSprite;
	var scanline:FlxSprite;
	var scanline2:FlxSprite;
	var bgShine:FlxSprite;

	var topBar:FlxSprite;
	var topAccent:FlxSprite;
	var bottomBar:FlxSprite;
	var sideAccent:FlxSprite;

	var titleText:FlxText;
	var titleGlow:FlxText;
	var tipText:FlxText;

	var selectedCard:FlxSprite;
	var selectedGlow:FlxSprite;
	var cardTag:FlxSprite;

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var scanlineY:Float  = 0;
	var scanline2Y:Float = 240;
	var shineX:Float     = -120;
	var glowTimer:Float  = 0;

	var entering:Bool = true;
	var exiting:Bool  = false;

	#if (target.threaded)
	var mutex:Mutex = new Mutex();
	#end

	function openSelectedSubstate(label:String):Void
	{
		if (exiting || entering) return;
		persistentUpdate = false;

		if (label != 'Adjust Delay and Combo')
		{
			#if mobile
			removeTouchPad();
			#end
		}

		switch (label)
		{
			case 'Note Colors':            openSubState(new options.NotesSubState());
			case 'Controls':               openSubState(new options.ControlsSubState());
			case 'Graphics':               openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':         openSubState(new options.VisualsUISubState());
			case 'Gameplay':               openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo': MusicBeatState.switchState(new options.NoteOffsetState());
			#if mobile
			case 'Mobile Options':         openSubState(new mobile.options.MobileOptionsSubState());
			#end
		}
	}

	override function create():Void
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Options Menu', null);
		#end

		_buildBG();
		_buildUI();
		_buildOptions();

		changeSelection(0, false);

		ClientPrefs.saveSettings();

		#if mobile
		addTouchPad('UP_DOWN', 'A_B_C');
		#end

		#if (target.threaded)
		Thread.create(function()
		{
			mutex.acquire();
			for (i in VisualsUISubState.pauseMusics)
				if (i.toLowerCase() != 'none')
					Paths.music(Paths.formatToSongPath(i));
			mutex.release();
		});
		#end

		super.create();
		_playEnterAnim();
	}

	function _buildBG():Void
	{
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color  = 0xFF888888;
		bg.alpha  = 0;
		bg.scale.set(1.06, 1.06);
		bg.screenCenter();
		add(bg);

		bgGrid = FlxGridOverlay.create(30, 30, FlxG.width, FlxG.height, true, 0x07FFFFFF, 0x00000000);
		bgGrid.scrollFactor.set();
		bgGrid.alpha = 0;
		add(bgGrid);

		vignette = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		vignette.scrollFactor.set();
		vignette.alpha = 0.45;
		add(vignette);

		scanline = new FlxSprite(0, 0).makeGraphic(FlxG.width, 3, 0x12FFFFFF);
		scanline.scrollFactor.set();
		add(scanline);

		scanline2 = new FlxSprite(0, 240).makeGraphic(FlxG.width, 2, 0x08FFFFFF);
		scanline2.scrollFactor.set();
		add(scanline2);

		bgShine = new FlxSprite(-120, 0).makeGraphic(80, FlxG.height, 0x0EFFFFFF);
		bgShine.scrollFactor.set();
		add(bgShine);

		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 52, 0xEE0A0A18);
		topBar.scrollFactor.set();
		topBar.y = -52;
		add(topBar);

		topAccent = new FlxSprite(0, 52).makeGraphic(FlxG.width, 3, 0xFF4FC3F7);
		topAccent.scrollFactor.set();
		topAccent.y = -3;
		add(topAccent);

		sideAccent = new FlxSprite(0, 55).makeGraphic(3, FlxG.height - 87, 0xFF4FC3F7);
		sideAccent.scrollFactor.set();
		sideAccent.x = -3;
		add(sideAccent);

		bottomBar = new FlxSprite(0, FlxG.height - 36).makeGraphic(FlxG.width, 36, 0xEE0A0A18);
		bottomBar.scrollFactor.set();
		bottomBar.y = FlxG.height;
		add(bottomBar);
	}

	function _buildUI():Void
	{
		selectedGlow = new FlxSprite(55, 200).makeGraphic(FlxG.width - 110, 66, 0x22FFFFFF);
		selectedGlow.scrollFactor.set();
		selectedGlow.alpha = 0;
		add(selectedGlow);

		selectedCard = new FlxSprite(62, 202).makeGraphic(FlxG.width - 124, 58, 0xFF14213D);
		selectedCard.scrollFactor.set();
		selectedCard.alpha = 0;
		add(selectedCard);

		cardTag = new FlxSprite(62, 202).makeGraphic(4, 58, 0xFF4FC3F7);
		cardTag.scrollFactor.set();
		cardTag.alpha = 0;
		add(cardTag);

		titleGlow = new FlxText(12, 13, 0, 'OPTIONS', 22);
		titleGlow.setFormat('VCR OSD Mono', 22, 0xFF4FC3F7, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF4FC3F7);
		titleGlow.borderSize = 5;
		titleGlow.scrollFactor.set();
		titleGlow.alpha = 0;
		titleGlow.y    = -50;
		add(titleGlow);

		titleText = new FlxText(12, 14, 0, 'OPTIONS', 22);
		titleText.setFormat('VCR OSD Mono', 22, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		titleText.scrollFactor.set();
		titleText.alpha = 0;
		titleText.y    = -50;
		add(titleText);

		if (controls.mobileC)
		{
			tipText = new FlxText(0, FlxG.height - 28, FlxG.width,
				'Press ' + #if mobile 'C' #else 'CTRL or C' #end + ' to open Mobile Controls', 13);
			tipText.setFormat('VCR OSD Mono', 13, 0xFF78909C, CENTER);
			tipText.scrollFactor.set();
			add(tipText);
		}
	}

	function _buildOptions():Void
	{
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			optionText.alpha = 0;
			optionText.x    = -FlxG.width;
			grpOptions.add(optionText);
		}

		selectorLeft  = new Alphabet(0, 0, '>', true);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorLeft);
		add(selectorRight);
	}

	function _playEnterAnim():Void
	{
		FlxTween.tween(bg,        {alpha: 0.72, 'scale.x': 1.0, 'scale.y': 1.0}, 0.7, {ease: FlxEase.quadOut});
		FlxTween.tween(bgGrid,    {alpha: 1},   0.9, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(topBar,    {y: 0},       0.45,{ease: FlxEase.expoOut});
		FlxTween.tween(topAccent, {y: 52},      0.45,{ease: FlxEase.expoOut, startDelay: 0.03});
		FlxTween.tween(sideAccent,{x: 0},       0.4, {ease: FlxEase.expoOut, startDelay: 0.08});
		FlxTween.tween(bottomBar, {y: FlxG.height - 36}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.05});
		FlxTween.tween(titleGlow, {y: 13, alpha: 0.15}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.12});
		FlxTween.tween(titleText, {y: 14, alpha: 1},    0.5, {ease: FlxEase.expoOut, startDelay: 0.14});
		FlxTween.tween(selectedCard, {alpha: 0.85}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(selectedGlow, {alpha: 0.3},  0.4, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(cardTag,      {alpha: 1.0},  0.4, {ease: FlxEase.quadOut, startDelay: 0.22});

		for (i in 0...grpOptions.members.length)
		{
			var item  = grpOptions.members[i];
			var delay = 0.1 + i * 0.065;
			FlxTween.tween(item, {alpha: 0.55, x: 0}, 0.5, {
				ease: FlxEase.expoOut,
				startDelay: delay,
				onComplete: function(_)
				{
					item.screenCenter(X);
					if (i == grpOptions.members.length - 1)
						entering = false;
				}
			});
		}
	}

	function _playExitAnim(onDone:Void->Void):Void
	{
		FlxTween.tween(bg,        {alpha: 0},  0.4, {ease: FlxEase.quadIn});
		FlxTween.tween(bgGrid,    {alpha: 0},  0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(topBar,    {y: -52},    0.4, {ease: FlxEase.expoIn});
		FlxTween.tween(topAccent, {y: -3},     0.4, {ease: FlxEase.expoIn});
		FlxTween.tween(sideAccent,{x: -3},     0.35,{ease: FlxEase.expoIn});
		FlxTween.tween(bottomBar, {y: FlxG.height}, 0.35, {ease: FlxEase.expoIn});
		FlxTween.tween(titleText, {y: -50, alpha: 0}, 0.3, {ease: FlxEase.expoIn});
		FlxTween.tween(selectedCard,{alpha: 0}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(selectedGlow,{alpha: 0}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(cardTag,     {alpha: 0}, 0.3, {ease: FlxEase.quadIn});

		for (i in 0...grpOptions.members.length)
		{
			var item = grpOptions.members[i];
			FlxTween.tween(item, {alpha: 0, x: item.x + 250}, 0.28, {
				ease: FlxEase.expoIn,
				startDelay: i * 0.02
			});
		}

		new FlxTimer().start(0.45, function(_) { onDone(); });
	}

	override function closeSubState():Void
	{
		super.closeSubState();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Options Menu', null);
		#end

		ClientPrefs.saveSettings();
		ClientPrefs.loadPrefs();
		controls.isInSubstate = false;
		persistentUpdate = true;

		#if mobile
		removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B_C');
		#end
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		_animateScanlines(elapsed);
		_animateShine(elapsed);
		_animateGlow(elapsed);

		if (entering || exiting) return;

		if (controls.UI_UP_P)   changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		#if mobile
		if (touchPad.buttonC.justPressed || (FlxG.keys.justPressed.CONTROL && controls.mobileC))
		{
			persistentUpdate = false;
			openSubState(new MobileControlSelectSubState());
		}
		#end

		if (controls.BACK)
		{
			exiting = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));

			_playExitAnim(function()
			{
				if (onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else
					MusicBeatState.switchState(new MainMenuState());
			});
		}
		else if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			openSelectedSubstate(options[curSelected]);
		}
	}

	function changeSelection(change:Int = 0, ?playSound:Bool = true):Void
	{
		curSelected += change;
		if (curSelected < 0)              curSelected = options.length - 1;
		if (curSelected >= options.length) curSelected = 0;

		if (playSound && change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		var col = FlxColor.fromInt(optionColors[curSelected % optionColors.length]);

		var bullShit:Int = 0;
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			var isSel = (item.targetY == 0);
			FlxTween.cancelTweensOf(item, ['alpha']);
			FlxTween.tween(item, {alpha: isSel ? 1.0 : 0.45}, 0.15, {ease: FlxEase.quadOut});

			if (isSel)
			{
				selectorLeft.x  = item.x - 63;
				selectorLeft.y  = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;

				selectedCard.y = item.y - 4;
				selectedGlow.y = item.y - 8;
				cardTag.y      = item.y - 4;
			}
		}

		FlxTween.cancelTweensOf(topAccent,    ['color']);
		FlxTween.cancelTweensOf(sideAccent,   ['color']);
		FlxTween.cancelTweensOf(cardTag,      ['color']);
		FlxTween.cancelTweensOf(selectedCard, ['color']);
		FlxTween.cancelTweensOf(selectedGlow, ['color']);

		FlxTween.color(topAccent,    0.3,  topAccent.color,    col);
		FlxTween.color(sideAccent,   0.3,  sideAccent.color,   col);
		FlxTween.color(cardTag,      0.25, cardTag.color,       col);
		FlxTween.color(selectedCard, 0.25, selectedCard.color,  col.getDarkened(0.78));
		FlxTween.color(selectedGlow, 0.25, selectedGlow.color,  col.getDarkened(0.55));
	}

	function _animateScanlines(elapsed:Float):Void
	{
		scanlineY  += 88 * elapsed;
		scanline2Y += 48 * elapsed;
		if (scanlineY  > FlxG.height) scanlineY  = -3;
		if (scanline2Y > FlxG.height) scanline2Y = -2;
		scanline.y  = scanlineY;
		scanline2.y = scanline2Y;
	}

	function _animateShine(elapsed:Float):Void
	{
		shineX += 145 * elapsed;
		if (shineX > FlxG.width + 80) shineX = -120;
		bgShine.x = shineX;
	}

	function _animateGlow(elapsed:Float):Void
	{
		glowTimer += elapsed;
		var pulse = (Math.sin(glowTimer * 2.0) + 1) / 2;
		if (sideAccent != null) sideAccent.alpha = 0.5 + pulse * 0.5;
		if (titleGlow  != null) titleGlow.alpha  = 0.06 + pulse * 0.12;
	}

	override function destroy():Void
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
