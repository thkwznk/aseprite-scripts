return {
    {command = "About", name = "About"},
    -- { command = "AddColor", name ="" }, -- Skipped, requires parameters
    {command = "AdvancedMode", name = "Advanced Mode"},
    {command = "AutocropSprite", name = "Trim"},
    {command = "BackgroundFromLayer", name = "Convert Layer to Background"},
    {command = "BrightnessContrast", name = "Brightness/Contrast"},
    -- {command = "Cancel", name = ""}, -- Skipped, requires context
    {command = "CanvasSize", name = "Canvas Size"},
    -- {command = "CelOpacity", name = ""}, -- Skipped, requires context
    {command = "CelProperties", name = "Cel Properties"},
    -- {command = "ChangeBrush", name = ""}, -- Skipped, requires parameters
    -- {command = "ChangeColor", name = ""}, -- Skipped, requires parameters
    {
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
    },
    -- {command = "ClearCel", name = ""}, -- Skipped, already can be achieved with a single key
    -- {command = "Clear", name = ""}, -- Skipped, already can be achieved with a single key
    {command = "CloseAllFiles", name = "Close All Files"},
    {command = "CloseFile", name = "Close File"},
    {command = "ColorCurve", name = "Color Curve"},
    {command = "ColorQuantization", name = "New Palette from Sprite"},
    -- {command = "ContiguousFill", name = ""}, -- Skipped
    {command = "ConvolutionMatrix", name = "Convolution Matrix"},
    -- {command = "CopyCel", name = ""}, -- Skipped, already can be achieved with a keyboard shortcut
    -- {command = "CopyColors", name = ""}, -- Skipped, already can be achieved with a keyboard shortcut
    -- {command = "CopyMerged", name = ""},
    -- {command = "Copy", name = ""},
    -- {command = "CropSprite", name = "Crop"}, -- TODO: Consider implementing a function that enables/disables command button in context
    -- {command = "Cut", name = ""}, -- Skipped, already can be achieved with a keyboard shortcut
    -- {command = "DeselectMask", name = ""}, -- Skipped, already can be achieved with a single key
    {command = "Despeckle", name = "Despeckle (Median Filter)"},
    {command = "DeveloperConsole", name = "Developer Console"},
    {command = "DiscardBrush", name = "DiscardBrush"}, -- TODO: Check
    {command = "DuplicateLayer", name = "Duplicate Layer"},
    {command = "DuplicateSprite", name = "Duplicate Sprite"},
    {command = "DuplicateView", name = "Duplicate View"},
    {command = "Exit", name = "Exit"},
    {command = "ExportSpriteSheet", name = "Export Sprite Sheet"},
    {command = "ExportTileset", name = "Export Tileset"},
    -- {command = "Eyedropper", name = "Eyedropper"}, -- Skipped, tool
    -- {command = "Fill", name = ""}, -- Skipped, already can be achieved with a single key
    {command = "FitScreen", name = "Fit Screen"},
    -- {command = "FlattenLayers", name = ""}, -- Skipped, requires context
    -- {command = "Flip", name = ""},
    {command = "FrameProperties", name = "Frame Properties"},
    -- {command = "FrameTagProperties", name = ""}, -- Skipped, requires context
    {command = "FullscreenPreview", name = "Full Screen Preview"},
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
    {command = "GridSettings", name = "Grid Settings"},
    -- {command = "Home", name = ""},
    {command = "HueSaturation", name = "Hue/Saturation"},
    {command = "ImportSpriteSheet", name = "Import Sprite Sheet"},
    {command = "InvertColor", name = "Invert Color"},
    {command = "InvertMask", name = "Inverse Selection"},
    {command = "KeyboardShortcuts", name = "Keyboard Shortcuts"},
    -- {command = "Launch", name = ""},
    {command = "LayerFromBackground", name = "Layer from Background"},
    -- {command = "LayerLock", name = ""},
    -- {command = "LayerOpacity", name = ""},
    {command = "LayerProperties", name = "Layer Properties"},
    -- {command = "LayerVisibility", name = ""},
    -- {command = "LinkCels", name = ""},
    {command = "LoadMask", name = "Load from MSK file"},
    -- {command = "LoadPalette", name = ""},
    -- {command = "MaskAll", name = ""},
    {command = "MaskByColor", name = "Select Color Range"},
    {command = "MaskContent", name = "Transform"},
    -- {command = "MergeDownLayer", name = ""},
    {
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
    }, -- {command = "MoveCel", name = ""}, 
    -- {command = "MoveColors", name = ""},
    -- {command = "MoveMask", name = ""},
    -- {command = "NewBrush", name = ""},
    {command = "NewFile", name = "New File"},
    {command = "NewFrameTag", name = "New Tag"},
    {command = "NewFrame", name = "New Frame"},
    {command = "NewLayer", name = "New Layer"},
    {command = "NewSpriteFromSelection", name = "New Sprite from Selection"},
    -- {command = "OpenBrowser", name = "Open Browser"}, -- SKipped, requires parameters
    {command = "OpenFile", name = "Open File"},
    -- {command = "OpenGroup", name = ""},
    -- {command = "OpenInFolder", name = ""},
    {command = "OpenScriptFolder", name = "Open Script Folder"},
    -- {command = "OpenWithApp", name = ""},
    {command = "Options", name = "Preferences"},
    {command = "Outline", name = "Outline"},
    -- {command = "PaletteEditor", name = ""},
    -- {command = "PaletteSize", name = ""},
    {command = "PasteText", name = "Insert Text"},
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
    {command = "RepeatLastExport", name = "Repeat Last Export"},
    {command = "ReplaceColor", name = "Replace Color"},
    -- {command = "ReselectMask", name = ""},
    -- {command = "ReverseFrames", name = ""},
    {
        command = "Rotate",
        name = "Rotate Canvas 90 CW",
        parameters = {angle = "90"}
    }, {
        command = "Rotate",
        name = "Rotate Canvas 90 CCW",
        parameters = {angle = "-90"}
    },
    {
        command = "Rotate",
        name = "Rotate Canvas 180",
        parameters = {angle = "180"}
    }, {
        command = "Rotate",
        name = "Rotate 90 CW",
        parameters = {target = "mask", angle = "90"}
    }, {
        command = "Rotate",
        name = "Rotate 90 CCW",
        parameters = {target = "mask", angle = "-90"}
    }, {
        command = "Rotate",
        name = "Rotate 180",
        parameters = {target = "mask", angle = "180"}
    }, -- {command = "RunScript", name = ""}, 
    -- {command = "SaveFile", name = ""},
    -- {command = "SaveFileAs", name = ""},
    -- {command = "SaveFileCopyAs", name = ""}, 
    {command = "SaveMask", name = "Save to MSK file"},
    -- {command = "SavePalette", name = "Save Palette"},
    -- {command = "ScrollCenter", name = "Scroll Center"},
    -- {command = "Scroll", name = ""},
    -- {command = "SelectTile", name = ""},
    {command = "SelectionAsGrid", name = "Selection as Grid"},
    -- {command = "SetColorSelector", name = ""},
    -- {command = "SetInkType", name = ""},
    -- {command = "SetLoopSection", name = ""}, -- Skipped, requires context
    -- {command = "SetPaletteEntrySize", name = ""},
    -- {command = "SetPalette", name = ""},
    -- {command = "SetSameInk", name = ""},
    {command = "ShowAutoGuides", name = "Show Auto Guides"},
    -- {command = "ShowBrushPreview", name = "Show Brush Preview"}, -- Skipped, a preferences option
    {command = "ShowExtras", name = "Show Extras"},
    {command = "ShowGrid", name = "Show Grid"},
    {command = "ShowLayerEdges", name = "Show Layer Edges"},
    {command = "ShowOnionSkin", name = "Show Onion Skin"},
    {command = "ShowPixelGrid", name = "Show Pixel Grid"},
    {command = "ShowSelectionEdges", name = "Show Selection Edges"},
    {command = "ShowSlices", name = "Show Slices"},
    -- {command = "SliceProperties", name = "Slice Properties"},
    {command = "SnapToGrid", name = "Snap to Grid"},
    {command = "SpriteProperties", name = "Sprite Properties"},
    {command = "SpriteSize", name = "Sprite Size"},
    -- {command = "Stroke", name = ""},
    -- {command = "SwitchColors", name = ""},
    -- {command = "SymmetryMode", name = ""},
    {
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
    }, -- {command = "Timeline", name = ""},
    -- {command = "TogglePreview", name = ""},
    {command = "ToggleTimelineThumbnails", name = "Toggle Timeline Thumbnails"},
    {command = "UndoHistory", name = "Undo History"}
    -- {command = "Undo", name = ""},
    -- {command = "UnlinkCelcommand", name = ""}
}
