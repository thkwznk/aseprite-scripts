local AreEqual = function(a, b, c) return a == b and b == c and c == a end
local Value = function(c) return app.pixelColor.grayaV(c) end
local IsLighter = function(ca, cb) return Value(ca) > Value(cb) end
local IsDarker = function(ca, cb) return Value(ca) < Value(cb) end
local GetLighter = function(ca, cb) return IsLighter(ca, cb) and ca or cb end
local GetDarker = function(ca, cb) return IsDarker(ca, cb) and ca or cb end

local ScaleAlgorithm = {}

function ScaleAlgorithm:ResizeCanvas(sprite, sizeFactor)
    sprite.width = sprite.width * sizeFactor
    sprite.height = sprite.height * sizeFactor
end

function ScaleAlgorithm:MoveCel(cel, sizeFactor)
    cel.position = Point(cel.position.x * sizeFactor,
                         cel.position.y * sizeFactor)
end

function ScaleAlgorithm:NearestNeighbour(sprite, sizeFactor)
    sprite:resize(sprite.width * sizeFactor, sprite.height * sizeFactor)
end

function ScaleAlgorithm:Eagle(sprite)
    local sizeFactor = 2

    ScaleAlgorithm:ResizeCanvas(sprite, sizeFactor)

    for _, cel in ipairs(sprite.cels) do
        ScaleAlgorithm:MoveCel(cel, sizeFactor)

        local image = cel.image
        -- Save references to methods to improve performance
        local getPixel, drawPixel = image.getPixel, image.drawPixel

        local width = image.width
        local height = image.height

        local newWidth = width * sizeFactor
        local newHeight = height * sizeFactor

        local imageResult = Image(newWidth, newHeight, sprite.colorMode)

        for ix = 0, width - 1 do
            for iy = 0, height - 1 do
                local up = math.max(iy - 1, 0)
                local down = math.min(iy + 1, height - 1)
                local right = math.min(ix + 1, width - 1)
                local left = math.max(ix - 1, 0)

                local upperLeft = getPixel(image, left, up)
                local upperCenter = getPixel(image, ix, up)
                local upperRight = getPixel(image, right, up)

                local middleLeft = getPixel(image, left, iy)
                local middleCenter = getPixel(image, ix, iy)
                local middleRight = getPixel(image, right, iy)

                local downLeft = getPixel(image, left, down)
                local downCenter = getPixel(image, ix, down)
                local downRight = getPixel(image, right, down)

                local x = ix * sizeFactor;
                local y = iy * sizeFactor;
                local xRight = math.min(x + 1, newWidth - 1)
                local yDown = math.min(y + 1, newHeight - 1)

                drawPixel(imageResult, x, y, AreEqual(upperLeft, upperCenter,
                                                      middleLeft) and upperLeft or
                              middleCenter);
                drawPixel(imageResult, xRight, y, AreEqual(upperCenter,
                                                           upperRight,
                                                           middleRight) and
                              upperRight or middleCenter);
                drawPixel(imageResult, x, yDown, AreEqual(middleLeft, downLeft,
                                                          downCenter) and
                              downLeft or middleCenter);
                drawPixel(imageResult, xRight, yDown, AreEqual(downCenter,
                                                               downRight,
                                                               middleRight) and
                              downRight or middleCenter);
            end
        end

        cel.image = imageResult
    end
end

function ScaleAlgorithm:Scale2x(sprite)
    local sizeFactor = 2

    ScaleAlgorithm:ResizeCanvas(sprite, sizeFactor)

    for _, cel in ipairs(sprite.cels) do
        ScaleAlgorithm:MoveCel(cel, sizeFactor)

        local image = cel.image
        -- Save references to methods to improve performance
        local getPixel, drawPixel = image.getPixel, image.drawPixel

        local width = image.width
        local height = image.height
        local newWidth = width * sizeFactor
        local newHeight = height * sizeFactor

        local imageResult = Image(newWidth, newHeight, sprite.colorMode)

        for ix = 0, width - 1 do
            for iy = 0, height - 1 do
                local x = ix * sizeFactor
                local y = iy * sizeFactor

                local center = getPixel(image, ix, iy)

                drawPixel(imageResult, x, y, center)
                drawPixel(imageResult, x + 1, y, center)
                drawPixel(imageResult, x, y + 1, center)
                drawPixel(imageResult, x + 1, y + 1, center)

                local iyUp = math.max(iy - 1, 0)
                local iyDown = math.min(iy + 1, height - 1)
                local ixRight = math.min(ix + 1, width - 1)
                local ixLeft = math.max(ix - 1, 0)

                local up = getPixel(image, ix, iyUp)
                local right = getPixel(image, ixRight, iy)
                local left = getPixel(image, ixLeft, iy)
                local down = getPixel(image, ix, iyDown)

                if left == up and left ~= down and up ~= right then
                    drawPixel(imageResult, x, y, up)
                end

                if up == right and up ~= left and right ~= down then
                    drawPixel(imageResult, x + 1, y, right)
                end

                if down == left and down ~= right and left ~= up then
                    drawPixel(imageResult, x, y + 1, left)
                end

                if right == down and right ~= up and down ~= left then
                    drawPixel(imageResult, x + 1, y + 1, down)
                end
            end
        end

        cel.image = imageResult
    end
end

