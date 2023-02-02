local EXPORT_DIALOG_WIDTH = 540

local ThemeEncoder = dofile("./Base64Encoder.lua")

local ThemeManager = {storage = nil}

function ThemeManager:Init(options)
    self.storage = options.storage

    self.storage.savedThemes = self.storage.savedThemes or {
        "<Peach:1:A:////6MbGnnx8eGBQ////98vfxpKerlVh/+u2////0sq9lYF0ZFVgAgIC/f39/0wA/0wA/1dX////xsbGtbW1ZVVhQUEs/wB9mwBdggAf/v//f39/AQAAAQEB>",
        "<Garden:1:B:////3u7T/5wAaseC7f//8cq9aseCUnNh/+u2////8cq9tIF0g1VgAAAA////ATskATsk/5wA////xsbGtbW1YGBgPEwr/5wAm0IAggQA/v///s1//5wAATsk>",
        "<Blue:1:A:////5ubmnJyceGBQ6O//lrr/ZYHNTUSQ/+u26fL+vLy8f3NzTkdfAAAA////S1r/S1r/AM3/6fL+sLnFn6i0TExMKDgXAM3/AHPfADWhAAAAcH9/4P//AAFV>",
        "<Professional:1:A:////4ODglpaW/4AA////0dnhoKCgiGNj4ODg7fb/wMDAg3d3UktjICAg////QEBAQEBA/4AA7fb/tL3Go6y1QEBAHCwL/4AAmyYAggAA////f39/AAAAICAg>",
        "<Eva:1:B:////zc3Ng4OD/74t/9H/rpzffWOeZSZh/74tkOqAwMDAOm5ZCUJFAAAA////kOqAOm5ZOm5ZkOqAV7FHRqA2XFxcOEgnkOqALJBgE1IiAAAASHVAkOqAAQEB>",
        "<Orange:1:B:////xsbG/4AAeGBQ/8eR/4AAaGhodysr/+u2////0sq9lYF0ZFVgAgIC/f39/1cA/1cA/1cA////xsbGtbW1UFBQLDwb/8eRm21xgi8z/4AA/79/////AQEB>",
        "<Magic:1:B:////zMzMMbnBAICAg+7iMbnBAICAAENDoKCg7fb/wMDAAICAAFRsAgIC/f39/wD//wD//wD/7fb/tL3Go6y1YGBgPEwr/wD/mwDfggCh/v///n///wD/AQEB>",
        "<Game Boy:1:B:4PjQiMBwNGhWNGhW4PjQiMBwNGhWCBgg4PjQ4PjQiMBwNGhWAzxCCBgg4PjQ4PjQNGhWNGhW4PjQp7+Xlq6GCBggAAQA4PjQfJ6wY2By4PjQdIh4CBggCBgg>",
        "<Warm:1:A:///jz8aqhXxgeGBQ//jezcO9nIp8hE0//+u2////0sq9lYF0ZFVgAgIC/f39QW4ZQW4Z/3sk////xsbGtbW1XFxcOEgn//99fZKdgmcf/v//n7aMQW4ZAQEB>",
        "<Dark:1:B:iYmJYWFhFxcXEiE7KXf/AEnHMzMzEiE7AEnHYGBgUFBQICAgAAAMwMDA////ALTmALTmKXf/YGBgJycnFhYWAAAAAAAAKXf/AB3fAACh////lLv/KXf/AAAA>",
        "<Mono Light:1:B:3d3dzMzMAAAA////7u7u3d3dzMzMAAAA////3d3dzMzMAAAAAAAAAAAA////////////AAAA3d3dpKSkk5OTzMzMqLiX////m6Xfgmeh/v//f39/AQAAAAAA>",
        "<Mono Dark:1:B:UFBQQEBAAAAAAAAAYGBgUFBQQEBAAAAAMDAwUFBQQEBAAAAAAAAAxMTE////////////AAAAUFBQFxcXBgYGQEBAHCwLAAAAAAAAAAAAQEBAn5+f////AAAA>",
        "<Game Boy Light:1:B:7//qrtnISLGWSLGW7//qrtnISLGWCQkIrtnI7//q7//qSLGWF4WCCQkI7//qrtnISLGWSLGW7//qtsaxpbWgrtnIisWTrtnISn+oMUFq7//qfIR5CQkICQkI>"
    }

    self.storage.savedThemes = self.storage.savedThemes or
                                   "<Default:1:A:////xsbGfHx8eGBQ////rsvffZKeZVVh/+u2////0sq9lYF0ZFVgAgIC/f39LEyRLEyR/1dX////xsbGtbW1ZVVhQUEs//99m6Vdgmcf/v//e3x8AQAAAQEB>"
end

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
