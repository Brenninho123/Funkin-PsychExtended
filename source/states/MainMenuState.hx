package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import states.school.SchoolState;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3';
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED
		'mods',
		#end
		#if ACHIEVEMENTS_ALLOWED
		'awards',
		#end
		'credits',
		'school',
		#if !switch
		'donate',
		#end
		'options'
	];

	var optionColors:Array<Int> = [
		0xFF4FC3F7,
		0xFFF48FB1,
		0xFF81C784,
		0xFFCE93D8,
		0xFF80DEEA,
		0xFFFFCC02,
		0xFFFF7043,
		0xFFB39DDB,
	];

	var bg:FlxSprite;
	var bgGrid:FlxSprite;
	var bgGlow:FlxSprite;
	var magenta:FlxSprite;
	var vignette:FlxSprite;

	var scanline:FlxSprite;
	var scanline2:FlxSprite;
	var scanline3:FlxSprite;
	var bgShine:FlxSprite;
	var bgShine2:FlxSprite;

	var bottomBar:FlxSprite;
	var bottomBarShine:FlxSprite;
	var sideAccent:FlxSprite;
	var sideAccent2:FlxSprite;
	var topBar:FlxSprite;
	var topAccent:FlxSprite;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var versionText:FlxText;
	var engineText:FlxText;
	var menuLabel:FlxText;
	var menuLabelGlow:FlxText;
	var counterText:FlxText;

	var selectedCard:FlxSprite;
	var selectedGlow:FlxSprite;
	var selectedGlow2:FlxSprite;
	var cardTag:FlxSprite;

	var particles:FlxTypedGroup<FlxSprite>;
	var particleSpeeds:Array<Float> = [];
	var particleTimer:Float = 0;

	var scanlineY:Float  = 0;
	var scanline2Y:Float = 240;
	var scanline3Y:Float = 480;
	var shineX:Float     = -200;
	var shine2X:Float    = -500;
	var glowTimer:Float  = 0;
	var titlePulse:Bool  = true;
	var accentShineX:Float = -60;

	var selectedSomethin:Bool = false;
	var entering:Bool = true;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn  = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;
		persistentUpdate = persistentDraw = true;

		_buildBG();
		_buildCards();
		_buildParticles();
		_buildMenuItems();
		_buildHUD();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');
		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if mobile
		addTouchPad("UP_DOWN", "A_B_E");
		#end

		super.create();

		FlxG.camera.follow(camFollowPos, null, 9);

		_playEnterAnim();
	}

	function _buildBG()
	{
		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0;
		bg.scale.set(1.06, 1.06);
		add(bg);

		bgGrid = FlxGridOverlay.create(32, 32, FlxG.width, FlxG.height, true, 0x06FFFFFF, 0x00000000);
		bgGrid.scrollFactor.set();
		bgGrid.alpha = 0;
		add(bgGrid);

		bgGlow = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF4FC3F7);
		bgGlow.scrollFactor.set();
		bgGlow.alpha = 0;
		add(bgGlow);

		camFollow    = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		vignette = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		vignette.scrollFactor.set();
		vignette.alpha = 0.4;
		add(vignette);

		scanline = new FlxSprite(0, 0).makeGraphic(FlxG.width, 3, 0x12FFFFFF);
		scanline.scrollFactor.set();
		add(scanline);

		scanline2 = new FlxSprite(0, 240).makeGraphic(FlxG.width, 2, 0x08FFFFFF);
		scanline2.scrollFactor.set();
		add(scanline2);

		scanline3 = new FlxSprite(0, 480).makeGraphic(FlxG.width, 1, 0x05FFFFFF);
		scanline3.scrollFactor.set();
		add(scanline3);

		bgShine = new FlxSprite(-200, 0).makeGraphic(90, FlxG.height, 0x0EFFFFFF);
		bgShine.scrollFactor.set();
		add(bgShine);

		bgShine2 = new FlxSprite(-500, 0).makeGraphic(40, FlxG.height, 0x07FFFFFF);
		bgShine2.scrollFactor.set();
		add(bgShine2);

		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 48, 0xDD0D0D1A);
		topBar.scrollFactor.set();
		topBar.y = -48;
		add(topBar);

		topAccent = new FlxSprite(0, 48).makeGraphic(FlxG.width, 3, 0xFF4FC3F7);
		topAccent.scrollFactor.set();
		topAccent.y = -3;
		add(topAccent);

		sideAccent = new FlxSprite(0, 51).makeGraphic(3, FlxG.height - 83, 0xFF4FC3F7);
		sideAccent.scrollFactor.set();
		sideAccent.x = -3;
		add(sideAccent);

		sideAccent2 = new FlxSprite(FlxG.width - 3, 51).makeGraphic(3, FlxG.height - 83, 0xFF4FC3F7);
		sideAccent2.scrollFactor.set();
		sideAccent2.alpha = 0.3;
		sideAccent2.x = FlxG.width;
		add(sideAccent2);

		bottomBar = new FlxSprite(0, FlxG.height - 34).makeGraphic(FlxG.width, 34, 0xDD0D0D1A);
		bottomBar.scrollFactor.set();
		bottomBar.y = FlxG.height;
		add(bottomBar);

		bottomBarShine = new FlxSprite(0, FlxG.height - 35).makeGraphic(FlxG.width, 1, 0x22FFFFFF);
		bottomBarShine.scrollFactor.set();
		add(bottomBarShine);
	}

	function _buildCards()
	{
		selectedGlow2 = new FlxSprite(52, 0).makeGraphic(FlxG.width - 104, 66, 0x11FFFFFF);
		selectedGlow2.scrollFactor.set();
		selectedGlow2.alpha = 0;
		add(selectedGlow2);

		selectedGlow = new FlxSprite(57, 0).makeGraphic(FlxG.width - 114, 60, 0x22FFFFFF);
		selectedGlow.scrollFactor.set();
		selectedGlow.alpha = 0;
		add(selectedGlow);

		selectedCard = new FlxSprite(64, 0).makeGraphic(FlxG.width - 128, 54, 0xFF14213D);
		selectedCard.scrollFactor.set();
		selectedCard.alpha = 0;
		add(selectedCard);

		cardTag = new FlxSprite(64, 0).makeGraphic(4, 54, 0xFF4FC3F7);
		cardTag.scrollFactor.set();
		cardTag.alpha = 0;
		add(cardTag);
	}

	function _buildParticles()
	{
		particles = new FlxTypedGroup<FlxSprite>();
		add(particles);

		for (i in 0...16)
		{
			var size = FlxG.random.int(1, 4);
			var p    = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			p.makeGraphic(size, size, 0x28FFFFFF);
			p.scrollFactor.set();
			p.alpha = 0;
			particles.add(p);
			particleSpeeds.push(FlxG.random.float(0.2, 1.0));
		}
	}

	function _buildMenuItems()
	{
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem = new FlxSprite(0, (i * 140) + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle',     optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.scrollFactor.set(0, optionShit.length < 6 ? 0 : (optionShit.length - 4) * 0.135);
			menuItem.updateHitbox();
			menuItem.screenCenter(X);
			menuItem.alpha = 0;
			menuItem.x    = -FlxG.width;
			menuItems.add(menuItem);
		}
	}

	function _buildHUD()
	{
		menuLabelGlow = new FlxText(12, 12, 0, 'MENU', 22);
		menuLabelGlow.setFormat('VCR OSD Mono', 22, 0xFF4FC3F7, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF4FC3F7);
		menuLabelGlow.borderSize = 5;
		menuLabelGlow.scrollFactor.set();
		menuLabelGlow.alpha = 0;
		menuLabelGlow.y = -40;
		add(menuLabelGlow);

		menuLabel = new FlxText(12, 13, 0, 'MENU', 22);
		menuLabel.setFormat('VCR OSD Mono', 22, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		menuLabel.borderSize = 2;
		menuLabel.scrollFactor.set();
		menuLabel.alpha = 0;
		menuLabel.y = -40;
		add(menuLabel);

		counterText = new FlxText(FlxG.width - 120, 16, 110, '', 13);
		counterText.setFormat('VCR OSD Mono', 13, 0xFF546E7A, RIGHT);
		counterText.scrollFactor.set();
		counterText.alpha = 0;
		add(counterText);

		engineText = new FlxText(12, FlxG.height - 27, 0, 'Psych Extended v$psychEngineVersion', 12);
		engineText.scrollFactor.set();
		engineText.setFormat('VCR OSD Mono', 12, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		engineText.borderSize = 1.5;
		engineText.alpha = 0;
		add(engineText);

		versionText = new FlxText(FlxG.width - 12, FlxG.height - 27, 0, 'v' + Application.current.meta.get('version'), 12);
		versionText.scrollFactor.set();
		versionText.setFormat('VCR OSD Mono', 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionText.borderSize = 1.5;
		versionText.x -= versionText.width;
		versionText.alpha = 0;
		add(versionText);
	}

	function _playEnterAnim()
	{
		FlxTween.tween(bg,         {alpha: 0.8, 'scale.x': 1.0, 'scale.y': 1.0}, 0.7, {ease: FlxEase.quadOut});
		FlxTween.tween(bgGrid,     {alpha: 1},   0.9, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(topBar,     {y: 0},       0.45,{ease: FlxEase.expoOut});
		FlxTween.tween(topAccent,  {y: 48},      0.45,{ease: FlxEase.expoOut, startDelay: 0.03});
		FlxTween.tween(sideAccent, {x: 0},       0.4, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(sideAccent2,{x: FlxG.width - 3}, 0.4, {ease: FlxEase.expoOut, startDelay: 0.12});
		FlxTween.tween(bottomBar,  {y: FlxG.height - 34}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.06});
		FlxTween.tween(menuLabelGlow, {y: 12, alpha: 0.15}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.12});
		FlxTween.tween(menuLabel,     {y: 13, alpha: 1},    0.5, {ease: FlxEase.expoOut, startDelay: 0.14});
		FlxTween.tween(counterText,   {alpha: 1},           0.4, {ease: FlxEase.quadOut, startDelay: 0.3});
		FlxTween.tween(selectedCard,  {alpha: 0.85},        0.4, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(selectedGlow,  {alpha: 0.3},         0.4, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(selectedGlow2, {alpha: 0.15},        0.4, {ease: FlxEase.quadOut, startDelay: 0.18});
		FlxTween.tween(cardTag,       {alpha: 1},           0.4, {ease: FlxEase.quadOut, startDelay: 0.25});

		for (i in 0...menuItems.members.length)
		{
			var item  = menuItems.members[i];
			var delay = 0.1 + i * 0.065;
			FlxTween.tween(item, {alpha: 0.55, x: 0}, 0.52, {
				ease: FlxEase.expoOut,
				startDelay: delay,
				onComplete: function(_)
				{
					item.screenCenter(X);
					if (i == menuItems.members.length - 1)
					{
						entering = false;
						FlxTween.tween(engineText,  {alpha: 1}, 0.4, {ease: FlxEase.quadOut});
						FlxTween.tween(versionText, {alpha: 1}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.05});
					}
				}
			});
		}

		for (i in 0...particles.members.length)
			FlxTween.tween(particles.members[i],
				{alpha: FlxG.random.float(0.04, 0.22)},
				FlxG.random.float(0.4, 1.2),
				{ease: FlxEase.quadOut, startDelay: FlxG.random.float(0, 1.0)});
	}

	function _playExitAnim(onDone:Void->Void)
	{
		FlxTween.tween(bg,          {alpha: 0},  0.4, {ease: FlxEase.quadIn});
		FlxTween.tween(bgGrid,      {alpha: 0},  0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(topBar,      {y: -48},    0.4, {ease: FlxEase.expoIn});
		FlxTween.tween(topAccent,   {y: -3},     0.4, {ease: FlxEase.expoIn});
		FlxTween.tween(sideAccent,  {x: -3},     0.35,{ease: FlxEase.expoIn});
		FlxTween.tween(sideAccent2, {x: FlxG.width}, 0.35, {ease: FlxEase.expoIn});
		FlxTween.tween(bottomBar,   {y: FlxG.height}, 0.35, {ease: FlxEase.expoIn});
		FlxTween.tween(menuLabel,   {y: -40, alpha: 0}, 0.3, {ease: FlxEase.expoIn});
		FlxTween.tween(engineText,  {alpha: 0},  0.25,{ease: FlxEase.quadIn});
		FlxTween.tween(versionText, {alpha: 0},  0.25,{ease: FlxEase.quadIn});
		FlxTween.tween(counterText, {alpha: 0},  0.2, {ease: FlxEase.quadIn});
		FlxTween.tween(selectedCard, {alpha: 0}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(selectedGlow, {alpha: 0}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(cardTag,      {alpha: 0}, 0.3, {ease: FlxEase.quadIn});

		for (i in 0...menuItems.members.length)
		{
			if (i == curSelected) continue;
			var item = menuItems.members[i];
			FlxTween.tween(item, {alpha: 0, x: item.x + 300}, 0.3, {
				ease: FlxEase.expoIn,
				startDelay: i * 0.022,
				onComplete: function(_) { item.kill(); }
			});
		}

		new FlxTimer().start(0.45, function(_) { onDone(); });
	}

	override function update(elapsed:Float)
	{
		_animateScanlines(elapsed);
		_animateShines(elapsed);
		_animateParticles(elapsed);
		_animateGlow(elapsed);
		_animateLabelPulse(elapsed);

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal = FlxMath.bound(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(
			FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
			FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
		);

		if (!selectedSomethin && !entering)
		{
			if (controls.UI_UP_P) changeItem(-1);
			if (controls.UI_DOWN_P) changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				_playExitAnim(function() MusicBeatState.switchState(new TitleState()));
			}
			else if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					if (ClientPrefs.data.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(_)
					{
						_switchToSelected();
					});

					for (i in 0...menuItems.members.length)
					{
						if (i == curSelected) continue;
						var item = menuItems.members[i];
						FlxTween.tween(item, {alpha: 0, x: item.x + 280}, 0.32, {
							ease: FlxEase.expoIn,
							startDelay: i * 0.022,
							onComplete: function(_) { item.kill(); }
						});
					}
				}
			}

			#if mobile
			var debugPressed = controls.justPressed('debug_1') || touchPad.buttonE.justPressed;
			#else
			var debugPressed = controls.justPressed('debug_1');
			#end

			if (debugPressed)
			{
				selectedSomethin = true;
				_playExitAnim(function() MusicBeatState.switchState(new MasterEditorMenu()));
			}
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite) { spr.screenCenter(X); });
	}

	function _switchToSelected()
	{
		switch (optionShit[curSelected])
		{
			case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
			case 'freeplay':   MusicBeatState.switchState(new FreeplayState());
			#if MODS_ALLOWED
			case 'mods':       MusicBeatState.switchState(new ModsMenuState());
			#end
			#if ACHIEVEMENTS_ALLOWED
			case 'awards':     MusicBeatState.switchState(new AchievementsMenuState());
			#end
			case 'credits':    MusicBeatState.switchState(new CreditsState());
			case 'school':     MusicBeatState.switchState(new SchoolState());
			case 'options':
				OptionsState.onPlayState = false;
				if (PlayState.SONG != null)
				{
					PlayState.SONG.arrowSkin  = null;
					PlayState.SONG.splashSkin = null;
					PlayState.stageUI = 'normal';
				}
				MusicBeatState.switchState(new OptionsState());
		}
	}

	function _animateScanlines(elapsed:Float)
	{
		scanlineY  += 88 * elapsed;
		scanline2Y += 50 * elapsed;
		scanline3Y += 30 * elapsed;
		if (scanlineY  > FlxG.height) scanlineY  = -3;
		if (scanline2Y > FlxG.height) scanline2Y = -2;
		if (scanline3Y > FlxG.height) scanline3Y = -1;
		scanline.y  = scanlineY;
		scanline2.y = scanline2Y;
		scanline3.y = scanline3Y;
	}

	function _animateShines(elapsed:Float)
	{
		shineX  += 155 * elapsed;
		shine2X += 95  * elapsed;
		if (shineX  > FlxG.width + 90)  shineX  = -200;
		if (shine2X > FlxG.width + 40)  shine2X = -500;
		bgShine.x  = shineX;
		bgShine2.x = shine2X;

		accentShineX += 210 * elapsed;
		if (accentShineX > FlxG.width + 60) accentShineX = -60;
	}

	function _animateParticles(elapsed:Float)
	{
		particleTimer += elapsed;
		if (particleTimer > 0.05)
		{
			particleTimer = 0;
			for (i in 0...particles.members.length)
			{
				var p = particles.members[i];
				p.y -= particleSpeeds[i];
				if (p.y < -10) p.y = FlxG.height + 10;
			}
		}
	}

	function _animateGlow(elapsed:Float)
	{
		glowTimer += elapsed;
		var pulse = (Math.sin(glowTimer * 2.0) + 1) / 2;
		if (sideAccent != null)
		{
			sideAccent.alpha  = 0.55 + pulse * 0.45;
			sideAccent2.alpha = 0.15 + pulse * 0.15;
		}
		bgGlow.alpha = pulse * 0.018;
	}

	function _animateLabelPulse(elapsed:Float)
	{
		if (menuLabelGlow == null) return;
		var pulse = (Math.sin(glowTimer * 1.6) + 1) / 2;
		menuLabelGlow.alpha = 0.06 + pulse * 0.14;
	}

	function changeItem(huh:Int = 0)
	{
		if (huh != 0) FlxG.sound.play(Paths.sound('scrollMenu'));

		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].updateHitbox();

		curSelected += huh;
		if (curSelected >= menuItems.length) curSelected = 0;
		if (curSelected < 0)                curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();

		var col = FlxColor.fromInt(optionColors[curSelected % optionColors.length]);

		for (i in 0...menuItems.members.length)
		{
			var item  = menuItems.members[i];
			var isSel = (i == curSelected);
			FlxTween.cancelTweensOf(item, ['alpha']);
			FlxTween.tween(item, {alpha: isSel ? 1.0 : 0.45}, 0.15, {ease: FlxEase.quadOut});
		}

		FlxTween.cancelTweensOf(sideAccent,  ['color']);
		FlxTween.cancelTweensOf(sideAccent2, ['color']);
		FlxTween.cancelTweensOf(topAccent,   ['color']);
		FlxTween.cancelTweensOf(cardTag,     ['color']);
		FlxTween.cancelTweensOf(selectedCard,['color']);

		FlxTween.color(sideAccent,   0.3, sideAccent.color,   col);
		FlxTween.color(sideAccent2,  0.3, sideAccent2.color,  col);
		FlxTween.color(topAccent,    0.3, topAccent.color,     col);
		FlxTween.color(cardTag,      0.25,cardTag.color,       col);
		FlxTween.color(selectedCard, 0.25,selectedCard.color,  col.getDarkened(0.75));
		FlxTween.color(selectedGlow, 0.25,selectedGlow.color,  col.getDarkened(0.5));

		counterText.text = (curSelected + 1) + ' / ' + menuItems.length;

		var sel = menuItems.members[curSelected];
		camFollow.setPosition(
			sel.getGraphicMidpoint().x,
			sel.getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0)
		);

		var selY = sel.y;
		selectedCard.y  = selY - 2;
		selectedGlow.y  = selY - 4;
		selectedGlow2.y = selY - 6;
		cardTag.y       = selY - 2;
	}
}
