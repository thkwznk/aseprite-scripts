local Base64 = dofile("../Base64.lua")
local ExportConfigurationDialog = dofile("./ExportConfigurationDialog.lua")
local ImportConfigurationDialog = dofile("./ImportConfigurationDialog.lua")

local CurrentPage = 1
local ConfigurationsPerPage = 10
local LoadButtonIdPrefix = "saved-theme-load-"
local ExportButtonIdPrefix = "saved-theme-export-"
local DeleteButtonIdPrefix = "saved-theme-delete-"

return function(options)
    local pages = math.ceil(#options.savedThemes / ConfigurationsPerPage)

    CurrentPage = math.min(CurrentPage, pages)

    local skip = (CurrentPage - 1) * ConfigurationsPerPage

    local browseDialog = Dialog("Load Configuration")

    local updateBrowseDialog = function()
        browseDialog --
        :modify{id = "button-previous", enabled = CurrentPage > 1} --
        :modify{id = "button-next", enabled = CurrentPage < pages}

        skip = (CurrentPage - 1) * ConfigurationsPerPage

        for index = 1, ConfigurationsPerPage do
            local savedthemeCode = options.savedThemes[skip + index]
            local loadButtonId = LoadButtonIdPrefix .. tostring(index)
            local exportButtonId = ExportButtonIdPrefix .. tostring(index)
            local deleteButtonId = DeleteButtonIdPrefix .. tostring(index)

            if savedthemeCode then
                local theme = Base64.DecodeSigned(savedthemeCode)

                browseDialog --
                :modify{id = loadButtonId, visible = true, label = theme.name} --
                :modify{id = exportButtonId, visible = true} --
                :modify{id = deleteButtonId, visible = true}
            else
                browseDialog --
                :modify{id = loadButtonId, visible = false} --
                :modify{id = exportButtonId, visible = false} --
                :modify{id = deleteButtonId, visible = false}
            end
        end
    end

    browseDialog --
    :button{
        id = "button-previous",
        text = "Previous",
        enabled = false,
        onclick = function()
            CurrentPage = CurrentPage - 1
            updateBrowseDialog()
        end
    } --
    :button{text = "", enabled = false} --
    :button{
        id = "button-next",
        text = "Next",
        enabled = pages > 1,
        onclick = function()
            CurrentPage = CurrentPage + 1
            updateBrowseDialog()
        end
    } --
    :separator()

    for index = 1, ConfigurationsPerPage do
        browseDialog --
        :button{
            id = LoadButtonIdPrefix .. tostring(index),
            label = "", -- Set empty label, without it it's impossible to update it later
            text = "Load",
            onclick = function()
                local savedthemeCode = options.savedThemes[skip + index]
                local theme = Base64.DecodeSigned(savedthemeCode)

                local confirmation = app.alert {
                    title = "Loading theme " .. theme.name,
                    text = "Unsaved changes will be lost, do you want to continue?",
                    buttons = {"Yes", "No"}
                }

                if confirmation == 1 then
                    browseDialog:close()
                    options.onload(theme)
                end
            end
        } --
        :button{
            id = ExportButtonIdPrefix .. tostring(index),
            text = "Export",
            onclick = function()
                local savedthemeCode = options.savedThemes[skip + index]
                local theme = Base64.DecodeSigned(savedthemeCode)

                browseDialog:close()

                local exportDialog = ExportConfigurationDialog {
                    name = theme.name,
                    code = savedthemeCode,
                    onclose = function() browseDialog:show() end
                }
                exportDialog:show()
            end
        } --
        :button{
            id = DeleteButtonIdPrefix .. tostring(index),
            text = "Delete",
            onclick = function()
                local savedthemeCode = options.savedThemes[skip + index]
                local theme = Base64.DecodeSigned(savedthemeCode)

                local confirmation = app.alert {
                    title = "Delete " .. theme.name,
                    text = "Are you sure?",
                    buttons = {"Yes", "No"}
                }

                if confirmation == 1 then
                    table.remove(options.savedThemes, skip + index)

                    browseDialog:close()
                    options.ondelete()
                end
            end
        }
    end

    if #options.savedThemes > 0 then browseDialog:separator{id = "separator"} end

    -- Initialize
    updateBrowseDialog()

    browseDialog --
    :button{
        text = "Import",
        onclick = function()
            browseDialog:close()
            local importDialog = ImportConfigurationDialog {
                onclick = options.onimport
            }

            importDialog:show()
        end
    } --
    :button{
        text = "Reset to Default",
        onclick = function()
            local confirmation = app.alert {
                title = "Resetting theme",
                text = "Unsaved changes will be lost, do you want to continue?",
                buttons = {"Yes", "No"}
            }

            -- TODO: Just replace this with a Default entry on the list of themes

            if confirmation == 1 then
                browseDialog:close()
                options.onload()
            end
        end
    }

    browseDialog --
    :separator() --
    :button{text = "Close"} --

    return browseDialog
end
