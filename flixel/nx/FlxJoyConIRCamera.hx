package flixel.nx;

#if !switch
#error "This file should only be compiled for the Nintendo Switch target"
#end
import cpp.Void as CppVoid;
import cpp.Pointer;
import cpp.ConstPointer;
import cpp.UInt8;
import cpp.UInt64;
import cpp.Int32;
import cpp.SizeT;
import cpp.Stdlib;
import switchLib.services.Hid;
import switchLib.services.Irs;
import switchLib.Result;
import switchLib.Types.ResultType;
import openfl.utils.ByteArray;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.FlxSprite;

enum IRCameraQuality
{
	VeryLow;
	Low;
	Medium;
	High;
}

/**
 * A class for getting an image from the right Joy-Con IR camera.
 */
class FlxJoyConIRCamera extends FlxSprite
{
	/**
	 * If the camera is running or not.
	 */
	public var isRunning(get, never):Bool;

	/**
	 * The primary color of output from the camera.
	 */
	public var colorDark:FlxColor;

	/**
	 * The secondary color of output from the camera.
	 */
	public var colorLight:FlxColor;

	/////////////////////////////////////////

	private var _irHandle:IrsIrCameraHandle;
	private var _irBuffer:Pointer<UInt8>;
	private var _samplingNumber:UInt64 = 0;

	private var irWidth(default, null):Int;
	private var irHeight(default, null):Int;

	private var _isRunning:Bool = false;
	private var _byteArray:ByteArray;
	private var _openFLRect:Rectangle;

	public static final RESOLUTIONS = {
		veryLow: {width: 40, height: 30},
		low: {width: 80, height: 60},
		medium: {width: 160, height: 120},
		high: {width: 320, height: 240}
	};

	private static inline final IR_BUFFER_SIZE:Int = 0x12c00;

	/////////////////////////////////////////

	/**
	 * Create a new sprite to represent the IR camera of the right Joy-Con.
	 * @param x The initial X position of the sprite.
	 * @param y	The initial Y position of the sprite.
	 * @param quality The quality of the IR camera.
	 * @param colorDark The primary color of output from the camera.
	 * @param colorLight The secondary color of output from the camera.
	 * @param padMode The controller mode.
	 */
	public function new(
		x:Float = 0,
		y:Float = 0,
		quality:IRCameraQuality = Medium,
		colorDark:FlxColor = FlxColor.BLACK,
		colorLight:FlxColor = FlxColor.GREEN,
		?padMode:Int32
	)
	{
		super(x, y);

		this.colorDark = colorDark ?? FlxColor.BLACK;
		this.colorLight = colorLight ?? FlxColor.GREEN;

		if (padMode == null)
			padMode = HidNpadIdType.HidNpadIdType_No1;

		if (quality == null)
			quality = IRCameraQuality.Medium;

		switch (quality)
		{
			case VeryLow:
				irWidth = RESOLUTIONS.veryLow.width;
				irHeight = RESOLUTIONS.veryLow.height;
			case Low:
				irWidth = RESOLUTIONS.low.width;
				irHeight = RESOLUTIONS.low.height;
			case Medium:
				irWidth = RESOLUTIONS.medium.width;
				irHeight = RESOLUTIONS.medium.height;
			case High:
				irWidth = RESOLUTIONS.high.width;
				irHeight = RESOLUTIONS.high.height;
		}

		final rc:ResultType = Irs.irsInitialize();
		if (Result.R_FAILED(rc))
		{
			trace('irsInitialize failed: 0x${StringTools.hex(rc)}');
			return;
		}

		_initCamera(padMode, quality);
	}

