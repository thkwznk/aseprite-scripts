return function()
    return {
        name = "Default",
        colors = {
            -- Button
            ["button_highlight"] = Color {gray = 255},
            ["button_background"] = Color {gray = 198},
            ["button_shadow"] = Color {gray = 124},
            ["button_selected"] = Color {r = 120, g = 96, b = 80},

            -- Tab
            ["tab_corner_highlight"] = Color {r = 255, g = 255, b = 254},
            ["tab_highlight"] = Color {r = 173, g = 202, b = 222},
            ["tab_background"] = Color {r = 125, g = 146, b = 158},
            ["tab_shadow"] = Color {r = 100, g = 84, b = 96},

            -- Window
            ["window_hover"] = Color {r = 255, g = 235, b = 182},
            ["window_highlight"] = Color {r = 255, g = 254, b = 255},
            ["window_background"] = Color {r = 210, g = 202, b = 189},
            ["window_shadow"] = Color {r = 149, g = 129, b = 116},
            ["window_corner_shadow"] = Color {r = 100, g = 85, b = 96},

            -- Text
            ["text_regular"] = Color {gray = 2},
            ["text_active"] = Color {gray = 253},
            ["text_link"] = Color {r = 44, g = 76, b = 145},
            ["text_separator"] = Color {r = 44, g = 76, b = 145},

            -- Field
            ["field_highlight"] = Color {r = 255, g = 87, b = 87},
            ["field_background"] = Color {gray = 254},
            ["field_shadow"] = Color {gray = 197},
            ["field_corner_shadow"] = Color {gray = 123},

            -- Editor
            ["editor_background"] = Color {r = 101, g = 85, b = 97},
            ["editor_background_shadow"] = Color {r = 65, g = 65, b = 44},
            ["editor_tooltip"] = Color {r = 255, g = 255, b = 125},
            ["editor_tooltip_shadow"] = Color {r = 125, g = 146, b = 157},
            ["editor_tooltip_corner_shadow"] = Color {r = 100, g = 84, b = 95},
            ["editor_cursor"] = Color {r = 254, g = 255, b = 255},
            ["editor_cursor_shadow"] = Color {r = 123, g = 124, b = 124},
            ["editor_cursor_outline"] = Color {r = 1, g = 0, b = 0},
            ["editor_icons"] = Color {gray = 1},

            -- Outline
            ["outline"] = Color {gray = 0},

            -- Window Title Bar
            ["window_title_bar_corner_highlight"] = Color {
                r = 255,
                g = 255,
                b = 253
            },
            ["window_title_bar_highlight"] = Color {r = 173, g = 202, b = 221},
            ["window_title_bar_background"] = Color {r = 125, g = 146, b = 156},
            ["window_title_bar_shadow"] = Color {r = 100, g = 85, b = 95}
        },
        parameters = {isAdvanced = false}
    }
end
