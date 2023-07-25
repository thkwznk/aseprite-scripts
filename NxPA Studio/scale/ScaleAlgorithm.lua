local ColorHelper = {}

function ColorHelper:gray(c) return app.pixelColor.grayaV(c) end
function ColorHelper:getLightValue(c) return self:gray(c) end
function ColorHelper:isLighter(ca, cb)
    return self:getLightValue(ca) > self:getLightValue(cb)
end
function ColorHelper:isDarker(ca, cb)
    return self:getLightValue(ca) < self:getLightValue(cb)
end
function ColorHelper:areEqual(ca, cb, cc)
    return ca == cb and cb == cc and cc == ca
end
function ColorHelper:getLighter(ca, cb)
    return self:isLighter(ca, cb) and ca or cb
end
function ColorHelper:getDarker(ca, cb) return self:isDarker(ca, cb) and ca or cb end

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

    for i, cel in ipairs(sprite.cels) do
        ScaleAlgorithm:MoveCel(cel, sizeFactor)

        local image = cel.image

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

                local upperLeft = image:getPixel(left, up)
                local upperCenter = image:getPixel(ix, up)
                local upperRight = image:getPixel(right, up)

                local middleLeft = image:getPixel(left, iy)
                local middleCenter = image:getPixel(ix, iy)
                local middleRight = image:getPixel(right, iy)

                local downLeft = image:getPixel(left, down)
                local downCenter = image:getPixel(ix, down)
                local downRight = image:getPixel(right, down)

                local x = ix * sizeFactor;
                local y = iy * sizeFactor;
                local xRight = math.min(x + 1, newWidth - 1)
                local yDown = math.min(y + 1, newHeight - 1)

                imageResult:putPixel(x, y,
                                     ColorHelper:areEqual(upperLeft,
                                                          upperCenter,
                                                          middleLeft) and
                                         upperLeft or middleCenter);
                imageResult:putPixel(xRight, y,
                                     ColorHelper:areEqual(upperCenter,
                                                          upperRight,
                                                          middleRight) and
                                         upperRight or middleCenter);
                imageResult:putPixel(x, yDown,
                                     ColorHelper:areEqual(middleLeft, downLeft,
                                                          downCenter) and
                                         downLeft or middleCenter);
                imageResult:putPixel(xRight, yDown,
                                     ColorHelper:areEqual(downCenter, downRight,
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

    for i, cel in ipairs(sprite.cels) do
        ScaleAlgorithm:MoveCel(cel, sizeFactor)

        local image = cel.image

        local width = image.width
        local height = image.height
        local newWidth = width * sizeFactor
        local newHeight = height * sizeFactor

        local imageResult = Image(newWidth, newHeight, sprite.colorMode)

        for ix = 0, width - 1 do
            for iy = 0, height - 1 do
                local x = ix * sizeFactor
                local y = iy * sizeFactor

                local center = image:getPixel(ix, iy)

                imageResult:putPixel(x, y, center)
                imageResult:putPixel(x + 1, y, center)
                imageResult:putPixel(x, y + 1, center)
                imageResult:putPixel(x + 1, y + 1, center)

                local iyUp = math.max(iy - 1, 0)
                local iyDown = math.min(iy + 1, height - 1)
                local ixRight = math.min(ix + 1, width - 1)
                local ixLeft = math.max(ix - 1, 0)

                local up = image:getPixel(ix, iyUp)
                local right = image:getPixel(ixRight, iy)
                local left = image:getPixel(ixLeft, iy)
                local down = image:getPixel(ix, iyDown)

                if left == up and left ~= down and up ~= right then
                    imageResult:putPixel(x, y, up)
                end

                if up == right and up ~= left and right ~= down then
                    imageResult:putPixel(x + 1, y, right)
                end

                if down == left and down ~= right and left ~= up then
                    imageResult:putPixel(x, y + 1, left)
                end

                if right == down and right ~= up and down ~= left then
                    imageResult:putPixel(x + 1, y + 1, down)
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

                local A = cel.image:getPixel(ixLeft, iyUp)
                local B = cel.image:getPixel(ix, iyUp)
                local C = cel.image:getPixel(ixRight, iyUp)

                local D = cel.image:getPixel(ixLeft, iy)
                local E = cel.image:getPixel(ix, iy)
                local F = cel.image:getPixel(ixRight, iy)

                local G = cel.image:getPixel(ixLeft, iyDown)
                local H = cel.image:getPixel(ix, iyDown)
                local I = cel.image:getPixel(ixRight, iyDown)

                imageResult:putPixel(x, y, E)
                imageResult:putPixel(x, y + 1, E)
                imageResult:putPixel(x, y + 2, E)
                imageResult:putPixel(x + 1, y, E)
                imageResult:putPixel(x + 1, y + 1, E)
                imageResult:putPixel(x + 1, y + 2, E)
                imageResult:putPixel(x + 2, y, E)
                imageResult:putPixel(x + 2, y + 1, E)
                imageResult:putPixel(x + 2, y + 2, E)

                if D == B and D ~= H and B ~= F then
                    imageResult:putPixel(x, y, D);
                end

                if (D == B and D ~= H and B ~= F and E ~= C) or
                    (B == F and B ~= D and F ~= H and E ~= A) then
                    imageResult:putPixel(x + 1, y, B);
                end

                if B == F and B ~= D and F ~= H then
                    imageResult:putPixel(x + 2, y, F);
                end

                if (H == D and H ~= F and D ~= B and E ~= A) or
                    (D == B and D ~= H and B ~= F and E ~= G) then
                    imageResult:putPixel(x, y + 1, D);
                end

                if (B == F and B ~= D and F ~= H and E ~= I) or
                    (F == H and F ~= B and H ~= D and E ~= C) then
                    imageResult:putPixel(x + 2, y + 1, F);
                end

                if H == D and H ~= F and D ~= B then
                    imageResult:putPixel(x, y + 2, D);
                end

                if (F == H and F ~= B and H ~= D and E ~= G) or
                    (H == D and H ~= F and D ~= B and E ~= I) then
                    imageResult:putPixel(x + 1, y + 2, H);
                end

                if F == H and F ~= B and H ~= D then
                    imageResult:putPixel(x + 2, y + 2, F);
                end
            end
        end

        cel.image = imageResult
    end
end

function ScaleAlgorithm:Hawk(sprite, focusOnDark)
    local sizeFactor = 2

    function isBetter(a, b)
        return focusOnDark and ColorHelper:isDarker(a, b) or
                   ColorHelper:isLighter(a, b)
    end

    function getBetter(a, b)
        return focusOnDark and ColorHelper:getLighter(a, b) or
                   ColorHelper:getDarker(a, b)
    end

    ScaleAlgorithm:ResizeCanvas(sprite, sizeFactor)

    for i, cel in ipairs(sprite.cels) do
        ScaleAlgorithm:MoveCel(cel, sizeFactor)

        local image = cel.image

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

                local b = image:getPixel(ix, iyUp)
                local d = image:getPixel(ixLeft, iy)
                local e = image:getPixel(ix, iy)
                local f = image:getPixel(ixRight, iy)
                local h = image:getPixel(ix, iyDown)

                local xRight = math.min(x + 1, newWidth - 1)
                local yDown = math.min(y + 1, newHeight - 1)

                local bIsBetterThanE = isBetter(b, e)
                local dIsBetterThanE = isBetter(d, e)
                local fIsBetterThanE = isBetter(f, e)
                local hIsBetterThanE = isBetter(h, e)

                imageResult:putPixel(xRight, y, e)
                imageResult:putPixel(x, y, e)
                imageResult:putPixel(x, yDown, e)
                imageResult:putPixel(xRight, yDown, e)

                if bIsBetterThanE then
                    if f == b then
                        imageResult:putPixel(xRight, y, f)
                    elseif fIsBetterThanE then
                        imageResult:putPixel(xRight, y, getBetter(b, f))
                    end

                    if b == d then
                        imageResult:putPixel(x, y, b)
                    elseif dIsBetterThanE then
                        imageResult:putPixel(x, y, getBetter(b, d))
                    end
                end

                if hIsBetterThanE then
                    if d == h then
                        imageResult:putPixel(x, yDown, d)
                    elseif dIsBetterThanE then
                        imageResult:putPixel(x, yDown, getBetter(d, h))
                    end

                    if h == f then
                        imageResult:putPixel(xRight, yDown, h)
                    elseif fIsBetterThanE then
                        imageResult:putPixel(xRight, yDown, getBetter(f, h))
                    end
                end
            end
        end

        cel.image = imageResult
    end
end

return ScaleAlgorithm;
