-- Copyright (C) 2020 Kacper Woźniak
--
-- This file is released under the terms of the CC BY 4.0 license.
-- See https://creativecommons.org/licenses/by/4.0/ for more information.
--
-- Version: 1.0.2, April 16, 2020

-- Check is UI available
if not app.isUIAvailable then
    return
end

local Color = {}
function Color:gray(c) return app.pixelColor.grayaV(c) end
function Color:getLightValue(c) return self:gray(c) end
function Color:isLighter(ca, cb) return self:getLightValue(ca) > self:getLightValue(cb) end
function Color:isDarker(ca, cb) return self:getLightValue(ca) < self:getLightValue(cb) end
function Color:areEqual(ca, cb, cc) return ca == cb and cb == cc and cc == ca end
function Color:getLighter(ca, cb) return self:isLighter(ca, cb) and ca or cb end
function Color:getDarker(ca, cb) return self:isDarker(ca, cb) and ca or cb end

function invokeAndUpdate(action)
    app.transaction(action)

    -- Hack to update workspace view
    app.command.Undo()
    app.command.Redo()
end

function Resize(sprite, sizeFactor)
    sprite.width = sprite.width * sizeFactor
    sprite.height = sprite.height * sizeFactor
end

function NearestNeighbour(sprite, sizeFactor)
    -- Resize canvas
    sprite:resize(sprite.width * sizeFactor, sprite.height * sizeFactor)
end

function Eagle(sprite)
    local sizeFactor = 2

    -- Resize canvas
    Resize(sprite, sizeFactor)

    for i, cel in ipairs(sprite.cels) do
        -- Move cel
        cel.position = Point(cel.position.x * sizeFactor, cel.position.y * sizeFactor)

        local image = cel.image

        local width = image.width
        local height = image.height

        local newWidth = width * sizeFactor
        local newHeight = height * sizeFactor

        local imageResult = Image(newWidth, newHeight, sprite.colorMode)

        -- Use algorithm to create new image
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
                local xRight = math.min(x + 1, newWidth - 1)
                local yDown = math.min(y + 1, newHeight - 1)

                imageResult:putPixel(x, y, Color:areEqual(upperLeft, upperCenter, middleLeft) and upperLeft or middleCenter);
                imageResult:putPixel(xRight, y, Color:areEqual(upperCenter, upperRight, middleRight) and upperRight or middleCenter);
                imageResult:putPixel(x, yDown, Color:areEqual(middleLeft, downLeft, downCenter) and downLeft or middleCenter);
                imageResult:putPixel(xRight, yDown, Color:areEqual(downCenter, downRight, middleRight) and downRight or middleCenter);
            end
        end

        -- Save new image to the current one
        cel.image = imageResult
    end
end

function Scale2x(sprite)
    local sizeFactor = 2

    -- Resize canvas
    Resize(sprite, sizeFactor)

    for i, cel in ipairs(sprite.cels) do
        -- Move cel
        cel.position = Point(cel.position.x * sizeFactor, cel.position.y * sizeFactor)

        local image = cel.image

        local width = image.width
        local height = image.height
        local newWidth = width * sizeFactor
        local newHeight = height * sizeFactor

        local imageResult = Image(newWidth, newHeight, sprite.colorMode)

        -- Use algorithm to create new image
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

function Hawk(sprite, focusOnDark)
    local sizeFactor = 2

    function isBetter(a, b)
        return focusOnDark and Color:isDarker(a, b) or Color:isLighter(a, b)
    end

    function getBetter(a, b)
        return focusOnDark and Color:getLighter(a, b) or Color:getDarker(a, b)
    end

    -- Resize canvas
    Resize(sprite, sizeFactor)

    for i, cel in ipairs(sprite.cels) do
        -- Move cel
        cel.position = Point(cel.position.x * sizeFactor, cel.position.y * sizeFactor)

        local image = cel.image

        local width = image.width
        local height = image.height
        local newWidth = width * sizeFactor
        local newHeight = height * sizeFactor

        local imageResult = Image(newWidth, newHeight, sprite.colorMode)

        -- Use algorithm to create new image
        for ix = 0, width - 1 do
            for iy = 0, height - 1 do
                -- Get original pixels
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

                -- Calculate new pixels
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

        -- Save new image to the current one
        cel.image = imageResult
    end
end

-- Run script
do
    local dlg = Dialog("Scale")
    dlg
        :separator{
            text="Nearest Neighbour"
        }
        :number{
            id="scale",
            label="Scale",
            text="2",
            decimals=false
        }
        :button{
            text="Scale",
            onclick=function()
                local sprite = app.activeSprite

                if sprite == nil then return end

                invokeAndUpdate(function()
                    NearestNeighbour(sprite, dlg.data["scale"])
                end)
            end
        }
        :separator{
            text="Advanced"
        }
        :button{
            text="Eagle",
            onclick=function()
                local sprite = app.activeSprite

                if sprite == nil then return end

                invokeAndUpdate(function()
                    Eagle(sprite)
                end)
            end
        }
        :button{
            text="Scale2x",
            onclick=function()
                local sprite = app.activeSprite

                if sprite == nil then return end

                invokeAndUpdate(function()
                    Scale2x(sprite)
                end)
            end}
        :newrow()
        :button{
            text="Hawk D",
            onclick=function()
                local sprite = app.activeSprite

                if sprite == nil then return end

                invokeAndUpdate(function()
                    Hawk(sprite, false)
                end)
            end}
        :button{
            text="Hawk N",
            onclick=function()
                local sprite = app.activeSprite

                if sprite == nil then return end

                invokeAndUpdate(function()
                    Hawk(sprite, true)
                end)
            end}
        :separator()
        :button{
            text="Undo",
            onclick=function()
                app.command.Undo()
            end}
        :show{wait=false}
end