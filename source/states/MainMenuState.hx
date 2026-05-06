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
		#if !switch
		'donate',
		#end
		'options'
	];

	var bg:FlxSprite;
	var bgGrid:FlxSprite;
	var magenta:FlxSprite;
	var vignette:FlxSprite;
	var scanline:FlxSprite;
	var scanline2:FlxSprite;
	var bgShine:FlxSprite;
	var bottomBar:FlxSprite;
	var sideAccent:FlxSprite;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var versionText:FlxText;
	var engineText:FlxText;

	var particles:FlxTypedGroup<FlxSprite>;
	var particleSpeeds:Array<Float> = [];
	var particleTimer:Float = 0;

	var scanlineY:Float  = 0;
	var scanline2Y:Float = 300;
	var shineX:Float     = -200;
	var glowTimer:Float  = 0;

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
		bg.scale.set(1.05, 1.05);
		add(bg);

		bgGrid = FlxGridOverlay.create(36, 36, FlxG.width, FlxG.height, true, 0x07FFFFFF, 0x00000000);
		bgGrid.scrollFactor.set();
		bgGrid.alpha = 0;
		add(bgGrid);

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
		vignette.alpha = 0.38;
		add(vignette);

		scanline = new FlxSprite(0, 0).makeGraphic(FlxG.width, 3, 0x12FFFFFF);
		scanline.scrollFactor.set();
		add(scanline);

		scanline2 = new FlxSprite(0, 300).makeGraphic(FlxG.width, 2, 0x08FFFFFF);
		scanline2.scrollFactor.set();
		add(scanline2);

		bgShine = new FlxSprite(-200, 0).makeGraphic(100, FlxG.height, 0x10FFFFFF);
		bgShine.scrollFactor.set();
		add(bgShine);

		sideAccent = new FlxSprite(0, 55).makeGraphic(3, FlxG.height - 85, 0xFFfd719b);
		sideAccent.scrollFactor.set();
		sideAccent.x = -3;
		add(sideAccent);

		bottomBar = new FlxSprite(0, FlxG.height - 32).makeGraphic(FlxG.width, 32, 0xCC0D0D1A);
		bottomBar.scrollFactor.set();
		bottomBar.y = FlxG.height;
		add(bottomBar);
	}

	function _buildParticles()
	{
		particles = new FlxTypedGroup<FlxSprite>();
		add(particles);

		for (i in 0...14)
		{
			var size = FlxG.random.int(1, 3);
			var p    = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			p.makeGraphic(size, size, 0x30FFFFFF);
			p.scrollFactor.set();
			p.alpha = 0;
			particles.add(p);
			particleSpeeds.push(FlxG.random.float(0.25, 1.0));
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
		engineText = new FlxText(12, FlxG.height - 28, 0, 'Psych Engine v$psychEngineVersion', 12);
		engineText.scrollFactor.set();
		engineText.setFormat('VCR OSD Mono', 13, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		engineText.borderSize = 1.5;
		engineText.alpha = 0;
		add(engineText);

		versionText = new FlxText(FlxG.width - 12, FlxG.height - 28, 0, 'v' + Application.current.meta.get('version'), 12);
		versionText.scrollFactor.set();
		versionText.setFormat('VCR OSD Mono', 13, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionText.borderSize = 1.5;
		versionText.x -= versionText.width;
		versionText.alpha = 0;
		add(versionText);
	}

	function _playEnterAnim()
	{
		FlxTween.tween(bg,       {alpha: 0.85, 'scale.x': 1.0, 'scale.y': 1.0}, 0.7, {ease: FlxEase.quadOut});
		FlxTween.tween(bgGrid,   {alpha: 1},   0.9, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(sideAccent, {x: 0},     0.4, {ease: FlxEase.expoOut, startDelay: 0.15});
		FlxTween.tween(bottomBar, {y: FlxG.height - 32}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.08});

		for (i in 0...menuItems.members.length)
		{
			var item  = menuItems.members[i];
			var delay = 0.1 + i * 0.07;
			FlxTween.tween(item, {alpha: 0.6, x: 0}, 0.55, {
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
				{alpha: FlxG.random.float(0.04, 0.2)},
				FlxG.random.float(0.4, 1.2),
				{ease: FlxEase.quadOut, startDelay: FlxG.random.float(0, 1.0)});
	}

	function _playExitAnim(onDone:Void->Void)
	{
		FlxTween.tween(bg,         {alpha: 0},  0.4, {ease: FlxEase.quadIn});
		FlxTween.tween(bgGrid,     {alpha: 0},  0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(sideAccent, {x: -3},     0.35, {ease: FlxEase.expoIn});
		FlxTween.tween(bottomBar,  {y: FlxG.height}, 0.35, {ease: FlxEase.expoIn});
		FlxTween.tween(engineText,  {alpha: 0}, 0.25, {ease: FlxEase.quadIn});
		FlxTween.tween(versionText, {alpha: 0}, 0.25, {ease: FlxEase.quadIn});

		for (i in 0...menuItems.members.length)
		{
			if (i == curSelected) continue;
			var item = menuItems.members[i];
			FlxTween.tween(item, {alpha: 0, x: item.x + 300}, 0.3, {
				ease: FlxEase.expoIn,
				startDelay: i * 0.025,
				onComplete: function(_) { item.kill(); }
			});
		}

		new FlxTimer().start(0.45, function(_) { onDone(); });
	}

	override function update(elapsed:Float)
	{
		_animateScanlines(elapsed);
		_animateShine(elapsed);
		_animateParticles(elapsed);
		_animateGlow(elapsed);

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
						FlxTween.tween(item, {alpha: 0, x: item.x + 280}, 0.35, {
							ease: FlxEase.expoIn,
							startDelay: i * 0.025,
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
		scanlineY  += 90 * elapsed;
		scanline2Y += 50 * elapsed;
		if (scanlineY  > FlxG.height) scanlineY  = -3;
		if (scanline2Y > FlxG.height) scanline2Y = -2;
		scanline.y  = scanlineY;
		scanline2.y = scanline2Y;
	}

	function _animateShine(elapsed:Float)
	{
		shineX += 160 * elapsed;
		if (shineX > FlxG.width + 100) shineX = -200;
		bgShine.x = shineX;
	}

	function _animateParticles(elapsed:Float)
	{
		particleTimer += elapsed;
		if (particleTimer > 0.055)
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
		var pulse = (Math.sin(glowTimer * 2.2) + 1) / 2;
		if (sideAccent != null)
			sideAccent.alpha = 0.6 + pulse * 0.4;
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

		for (i in 0...menuItems.members.length)
		{
			var item  = menuItems.members[i];
			var isSel = (i == curSelected);
			FlxTween.cancelTweensOf(item, ['alpha']);
			FlxTween.tween(item, {alpha: isSel ? 1.0 : 0.5}, 0.15, {ease: FlxEase.quadOut});
		}

		var sel = menuItems.members[curSelected];
		camFollow.setPosition(
			sel.getGraphicMidpoint().x,
			sel.getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0)
		);

		FlxTween.cancelTweensOf(sideAccent, ['color']);
		FlxTween.color(sideAccent, 0.3, sideAccent.color, FlxColor.fromInt(0xFFfd719b).getLightened(0.15));
	}
}
