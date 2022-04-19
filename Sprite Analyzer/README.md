# Sprite Analyzer

**Sprite Analyzer** is an extension that creates a live preview with a breakdown of a sprite, allowing you to track values, silhouette, outline, and blocked shapes of the sprites.

## How to use the extension

In order to analyze a sprite you need to:

1. Install the extension and restart Aseprite
2. Open any sprite/image
3. Select an area that you want to create a preview of - preferably with the Rectangular Marquee Tool
4. Go to the _View_ menu and click the _Sprite Analyzer_ option near the bottom

## How to add colors

![Preview of a manual color selection](/Sprite%20Analyzer/readme-images/sprite-analyzer-preview.gif "Preview of a manual color selection")

Sprite Analyzer can show additional previews - an **outline preview** and a **flat colors** preview - for both of these additional information about colors need to be input.

There are two sections for inputting outline colors and colors to flatten:

![Sprite Analysis Dialog](/Sprite%20Analyzer/readme-images/sprite-analysis-dialog.png "Sprite Analysis Dialog")

**Outline Colors** has a single collection of colors that will show up as black in the preview.

**Flatten Colors** can have multiple collections/ramps of colors that will all be drawn as the first color in a collection.

In order to configure collections:

- Add a color - by left-clicking on the colors collection which will add the current foreground color or colors selected in the palette
- Remove a color - by right-clicking on a color in the collection
- Reorder colors - by moving colors in a collection, moving a color out of a collection removes it, the order of outline colors doesn't matter

## How to automatically analyze a sprite

![Preview of an automatic color analysis](/Sprite%20Analyzer/readme-images/sprite-analyzer-auto-preview.gif "Preview of an automatic color analysis")

You can automatically analyze a sprite by selecting the _New Auto_ option from the top section of the dialog. This will guide you through a short process where first, you can pick outline colors used in the sprite (or lack thereof), and then all colors used will be grouped into colors ramps, you can adjust the grouping using two sliders:

- Tolerance - which controls how big of a shift in hue is acceptable for colors to be still considered a part of the same ramp
- Ignorance - which controls how many pixels of a given color need to be adjacent to be considered a part of the same ramp

![Palette Extraction Dialog](/Sprite%20Analyzer/readme-images/palette-extraction-dialog.png "Palette Extraction Dialog")

## How to manage presets

Any configuration consisting of outline colors, colors to flatten, and preview options can be saved and loaded as a preset. The top section of the dialog provides options for managing presets.
