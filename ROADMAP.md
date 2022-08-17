# Roadmap

## Theme Preferences

Unreleased:

- [Improvement] Add pagination for the Load window

Update v1.0.1

- [Refactor] Add a Default model next to Template - Template is a template, default is default
- [Improvement] Improve Import - add a dialog window allowing the user to change the name of the imported config and additional button for saving and loading the config
- [Bug] Fix tab frames, it mixes button highlights with tab colors (either use all button colors or maybe use the tab colors? tab corner highlight?)

Future:

- [Feature] Support customising fonts
- [Feature] Test a Super Simple Mode where you can only edit the Tab color
- [Feature] Separate "field_background" when Aseprite fixes the menu shadow
- [Feature] Add a Dark theme template
- [Feature] Export to Aseprite theme (extension)
- [Feature] Add separate color for Tooltip Text (Tooltip Section?) - currently it doesn't work due to a bug
- [Feature] Generating a theme from the current color palette

## Magic Pencil

Unreleased:

- ...

Update v1.0.4:

- [Bug] Block opening multiple instances
- [Feature] Move graffiti simulation to Magic Pencil from Substance Sim
- [Feature] Two Tone
- [Improvement] Rework the dialog UI to accommodate the number of options
- [Improvement] Allow for shifting multiple components at the same time (also, possibly, with different values?)
- [Fix] Edge case where drawing on an empty cel results in not processing the image correctly - just check if the whole image is only magic color

Future:

- Unlock as much as possible for all color modes - this is more difficult than I thought, I can't use magic colors on an indexed image (maybe I could use white/black there?)

## Sprite Analyzer

Unreleased:

- ...

Update v1.0.1:

- [Fix] Calculations in the initial version were using incorrect values
- [Refactor] Use app.alert for the confirmation dialog
- [Improvement] Try using linear RGB for distance calculations
