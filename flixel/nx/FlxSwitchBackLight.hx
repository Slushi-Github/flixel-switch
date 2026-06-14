package flixel.nx;

#if !switch
#error "This file should only be compiled for the Nintendo Switch target"
#end

import cpp.Pointer;
import cpp.UInt64;
import cpp.Float32;

import switchLib.Result;
import switchLib.Types.ResultType;

import switchLib.services.Lbl;

import flixel.FlxBasic;

/**
 * The status of the Nintendo Switch screen backlight
 */
enum FlxSwitchBacklightStatus {
    ENABLED;
    DISABLED;
    ENABLING;
    DISABLING;
}

/**
 * Controls the screen backlight of the Nintendo Switch, and get information about it
 */
class FlxSwitchBackLight extends FlxBasic {

    /**
     * The screen brightness value between 0.0 and 1.0
     */
    public var screenBrightness(get, set):Float;

    /**
     * The status of the screen backlight, if is enabled or not and if it is dimming or not
     * @see FlxSwitchBacklightStatus
     * */
    public var screenBackLightStatus(get, never):FlxSwitchBacklightStatus;

    /**
     * If the screen backlight is enabled or not
     */
    public var screenBackLightEnabled(get, set):Bool;

    /**
     * If the screen is dimming or not
     */
    public var screenDimming(get, set):Bool;

    /**
     * The ambient light value between 0.0 and 1.0
     */
    public var screenAmbientLightValue(get, never):Float;

    /**
     * If the ambient light value is over the limit or not
     */
    public var screenAmbientLightOverLimit(get, never):Bool;

    ////////////////////////////////////////

    private var systemBrightnessConfigured(get, never):Float;

    private var hardwareBacklightBrightness(get, never):Float;

    private var backlightStatus(get, never):FlxSwitchBacklightStatus;

    private var isDimmingEnabled(get, never):Bool;

    private var ambientLightAvailable(get, never):Bool;

    private var ambientLightSensorOverLimit:Bool;

    private var ambientLightSensorLux:Float32;
    
    /**
     * Initializes the screen backlight service of the Nintendo Switch
     */
    public function new() {
        super();

        final result = Lbl.lblInitialize();
        if (result != 0) {
            trace('lblInitialize failed to initialize LBL service: 0x${StringTools.hex(result)}');
            return;
        }

        final rc = Lbl.lblGetAmbientLightSensorValue(Pointer.addressOf(ambientLightSensorOverLimit), Pointer.addressOf(ambientLightSensorLux));
        if (rc != 0) {
            trace('lblGetAmbientLightSensorValue failed to get ambient light sensor value: 0x${StringTools.hex(rc)}');
        }
    }

    /**
     * Turns on the backlight with fade effect
     * @param fadeTimeSeconds Duration of the fade in seconds (0 = instant)
     * @return true if executed successfully
     */
    public function switchBacklightOn(fadeTimeSeconds:Float = 0.0):Bool {
        final fadeTimeNanos:UInt64 = cast (fadeTimeSeconds * 1000000000.0);
        final result = Lbl.lblSwitchBacklightOn(fadeTimeNanos);
        if (result != 0) {
            trace('lblSwitchBacklightOn failed to switch backlight on: 0x${StringTools.hex(result)}');
            return false;
        }
        return true;
    }
    
    /**
     * Turns off the backlight with fade effect
     * @param fadeTimeSeconds Duration of the fade in seconds (0 = instant)
     * @return true if executed successfully
     */
    public function switchBacklightOff(fadeTimeSeconds:Float = 0.0):Bool {
        final fadeTimeNanos:UInt64 = cast (fadeTimeSeconds * 1000000000.0);
        final result = Lbl.lblSwitchBacklightOff(fadeTimeNanos);
        if (result != 0) {
            trace('lblSwitchBacklightOff failed to switch backlight off: 0x${StringTools.hex(result)}');
            return false;
        }
        return true;
    }

