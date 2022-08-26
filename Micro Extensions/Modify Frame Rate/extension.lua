local title = "Modify Frame Rate"

function CreateFrameNumberLabel(frames)
    if #frames == 1 then return frames[1].frameNumber end

    local first = frames[1].frameNumber
    local last = frames[#frames].frameNumber

    return "[" .. tostring(first) .. "..." .. tostring(last) .. "]"
end

function init(plugin)
    plugin:newCommand{
        id = "ModifyFrameRate",
        title = title,
        group = "cel_frames",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local frames = app.range.frames

            -- Range contains only a single frame if none, or only one is selected - in both cases default to modifying all frames
            if #frames == 1 then frames = app.activeSprite.frames end

            local dialog = Dialog(title)

            dialog --
            :label{
                label = "Frame number:",
                text = CreateFrameNumberLabel(frames)
            } --
            :number{
                id = "duration",
                label = "Duration (%):",
                text = "100",
                decimals = 0
            } --
            :separator() --
            :button{
                text = "OK",
                onclick = function()
                    app.transaction(function()
                        local modifier = dialog.data.duration / 100

                        for _, frame in ipairs(frames) do
                            frame.duration = frame.duration * modifier
                        end
                    end)

                    dialog:close()
                end
            } --
            :button{text = "Cancel"}

            dialog:show()

        end
    }
end

function exit(plugin) end
