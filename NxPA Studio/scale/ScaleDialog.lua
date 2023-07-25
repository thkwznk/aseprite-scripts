ScaleAlgorithm = dofile("./ScaleAlgorithm.lua")

local Algorithm = {
    Eagle = "Eagle",
    Scale2x = "Scale2x",
    Scale3x = "Scale3x",
    Hawk = "Hawk (Light)",
    HawkDark = "Hawk (Dark)"
}

local GetScaleBase = function(algorithm)
    if algorithm == Algorithm.Scale3x then return 3 end

    return 2
end

local GetSizes = function(scale)
    local result = {}
    for i = 1, 3 do table.insert(result, tostring((scale ^ i) * 100) .. "%") end
    return result
end

-- Store these in variables to preserve data between dialog opens
local selectedAlgorithm = Algorithm.Eagle
local selectedScale = "200%"
local selectedScaleBase = 2

return function(dialogTitle)
    local dialog = Dialog {title = dialogTitle}

    dialog --
    :separator{text = "Scaling:"} --
    :combobox{
        id = "algorithm",
        label = "Algorithm:",
        option = selectedAlgorithm,
        options = {
            Algorithm.Eagle, Algorithm.Scale2x, Algorithm.Scale3x,
            Algorithm.Hawk, Algorithm.HawkDark
        },
        onchange = function()
            local lastScaleBase = selectedScaleBase

            selectedAlgorithm = dialog.data.algorithm
            selectedScaleBase = GetScaleBase(selectedAlgorithm)

            if lastScaleBase ~= selectedScaleBase then
                local scales = GetSizes(selectedScaleBase)
                selectedScale = scales[1]

                dialog:modify{
                    id = "scale",
                    option = scales[1],
                    options = scales
                }
            end
        end
    } --
    :combobox{
        id = "scale",
        label = "Scale:",
        option = selectedScale,
        options = GetSizes(selectedScaleBase),
        onchange = function() selectedScale = dialog.data.scale end
    } --
    :separator() --
    :button{
        text = "OK",
        onclick = function()
            local scales = GetSizes(selectedScaleBase)
            local algorithm = dialog.data.algorithm

            app.transaction(function()
                local runTimes = 1

                for i = 1, #scales do
                    if scales[i] == dialog.data.scale then
                        runTimes = i
                        break
                    end
                end

                for _ = 1, runTimes do
                    if algorithm == Algorithm.Eagle then
                        ScaleAlgorithm:Eagle(app.activeSprite)
                    elseif algorithm == Algorithm.Scale2x then
                        ScaleAlgorithm:Scale2x(app.activeSprite)
                    elseif algorithm == Algorithm.Scale3x then
                        ScaleAlgorithm:Scale3x(app.activeSprite)
                    elseif algorithm == Algorithm.Hawk then
                        ScaleAlgorithm:Hawk(app.activeSprite)
                    elseif algorithm == Algorithm.HawkDark then
                        ScaleAlgorithm:Hawk(app.activeSprite, true)
                    end
                end
            end)

            app.refresh()
            dialog:close()
        end
    } --
    :button{text = "Cancel"}

    return dialog
end
