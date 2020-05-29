Transaction = dofile("../shared/Transaction.lua");
ColorList = dofile("./ColorList.lua");

-- TODO: Refresh dialog on sort instead of closing

return function(title)
    local dialog = Dialog {title = title};
    local image = app.activeCel.image;
    local palette = app.activeSprite.palettes[1];
    local isIndexedPalette = app.activeImage.spec.colorMode == ColorMode.INDEXED;

    -- Color Usage
    dialog:separator{text = "Color Usage"};

    ColorList:Clear();
    ColorList:GetColorsFromImage(image);
    ColorList:Sort();

    local max = image.width * image.height;

    for i, color in ipairs(ColorList) do
        local colorId = tostring(i);
        local resetButtonId = "reset" .. colorId;

        local colorValue = Color(color.value);

        dialog:color{
            id = colorId,
            label = string.format("%.2f %%", color.count / max * 100),
            color = colorValue,
            onchange = function()
                local newColorValue = dialog.data[colorId];

                palette:setColor(color.paletteIndex, newColorValue);

                if not isIndexedPalette then
                    app.command.ReplaceColor {
                        ui = false,
                        from = colorValue,
                        to = newColorValue,
                        tolerance = 0
                    };
                    colorValue = Color(newColorValue);
                end

                dialog:modify{id = resetButtonId, visible = true};
            end
        }:button{
            id = resetButtonId,
            text = "Reset",
            onclick = function()
                palette:setColor(color.paletteIndex, Color {
                    red = color.red,
                    green = color.green,
                    blue = color.blue,
                    alpha = color.alpha
                });

                if not isIndexedPalette then
                    app.command.ReplaceColor {
                        ui = false,
                        from = colorValue,
                        to = color.value,
                        tolerance = 0
                    };
                    colorValue = Color(color.value);
                end

                dialog:modify{id = colorId, color = color.value} -- Reset color on widget
                :modify{id = resetButtonId, visible = false}; -- Hide reset button
            end,
            visible = false
        }
    end

    -- Sort Palette
    dialog:separator{text = "Palette"};

    function handleSortButtonOnClick()
        if isIndexedPalette then
            ColorList:CopyToIndexedPalette(palette);
        else
            ColorList:CopyToPalette(palette);
        end

        dialog:close();
    end

    dialog:button{
        text = "Sort By Usage",
        onclick = Transaction(handleSortButtonOnClick)
    };

    return dialog;
end
