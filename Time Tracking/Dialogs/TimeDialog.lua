local Preferences = dofile("../Preferences.lua")
local Statistics = dofile("../Statistics.lua")
local Tracking = dofile("../Tracking.lua")
local Tab = dofile("../Tab.lua")
local Time = dofile("../Time.lua")
-- local AddMilestoneDialog = dofile("./AddMilestoneDialog.lua")

local ButtonState = {
    normal = {part = "toolbutton_last", color = "button_normal_text"},
    hot = {part = "toolbutton_hot", color = "button_hot_text"},
    selected = {part = "toolbutton_pushed", color = "button_selected_text"}
}

return function(options)
    Preferences:Init(options.preferences)
    Statistics:Init(options.preferences)

    local isRunning = true
    local timer

    local lastFilename = app.activeSprite and app.activeSprite.filename
    local totalData = Statistics:GetTotalData(lastFilename, true)
    local todayData = Statistics:GetTodayData(lastFilename, true)
    -- local lastMilestone
    local onSiteChangeListener

    -- This is necessary at this point as the dialog.data.tab doesn't update when using dialog:modify
    local selectedTab = Preferences:GetSelectedTab(app.activeSprite)

    local dialog = Dialog {
        title = "Session Time",
        notitlebar = options.notitlebar,
        onclose = function()
            if options.onclose then options.onclose() end
            timer:stop()

            app.events:off(onSiteChangeListener)

            -- Resume when the dialog is closed
            if not isRunning then options.onresume() end
        end
    }

    local sessionTime = Time.Zero()
    local todayTime = Time.Zero()
    local totalTime = Time.Zero()

    -- local function UpdateLastMilestone(filename)
    --     if filename == nil then
    --         dialog:modify{id = "last-milestone", visible = false}
    --         return
    --     end

    --     local id = Hash(filename)
    --     local milestones = options.preferences.milestones[id]
    --     lastMilestone = milestones and milestones[#milestones]

    --     dialog:modify{id = "last-milestone", visible = lastMilestone ~= nil}

    --     if lastMilestone then
    --         local time = lastMilestone.totalTime

    --         if dialog.data.tab == "session-tab" then
    --             time = time - totalData.totalTime
    --         elseif dialog.data.tab == "today-tab" then
    --             time = time - totalData.totalTime + todayData.totalTime
    --         end

    --         dialog:modify{
    --             id = "last-milestone",
    --             text = lastMilestone.title .. ": " .. Time.Parse(time),
    --             visible = time > 0
    --         }
    --     end
    -- end

    local function UpdateDialog(sprite)
        if sprite == nil then return end

        local sessionData = Statistics:GetSessionData(sprite.filename)

        local todayDataUpdated = Tracking.Sum(todayData, sessionData)
        local totalDataUpdated = Tracking.Sum(totalData, sessionData)

        sessionTime = Time.Parse(sessionData.totalTime)
        todayTime = Time.Parse(todayDataUpdated.totalTime)
        totalTime = Time.Parse(totalDataUpdated.totalTime)
        -- UpdateLastMilestone(filename)
        dialog:repaint()

        if dialog.bounds.width ~= 126 -- 
        or dialog.bounds.x ~= app.window.width - 152 --
        or dialog.bounds.y ~= 48 then
            local newBounds = Rectangle(dialog.bounds)
            newBounds.width = 126
            newBounds.x = app.window.width - 152
            newBounds.y = 48
            dialog.bounds = newBounds
            app.refresh()
        end
    end

    onSiteChangeListener = app.events:on("sitechange", function()
        local sprite = app.activeSprite

        if sprite == nil then
            lastFilename = nil
            sessionTime = Time.Zero()
            todayTime = Time.Zero()
            totalTime = Time.Zero()
            -- UpdateLastMilestone()
            return
        end

        local filename = sprite.filename

        if filename ~= lastFilename then
            selectedTab = Preferences:GetSelectedTab(sprite)

            totalData = Statistics:GetTotalData(filename, true)
            todayData = Statistics:GetTodayData(filename, true)

            dialog --
            :modify{ --
                id = Tab.Session,
                selected = selectedTab == Tab.Session
            } --
            :modify{
                id = Tab.Today,
                enabled = todayData.totalTime > 0,
                selected = selectedTab == Tab.Today
            } --
            :modify{
                id = Tab.Total,
                enabled = totalData.totalDays > 1,
                selected = selectedTab == Tab.Total
            } --
            :modify{id = "tab", selected = selectedTab}
        end

        lastFilename = filename

        UpdateDialog(sprite)
    end)

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

    local function CreateTab(title, tab)
        -- local addMilestoneButton = {
        --     bounds = Rectangle(0, 0, 20, 16),
        --     state = ButtonState,
        --     icon = "debug_breakpoint",
        --     iconSize = Size(7, 7),
        --     onclick = function()
        --         local addMilestoneDialog =
        --             AddMilestoneDialog {
        --                 sprite = app.activeSprite,
        --                 preferences = options.preferences
        --             }
        --         addMilestoneDialog:show()

        --         dialog:repaint()
        --     end
        -- }

        local customWidgets = {startStopButton} -- , addMilestoneButton}

        dialog --
        :tab{
            id = tab,
            text = title,
            onclick = function()
                selectedTab = tab
                Preferences:UpdateSelectedTab(app.activeSprite, selectedTab)
            end
        } --
        :label{id = tab .. "-empty-label", visible = false} -- Tab needs at least one  widget to not glue all canvases together in the first one
        :canvas{
            id = tab .. "-canvas",
            width = 120,
            height = 17,
            onpaint = function(ev)
                local ctx = ev.context
                local mouseOver = false
                local widthSum = 0

                local text = "Time: "

                if selectedTab == Tab.Session then
                    text = text .. sessionTime
                elseif selectedTab == Tab.Today then
                    text = text .. todayTime
                else
                    text = text .. totalTime
                end

                ctx.color = app.theme.color["button_normal_text"]
                local placeholderTextSize = ctx:measureText("Time: 00:00:00")
                ctx:fillText(text, (ctx.width - placeholderTextSize.width) / 2,
                             (ctx.height - placeholderTextSize.height) / 2)

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

                -- Start placing widgets them from the right
                local x = ctx.width -- (ctx.width - widthSum) / 2

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
                    x = x - widget.bounds.width
                    widget.bounds.x = x
                    x = x + 1

                    ctx:drawThemeRect(state.part, widget.bounds)

                    local center = Point(
                                       widget.bounds.x + widget.bounds.width / 2,
                                       widget.bounds.y + widget.bounds.height /
                                           2)

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
    end

    CreateTab("Session", Tab.Session)
    CreateTab("Today", Tab.Today)
    CreateTab("Total", Tab.Total)

    dialog --
    :tab{text = "X", onclick = function() dialog:close() end} --
    :endtabs{
        id = "tab",
        selected = selectedTab,
        onchange = function() dialog:repaint() end
    } --
    -- :label{id = "last-milestone", text = "", enabled = false} --

    timer = Timer {
        interval = 1.0,
        ontick = function() UpdateDialog(app.activeSprite) end
    }
    timer:start()

    return dialog
end

-- TODO: Create a separate debug dialog
