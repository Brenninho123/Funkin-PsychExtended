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

typedef Lesson =
{
	var title:String;
	var content:Array<String>;
	var question:String;
	var answers:Array<String>;
	var correctIndex:Int;
}

typedef Subject =
{
	var name:String;
	var icon:String;
	var color:Int;
	var teacher:String;
	var lessons:Array<Lesson>;
	var grade:Int;
	var completed:Array<Int>;
}

enum SchoolScreen
{
	SUBJECTS;
	LESSONS;
	TEACHING;
	QUIZ;
	RESULT;
}

class SchoolState extends MusicBeatState
{
	var subjects:Array<Subject> = [
		{
			name: 'Mathematics',
			icon: '📐',
			color: 0xFF4FC3F7,
			teacher: 'Prof. Senpai',
			grade: 0,
			completed: [],
			lessons: [
				{
					title: 'Lesson 1 — Equations',
					content: [
						'An equation is an equality between two expressions.',
						'Example:  2x + 4 = 10',
						'To solve: isolate the variable.',
						'2x = 10 - 4   →   2x = 6   →   x = 3',
						'Always do the same operation on both sides!'
					],
					question: 'If 3x - 6 = 9, what is the value of x?',
					answers: ['x = 3', 'x = 5', 'x = 4', 'x = 7'],
					correctIndex: 1
				},
				{
					title: 'Lesson 2 — Fractions',
					content: [
						'A fraction represents a part of a whole.',
						'Example:  1/2 means one half.',
						'To add fractions, equalize the denominators first.',
						'1/4 + 1/4 = 2/4 = 1/2',
						'To multiply: numerator × numerator / denominator × denominator.'
					],
					question: 'How much is 1/3 + 1/6?',
					answers: ['2/9', '1/2', '3/6', '2/3'],
					correctIndex: 1
				},
				{
					title: 'Lesson 3 — Geometry',
					content: [
						'Area of a square:    side × side',
						'Area of a rectangle: base × height',
						'Area of a triangle:  (base × height) / 2',
						'Perimeter = sum of all sides.',
						'A circle\'s area is π × radius².'
					],
					question: 'What is the area of a triangle with base 6 and height 4?',
					answers: ['24', '10', '12', '8'],
					correctIndex: 2
				},
			]
		},
		{
			name: 'Physics',
			icon: '⚡',
			color: 0xFFFFCC02,
			teacher: 'Prof. Daddy Dearest',
			grade: 0,
			completed: [],
			lessons: [
				{
					title: 'Lesson 1 — Motion',
					content: [
						'Motion is the change of position over time.',
						'Speed = Distance / Time',
						'Example: 100 m in 10 s = 10 m/s',
						'Acceleration = change in speed / time.',
						'A car going from 0 to 60 km/h in 6 s has 10 km/h/s acceleration.'
					],
					question: 'A car travels 200 m in 20 seconds. What is its speed?',
					answers: ['5 m/s', '20 m/s', '10 m/s', '15 m/s'],
					correctIndex: 2
				},
				{
					title: 'Lesson 2 — Forces',
					content: [
						'Force = Mass × Acceleration  (Newton\'s 2nd Law)',
						'Unit of force: Newton (N).',
						'A 10 kg object with 2 m/s² acceleration needs 20 N.',
						'Newton\'s 3rd Law: every action has an equal and opposite reaction.',
						'Gravity on Earth accelerates objects at ~9.8 m/s².'
					],
					question: 'What force is needed to accelerate 5 kg at 4 m/s²?',
					answers: ['9 N', '20 N', '1.25 N', '40 N'],
					correctIndex: 1
				},
				{
					title: 'Lesson 3 — Energy',
					content: [
						'Energy cannot be created or destroyed, only transformed.',
						'Kinetic Energy = (1/2) × mass × velocity²',
						'Potential Energy = mass × gravity × height',
						'Work = Force × Distance',
						'Power = Work / Time — measured in Watts.'
					],
					question: 'What is the kinetic energy of a 2 kg object at 3 m/s?',
					answers: ['6 J', '9 J', '12 J', '18 J'],
					correctIndex: 1
				},
			]
		},
		{
			name: 'History',
			icon: '📜',
			color: 0xFFCE93D8,
			teacher: 'Prof. Pico',
			grade: 0,
			completed: [],
			lessons: [
				{
					title: 'Lesson 1 — Ancient Civilizations',
					content: [
						'Mesopotamia is considered the cradle of civilization.',
						'Egypt developed along the Nile River around 3100 BC.',
						'The Greeks invented democracy in Athens, ~500 BC.',
						'The Roman Empire lasted from 27 BC to 476 AD.',
						'China\'s Great Wall was built to defend against invasions.'
					],
					question: 'Which civilization invented democracy?',
					answers: ['Romans', 'Egyptians', 'Greeks', 'Persians'],
					correctIndex: 2
				},
				{
					title: 'Lesson 2 — Middle Ages',
					content: [
						'The Middle Ages lasted from ~476 AD to ~1492 AD.',
						'Feudalism was the dominant social/political system.',
						'The Black Death killed ~1/3 of Europe\'s population.',
						'The Crusades were religious wars for the Holy Land.',
						'The Magna Carta (1215) limited the king\'s power.'
					],
					question: 'What social system dominated the Middle Ages?',
					answers: ['Capitalism', 'Feudalism', 'Socialism', 'Democracy'],
					correctIndex: 1
				},
				{
					title: 'Lesson 3 — Modern Age',
					content: [
						'The Modern Age began with Columbus\'s voyage in 1492.',
						'The Renaissance revived arts, science, and culture.',
						'The French Revolution (1789) ended the monarchy.',
						'The Industrial Revolution began in England ~1760.',
						'World War I lasted from 1914 to 1918.'
					],
					question: 'When did Columbus arrive in the Americas?',
					answers: ['1776', '1492', '1600', '1215'],
					correctIndex: 1
				},
			]
		},
		{
			name: 'Biology',
			icon: '🧬',
			color: 0xFF81C784,
			teacher: 'Prof. GF',
			grade: 0,
			completed: [],
			lessons: [
				{
					title: 'Lesson 1 — Cells',
					content: [
						'Cells are the basic unit of all living organisms.',
						'Prokaryotic cells have no nucleus (e.g. bacteria).',
						'Eukaryotic cells have a nucleus (e.g. animals, plants).',
						'The cell membrane controls what enters and exits.',
						'DNA carries the genetic information of an organism.'
					],
					question: 'Which type of cell has no nucleus?',
					answers: ['Eukaryotic', 'Animal cell', 'Plant cell', 'Prokaryotic'],
					correctIndex: 3
				},
				{
					title: 'Lesson 2 — Evolution',
					content: [
						'Charles Darwin proposed the Theory of Evolution in 1859.',
						'Natural selection favors traits that aid survival.',
						'Mutations in DNA can create new traits.',
						'Species that adapt to their environment survive longer.',
						'Fossils provide evidence of past life on Earth.'
					],
					question: 'Who proposed the Theory of Evolution?',
					answers: ['Newton', 'Einstein', 'Darwin', 'Mendel'],
					correctIndex: 2
				},
				{
					title: 'Lesson 3 — Ecosystems',
					content: [
						'An ecosystem is all living and non-living things in an area.',
						'Producers (plants) make energy from sunlight.',
						'Consumers eat producers or other consumers.',
						'Decomposers break down dead matter and recycle nutrients.',
						'Food chains show energy flow between organisms.'
					],
					question: 'What do decomposers do in an ecosystem?',
					answers: [
						'Produce energy from sunlight',
						'Hunt other animals',
						'Break down dead matter',
						'Absorb water from soil'
					],
					correctIndex: 2
				},
			]
		},
	];

