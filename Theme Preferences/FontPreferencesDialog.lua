local DefaultFont = dofile("./DefaultFont.lua")

local FontSizes = {"6", "7", "8", "9", "10", "11", "12"}

function HasSize(font) return font.type ~= "spritesheet" end

function GetFontNames(fonts)
    local fontNames = {}

    for name, _ in pairs(fonts) do table.insert(fontNames, name) end
    table.sort(fontNames)

    return fontNames
end

return function(font, availableFonts, onclose, onconfirm)
    local fontNames = GetFontNames(availableFonts)

    local dialog = Dialog {title = "Font Preferences", onclose = onclose}

    local updateFonts = function()
        local fontName = dialog.data["default-font"]
        local defaultFont = availableFonts[fontName]

        local miniFontName = dialog.data["mini-font"]
        local miniFont = availableFonts[miniFontName]

        local newFont = {
            default = {
                name = defaultFont.name,
                type = defaultFont.type,
                file = defaultFont.file,
                size = dialog.data["default-font-size"]
            },
            mini = {
                name = miniFont.name,
                type = miniFont.type,
                file = miniFont.file,
                size = dialog.data["mini-font-size"]
            }
        }

        onconfirm(newFont)

        -- self:VerifyScaling()
    end

    dialog --
    :separator{text = "Default"} --
    :combobox{
        id = "default-font",
        label = "Name",
        option = font.default.name,
        options = fontNames,
        onchange = function()
            local fontName = dialog.data["default-font"]
            dialog:modify{
                id = "default-font-size",
                enabled = HasSize(availableFonts[fontName])
            }
        end
    } --
    :combobox{
        id = "default-font-size",
        options = FontSizes,
        option = font.default.size,
        enabled = HasSize(font.default)
    } --
    :separator{text = "Mini"} --
    :combobox{
        id = "mini-font",
        label = "Name",
        option = font.mini.name,
        options = fontNames,
        onchange = function()
            local miniFontName = dialog.data["mini-font"]
            dialog:modify{
                id = "mini-font-size",
                enabled = HasSize(availableFonts[miniFontName])
            }
        end
    } --
    :combobox{
        id = "mini-font-size",
        options = FontSizes,
        option = font.mini.size,
        enabled = HasSize(font.mini)
    } --
    :separator() --
    :button{
        text = "Reset to Default",
        onclick = function()
            local default = DefaultFont()

            dialog --
            :modify{id = "default-font-size", option = default.default.size} --
            :modify{id = "mini-font-size", option = default.mini.size} --
            :modify{id = "default-font", option = default.default.name} --
            :modify{id = "mini-font", option = default.mini.name} --

            updateFonts()
        end
    } --
    :separator() --
    :button{
        text = "OK",
        onclick = function()
            updateFonts()
            dialog:close()
        end
    } --
    :button{text = "Apply", onclick = updateFonts} --
    :button{text = "Cancel"}

    return dialog
end
