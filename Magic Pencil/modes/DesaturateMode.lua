local DesaturateMode = {useMaskColor = true, deleteOnEmptyCel = true}

function DesaturateMode:Process(change, sprite, cel, parameters)
    local x, y, c

    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cel.position.x
        y = pixel.y - cel.position.y
        c = Color(getPixel(cel.image, x, y))

        if c.alpha > 0 then
            c = Color {
                gray = 0.299 * c.red + 0.114 * c.blue + 0.587 * c.green,
                alpha = c.alpha
            }

            if parameters.indexedMode then
                c = sprite.palettes[1]:getColor(c.index)
            end

            drawPixel(cel.image, x, y, c)
        end
    end

    app.activeCel.image = cel.image
    app.activeCel.position = cel.position
end

return DesaturateMode
