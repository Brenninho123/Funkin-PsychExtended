package states.school;

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

typedef SchoolWeek =
{
	var name:String;
	var songs:Array<String>;
	var description:String;
	var color:Int;
	var locked:Bool;
}

class SchoolState extends MusicBeatState
{
	var weeks:Array<SchoolWeek> = [
		{name: 'Tutorial',  songs: ['tutorial'],                       description: 'Learn the basics.',           color: 0xFF4FC3F7, locked: false},
		{name: 'Week 1',    songs: ['bopeebo', 'fresh', 'dadbattle'], description: 'Face your girlfriend\'s dad.', color: 0xFFF48FB1, locked: false},
		{name: 'Week 2',    songs: ['spookeez', 'south', 'monster'],  description: 'A spooky scary week.',        color: 0xFF81C784, locked: false},
		{name: 'Week 3',    songs: ['pico', 'philly', 'blammed'],     description: 'The streets are tough.',      color: 0xFFFFCC02, locked: false},
		{name: 'Week 4',    songs: ['satin-panties', 'high', 'milf'], description: 'A luxurious challenge.',      color: 0xFFCE93D8, locked: false},
		{name: 'Week 5',    songs: ['cocoa', 'eggnog', 'winter-horrorland'], description: 'Holiday madness.',     color: 0xFF80DEEA, locked: false},
		{name: 'Week 6',    songs: ['senpai', 'roses', 'thorns'],     description: 'A schoolyard romance.',       color: 0xFFFF8A65, locked: false},
		{name: 'Week 7',    songs: ['ugh', 'guns', 'stress'],         description: 'Military precision.',         color: 0xFFB0BEC5, locked: false},
	];

	var curSelected:Int = 0;
	var entering:Bool   = true;
	var exiting:Bool    = false;

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
	var counterText:FlxText;
	var descText:FlxText;
	var songListText:FlxText;

	var cards:FlxTypedGroup<FlxSprite>;
	var cardTags:FlxTypedGroup<FlxSprite>;
	var weekLabels:FlxTypedGroup<FlxText>;
	var lockIcons:FlxTypedGroup<FlxText>;

	var selectedCard:FlxSprite;
	var selectedGlow:FlxSprite;
	var cardTag:FlxSprite;

	var particles:FlxTypedGroup<FlxSprite>;
	var particleSpeeds:Array<Float> = [];
	var particleTimer:Float  = 0;
	var scanlineY:Float  = 0;
	var scanline2Y:Float = 360;
	var shineX:Float     = -120;
	var glowTimer:Float  = 0;

	override function create()
	{
		persistentUpdate = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("School Menu", null);
		#end

		_buildBG();
		_buildParticles();
		_buildCards();
		_buildHUD();

		changeSelection(0, false);

		#if mobile
		addTouchPad("UP_DOWN", "A_B");
		#end

		super.create();

		_playEnterAnim();
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

		bgGrid = FlxGridOverlay.create(30, 30, FlxG.width, FlxG.height, true, 0x07FFFFFF, 0x00000000);
		bgGrid.scrollFactor.set();
		bgGrid.alpha = 0;
		add(bgGrid);

		vignette = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		vignette.scrollFactor.set();
		vignette.alpha = 0.45;
		add(vignette);

		scanline = new FlxSprite(0, 0).makeGraphic(FlxG.width, 3, 0x14FFFFFF);
		scanline.scrollFactor.set();
		add(scanline);

		scanline2 = new FlxSprite(0, 360).makeGraphic(FlxG.width, 2, 0x08FFFFFF);
		scanline2.scrollFactor.set();
		add(scanline2);

		bgShine = new FlxSprite(-120, 0).makeGraphic(80, FlxG.height, 0x0EFFFFFF);
		bgShine.scrollFactor.set();
		add(bgShine);

		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 52, 0xDD0D0D1A);
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

