# Magic Pencil

**Magic Pencil** is an extension for Aseprite that provides additional options for the pencil tool.

## How to use the extension

Go to the Edit menu and click the Magic Pencil option, select an effect from the dialog window and use the pencil tool.

Please note that most options use magic colors, selected colors will be restored after closing the Magic Pencil dialog window or selecting the Regular option.

## Options

**Graffiti** - adds an effect of paint drips and specks to the brush. After selecting this option, a slider controlling the effect's strength will appear underneath.

**Tool [Outline]** - adds an outline around a closed shape that you click on, works with foreground (left-click) and background (right-click) colors.

**Brush [Outline]** - adds an outline around the brush as you draw. After selecting this option, the outline's color can be changed under this option in the dialog window.

**Lift** - moves a part of the image into its own layer.

**Unique [Mix]** - mixes colors, left-click uses the RGB color model to mix colors, while right-click uses HSV.

**Proportional [Mix]** - mixes colors taking into account the number of pixels of each color, left-click uses the RGB color model to mix colors, while right-click uses HSV.

**Colorize** - changes color (hue), works with foreground (left-click) and background (right-click) colors.

**Desaturate** - removes color (hue) completely.

**Hue/Saturation/Value/Lightness [Shift]** - changes the colors based on the selected property, left-click to add, right-click to subtract. You can change how much of a shift will be applied by changing the percentage slider under these options.

**Indexed Mode** - when enabled, prevents new colors from being introduced, and any option that modifies colors will use colors from the palette.

## Known issues

- Selecting colors from the palette **while** using any option from the Magic Pencil other than *Graffiti*, *Outline Tool*, *Outline Brush* or *Colorize* will interfere with its working and result in odd behaviour

## Previews

![Graffiti Brush](/Magic%20Pencil/readme-images/graffiti.gif "Graffiti Brush")

![Outline Brush](/Magic%20Pencil/readme-images/outline-brush.gif "Outline Brush")

![Selection and RGB Shift](/Magic%20Pencil/readme-images/selection-rgb-shift.gif "Selection and RGB Shift")

![Colorize, Desaturate, Shift](/Magic%20Pencil/readme-images/colorize-desaturate-shift.gif "Colorize, Desaturate, Shift")

![Color Mixing](/Magic%20Pencil/readme-images/color-mixing.gif "Color Mixing")

![Color Mixing - RGB vs HSV](/Magic%20Pencil/readme-images/color-mixing-rgb-vs-hsv.gif "Color Mixing - RGB vs HSV")
