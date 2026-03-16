local DesaturateMode = {
    useMaskColor = true,
    ignoreEmptyCel = true,
    deleteOnEmptyCel = true
}

function DesaturateMode:Process(change, sprite, cel, parameters)
    local cx, cy, image = cel.position.x, cel.position.y, cel.image
    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    local palette = sprite.palettes[1]
    local getColor = palette.getColor

    local isIndexed = parameters.indexedMode and sprite.colorMode ==
                          ColorMode.RGB

    local x, y, color, alpha
    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cx
        y = pixel.y - cy
        color = Color(getPixel(image, x, y))
        alpha = color.alpha

        if alpha > 0 then
            color = Color {
                gray = 0.299 * color.red + 0.114 * color.blue + 0.587 *
                    color.green,
                alpha = alpha
            }

            if isIndexed then color = getColor(palette, color.index) end

            drawPixel(image, x, y, color)
        end
    end

    app.activeCel.image = image
    app.activeCel.position = cel.position
end

return DesaturateMode
