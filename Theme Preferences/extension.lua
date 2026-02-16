local Template = dofile("./Template.lua")
local ThemePreferences = dofile("./ThemePreferences.lua")
local FontPreferences = dofile("./FontPreferences.lua")
local ThemePreferencesDialog = dofile("./ThemePreferencesDialog.lua")
local DialogBounds = dofile("./DialogBounds.lua")
local RefreshTheme = dofile("./RefreshTheme.lua")

local SimpleDialogSize = Size(240, 422)
local AdvancedDialogSize = Size(240, 440)

local IsDialogOpen = false
local IsFontsDialogOpen = false
local IsModified = false

function init(plugin)
    -- Do nothing when UI is not available
    if not app.isUIAvailable then return end

    -- Copy plugin theme preferences data for backwards compatibility
    if plugin.preferences.themePreferences then
        for key, value in pairs(plugin.preferences.themePreferences) do
            plugin.preferences[key] = value
        end

        plugin.preferences.themePreferences = nil
    end

    local preferences = plugin.preferences

    -- Initialize data from plugin preferences
    ThemePreferences:Init(preferences)
    FontPreferences:Init(preferences)
    IsModified = preferences.isThemeModified

    plugin:newCommand{
        id = "ThemePreferencesNew",
        title = "Theme Preferences...",
        group = "view_screen",
        onenabled = function() return not IsDialogOpen end,
        onclick = function()
            local currentTheme = ThemePreferences:GetCurrentTheme()

            local dialog = nil
            local CreateDialog = function() end

            local onSave = function(colors, parameters)
                currentTheme.colors = colors
                currentTheme.parameters = parameters
                IsModified = false

                ThemePreferences:Save(currentTheme)
            end

            local onSaveAs = function(colors, parameters, refreshTitle)
                local onsuccess = function(theme)
                    refreshTitle(theme.name)

                    currentTheme.colors = colors
                    currentTheme.parameters = parameters
                    IsModified = false

                    ThemePreferences:SetCurrentTheme(theme)
                end

                ThemePreferences:SaveAs(currentTheme, onsuccess)
            end

            local onLoad = function()
                -- Hide the Theme Preferences dialog
                dialog:close()

                local onConfirm = function(theme)
                    currentTheme = theme or Template()

                    ThemePreferences:SetCurrentTheme(currentTheme)
                    IsModified = false

                    local currentFont = FontPreferences:GetCurrentFont()

                    RefreshTheme(currentTheme, currentFont)
                end

                ThemePreferences:Load(onConfirm)

                -- Reopen the dialog
                dialog = CreateDialog()
            end

            local onReset = function()
                -- Hide the Theme Preferences dialog
                dialog:close()

                currentTheme = Template()

                ThemePreferences:SetCurrentTheme(currentTheme)
                IsModified = false

                local currentFont = FontPreferences:GetCurrentFont()

                RefreshTheme(currentTheme, currentFont)

                -- Reopen the dialog
                dialog = CreateDialog()
            end

            local onConfirm = function(colors, parameters)
                currentTheme.colors = colors
                currentTheme.parameters = parameters

                IsModified = parameters.isModified

                ThemePreferences:SetCurrentTheme(currentTheme)

                local currentFont = FontPreferences:GetCurrentFont()

                RefreshTheme(currentTheme, currentFont)
            end

            CreateDialog = function()
                local newDialog = ThemePreferencesDialog {
                    name = currentTheme.name,
                    colors = currentTheme.colors,
                    parameters = currentTheme.parameters,
                    isModified = IsModified,
                    onclose = function() IsDialogOpen = false end,
                    onsave = onSave,
                    onsaveas = onSaveAs,
                    onload = onLoad,
                    onreset = onReset,
                    onok = onConfirm
                }

                local bounds = currentTheme.parameters.isAdvanced and
                                   AdvancedDialogSize or SimpleDialogSize

                local position = nil

                if dialog then
                    position = Point(dialog.bounds.x, dialog.bounds.y)
                end

                newDialog:show{
                    wait = false,
                    bounds = DialogBounds(bounds, position),
                    autoscrollbars = true
                }
                return newDialog
            end

            dialog = CreateDialog()
            IsDialogOpen = true
        end
    }

    plugin:newCommand{
        id = "FontPreferences",
        title = "Font Preferences...",
        group = "view_screen",
        onenabled = function() return not IsFontsDialogOpen end,
        onclick = function()
            local onClose = function() IsFontsDialogOpen = false end

            local onConfirm = function(font)
                local currentTheme = ThemePreferences:GetCurrentTheme()
                RefreshTheme(currentTheme, font)
            end

            FontPreferences:OpenDialog(onClose, onConfirm)

            IsFontsDialogOpen = true
        end
    }
end

function exit(plugin) plugin.preferences.isThemeModified = IsModified end
