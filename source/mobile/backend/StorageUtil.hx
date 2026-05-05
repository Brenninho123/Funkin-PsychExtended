package mobile.backend;

import lime.system.System as LimeSystem;
import haxe.io.Path;
import haxe.Exception;
#if android
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#elseif sys
import sys.FileSystem;
import sys.io.File;
#end

class StorageUtil
{
	#if sys
	public static final rootDir:String = LimeSystem.applicationStorageDirectory;

	static var _cachedPath:String = null;

	public static function getStorageDirectory(?force:Bool = false):String
	{
		#if android
		if (!force && _cachedPath != null)
			return _cachedPath;

		var typeFile = rootDir + 'storagetype.txt';
		if (!FileSystem.exists(typeFile))
			File.saveContent(typeFile, ClientPrefs.data.storageType);

		var curType:String = '';
		try { curType = File.getContent(typeFile).trim(); }
		catch (_) { curType = ClientPrefs.data.storageType; }

		var path = force ? StorageType.fromStrForce(curType) : StorageType.fromStr(curType);
		path = Path.addTrailingSlash(path);

		if (!force) _cachedPath = path;
		return path;

		#elseif ios
		return Path.addTrailingSlash(LimeSystem.documentsDirectory);

		#else
		return Path.addTrailingSlash(Sys.getCwd());
		#end
	}

	public static function ensureDirectory(path:String):Bool
	{
		try
		{
			if (!FileSystem.exists(path))
				FileSystem.createDirectory(path);
			return true;
		}
		catch (e:Exception)
		{
			trace('StorageUtil: failed to create directory "$path" — ${e.message}');
			return false;
		}
	}

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Bool
	{
		try
		{
			ensureDirectory('saves');
			File.saveContent('saves/$fileName', fileData);
			if (alert) CoolUtil.showPopUp('$fileName saved successfully.', 'Success!');
			return true;
		}
		catch (e:Exception)
		{
			var msg = '$fileName could not be saved.\n(${e.message})';
			if (alert) CoolUtil.showPopUp(msg, 'Error!');
			else trace(msg);
			return false;
		}
	}

	public static function loadContent(fileName:String):Null<String>
	{
		var path = 'saves/$fileName';
		try
		{
			if (FileSystem.exists(path))
				return File.getContent(path);
		}
		catch (e:Exception)
		{
			trace('StorageUtil: failed to load "$path" — ${e.message}');
		}
		return null;
	}

	public static function deleteContent(fileName:String):Bool
	{
		var path = 'saves/$fileName';
		try
		{
			if (FileSystem.exists(path))
			{
				FileSystem.deleteFile(path);
				return true;
			}
		}
		catch (e:Exception)
		{
			trace('StorageUtil: failed to delete "$path" — ${e.message}');
		}
		return false;
	}

	public static function listSaves():Array<String>
	{
		try
		{
			if (FileSystem.exists('saves'))
				return FileSystem.readDirectory('saves');
		}
		catch (e:Exception)
		{
			trace('StorageUtil: failed to list saves — ${e.message}');
		}
		return [];
	}

