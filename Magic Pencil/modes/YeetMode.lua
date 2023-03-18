local YeetMode = {}

function YeetMode:Process(mode, change, sprite, cel, parameters)
    local startFrame = app.activeFrame.frameNumber

    local x, y = cel.position.x, cel.position.y
    local xSpeed = math.floor(change.bounds.width / 2)
    local ySpeed = -math.floor(change.bounds.height / 2)

    sprite:newCel(app.activeLayer, startFrame, cel.image, cel.position)

    local MaxFrames = 50

    for frame = startFrame + 1, startFrame + MaxFrames do
        if x < 0 or x > sprite.width or y > sprite.height then break end

        x, y = x + xSpeed, y + ySpeed
        xSpeed, ySpeed = xSpeed, ySpeed + 2

        if frame > #sprite.frames then sprite:newEmptyFrame() end
        sprite:newCel(app.activeLayer, frame, cel.image, Point(x, y))
    end
end

return YeetMode

