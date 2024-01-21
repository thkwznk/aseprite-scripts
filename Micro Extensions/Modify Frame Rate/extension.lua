local title = "Modify Frame Rate"

function CreateFrameNumberLabel(frames)
    if #frames == 1 then return frames[1].frameNumber end

    local first = frames[1].frameNumber
    local last = frames[#frames].frameNumber

    return "[" .. tostring(first) .. "..." .. tostring(last) .. "]"
end

function RoundDuration(duration) return math.floor(((duration * 1000)) + 0.5) end

function FormatDuration(duration) return tostring(RoundDuration(duration)) end

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

            local min = nil
            local max = nil
            local total = 0

            for _, frame in ipairs(frames) do
                local duration = frame.duration
                if not min or duration < min then min = duration end
                if not max or duration > max then max = duration end

                total = total + duration
            end

            local average = total / #frames

            local dialog = Dialog(title)

            local UpdateDialog = function(modifier)
                if not modifier then modifier = 1 end

                dialog --
                :modify{id = "min", text = FormatDuration(min * modifier)} --
                :modify{id = "max", text = FormatDuration(max * modifier)} --
                :modify{
                    id = "average",
                    text = FormatDuration(average * modifier)
                }

                if modifier == 1 then
                    dialog --
                    :modify{id = "total", text = FormatDuration(total)} --
                end
            end

            dialog --
            :label{
                label = "Frame number:",
                text = CreateFrameNumberLabel(frames)
            } --
            :separator{text = "Duration"} --
            :label{
                id = "min",
                label = "Min (milliseconds):",
                text = FormatDuration(min)
            } --
            :label{
                id = "max",
                label = "Max (milliseconds):",
                text = FormatDuration(max)
            } --
            :label{
                id = "average",
                label = "Average (milliseconds):",
                text = FormatDuration(average)
            } --
            :number{
                id = "total",
                label = "Total (milliseconds):",
                text = FormatDuration(total),
                decimals = 0,
                onchange = function()
                    local modifier = (dialog.data.total / 1000) / total
                    UpdateDialog(modifier)
                end
            } --
            :separator() --
            :button{
                text = "&OK",
                onclick = function()
                    local modifier = (dialog.data.total / 1000) / total

                    for _, frame in ipairs(frames) do
                        local newDuration =
                            RoundDuration(frame.duration * modifier) / 1000

                        -- Fix for the open issue #1504
                        frame.duration = math.max(newDuration, 0.02)
                    end

                    dialog:close()
                end
            } --
            :button{text = "&Reset", onclick = function()
                UpdateDialog()
            end} --
            :button{text = "&Cancel"}

            dialog:show()
        end
    }
end

function exit(plugin) end
