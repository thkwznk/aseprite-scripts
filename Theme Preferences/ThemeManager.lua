local Base64 = dofile("./Base64.lua")

local SaveConfigurationDialog = dofile("./Dialogs/SaveConfigurationDialog.lua")
local LoadConfigurationDialog = dofile("./Dialogs/LoadConfigurationDialog.lua")

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
    local code = Base64.EncodeSigned(theme.name, theme.parameters, theme.colors)

    if code then self.storage.currentTheme = code end
end

function ThemeManager:GetCurrentTheme()
    if self.storage.currentTheme then
        return Base64.DecodeSigned(self.storage.currentTheme)
    end
end

function ThemeManager:Find(name)
    for i, savedthemeCode in ipairs(self.storage.savedThemes) do
        if Base64.DecodeName(savedthemeCode) == name then return i end
    end
end

function ThemeManager:Save(theme, onsave, isImport)
    local saveDialog
    saveDialog = SaveConfigurationDialog {
        theme = theme,
        isImport = isImport,
        onsave = function(options)
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

            local code = Base64.EncodeSigned(theme.name, theme.parameters,
                                             theme.colors)

            if isNameUsed then
                self.storage.savedThemes[isNameUsed] = code
            else
                table.insert(self.storage.savedThemes, code)
            end

            saveDialog:close()
        end
    }

    saveDialog:show()
end

function ThemeManager:Load(onload)
    local browseDialog = LoadConfigurationDialog {
        savedThemes = self.storage.savedThemes,
        onload = onload,
        onimport = function(theme) self:Save(theme, onload, true) end,
        ondelete = function() self:Load(onload) end
    }

    browseDialog:show()
end

return ThemeManager
