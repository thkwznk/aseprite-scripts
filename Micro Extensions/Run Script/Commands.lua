return {
    {command = "About", name = "About"},
    {command = "AdvancedMode", name = "Advanced Mode"},
    {command = "AutocropSprite", name = "Trim"},
    {command = "BackgroundFromLayer", name = "Convert Layer to Background"},
    {command = "BrightnessContrast", name = "Brightness/Contrast"},
    {command = "CanvasSize", name = "Canvas Size"},
    {command = "CelProperties", name = "Cel Properties"}, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to RGB",
        parameters = {format = "rgb"}
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to Grayscale",
        parameters = {format = "gray"}
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to Indexed",
        parameters = {format = "indexed"}
    }, {command = "CloseAllFiles", name = "Close All Files"},
    {command = "CloseFile", name = "Close File"},
    {command = "ColorCurve", name = "Color Curve"},
    {command = "ColorQuantization", name = "New Palette from Sprite"},
    {command = "ConvolutionMatrix", name = "Convolution Matrix"},
    -- {command = "CropSprite", name = "Crop"}, -- TODO: Consider implementing a function that enables/disables command button in context
    {command = "Despeckle", name = "Despeckle (Median Filter)"},
    {command = "DeveloperConsole", name = "Developer Console"},
    {command = "DiscardBrush", name = "DiscardBrush"}, -- TODO: Check
    {command = "DuplicateLayer", name = "Duplicate Layer"},
    {command = "DuplicateSprite", name = "Duplicate Sprite"},
    {command = "DuplicateView", name = "Duplicate View"},
    {command = "Exit", name = "Exit"},
    {command = "ExportSpriteSheet", name = "Export Sprite Sheet"},
    {command = "ExportTileset", name = "Export Tileset"},
    {command = "FitScreen", name = "Fit Screen"},
    {command = "FrameProperties", name = "Frame Properties"},
    {command = "FullscreenPreview", name = "Full Screen Preview"},
    {command = "GridSettings", name = "Grid Settings"},
    {command = "HueSaturation", name = "Hue/Saturation"},
    {command = "ImportSpriteSheet", name = "Import Sprite Sheet"},
    {command = "InvertColor", name = "Invert Color"},
    {command = "InvertMask", name = "Inverse Selection"},
    {command = "KeyboardShortcuts", name = "Keyboard Shortcuts"},
    {command = "LayerFromBackground", name = "Layer from Background"},
    {command = "LayerProperties", name = "Layer Properties"},
    {command = "LoadMask", name = "Load from MSK file"},
    {command = "MaskByColor", name = "Select Color Range"},
    {command = "MaskContent", name = "Transform"}, {
        command = "ModifySelection",
        name = "Border Selection",
        parameters = {modifier = "border"}
    }, {
        command = "ModifySelection",
        name = "Expand Selection",
        parameters = {modifier = "expand"}
    }, {
        command = "ModifySelection",
        name = "Contract Selection",
        parameters = {modifier = "contract"}
    }, {command = "NewFile", name = "New File"},
    {command = "NewFrameTag", name = "New Tag"},
    {command = "NewFrame", name = "New Frame"},
    {command = "NewLayer", name = "New Layer"},
    {command = "NewSpriteFromSelection", name = "New Sprite from Selection"},
    {command = "OpenFile", name = "Open File"},
    {command = "OpenScriptFolder", name = "Open Script Folder"},
    {command = "Options", name = "Preferences"},
    {command = "Outline", name = "Outline"},
    {command = "PasteText", name = "Insert Text"},
    {command = "RepeatLastExport", name = "Repeat Last Export"},
    {command = "ReplaceColor", name = "Replace Color"},
    {
        command = "Rotate",
        name = "Rotate Canvas 180",
        parameters = {angle = "180"}
    },
    {
        command = "Rotate",
        name = "Rotate Canvas 90 CW",
        parameters = {angle = "90"}
    }, {
        command = "Rotate",
        name = "Rotate Canvas 90 CCW",
        parameters = {angle = "-90"}
    }, {
        command = "Rotate",
        name = "Rotate 180",
        parameters = {target = "mask", angle = "180"}
    }, {
        command = "Rotate",
        name = "Rotate 90 CW",
        parameters = {target = "mask", angle = "90"}
    }, {
        command = "Rotate",
        name = "Rotate 90 CCW",
        parameters = {target = "mask", angle = "-90"}
    }, {command = "SaveFile", name = "Save File"},
    {command = "SaveFileAs", name = "Save File As"},
    {command = "SaveFileCopyAs", name = "Export File"},
    {command = "SaveMask", name = "Save to MSK file"},
    {command = "SelectionAsGrid", name = "Selection as Grid"},
    {command = "ShowAutoGuides", name = "Show Auto Guides"},
    {command = "ShowExtras", name = "Show Extras"},
    {command = "ShowGrid", name = "Show Grid"},
    {command = "ShowLayerEdges", name = "Show Layer Edges"},
    {command = "ShowOnionSkin", name = "Show Onion Skin"},
    {command = "ShowPixelGrid", name = "Show Pixel Grid"},
    {command = "ShowSelectionEdges", name = "Show Selection Edges"},
    {command = "ShowSlices", name = "Show Slices"},
    {command = "SnapToGrid", name = "Snap to Grid"},
    {command = "SpriteProperties", name = "Sprite Properties"},
    {command = "SpriteSize", name = "Sprite Size"}, {
        command = "TiledMode",
        name = "View Tiled in None Axes",
        parameters = {axis = "none"}
    }, {
        command = "TiledMode",
        name = "View Tiled in Both Axes",
        parameters = {axis = "both"}
    }, {
        command = "TiledMode",
        name = "View Tiled in X Axis",
        parameters = {axis = "x"}
    }, {
        command = "TiledMode",
        name = "View Tiled in Y Axis",
        parameters = {axis = "y"}
    },
    {command = "ToggleTimelineThumbnails", name = "Toggle Timeline Thumbnails"},
    {command = "UndoHistory", name = "Undo History"}
    --
    -- Skipped, requires parameters
    -- { command = "AddColor", name ="" },
    -- {command = "ChangeBrush", name = ""},
    -- {command = "ChangeColor", name = ""},
    -- {command = "Launch", name = ""},
    -- {command = "LayerOpacity", name = ""},
    --
    -- Skipped, requires context
    -- {command = "Cancel", name = ""},
    -- {command = "CelOpacity", name = ""},
    -- {command = "ContiguousFill", name = ""},
    -- {command = "FlattenLayers", name = ""},
    -- {command = "FrameTagProperties", name = ""},
    -- {command = "LayerLock", name = ""},
    -- {command = "LayerVisibility", name = ""},
    -- {command = "LinkCels", name = ""},
    -- {command = "MergeDownLayer", name = ""},
    -- {command = "SetLoopSection", name = ""},
    --
    -- Skipped, already can be achieved with a single key
    -- {command = "ClearCel", name = ""},
    -- {command = "Clear", name = ""},
    -- {command = "DeselectMask", name = ""},
    -- {command = "Fill", name = ""},
    -- {command = "GotoFirstFrameInTag", name = ""},
    -- {command = "GotoFirstFrame", name = ""}, {command = "GotoFrame", name = ""},
    -- {command = "GotoLastFrameInTag", name = ""},
    -- {command = "GotoLastFrame", name = ""},
    -- {command = "GotoNextFrameWithSameTag", name = ""},
    -- {command = "GotoNextFrame", name = ""},
    -- {command = "GotoNextLayer", name = ""},
    -- {command = "GotoNextTab", name = ""},
    -- {command = "GotoPreviousFrameWithSameTag", name = ""},
    -- {command = "GotoPreviousFrame", name = ""},
    -- {command = "GotoPreviousLayer", name = ""},
    -- {command = "GotoPreviousTab", name = ""},
    --
    -- Skipped, already can be achieved with a keyboard shortcut
    -- {command = "CopyCel", name = ""},
    -- {command = "CopyColors", name = ""},
    -- {command = "CopyMerged", name = ""},
    -- {command = "Copy", name = ""},
    -- {command = "Cut", name = ""},
    -- {command = "Flip", name = ""},
    -- {command = "MaskAll", name = ""},
    --
    -- Skipped, tool
    -- {command = "Eyedropper", name = "Eyedropper"},
    --
    -- Skipped
    -- {command = "Home", name = ""},
    -- {command = "LoadPalette", name = ""},
    -- {command = "MoveCel", name = ""}, 
    -- {command = "MoveColors", name = ""},
    -- {command = "MoveMask", name = ""},
    -- {command = "NewBrush", name = ""},
    -- {command = "OpenBrowser", name = "Open Browser"},
    -- {command = "OpenGroup", name = ""},
    -- {command = "OpenInFolder", name = ""},
    -- {command = "OpenWithApp", name = ""},
    -- {command = "PaletteEditor", name = ""},
    -- {command = "PaletteSize", name = ""},
    -- {command = "Paste", name = ""},
    -- {command = "PixelPerfectMode", name = ""},
    -- {command = "PlayAnimation", name = ""},
    -- {command = "PlayPreviewAnimation", name = ""},
    -- {command = "Redo", name = ""},
    -- {command = "Refresh", name = ""},
    -- {command = "RemoveFrameTag", name = ""},
    -- {command = "RemoveFrame", name = ""},
    -- {command = "RemoveLayer", name = ""},
    -- {command = "RemoveSlice", name = ""},
    -- {command = "RunScript", name = ""}, 
    -- {command = "SavePalette", name = "Save Palette"},
    -- {command = "ScrollCenter", name = "Scroll Center"},
    -- {command = "Scroll", name = ""},
    -- {command = "SelectTile", name = ""},
    -- {command = "ReselectMask", name = ""},
    -- {command = "ReverseFrames", name = ""},
    -- {command = "SetColorSelector", name = ""},
    -- {command = "SetInkType", name = ""},
    -- {command = "SetPaletteEntrySize", name = ""},
    -- {command = "SetPalette", name = ""},
    -- {command = "SetSameInk", name = ""},
    -- {command = "ShowBrushPreview", name = "Show Brush Preview"}, -- Skipped, a preferences option
    -- {command = "SliceProperties", name = "Slice Properties"},
    -- {command = "Stroke", name = ""},
    -- {command = "SwitchColors", name = ""},
    -- {command = "SymmetryMode", name = ""},
    -- {command = "Timeline", name = ""},
    -- {command = "TogglePreview", name = ""},
    -- {command = "Undo", name = ""},
    -- {command = "UnlinkCelcommand", name = ""}
}
