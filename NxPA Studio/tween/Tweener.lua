local Tweener = {isDebug = false}

function Tweener:tween(config)
    if not config or not config["sprite"] or not config["framesToAdd"] then
        return
    end

    app.transaction(function()
        local sprite = config["sprite"]
        local firstFrame = config["firstFrame"]
        local lastFrame = config["lastFrame"]
        local numberOfFramesToAdd = config["framesToAdd"]

        local lastFrameToMove = lastFrame + (lastFrame - firstFrame) *
                                    numberOfFramesToAdd

        self:addInbetweenFrames(sprite, firstFrame, lastFrame,
                                numberOfFramesToAdd)
        self:moveInbetweenFrames(sprite, firstFrame, lastFrameToMove,
                                 numberOfFramesToAdd)
    end)
end

function Tweener:addInbetweenFrames(sprite, firstFrame, lastFrame,
                                    numberOfFramesToAdd)
    -- Add inbetween frames after all frames except for the last one
    for i = firstFrame, lastFrame - 1 do
        local frameToClone = i + (i - firstFrame) * numberOfFramesToAdd

        for j = 1, numberOfFramesToAdd do sprite:newFrame(frameToClone) end
    end
end

function Tweener:moveInbetweenFrames(sprite, firstFrame, lastFrame,
                                     numberOfFramesToAdd)
    local stepX = 0
    local stepY = 0

    local delta = numberOfFramesToAdd + 1

    self:log("Delta " .. tostring(delta))

    self:log("Processing frames from " .. tostring(firstFrame) .. " to " ..
                 tostring(lastFrame))

    for layerNumber, layer in ipairs(sprite.layers) do
        self:log("Processing layer " .. tostring(layerNumber) .. "...")

        for _, cel in ipairs(layer.cels) do
            local celNumber = cel.frameNumber

            if celNumber < firstFrame or celNumber >= lastFrame then
                goto continue
            end

            self:log("Processing cel " .. tostring(celNumber) .. "")

            local step = (celNumber - firstFrame) % delta

            self:log("Step " .. tostring(step))

            if step == 0 then
                self:log("Next Original Cel " .. tostring(celNumber + delta))

                local next = layer.cels[celNumber + delta]

                if next then
                    stepX = (next.position.x - cel.position.x) / delta
                    stepY = (next.position.y - cel.position.y) / delta
                end
            else
                cel.position = {
                    x = cel.position.x + math.floor(stepX * step),
                    y = cel.position.y + math.floor(stepY * step)
                }
            end

            ::continue::
        end

        self:log(" ")
    end
end

function Tweener:log(message) if self.isDebug then print(message) end end

return Tweener;
