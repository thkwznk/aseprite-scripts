ColorList = dofile("./ColorList.lua")
SortOptions = dofile("./SortOptions.lua")

local PageSize = 16

local sortBy = SortOptions.UsageDesc

local ColorAnalyzerDialog = function(title)
    local dialog = Dialog(title)
    local page = 1

    local GetColorEntries = function()
        return ColorList --
        :Clear() --
        :LoadColorsFromImage(app.activeCel.image) --
        :GetColors(sortBy)
    end

    local colorEntries = GetColorEntries()

    local Refresh = function()
        local pageSkip = (page - 1) * (PageSize)

        local maxColorCount = 0
        for _, colorEntry in ipairs(colorEntries) do
            maxColorCount = maxColorCount + colorEntry.count
        end

        for i = 1, PageSize do
            local colorEntry = colorEntries[pageSkip + i]

            if colorEntry then
                local colorUsagePercent =
                    (colorEntry.count / maxColorCount) * 100

                dialog --
                :modify{
                    id = "color-" .. tostring(i),
                    label = string.format("%.2f %%", colorUsagePercent),
                    colors = {colorEntry.color},
                    visible = true
                }
            else
                dialog --
                :modify{id = "color-" .. tostring(i), visible = false}
            end
        end
    end

    -- Colors
    dialog --
    :combobox{
        id = "sortBy",
        label = "Sort By",
        option = sortBy,
        options = SortOptions,
        onchange = function()
            sortBy = dialog.data["sortBy"]
            colorEntries = ColorList:GetColors(sortBy)

            Refresh()
        end
    } --
    :separator{text = "Colors"}

    local numberOfPages = math.ceil(#colorEntries / PageSize)

    -- Page Buttons
    local hasPreviousPage = page > 1
    local hasNextPage = page < numberOfPages

    local RefreshButtons = function()
        hasPreviousPage = page > 1
        hasNextPage = page < numberOfPages
        dialog:modify{id = "prev-button", enabled = hasPreviousPage}
        dialog:modify{id = "next-button", enabled = hasNextPage}
    end

    dialog --
    :button{
        id = "prev-button",
        text = "Prev",
        enabled = hasPreviousPage,
        onclick = function()
            page = page - 1
            RefreshButtons()
            Refresh()
        end
    } --
    :button{
        id = "next-button",
        text = "Next",
        enabled = hasNextPage,
        onclick = function()
            page = page + 1
            RefreshButtons()
            Refresh()
        end
    }

    RefreshButtons()

    -- Color List
    for i = 1, PageSize do
        dialog --
        :shades{
            id = "color-" .. tostring(i),
            label = "",
            mode = "pick",
            visible = false,
            onclick = function(ev)
                if ev.button == MouseButton.LEFT then
                    local color = dialog.data["color-" .. tostring(i)]

                    app.command.ReplaceColor {
                        ui = true,
                        from = color,
                        to = color,
                        tolerance = 0
                    }

                    -- Get colors entries again after replacing a color 
                    colorEntries = GetColorEntries()
                    Refresh()
                end
            end
        }
    end

    -- Palette
    dialog --
    :separator{text = "Palette"} --
    :button{
        text = "Sort",
        onclick = function()
            app.transaction(function()
                ColorList:SortPalette(colorEntries)
            end)

            dialog:close()
        end
    } --
    :button{text = "Close"}

    Refresh()

    return dialog
end

return ColorAnalyzerDialog
