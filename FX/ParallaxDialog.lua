local PreviewCanvas = dofile("./PreviewCanvas.lua")
local Parallax = dofile("./fx/Parallax.lua")
local StackIndexId = dofile("./StackIndexId.lua")

local function GetFullLayerName(layer)
    local result = layer.name
    local parent = layer.parent

    while parent ~= layer.sprite do
        result = parent.name .. " > " .. result
        parent = parent.parent
    end

    return result
end

-- Source: https://rosettacode.org/wiki/Least_common_multiple#Lua
local function gcd(m, n)
    while n ~= 0 do
        local q = m
        m = n
        n = q % n
    end
    return m
end

local function lcm(m, n) return (m ~= 0 and n ~= 0) and m * n / gcd(m, n) or 0 end

local function ParallaxDialog(options)
    local session = options.session
    local sprite = options.sprite
    local timer

    local dialog = Dialog {
        title = options.title,
        onclose = function() timer:stop() end
    }

    local speedIds = {}
    local frames = {}

    function AddLayerWidgets(layersToProcess, groupSpeed)
        for i = #layersToProcess, 1, -1 do
            local layer = layersToProcess[i]
            local speed = 0

            if layer.isGroup then
                AddLayerWidgets(layer.layers, speed)
            elseif layer.isVisible and not layer.isReference then
                if groupSpeed then speed = groupSpeed end

                if layer.isBackground then speed = 0 end

                -- Save the initial position of the layers
                local cel = layer.cels[1]

                local id = StackIndexId(layer)
                local label = GetFullLayerName(layer)

                table.insert(speedIds, "speed-x-" .. id)
                table.insert(speedIds, "speed-y-" .. id)

                table.insert(frames, #layer.cels)

                if cel then
                    dialog --
                    :number{
                        id = "speed-x-" .. id,
                        label = label,
                        decimals = 2,
                        text = tostring(speed),
                        enabled = not layer.isBackground,
                        visible = not layer.isBackground
                    } --
                    :number{
                        id = "speed-y-" .. id,
                        decimals = 2,
                        text = tostring(0), -- TODO: ???
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

    local shift = 1

    timer = Timer {
        interval = 0.1,
        ontick = function()
            shift = shift + 1
            local previewImage = Parallax:Preview(sprite, dialog.data, shift)
            RepaintPreviewImage(previewImage)
        end
    }
    timer:start()

    -- TODO: The button to preview the parallax is necessary, it should also be off by default

    dialog:separator{text = "Speed [X/Y]"}

    AddLayerWidgets(sprite.layers)

    dialog --
    :separator{text = "Output"} --
    :number{id = "frames", label = "Frames", text = tostring(sprite.width)} --
    :button{
        text = "Perfect Loop",
        onclick = function()
            local result = sprite.width

            for _, id in ipairs(speedIds) do
                local speed = dialog.data[id]
                if speed ~= 0 then
                    local z = sprite.width / speed

                    if z % 1 ~= 0 then
                        z = sprite.width * speed
                    end

                    result = lcm(result, z)
                end
            end

            -- Take the number of animation frames into consideration
            for _, f in ipairs(frames) do
                if f > 1 then
                    result = lcm(result, sprite.width / f)
                end
            end

            -- TODO: If we're not supporting layers with variable frame number, then we can just take into account the sprites number of frames

            dialog:modify{id = "frames", text = tostring(result)}
        end
    } --
    :separator() --
    :button{
        id = "okButton",
        text = "&OK",
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
