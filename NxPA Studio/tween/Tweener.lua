local Tweener = {isDebug = false}

function Tweener:Tween(config)
    if not config or not config.sprite then return end

    app.transaction(function()
        config.firstFrame = config.firstFrame or 1
        config.lastFrame = config.lastFrame or #config.sprite.frames
        config.framesToAdd = config.framesToAdd or 1

        self:AddInbetweenFrames(config)
        self:MoveInbetweenFrames(config.sprite.layers, config)
    end)
end

function Tweener:AddInbetweenFrames(config)
    -- Add inbetween frames after all frames except for the last one
    for i = config.firstFrame, config.lastFrame - 1 do
        local frameToClone = i + (i - config.firstFrame) * config.framesToAdd

        for _ = 1, config.framesToAdd do
            config.sprite:newFrame(frameToClone)
        end
    end
end

function Tweener:MoveInbetweenFrames(layers, config)
    self:Log("Processing frames: %d-%d", config.firstFrame, config.lastFrame)

    for _, layer in ipairs(layers) do
        self:Log("Processing layer %s", layer.name)

        if layer.isGroup then
            self:MoveInbetweenFrames(layer.layers, config)
        else
            self:MoveLayerFrames(layer, config)
        end

        self:Log(" ")
    end
end

function Tweener:MoveLayerFrames(layer, config)
    local delta = config.framesToAdd + 1
    self:Log("Delta %d", delta)

    local lastFrameToMove = config.lastFrame +
                                (config.lastFrame - config.firstFrame) *
                                config.framesToAdd

    local stepX = 0
    local stepY = 0

    local cels = {}

    for frameNumber = config.firstFrame, lastFrameToMove do
        local cel = layer:cel(frameNumber)
        table.insert(cels, cel)
    end

    for _, cel in ipairs(cels) do
        self:Log("Processing cel %d", cel.frameNumber)

        local step = (cel.frameNumber - config.firstFrame) % delta
        self:Log("Step %d", step)

        if step == 0 then
            self:Log("Next Original Cel %d", cel.frameNumber + delta)

            local next = layer:cel(cel.frameNumber + delta)

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
    end
end

function Tweener:Log(...) if self.isDebug then print(string.format(...)) end end

return Tweener
