package flixel.nx;

#if !switch
#error "This file should only be compiled for the Nintendo Switch target"
#end

import cpp.Pointer;

import haxe.ds.Vector;

import switchLib.services.Hid;
import switchLib.Result;
import switchLib.Types.ResultType;
import switchLib.runtime.Pad;

import flixel.util.FlxColor;
import flixel.FlxBasic;

enum FlxJoyConType
{
	LEFT;
	RIGHT;
}

typedef FlxJoyConColor =
{
	colorMain:FlxColor,
	colorSub:FlxColor,
}

/**
 * A manager for the Nintendo Switch Joy-Cons.
 */
@:access(flixel.nx.FlxJoyConVibration)
class FlxJoyCon extends FlxBasic {
	public static var instance:FlxJoyCon;

	/**
	 * Vibration manager of the controller.
	 */
	public var vibration:FlxJoyConVibration;

	public var joyconLeftMainColor(get, never):FlxColor;

	public var joyconRightMainColor(get, never):FlxColor;

	/////////////////////////////////////////

	/**
	 * Current controller state.
	 */
	@:unreflective
	private var pad:PadState;

	private var joyConColors:Vector<FlxJoyConColor>;

	private var _internalJoyconLeftColor:HidNpadControllerColor;

	private var _internalJoyconRightColor:HidNpadControllerColor;
	
	/////////////////////////////////////////

	/**
	 * Initialize the controller and vibration.
	 */
    public function new() {
		super();
		
		instance = this;

		// Initialize the controller
		Pad.padConfigureInput(1, HidNpadStyleTag.HidNpadStyleSet_NpadStandard);
		pad = new PadState();
		Pad.padInitializeDefault(Pointer.addressOf(pad));

		vibration = new FlxJoyConVibration();
		joyConColors = new Vector<FlxJoyConColor>(2);

		// Initialize the controller colors with white by default
		joyConColors[0] = {
			colorMain: FlxColor.WHITE,
			colorSub: FlxColor.WHITE
		};
		joyConColors[1] = {
			colorMain: FlxColor.WHITE,
			colorSub: FlxColor.WHITE
		};

		_internalJoyconLeftColor = new HidNpadControllerColor();
		_internalJoyconRightColor = new HidNpadControllerColor();

		final rc:ResultType = Hid.hidGetNpadControllerColorSplit(Pad.padIsHandheld(Pointer.addressOf(pad)) ? HidNpadIdType.HidNpadIdType_Handheld : HidNpadIdType.HidNpadIdType_No1,
			Pointer.addressOf(_internalJoyconLeftColor),
			Pointer.addressOf(_internalJoyconRightColor));
		if (Result.R_SUCCEEDED(rc))
		{
			joyConColors[0] = {
				colorMain: new FlxColor(_internalJoyconLeftColor.main),
				colorSub: new FlxColor(_internalJoyconLeftColor.sub)
			};
			joyConColors[1] = {
				colorMain: new FlxColor(_internalJoyconRightColor.main),
				colorSub: new FlxColor(_internalJoyconRightColor.sub)
			};
		}
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

		Pad.padUpdate(Pointer.addressOf(pad));
		if (vibration != null)
		{
			vibration.updateMode(Pad.padIsHandheld(Pointer.addressOf(pad)));
			vibration.update(elapsed);
		}

		// Update the controller colors
		if (joyConColors != null)
		{
			final rc:ResultType = Hid.hidGetNpadControllerColorSplit(Pad.padIsHandheld(Pointer.addressOf(pad)) ? HidNpadIdType.HidNpadIdType_Handheld : HidNpadIdType.HidNpadIdType_No1,
				Pointer.addressOf(_internalJoyconLeftColor),
				Pointer.addressOf(_internalJoyconRightColor));
			if (Result.R_SUCCEEDED(rc))
			{
				joyConColors[0] = {
					colorMain: FlxColor.fromRGB((_internalJoyconLeftColor.main >> 0) & 0xFF, // R
						(_internalJoyconLeftColor.main >> 8) & 0xFF, // G
						(_internalJoyconLeftColor.main >> 16) & 0xFF, // B
						(_internalJoyconLeftColor.main >> 24) & 0xFF // A
					),
					colorSub: FlxColor.fromRGB((_internalJoyconLeftColor.sub >> 0) & 0xFF,
						(_internalJoyconLeftColor.sub >> 8) & 0xFF,
						(_internalJoyconLeftColor.sub >> 16) & 0xFF,
						(_internalJoyconLeftColor.sub >> 24) & 0xFF)
				};
				joyConColors[1] = {
					colorMain: FlxColor.fromRGB((_internalJoyconRightColor.main >> 0) & 0xFF,
						(_internalJoyconRightColor.main >> 8) & 0xFF,
						(_internalJoyconRightColor.main >> 16) & 0xFF,
						(_internalJoyconRightColor.main >> 24) & 0xFF),
					colorSub: FlxColor.fromRGB((_internalJoyconRightColor.sub >> 0) & 0xFF,
						(_internalJoyconRightColor.sub >> 8) & 0xFF,
						(_internalJoyconRightColor.sub >> 16) & 0xFF,
						(_internalJoyconRightColor.sub >> 24) & 0xFF)
				};
			}
			// If the function failed, use the default colors
			else if (Result.R_FAILED(rc))
			{
				joyConColors[0] = {
					colorMain: FlxColor.WHITE,
					colorSub: FlxColor.WHITE,
				};
				joyConColors[1] = {
					colorMain: FlxColor.WHITE,
					colorSub: FlxColor.WHITE
				};
			}
		}
    }

	override public function destroy():Void
	{
        super.destroy();

		if (vibration != null)
		{
			vibration.destroy();
		}
	}

	/////////////////////////////////////////

	/**
	 * Get the main color and sub color of a Joy-Con.
	 * 
	 * -------
	 * 
	 * Primary color: The color of the Joy-Con outer shell.
	 * 
	 * Secondary color: The color of the Joy-Con buttons.
	 * 
	 * -------
	 * 
	 * Sometimes it may return inverted colors, or return black, 
	 * or other strange things. If non-original Joy-Cons are 
	 * being used, the colors returned from this function are unknown.
	 * 
	 * @param joycon Joy-Con to get the color of.
	 * @return FlxJoyConColor
	 */
	public function getJoyConColor(joycon:FlxJoyConType):FlxJoyConColor
	{
		return switch (joycon)
		{
			case FlxJoyConType.LEFT:
				return joyConColors[0];
			case FlxJoyConType.RIGHT:
				return joyConColors[1];
		}
	}

	/////////////////////////////////////////

	private function get_joyconLeftMainColor():FlxColor {
        return joyConColors[0]?.colorMain;
    }

    private function get_joyconRightMainColor():FlxColor {
        return joyConColors[1]?.colorMain;
    }
}