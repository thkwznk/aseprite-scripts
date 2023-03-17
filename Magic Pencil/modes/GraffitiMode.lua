local GraffitiMode = {}

function GraffitiMode:Process(change, sprite, cel, parameters)
    local brushSize = app.preferences.tool("pencil").brush.size
    local power = parameters.graffitiPower / 100

    parameters.chanceToDrip = 5 * power
    parameters.chanceToSpeck = 10 * power
    parameters.maxDripLength = 5 * power
    parameters.maxSpeckDist = 20 * power
    parameters.maxSpeckSize = 2 * power

    local chanceToDrip = parameters.chanceToDrip / 100
    local chanceToSpeck = parameters.chanceToSpeck / 100
    -- local maxSpeckSize = 2 -- Maybe this should be a percentage of the brush size?

    -- TODO: Make the mode correctly expand the image

    for _, pixel in ipairs(change.pixels) do
        local x = pixel.x - cel.position.x
        local y = pixel.y - cel.position.y

        cel.image:drawPixel(x, y, pixel.newColor)

        local shouldDrip = math.random() <= chanceToDrip
        local shouldSpeck = math.random() <= chanceToSpeck

        if shouldDrip then
            local dripLength = math.random(parameters.maxDripLength)

            for i = 1, dripLength do
                cel.image:drawPixel(x, y + i, pixel.newColor)
            end
        end

        if shouldSpeck then
            local speckDistX = math.floor(
                                   (math.random() - 0.5) *
                                       parameters.maxSpeckDist)
            local speckDistY = math.floor(
                                   (math.random() - 0.5) *
                                       parameters.maxSpeckDist)
            local speckSize =
                math.floor(math.random() * parameters.maxSpeckSize)

            local speckX = x + speckDistX
            local speckY = y + speckDistY

            for ex = speckX - speckSize, speckX + speckSize do
                for ey = speckY - speckSize, speckY + speckSize do

                    if math.sqrt(((ex - speckX) ^ 2) + ((ey - speckY) ^ 2)) <=
                        speckSize then
                        cel.image:drawPixel(ex, ey, pixel.newColor)
                    end
                end
            end
        end
    end

    sprite:newCel(app.activeLayer, app.activeFrame, cel.image, cel.position)
end

return GraffitiMode