	var currentScreen:SchoolScreen = SUBJECTS;
	var curSubject:Int  = 0;
	var curLesson:Int   = 0;
	var curPage:Int     = 0;
	var curAnswer:Int   = 0;
	var lastAnswerCorrect:Bool = false;
	var totalScore:Int  = 0;

	var entering:Bool = true;
	var exiting:Bool  = false;

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
	var subtitleText:FlxText;

	var mainPanel:FlxSprite;
	var mainPanelTag:FlxSprite;
	var contentText:FlxText;
	var teacherText:FlxText;
	var hintText:FlxText;
	var progressText:FlxText;
	var scoreText:FlxText;

	var subjectCards:FlxTypedGroup<FlxSprite>;
	var subjectTags:FlxTypedGroup<FlxSprite>;
	var subjectLabels:FlxTypedGroup<FlxText>;
	var subjectGrades:FlxTypedGroup<FlxText>;

	var lessonCards:FlxTypedGroup<FlxSprite>;
	var lessonTags:FlxTypedGroup<FlxSprite>;
	var lessonLabels:FlxTypedGroup<FlxText>;
	var lessonStatus:FlxTypedGroup<FlxText>;

	var answerCards:FlxTypedGroup<FlxSprite>;
	var answerTags:FlxTypedGroup<FlxSprite>;
	var answerLabels:FlxTypedGroup<FlxText>;

