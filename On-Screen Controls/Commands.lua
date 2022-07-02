function StartsWith(s, prefix) return s:sub(1, prefix:len()) == prefix end

local Commands = {};

Commands.all = {
    "About", "AddColor", "AdvancedMode", "AutocropSprite",
    "BackgroundFromLayer", "BrightnessContrast", "Cancel", "CanvasSize",
    "CelOpacity", "CelProperties", "ChangeBrush", "ChangeColor",
    "ChangePixelFormat", "ClearCel", "Clear", "CloseAllFiles", "CloseFile",
    "ColorCurve", "ColorQuantization", "ContiguousFill", "ConvolutionMatrix",
    "CopyCel", "CopyColors", "CopyMerged", "Copy", "CropSprite", "Cut",
    "DeselectMask", "Despeckle", "DeveloperConsole", "DiscardBrush",
    "DuplicateLayer", "DuplicateSprite", "DuplicateView", "Exit",
    "ExportSpriteSheet", "Eyedropper", "Fill", "FitScreen", "FlattenLayers",
    "Flip", "FrameProperties", "FrameTagProperties", "FullscreenPreview",
    "GotoFirstFrameInTag", "GotoFirstFrame", "GotoFrame", "GotoLastFrameInTag",
    "GotoLastFrame", "GotoNextFrameWithSameTag", "GotoNextFrame",
    "GotoNextLayer", "GotoNextTab", "GotoPreviousFrameWithSameTag",
    "GotoPreviousFrame", "GotoPreviousLayer", "GotoPreviousTab", "GridSettings",
    "Home", "HueSaturation", "ImportSpriteSheet", "InvertColor", "InvertMask",
    "KeyboardShortcuts", "Launch", "LayerFromBackground", "LayerLock",
    "LayerOpacity", "LayerProperties", "LayerVisibility", "LinkCels",
    "LoadMask", "LoadPalette", "MaskAll", "MaskByColor", "MaskContent",
    "MergeDownLayer", "ModifySelection", "MoveCel", "MoveColors", "MoveMask",
    "NewBrush", "NewFile", "NewFrameTag", "NewFrame", "NewLayer",
    "NewSpriteFromSelection", "OpenBrowser", "OpenFile", "OpenGroup",
    "OpenInFolder", "OpenScriptFolder", "OpenWithApp", "Options", "Outline",
    "PaletteEditor", "PaletteSize", "PasteText", "Paste", "PixelPerfectMode",
    "PlayAnimation", "PlayPreviewAnimation", "Redo", "Refresh",
    "RemoveFrameTag", "RemoveFrame", "RemoveLayer", "RemoveSlice",
    "RepeatLastExport", "ReplaceColor", "ReselectMask", "ReverseFrames",
    "Rotate", "RunScript", "SaveFileAs", "SaveFileCopyAs", "SaveFile",
    "SaveMask", "SavePalette", "ScrollCenter", "Scroll", "SelectTile",
    "SelectionAsGrid", "SetColorSelector", "SetInkType", "SetLoopSection",
    "SetPaletteEntrySize", "SetPalette", "SetSameInk", "ShowAutoGuides",
    "ShowBrushPreview", "ShowExtras", "ShowGrid", "ShowLayerEdges",
    "ShowOnionSkin", "ShowPixelGrid", "ShowSelectionEdges", "ShowSlices",
    "SliceProperties", "SnapToGrid", "SpriteProperties", "SpriteSize", "Stroke",
    "SwitchColors", "SymmetryMode", "TiledMode", "Timeline", "TogglePreview",
    "ToggleTimelineThumbnails", "UndoHistory", "Undo", "UnlinkCel", "Zoom"
};

function Commands.GetPattern(text)
    local pattern = "";

    for i = 1, #text do
        local v = text:sub(i, i)
        pattern = pattern .. v .. ".*"
    end

    return pattern;
end

function Commands:Search(searchText)
    local pattern = self.GetPattern(searchText):lower();

    local results = {}

    for i, value in ipairs(self.all) do
        local searchResult = {text = value, weight = 0};

        local command = value:lower();

        if StartsWith(command, searchText:lower()) then
            searchResult.weight = 1;
        elseif command:match(pattern) then
            searchResult.weight = searchText:len() / command:len()
        end

        if searchResult.weight > 0 then
            table.insert(results, searchResult)
        end
    end

    table.sort(results, function(a, b) return a.weight > b.weight end)

    local textResult = {};
    for _, result in ipairs(results) do table.insert(textResult, result.text) end

    return textResult
end

return Commands;
