local Statistics = dofile("../Statistics.lua")
local Tracking = dofile("../Tracking.lua")
local View = dofile("../View.lua")
local Hash = dofile("../Hash.lua")
local Time = dofile("../Time.lua")
local AddMilestoneDialog = dofile("./AddMilestoneDialog.lua")

local ButtonState = {
    normal = {part = "toolbutton_last", color = "button_normal_text"},
    hot = {part = "toolbutton_hot", color = "button_hot_text"},
    selected = {part = "toolbutton_pushed", color = "button_selected_text"}
}

return function(options)
    local isRunning = true
    local isDebug = options.isDebug ~= nil and options.isDebug or false
    local timer, lastFilename, totalData, todayData, lastMilestone
    Statistics:Init(options.preferences)

    local dialog = Dialog {
        title = "Sprite Work Time",
        notitlebar = options.notitlebar,
        onclose = function()
            if options.onclose then options.onclose() end
            timer:stop()

            -- Resume when the dialog is closed
            if not isRunning then options.onresume() end
        end
    }

    local function UpdateSection(id, data)
        dialog --
        :modify{id = id .. "-time", text = Time.Parse(data.totalTime)} --
        :modify{id = id .. "-change-time", text = Time.Parse(data.changeTime)} --
        :modify{id = id .. "-changes", text = tostring(data.changes)} --
        :modify{id = id .. "-saves", text = tostring(data.saves)} --
        :modify{
            id = id .. "-sessions",
            text = data.sessions or "-",
            enabled = id ~= "session"
        } --
    end

    local function UpdateLastMilestone(filename)
        if filename == nil then
            dialog:modify{id = "last-milestone", visible = false}
            return
        end

        local id = Hash(filename)
        local milestones = options.preferences.milestones[id]
        lastMilestone = milestones and milestones[#milestones]

        dialog:modify{id = "last-milestone", visible = lastMilestone ~= nil}

        if lastMilestone then
            local time = lastMilestone.totalTime

            if dialog.data.tab == "session-tab" then
                time = time - totalData.totalTime
            elseif dialog.data.tab == "today-tab" then
                time = time - totalData.totalTime + todayData.totalTime
            end

            dialog:modify{
                id = "last-milestone",
                text = lastMilestone.title .. ": " .. Time.Parse(time),
                visible = time > 0
            }
        end
    end

    local function UpdateDialog(sprite)
        if sprite == nil then
            lastFilename = nil
            local data = Tracking.Data()
            UpdateSection("total", data)
            UpdateSection("today", data)
            UpdateSection("session", data)
            UpdateLastMilestone()
            return
        end

        local filename = sprite.filename

        if filename ~= lastFilename then
            totalData = Statistics:GetTotalData(filename, true)
            todayData = Statistics:GetTodayData(filename, true)

            if totalData.totalDays <= 1 then
                dialog:modify{id = "total-tab", enabled = false}

                if dialog.data.tab == View.Total then
                    dialog:modify{id = "tab", selected = View.Today}
                end
            end
        end

        local sessionData = Statistics:GetSessionData(filename)

        local totalDataUpdated = Tracking.Sum(totalData, sessionData)
        local todayDataUpdated = Tracking.Sum(todayData, sessionData)

        UpdateSection("total", totalDataUpdated)
        UpdateSection("today", todayDataUpdated)
        UpdateSection("session", sessionData)
        UpdateLastMilestone(filename)

        lastFilename = filename
    end

    dialog --
    :tab{id = "session-tab", text = "Session", onclick = function() end} --
    :label{id = "session-time", label = "Time:"} --
    :label{
        id = "session-change-time",
        label = "Change Time:",
        visible = isDebug
    } --
    :label{id = "session-changes", label = "Changes:", visible = isDebug} --
    :label{id = "session-saves", label = "Saves:", visible = isDebug} --
    :label{id = "session-sessions", label = "Sessions:", visible = isDebug} --
    --
    :tab{id = "today-tab", text = "Today", onclick = function() end} --
    :label{id = "today-time", label = "Time:"} --
    :label{id = "today-change-time", label = "Change Time:", visible = isDebug} --
    :label{id = "today-changes", label = "Changes:", visible = isDebug} --
    :label{id = "today-saves", label = "Saves:", visible = isDebug} --
    :label{id = "today-sessions", label = "Sessions:", visible = isDebug} --
    --
    :tab{id = "total-tab", text = "Total", onclick = function() end} --
    :label{id = "total-time", label = "Time:"} --
    :label{id = "total-change-time", label = "Change Time:", visible = isDebug} --
    :label{id = "total-changes", label = "Changes:", visible = isDebug} --
    :label{id = "total-saves", label = "Saves:", visible = isDebug} --
    :label{id = "total-sessions", label = "Sessions:", visible = isDebug} --
    --
    :endtabs{
        id = "tab",
        selected = options.preferences.view .. "-tab",
        onchange = function() options.preferences.view = dialog.data.tab end
    } --
    :label{id = "last-milestone", text = "", enabled = false} --

    local mouse = {position = Point(0, 0), leftClick = false}

    local startStopButton
    startStopButton = {
        bounds = Rectangle(0, 0, 20, 16),
        state = ButtonState,
        icon = "debug_pause",
        iconSize = Size(7, 7),
        onclick = function()
            if isRunning then
                options.onpause()
                startStopButton.icon = "debug_continue"
            else
                options.onresume()
                startStopButton.icon = "debug_pause"
            end

            isRunning = not isRunning

            dialog:repaint()
        end
    }

    local addMilestoneButton = {
        bounds = Rectangle(0, 0, 20, 16),
        state = ButtonState,
        icon = "debug_breakpoint",
        iconSize = Size(7, 7),
        onclick = function()
            local addMilestoneDialog = AddMilestoneDialog {
                sprite = app.activeSprite,
                preferences = options.preferences
            }
            addMilestoneDialog:show()

            dialog:repaint()
        end
    }

    local customWidgets = {startStopButton, addMilestoneButton}

    dialog --
    :canvas{
        id = "canvas",
        width = 120,
        height = 17,
        onpaint = function(ev)
            local ctx = ev.context
            local mouseOver = false
            local widthSum = 0

            -- Recalculate widget width first
            for _, widget in ipairs(customWidgets) do
                local size
                if widget.icon then
                    size = widget.iconSize or Rectangle(0, 0, 5, 5)
                else
                    size = ctx:measureText(widget.text)
                end

                widget.bounds.width = size.width + 5 * 2
                widthSum = widthSum + widget.bounds.width
            end

            local x = (ctx.width - widthSum) / 2

            -- ctx:drawThemeRect("separator_horz", Rectangle(0, 0, ctx.width, 16))

            -- Draw each custom widget
            for _, widget in ipairs(customWidgets) do
                local state = widget.state.normal
                local isMouseOver = widget.bounds:contains(mouse.position)

                if isMouseOver and not mouseOver then
                    state = widget.state.hot or state

                    if mouse.leftClick then
                        state = widget.state.selected
                    end
                end
                mouseOver = mouseOver or isMouseOver

                -- Calculate button X position
                widget.bounds.x = x
                x = x + widget.bounds.width - 1

                ctx:drawThemeRect(state.part, widget.bounds)

                local center = Point(widget.bounds.x + widget.bounds.width / 2,
                                     widget.bounds.y + widget.bounds.height / 2)

                if widget.icon then
                    -- Assuming default icon size of 16x16 pixels
                    local size = widget.iconSize or Rectangle(0, 0, 16, 16)

                    ctx:drawThemeImage(widget.icon, widget.bounds.x + 5,
                                       center.y - size.height / 2)
                elseif widget.text then
                    local size = ctx:measureText(widget.text)

                    ctx.color = app.theme.color[state.color]
                    ctx:fillText(widget.text, widget.bounds.x + 5,
                                 center.y - size.height / 2)
                end
            end
        end,
        onmousemove = function(ev)
            -- Update the mouse position
            mouse.position = Point(ev.x, ev.y)

            dialog:repaint()
        end,
        onmousedown = function(ev)
            -- Update information about left mouse button being pressed
            mouse.leftClick = ev.button == MouseButton.LEFT

            dialog:repaint()
        end,
        onmouseup = function(ev)
            local position = Point(ev.x, ev.y)

            -- When releasing left mouse button over a widget, call `onclick` method
            if ev.button == MouseButton.LEFT then
                for _, widget in ipairs(customWidgets) do
                    local isMouseOver = widget.bounds:contains(position)

                    if isMouseOver then
                        widget.onclick()
                        break
                    end
                end
            end

            -- Update information about left mouse button being released
            mouse.leftClick = false

            dialog:repaint()
        end
    }

    timer = Timer {
        interval = 0.5,
        ontick = function() UpdateDialog(app.activeSprite) end
    }
    timer:start()

    return dialog
end