    /**
     * Gets the ambient light sensor value between 0.0 and 1.0
     * @param scale The scale to apply to the value
     * @return The ambient light sensor value between 0.0 and 1.0
     */
    public function getAmbientLightSensorLuxToRange(scale:Null<Float> = 1.0):Float {
        if (!ambientLightAvailable) return 0.0;
        final rc = Lbl.lblGetAmbientLightSensorValue(Pointer.addressOf(ambientLightSensorOverLimit), Pointer.addressOf(ambientLightSensorLux));
        if (rc != 0) return 0.0;
        if (ambientLightSensorOverLimit) return scale;
        final result:Float = Math.min(ambientLightSensorLux / 17972.0, 1.0) * scale;
        return Math.round(result * 100) / 100.0;
    }

    /**
     * Loads the saved brightness setting
     * @return true if loaded successfully
     */
    public function loadBrightnessSetting():Bool {
        final result = Lbl.lblLoadCurrentSetting();
        if (result != 0) {
            trace('lblLoadCurrentSetting failed to load brightness setting: 0x${StringTools.hex(result)}');
            return false;
        }
        return true;
    }

    ///////////////////////////////////

    override public function destroy():Void {
        super.destroy();

        // Activate backlight if needed
        if (backlightStatus == FlxSwitchBacklightStatus.DISABLING || backlightStatus == FlxSwitchBacklightStatus.DISABLED) {
            switchBacklightOn();
        }

        // Restore system brightness
        Lbl.lblLoadCurrentSetting();
        Lbl.lblApplyCurrentBrightnessSettingToBacklight();

        Lbl.lblExit();
    }
    
    private function setBrightness(brightness:Null<Float>, apply:Null<Bool> = true):Void {
        final realBrightness = brightness == null || brightness >= 1.0 || brightness <= 0.0 ? systemBrightnessConfigured : brightness;

        final result = Lbl.lblSetCurrentBrightnessSetting(realBrightness);
        if (result != 0) {
            trace('lblSetCurrentBrightnessSetting failed to set brightness: 0x${StringTools.hex(result)}');
            return;
        }
        
        if (apply != null && apply) {
            applyBrightnessToBacklight();
        }
    }

    private function getBrightness():Float {
        var result:Float32 = 0.0;
        final rc = Lbl.lblGetCurrentBrightnessSetting(Pointer.addressOf(result));
        if (rc != 0) {
            trace('lblGetCurrentBrightnessSetting failed to get brightness: 0x${StringTools.hex(rc)}');
            return 0.0;
        }
        return Math.round(result * 100) / 100.0;
    }
    
    private function applyBrightnessToBacklight():Bool {
        final result = Lbl.lblApplyCurrentBrightnessSettingToBacklight();
        if (result != 0) {
            trace('lblApplyCurrentBrightnessSettingToBacklight failed to apply brightness to backlight: 0x${StringTools.hex(result)}');
            return false;
        }
        return true;
    }
    
    private function setDimming(mode:Bool):Bool {
        final result:ResultType = mode ? Lbl.lblEnableDimming() : Lbl.lblDisableDimming();

        if (result != 0) {
            trace('lblEnableDimming or lblDisableDimming failed to enable or disable dimming: 0x${StringTools.hex(result)}');
            return false;
        }
        return true;
    }
    
    private function isBacklightOn():Bool {
        return backlightStatus == FlxSwitchBacklightStatus.ENABLED;
    }

    // Getters ////////////////////////////
    
    private function get_screenBrightness():Float {
        return getBrightness();
    }

    private function set_screenBrightness(brightness:Float):Float {
        setBrightness(brightness, true);
        return getBrightness();
    }

    private function get_screenBackLightStatus():FlxSwitchBacklightStatus {
        return backlightStatus;
    }

    private function get_screenDimming():Bool {
        return isDimmingEnabled;
    }

    private function set_screenDimming(mode:Bool):Bool {
        setDimming(mode);
        return isDimmingEnabled;
    }

