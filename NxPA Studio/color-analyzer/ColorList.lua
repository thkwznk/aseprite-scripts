local ColorList = {};

function ColorList:GetColorsFromImage(image)
    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            local value = image:getPixel(x, y);

            self:Add(value);
        end
    end
end

function ColorList:Add(value)
    for i, color in ipairs(self) do
        if color.value == value then
            self[i].count = self[i].count + 1;
            return;
        end
    end

    table.insert(self, {value = value, count = 1});
end

function ColorList:Sort()
    table.sort(self, function(a, b) return a.count > b.count end);
end

function ColorList:CopyToPalette(palette)
    for i, color in ipairs(self) do palette:setColor(i, color.value); end
end

function ColorList:CopyToIndexedPalette(palette)
    -- Changing format to RGB temporarily to preserve color in the image
    app.command.ChangePixelFormat {format = "rgb"};

    for i, color in ipairs(self) do
        color.value = palette:getColor(color.value);
    end

    self:CopyToPalette(palette);

    app.command.ChangePixelFormat {format = "indexed"};
end

function ColorList:Clear() for i, _ in ipairs(self) do self[i] = nil; end end

return ColorList;
