package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var bgOverlay:FlxSprite;
	var bgGrid:FlxSprite;
	var vignette:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var topBar:FlxSprite;
	var accentBar:FlxSprite;
	var accentBarShine:FlxSprite;
	var bottomBar:FlxSprite;
	var sideLine:FlxSprite;

	var scanline:FlxSprite;
	var scanline2:FlxSprite;
	var bgShine:FlxSprite;

	var titleText:FlxText;
	var titleGlow:FlxText;
	var songCountText:FlxText;
	var weekText:FlxText;

	var selectedCard:FlxSprite;
	var selectedGlow:FlxSprite;
	var cardTag:FlxSprite;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var particles:FlxTypedGroup<FlxSprite>;
	var particleSpeeds:Array<Float> = [];
	var particleTimer:Float = 0;

	var scanlineY:Float  = 0;
	var scanline2Y:Float = 200;
	var shineX:Float     = -120;
	var accentShineX:Float = -60;
	var glowTimer:Float  = 0;
	var titlePulse:Bool  = true;

	var player:MusicPlayer;

	var entering:Bool = true;
	var exiting:Bool  = false;

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];

	override function create()
	{
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		_loadSongs();
		_buildBG();
		_buildParticles();
		_buildCards();
		_buildSongList();
		_buildScorePanel();
		_buildHUD();
		_buildMissing();

		if (curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		player = new MusicPlayer(this);
		add(player);

		changeSelection();
		updateTexts();

		#if mobile
		addTouchPad("LEFT_FULL", "A_B_C_X_Y_Z");
		#end

		super.create();

		_playEnterAnim();
	}

	function _loadSongs()
	{
		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i])) continue;
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3) colors = [146, 113, 253];
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();
	}

	function _buildBG()
	{
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		bg.color = 0xFF888888;
		bg.alpha = 0;
		bg.scale.set(1.06, 1.06);
		add(bg);

		bgOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bgOverlay.scrollFactor.set();
		bgOverlay.alpha = 0.5;
		add(bgOverlay);

		bgGrid = FlxGridOverlay.create(30, 30, FlxG.width, FlxG.height, true, 0x07FFFFFF, 0x00000000);
		bgGrid.scrollFactor.set();
		bgGrid.alpha = 0;
		add(bgGrid);

		vignette = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		vignette.scrollFactor.set();
		vignette.alpha = 0.3;
		add(vignette);

		scanline = new FlxSprite(0, 0).makeGraphic(FlxG.width, 3, 0x14FFFFFF);
		scanline.scrollFactor.set();
		add(scanline);

		scanline2 = new FlxSprite(0, 200).makeGraphic(FlxG.width, 2, 0x08FFFFFF);
		scanline2.scrollFactor.set();
		add(scanline2);

		bgShine = new FlxSprite(-120, 0).makeGraphic(80, FlxG.height, 0x10FFFFFF);
		bgShine.scrollFactor.set();
		add(bgShine);

		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 54, 0xDD0D0D1A);
		topBar.scrollFactor.set();
		topBar.y = -54;
		add(topBar);

		accentBar = new FlxSprite(0, 54).makeGraphic(FlxG.width, 3, 0xFF00D4FF);
		accentBar.scrollFactor.set();
		accentBar.y = -3;
		add(accentBar);

		accentBarShine = new FlxSprite(0, 54).makeGraphic(50, 3, 0xAAFFFFFF);
		accentBarShine.scrollFactor.set();
		accentBarShine.y = -3;
		add(accentBarShine);

		sideLine = new FlxSprite(0, 57).makeGraphic(3, FlxG.height - 85, 0xFF00D4FF);
		sideLine.scrollFactor.set();
		sideLine.x = -3;
		add(sideLine);

		bottomBar = new FlxSprite(0, FlxG.height - 30).makeGraphic(FlxG.width, 30, 0xDD0D0D1A);
		bottomBar.scrollFactor.set();
		bottomBar.y = FlxG.height;
		add(bottomBar);
	}

	function _buildParticles()
	{
		particles = new FlxTypedGroup<FlxSprite>();
		add(particles);

		for (i in 0...16)
		{
			var size = FlxG.random.int(1, 3);
			var p = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			p.makeGraphic(size, size, 0x28FFFFFF);
			p.scrollFactor.set();
			p.alpha = 0;
			particles.add(p);
			particleSpeeds.push(FlxG.random.float(0.2, 1.1));
		}
	}

	function _buildCards()
	{
		selectedGlow = new FlxSprite(55, 0).makeGraphic(FlxG.width - 110, 62, 0x22FFFFFF);
		selectedGlow.scrollFactor.set();
		selectedGlow.alpha = 0;
		add(selectedGlow);

		selectedCard = new FlxSprite(62, 0).makeGraphic(FlxG.width - 124, 54, 0xFF16213E);
		selectedCard.scrollFactor.set();
		selectedCard.alpha = 0;
		add(selectedCard);

		cardTag = new FlxSprite(62, 0).makeGraphic(4, 54, 0xFF00D4FF);
		cardTag.scrollFactor.set();
		cardTag.alpha = 0;
		add(cardTag);
	}

	function _buildSongList()
	{
		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			songText.visible = songText.active = songText.isMenuItem = false;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			icon.visible = icon.active = false;
			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();
	}

	function _buildScorePanel()
	{
		scoreText = new FlxText(FlxG.width * 0.7, 58, 0, '', 28);
		scoreText.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.borderSize = 1.5;
		scoreText.scrollFactor.set();
		scoreText.alpha = 0;
		add(scoreText);

		scoreBG = new FlxSprite(scoreText.x - 6, 57).makeGraphic(1, 66, 0xCC000000);
		scoreBG.scrollFactor.set();
		scoreBG.alpha = 0;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 34, 0, '', 20);
		diffText.setFormat(Paths.font('vcr.ttf'), 20, 0xFF00D4FF, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		diffText.borderSize = 1;
		diffText.scrollFactor.set();
		diffText.alpha = 0;
		add(diffText);
	}

	function _buildHUD()
	{
		titleGlow = new FlxText(10, 13, 0, 'FREEPLAY', 24);
		titleGlow.setFormat('VCR OSD Mono', 24, 0xFF00D4FF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF00D4FF);
		titleGlow.borderSize = 5;
		titleGlow.scrollFactor.set();
		titleGlow.alpha = 0;
		titleGlow.y = -50;
		add(titleGlow);

		titleText = new FlxText(10, 14, 0, 'FREEPLAY', 24);
		titleText.setFormat('VCR OSD Mono', 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		titleText.scrollFactor.set();
		titleText.alpha = 0;
		titleText.y = -50;
		add(titleText);

		songCountText = new FlxText(FlxG.width - 120, 18, 110, '', 13);
		songCountText.setFormat('VCR OSD Mono', 13, 0xFF546E7A, RIGHT);
		songCountText.scrollFactor.set();
		songCountText.alpha = 0;
		add(songCountText);

		weekText = new FlxText(10, FlxG.height - 24, 0, '', 12);
		weekText.setFormat('VCR OSD Mono', 12, 0xFFFFCC02, LEFT);
		weekText.scrollFactor.set();
		add(weekText);

		var btnSpace = controls.mobileC ? 'X' : 'SPACE';
		var btnCtrl  = controls.mobileC ? 'C' : 'CTRL';
		var btnReset = controls.mobileC ? 'Y' : 'RESET';

		bottomBG = new FlxSprite(0, FlxG.height - 30).makeGraphic(FlxG.width, 30, 0xCC000000);
		bottomBG.scrollFactor.set();
		bottomBG.alpha = 0;
		add(bottomBG);

		bottomText = new FlxText(0, FlxG.height - 24, FlxG.width,
			'$btnSpace: Preview  |  $btnCtrl: Options  |  $btnReset: Reset  |  ◄►: Difficulty', 12);
		bottomText.setFormat(Paths.font('vcr.ttf'), 12, 0xFF78909C, CENTER);
		bottomText.scrollFactor.set();
		bottomText.alpha = 0;
		add(bottomText);
	}

	function _buildMissing()
	{
		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);
	}

	function _playEnterAnim()
	{
		FlxTween.tween(bg,       {alpha: 0.7, 'scale.x': 1.0, 'scale.y': 1.0}, 0.7, {ease: FlxEase.quadOut});
		FlxTween.tween(bgGrid,   {alpha: 1},   0.9, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(topBar,   {y: 0},       0.5, {ease: FlxEase.expoOut});
		FlxTween.tween(accentBar,{y: 54},      0.5, {ease: FlxEase.expoOut, startDelay: 0.04});
		FlxTween.tween(accentBarShine, {y: 54},0.5, {ease: FlxEase.expoOut, startDelay: 0.06});
		FlxTween.tween(sideLine, {x: 0},       0.4, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(bottomBar,{y: FlxG.height - 30}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.04});

		FlxTween.tween(titleGlow,{y: 13, alpha: 0.15}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.12});
		FlxTween.tween(titleText,{y: 14, alpha: 1},    0.5, {ease: FlxEase.expoOut, startDelay: 0.14});

		FlxTween.tween(selectedCard, {alpha: 0.8}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(selectedGlow, {alpha: 0.3}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(cardTag,      {alpha: 1},   0.4, {ease: FlxEase.quadOut, startDelay: 0.25});

		FlxTween.tween(scoreBG,    {alpha: 0.6}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.25});
		FlxTween.tween(scoreText,  {alpha: 1},   0.4, {ease: FlxEase.quadOut, startDelay: 0.28});
		FlxTween.tween(diffText,   {alpha: 1},   0.4, {ease: FlxEase.quadOut, startDelay: 0.3});
		FlxTween.tween(songCountText,{alpha: 1}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.32});
		FlxTween.tween(bottomBG,   {alpha: 0.6}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.3});
		FlxTween.tween(bottomText, {alpha: 1},   0.4, {ease: FlxEase.quadOut, startDelay: 0.32});

		for (i in 0...particles.members.length)
			FlxTween.tween(particles.members[i],
				{alpha: FlxG.random.float(0.04, 0.2)},
				FlxG.random.float(0.4, 1.2),
				{ease: FlxEase.quadOut, startDelay: FlxG.random.float(0, 0.8)});

		new FlxTimer().start(0.55, function(_) { entering = false; });
	}

	function _playExitAnim(onDone:Void->Void)
	{
		FlxTween.tween(bg,        {alpha: 0},  0.4, {ease: FlxEase.quadIn});
		FlxTween.tween(bgGrid,    {alpha: 0},  0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(topBar,    {y: -54},    0.4, {ease: FlxEase.expoIn});
		FlxTween.tween(accentBar, {y: -3},     0.4, {ease: FlxEase.expoIn});
		FlxTween.tween(sideLine,  {x: -3},     0.35,{ease: FlxEase.expoIn});
		FlxTween.tween(bottomBar, {y: FlxG.height}, 0.35, {ease: FlxEase.expoIn});
		FlxTween.tween(titleText, {y: -50, alpha: 0}, 0.3, {ease: FlxEase.expoIn});
		FlxTween.tween(selectedCard,{alpha: 0}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(selectedGlow,{alpha: 0}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(cardTag,     {alpha: 0}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(scoreBG,     {alpha: 0}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(scoreText,   {alpha: 0}, 0.25,{ease: FlxEase.quadIn});
		FlxTween.tween(diffText,    {alpha: 0}, 0.25,{ease: FlxEase.quadIn});
		FlxTween.tween(bottomText,  {alpha: 0}, 0.2, {ease: FlxEase.quadIn});

		new FlxTimer().start(0.45, function(_) { onDone(); });
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();

		#if mobile
		removeTouchPad();
		addTouchPad("LEFT_FULL", "A_B_C_X_Y_Z");
		#end
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return !leWeek.startUnlocked && leWeek.weekBefore.length > 0 &&
			(!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) ||
			 !StoryMenuState.weekCompleted.get(leWeek.weekBefore));
	}

	override function update(elapsed:Float)
	{
		_animateScanlines(elapsed);
		_animateShine(elapsed);
		_animateParticles(elapsed);
		_animateGlow(elapsed);
		_animateAccentShine(elapsed);

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		lerpScore  = Math.floor(FlxMath.lerp(intendedScore,  lerpScore,  Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));
		if (Math.abs(lerpScore  - intendedScore)  <= 10)   lerpScore  = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;

		var ratingSplit = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2) ratingSplit.push('');
		while (ratingSplit[1].length < 2) ratingSplit[1] += '0';

		if (entering || exiting) { updateTexts(elapsed); super.update(elapsed); return; }

		#if mobile
		var shiftMult:Int = (FlxG.keys.pressed.SHIFT || touchPad.buttonZ.pressed) && !player.playingMusic ? 3 : 1;
		#else
		var shiftMult:Int = FlxG.keys.pressed.SHIFT && !player.playingMusic ? 3 : 1;
		#end

		if (!player.playingMusic)
		{
			scoreText.text = 'BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
			positionHighscore();

			if (songs.length > 1)
			{
				if (FlxG.keys.justPressed.HOME) { curSelected = 0; changeSelection(); holdTime = 0; }
				if (FlxG.keys.justPressed.END)  { curSelected = songs.length - 1; changeSelection(); holdTime = 0; }

				if (controls.UI_UP_P)   { changeSelection(-shiftMult); holdTime = 0; }
				if (controls.UI_DOWN_P) { changeSelection(shiftMult);  holdTime = 0; }

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold = Math.floor((holdTime - 0.5) * 10);
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (controls.UI_LEFT_P)       { changeDiff(-1); _updateSongLastDifficulty(); }
			else if (controls.UI_RIGHT_P) { changeDiff(1);  _updateSongLastDifficulty(); }
		}

		if (controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;
				player.playingMusic = false;
				player.switchPlayMusic();
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else
			{
				exiting = true;
				if (colorTween != null) colorTween.cancel();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				_playExitAnim(function() MusicBeatState.switchState(new MainMenuState()));
			}
		}

		#if mobile
		var ctrlPressed  = FlxG.keys.justPressed.CONTROL || touchPad.buttonC.justPressed;
		var spacePressed = FlxG.keys.justPressed.SPACE    || touchPad.buttonX.justPressed;
		var resetPressed = controls.RESET                 || touchPad.buttonY.justPressed;
		#else
		var ctrlPressed  = FlxG.keys.justPressed.CONTROL;
		var spacePressed = FlxG.keys.justPressed.SPACE;
		var resetPressed = controls.RESET;
		#end

		if (ctrlPressed && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
			#if mobile removeTouchPad(); #end
		}
		else if (spacePressed)
		{
			if (instPlaying != curSelected && !player.playingMusic)
				_previewSong();
			else if (instPlaying == curSelected && player.playingMusic)
				player.pauseOrResume(player.paused);
		}
		else if (controls.ACCEPT && !player.playingMusic)
		{
			_selectSong(elapsed);
		}
		else if (resetPressed && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			#if mobile removeTouchPad(); #end
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	function _previewSong()
	{
		destroyFreeplayVocals();
		FlxG.sound.music.volume = 0;
		Mods.currentModDirectory = songs[curSelected].folder;
		var poop = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
		PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());

		if (PlayState.SONG.needsVoices)
		{
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			FlxG.sound.list.add(vocals);
			vocals.persist = vocals.looped = true;
		}
		else if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
			vocals = null;
		}

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
		if (vocals != null) { vocals.play(); vocals.volume = 0.8; }
		instPlaying = curSelected;
		player.playingMusic = true;
		player.curTime = 0;
		player.switchPlayMusic();
	}

	function _selectSong(elapsed:Float)
	{
		persistentUpdate = false;
		var songLowercase = Paths.formatToSongPath(songs[curSelected].songName);
		var poop = Highscore.formatSong(songLowercase, curDifficulty);

		try
		{
			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			if (colorTween != null) colorTween.cancel();
		}
		catch (e:Dynamic)
		{
			var errorStr:String = e.toString();
			if (errorStr.startsWith('[file_contents,assets/data/'))
				errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length - 1);
			missingText.text = 'ERROR LOADING CHART:\n$errorStr';
			missingText.screenCenter(Y);
			missingText.visible = true;
			missingTextBG.visible = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			updateTexts(elapsed);
			super.update(elapsed);
			return;
		}

		exiting = true;
		_playExitAnim(function()
		{
			FlxG.sound.music.volume = 0;
			destroyFreeplayVocals();
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
			LoadingState.loadAndSwitchState(new PlayState());
		});
	}

	function _animateScanlines(elapsed:Float)
	{
		scanlineY  += 95 * elapsed;
		scanline2Y += 52 * elapsed;
		if (scanlineY  > FlxG.height) scanlineY  = -3;
		if (scanline2Y > FlxG.height) scanline2Y = -2;
		scanline.y  = scanlineY;
		scanline2.y = scanline2Y;
	}

	function _animateShine(elapsed:Float)
	{
		shineX += 150 * elapsed;
		if (shineX > FlxG.width + 80) shineX = -120;
		bgShine.x = shineX;
	}

	function _animateAccentShine(elapsed:Float)
	{
		accentShineX += 200 * elapsed;
		if (accentShineX > FlxG.width + 60) accentShineX = -60;
		accentBarShine.x = accentShineX;
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
		if (glowTimer > 1.6)
		{
			glowTimer = 0;
			titlePulse = !titlePulse;
			FlxTween.tween(titleGlow, {alpha: titlePulse ? 0.2 : 0.06}, 0.8, {ease: FlxEase.sineInOut});
		}
	}

	public static function destroyFreeplayVocals()
	{
		if (vocals != null) { vocals.stop(); vocals.destroy(); }
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic) return;

		curDifficulty += change;
		if (curDifficulty < 0)                         curDifficulty = Difficulty.list.length - 1;
		if (curDifficulty >= Difficulty.list.length)   curDifficulty = 0;

		#if !switch
		intendedScore  = Highscore.getScore(songs[curSelected].songName,  curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		diffText.text = Difficulty.list.length > 1
			? '< ' + lastDifficultyName.toUpperCase() + ' >'
			: lastDifficultyName.toUpperCase();

		positionHighscore();
		missingText.visible = missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic) return;

		_updateSongLastDifficulty();
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList = Difficulty.list;
		curSelected += change;
		if (curSelected < 0)             curSelected = songs.length - 1;
		if (curSelected >= songs.length) curSelected = 0;

		var newColor:Int = songs[curSelected].color;
		if (newColor != intendedColor)
		{
			if (colorTween != null) colorTween.cancel();
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 0.7, bg.color, intendedColor, {
				ease: FlxEase.sineOut,
				onComplete: function(_) { colorTween = null; }
			});

			var lightAccent = FlxColor.fromInt(newColor).getLightened(0.25);
			var darkCard    = FlxColor.fromInt(newColor).getDarkened(0.72);

			FlxTween.color(accentBar,    0.35, accentBar.color,    lightAccent);
			FlxTween.color(sideLine,     0.35, sideLine.color,     lightAccent);
			FlxTween.color(cardTag,      0.3,  cardTag.color,      lightAccent);
			FlxTween.color(selectedCard, 0.3,  selectedCard.color, darkCard);
		}

		songCountText.text = (curSelected + 1) + ' / ' + songs.length;

		var wIdx = songs[curSelected].week;
		var wName = (wIdx < WeekData.weeksList.length && WeekData.weeksLoaded.exists(WeekData.weeksList[wIdx]))
			? WeekData.weeksLoaded.get(WeekData.weeksList[wIdx]).weekName : '';
		weekText.text = wName.toUpperCase();

		for (i in 0...iconArray.length)
			iconArray[i].alpha = (i == curSelected) ? 1 : 0.5;

		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek      = songs[curSelected].week;
		Difficulty.loadFromWeek();

		var savedDiff = songs[curSelected].lastDifficulty;
		var lastDiff  = Difficulty.list.indexOf(lastDifficultyName);
		if (savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if (lastDiff > -1)
			curDifficulty = lastDiff;
		else if (Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);

	private function positionHighscore()
	{
		scoreText.x      = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x  = FlxG.width - scoreText.x + 6;
		scoreBG.x        = FlxG.width - scoreBG.scale.x / 2;
		diffText.x       = Std.int(scoreBG.x + scoreBG.width / 2 - diffText.width / 2);
	}

	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		var cardY = (lerpSelected * 1.3 - lerpSelected) * 80 + 200;
		if (grpSongs.members.length > 0)
		{
			var selItem = grpSongs.members[curSelected];
			if (selItem != null && selItem.visible)
			{
				selectedCard.y  = selItem.y - 2;
				selectedGlow.y  = selItem.y - 4;
				cardTag.y       = selItem.y - 2;
			}
		}

		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));

		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var isSel = (i == curSelected);
			item.alpha = FlxMath.lerp(item.alpha, isSel ? 1.0 : 0.45, 0.25);

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}

	override function destroy():Void
	{
		super.destroy();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}
}

class SongMetadata
{
	public var songName:String      = '';
	public var week:Int             = 0;
	public var songCharacter:String = '';
	public var color:Int            = -7179779;
	public var folder:String        = '';
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName      = song;
		this.week          = week;
		this.songCharacter = songCharacter;
		this.color         = color;
		this.folder        = Mods.currentModDirectory;
	}
}
