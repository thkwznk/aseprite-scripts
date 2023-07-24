ColorList = dofile("./ColorList.lua")
SortOptions = dofile("./SortOptions.lua")

local PageSize = 16

local sortBy = SortOptions.UsageDesc

local ColorAnalyzerDialog = function(title)
    local dialog = Dialog(title)
    local page = 1

    local image = app.activeCel.image
    local colorEntries = ColorList --
    :Clear() --
    :LoadColorsFromImage(image) --
    :GetColors(sortBy)

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
                    color = colorEntry.color,
                    visible = true,
                    enabled = false
                }
            else
                dialog --
                :modify{
                    id = "color-" .. tostring(i),
                    visible = false,
                    enabled = false
                }
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
        :color{
            id = "color-" .. tostring(i),
            label = "",
            visible = false,
            enabled = false
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
