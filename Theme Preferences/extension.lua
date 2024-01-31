local Template = dofile("./Template.lua")
local ThemeManager = dofile("./ThemeManager.lua")
local FontsProvider = dofile("./FontsProvider.lua")
local ThemePreferencesDialog = dofile("./ThemePreferencesDialog.lua")
local GetWindowSize = dofile("./GetWindowSize.lua") -- TODO: This would be a good place to use "require"
local RefreshTheme = dofile("./RefreshTheme.lua")

local DialogSize = Size(240, 412)

local IsDialogOpen = false
local IsFontsDialogOpen = false

function init(plugin)
    -- Do nothing when UI is not available
    if not app.isUIAvailable then return end

    -- Initialize plugin preferences data for backwards compatibility
    plugin.preferences.themePreferences =
        plugin.preferences.themePreferences or {}
    local storage = plugin.preferences.themePreferences

    -- Initialize data from plugin preferences
    ThemeManager:Init{storage = storage}
    Theme = ThemeManager:GetCurrentTheme() or Theme

    FontsProvider:Init{storage = storage}
    IsModified = storage.isThemeModified

    plugin:newCommand{
        id = "ThemePreferencesNew",
        title = "Theme Preferences...",
        group = "view_screen",
        onenabled = function() return not IsDialogOpen end,
        onclick = function()
            local currentTheme = ThemeManager:GetCurrentTheme()

            local dialog = nil
            local CreateDialog = function() end

            local onSave = function(colors, parameters, refreshTitle)
                local onsuccess = function(theme)
                    refreshTitle(theme.name)

                    currentTheme.colors = colors
                    currentTheme.parameters = parameters
                    IsModified = false

                    ThemeManager:SetCurrentTheme(theme)
                end

                ThemeManager:Save(currentTheme, onsuccess)
            end

            local onLoad = function()
                -- Hide the Theme Preferences dialog
                dialog:close()

                local onConfirm = function(theme)
                    currentTheme = theme or Template()

                    ThemeManager:SetCurrentTheme(currentTheme)
                    IsModified = false

                    local currentFont = FontsProvider:GetCurrentFont()

                    RefreshTheme(currentTheme, currentFont)
                end

                ThemeManager:Load(onConfirm)

                -- Reopen the dialog
                dialog = CreateDialog()
            end

            local onConfirm = function(colors, parameters)
                currentTheme.colors = colors
                currentTheme.parameters = parameters

                IsModified = parameters.isModified

                ThemeManager:SetCurrentTheme(currentTheme)

                local currentFont = FontsProvider:GetCurrentFont()

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
                    onload = onLoad,
                    onok = onConfirm
                }

                local window = GetWindowSize()
                local bounds = Rectangle((window.width - DialogSize.width) / 2,
                                         (window.height - DialogSize.height) / 2,
                                         DialogSize.width, DialogSize.height)

                newDialog:show{
                    wait = false,
                    bounds = bounds,
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
                local currentTheme = ThemeManager:GetCurrentTheme()
                RefreshTheme(currentTheme, font)
            end

            FontsProvider:OpenDialog(onClose, onConfirm)

            IsFontsDialogOpen = true
        end
    }
end

function exit(plugin)
    plugin.preferences.themePreferences.isThemeModified = IsModified
end

-- TODO: Consider moving the font configuration to a separate menu option - "Font Preferences..."
