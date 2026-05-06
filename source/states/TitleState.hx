package states;

import backend.WeekData;
import backend.Highscore;

import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import shaders.ColorSwap;

import states.StoryMenuState;
import states.OutdatedState;
import states.MainMenuState;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Float
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey>       = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey>   = [FlxKey.NUMPADPLUS,  FlxKey.PLUS];

	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float>    = [1, 0.64];

	var curWacky:Array<String> = [];
	var wackyImage:FlxSprite;

	#if TITLE_SCREEN_EASTER_EGG
	var easterEggKeys:Array<String> = ['SHADOW', 'RIVER', 'BBPANZU'];
	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	var mustUpdate:Bool = false;
	var titleJSON:TitleData;
	public static var updateVersion:String = '';

	var scanline:FlxSprite;
	var scanline2:FlxSprite;
	var bgParticles:FlxTypedGroup<FlxSprite>;
	var scanlineY:Float  = 0;
	var scanline2Y:Float = 360;
	var particleSpeeds:Array<Float> = [];
	var particleTimer:Float = 0;

	var vignette:FlxSprite;
	var glowPulse:FlxSprite;
	var glowTimer:Float = 0;

	override public function create():Void
	{
		Paths.clearStoredMemory();

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		curWacky = FlxG.random.getObject(getIntroTextShit());

		super.create();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		ClientPrefs.loadPrefs();

		#if CHECK_FOR_UPDATES
		if (ClientPrefs.data.checkForUpdates && !closedState)
		{
			var http = new haxe.Http("https://raw.githubusercontent.com/AliAlafandy/FNF-PsychEngine-0.7.3-Template/main/gitVersion.txt");
			http.onData  = function(data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion = MainMenuState.psychEngineVersion.trim();
				if (updateVersion != curVersion) mustUpdate = true;
			}
			http.onError = function(error) { trace('update check error: $error'); }
			http.request();
		}
		#end

		Highscore.load();

		titleJSON = tjson.TJSON.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		#if TITLE_SCREEN_EASTER_EGG
		if (FlxG.save.data.psychDevsEasterEgg == null)
			FlxG.save.data.psychDevsEasterEgg = '';
		switch (FlxG.save.data.psychDevsEasterEgg.toUpperCase())
		{
			case 'SHADOW':  titleJSON.gfx += 210; titleJSON.gfy += 40;
			case 'RIVER':   titleJSON.gfx += 180; titleJSON.gfy += 40;
			case 'BBPANZU': titleJSON.gfx += 45;  titleJSON.gfy += 100;
		}
		#end

		if (!initialized)
		{
			if (FlxG.save.data != null && FlxG.save.data.fullscreen)
				FlxG.fullscreen = FlxG.save.data.fullscreen;
			persistentUpdate = true;
			persistentDraw   = true;
			MobileData.init();
		}

		if (FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxG.mouse.visible = false;

		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			controls.isInSubstate = false;
			FlxTransitionableState.skipNextTransIn  = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
		{
			if (initialized)
				startIntro();
			else
				new FlxTimer().start(1, function(_) { startIntro(); });
		}
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	function startIntro()
	{
		if (!initialized && FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

		Conductor.bpm = titleJSON.bpm;
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none")
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
		else
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		_buildAtmosphere();

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		logoBl.alpha = 0;
		logoBl.scale.set(0.85, 0.85);

		if (ClientPrefs.data.shaders) swagShader = new ColorSwap();

		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
		gfDance.antialiasing = ClientPrefs.data.antialiasing;
		gfDance.alpha = 0;

		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg != null
			? FlxG.save.data.psychDevsEasterEgg.toUpperCase() : '';

		switch (easterEgg)
		{
			#if TITLE_SCREEN_EASTER_EGG
			case 'SHADOW':
				gfDance.frames = Paths.getSparrowAtlas('ShadowBump');
				gfDance.animation.addByPrefix('danceLeft',  'Shadow Title Bump', 24);
				gfDance.animation.addByPrefix('danceRight', 'Shadow Title Bump', 24);
			case 'RIVER':
				gfDance.frames = Paths.getSparrowAtlas('RiverBump');
				gfDance.animation.addByIndices('danceLeft',  'River Title Bump', [15,16,17,18,19,20,21,22,23,24,25,26,27,28,29], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'River Title Bump', [29,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14], "", 24, false);
			case 'BBPANZU':
				gfDance.frames = Paths.getSparrowAtlas('BBBump');
				gfDance.animation.addByIndices('danceLeft',  'BB Title Bump', [14,15,16,17,18,19,20,21,22,23,24,25,26,27], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'BB Title Bump', [27,0,1,2,3,4,5,6,7,8,9,10,11,12,13], "", 24, false);
			#end
			default:
				gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
				gfDance.animation.addByIndices('danceLeft',  'gfDance', [30,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'gfDance', [15,16,17,18,19,20,21,22,23,24,25,26,27,28,29], "", 24, false);
		}

		add(gfDance);
		add(logoBl);

		if (swagShader != null)
		{
			gfDance.shader = swagShader.shader;
			logoBl.shader  = swagShader.shader;
		}

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		titleText.alpha  = 0;

		var animFrames:Array<FlxFrame> = [];
		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		if (animFrames.length > 0)
		{
			newTitle = true;
			titleText.animation.addByPrefix('idle',  "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			newTitle = false;
			titleText.animation.addByPrefix('idle',  "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}

		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		add(vignette);
		add(scanline);
		add(scanline2);
		add(bgParticles);
		add(glowPulse);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;
		add(ngSpr);

		if (initialized)
			skipIntro();
		else
			initialized = true;

		Paths.clearUnusedMemory();
	}

	function _buildAtmosphere()
	{
		vignette = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		vignette.scrollFactor.set();
		vignette.alpha = 0.35;

		scanline = new FlxSprite(0, 0).makeGraphic(FlxG.width, 3, 0x14FFFFFF);
		scanline.scrollFactor.set();

		scanline2 = new FlxSprite(0, 360).makeGraphic(FlxG.width, 2, 0x08FFFFFF);
		scanline2.scrollFactor.set();

		glowPulse = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF00AAFF);
		glowPulse.scrollFactor.set();
		glowPulse.alpha = 0;

		bgParticles = new FlxTypedGroup<FlxSprite>();
		for (i in 0...18)
		{
			var size = FlxG.random.int(1, 3);
			var p    = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			p.makeGraphic(size, size, 0x20FFFFFF);
			p.scrollFactor.set();
			p.alpha = 0;
			bgParticles.add(p);
			particleSpeeds.push(FlxG.random.float(0.2, 0.9));
		}

		for (i in 0...bgParticles.members.length)
			FlxTween.tween(bgParticles.members[i],
				{alpha: FlxG.random.float(0.05, 0.22)},
				FlxG.random.float(0.5, 1.5),
				{ease: FlxEase.quadOut, startDelay: FlxG.random.float(0, 1.5)});
	}

	function getIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		var firstArray = Mods.mergeAllTextsNamed('data/introText.txt', Paths.getSharedPath());
		#else
		var firstArray = Assets.getText(Paths.txt('introText')).split('\n');
		#end
		return [for (i in firstArray) i.split('--')];
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;

	var newTitle:Bool   = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		_animateScanlines(elapsed);
		_animateParticles(elapsed);
		_animateGlow(elapsed);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
			if (touch.justPressed) pressedEnter = true;
		#end

		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			if (gamepad.justPressed.START) pressedEnter = true;
			#if switch
			if (gamepad.justPressed.B) pressedEnter = true;
			#end
		}

		if (newTitle)
		{
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var t:Float = titleTimer >= 1 ? (-titleTimer) + 2 : titleTimer;
				t = FlxEase.quadInOut(t);
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], t);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], t);
			}

			if (pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				if (titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				_flashLogoOnPress();

				transitioning = true;

				new FlxTimer().start(1, function(_)
				{
					MusicBeatState.switchState(mustUpdate ? new OutdatedState() : new MainMenuState());
					closedState = true;
				});
			}

			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyName = Std.string(FlxG.keys.firstJustPressed());
				if (allowedKeys.contains(keyName))
				{
					easterEggKeysBuffer += keyName;
					if (easterEggKeysBuffer.length >= 32)
						easterEggKeysBuffer = easterEggKeysBuffer.substring(1);

					for (wordRaw in easterEggKeys)
					{
						var word = wordRaw.toUpperCase();
						if (easterEggKeysBuffer.contains(word))
						{
							FlxG.save.data.psychDevsEasterEgg =
								(FlxG.save.data.psychDevsEasterEgg == word) ? '' : word;
							FlxG.save.flush();
							FlxG.sound.play(Paths.sound('ToggleJingle'));

							var black = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
							black.alpha = 0;
							add(black);
							FlxTween.tween(black, {alpha: 1}, 1, {
								onComplete: function(_)
								{
									FlxTransitionableState.skipNextTransIn  = true;
									FlxTransitionableState.skipNextTransOut = true;
									MusicBeatState.switchState(new TitleState());
								}
							});

							FlxG.sound.music.fadeOut();
							if (FreeplayState.vocals != null) FreeplayState.vocals.fadeOut();
							closedState    = true;
							transitioning  = true;
							playJingle     = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if (initialized && pressedEnter && !skippedIntro)
			skipIntro();

		if (swagShader != null)
		{
			if (controls.UI_LEFT)  swagShader.hue -= elapsed * 0.1;
			if (controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function _flashLogoOnPress()
	{
		if (logoBl == null) return;
		FlxTween.tween(logoBl, {alpha: 0.3}, 0.06, {
			ease: FlxEase.quadOut,
			onComplete: function(_) {
				FlxTween.tween(logoBl, {alpha: 1}, 0.15, {ease: FlxEase.quadIn});
			}
		});
		FlxTween.tween(logoBl.scale, {x: 1.08, y: 1.08}, 0.08, {
			ease: FlxEase.quadOut,
			onComplete: function(_) {
				FlxTween.tween(logoBl.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.elasticOut});
			}
		});
	}

	function _animateScanlines(elapsed:Float)
	{
		if (scanline == null || scanline2 == null) return;
		scanlineY  += 88 * elapsed;
		scanline2Y += 48 * elapsed;
		if (scanlineY  > FlxG.height) scanlineY  = -3;
		if (scanline2Y > FlxG.height) scanline2Y = -2;
		scanline.y  = scanlineY;
		scanline2.y = scanline2Y;
	}

	function _animateParticles(elapsed:Float)
	{
		if (bgParticles == null) return;
		particleTimer += elapsed;
		if (particleTimer > 0.06)
		{
			particleTimer = 0;
			for (i in 0...bgParticles.members.length)
			{
				var p = bgParticles.members[i];
				p.y -= particleSpeeds[i];
				if (p.y < -10) p.y = FlxG.height + 10;
			}
		}
	}

	function _animateGlow(elapsed:Float)
	{
		if (glowPulse == null) return;
		glowTimer += elapsed;
		glowPulse.alpha = (Math.sin(glowTimer * 1.8) + 1) / 2 * 0.04;
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y    += (i * 60) + 200 + offset;
			money.alpha = 0;
			money.x    -= 80;

			FlxTween.tween(money, {alpha: 1, x: money.x + 80}, 0.4, {
				ease: FlxEase.expoOut,
				startDelay: i * 0.08
			});

			if (credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if (textGroup == null || credGroup == null) return;

		var coolText:Alphabet = new Alphabet(0, 0, text, true);
		coolText.screenCenter(X);
		coolText.y    += (textGroup.length * 60) + 200 + offset;
		coolText.alpha = 0;
		coolText.x    -= 60;

		FlxTween.tween(coolText, {alpha: 1, x: coolText.x + 60}, 0.35, {ease: FlxEase.expoOut});

		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		var membersToDelete = textGroup.members.copy();
		for (basicMember in membersToDelete)
		{
			var member = cast(basicMember, FlxObject);
			if (member == null) continue;

			FlxTween.tween(member, {alpha: 0, y: member.y - 20}, 0.25, {
				ease: FlxEase.quadIn,
				onComplete: function(_)
				{
					credGroup.remove(member, true);
					textGroup.remove(member, true);
				}
			});
		}
	}

	private var sickBeats:Int = 0;
	public static var closedState:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if (logoBl != null)
		{
			logoBl.animation.play('bump', true);
			FlxTween.tween(logoBl.scale, {x: 1.04, y: 1.04}, 0.06, {
				ease: FlxEase.quadOut,
				onComplete: function(_) {
					FlxTween.tween(logoBl.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.elasticOut});
				}
			});
		}

		if (gfDance != null)
		{
			danceLeft = !danceLeft;
			gfDance.animation.play(danceLeft ? 'danceRight' : 'danceLeft');
		}

		if (!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					#if PSYCH_WATERMARKS
					createCoolText(['Psych Engine by'], 40);
					#else
					createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
					#end
				case 4:
					#if PSYCH_WATERMARKS
					addMoreText('Shadow Mario', 40);
					addMoreText('Riveren', 40);
					#else
					addMoreText('present');
					#end
				case 5:
					deleteCoolText();
				case 6:
					#if PSYCH_WATERMARKS
					createCoolText(['Not associated', 'with'], -40);
					#else
					createCoolText(['In association', 'with'], -40);
					#end
				case 8:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
					ngSpr.alpha   = 0;
					FlxTween.tween(ngSpr, {alpha: 1}, 0.4, {ease: FlxEase.quadOut});
				case 9:
					deleteCoolText();
					FlxTween.tween(ngSpr, {alpha: 0}, 0.25, {
						ease: FlxEase.quadIn,
						onComplete: function(_) { ngSpr.visible = false; }
					});
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
				case 14:
					addMoreText('Friday');
				case 15:
					addMoreText('Night');
				case 16:
					addMoreText('Funkin');
				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool   = false;
	var increaseVolume:Bool = false;

	function skipIntro():Void
	{
		if (skippedIntro) return;

		if (playJingle)
		{
			var easteregg = (FlxG.save.data.psychDevsEasterEgg != null
				? FlxG.save.data.psychDevsEasterEgg : '').toUpperCase();

			var sound:FlxSound = null;
			switch (easteregg)
			{
				case 'RIVER':   sound = FlxG.sound.play(Paths.sound('JingleRiver'));
				case 'SHADOW':  FlxG.sound.play(Paths.sound('JingleShadow'));
				case 'BBPANZU': sound = FlxG.sound.play(Paths.sound('JingleBB'));
				default:
					_flashSkipIntro(4);
					playJingle   = false;
					skippedIntro = true;
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
					return;
			}

			transitioning = true;
			if (easteregg == 'SHADOW')
			{
				new FlxTimer().start(3.2, function(_)
				{
					_flashSkipIntro(0.6);
					transitioning = false;
				});
			}
			else
			{
				_flashSkipIntro(3);
				if (sound != null)
				{
					sound.onComplete = function()
					{
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						transitioning = false;
					};
				}
			}
			playJingle = false;
		}
		else
		{
			_flashSkipIntro(4);

			var easteregg = (FlxG.save.data.psychDevsEasterEgg != null
				? FlxG.save.data.psychDevsEasterEgg : '').toUpperCase();

			#if TITLE_SCREEN_EASTER_EGG
			if (easteregg == 'SHADOW')
			{
				FlxG.sound.music.fadeOut();
				if (FreeplayState.vocals != null) FreeplayState.vocals.fadeOut();
			}
			#end
		}

		skippedIntro = true;
	}

	function _flashSkipIntro(duration:Float)
	{
		remove(ngSpr);
		remove(credGroup);

		FlxG.camera.flash(FlxColor.WHITE, duration);

		if (logoBl != null)
		{
			logoBl.alpha = 0;
			FlxTween.tween(logoBl, {alpha: 1, 'scale.x': 1.0, 'scale.y': 1.0}, 0.5, {
				ease: FlxEase.backOut,
				startDelay: 0.1
			});
		}

		if (gfDance != null)
		{
			gfDance.alpha = 0;
			FlxTween.tween(gfDance, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.15});
		}

		if (titleText != null)
		{
			titleText.alpha = 0;
			FlxTween.tween(titleText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.3});
		}
	}
}
