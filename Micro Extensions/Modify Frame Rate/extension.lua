function CreateFrameNumberLabel(frames)
    if #frames == 1 then return frames[1].frameNumber end

    local first = frames[1].frameNumber
    local last = frames[#frames].frameNumber

    return "[" .. tostring(first) .. "..." .. tostring(last) .. "]"
end

function RoundDuration(duration) return math.floor(((duration * 1000)) + 0.5) end

function FormatDuration(duration) return tostring(RoundDuration(duration)) end

function FormatSpeed(speed) return string.format("%.2f", speed) end

function GetFramesStatistics(frames)
    local min = nil
    local max = nil
    local total = 0

    for _, frame in ipairs(frames) do
        local duration = frame.duration
        if not min or duration < min then min = duration end
        if not max or duration > max then max = duration end

        total = total + duration
    end

    return {min = min, max = max, avg = total / #frames, total = total}
end

function ModifyFrameRate(frames, modifier)
    app.transaction(function()
        for _, frame in ipairs(frames) do
            local newDuration = RoundDuration(frame.duration * modifier) / 1000

            -- Fix for the open issue #1504
            frame.duration = math.max(newDuration, 0.02)
        end
    end)
end

function ModifyFrameRateDialog()
    local frames = app.range.frames

    -- A frames range is never empty, it at least contains the active frame
    -- It's treated an empty range and consider all frames are considered
    if #frames == 1 then frames = app.activeSprite.frames end

    local stats = GetFramesStatistics(frames)

    local dialog = Dialog("Modify Frame Rate")

    local UpdateDialog = function(modifier, updateTotal, updateSpeed)
        if not modifier then modifier = 1 end

        dialog --
        :modify{id = "min", text = FormatDuration(stats.min * modifier)} --
        :modify{id = "max", text = FormatDuration(stats.max * modifier)} --
        :modify{id = "average", text = FormatDuration(stats.avg * modifier)} --

        if updateTotal then
            dialog:modify{
                id = "total",
                text = FormatDuration(stats.total * modifier)
            } --
        end

        if updateSpeed then
            dialog:modify{id = "speed", text = FormatSpeed(1 / modifier)}
        end

        dialog:modify{
            id = "okButton",
            enabled = modifier > 0 and modifier ~= math.huge
        }
    end

    dialog --
    :label{label = "Frame number:", text = CreateFrameNumberLabel(frames)} --
    :separator{text = "Duration"} --
    :label{
        id = "min",
        label = "Min (milliseconds):",
        text = FormatDuration(stats.min)
    } --
    :label{
        id = "max",
        label = "Max (milliseconds):",
        text = FormatDuration(stats.max)
    } --
    :label{
        id = "average",
        label = "Average (milliseconds):",
        text = FormatDuration(stats.avg)
    } --
    :number{
        id = "total",
        label = "Total (milliseconds):",
        text = FormatDuration(stats.total),
        decimals = 0,
        onchange = function()
            local modifier = (dialog.data.total / 1000) / stats.total
            UpdateDialog(modifier, false, true)
        end
    } --
    :separator() --
    :number{
        id = "speed",
        label = "Speed:",
        text = FormatSpeed(stats.total / (dialog.data.total / 1000)) .. "x",
        decimals = 2,
        onchange = function()
            local modifier = 1 / dialog.data.speed
            UpdateDialog(modifier, true, false)
        end
    } --
    :separator() --
    :button{
        id = "okButton",
        text = "&OK",
        onclick = function()
            local modifier = (dialog.data.total / 1000) / stats.total
            ModifyFrameRate(frames, modifier)

            dialog:close()
        end
    } --
    :button{
        text = "&Reset",
        onclick = function() UpdateDialog(1, true, true) end
    } --
    :button{text = "&Cancel"}

    return dialog
end

function init(plugin)
    local group = "frame_popup_properties"

    if app.apiVersion >= 22 then
        group = "modify_frame_rate_popup"

        plugin:newMenuSeparator{group = "frame_popup_properties"}

        plugin:newMenuGroup{
            id = "modify_frame_rate_popup",
            title = "Speed Up/Slow Down",
            group = "frame_popup_properties"
        }

        local quickSpeedRates = {
            {id = "020", title = "1/5x", modifier = 5},
            {id = "025", title = "1/4x", modifier = 4},
            {id = "033", title = "1/3x", modifier = 3},
            {id = "050", title = "1/2x", modifier = 2},
            {id = "200", title = "2x", modifier = 0.5},
            {id = "300", title = "3x", modifier = 0.33},
            {id = "400", title = "4x", modifier = 0.25},
            {id = "500", title = "5x", modifier = 0.2}
        }

        for _, rate in ipairs(quickSpeedRates) do
            plugin:newCommand{
                id = "ModifyFrameRate" .. rate.id,
                title = rate.title,
                group = group,
                onclick = function()
                    local frames = app.range.frames
                    ModifyFrameRate(frames, rate.modifier)
                end
            }
        end

        plugin:newMenuSeparator{group = group}
    end

    plugin:newCommand{
        id = "ModifyFrameRatePopup",
        title = "Modify Frame Rates",
        group = group,
        onclick = function()
            local dialog = ModifyFrameRateDialog()
            dialog:show()
        end,
        onenabled = function() return #app.range.frames > 1 end
    }

    plugin:newCommand{
        id = "ModifyFrameRate",
        title = "Modify Frame Rate",
        group = "cel_frames",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = ModifyFrameRateDialog()
            dialog:show()
        end
    }
end

function exit(plugin) end
