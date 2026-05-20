local function MeasureDataColumns(data, padding)
    local result = {}
    for i = 1, #data[1] do result[i] = 0 end

    local measureDialog = Dialog {title = "Fake"}
    measureDialog:canvas{
        width = 1,
        height = 1,
        onpaint = function(ev)
            local context = ev.context

            for _, row in ipairs(data) do
                for i, cell in ipairs(row) do
                    local textWidth = context:measureText(cell).width
                    result[i] = math.max(result[i], textWidth + padding)
                end
            end
        end
    }

    measureDialog:show{wait = false}
    measureDialog:close()

    return result
end

local function TableDialog(options)
    local padding = 10
    local columnWidths = MeasureDataColumns(options.data, padding)

    local width, height = 0, 0

    height = #options.data * 10 + padding * 3
    for _, d in ipairs(columnWidths) do width = width + d end
    width = width + padding

    local dialog = Dialog {title = options.title}

    dialog:canvas{
        id = "table",
        width = width,
        height = height,
        onpaint = function(ev)
            local context = ev.context
            local x, y = 0, padding / 2

            for i, row in ipairs(options.data) do
                x = padding

                if i == #options.data then
                    -- TODO: Get the actual height of a horizontal separator from the theme
                    context:drawThemeRect("separator_horz", 0, y, width, 5)
                    y = y + padding
                end

                for j, cell in ipairs(row) do
                    context:fillText(cell, x, y)
                    x = x + columnWidths[j]
                end

                y = y + padding

                if i == 1 then
                    -- TODO: Get the actual height of a horizontal separator from the theme
                    context:drawThemeRect("separator_horz", 0, y, width, 5)
                    y = y + padding
                end
            end
        end
    }

    return dialog
end

return TableDialog
