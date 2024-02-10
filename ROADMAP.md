# Roadmap

## Time Tracking

Unreleased:

- ...

Update v1.0.3.
- [Feature] Milestone trackers
- [Feature] Actual Timer
- [Improvement] Remember data using the new `properties`

## Theme Preferences

Unreleased:

- [Improvement] Major performance improvement when applying theme preferences
- [Improvement] Move the Font configuration to it's own menu option under View > Font Preferences...
- [Improvement] Move the "Reset to Default" option to the main Theme Preferences dialog window
- [Improvement] Change user screen & UI scaling settings to correctly display vector fonts
- [Improvement] Add "Save As" button for the Theme configuration
- [Feature] Add "Outline" color
- [Feature] Add "Title Bar" Window color

Update v2.0.0:

- [Improvement] A new color (set) - Window Title Bar
- [Improvement] Read font names from TTF files

Future:

- [Feature] Add a Dark theme template
- [Feature] [Blocked] Separate "field_background" when Aseprite fixes the menu shadow
- [Feature] [Blocked] Add separate color for Tooltip Text (Tooltip Section?) - currently it doesn't work due to a bug

## FX

Unreleased:

- ...

Future:

- [Fix] Parallax doesn't generate correctly if the timeline is closed/hidden - cels aren't linked 
- [Feature] Parallax - add an options for delaying layers reappearing
- [Feature] Parallax - add an option to generate only from the selected frames
- [Feature] Parallax - add alternative movement functions
- [Improvement] Parallax - remember settings using the new `properties` 

## Magic Pencil

Unreleased:

- ...

Update v2.0.0:

- [Improvement] Rework the dialog UI to accommodate the number of options
- [Improvement] Create a new section called "Brush", with Outline and Graffiti modes
- [Improvement] Create a new section called "Tool", with Outline
- [Feature] Add a separate set of options for the Grayscale Color Mode
- [Feature] Add a separate set of options for the Indexed Color Mode

Future:

- [Feature] Two Tone
- [Improvement] Allow for shifting multiple components at the same time (also, possibly, with different values?)

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

- [Improvement] New UI - animation steps preview in the dialog with interactive UI

## On-Screen Controls

Unreleased:

- [Improvement] Rework dialog to use nested menus

Update v2.0.0:

- [Fix] After changing displays a dialog can be stuck out of screen
- [Fix] Opening a submenu too close to the bottom of the screen the subdialog is clipped
- [Improvement] Add sliders to resize color in the palette and thumbnails on the timeline
- [Improvement] Add a button to make a new brush from selection
- [Improvement] Add buttons for switching layers up/down, changing their visibility, locking them, and selecting layer content
- [Improvement] Deselect? Invert selection?
- [Fix] Clear can delete a layer, it shouldn't
- [Change] Remove the Command button

## NxPA Studio

Unreleased:

- 

Update v3.0.0:

- [Improvement] Rebuild the *Analyze Colors* using the canvas widget

## Center Image

Unreleased:

- [Improvement] Minor performance improvements

## Brush Transformations

Unreleased:

- ...

Update v2.0.0:

- [Improvement] From Aseprite v1.3-rc2 - add a new menu group for the Brush Transformations options