	var selectedGlow:FlxSprite;
	var selectedCard:FlxSprite;
	var cardTag:FlxSprite;

	var scanlineY:Float  = 0;
	var scanline2Y:Float = 360;
	var shineX:Float     = -120;
	var glowTimer:Float  = 0;
	var particleTimer:Float = 0;
	var particles:FlxTypedGroup<FlxSprite>;
	var particleSpeeds:Array<Float> = [];

	override function create()
	{
		persistentUpdate = true;

		_buildBG();
		_buildParticles();
		_buildUI();
		_showSubjects();

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
		bg.color = 0xFF222244;
		bg.alpha = 0;
		bg.scale.set(1.06, 1.06);
		add(bg);

		bgGrid = FlxGridOverlay.create(28, 28, FlxG.width, FlxG.height, true, 0x07FFFFFF, 0x00000000);
		bgGrid.scrollFactor.set();
		bgGrid.alpha = 0;
		add(bgGrid);

		vignette = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		vignette.scrollFactor.set();
		vignette.alpha = 0.5;
		add(vignette);

		scanline = new FlxSprite(0, 0).makeGraphic(FlxG.width, 3, 0x12FFFFFF);
		scanline.scrollFactor.set();
		add(scanline);

		scanline2 = new FlxSprite(0, 360).makeGraphic(FlxG.width, 2, 0x08FFFFFF);
		scanline2.scrollFactor.set();
		add(scanline2);

		bgShine = new FlxSprite(-120, 0).makeGraphic(80, FlxG.height, 0x0CFFFFFF);
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

		bottomBar = new FlxSprite(0, FlxG.height - 38).makeGraphic(FlxG.width, 38, 0xEE0A0A18);
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
			var p = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			p.makeGraphic(FlxG.random.int(1, 3), FlxG.random.int(1, 3), 0x22FFFFFF);
			p.scrollFactor.set();
			p.alpha = 0;
			particles.add(p);
			particleSpeeds.push(FlxG.random.float(0.2, 0.9));
		}
	}

	function _buildUI()
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

		subtitleText = new FlxText(FlxG.width - 12, 18, 0, '', 13);
		subtitleText.setFormat('VCR OSD Mono', 13, 0xFF546E7A, RIGHT);
		subtitleText.scrollFactor.set();
		add(subtitleText);

		selectedGlow = new FlxSprite(55, 200).makeGraphic(FlxG.width - 110, 62, 0x22FFFFFF);
		selectedGlow.scrollFactor.set();
		selectedGlow.alpha = 0;
		add(selectedGlow);

		selectedCard = new FlxSprite(62, 202).makeGraphic(FlxG.width - 124, 54, 0xFF14213D);
		selectedCard.scrollFactor.set();
		selectedCard.alpha = 0;
		add(selectedCard);

		cardTag = new FlxSprite(62, 202).makeGraphic(4, 54, 0xFF4FC3F7);
		cardTag.scrollFactor.set();
		cardTag.alpha = 0;
		add(cardTag);

		mainPanel = new FlxSprite(40, 70).makeGraphic(FlxG.width - 80, FlxG.height - 130, 0xCC0A0A22);
		mainPanel.scrollFactor.set();
		mainPanel.alpha = 0;
		add(mainPanel);

		mainPanelTag = new FlxSprite(40, 70).makeGraphic(4, FlxG.height - 130, 0xFF4FC3F7);
		mainPanelTag.scrollFactor.set();
		mainPanelTag.alpha = 0;
		add(mainPanelTag);

		teacherText = new FlxText(60, 80, FlxG.width - 120, '', 13);
		teacherText.setFormat('VCR OSD Mono', 13, 0xFFFFCC02, LEFT);
		teacherText.scrollFactor.set();
		add(teacherText);

		contentText = new FlxText(60, 108, FlxG.width - 120, '', 17);
		contentText.setFormat('VCR OSD Mono', 17, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		contentText.borderSize = 1;
		contentText.wordWrap = true;
		contentText.scrollFactor.set();
		add(contentText);

		progressText = new FlxText(60, 0, FlxG.width - 120, '', 12);
		progressText.setFormat('VCR OSD Mono', 12, 0xFF546E7A, RIGHT);
		progressText.scrollFactor.set();
		add(progressText);

		hintText = new FlxText(0, FlxG.height - 30, FlxG.width, '', 13);
		hintText.setFormat('VCR OSD Mono', 13, 0xFF78909C, CENTER);
		hintText.scrollFactor.set();
		add(hintText);

		scoreText = new FlxText(FlxG.width - 200, FlxG.height - 30, 190, '', 13);
		scoreText.setFormat('VCR OSD Mono', 13, 0xFFFFCC02, RIGHT);
		scoreText.scrollFactor.set();
		add(scoreText);

		subjectCards  = new FlxTypedGroup<FlxSprite>();
		subjectTags   = new FlxTypedGroup<FlxSprite>();
		subjectLabels = new FlxTypedGroup<FlxText>();
		subjectGrades = new FlxTypedGroup<FlxText>();
		lessonCards   = new FlxTypedGroup<FlxSprite>();
		lessonTags    = new FlxTypedGroup<FlxSprite>();
		lessonLabels  = new FlxTypedGroup<FlxText>();
		lessonStatus  = new FlxTypedGroup<FlxText>();
		answerCards   = new FlxTypedGroup<FlxSprite>();
		answerTags    = new FlxTypedGroup<FlxSprite>();
		answerLabels  = new FlxTypedGroup<FlxText>();

		add(subjectCards);  add(subjectTags);  add(subjectLabels);  add(subjectGrades);
		add(lessonCards);   add(lessonTags);   add(lessonLabels);   add(lessonStatus);
		add(answerCards);   add(answerTags);   add(answerLabels);
	}

	function _clearGroups()
	{
		subjectCards.clear();  subjectTags.clear();  subjectLabels.clear();  subjectGrades.clear();
		lessonCards.clear();   lessonTags.clear();   lessonLabels.clear();   lessonStatus.clear();
		answerCards.clear();   answerTags.clear();   answerLabels.clear();
		mainPanel.alpha    = 0;
		mainPanelTag.alpha = 0;
		contentText.text   = '';
		teacherText.text   = '';
		progressText.text  = '';
		selectedCard.alpha = 0;
		selectedGlow.alpha = 0;
		cardTag.alpha      = 0;
	}

	function _showSubjects()
	{
		_clearGroups();
		currentScreen = SUBJECTS;
		curSubject    = 0;

		subtitleText.text = 'Choose a subject';
		hintText.text     = '[ACCEPT] Enter   [BACK] Main Menu';
		scoreText.text    = 'Score: $totalScore';

		var spacing:Float = 78;
		var startY:Float  = 78;

		for (i in 0...subjects.length)
		{
			var s   = subjects[i];
			var col = FlxColor.fromInt(s.color);
			var cy  = startY + i * spacing;

			var card = new FlxSprite(62, cy).makeGraphic(FlxG.width - 124, 62, col.getDarkened(0.78));
			card.scrollFactor.set();
			card.alpha = 0;
			card.x    = -FlxG.width;
			subjectCards.add(card);

			var tag = new FlxSprite(62, cy).makeGraphic(4, 62, col);
			tag.scrollFactor.set();
			tag.alpha = 0;
			tag.x    = -FlxG.width;
			subjectTags.add(tag);

			var lbl = new FlxText(80, cy + 8, FlxG.width - 300, s.icon + '  ' + s.name, 20);
			lbl.setFormat('VCR OSD Mono', 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			lbl.borderSize = 1.5;
			lbl.scrollFactor.set();
			lbl.alpha = 0;
			lbl.x    = -FlxG.width;
			subjectLabels.add(lbl);

			var teacher = new FlxText(80, cy + 36, 300, s.teacher, 11);
			teacher.setFormat('VCR OSD Mono', 11, col.getLightened(0.3), LEFT);
			teacher.scrollFactor.set();
			teacher.alpha = 0;
			subjectLabels.add(teacher);

			var pct   = s.lessons.length > 0 ? Math.round(s.completed.length / s.lessons.length * 100) : 0;
			var grade = new FlxText(FlxG.width - 200, cy + 16, 170, 'Grade: ${s.grade}  (${pct}%)', 13);
			grade.setFormat('VCR OSD Mono', 13, col, RIGHT);
			grade.scrollFactor.set();
			grade.alpha = 0;
			subjectGrades.add(grade);

			var delay = i * 0.07;
			FlxTween.tween(card,    {alpha: 0.7,  x: 62},  0.45, {ease: FlxEase.expoOut, startDelay: delay});
			FlxTween.tween(tag,     {alpha: 1.0,  x: 62},  0.45, {ease: FlxEase.expoOut, startDelay: delay + 0.02});
			FlxTween.tween(lbl,     {alpha: 0.7,  x: 80},  0.45, {ease: FlxEase.expoOut, startDelay: delay + 0.03});
			FlxTween.tween(teacher, {alpha: 0.5},           0.45, {ease: FlxEase.quadOut, startDelay: delay + 0.05});
			FlxTween.tween(grade,   {alpha: 0.8},           0.4,  {ease: FlxEase.quadOut, startDelay: delay + 0.06});
		}

		FlxTween.tween(selectedCard, {alpha: 0.85}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(selectedGlow, {alpha: 0.3},  0.3, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(cardTag,      {alpha: 1.0},  0.3, {ease: FlxEase.quadOut, startDelay: 0.12});

		_updateSubjectSelection();
	}

	function _updateSubjectSelection()
	{
		for (i in 0...subjectCards.members.length)
		{
			var isSel = (i == curSubject);
			FlxTween.cancelTweensOf(subjectCards.members[i],  ['alpha']);
			FlxTween.cancelTweensOf(subjectLabels.members[i * 2], ['alpha']);
			FlxTween.tween(subjectCards.members[i],       {alpha: isSel ? 0.95 : 0.5},  0.15, {ease: FlxEase.quadOut});
			FlxTween.tween(subjectLabels.members[i * 2],  {alpha: isSel ? 1.0  : 0.45}, 0.15, {ease: FlxEase.quadOut});
		}

		if (subjectCards.members.length > 0)
		{
			var card = subjectCards.members[curSubject];
			var col  = FlxColor.fromInt(subjects[curSubject].color);

			selectedCard.y = card.y;
			selectedGlow.y = card.y - 4;
			cardTag.y      = card.y;

			FlxTween.color(topAccent,    0.3, topAccent.color,    col);
			FlxTween.color(sideAccent,   0.3, sideAccent.color,   col);
			FlxTween.color(cardTag,      0.25,cardTag.color,       col);
			FlxTween.color(selectedCard, 0.25,selectedCard.color,  col.getDarkened(0.78));
			FlxTween.color(selectedGlow, 0.25,selectedGlow.color,  col.getDarkened(0.55));
			FlxTween.color(mainPanelTag, 0.25,mainPanelTag.color,  col);
		}
	}

	function _showLessons()
	{
		_clearGroups();
		currentScreen = LESSONS;
		curLesson     = 0;

		var s   = subjects[curSubject];
		var col = FlxColor.fromInt(s.color);

		subtitleText.text = s.name + ' — Select a lesson';
		hintText.text     = '[ACCEPT] Start Lesson   [BACK] Subjects';

		var spacing:Float = 70;
		var startY:Float  = 78;

		for (i in 0...s.lessons.length)
		{
			var les    = s.lessons[i];
			var done   = s.completed.indexOf(i) >= 0;
			var cy     = startY + i * spacing;
			var lColor = done ? col.getLightened(0.1) : col.getDarkened(0.4);

			var card = new FlxSprite(62, cy).makeGraphic(FlxG.width - 124, 58, lColor.getDarkened(0.72));
			card.scrollFactor.set();
			card.alpha = 0;
			card.x    = -FlxG.width;
			lessonCards.add(card);

			var tag = new FlxSprite(62, cy).makeGraphic(4, 58, lColor);
			tag.scrollFactor.set();
			tag.alpha = 0;
			tag.x    = -FlxG.width;
			lessonTags.add(tag);

			var lbl = new FlxText(80, cy + 10, FlxG.width - 250, les.title, 18);
			lbl.setFormat('VCR OSD Mono', 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			lbl.borderSize = 1.5;
			lbl.scrollFactor.set();
			lbl.alpha = 0;
			lbl.x    = -FlxG.width;
			lessonLabels.add(lbl);

			var status = new FlxText(FlxG.width - 200, cy + 14, 170, done ? '✓ DONE' : 'NEW', 14);
			status.setFormat('VCR OSD Mono', 14, done ? 0xFF69F0AE : 0xFF546E7A, RIGHT);
			status.scrollFactor.set();
			status.alpha = 0;
			lessonStatus.add(status);

			var delay = i * 0.07;
			FlxTween.tween(card,   {alpha: 0.7,  x: 62},  0.45, {ease: FlxEase.expoOut, startDelay: delay});
			FlxTween.tween(tag,    {alpha: 1.0,  x: 62},  0.45, {ease: FlxEase.expoOut, startDelay: delay + 0.02});
			FlxTween.tween(lbl,    {alpha: 0.7,  x: 80},  0.45, {ease: FlxEase.expoOut, startDelay: delay + 0.03});
			FlxTween.tween(status, {alpha: 0.8},           0.4,  {ease: FlxEase.quadOut, startDelay: delay + 0.05});
		}

		FlxTween.tween(selectedCard, {alpha: 0.85}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(selectedGlow, {alpha: 0.3},  0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(cardTag,      {alpha: 1.0},  0.3, {ease: FlxEase.quadOut});

		_updateLessonSelection();
	}

	function _updateLessonSelection()
	{
		for (i in 0...lessonCards.members.length)
		{
			var isSel = (i == curLesson);
			FlxTween.cancelTweensOf(lessonCards.members[i],  ['alpha']);
			FlxTween.cancelTweensOf(lessonLabels.members[i], ['alpha']);
			FlxTween.tween(lessonCards.members[i],  {alpha: isSel ? 0.95 : 0.5},  0.15, {ease: FlxEase.quadOut});
			FlxTween.tween(lessonLabels.members[i], {alpha: isSel ? 1.0  : 0.45}, 0.15, {ease: FlxEase.quadOut});
		}

		if (lessonCards.members.length > 0)
		{
			var card = lessonCards.members[curLesson];
			selectedCard.y = card.y;
			selectedGlow.y = card.y - 4;
			cardTag.y      = card.y;
		}
	}

	function _showTeaching()
	{
		_clearGroups();
		currentScreen = TEACHING;
		curPage       = 0;

		var s   = subjects[curSubject];
		var les = s.lessons[curLesson];
		var col = FlxColor.fromInt(s.color);

		subtitleText.text  = s.name;
		hintText.text      = '[ACCEPT] Next Page   [BACK] Lessons';

		FlxTween.tween(mainPanel,    {alpha: 0.88}, 0.35, {ease: FlxEase.quadOut});
		FlxTween.tween(mainPanelTag, {alpha: 1.0},  0.35, {ease: FlxEase.quadOut});

		_updateTeachingPage();
	}

	function _updateTeachingPage()
	{
		var s   = subjects[curSubject];
		var les = s.lessons[curLesson];
		var col = FlxColor.fromInt(s.color);

		teacherText.text  = '👨‍🏫  ' + s.teacher + '   •   ' + les.title;
		progressText.text = 'Page ' + (curPage + 1) + ' / ' + les.content.length;
		progressText.y    = mainPanel.y + 8;

		var displayedContent = les.content.slice(0, curPage + 1).join('\n\n');
		contentText.text = displayedContent;
		contentText.alpha = 0;
		contentText.y    = 108;
		FlxTween.tween(contentText, {alpha: 1}, 0.35, {ease: FlxEase.quadOut});

		if (curPage < les.content.length - 1)
			hintText.text = '[ACCEPT] Next   [BACK] Lessons';
		else
			hintText.text = '[ACCEPT] Take the Quiz!   [BACK] Lessons';
	}

	function _showQuiz()
	{
		_clearGroups();
		currentScreen = QUIZ;
		curAnswer     = 0;

		var s   = subjects[curSubject];
		var les = s.lessons[curLesson];
		var col = FlxColor.fromInt(s.color);

		subtitleText.text = s.name + ' — Quiz';
		hintText.text     = '[UP/DOWN] Select   [ACCEPT] Confirm';

		FlxTween.tween(mainPanel,    {alpha: 0.88}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(mainPanelTag, {alpha: 1.0},  0.3, {ease: FlxEase.quadOut});

		teacherText.text = '🧪  Quiz Time!   ' + les.title;
		contentText.y    = 115;
		contentText.text = les.question;
		contentText.alpha = 0;
		FlxTween.tween(contentText, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});

		progressText.text = 'Choose the correct answer:';
		progressText.y    = 97;

		var ansColors:Array<Int> = [0xFF4FC3F7, 0xFF81C784, 0xFFFFCC02, 0xFFCE93D8];
		var startY:Float  = 310;
		var spacing:Float = 72;

		for (i in 0...les.answers.length)
		{
			var ac  = FlxColor.fromInt(ansColors[i]);
			var ay  = startY + i * spacing;

			var card = new FlxSprite(62, ay).makeGraphic(FlxG.width - 124, 58, ac.getDarkened(0.75));
			card.scrollFactor.set();
			card.alpha = 0;
			answerCards.add(card);

			var tag = new FlxSprite(62, ay).makeGraphic(4, 58, ac);
			tag.scrollFactor.set();
			tag.alpha = 0;
			answerTags.add(tag);

			var lbl = new FlxText(80, ay + 14, FlxG.width - 160, (i + 1) + '.  ' + les.answers[i], 17);
			lbl.setFormat('VCR OSD Mono', 17, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			lbl.borderSize = 1.5;
			lbl.scrollFactor.set();
			lbl.alpha = 0;
			answerLabels.add(lbl);

			var delay = i * 0.06 + 0.1;
			FlxTween.tween(card, {alpha: 0.6}, 0.4, {ease: FlxEase.quadOut, startDelay: delay});
			FlxTween.tween(tag,  {alpha: 1.0}, 0.4, {ease: FlxEase.quadOut, startDelay: delay + 0.02});
			FlxTween.tween(lbl,  {alpha: 0.6}, 0.4, {ease: FlxEase.quadOut, startDelay: delay + 0.03});
		}

		FlxTween.tween(selectedCard, {alpha: 0.9}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.15});
		FlxTween.tween(selectedGlow, {alpha: 0.4}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.15});
		FlxTween.tween(cardTag,      {alpha: 1.0}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.18});

		_updateAnswerSelection();
	}

	function _updateAnswerSelection()
	{
		for (i in 0...answerCards.members.length)
		{
			var isSel = (i == curAnswer);
			FlxTween.cancelTweensOf(answerCards.members[i],  ['alpha']);
			FlxTween.cancelTweensOf(answerLabels.members[i], ['alpha']);
			FlxTween.tween(answerCards.members[i],  {alpha: isSel ? 0.95 : 0.45}, 0.15, {ease: FlxEase.quadOut});
			FlxTween.tween(answerLabels.members[i], {alpha: isSel ? 1.0  : 0.4},  0.15, {ease: FlxEase.quadOut});
		}

		if (answerCards.members.length > 0)
		{
			var card = answerCards.members[curAnswer];
			selectedCard.y = card.y;
			selectedGlow.y = card.y - 4;
			cardTag.y      = card.y;
		}
	}

	function _confirmAnswer()
	{
		var s   = subjects[curSubject];
		var les = s.lessons[curLesson];

		lastAnswerCorrect = (curAnswer == les.correctIndex);

		if (lastAnswerCorrect)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			if (s.completed.indexOf(curLesson) < 0)
			{
				s.completed.push(curLesson);
				s.grade += 20;
				totalScore += 100;
			}
		}
		else
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		_showResult();
	}

	function _showResult()
	{
		_clearGroups();
		currentScreen = RESULT;

		var s   = subjects[curSubject];
		var col = FlxColor.fromInt(s.color);

		FlxTween.tween(mainPanel,    {alpha: 0.9}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(mainPanelTag, {alpha: 1.0}, 0.3, {ease: FlxEase.quadOut});

		if (lastAnswerCorrect)
		{
			teacherText.text = '🎉  Correct! Well done!';
			contentText.text = 'You got it right!\n\n+100 points added to your score.\n\nGrade in ' + s.name + ':  ' + s.grade + ' / ' + (s.lessons.length * 20);
			FlxTween.color(mainPanelTag, 0.3, mainPanelTag.color, FlxColor.fromInt(0xFF69F0AE));
		}
		else
		{
			var les = s.lessons[curLesson];
			teacherText.text = '❌  Wrong answer.';
			contentText.text = 'The correct answer was:\n\n' + les.answers[les.correctIndex] + '\n\nDon\'t give up! Try the lesson again.';
			FlxTween.color(mainPanelTag, 0.3, mainPanelTag.color, FlxColor.fromInt(0xFFEF9A9A));
		}

		contentText.alpha = 0;
		FlxTween.tween(contentText, {alpha: 1}, 0.4, {ease: FlxEase.quadOut});

		progressText.text = 'Total Score: $totalScore';
		progressText.y    = mainPanel.y + 8;

		scoreText.text = 'Score: $totalScore';
		hintText.text  = '[ACCEPT] Continue   [BACK] Lessons';

		subtitleText.text = lastAnswerCorrect ? 'Correct!' : 'Wrong!';
	}

	override function update(elapsed:Float)
	{
		_animateScanlines(elapsed);
		_animateShine(elapsed);
		_animateParticles(elapsed);
		_animateGlow(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		if (entering || exiting) { super.update(elapsed); return; }

		switch (currentScreen)
		{
			case SUBJECTS:
				if (controls.UI_UP_P)   { _subjectNav(-1); FlxG.sound.play(Paths.sound('scrollMenu')); }
				if (controls.UI_DOWN_P) { _subjectNav(1);  FlxG.sound.play(Paths.sound('scrollMenu')); }
				if (controls.BACK)      { _goBack(); }
				if (controls.ACCEPT)    { FlxG.sound.play(Paths.sound('confirmMenu')); _showLessons(); }

			case LESSONS:
				if (controls.UI_UP_P)   { _lessonNav(-1); FlxG.sound.play(Paths.sound('scrollMenu')); }
				if (controls.UI_DOWN_P) { _lessonNav(1);  FlxG.sound.play(Paths.sound('scrollMenu')); }
				if (controls.BACK)      { FlxG.sound.play(Paths.sound('cancelMenu')); _showSubjects(); }
				if (controls.ACCEPT)    { FlxG.sound.play(Paths.sound('confirmMenu')); _showTeaching(); }

			case TEACHING:
				if (controls.BACK)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					_showLessons();
				}
				if (controls.ACCEPT)
				{
					var les = subjects[curSubject].lessons[curLesson];
					if (curPage < les.content.length - 1)
					{
						curPage++;
						FlxG.sound.play(Paths.sound('scrollMenu'));
						_updateTeachingPage();
					}
					else
					{
						FlxG.sound.play(Paths.sound('confirmMenu'));
						_showQuiz();
					}
				}

			case QUIZ:
				if (controls.UI_UP_P)   { _answerNav(-1); FlxG.sound.play(Paths.sound('scrollMenu')); }
				if (controls.UI_DOWN_P) { _answerNav(1);  FlxG.sound.play(Paths.sound('scrollMenu')); }
				if (controls.BACK)      { FlxG.sound.play(Paths.sound('cancelMenu')); _showLessons(); }
				if (controls.ACCEPT)    { _confirmAnswer(); }

			case RESULT:
				if (controls.BACK || controls.ACCEPT)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					_showLessons();
				}
		}

		super.update(elapsed);
	}

	function _subjectNav(dir:Int)
	{
		curSubject += dir;
		if (curSubject < 0)                curSubject = subjects.length - 1;
		if (curSubject >= subjects.length) curSubject = 0;
		_updateSubjectSelection();
	}

	function _lessonNav(dir:Int)
	{
		curLesson += dir;
		var len = subjects[curSubject].lessons.length;
		if (curLesson < 0)    curLesson = len - 1;
		if (curLesson >= len) curLesson = 0;
		_updateLessonSelection();
	}

	function _answerNav(dir:Int)
	{
		curAnswer += dir;
		var len = subjects[curSubject].lessons[curLesson].answers.length;
		if (curAnswer < 0)    curAnswer = len - 1;
		if (curAnswer >= len) curAnswer = 0;
		_updateAnswerSelection();
	}

	function _goBack()
	{
		exiting = true;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		_playExitAnim(function() MusicBeatState.switchState(new MainMenuState()));
	}

	function _playEnterAnim()
	{
		FlxTween.tween(bg,        {alpha: 0.7, 'scale.x': 1.0, 'scale.y': 1.0}, 0.7, {ease: FlxEase.quadOut});
		FlxTween.tween(bgGrid,    {alpha: 1},   0.9, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(topBar,    {y: 0},       0.45,{ease: FlxEase.expoOut});
		FlxTween.tween(topAccent, {y: 52},      0.45,{ease: FlxEase.expoOut, startDelay: 0.03});
		FlxTween.tween(sideAccent,{x: 0},       0.4, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(bottomBar, {y: FlxG.height - 38}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.06});
		FlxTween.tween(titleGlow, {y: 13, alpha: 0.15}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.12});
		FlxTween.tween(titleText, {y: 14, alpha: 1},    0.5, {ease: FlxEase.expoOut, startDelay: 0.14});

		for (i in 0...particles.members.length)
			FlxTween.tween(particles.members[i],
				{alpha: FlxG.random.float(0.04, 0.2)},
				FlxG.random.float(0.4, 1.2),
				{ease: FlxEase.quadOut, startDelay: FlxG.random.float(0, 0.8)});

		new FlxTimer().start(0.6, function(_) { entering = false; });
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
		FlxTween.tween(mainPanel, {alpha: 0},  0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(selectedCard,{alpha: 0},0.3, {ease: FlxEase.quadIn});

		new FlxTimer().start(0.45, function(_) { onDone(); });
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
		shineX += 140 * elapsed;
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
		if (sideAccent  != null) sideAccent.alpha  = 0.5 + pulse * 0.5;
		if (titleGlow   != null) titleGlow.alpha   = 0.06 + pulse * 0.12;
	}
}
