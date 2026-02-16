local ExportConfigurationDialog = dofile("./ExportConfigurationDialog.lua")
local DialogBounds = dofile("./DialogBounds.lua")

local ExportDialogSize = Size(540, 67)

local ConfigurationsPerPage = 10
local CurrentPage = 1

return function(themes, onload, ondelete, onimport)
    local pages = math.ceil(#themes / ConfigurationsPerPage)

    local dialog = Dialog("Load Configuration")

    -- TODO: Hide tabs in older version of Aseprite, also hide them when there's only one page

    for page = 1, pages do
        dialog:tab{
            id = "tab-" .. page,
            text = "  " .. page .. "  ",
            onclick = function() CurrentPage = page end
        }

        for i = 1, ConfigurationsPerPage do
            local index = i + (page - 1) * ConfigurationsPerPage
            if index > #themes then break end

            local theme = themes[index]

            dialog --
            :button{
                label = theme.name, -- TODO: Limit the max number of characters displayed here to not make different pages have buttons of different sizes 
                text = "Load",
                onclick = function()
                    local confirmation = app.alert {
                        title = "Loading theme " .. theme.name,
                        text = "Unsaved changes will be lost, do you want to continue?",
                        buttons = {"Yes", "No"}
                    }

                    if confirmation == 1 then
                        dialog:close()
                        onload(theme)
                    end
                end
            } --
            :button{
                text = "Export",
                onclick = function()
                    dialog:close()
                    local onExportDialogClose = function()
                        dialog:show()
                    end

                    local exportDialog =
                        ExportConfigurationDialog(theme.name, theme.code,
                                                  onExportDialogClose)
                    exportDialog:show{bounds = DialogBounds(ExportDialogSize)}
                end
            } --
            :button{
                text = "Delete",
                onclick = function()
                    local confirmation = app.alert {
                        title = "Delete " .. theme.name,
                        text = "Are you sure?",
                        buttons = {"Yes", "No"}
                    }

                    if confirmation == 1 then
                        dialog:close()
                        ondelete(index - 1)
                    end
                end
            }
        end
    end

    local selectedPage = math.min(pages, CurrentPage)

    dialog:endtabs{id = "tabs", selected = "tab-" .. selectedPage}

    dialog --
    :button{
        text = "Import",
        onclick = function()
            dialog:close()
            onimport()
        end
    } --

    dialog --
    :separator() --
    :button{text = "Close"} --

    return dialog
end
