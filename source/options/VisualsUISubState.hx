package options;

import audio.AudioAPI;
import objects.Note;
import objects.StrumNote;
import objects.Alphabet;

class VisualsUISubState extends BaseOptionsMenu
{
	public static var pauseMusics:Array<String> = ['None', 'Breakfast', 'Tea Time'];
	public static var eqPresets:Array<String>   = ['Flat', 'Bass Boost', 'Treble Boost', 'Vocal Boost', 'Cinema', 'Game'];

	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;

	public function new()
	{
		title    = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu';

		notes = new FlxTypedGroup<StrumNote>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			note.centerOffsets();
			note.centerOrigin();
			note.playAnim('static');
			notes.add(note);
		}

		var option:Option = new Option('Master Volume',
			'Overall game volume.',
			'masterVolume', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue    = 0.0;
		option.maxValue    = 1.0;
		option.changeValue = 0.05;
		option.decimals    = 2;
		option.onChange    = function() { AudioAPI.masterVolume = ClientPrefs.data.masterVolume; };
		addOption(option);

		var option:Option = new Option('Music Volume',
			'Volume of background music.',
			'musicVolume', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue    = 0.0;
		option.maxValue    = 1.0;
		option.changeValue = 0.05;
		option.decimals    = 2;
		option.onChange    = function() { AudioAPI.setMusicVolume(ClientPrefs.data.musicVolume); };
		addOption(option);

		var option:Option = new Option('SFX Volume',
			'Volume of sound effects.',
			'sfxVolume', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue    = 0.0;
		option.maxValue    = 1.0;
		option.changeValue = 0.05;
		option.decimals    = 2;
		option.onChange    = function() { AudioAPI.setSFXVolume(ClientPrefs.data.sfxVolume); };
		addOption(option);

		var option:Option = new Option('Vocal Volume',
			'Volume of character vocals during gameplay.',
			'vocalVolume', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue    = 0.0;
		option.maxValue    = 1.0;
		option.changeValue = 0.05;
		option.decimals    = 2;
		option.onChange    = function() { AudioAPI.setVocalVolume(ClientPrefs.data.vocalVolume); };
		addOption(option);

		var option:Option = new Option('Mute Audio',
			'If checked, mutes all game audio.',
			'masterMuted', 'bool');
		option.onChange = function() { AudioAPI.masterMuted = ClientPrefs.data.masterMuted; };
		addOption(option);

		var option:Option = new Option('EQ Preset',
			'Audio equalizer preset. Flat means no changes.',
			'eqPreset', 'string', eqPresets);
		option.onChange = function()
		{
			if (ClientPrefs.data.eqPreset != null)
				AudioAPI.eqPreset(ClientPrefs.data.eqPreset.toLowerCase());
		};
		addOption(option);

		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if (noteSkins.length > 0)
		{
			if (!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin;

			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin);

			var option:Option = new Option('Note Skins:',
				'Select your preferred note skin.',
				'noteSkin', 'string', noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}

		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if (noteSplashes.length > 0)
		{
			if (!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin;

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin);

			var option:Option = new Option('Note Splashes:',
				'Select your preferred note splash variation or turn it off.',
				'splashSkin', 'string', noteSplashes);
			addOption(option);
		}

		var option:Option = new Option('Note Splash Opacity',
			'How transparent should note splashes be.',
			'splashAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue    = 0.0;
		option.maxValue    = 1.0;
		option.changeValue = 0.1;
		option.decimals    = 1;
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud', 'bool');
		addOption(option);

		var option:Option = new Option('Time Bar:',
			'What should the time bar display?',
			'timeBarType', 'string',
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			'Uncheck this if you are sensitive to flashing lights.',
			'flashing', 'bool');
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			'If unchecked, the camera will not zoom in on a beat hit.',
			'camZooms', 'bool');
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit',
			'If unchecked, disables score text zooming when hitting a note.',
			'scoreZoom', 'bool');
		addOption(option);

		var option:Option = new Option('Health Bar Opacity',
			'How transparent should the health bar and icons be.',
			'healthBarAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue    = 0.0;
		option.maxValue    = 1.0;
		option.changeValue = 0.1;
		option.decimals    = 1;
		addOption(option);

		var option:Option = new Option('FPS Counter',
			'If unchecked, hides the FPS counter.',
			'showFPS', 'bool');
		option.onChange = onChangeFPSCounter;
		addOption(option);

		#if sys
		var option:Option = new Option('VSync',
			'Enables VSync, fixing screen tearing at the cost of capping FPS to your display refresh rate.\n(Requires game restart)',
			'vsync', 'bool');
		option.onChange = onChangeVSync;
		addOption(option);
		#end

		var option:Option = new Option('Pause Screen Song:',
			'Which song plays on the pause screen?',
			'pauseMusic', 'string', pauseMusics);
		option.onChange = onChangePauseMusic;
		addOption(option);

		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			'On release builds, checks for updates when the game starts.',
			'checkForUpdates', 'bool');
		addOption(option);
		#end

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			'Uncheck to hide the game from your Discord activity.',
			'discordRPC', 'bool');
		addOption(option);
		#end

		var option:Option = new Option('Combo Stacking',
			'If unchecked, ratings and combo will not stack, saving memory and improving readability.',
			'comboStacking', 'bool');
		addOption(option);

		super();
		add(notes);
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);

		if (noteOptionID < 0) return;

		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = notes.members[i];
			if (notesTween[i] != null) notesTween[i].cancel();
			if (curSelected == noteOptionID)
				notesTween[i] = FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
			else
				notesTween[i] = FlxTween.tween(note, {y: -200},  Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
		}
	}

	var changedMusic:Bool = false;

	function onChangePauseMusic()
	{
		if (ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	function onChangeNoteSkin()
	{
		notes.forEachAlive(function(note:StrumNote)
		{
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function changeNoteSkin(note:StrumNote)
	{
		var skin:String       = Note.defaultNoteSkin;
		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
		note.texture = skin;
		note.reloadNote();
		note.playAnim('static');
	}

	override function destroy()
	{
		if (changedMusic && !OptionsState.onPlayState)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		super.destroy();
	}

	function onChangeFPSCounter()
	{
		if (Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
	}

	#if sys
	function onChangeVSync()
	{
		var file:String = StorageUtil.rootDir + 'vsync.txt';
		if (FileSystem.exists(file)) FileSystem.deleteFile(file);
		File.saveContent(file, Std.string(ClientPrefs.data.vsync));
	}
	#end
}
