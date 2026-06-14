# Flixel Switch

A little library to get things of the Nintendo Switch console easier in HaxeFlixel!

> [!IMPORTANT]
> This library only works with Nintendo Switch target. It is not compatible with other targets.

## Why?

Well, ever since I managed to get HaxeFlixel working on the Nintendo Switch, I've wanted to add some useful features to HaxeFlixel, so I decided to create this library.

## Classes

## FlxJoyCon

This is a class that you can use to get some things from the JoyCon, like their color or the vibration, **It needs to be initialized manually!**

## FlxJoyConIRCamera

This is a class that you can use to get the IR camera of the right JoyCon as a normal [`flixel.FlxSprite`](https://api.haxeflixel.com/flixel/FlxSprite.html), **it needs to be initialized manually!**

## FlxJoyConVibration

This is a class that you can use to get the vibration of the JoyCon, **This class is initialized when FlxJoycon is initialized!**

## FlxSwitch

This is a class that you can use to get information about the Nintendo Switch console, like the system version, the applet state, show a error message, etc, **This class does NOT need to be initialized manually; it is static!**

## FlxSwitchBackLight

This is a class that you can use to manage the back light of the screen of the Nintendo Switch, **It needs to be initialized manually!**

------

## Installation

Install through the haxelib (Not alvailable yet):

```
haxelib install flixel-switch
```

or with git for the latest updates.

```
haxelib git flixel-switch https://github.com/Slushi-Github/flixel-switch
```

----

## License
This project is released under the [MIT license](https://github.com/Slushi-Github/flixel-switch/blob/main/LICENSE.md).
