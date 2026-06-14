package flixel.nx;

#if !switch
#error "This file should only be compiled for the Nintendo Switch target"
#end

import cpp.Pointer;

import switchLib.applets.Error;
import switchLib.applets.Error.ErrorApplicationConfig;
import switchLib.services.Set;
import switchLib.Result;
import switchLib.Types.ResultType;
import switchLib.services.Applet;

/**
 * States of the applet (Current program).
 */
enum AppletStateMode
{
	/**
	 * The applet/program is in focus.
	 */
	APP_IN_FOCUS;

	/**
	 * The applet/program is out of focus.
	 */
	APP_OUT_OF_FOCUS;

	/**
	 * The applet/program is suspended (In HOME menu or the console is sleeping).
	 */
	APP_SUSPENDED;

	/**
	 * Unknown state.
	 */
	APP_UNKNOWN;
}

/**
 * A class that holds information about the Nintendo Switch console.
 */
class FlxSwitch
{
	/**
	 * The current version of the Nintendo Switch OS (horizon OS).
	 */
	public static var SWITCH_VERSION(get, never):String;

	/**
	 * The current version of the Nintendo Switch OS (horizon OS) as an integer.
	 */
	public static var SWITCH_VERSION_INT(get, never):Null<Int>;

	/**
	 * The current version of Atmosphère (Custom OS).
	 */
	public static var ATMOSPHERE_VERSION(get, never):String;

	/**
	 * The current version of Atmosphère (Custom OS) as an integer.
	 */
	public static var ATMOSPHERE_VERSION_INT(get, never):Null<Int>;

	/**
	 * Checks if the console is docked (TV mode).
	 */
	public static var isConsoleDocked(get, never):Bool;

	/**
	 * The current applet state.
	 */
	public static var appState(get, never):AppletStateMode;

	/**
	 * Checks if the application is running on Applet mode.
	 */
	public static var isRunningAsApplet(get, never):Bool;

	/**
	 * Shows an system error message.
     * 
     * @param code The error code.
	 * @param msg The error message.
     * @param full_message The full error message.
	 */
	public static function showErrorMessage(code:Null<Int> = 0, msg:String = '', ?full_message:String = null):Void
	{
		if (!isRunningAsApplet)
		{

			if (dialogMessage == null || dialogMessage == "")
			{
				dialogMessage = "An error has occurred. (no message specified)";
			}
			if (fullMessage == null || fullMessage == "")
			{
				fullMessage = null; // No full message
			}
			if (errorNumber == null || errorNumber < 0)
			{
				errorNumber = 0;
			}

			final config:ErrorApplicationConfig = new ErrorApplicationConfig();
			final result:ResultType = Error.errorApplicationCreate(Pointer.addressOf(config), msg,
				full_message);

			if (Result.R_SUCCEEDED(result))
			{
				Error.errorApplicationSetNumber(Pointer.addressOf(config), code ?? 0);
				Error.errorApplicationShow(Pointer.addressOf(config));
			}
		}
	}

    ////////////////////////////////////

	private static function get_isConsoleDocked():Bool
	{
		return Applet.appletGetOperationMode() == AppletOperationMode.AppletOperationMode_Console;
	}

	private static function get_appState():AppletStateMode
	{
		return switch (Applet.appletGetFocusState())
		{
			case AppletFocusState.AppletFocusState_InFocus: AppletStateMode.APP_IN_FOCUS;
			case AppletFocusState.AppletFocusState_OutOfFocus: AppletStateMode.APP_OUT_OF_FOCUS;
			case AppletFocusState.AppletFocusState_Background: AppletStateMode.APP_SUSPENDED;
			default: AppletStateMode.APP_UNKNOWN;
		}
	}

	private static function get_isRunningAsApplet():Bool
	{
		return Applet.appletGetAppletType() != AppletType.AppletType_Application
			&& Applet.appletGetAppletType() != AppletType.AppletType_SystemApplication;
	}

	private static function get_SWITCH_VERSION():String
	{
		final switchVersion:UInt32 = Hosversion.hosversionGet();
		final major:UInt32 = Hosversion.HOSVER_MAJOR(switchVersion);
		final minor:UInt32 = Hosversion.HOSVER_MINOR(switchVersion);
		final patch:UInt32 = Hosversion.HOSVER_MICRO(switchVersion);

		return major + "." + minor + "." + patch;
	}

	private static function get_SWITCH_VERSION_INT():Null<Int>
	{
		return Std.parseInt(SWITCH_VERSION.replace(".", ""));
	}

	private static function get_ATMOSPHERE_VERSION():String
	{
		var version:UInt64 = 0;
		if (Hosversion.hosversionIsAtmosphere())
		{
			// Copied from https://github.com/impeeza/sys-patch/blob/2ca9ba8fc6fa9f02583a5d821ca75a5603937389/sysmod/src/main.cpp#L751
			untyped __cpp__("
            Result rc;
            uint64_t v;
            if (R_SUCCEEDED(rc = splInitialize())) {
                if (R_SUCCEEDED(rc = splGetConfig((SplConfigItem)65000, &v))) {
                    {0} = (v >> 40) & 0xFFFFFF;
                }
                splExit();
            }
            ", version);
		}

		if (version.toInt() > 0)
		{
			final major:UInt32 = (version.toInt() >> 16) & 0xFF;
			final minor:UInt32 = (version.toInt() >> 8) & 0xFF;
			final patch:UInt32 = version.toInt() & 0xFF;
			return major + "." + minor + "." + patch;
		}

		return "0.0.0";
	}

	private static function get_ATMOSPHERE_VERSION_INT():Null<Int>
	{
		return Std.parseInt(ATMOSPHERE_VERSION.replace(".", ""));
	}
}