    private function get_screenBackLightEnabled():Bool {
        return isBacklightOn();
    }

    private function set_screenBackLightEnabled(mode:Bool):Bool {
        return mode ? switchBacklightOn() : switchBacklightOff();
    }

    private function get_screenAmbientLightValue():Float {
        if (!ambientLightAvailable) return 0.0;
        final rc = Lbl.lblGetAmbientLightSensorValue(Pointer.addressOf(ambientLightSensorOverLimit), Pointer.addressOf(ambientLightSensorLux));
        if (rc != 0) {
            trace('lblGetAmbientLightSensorValue failed to get ambient light sensor value: 0x${StringTools.hex(rc)}');
            return 0.0;
        }

        return ambientLightSensorOverLimit ? 17972.0 : ambientLightSensorLux;
    }

    private function get_screenAmbientLightOverLimit():Bool {
        if (!ambientLightAvailable) return false;
        final rc = Lbl.lblGetAmbientLightSensorValue(Pointer.addressOf(ambientLightSensorOverLimit), Pointer.addressOf(ambientLightSensorLux));
        if (rc != 0) {
            trace('lblGetAmbientLightSensorValue failed to get ambient light sensor value: 0x${StringTools.hex(rc)}');
            return false;
        }

        return ambientLightSensorOverLimit;
    }

    /////////////////////////////////////////

    private function get_systemBrightnessConfigured():Float {
        var result:Float32 = 0.0;
        final rc = Lbl.lblGetCurrentBrightnessSetting(Pointer.addressOf(result));
        if (rc != 0) {
            trace('lblGetCurrentBrightnessSetting failed to get configured brightness: 0x${StringTools.hex(rc)}');
            return 0.0;
        }
        return result;
    }

    private function get_hardwareBacklightBrightness():Float {
        var result:Float32 = 0.0;
        final rc = Lbl.lblGetBrightnessSettingAppliedToBacklight(Pointer.addressOf(result));
        if (rc != 0) {
            trace('lblGetBrightnessSettingAppliedToBacklight failed to get backlight brightness: 0x${StringTools.hex(rc)}');
            return 0.0;
        }
        return result;
    }
    
    private function get_backlightStatus():FlxSwitchBacklightStatus {
        var result:LblBacklightSwitchStatus = LblBacklightSwitchStatus.LblBacklightSwitchStatus_Disabled;
        final rc = Lbl.lblGetBacklightSwitchStatus(untyped __cpp__("&{0}", result));
        if (rc != 0) {
            trace('Warning: Failed to get backlight status: 0x${StringTools.hex(rc)}');
        }

        if (result == LblBacklightSwitchStatus.LblBacklightSwitchStatus_Disabled) {
            return FlxSwitchBacklightStatus.DISABLED;
        } else if (result == LblBacklightSwitchStatus.LblBacklightSwitchStatus_Enabled) {
            return FlxSwitchBacklightStatus.ENABLED;
        } else if (result == LblBacklightSwitchStatus.LblBacklightSwitchStatus_Enabling) {
            return FlxSwitchBacklightStatus.ENABLING;
        } else if (result == LblBacklightSwitchStatus.LblBacklightSwitchStatus_Disabling) {
            return FlxSwitchBacklightStatus.DISABLING;
        }
        return FlxSwitchBacklightStatus.DISABLED;
    }
    
    private function get_isDimmingEnabled():Bool {
        var result:Bool = false;
        final rc = Lbl.lblIsDimmingEnabled(Pointer.addressOf(result));
        if (rc != 0) {
            trace('Failed to get dimming status: 0x${StringTools.hex(rc)}');
        }
        return result;
    }

    private function get_ambientLightAvailable():Bool {
        var result:Bool = false;
        final rc = Lbl.lblIsAmbientLightSensorAvailable(Pointer.addressOf(result));
        if (rc != 0) {
            trace('Failed to get ambient light sensor status: 0x${StringTools.hex(rc)}');
        }
        return result;
    }
}