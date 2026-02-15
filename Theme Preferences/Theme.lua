return function()
    return {
        name = "Default",
        colors = {
            -- Button
            ["button_highlight"] = Color {gray = 255, alpha = 255},
            ["button_background"] = Color {gray = 198, alpha = 255},
            ["button_shadow"] = Color {gray = 124, alpha = 255},
            ["button_selected"] = Color {
                red = 120,
                green = 96,
                blue = 80,
                alpha = 255
            },

            -- Tab
            ["tab_corner_highlight"] = Color {
                red = 255,
                green = 255,
                blue = 254,
                alpha = 255
            },
            ["tab_highlight"] = Color {
                red = 173,
                green = 202,
                blue = 222,
                alpha = 255
            },
            ["tab_background"] = Color {
                red = 125,
                green = 146,
                blue = 158,
                alpha = 255
            },
            ["tab_shadow"] = Color {
                red = 100,
                green = 84,
                blue = 96,
                alpha = 255
            },

            -- Window
            ["window_hover"] = Color {
                red = 255,
                green = 235,
                blue = 182,
                alpha = 255
            },
            ["window_highlight"] = Color {
                red = 255,
                green = 254,
                blue = 255,
                alpha = 255
            },
            ["window_background"] = Color {
                red = 210,
                green = 202,
                blue = 189,
                alpha = 255
            },
            ["window_shadow"] = Color {
                red = 149,
                green = 129,
                blue = 116,
                alpha = 255
            },
            ["window_corner_shadow"] = Color {
                red = 100,
                green = 85,
                blue = 96,
                alpha = 255
            },

            -- Text
            ["text_regular"] = Color {gray = 2, alpha = 255},
            ["text_active"] = Color {gray = 253, alpha = 255},
            ["text_link"] = Color {
                red = 44,
                green = 76,
                blue = 145,
                alpha = 255
            },
            ["text_separator"] = Color {
                red = 44,
                green = 76,
                blue = 145,
                alpha = 255
            },

            -- Field
            ["field_highlight"] = Color {
                red = 255,
                green = 87,
                blue = 87,
                alpha = 255
            },
            ["field_background"] = Color {gray = 254, alpha = 255},
            ["field_shadow"] = Color {gray = 197, alpha = 255},
            ["field_corner_shadow"] = Color {gray = 123, alpha = 255},

            -- Editor
            ["editor_background"] = Color {
                red = 101,
                green = 85,
                blue = 97,
                alpha = 255
            },
            ["editor_background_shadow"] = Color {
                red = 65,
                green = 65,
                blue = 44,
                alpha = 255
            },
            ["editor_tooltip"] = Color {
                red = 255,
                green = 255,
                blue = 125,
                alpha = 255
            },
            ["editor_tooltip_shadow"] = Color {
                red = 125,
                green = 146,
                blue = 157,
                alpha = 255
            },
            ["editor_tooltip_corner_shadow"] = Color {
                red = 100,
                green = 84,
                blue = 95,
                alpha = 255
            },
            ["editor_cursor"] = Color {
                red = 254,
                green = 255,
                blue = 255,
                alpha = 255
            },
            ["editor_cursor_shadow"] = Color {
                red = 123,
                green = 124,
                blue = 124,
                alpha = 255
            },
            ["editor_cursor_outline"] = Color {
                red = 1,
                green = 0,
                blue = 0,
                alpha = 255
            },
            ["editor_icons"] = Color {gray = 1, alpha = 255}
        },
        parameters = {isAdvanced = false}
    }
end