	private function _initCamera(padMode:Int, quality:IRCameraQuality):Void
	{
		_irBuffer = Stdlib.malloc(IR_BUFFER_SIZE);
		if (_irBuffer == null)
		{
			trace("Malloc irBuffer failed");
			return;
		}
		_memset(cast _irBuffer, 0, IR_BUFFER_SIZE);

		_irHandle = new IrsIrCameraHandle();
		var rc = Irs.irsGetIrCameraHandle(Pointer.addressOf(_irHandle), padMode);
		if (rc != 0)
		{
			trace('irsGetIrCameraHandle failed: 0x${StringTools.hex(rc)}');
			_freeNative();
			return;
		}

		final config = new IrsImageTransferProcessorConfig();
		Irs.irsGetDefaultImageTransferProcessorConfig(Pointer.addressOf(config));

		config.format = switch (quality)
		{
			case VeryLow: IrsImageTransferProcessorFormat.IrsImageTransferProcessorFormat_40x30;
			case Low: IrsImageTransferProcessorFormat.IrsImageTransferProcessorFormat_80x60;
			case Medium: IrsImageTransferProcessorFormat.IrsImageTransferProcessorFormat_160x120;
			case High: IrsImageTransferProcessorFormat.IrsImageTransferProcessorFormat_320x240;
		};

		rc = Irs.irsRunImageTransferProcessor(_irHandle, Pointer.addressOf(config), 0x100000);
		if (rc != 0)
		{
			trace('irsRunImageTransferProcessor failed: 0x${StringTools.hex(rc)}');
			_freeNative();
			return;
		}

		makeGraphic(irWidth, irHeight, 0xFF000000, true);

		resetFrameSize();
		resetSizeFromFrame();

		_byteArray = new ByteArray();
		_byteArray.length = irWidth * irHeight * 4;
		_openFLRect = new Rectangle(0, 0, irWidth, irHeight);

		_isRunning = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!_isRunning)
			return;

		final state = new IrsImageTransferProcessorState();
		final rc = Irs.irsGetImageTransferProcessorState(_irHandle,
			untyped __cpp__("(void*){0}", _irBuffer), IR_BUFFER_SIZE, Pointer.addressOf(state));

		if (rc != 0 || state.sampling_number == _samplingNumber)
			return;
		_samplingNumber = state.sampling_number;

		_updatePixels();
	}

	private function _updatePixels():Void
	{
		final dr:Int = colorDark.red ?? FlxColor.BLACK.red;
		final dg:Int = colorDark.green ?? FlxColor.BLACK.green;
		final db:Int = colorDark.blue ?? FlxColor.BLACK.blue;

		final lr:Int = colorLight.red ?? FlxColor.GREEN.red;
		final lg:Int = colorLight.green ?? FlxColor.GREEN.green;
		final lb:Int = colorLight.blue ?? FlxColor.GREEN.blue;

		final total:Int = irWidth * irHeight;

		_byteArray.position = 0;

		for (i in 0...total)
		{
			final t:Int = _irBuffer[i];

			final r:Int = dr + Std.int((lr - dr) * t / 255);
			final g:Int = dg + Std.int((lg - dg) * t / 255);
			final b:Int = db + Std.int((lb - db) * t / 255);

			_byteArray.writeByte(r);
			_byteArray.writeByte(g);
			_byteArray.writeByte(b);
			_byteArray.writeByte(0xFF);
		}

		_byteArray.position = 0;

		final bmd = pixels;
		bmd.lock();
		bmd.setPixels(_openFLRect, _byteArray);
		bmd.unlock();

		dirty = true;
	}

	private function stopCamera():Void
	{
		if (!_isRunning)
			return;
		Irs.irsStopImageProcessorAsync(_irHandle);
		_freeNative();
		_isRunning = false;
	}

	private function _freeNative():Void
	{
		if (_irBuffer != null)
		{
			Stdlib.free(_irBuffer);
			_irBuffer = null;
		}
	}

	override public function destroy():Void
	{
		stopCamera();
		super.destroy();
	}

	private function get_isRunning():Bool
	{
		return _isRunning;
	}

	@:native("memset")
	extern private static function _memset(s:Pointer<CppVoid>, c:Int, n:SizeT):Int;
}
