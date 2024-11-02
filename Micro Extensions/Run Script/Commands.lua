local function HasTileset(layers)
    for _, layer in ipairs(layers) do
        if layer.isGroup and HasTileset(layer.layers) then return true end
        if layer.isTilemap then return true end
    end
end

local function EnableForSprite() return app.activeSprite ~= nil end
local function EnableForImage() return app.activeCel ~= nil end
local function EnableForSelection()
    local sprite = app.activeSprite
    if sprite == nil then return false end

    return not sprite.selection.isEmpty
end
local function EnableForTileset()
    local sprite = app.activeSprite
    if sprite == nil then return false end

    return HasTileset(sprite.layers)
end

return {
    {command = "About", name = "About", path = "Help > About"}, {
        command = "AdvancedMode",
        name = "Advanced Mode",
        path = "View > AdvancedMode"
    }, {
        command = "AutocropSprite",
        name = "Trim Sprite",
        path = "Sprite > Trim",
        onenable = EnableForSprite
    }, {
        command = "BackgroundFromLayer",
        name = "Convert Layer to Background",
        path = "Layer > Convert To > Background",
        onenable = EnableForSprite
    }, {
        command = "BrightnessContrast",
        name = "Brightness/Contrast",
        path = "Edit > Adjustments > Brightness/Contrast",
        onenable = EnableForImage
    }, {
        command = "CanvasSize",
        name = "Canvas Size",
        path = "Sprite > Canvas Size",
        onenable = EnableForSprite
    }, {
        command = "CelProperties",
        name = "Cel Properties",
        path = "Frame > Cel Properties",
        onenable = EnableForImage
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to RGB",
        path = "Sprite > Color Mode > RGB",
        parameters = {format = "rgb"},
        onenable = EnableForSprite
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to Grayscale",
        path = "Sprite > Color Mode > Grayscale",
        parameters = {format = "gray"},
        onenable = EnableForSprite
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to Indexed",
        path = "Sprite > Color Mode > Indexed",
        parameters = {format = "indexed"},
        onenable = EnableForSprite
    }, {
        command = "CloseFile",
        name = "Close File",
        path = "File > Close File",
        onenable = EnableForSprite
    }, {
        command = "CloseAllFiles",
        name = "Close All Files",
        path = "File > Close All Files"
    }, {
        command = "ColorCurve",
        name = "Color Curve",
        path = "Edit > Adjustments > Color Curve",
        onenable = EnableForImage
    }, {
        command = "ColorQuantization",
        name = "New Palette from Sprite",
        path = "Palette > New Palette from Sprite",
        onenable = EnableForSprite
    }, {
        command = "ConvolutionMatrix",
        name = "Convolution Matrix",
        path = "Edit > FX > Convolution Matrix",
        onenable = EnableForImage
    }, {
        command = "CropSprite",
        name = "Crop",
        path = "Edit > Crop",
        onenable = EnableForSelection
    }, {
        command = "Despeckle",
        name = "Despeckle (Median Filter)",
        path = "Edit > FX > Despeckle (Median Filter)",
        onenable = EnableForImage
    }, {
        command = "DeveloperConsole",
        name = "Developer Console",
        path = "Developer Console"
    }, {
        command = "DuplicateLayer",
        name = "Duplicate Layer",
        path = "Layer > Duplicate",
        onenable = EnableForSprite
    }, {
        command = "DuplicateSprite",
        name = "Duplicate Sprite",
        path = "Sprite > Duplicate",
        onenable = EnableForSprite
    }, {
        command = "DuplicateView",
        name = "Duplicate View",
        path = "View > Duplicate View"
    }, {command = "Exit", name = "Exit", path = "File > Exit"}, {
        command = "ExportSpriteSheet",
        name = "Export Sprite Sheet",
        path = "File > Export > Export Sprite Sheet",
        onenable = EnableForSprite
    }, {
        command = "ExportTileset",
        name = "Export Tileset",
        path = "File > Export > Export Tileset",
        onenable = EnableForTileset
    }, {
        command = "FitScreen",
        name = "Fit Screen",
        path = "Zoom > Fit Screen",
        onenable = EnableForSprite
    }, {
        command = "FrameProperties",
        name = "Frame Properties",
        path = "Frame > Frame Properties",
        onenable = EnableForSprite
    }, {
        command = "FullscreenPreview",
        name = "Full Screen Preview",
        path = "View > Full Screen Preview",
        onenable = EnableForSprite
    }, {
        command = "GridSettings",
        name = "Grid Settings",
        path = "View > Grid > Grid Settings"
    }, {
        command = "HueSaturation",
        name = "Hue/Saturation",
        path = "Edit > Adjustments > Hue/Saturation",
        onenable = EnableForImage
    }, {
        command = "ImportSpriteSheet",
        name = "Import Sprite Sheet",
        path = "File > Import > Import Sprite Sheet"
    }, {
        command = "InvertColor",
        name = "Invert Color",
        path = "Edit > Invert",
        onenable = EnableForImage
    }, {
        command = "InvertMask",
        name = "Inverse Selection",
        path = "Select > Inverse",
        onenable = EnableForImage
    }, {
        command = "KeyboardShortcuts",
        name = "Keyboard Shortcuts",
        path = "Edit > Keyboard Shortcuts"
    }, {
        command = "LayerFromBackground",
        name = "Layer from Background",
        path = "Layer > Convert To > Layer",
        onenable = EnableForSprite
    }, {
        command = "LayerProperties",
        name = "Layer Properties",
        path = "Layer > Properties",
        onenable = EnableForSprite
    }, {
        command = "LoadMask",
        name = "Load from MSK file",
        path = "Select > Load from MSK file",
        onenable = EnableForSprite
    }, {
        command = "MaskByColor",
        name = "Select Color Range",
        path = "Select > Color Range",
        onenable = EnableForSprite
    }, {command = "MaskContent", name = "Transform", path = "Edit > Transform"},
    {
        command = "ModifySelection",
        name = "Border Selection",
        path = "Select > Modify > Border",
        parameters = {modifier = "border"},
        onenable = EnableForSelection
    }, {
        command = "ModifySelection",
        name = "Expand Selection",
        path = "Select > Modify > Expand",
        parameters = {modifier = "expand"},
        onenable = EnableForSelection
    }, {
        command = "ModifySelection",
        name = "Contract Selection",
        path = "Select > Modify > Contract",
        parameters = {modifier = "contract"},
        onenable = EnableForSelection
    }, {command = "NewFile", name = "New File", path = "File > New"}, {
        command = "NewFrameTag",
        name = "New Tag",
        path = "Frame > Tags > New Tag",
        onenable = EnableForSprite
    }, {
        command = "NewFrame",
        name = "New Frame",
        path = "Frame > New Frame",
        onenable = EnableForSprite
    }, {
        command = "NewLayer",
        name = "New Layer",
        path = "Layer > New > New Layer",
        onenable = EnableForSprite
    }, {
        command = "NewSpriteFromSelection",
        name = "New Sprite from Selection",
        path = "Edit > New Sprite from Selection",
        onenable = EnableForSelection
    }, {command = "OpenFile", name = "Open File", path = "File > Open"}, {
        command = "OpenScriptFolder",
        name = "Open Script Folder",
        path = "File > Scripts > Open Script Folder"
    }, {command = "Options", name = "Preferences", path = "Edit > Preferences"},
    {
        command = "Outline",
        name = "Outline",
        path = "Edit > FX > Outline",
        onenable = EnableForImage
    }, {
        command = "PasteText",
        name = "Insert Text",
        path = "Edit > Insert Text",
        onenable = EnableForImage
    }, {
        command = "RepeatLastExport",
        name = "Repeat Last Export",
        path = "File > Export > Repeat Last Export",
        onenable = EnableForSprite
    }, {
        command = "ReplaceColor",
        name = "Replace Color",
        path = "Edit > Replace Color",
        onenable = EnableForSprite
    }, {
        command = "Rotate",
        name = "Rotate Canvas 180",
        path = "Sprite > Rotate Canvas > 180",
        parameters = {angle = "180"},
        onenable = EnableForSprite
    }, {
        command = "Rotate",
        name = "Rotate Canvas 90 CW",
        path = "Sprite > Rotate Canvas > 90 CW",
        parameters = {angle = "90"},
        onenable = EnableForSprite
    }, {
        command = "Rotate",
        name = "Rotate Canvas 90 CCW",
        path = "Sprite > Rotate Canvas > 90 CCW",
        parameters = {angle = "-90"},
        onenable = EnableForSprite
    }, {
        command = "Rotate",
        name = "Rotate 180",
        path = "Edit > Rotate > 180",
        parameters = {target = "mask", angle = "180"},
        onenable = EnableForImage
    }, {
        command = "Rotate",
        name = "Rotate 90 CW",
        path = "Edit > Rotate > 90 CW",
        parameters = {target = "mask", angle = "90"},
        onenable = EnableForImage
    }, {
        command = "Rotate",
        name = "Rotate 90 CCW",
        path = "Edit > Rotate > 90 CCW",
        parameters = {target = "mask", angle = "-90"},
        onenable = EnableForImage
    }, {
        command = "SaveFile",
        name = "Save File",
        path = "File > Save",
        onenable = EnableForSprite
    }, {
        command = "SaveFileAs",
        name = "Save File As",
        path = "File > Save As",
        onenable = EnableForSprite
    }, {
        command = "SaveFileCopyAs",
        name = "Export File",
        path = "File > Export > Export As",
        onenable = EnableForSprite
    }, {
        command = "SaveMask",
        name = "Save to MSK file",
        path = "Select > Save to MSK file",
        onenable = EnableForSprite
    }, {
        command = "SelectionAsGrid",
        name = "Selection as Grid",
        path = "View > Grid > Selection as Grid",
        onenable = EnableForSelection
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
        path = "View > Show Onion Skin",
        onenable = EnableForSprite
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
        path = "Sprite > Properties",
        onenable = EnableForSprite
    }, {
        command = "SpriteSize",
        name = "Sprite Size",
        path = "Sprite > Sprite Size",
        onenable = EnableForSprite
    }, {
        command = "TiledMode",
        name = "View Tiled in None Axes",
        path = "View > Tiled Mode > None",
        parameters = {axis = "none"},
        onenable = EnableForSprite
    }, {
        command = "TiledMode",
        name = "View Tiled in Both Axes",
        path = "View > Tiled Mode > Tile in Both Axes",
        parameters = {axis = "both"},
        onenable = EnableForSprite
    }, {
        command = "TiledMode",
        name = "View Tiled in X Axis",
        path = "View > Tiled Mode > Tile in X Axis",
        parameters = {axis = "x"},
        onenable = EnableForSprite
    }, {
        command = "TiledMode",
        name = "View Tiled in Y Axis",
        path = "View > Tiled Mode > Tile in Y Axis",
        parameters = {axis = "y"},
        onenable = EnableForSprite
    }, {
        command = "ToggleTimelineThumbnails",
        name = "Toggle Timeline Thumbnails",
        path = "Timeline > Toggle Thumbnails",
        onenable = EnableForSprite
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
