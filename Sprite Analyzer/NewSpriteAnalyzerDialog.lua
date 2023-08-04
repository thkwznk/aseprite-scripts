local AnalysisMode = {
    Silhouette = "Silhouette",
    Outline = "Outline",
    Values = "Values",
    ColorBlocks = "Color Blocks"
}

local SpriteAnalyzerDialog = function(options)
    local dialog = Dialog {
        title = options.title or "Sprite Analyzer",
        onclose = options.onclose
    }

    dialog --
    :canvas{
        width = 100,
        height = 100,
        onpaint = function(ev)
            local gc = ev.context
            gc:drawImage(options.imageProvider:GetImage(), 0, 0)
        end
    } --
    :combobox{
        id = "analysisMode",
        label = "Mode:",
        option = AnalysisMode.Silhouette,
        options = {
            AnalysisMode.Silhouette, AnalysisMode.Outline, AnalysisMode.Values,
            AnalysisMode.ColorBlocks
        },
        onchange = function() options.onchange() end
    } --
    :check{
        id = "flip",
        label = "Flip:",
        onclick = function() options.onchange() end
    } --

    return dialog
end

return SpriteAnalyzerDialog