function ScaleAlgorithm:Scale3x(sprite)
    local sizeFactor = 3;

    ScaleAlgorithm:ResizeCanvas(sprite, sizeFactor)

    for _, cel in ipairs(sprite.cels) do
        ScaleAlgorithm:MoveCel(cel, sizeFactor)

        -- Save references to methods to improve performance
        local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

        local width = cel.image.width
        local height = cel.image.height

        local imageResult = Image(width * sizeFactor, height * sizeFactor,
                                  sprite.colorMode)

        for ix = 0, width - 1 do
            for iy = 0, height - 1 do
                local x = ix * sizeFactor
                local y = iy * sizeFactor

                local iyUp = math.max(iy - 1, 0)
                local iyDown = math.min(iy + 1, height - 1)
                local ixRight = math.min(ix + 1, width - 1)
                local ixLeft = math.max(ix - 1, 0)

                local A = getPixel(cel.image, ixLeft, iyUp)
                local B = getPixel(cel.image, ix, iyUp)
                local C = getPixel(cel.image, ixRight, iyUp)

                local D = getPixel(cel.image, ixLeft, iy)
                local E = getPixel(cel.image, ix, iy)
                local F = getPixel(cel.image, ixRight, iy)

                local G = getPixel(cel.image, ixLeft, iyDown)
                local H = getPixel(cel.image, ix, iyDown)
                local I = getPixel(cel.image, ixRight, iyDown)

                drawPixel(imageResult, x, y, E)
                drawPixel(imageResult, x, y + 1, E)
                drawPixel(imageResult, x, y + 2, E)
                drawPixel(imageResult, x + 1, y, E)
                drawPixel(imageResult, x + 1, y + 1, E)
                drawPixel(imageResult, x + 1, y + 2, E)
                drawPixel(imageResult, x + 2, y, E)
                drawPixel(imageResult, x + 2, y + 1, E)
                drawPixel(imageResult, x + 2, y + 2, E)

                if D == B and D ~= H and B ~= F then
                    drawPixel(imageResult, x, y, D);
                end

                if (D == B and D ~= H and B ~= F and E ~= C) or
                    (B == F and B ~= D and F ~= H and E ~= A) then
                    drawPixel(imageResult, x + 1, y, B);
                end

                if B == F and B ~= D and F ~= H then
                    drawPixel(imageResult, x + 2, y, F);
                end

                if (H == D and H ~= F and D ~= B and E ~= A) or
                    (D == B and D ~= H and B ~= F and E ~= G) then
                    drawPixel(imageResult, x, y + 1, D);
                end

                if (B == F and B ~= D and F ~= H and E ~= I) or
                    (F == H and F ~= B and H ~= D and E ~= C) then
                    drawPixel(imageResult, x + 2, y + 1, F);
                end

                if H == D and H ~= F and D ~= B then
                    drawPixel(imageResult, x, y + 2, D);
                end

                if (F == H and F ~= B and H ~= D and E ~= G) or
                    (H == D and H ~= F and D ~= B and E ~= I) then
                    drawPixel(imageResult, x + 1, y + 2, H);
                end

                if F == H and F ~= B and H ~= D then
                    drawPixel(imageResult, x + 2, y + 2, F);
                end
            end
        end

        cel.image = imageResult
    end
end

function ScaleAlgorithm:Hawk(sprite, focusOnDark)
    local sizeFactor = 2

    local isBetter = focusOnDark and IsDarker or IsLighter
    local getBetter = focusOnDark and GetLighter or GetDarker

    ScaleAlgorithm:ResizeCanvas(sprite, sizeFactor)

    for i, cel in ipairs(sprite.cels) do
        ScaleAlgorithm:MoveCel(cel, sizeFactor)

        local image = cel.image
        -- Save references to methods to improve performance
        local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

        local width = image.width
        local height = image.height
        local newWidth = width * sizeFactor
        local newHeight = height * sizeFactor

        local imageResult = Image(newWidth, newHeight, sprite.colorMode)

        for ix = 0, width - 1 do
            for iy = 0, height - 1 do
                local x = ix * sizeFactor
                local y = iy * sizeFactor

                local iyUp = math.max(iy - 1, 0)
                local iyDown = math.min(iy + 1, height - 1)
                local ixRight = math.min(ix + 1, width - 1)
                local ixLeft = math.max(ix - 1, 0)

                local b = getPixel(image, ix, iyUp)
                local d = getPixel(image, ixLeft, iy)
                local e = getPixel(image, ix, iy)
                local f = getPixel(image, ixRight, iy)
                local h = getPixel(image, ix, iyDown)

                local xRight = math.min(x + 1, newWidth - 1)
                local yDown = math.min(y + 1, newHeight - 1)

                local bIsBetterThanE = isBetter(b, e)
                local dIsBetterThanE = isBetter(d, e)
                local fIsBetterThanE = isBetter(f, e)
                local hIsBetterThanE = isBetter(h, e)

                drawPixel(imageResult, xRight, y, e)
                drawPixel(imageResult, x, y, e)
                drawPixel(imageResult, x, yDown, e)
                drawPixel(imageResult, xRight, yDown, e)

                if bIsBetterThanE then
                    if f == b then
                        drawPixel(imageResult, xRight, y, f)
                    elseif fIsBetterThanE then
                        drawPixel(imageResult, xRight, y, getBetter(b, f))
                    end

                    if b == d then
                        drawPixel(imageResult, x, y, b)
                    elseif dIsBetterThanE then
                        drawPixel(imageResult, x, y, getBetter(b, d))
                    end
                end

                if hIsBetterThanE then
                    if d == h then
                        drawPixel(imageResult, x, yDown, d)
                    elseif dIsBetterThanE then
                        drawPixel(imageResult, x, yDown, getBetter(d, h))
                    end

                    if h == f then
                        drawPixel(imageResult, xRight, yDown, h)
                    elseif fIsBetterThanE then
                        drawPixel(imageResult, xRight, yDown, getBetter(f, h))
                    end
                end
            end
        end

        cel.image = imageResult
    end
end

return ScaleAlgorithm;
