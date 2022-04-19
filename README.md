# Aseprite Script

This repository is my workspace for developing LUA scripts and extensions for [Aseprite](https://www.aseprite.org/).

## Versioning

`{major}.{minor}.{patch}`

Major version changes when a new script is added.  
Minor version changes when new functionality is added to an existing script.  
Patch version changes when a bug is fixed in an existing script.

## NxPA Studio

A script suite/extension for [Aseprite](https://www.aseprite.org/) that adds image processing functionalities.

Contains:

- **Advanced Scaling** (in _Sprite_ menu) - allows for upscaling pixel art without introducing new colors using a variety of algorithms: Nearest Neighbor, Eagle, Scale2x, Scale3x and a custom algorithm named Hawk.

- **Add Inbetween Frames** (in _Frame_ menu) - adds in-between frames based on position.

- **Analyze Colors** (in _Sprite_ menu) - provides statistics regarding color usage, allows for changing any of the used colors and palette sorting.

## On-Screen Controls

An extension for [Aseprite](https://www.aseprite.org/) that adds on-screen controls for touch screen users.
Can be launched from _View_ menu.

## Animation Suite

An extension for [Aseprite](https://www.aseprite.org/) that adds animation-related functionalities:

- **Import Animation** (in _Edit_ menu) - allows for importing an animation from another sprite with an on-screen guide. Source animation can be based on a layer, a tag, or a selection. Imported animation can have one of the following movement patterns:

  - Static
  - Shake
  - Linear
  - Sine
  - Parabola

- **Loop Animation** (in _Edit_ menu) - generates a perfect loop from multiple animations on separate layers with a different number of frames.

Known issues:

- **Extension doesn't work with the BETA version of Aseprite** - at least not by default, in relation to an [open issue](https://github.com/aseprite/aseprite/issues/3019) on GitHub the extension crashes if used with an experimental option "UI with multiple windows". This can be disabled in _Edit_ > _Preferences_ > _Experimental_ > _UI with multiple windows_.
- Background layers in general cause issues for the extension, it's recommended to avoid them.

## Sprite Analyzer

An extension that creates a live preview with a breakdown of a sprite, allowing you to track values, silhouette, outline, and blocked shapes of the sprites.

## AsepriteOS

An experimental project trying to implements basic applications as [Aseprite](https://www.aseprite.org/) scripts/extensions.

Contains:

- **Note** - a to-do list app inside Aseprite.

# How add Scripts to Aseprite

In order to add LUA scripts open Aseprite and select _File_ > _Scripts_ > _Open Scripts Folder_. Next, copy script files to the opened directory.
