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

function ThemeManager:Import(code, onimport, onerror)
    local theme = ThemeEncoder:DecodeSigned(code)

    if not theme then
        onerror()
        return
    end

    local isNameUsed = self:Find(theme.name)

    if isNameUsed then
        local overwriteConfirmation = app.alert {
            title = "Configuration overwrite",
            text = "Configuration with a name " .. theme.name ..
                " already exists, do you want to overwrite it?",
            buttons = {"Yes", "No"}
        }

        if overwriteConfirmation == 1 then
            self.storage.savedThemes[isNameUsed] = code
            onimport()
        end
    else
        table.insert(self.storage.savedThemes, code)
        onimport()
    end
end

function ThemeManager:Save(theme, onsave)
    local confirmation = false

    local saveDialog = Dialog("Save")
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
        text = "OK",
        enabled = #theme.name > 0,
        onclick = function()
            local isNameUsed = self:Find(saveDialog.data.name)

            if not isNameUsed then
                confirmation = true
                saveDialog:close()
                return
            end

            local overwriteConfirmation = app.alert {
                title = "Configuration overwrite",
                text = "Configuration with a name " .. saveDialog.data.name ..
                    " already exists, do you want to overwrite it?",
                buttons = {"Yes", "No"}
            }

            if overwriteConfirmation == 1 then
                confirmation = true
                saveDialog:close()
            end
        end
    } --
    :button{text = "Cancel"} --
    :show()

    if confirmation then
        theme.name = saveDialog.data.name
        onsave()

        local code = ThemeEncoder:EncodeSigned(theme.name, theme.parameters,
                                               theme.colors)

        local nameUsed = ThemeManager:Find(theme.name)

        if nameUsed then
            self.storage.savedThemes[nameUsed] = code
        else
            table.insert(self.storage.savedThemes, code)
        end
    end
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

local ConfigurationsPerPage = 10
local LoadButtonIdPrefix = "saved-theme-load-"
local ExportButtonIdPrefix = "saved-theme-export-"
local DeleteButtonIdPrefix = "saved-theme-delete-"

function ThemeManager:Load(onload, onreset)
    local currentPage = 1
    local pages = math.ceil(#self.storage.savedThemes / ConfigurationsPerPage)
    local skip = (currentPage - 1) * ConfigurationsPerPage

    local browseDialog = Dialog("Load")

    local updateBrowseDialog = function()
        browseDialog --
        :modify{id = "button-previous", enabled = currentPage > 1} --
        :modify{id = "button-next", enabled = currentPage < pages}

        skip = (currentPage - 1) * ConfigurationsPerPage

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
            currentPage = currentPage - 1
            updateBrowseDialog()
        end
    } --
    :button{text = "", enabled = false} --
    :button{
        id = "button-next",
        text = "Next",
        enabled = pages > 1,
        onclick = function()
            currentPage = currentPage + 1
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
                    table.remove(self.storage.savedThemes, index)

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
            local isFirstOpen = true

            local importDialog = Dialog {
                title = "Import",
                onclose = function()
                    if not isFirstOpen then
                        self:Load(onload, onreset)
                    end
                end
            }
            importDialog --
            :entry{id = "code", label = "Code"} --
            :separator{id = "separator"} --
            :button{
                text = "Import",
                onclick = function()
                    local onimport = function()
                        importDialog:close()
                    end
                    local onerror = function()
                        importDialog:modify{
                            id = "separator",
                            text = "Incorrect code"
                        }
                    end
                    self:Import(importDialog.data.code, onimport, onerror)
                end
            } --
            :button{text = "Cancel"} --

            -- Open and close to initialize bounds
            importDialog:show{wait = false}
            importDialog:close()

            isFirstOpen = false

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
