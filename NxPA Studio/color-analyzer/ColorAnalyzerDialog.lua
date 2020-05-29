Transaction = dofile("../shared/Transaction.lua");
ColorList = dofile("./ColorList.lua");

-- TODO: Replace colors with onchange
-- TODO: Refresh dialog on sort instead of closing

return function(title)
    local dialog = Dialog {title = title};
    local image = app.activeCel.image;

    -- Color Usage
    dialog:separator{text = "Color Usage"};

    ColorList:Clear();
    ColorList:GetColorsFromImage(image);
    ColorList:Sort();

    local max = image.width * image.height;

    for i, color in ipairs(ColorList) do
        local colorValue = Color(color.value);

        dialog:color{
            label = string.format("%.2f %%", color.count / max * 100),
            color = colorValue
        };
    end

    -- Sort Palette
    dialog:separator{text = "Palette"};

    function handleSortButtonOnClick()
        local palette = app.activeSprite.palettes[1];
        local isIndexedPalette = app.activeImage.spec.colorMode ==
                                     ColorMode.INDEXED;

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
