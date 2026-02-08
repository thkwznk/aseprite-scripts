# Roadmap

## Time Tracking

Unreleased:

- [Change] No longer pause tracking when Sprite Statistics dialog window is open, **INSTEAD** > Live update time in the Sprite Statistics dialog window
- [Change] Hide the current session data and always display all information
- [Feature] Sprite Work Time
- [Fix] Correctly save time when closing Aseprite with multiple files open

Update v2.0.0:

- [Feature] Milestone trackers

Update v2.1.0:

- [Feature] Stopwatch

Update v2.2.0:

- [Improvement] Add a mechanism that flushes time data into a temp file that is not the "_pref" file, in case Aseprite crashes

Update v2.3.0:

- [Feature] Add a Graph data view with a canvas render

## Theme Preferences

Unreleased:

- ...

Update v2.0.0:

- [Test-Feature] Tint Mode where you can only edit the Tab color + optional underglow
- [Improvement] A new color (set) - Window Title Bar
- [Improvement] Read font names from TTF files

Future:

- [Feature] Add a Dark theme template
- [Feature] [Blocked] Separate "field_background" when Aseprite fixes the menu shadow
- [Feature] [Blocked] Add separate color for Tooltip Text (Tooltip Section?) - currently it doesn't work due to a bug
- [Feature] Generating a theme from the current color palette
- [Refactor] Add a Default model next to Template - Template is a template, default is default

## FX

Unreleased:

- [Improvement] Parallax - add a preview in the dialog window
- [Improvement] Parallax - add an option to input a layer speed directly
- [Feature] Add an option to calculate a perfect loop

Future:

- [Feature] Parallax - a new mode for specifying speed per layer instead of distance
- [Fix] Parallax doesn't generate correctly if the timeline is closed/hidden - cels aren't linked 
- [Feature] Parallax - add an options for delaying layers reappearing
- [Feature] Parallax - add an option to generate only from the selected frames
- [Improvement] Parallax - remember settings using the new `properties` 

## Magic Pencil

Unreleased:

- ...

Future:

- [Fix] Correctly support all inks

## Sprite Analyzer

Unreleased:

- ...

Update v1.0.1:

- [Fix] Calculations in the initial version were using incorrect values
- [Refactor] Use app.alert for the confirmation dialog
- [Improvement] Try using linear RGB for distance calculations
- [Improvement] Optimise how part of the image is taken from the source

Update v2.0.0:

- [Feature] New preview in a floating dialog window
- [Improvement] Remember settings (using the new `properties`)

## Animation Suite

Unreleased:

- ...

Update v2.0.0:

- [Improvement] Always import into a new layer
- [Improvement] New UI - animation steps preview in the dialog with interactive UI

## On-Screen Controls

Unreleased:

- [Improvement] Rework dialog to use nested menus
- [Feature] Add separate keypad controls dialog with buttons for switching layers up/down, changing their visibility, locking them and changing frames

Update v2.0.0:

- [Fix] After changing displays a dialog can be stuck out of screen
- [Fix] Opening a submenu too close to the bottom of the screen the subdialog is clipped
- [Improvement] Add a button to make a new brush from selection
- [Improvement] Add a button for selecting layer content
- [Improvement] Deselect? Invert selection?
- [Fix] Clear can delete a layer, it shouldn't
- [Change] Remove the Command button

## NxPA Studio

Unreleased:

- ...

Next:

- [Improvement] Move inbetween frames by the center instead of the top-left anchor for better results (+refactor code)

Update v3.0.0:

- [Improvement] Rebuild the *Analyze Colors* using the canvas widget

## Run

Unreleased:

- [Feature] Add a new option under _File > Run..._ that allows for searching and running scripts and commands 
- [Feature] Add a keyboard shortcut for running the last searched script or command

## Brush Transformations

Unreleased:

- ...

## Extend Cel

Unreleased:

- Added the "Extend Cels" name to appear in the Undo History
- Added a tooltip that appear after extending cels

Future:

- [Feature] Fill - add a new option in the context menu which extends the cel both directions (backwards and forwards)
