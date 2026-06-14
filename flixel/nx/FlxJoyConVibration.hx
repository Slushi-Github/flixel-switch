package flixel.nx;

#if !switch
#error "This file should only be compiled for the Nintendo Switch target"
#end

import cpp.Pointer;
import cpp.RawPointer;
import cpp.Stdlib;

import switchLib.services.Hid;
import switchLib.Result;
import switchLib.Types.ResultType;
import switchLib.runtime.Pad;

import flixel.nx.FlxJoyCon.FlxJoyConType;

/**
 * A struct for holding vibration data.
 */
typedef FlxJoyConVibrationData =
{
	var joycon:FlxJoyConType;
	var duration:Float;
	var amplitude_low:Float;
	var frequency_low:Float;
	var amplitude_high:Float;
	var frequency_high:Float;
}

/**
 * A class for handling vibration for the Joy-Cons.
 */
class FlxJoyConVibration
{
	/**
	 * If an Joy-Con are currently vibrating.
	 */
	public var isRunning(get, never):Bool;

	private var currentMode:Int = 0;
	private var handlesPtr:RawPointer<HidVibrationDeviceHandle>;
	private var vibrationData:HidVibrationValue;

	private var stopValue:HidVibrationValue;

	private var leftTimer:Float = 0;
	private var rightTimer:Float = 0;

	private var _isRunning:Bool = false;

	/**
	 * Creates a new instance of the Joy-Con Vibration.
	 */
	public function new()
	{
		handlesPtr = untyped __cpp__("(HidVibrationDeviceHandle*)malloc(4 * sizeof(HidVibrationDeviceHandle))");

		Hid.hidInitializeVibrationDevices(handlesPtr, 2, HidNpadIdType.HidNpadIdType_Handheld,
			HidNpadStyleTag.HidNpadStyleTag_NpadHandheld);

		final dockedPtr:RawPointer<HidVibrationDeviceHandle> = untyped __cpp__("{0} + 2", handlesPtr);
		Hid.hidInitializeVibrationDevices(dockedPtr, 2, HidNpadIdType.HidNpadIdType_No1,
			HidNpadStyleTag.HidNpadStyleTag_NpadJoyDual);

		vibrationData = new HidVibrationValue();

		stopValue = new HidVibrationValue();
		stopValue.amp_low = 0;
		stopValue.amp_high = 0;
		stopValue.freq_low = 160.0;
		stopValue.freq_high = 320.0;
	}

	public function update(elapsed:Float):Void
	{
		// Handle Left Joy-Con auto-stop
		if (leftTimer > 0)
		{
			leftTimer -= elapsed;
			if (leftTimer <= 0)
			{
				leftTimer = 0;
				_sendStopDirect(FlxJoyConType.LEFT);
			}
		}

		// Handle Right Joy-Con auto-stop
		if (rightTimer > 0)
		{
			rightTimer -= elapsed;
			if (rightTimer <= 0)
			{
				rightTimer = 0;
				_sendStopDirect(FlxJoyConType.RIGHT);
			}
		}

		_isRunning = (leftTimer > 0 || rightTimer > 0);
	}

	/**
	 * Vibrate a single Joy-Con
	 * @param data The vibration data
	 */
	public function vibrate(data:FlxJoyConVibrationData)
	{
        if (data == null) return;

		_internalVibrate(data.joycon, data.amplitude_low, data.frequency_low, data.amplitude_high,
			data.frequency_high);

		// if duration is > 0, start a timer to stop the vibration
		if (data.duration > 0)
		{
			if (data.joycon == FlxJoyConType.LEFT)
				leftTimer = data.duration;
			else
				rightTimer = data.duration;
		}
	}

	/**
	 * Vibrate both Joy-Cons.
	 * @param data The vibration data.
	 */
	public function vibrateBoth(data:FlxJoyConVibrationData)
	{
		if (data == null) return;

		final values:Array<HidVibrationValue> = [createVibrationValue(data), createVibrationValue(data)];

		final baseHandlePtr:RawPointer<HidVibrationDeviceHandle> = untyped __cpp__("{0} + {1}",
			handlesPtr, currentMode * 2);

		Hid.hidSendVibrationValues(baseHandlePtr, Pointer.arrayElem(values, 0), 2);

		if (data.duration > 0)
		{
			leftTimer = data.duration;
			rightTimer = data.duration;
		}
	}

	/**
	 * Stop a single Joy-Con.
	 * @param joycon The Joy-Con to stop.
	 */
	public function stop(joycon:FlxJoyConType)
	{
		if (joycon == FlxJoyConType.LEFT)
			leftTimer = 0;
		else if (joycon == FlxJoyConType.RIGHT)
			rightTimer = 0;
        else {
            return;
        }

		_sendStopDirect(joycon);
	}

	/////////////////////////////////////////

	private function updateMode(isHandheld:Bool)
	{
		currentMode = isHandheld ? 0 : 1;
	}

	private inline function getHandle(joycon:FlxJoyConType):HidVibrationDeviceHandle
	{
		var joyconIndex = (joycon == FlxJoyConType.LEFT) ? 0 : 1;
		var index = currentMode * 2 + joyconIndex;
		return handlesPtr[index];
	}

	private inline function getHandlePtr(joycon:FlxJoyConType):RawPointer<HidVibrationDeviceHandle>
	{
		var joyconIndex = (joycon == FlxJoyConType.LEFT) ? 0 : 1;
		var index = currentMode * 2 + joyconIndex;
		return untyped __cpp__("{0} + {1}", handlesPtr, index);
	}

	private function createVibrationValue(data:FlxJoyConVibrationData):HidVibrationValue
	{
		var val = new HidVibrationValue();
		val.amp_low = data.amplitude_low;
		val.freq_low = data.frequency_low;
		val.amp_high = data.amplitude_high;
		val.freq_high = data.frequency_high;
		return val;
	}

	private function _internalVibrate(joy:FlxJoyConType, al:Float, fl:Float, ah:Float, fh:Float)
	{
		vibrationData.amp_low = al;
		vibrationData.freq_low = fl;
		vibrationData.amp_high = ah;
		vibrationData.freq_high = fh;
		Hid.hidSendVibrationValue(getHandle(joy), Pointer.addressOf(vibrationData));
	}

	private function _sendStopDirect(joy:FlxJoyConType)
	{
		Hid.hidSendVibrationValue(getHandle(joy), Pointer.addressOf(stopValue));
	}

	public function destroy()
	{
		untyped __cpp__("free({0})", handlesPtr);
	}

	/////////////////////////////////////////

	private function get_isRunning():Bool
	{
		return _isRunning;
	}
}