	#if android
	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO']);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		if (!AndroidEnvironment.isExternalStorageManager())
		{
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.S)
				AndroidSettings.requestSetting('REQUEST_MANAGE_MEDIA');
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}

		var granted = AndroidPermissions.getGrantedPermissions();
		var permOk = AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU
			? granted.contains('android.permission.READ_MEDIA_IMAGES')
			: granted.contains('android.permission.READ_EXTERNAL_STORAGE');

		if (!permOk)
			CoolUtil.showPopUp(
				'If you accepted the permissions you are good to go!\nIf not, expect a crash.\nPress OK to continue.',
				'Notice!'
			);

		var storageDir = getStorageDirectory();
		if (!ensureDirectory(storageDir))
		{
			CoolUtil.showPopUp(
				'Could not create storage directory:\n${getStorageDirectory(true)}\nPress OK to close.',
				'Error!'
			);
			LimeSystem.exit(1);
		}

		_cachedPath = null;
	}

	public static function checkExternalPaths(?splitStorage:Bool = false):Array<String>
	{
		try
		{
			var process = new Process('grep -o "/storage/....-...." /proc/mounts | paste -sd \',\'');
			var raw = process.stdout.readAll().toString().trim();
			process.close();
			if (splitStorage) raw = raw.replace('/storage/', '');
			var result = raw.split(',');
			return result.filter(p -> p.length > 0);
		}
		catch (e:Exception)
		{
			trace('StorageUtil: checkExternalPaths failed — ${e.message}');
			return [];
		}
	}

	public static function getExternalDirectory(externalDir:String):String
	{
		for (path in checkExternalPaths())
			if (path.contains(externalDir))
				return Path.addTrailingSlash(path.trim());
		return '';
	}

	public static function getAvailableStorageTypes():Array<String>
	{
		var types:Array<String> = ['EXTERNAL_DATA', 'EXTERNAL_OBB', 'EXTERNAL_MEDIA', 'EXTERNAL'];
		for (path in checkExternalPaths(true))
			if (path.trim().length > 0) types.push(path.trim());
		return types;
	}

	public static function getFreeSpace(?path:String):Int
	{
		if (path == null) path = getStorageDirectory();
		try
		{
			var proc = new Process('df -k "$path" | tail -1 | awk \'{print $4}\'');
			var result = proc.stdout.readAll().toString().trim();
			proc.close();
			return Std.parseInt(result) ?? 0;
		}
		catch (_) { return 0; }
	}

	public static function changeStorageType(newType:String):Void
	{
		try
		{
			File.saveContent(rootDir + 'storagetype.txt', newType);
			_cachedPath = null;
			ensureDirectory(getStorageDirectory());
		}
		catch (e:Exception)
		{
			trace('StorageUtil: failed to change storage type — ${e.message}');
		}
	}
	#end
	#end
}

#if android
@:runtimeValue
enum abstract StorageType(String) from String to String
{
	static inline final FORCED_PATH:String  = '/storage/emulated/0/';
	static inline final PKG_NAME:String     = 'com.brenninho.psychengine';
	static inline final FILE_NAME:String    = 'PsychEngine';

	var EXTERNAL_DATA  = "EXTERNAL_DATA";
	var EXTERNAL_OBB   = "EXTERNAL_OBB";
	var EXTERNAL_MEDIA = "EXTERNAL_MEDIA";
	var EXTERNAL       = "EXTERNAL";

	public static function fromStr(str:String):StorageType
	{
		var pkg  = lime.app.Application.current.meta.get('packageName');
		var file = lime.app.Application.current.meta.get('file');
		var ext  = AndroidEnvironment.getExternalStorageDirectory();

		return switch (str.trim())
		{
			case "EXTERNAL_DATA":  AndroidContext.getExternalFilesDir();
			case "EXTERNAL_OBB":   AndroidContext.getObbDir();
			case "EXTERNAL_MEDIA": '$ext/Android/media/$pkg';
			case "EXTERNAL":       '$ext/.$file';
			default:               StorageUtil.getExternalDirectory(str) + '.$FILE_NAME';
		}
	}

	public static function fromStrForce(str:String):StorageType
	{
		return switch (str.trim())
		{
			case "EXTERNAL_DATA":  '${FORCED_PATH}Android/data/$PKG_NAME/files';
			case "EXTERNAL_OBB":   '${FORCED_PATH}Android/obb/$PKG_NAME';
			case "EXTERNAL_MEDIA": '${FORCED_PATH}Android/media/$PKG_NAME';
			case "EXTERNAL":       '${FORCED_PATH}.$FILE_NAME';
			default:               StorageUtil.getExternalDirectory(str) + '.$FILE_NAME';
		}
	}

	public static function getDisplayName(type:String):String
	{
		return switch (type.trim())
		{
			case "EXTERNAL_DATA":  'External Data (Android/data)';
			case "EXTERNAL_OBB":   'External OBB (Android/obb)';
			case "EXTERNAL_MEDIA": 'External Media (Android/media)';
			case "EXTERNAL":       'External Root';
			default:               'Custom ($type)';
		}
	}
}
#end