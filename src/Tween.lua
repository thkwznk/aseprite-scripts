-- Copyright (C) 2018 Kacper Woźniak
--
-- This file is released under the terms of the CC BY 4.0 license.
-- See https://creativecommons.org/licenses/by/4.0/ for more information.
--
-- Version: 1.0.1, May 24, 2019

-- Check is UI available
if not app.isUIAvailable then
    return
end

local Tweener = {}

function Tweener:tween(config)
    if not config or
        not config["sprite"] or
        not config["frames"] then
        return
    end

    app.transaction(function()
        local sprite = config["sprite"]
        local loop = config["loop"]
        local numberOfFramesToAdd = config["frames"]
        
        self:addInbetweenFrames(sprite, numberOfFramesToAdd, loop)
        self:moveInbetweenFrames(sprite, numberOfFramesToAdd + 1, loop)
    end)
end

function Tweener:addInbetweenFrames(sprite, numberOfFramesToAdd, loop)
    local numberOfFrames = #sprite.frames
    local numberOfAddedFrames = 0

    local firstFrameIndex = 1
    local numberOfFramesToClone = loop and numberOfFrames or numberOfFrames - 1

    -- Add inbetween frames after all frames except for the last one
    for i = firstFrameIndex, numberOfFramesToClone do
        local frameToClone = i + (i - firstFrameIndex) * numberOfFramesToAdd

        for j = 1, numberOfFramesToAdd do
            sprite:newFrame(frameToClone)
        end
    end
end

function Tweener:moveInbetweenFrames(sprite, originalNumberOfFrames, loop)
    local stepX = 0
    local stepY = 0

    for i, layer in ipairs(sprite.layers) do
        for j, cel in ipairs(layer.cels) do
            local step = (j - 1) % originalNumberOfFrames

            if step == 0 then
                local next = layer.cels[j + originalNumberOfFrames]

                if loop and not next then
                    next = layer.cels[1]
                end

                if next then
                    stepX = (next.position.x - cel.position.x) / originalNumberOfFrames
                    stepY = (next.position.y - cel.position.y) / originalNumberOfFrames
                end
            else
                cel.position = {
                    x = cel.position.x + math.floor(stepX * step),
                    y = cel.position.y + math.floor(stepY * step)
                }
            end
        end
    end
end

do
    local dialog = Dialog("Tween")

    dialog
        :number{
            id="frames",
            label="Frames:",
            text="2",
            decimals=false
        }
        :button{
            text="Tween",
            onclick=function()
                Tweener:tween{
                    sprite=app.activeSprite,
                    loop=dialog.data["loop"],
                    frames=dialog.data["frames"]
                }
            end
        }
        :check{
            id="loop",
            label="Loop:",
            selected=false
        }
        :show{
            wait=false
        }
end