		bottomBar = new FlxSprite(0, FlxG.height - 56).makeGraphic(FlxG.width, 56, 0xDD0D0D1A);
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
			p.makeGraphic(size, size, 0x24FFFFFF);
			p.scrollFactor.set();
			p.alpha = 0;
			particles.add(p);
			particleSpeeds.push(FlxG.random.float(0.2, 0.9));
		}
	}

	function _buildCards()
	{
		selectedGlow = new FlxSprite(55, 0).makeGraphic(FlxG.width - 110, 62, 0x22FFFFFF);
		selectedGlow.scrollFactor.set();
		selectedGlow.alpha = 0;
		add(selectedGlow);

		selectedCard = new FlxSprite(62, 0).makeGraphic(FlxG.width - 124, 54, 0xFF14213D);
		selectedCard.scrollFactor.set();
		selectedCard.alpha = 0;
		add(selectedCard);

		cardTag = new FlxSprite(62, 0).makeGraphic(4, 54, 0xFF4FC3F7);
		cardTag.scrollFactor.set();
		cardTag.alpha = 0;
		add(cardTag);

		cards      = new FlxTypedGroup<FlxSprite>();
		cardTags   = new FlxTypedGroup<FlxSprite>();
		weekLabels = new FlxTypedGroup<FlxText>();
		lockIcons  = new FlxTypedGroup<FlxText>();
		add(cards);
		add(cardTags);
		add(weekLabels);
		add(lockIcons);

		var spacing:Float = 72;
		var totalH:Float  = weeks.length * spacing;
		var startY:Float  = (FlxG.height - totalH) / 2 + 28;

		for (i in 0...weeks.length)
		{
			var w   = weeks[i];
			var col = FlxColor.fromInt(w.color);
			var cy  = startY + i * spacing;

			var card = new FlxSprite(62, cy - 4).makeGraphic(FlxG.width - 124, 54, col.getDarkened(0.75));
			card.scrollFactor.set();
			card.alpha = 0;
			card.x    = -FlxG.width;
			cards.add(card);

			var tag = new FlxSprite(62, cy - 4).makeGraphic(4, 54, col);
			tag.scrollFactor.set();
			tag.alpha = 0;
			tag.x    = -FlxG.width;
			cardTags.add(tag);

			var lbl = new FlxText(80, cy + 8, FlxG.width - 160, w.name, 20);
			lbl.setFormat('VCR OSD Mono', 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			lbl.borderSize = 1.5;
			lbl.scrollFactor.set();
			lbl.alpha = 0;
			lbl.x    = -FlxG.width;
			weekLabels.add(lbl);

			if (w.locked)
			{
				var lock = new FlxText(FlxG.width - 80, cy + 10, 60, '🔒', 18);
				lock.setFormat('VCR OSD Mono', 18, 0xFF546E7A, RIGHT);
				lock.scrollFactor.set();
				lock.alpha = 0;
				lockIcons.add(lock);
			}
			else
			{
				lockIcons.add(new FlxText(0, 0, 0, '', 1));
			}
		}
	}

	function _buildHUD()
	{
		titleGlow = new FlxText(12, 13, 0, 'SCHOOL', 22);
		titleGlow.setFormat('VCR OSD Mono', 22, 0xFF4FC3F7, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF4FC3F7);
		titleGlow.borderSize = 5;
		titleGlow.scrollFactor.set();
		titleGlow.alpha = 0;
		titleGlow.y = -50;
		add(titleGlow);

		titleText = new FlxText(12, 14, 0, 'SCHOOL', 22);
		titleText.setFormat('VCR OSD Mono', 22, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		titleText.scrollFactor.set();
		titleText.alpha = 0;
		titleText.y = -50;
		add(titleText);

		counterText = new FlxText(FlxG.width - 120, 17, 110, '', 13);
		counterText.setFormat('VCR OSD Mono', 13, 0xFF546E7A, RIGHT);
		counterText.scrollFactor.set();
		counterText.alpha = 0;
		add(counterText);

		descText = new FlxText(12, FlxG.height - 50, FlxG.width - 24, '', 14);
		descText.setFormat('VCR OSD Mono', 14, 0xFFB0BEC5, LEFT);
		descText.scrollFactor.set();
		descText.alpha = 0;
		add(descText);

		songListText = new FlxText(12, FlxG.height - 30, FlxG.width - 24, '', 11);
		songListText.setFormat('VCR OSD Mono', 11, 0xFF546E7A, LEFT);
		songListText.scrollFactor.set();
		songListText.alpha = 0;
		add(songListText);
	}

	function _playEnterAnim()
	{
		FlxTween.tween(bg,        {alpha: 0.72, 'scale.x': 1.0, 'scale.y': 1.0}, 0.7, {ease: FlxEase.quadOut});
		FlxTween.tween(bgGrid,    {alpha: 1},   0.9, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(topBar,    {y: 0},       0.45,{ease: FlxEase.expoOut});
		FlxTween.tween(topAccent, {y: 52},      0.45,{ease: FlxEase.expoOut, startDelay: 0.03});
		FlxTween.tween(sideAccent,{x: 0},       0.4, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(bottomBar, {y: FlxG.height - 56}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.06});

		FlxTween.tween(titleGlow, {y: 13, alpha: 0.15}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.12});
		FlxTween.tween(titleText, {y: 14, alpha: 1},    0.5, {ease: FlxEase.expoOut, startDelay: 0.14});
		FlxTween.tween(counterText, {alpha: 1},         0.4, {ease: FlxEase.quadOut, startDelay: 0.3});
		FlxTween.tween(descText,    {alpha: 1},         0.4, {ease: FlxEase.quadOut, startDelay: 0.35});
		FlxTween.tween(songListText,{alpha: 1},         0.4, {ease: FlxEase.quadOut, startDelay: 0.38});

		FlxTween.tween(selectedCard, {alpha: 0.85}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(selectedGlow, {alpha: 0.3},  0.4, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(cardTag,      {alpha: 1},    0.4, {ease: FlxEase.quadOut, startDelay: 0.25});

		for (i in 0...weeks.length)
		{
			var delay = 0.12 + i * 0.055;
			var card  = cards.members[i];
			var tag   = cardTags.members[i];
			var lbl   = weekLabels.members[i];
			FlxTween.tween(card, {alpha: 0.6, x: 62},   0.5, {ease: FlxEase.expoOut, startDelay: delay});
			FlxTween.tween(tag,  {alpha: 1.0, x: 62},   0.5, {ease: FlxEase.expoOut, startDelay: delay + 0.02});
			FlxTween.tween(lbl,  {alpha: 0.6, x: 80},   0.5, {ease: FlxEase.expoOut, startDelay: delay + 0.04});
		}

		for (i in 0...particles.members.length)
			FlxTween.tween(particles.members[i],
				{alpha: FlxG.random.float(0.04, 0.2)},
				FlxG.random.float(0.4, 1.2),
				{ease: FlxEase.quadOut, startDelay: FlxG.random.float(0, 0.8)});

		new FlxTimer().start(0.5 + weeks.length * 0.055 + 0.1, function(_) { entering = false; });
	}

	function _playExitAnim(onDone:Void->Void)
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
		FlxTween.tween(descText,    {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
		FlxTween.tween(songListText,{alpha: 0}, 0.2, {ease: FlxEase.quadIn});

		for (i in 0...weeks.length)
		{
			if (i == curSelected) continue;
			FlxTween.tween(cards.members[i],      {alpha: 0, x: cards.members[i].x + 250},      0.28, {ease: FlxEase.expoIn, startDelay: i * 0.02});
			FlxTween.tween(weekLabels.members[i], {alpha: 0, x: weekLabels.members[i].x + 250}, 0.28, {ease: FlxEase.expoIn, startDelay: i * 0.02});
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
			FlxG.sound.music.volume += 0.5 * elapsed;

		if (entering || exiting) { super.update(elapsed); return; }

		if (controls.UI_UP_P)   changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (FlxG.mouse.wheel != 0)
			changeSelection(-FlxG.mouse.wheel);

		if (controls.BACK)
		{
			exiting = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			_playExitAnim(function() MusicBeatState.switchState(new MainMenuState()));
		}
		else if (controls.ACCEPT)
		{
			if (weeks[curSelected].locked)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			else
			{
				exiting = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				_playExitAnim(function()
				{
					PlayState.isStoryMode = true;
					MusicBeatState.switchState(new StoryMenuState());
				});
			}
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var prev = curSelected;
		curSelected += change;
		if (curSelected < 0)            curSelected = weeks.length - 1;
		if (curSelected >= weeks.length) curSelected = 0;

		for (i in 0...weeks.length)
		{
			var isSel = (i == curSelected);
			var col   = FlxColor.fromInt(weeks[i].color);

			FlxTween.cancelTweensOf(cards.members[i],      ['alpha']);
			FlxTween.cancelTweensOf(weekLabels.members[i], ['alpha']);
			FlxTween.tween(cards.members[i],      {alpha: isSel ? 0.9 : 0.5}, 0.15, {ease: FlxEase.quadOut});
			FlxTween.tween(weekLabels.members[i], {alpha: isSel ? 1.0 : 0.45},0.15, {ease: FlxEase.quadOut});
		}

		var w   = weeks[curSelected];
		var col = FlxColor.fromInt(w.color);

		FlxTween.color(topAccent,    0.3, topAccent.color,    col);
		FlxTween.color(sideAccent,   0.3, sideAccent.color,   col);
		FlxTween.color(cardTag,      0.25,cardTag.color,       col);
		FlxTween.color(selectedCard, 0.25,selectedCard.color,  col.getDarkened(0.78));
		FlxTween.color(selectedGlow, 0.25,selectedGlow.color,  col.getDarkened(0.55));

		var card = cards.members[curSelected];
		if (card != null)
		{
			selectedCard.y  = card.y;
			selectedGlow.y  = card.y - 4;
			cardTag.y       = card.y;
		}

		counterText.text  = (curSelected + 1) + ' / ' + weeks.length;
		descText.text     = w.description;
		songListText.text = 'Songs: ' + w.songs.join('  •  ').toUpperCase();
	}

	function _animateScanlines(elapsed:Float)
	{
		scanlineY  += 88 * elapsed;
		scanline2Y += 48 * elapsed;
		if (scanlineY  > FlxG.height) scanlineY  = -3;
		if (scanline2Y > FlxG.height) scanline2Y = -2;
		scanline.y  = scanlineY;
		scanline2.y = scanline2Y;
	}

	function _animateShine(elapsed:Float)
	{
		shineX += 145 * elapsed;
		if (shineX > FlxG.width + 80) shineX = -120;
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
		var pulse = (Math.sin(glowTimer * 2.0) + 1) / 2;
		if (sideAccent != null) sideAccent.alpha = 0.55 + pulse * 0.45;
		if (titleGlow  != null) titleGlow.alpha  = 0.06 + pulse * 0.12;
	}
}
