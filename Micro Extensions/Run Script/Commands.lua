return {
    {command = "About", name = "About", path = "Help > About"}, {
        command = "AdvancedMode",
        name = "Advanced Mode",
        path = "View > AdvancedMode"
    },
    {command = "AutocropSprite", name = "Trim Sprite", path = "Sprite > Trim"},
    {
        command = "BackgroundFromLayer",
        name = "Convert Layer to Background",
        path = "Layer > Convert To > Background"
    }, {
        command = "BrightnessContrast",
        name = "Brightness/Contrast",
        path = "Edit > Adjustments > Brightness/Contrast"
    },
    {
        command = "CanvasSize",
        name = "Canvas Size",
        path = "Sprite > Canvas Size"
    }, {
        command = "CelProperties",
        name = "Cel Properties",
        path = "Frame > Cel Properties"
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to RGB",
        path = "Sprite > Color Mode > RGB",
        parameters = {format = "rgb"}
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to Grayscale",
        path = "Sprite > Color Mode > Grayscale",
        parameters = {format = "gray"}
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to Indexed",
        path = "Sprite > Color Mode > Indexed",
        parameters = {format = "indexed"}
    }, {command = "CloseFile", name = "Close File", path = "File > Close File"},
    {
        command = "CloseAllFiles",
        name = "Close All Files",
        path = "File > Close All Files"
    }, {
        command = "ColorCurve",
        name = "Color Curve",
        path = "Edit > Adjustments > Color Curve"
    }, {
        command = "ColorQuantization",
        name = "New Palette from Sprite",
        path = "Palette > New Palette from Sprite"
    }, {
        command = "ConvolutionMatrix",
        name = "Convolution Matrix",
        path = "Edit > FX > Convolution Matrix"
    },
    -- {command = "CropSprite", name = "Crop"}, -- TODO: Consider implementing a function that enables/disables command button in context
    {
        command = "Despeckle",
        name = "Despeckle (Median Filter)",
        path = "Edit > FX > Despeckle (Median Filter)"
    }, {
        command = "DeveloperConsole",
        name = "Developer Console",
        path = "Developer Console"
    }, {
        command = "DuplicateLayer",
        name = "Duplicate Layer",
        path = "Layer > Duplicate"
    }, -- TODO: In this form it's somewhat harder to search for
    {
        command = "DuplicateSprite",
        name = "Duplicate Sprite",
        path = "Sprite > Duplicate"
    }, {
        command = "DuplicateView",
        name = "Duplicate View",
        path = "View > Duplicate View"
    }, {command = "Exit", name = "Exit", path = "File > Exit"}, {
        command = "ExportSpriteSheet",
        name = "Export Sprite Sheet",
        path = "File > Export > Export Sprite Sheet"
    }, {
        command = "ExportTileset",
        name = "Export Tileset",
        path = "File > Export > Export Tileset"
    }, {command = "FitScreen", name = "Fit Screen", path = "Zoom > Fit Screen"},
    {
        command = "FrameProperties",
        name = "Frame Properties",
        path = "Frame > Frame Properties"
    }, {
        command = "FullscreenPreview",
        name = "Full Screen Preview",
        path = "View > Full Screen Preview"
    }, {
        command = "GridSettings",
        name = "Grid Settings",
        path = "View > Grid > Grid Settings"
    }, {
        command = "HueSaturation",
        name = "Hue/Saturation",
        path = "Edit > Adjustments > Hue/Saturation"
    }, {
        command = "ImportSpriteSheet",
        name = "Import Sprite Sheet",
        path = "File > Import > Import Sprite Sheet"
    }, {command = "InvertColor", name = "Invert Color", path = "Edit > Invert"},
    {
        command = "InvertMask",
        name = "Inverse Selection",
        path = "Select > Inverse"
    }, {
        command = "KeyboardShortcuts",
        name = "Keyboard Shortcuts",
        path = "Edit > Keyboard Shortcuts"
    }, {
        command = "LayerFromBackground",
        name = "Layer from Background",
        path = "Layer > Convert To > Layer"
    }, {
        command = "LayerProperties",
        name = "Layer Properties",
        path = "Layer > Properties"
    }, {
        command = "LoadMask",
        name = "Load from MSK file",
        path = "Select > Load from MSK file"
    }, {
        command = "MaskByColor",
        name = "Select Color Range",
        path = "Select > Color Range"
    }, {command = "MaskContent", name = "Transform", path = "Edit > Transform"},
    {
        command = "ModifySelection",
        name = "Border Selection",
        path = "Select > Modify > Border",
        parameters = {modifier = "border"}
    }, {
        command = "ModifySelection",
        name = "Expand Selection",
        path = "Select > Modify > Expand",
        parameters = {modifier = "expand"}
    }, {
        command = "ModifySelection",
        name = "Contract Selection",
        path = "Select > Modify > Contract",
        parameters = {modifier = "contract"}
    }, {command = "NewFile", name = "New File", path = "File > New"},
    {command = "NewFrameTag", name = "New Tag", path = "Frame > Tags > New Tag"},
    {command = "NewFrame", name = "New Frame", path = "Frame > New Frame"},
    {command = "NewLayer", name = "New Layer", path = "Layer > New > New Layer"},
    {
        command = "NewSpriteFromSelection",
        name = "New Sprite from Selection",
        path = "Edit > New Sprite from Selection"
    }, {command = "OpenFile", name = "Open File", path = "File > Open"}, {
        command = "OpenScriptFolder",
        name = "Open Script Folder",
        path = "File > Scripts > Open Script Folder"
    }, {command = "Options", name = "Preferences", path = "Edit > Preferences"},
    {command = "Outline", name = "Outline", path = "Edit > FX > Outline"},
    {command = "PasteText", name = "Insert Text", path = "Edit > Insert Text"},
    {
        command = "RepeatLastExport",
        name = "Repeat Last Export",
        path = "File > Export > Repeat Last Export"
    }, {
        command = "ReplaceColor",
        name = "Replace Color",
        path = "Edit > Replace Color"
    }, {
        command = "Rotate",
        name = "Rotate Canvas 180",
        path = "Sprite > Rotate Canvas > 180",
        parameters = {angle = "180"}
    }, {
        command = "Rotate",
        name = "Rotate Canvas 90 CW",
        path = "Sprite > Rotate Canvas > 90 CW",
        parameters = {angle = "90"}
    }, {
        command = "Rotate",
        name = "Rotate Canvas 90 CCW",
        path = "Sprite > Rotate Canvas > 90 CCW",
        parameters = {angle = "-90"}
    }, {
        command = "Rotate",
        name = "Rotate 180",
        path = "Edit > Rotate > 180",
        parameters = {target = "mask", angle = "180"}
    }, {
        command = "Rotate",
        name = "Rotate 90 CW",
        path = "Edit > Rotate > 90 CW",
        parameters = {target = "mask", angle = "90"}
    }, {
        command = "Rotate",
        name = "Rotate 90 CCW",
        path = "Edit > Rotate > 90 CCW",
        parameters = {target = "mask", angle = "-90"}
    }, {command = "SaveFile", name = "Save File", path = "File > Save"},
    {command = "SaveFileAs", name = "Save File As", path = "File > Save As"}, {
        command = "SaveFileCopyAs",
        name = "Export File",
        path = "File > Export > Export As"
    }, {
        command = "SaveMask",
        name = "Save to MSK file",
        path = "Select > Save to MSK file"
    }, {
        command = "SelectionAsGrid",
        name = "Selection as Grid",
        path = "View > Grid > Selection as Grid"
    }, {
        command = "ShowAutoGuides",
        name = "Show Auto Guides",
        path = "View > Show > Auto Guides"
    }, {command = "ShowExtras", name = "Show Extras", path = "View > Extras"},
    {command = "ShowGrid", name = "Show Grid", path = "View > Show > Grid"}, {
        command = "ShowLayerEdges",
        name = "Show Layer Edges",
        path = "View > Show > Layer Edges"
    }, {
        command = "ShowOnionSkin",
        name = "Show Onion Skin",
        path = "View > Show Onion Skin"
    }, {
        command = "ShowPixelGrid",
        name = "Show Pixel Grid",
        path = "View > Show > Pixel Grid"
    }, {
        command = "ShowSelectionEdges",
        name = "Show Selection Edges",
        path = "View > Show > Selection Edges"
    },
    {
        command = "ShowSlices",
        name = "Show Slices",
        path = "View > Show > Slices"
    }, {
        command = "SnapToGrid",
        name = "Snap to Grid",
        path = "View > Grid > Snap to Grid"
    }, {
        command = "SpriteProperties",
        name = "Sprite Properties",
        path = "Sprite > Properties"
    },
    {
        command = "SpriteSize",
        name = "Sprite Size",
        path = "Sprite > Sprite Size"
    }, {
        command = "TiledMode",
        name = "View Tiled in None Axes",
        path = "View > Tiled Mode > None",
        parameters = {axis = "none"}
    }, {
        command = "TiledMode",
        name = "View Tiled in Both Axes",
        path = "View > Tiled Mode > Tile in Both Axes",
        parameters = {axis = "both"}
    }, {
        command = "TiledMode",
        name = "View Tiled in X Axis",
        path = "View > Tiled Mode > Tile in X Axis",
        parameters = {axis = "x"}
    }, {
        command = "TiledMode",
        name = "View Tiled in Y Axis",
        path = "View > Tiled Mode > Tile in Y Axis",
        parameters = {axis = "y"}
    }, {
        command = "ToggleTimelineThumbnails",
        name = "Toggle Timeline Thumbnails",
        path = "Timeline > Toggle Thumbnails"
    },
    {
        command = "UndoHistory",
        name = "Undo History",
        path = "Edit > Undo History"
    }
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
    -- {command = "DiscardBrush", name = "Discard Brush"},
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
