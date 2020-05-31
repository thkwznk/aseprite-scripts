Transaction = dofile("../shared/Transaction.lua");
ColorList = dofile("./ColorList.lua");

local ColorAnalyzerDialog = {
    title = nil,
    dialog = nil,
    sortBy = ColorList.SortOptions[0],
    page = 1,
    pageSize = 16,
    numberOfPages = 1
};

function ColorAnalyzerDialog:Create(title)
    self.title = title or self.title;
    self.dialog = Dialog {title = self.title};

    local image = app.activeCel.image;
    local palette = app.activeSprite.palettes[1];
    local isIndexedPalette = app.activeImage.spec.colorMode == ColorMode.INDEXED;

    -- Colors
    self.dialog:combobox{
        id = "sortBy",
        label = "Sort By",
        option = self.sortBy,
        options = ColorList.SortOptions,
        onchange = function()
            self.sortBy = self.dialog.data["sortBy"];
            self:Refresh();
        end
    };

    self.dialog:separator{text = "Colors"};

    ColorList:Clear();
    ColorList:GetColorsFromImage(image);
    ColorList:Sort(self.dialog.data.sortBy);

    local max = image.width * image.height;

    local pageStart = (self.page - 1) * (self.pageSize) + 1;
    local numberOfColorsOnPage = math.min(self.pageSize, #ColorList -
                                              ((self.page - 1) * self.pageSize));
    self.numberOfPages = math.ceil(#ColorList / self.pageSize);

    if self.numberOfPages > 1 then
        local hasPreviousPage = self.page > 1;
        local hasNextPage = self.page < self.numberOfPages;

        self.dialog:button{
            text = hasPreviousPage and "Prev",
            onclick = function()
                if not hasPreviousPage then return; end
                self.page = self.page - 1;
                self:Refresh();
            end
        };

        self.dialog:button{
            text = hasNextPage and "Next",
            onclick = function()
                if not hasNextPage then return; end
                self.page = self.page + 1;
                self:Refresh();
            end
        };
    end

    for i = 0, numberOfColorsOnPage - 1 do
        local color = ColorList[pageStart + i];
        local colorId = tostring(i);
        local resetButtonId = "reset" .. colorId;

        local colorValue = Color(color.value);

        function handleColorOnChange()
            local newColorValue = self.dialog.data[colorId];

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

            self.dialog:modify{id = resetButtonId, visible = true};
        end

        function handleResetOnClick()
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

            self.dialog:modify{id = colorId, color = color.value}; -- Reset color on widget
            self.dialog:modify{id = resetButtonId, visible = false}; -- Hide reset button
        end

        local label = string.format("%.2f %%", color.count / max * 100);

        self.dialog:color{
            id = colorId,
            label = label,
            color = colorValue,
            onchange = handleColorOnChange
        }:button{
            id = resetButtonId,
            text = "Reset",
            onclick = handleResetOnClick,
            visible = false
        };
    end

    -- Palette
    self.dialog:separator{text = "Palette"};

    function handleSortButtonOnClick()
        if isIndexedPalette then
            ColorList:CopyToIndexedPalette(palette);
        else
            ColorList:CopyToPalette(palette);
        end

        self.dialog:close();
    end

    self.dialog:button{
        text = "Sort",
        onclick = Transaction(handleSortButtonOnClick)
    };
end

function ColorAnalyzerDialog:Refresh()
    local bounds = self.dialog.bounds;

    self:Close();
    self:Create();
    self:Show(false);

    local newBounds = self.dialog.bounds;
    newBounds.x = bounds.x;
    newBounds.y = bounds.y;
    self.dialog.bounds = newBounds;
end

function ColorAnalyzerDialog:Show(wait)
    self.dialog:show{wait = wait};

    -- Don't display the dialog in the center of the screen, It covers the image
    local bounds = self.dialog.bounds;
    bounds.x = bounds.x / 2;
    self.dialog.bounds = bounds;
end

function ColorAnalyzerDialog:Close()
    if self.dialog ~= nil then self.dialog:close() end
end

return ColorAnalyzerDialog;
