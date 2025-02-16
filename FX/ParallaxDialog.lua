local PreviewCanvas = dofile("./PreviewCanvas.lua")
local Parallax = dofile("./fx/Parallax.lua")

local function ParallaxDialog(options)
    local session = options.session
    local sprite = options.sprite

    local dialog = Dialog {title = options.title}

    local defaultSpeed = math.floor(math.sqrt(math.sqrt(sprite.width)))
    local defaultFrames = math.floor(sprite.width /
                                         math.max((defaultSpeed / 2), 1))

    local speedX = session:Get(sprite, "speedX") or defaultSpeed
    local speedY = session:Get(sprite, "speedY") or 0

    function AddLayerWidgets(layersToProcess, groupIndex)
        for i = #layersToProcess, 1, -1 do
            local layer = layersToProcess[i]

            if layer.isGroup then
                AddLayerWidgets(layer.layers, #layersToProcess - i)
            elseif layer.isVisible and not layer.isReference then
                local speed = defaultSpeed ^ (#layersToProcess - i)
                if groupIndex then
                    speed = defaultSpeed ^ groupIndex
                end

                if layer.isBackground then speed = 0 end

                -- Save the initial position of the layers
                local cel = layer.cels[1]

                -- If there's saved speed, use it
                if layer.data and #layer.data > 0 then
                    speed = tonumber(layer.data) or speed
                end

                local id = Parallax:_GetLayerId(layer)
                local label = Parallax:GetFullLayerName(layer)

                if cel then
                    dialog --
                    :number{
                        id = "distance-" .. id,
                        label = label,
                        decimals = 2,
                        text = tostring(speed),
                        enabled = not layer.isBackground,
                        visible = not layer.isBackground
                    }
                end
            end
        end
    end

    local RepaintPreviewImage = PreviewCanvas(dialog, 100, 100,
                                              app.activeSprite, Image(sprite),
                                              Point(0, 0))

    dialog -- 
    :slider{
        id = "shift", -- TODO: Replace with Play/Stop button playing preview in real-time
        label = "Shift",
        min = 0,
        max = sprite.width,
        value = 0,
        onchange = function()
            local previewImage = Parallax:Preview(sprite, dialog.data)
            RepaintPreviewImage(previewImage)

            app.refresh() -- TODO: remove?
        end
    } --
    :separator{text = "Distance"}

    AddLayerWidgets(sprite.layers)

    dialog --
    :separator{text = "Movement"} --
    :number{
        id = "speedX",
        label = "Speed [X/Y]",
        text = tostring(speedX),
        onchange = function()
            session:Set(sprite, "speedX", dialog.data.speedX)

            dialog:modify{
                id = "okButton",
                enabled = dialog.data.speedX ~= 0 or dialog.data.speedY ~= 0
            }
        end
    } --
    :number{
        id = "speedY",
        text = tostring(speedY),
        onchange = function()
            session:Set(sprite, "speedY", dialog.data.speedY)

            dialog:modify{
                id = "okButton",
                enabled = dialog.data.speedX ~= 0 or dialog.data.speedY ~= 0
            }
        end
    } --
    :separator{text = "Output"} --
    :number{id = "frames", label = "Frames", text = tostring(defaultFrames)} --
    :separator() --
    :button{
        id = "okButton",
        text = "&OK",
        enabled = speedX ~= 0 or speedY ~= 0,
        onclick = function()
            dialog:close()
            Parallax:Generate(sprite, dialog.data)
        end
    } --
    :button{
        text = "&Cancel",
        onclick = function()
            dialog:close()

            -- Set active sprite back to the originally open file
            app.activeSprite = sprite
        end
    }

    return dialog
end

return ParallaxDialog
