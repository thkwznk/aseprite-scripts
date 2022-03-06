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

- **Advanced Scaling** - allows for upscaling pixel art without introducing new colors using a variety of algorithms: Nearest Neighbor, Eagle, Scale2x, Scale3x and a custom algorithm named Hawk.

- **Add Inbetween Frames** - adds in between frames based on position.

- **Analyze Colors** - provides statistics regarding color usage, allows for changing any of the used colors and palette sorting.

## On-Screen Controls

An extension for [Aseprite](https://www.aseprite.org/) that adds on-screen controls for touch screen users.

## Animation Suite

An extension for [Aseprite](https://www.aseprite.org/) that adds animation-related functionalities:

- **Import Animation** - allows for importing an animation from another sprite with an on-screen guide. Source animation can be based on a layer, a tag, or a selection. Imported animation can be static or move in a linear or sine pattern.
- **Loop Animation** - generates a perfect loop from multiple animations on separate layers with a different number of frames.

Known issues:

- Background layers aren't in general cause issues for the extension, it's recommended to avoid them.

## AsepriteOS

An experimental project trying to implements basic applications as [Aseprite](https://www.aseprite.org/) scripts/extensions.

Contains:

- **Note** - a to-do list app inside Aseprite.

# How add Scripts to Aseprite

In order to add LUA scripts open Aseprite and select _File_ > _Scripts_ > _Open Scripts Folder_. Next, copy script files to the opened directory.
