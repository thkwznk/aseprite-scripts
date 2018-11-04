-- Copyright (C) 2018 Kacper Woźniak
--
-- This file is released under the terms of the CC BY 4.0 license.
-- See https://creativecommons.org/licenses/by/4.0/ for more information.
--
-- Version: Alpha 1, November 3, 2018

local color = {}
color.r = app.pixelColor.rgbaR
color.g = app.pixelColor.rgbaG
color.b = app.pixelColor.rgbaB
color.a = app.pixelColor.rgbaA
-- Could be faster if grayaG would be working!
-- return pc.grayaG(colorA) > pc.grayaG(colorB)
color.getLightValue = function(c) return color.r(c) ^ 2 + color.g(c) ^ 2 + color.b(c) ^ 2 + color.a(c) ^ 2 end
color.isLighter = function(ca, cb) return color.getLightValue(ca) > color.getLightValue(cb) end
color.isDarker = function(ca, cb) return color.getLightValue(ca) < color.getLightValue(cb) end
color.areEqual = function(ca, cb, cc) return ca == cb and cb == cc and cc == ca end
color.getLighter = function(ca, cb) return color.isLighter(ca, cb) and ca or cb end
color.getDarker = function(ca, cb) return color.isDarker(ca, cb) and ca or cb end

function invokeAndUpdate(action)
    app.transaction(action)

    -- Hack to update workspace
    app.command.Undo()
    app.command.Redo()
end

local sprite = app.activeSprite
local sizeFactor = 2

function Eagle()
    -- Resize canvas
    sprite:resize(sprite.width * sizeFactor, sprite.height * sizeFactor)

    for i, cel in ipairs(sprite.cels) do
        -- Move cel
        cel.position = Point(cel.position.x * sizeFactor, cel.position.y * sizeFactor)

        local image = cel.image

        local width = image.width
        local height = image.height

        local width2 = width * sizeFactor
        local height2 = height * sizeFactor

        local imageResult = Image(width2, height2, sprite.colorMode)

        -- Use Eagle algorithm to create new image
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

                -- Place pixels in a new image
                local x = ix * sizeFactor;
                local y = iy * sizeFactor;
                local xRight = math.min(x + 1, width2 - 1)
                local yDown = math.min(y + 1, height2 - 1)

                imageResult:putPixel(x, y, color.areEqual(upperLeft, upperCenter, middleLeft) and upperLeft or middleCenter);
                imageResult:putPixel(xRight, y, color.areEqual(upperCenter, upperRight, middleRight) and upperRight or middleCenter);
                imageResult:putPixel(x, yDown, color.areEqual(middleLeft, downLeft, downCenter) and downLeft or middleCenter);
                imageResult:putPixel(xRight, yDown, color.areEqual(downCenter, downRight, middleRight) and downRight or middleCenter);
            end
        end

        -- Save new image to the current one
        cel.image = imageResult
    end
end

function Scale2x()
    -- Resize canvas
    sprite:resize(sprite.width * sizeFactor, sprite.height * sizeFactor)

    for i, cel in ipairs(sprite.cels) do
        -- Move cel
        cel.position = Point(cel.position.x * sizeFactor, cel.position.y * sizeFactor)

        local image = cel.image

        local width = image.width
        local height = image.height
        local width2 = width * sizeFactor
        local height2 = height * sizeFactor

        local imageResult = Image(width2, height2, sprite.colorMode)

        -- Use Eagle algorithm to create new image
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

        -- Save new image to the current one
        cel.image = imageResult
    end
end

function Hawk(focusOnDark)
    local isBetter = color.isLighter
    local getBetter = color.getDarker

    if focusOnDark then
        isBetter = color.isDarker
        getBetter = color.getLighter
    end

    -- Resize canvas
    sprite:resize(sprite.width * sizeFactor, sprite.height * sizeFactor)

    for i, cel in ipairs(sprite.cels) do
        -- Move cel
        cel.position = Point(cel.position.x * sizeFactor, cel.position.y * sizeFactor)

        local image = cel.image

        local width = image.width
        local height = image.height
        local width2 = width * sizeFactor
        local height2 = height * sizeFactor

        local imageResult = Image(width2, height2, sprite.colorMode)

        -- Use Eagle algorithm to create new image
        for ix = 0, width - 1 do
            for iy = 0, height - 1 do
                local x = ix * sizeFactor
                local y = iy * sizeFactor

                local xLeft = math.max(x - 1, 0)
                local xRight = math.min(x + 1, width2 - 1)
                local yDown = math.min(y + 1, height2 - 1)
                local yUp = math.max(y + 1, 0)

                local center = image:getPixel(ix, iy)

                imageResult:putPixel(x, y, center)
                imageResult:putPixel(x + 1, y, center)
                imageResult:putPixel(x, y + 1, center)
                imageResult:putPixel(x + 1, y + 1, center)

                local iyUp = math.max(iy - 1, 0)
                local iyDown = math.min(iy + 1, height - 1)
                local ixRight = math.min(ix + 1, width - 1)
                local ixLeft = math.max(ix - 1, 0)

                local a = image:getPixel(ixLeft, iyUp)
                local b = image:getPixel(ix, iyUp)
                local c = image:getPixel(ixRight, iyUp)

                local d = image:getPixel(ixLeft, iy)
                local e = image:getPixel(ix, iy)
                local f = image:getPixel(ixRight, iy)

                local g = image:getPixel(ixLeft, iyDown)
                local h = image:getPixel(ix, iyDown)
                local _i = image:getPixel(ixRight, iyDown)

                if b == d and isBetter(b, e) then
                    imageResult:putPixel(x, y, b)
                elseif isBetter(b, e) and isBetter(d, e) then
                    imageResult:putPixel(x, y, getBetter(b, d))
                end

                if b == f and isBetter(b, e) then
                    imageResult:putPixel(xRight, y, b)
                elseif isBetter(b, e) and isBetter(f, e) then
                    imageResult:putPixel(xRight, y, getBetter(b, f))
                end

                if d == h and isBetter(d, e) then
                    imageResult:putPixel(x, yDown, d)
                elseif isBetter(d, e) and isBetter(h, e) then
                    imageResult:putPixel(x, yDown, getBetter(d, h))
                end

                if f == h and isBetter(f, e) then
                    imageResult:putPixel(xRight, yDown, h)
                elseif isBetter(f, e) and isBetter(h, e) then
                    imageResult:putPixel(xRight, yDown, getBetter(f, h))
                end
            end
        end

        -- Save new image to the current one
        cel.image = imageResult
    end
end

do
    local eagle = function() invokeAndUpdate(Eagle) end
    local scale2x = function() invokeAndUpdate(Scale2x) end
    local hawkD = function() invokeAndUpdate(function() Hawk(false) end) end
    local hawkN = function() invokeAndUpdate(function() Hawk(true) end) end

    Dialog("NxPA")
        :button{text="Eagle", onclick=eagle}
        :button{text="Scale2x", onclick=scale2x}
        :newrow():newrow()
        :button{text="Hawk D", onclick=hawkD}
        :button{text="Hawk N", onclick=hawkN}
        :newrow():newrow()
        :button{text="Undo", onclick=function() app.command.Undo() end}
        :show{wait=false}
end