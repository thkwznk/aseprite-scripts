# Roadmap

## Time Tracking

Unreleased:

- ...

Update v1.0.3.
- [Feature] Milestone trackers

## Theme Preferences

Unreleased:

- [Fix] Updating the theme while the active sprite is in Indexed (or Grayscale) color mode no longer breaks the theme
- [Fix] Correctly load system fonts for macOS
- [Improvement] For Windows and macOS - allow for choosing user fonts

Next:

- [Fix] Test and fix font file paths for different OSs

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

- ...

Future:

- [Fix] Parallax doesn't generate correctly if the timeline is closed/hidden - cels aren't linked 
- [Feature] Parallax - add an options for delaying layers reappearing
- [Feature] Parallax - add an option to generate only from the selected frames
- [Feature] Parallax - add alternative movement functions

## Magic Pencil

Unreleased:

- [Improvement] Improve performance
- [Fix] Ignore the selected pencil ink to avoid it causing issues with the Magic Pencil

Update v1.0.4:

- [Feature] Move graffiti simulation to Magic Pencil from Substance Sim
- [Improvement] Rework the dialog UI to accommodate the number of options

Future:

- [Feature] Two Tone
- [Improvement] Allow for shifting multiple components at the same time (also, possibly, with different values?)
- [Fix] Edge case where drawing on an empty cel results in not processing the image correctly - just check if the whole image is only magic color
- Unlock as much as possible for all color modes - this is more difficult than I thought, I can't use magic colors on an indexed image (maybe I could use white/black there?)

## Sprite Analyzer

Unreleased:

- ...

Update v1.0.1:

- [Fix] Calculations in the initial version were using incorrect values
- [Refactor] Use app.alert for the confirmation dialog
- [Improvement] Try using linear RGB for distance calculations
- [Improvement] Optimise how part of the image is taken from the source

## On-Screen Controls

Unreleased:

- [Improvement] Rework dialog to use nested menus

Update v2.0.0:

- [Improvement] Add sliders to resize color in the palette and thumbnails on the timeline
- [Improvement] Add a button to make a new brush from selection
- [Improvement] Add buttons for switching layers up/down, changing their visibility, locking them, and selecting layer content
- [Improvement] Deselect? Invert selection?
- [Fix] Clear can delete a layer, it shouldn't
- [Change] Remove the Command button

## NxPA Studio

Unreleased:

- ...

Update v?.?.?:

- [Fix] *Add Inbetween Frames* should work with groups, currently it doesn't
- [Improvement] *Advanced Scaling* lock the UI when dialog is shown for consistency with the rest of Aseprite and show "Processing..." dialog when resizing
- [Improvement] *Analyze Colors* reintroduce color replacement and color selection on click