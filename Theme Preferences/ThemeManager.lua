local EXPORT_DIALOG_WIDTH = 540

local ThemeEncoder = dofile("./Base64Encoder.lua")

local ThemeManager = {storage = nil}

function ThemeManager:Init(options) self.storage = options.storage end

function ThemeManager:SetCurrentTheme(theme)
    local code = ThemeEncoder:EncodeSigned(theme.name, theme.parameters,
                                           theme.colors)

    if code then self.storage.currentTheme = code end
end

function ThemeManager:GetCurrentTheme()
    if self.storage.currentTheme then
        return ThemeEncoder:DecodeSigned(self.storage.currentTheme)
    end
end

function ThemeManager:Find(name)
    for i, savedthemeCode in ipairs(self.storage.savedThemes) do
        if ThemeEncoder:DecodeName(savedthemeCode) == name then return i end
    end
end

function ThemeManager:Save(theme, onsave, isImport)
    local title = "Save Configuration"
    local okButtonText = "OK"

    if isImport then
        title = "Import Configuration"
        okButtonText = "Save"
    end

    local saveDialog = Dialog(title)

    local save = function(options)
        local applyImmediately = options and options.apply
        local isNameUsed = self:Find(saveDialog.data.name)

        if isNameUsed then
            local overwriteConfirmation = app.alert {
                title = "Configuration overwrite",
                text = "Configuration with a name " .. saveDialog.data.name ..
                    " already exists, do you want to overwrite it?",
                buttons = {"Yes", "No"}
            }

            if overwriteConfirmation ~= 1 then return end
        end

        theme.name = saveDialog.data.name

        if not isImport or (isImport and applyImmediately) then
            onsave(theme)
        end

        local code = ThemeEncoder:EncodeSigned(theme.name, theme.parameters,
                                               theme.colors)

        if isNameUsed then
            self.storage.savedThemes[isNameUsed] = code
        else
            table.insert(self.storage.savedThemes, code)
        end

        saveDialog:close()
    end

    saveDialog --
    :entry{
        id = "name",
        label = "Name",
        text = theme.name,
        onchange = function()
            saveDialog:modify{id = "ok", enabled = #saveDialog.data.name > 0} --
        end
    } --
    :separator() --
    :button{
        id = "ok",
        text = okButtonText,
        enabled = #theme.name > 0,
        onclick = function() save() end
    } --

    if isImport then
        saveDialog:button{
            text = "Save and Apply",
            enabled = #theme.name > 0,
            onclick = function() save {apply = true} end
        }
    end

    saveDialog --
    :button{text = "Cancel"} --
    :show()

end

function ThemeManager:ShowExportDialog(name, code, onclose)
    local isFirstOpen = true

    local exportDialog = Dialog {
        title = "Export " .. name,
        onclose = function() if not isFirstOpen then onclose() end end
    }

    exportDialog --
    :entry{label = "Code", text = code} --
    :separator() --
    :button{text = "Close"} --

    -- Open and close to initialize bounds
    exportDialog:show{wait = false}
    exportDialog:close()

    isFirstOpen = false

    local bounds = exportDialog.bounds
    bounds.x = bounds.x - (EXPORT_DIALOG_WIDTH - bounds.width) / 2
    bounds.width = EXPORT_DIALOG_WIDTH
    exportDialog.bounds = bounds

    exportDialog:show()
end

local CurrentPage = 1
local ConfigurationsPerPage = 10
local LoadButtonIdPrefix = "saved-theme-load-"
local ExportButtonIdPrefix = "saved-theme-export-"
local DeleteButtonIdPrefix = "saved-theme-delete-"

function ThemeManager:Load(onload, onreset)
    local pages = math.ceil(#self.storage.savedThemes / ConfigurationsPerPage)

    CurrentPage = math.min(CurrentPage, pages)

    local skip = (CurrentPage - 1) * ConfigurationsPerPage

    local browseDialog = Dialog("Load Configuration")

    local updateBrowseDialog = function()
        browseDialog --
        :modify{id = "button-previous", enabled = CurrentPage > 1} --
        :modify{id = "button-next", enabled = CurrentPage < pages}

        skip = (CurrentPage - 1) * ConfigurationsPerPage

        for index = 1, ConfigurationsPerPage do
            local savedthemeCode = self.storage.savedThemes[skip + index]
            local loadButtonId = LoadButtonIdPrefix .. tostring(index)
            local exportButtonId = ExportButtonIdPrefix .. tostring(index)
            local deleteButtonId = DeleteButtonIdPrefix .. tostring(index)

            if savedthemeCode then
                local theme = ThemeEncoder:DecodeSigned(savedthemeCode)

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
                local savedthemeCode = self.storage.savedThemes[skip + index]
                local theme = ThemeEncoder:DecodeSigned(savedthemeCode)

                local confirmation = app.alert {
                    title = "Loading theme " .. theme.name,
                    text = "Unsaved changes will be lost, do you want to continue?",
                    buttons = {"Yes", "No"}
                }

                if confirmation == 1 then
                    browseDialog:close()
                    onload(theme)
                end
            end
        } --
        :button{
            id = ExportButtonIdPrefix .. tostring(index),
            text = "Export",
            onclick = function()
                local savedthemeCode = self.storage.savedThemes[skip + index]
                local theme = ThemeEncoder:DecodeSigned(savedthemeCode)

                browseDialog:close()
                local onExportDialogClose = function()
                    browseDialog:show()
                end

                self:ShowExportDialog(theme.name, savedthemeCode,
                                      onExportDialogClose)
            end
        } --
        :button{
            id = DeleteButtonIdPrefix .. tostring(index),
            text = "Delete",
            onclick = function()
                local savedthemeCode = self.storage.savedThemes[skip + index]
                local theme = ThemeEncoder:DecodeSigned(savedthemeCode)

                local confirmation = app.alert {
                    title = "Delete " .. theme.name,
                    text = "Are you sure?",
                    buttons = {"Yes", "No"}
                }

                if confirmation == 1 then
                    table.remove(self.storage.savedThemes, skip + index)

                    browseDialog:close()
                    self:Load(onload, onreset)
                end
            end
        }
    end

    if #self.storage.savedThemes > 0 then
        browseDialog:separator{id = "separator"}
    end

    -- Initialize
    updateBrowseDialog()

    browseDialog --
    :button{
        text = "Import",
        onclick = function()
            browseDialog:close()
            local importDialog = Dialog("Import")

            importDialog --
            :entry{id = "code", label = "Code"} --
            :separator{id = "separator"} --
            :button{
                text = "Import",
                onclick = function()
                    local code = importDialog.data.code
                    local theme = ThemeEncoder:DecodeSigned(code)

                    if not theme then
                        importDialog:modify{
                            id = "separator",
                            text = "Incorrect code"
                        }
                        return
                    end

                    importDialog:close()

                    self:Save(theme, onload, true)
                end
            } --
            :button{text = "Cancel"} --

            -- Open and close to initialize bounds
            importDialog:show{wait = false}
            importDialog:close()

            local bounds = importDialog.bounds
            bounds.x = bounds.x - (EXPORT_DIALOG_WIDTH - bounds.width) / 2
            bounds.width = EXPORT_DIALOG_WIDTH
            importDialog.bounds = bounds

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

            if confirmation == 1 then
                browseDialog:close()
                onreset()
            end
        end
    }

    browseDialog --
    :separator() --
    :button{text = "Close"} --
    :show()
end

return ThemeManager
