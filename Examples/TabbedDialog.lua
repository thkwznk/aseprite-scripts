if not app.isUIAvailable then return end

local TabbedDialog = {selectedTab = 1}

function TabbedDialog:Config(title, config)
    self.title = title or self.title
    self.config = config or self.config
end

function TabbedDialog:Create()
    self.dialog = Dialog(self.title)

    local selectedTab = self.config[self.selectedTab]

    for i, tab in ipairs(self.config) do
        local isSelected = tab == selectedTab

        self.dialog --
        :button{
            id = "tab-" .. tostring(i),
            text = (not isSelected) and ("| " .. tab.text .. " |") or nil,
            enabled = not isSelected,
            onclick = function()
                self.selectedTab = i
                self:Refresh()
            end
        }
    end

    local characterWidth = 4

    local tabs = ""

    if self.bounds then
        -- Padding to the selected button + padding to the center of the button - half of the tab text
        local buttonWidth = (self.bounds.width - (5 * 2) -
                                (4 * (#self.config - 1))) / #self.config

        -- TODO: Consider additional padding the dialog has labels

        local buttonPadding = (self.selectedTab - 1) * buttonWidth
        local centerPadding = buttonWidth / 2
        local tabsNumber = ((buttonPadding + centerPadding) / characterWidth) -
                               ((#selectedTab.text + 4) / 2)

        for _ = 1, tabsNumber do tabs = tabs .. "-" end
    end

    self.dialog:separator{text = tabs .. "| " .. selectedTab.text .. " |"}

    if selectedTab.onclick then selectedTab.onclick(self.dialog) end

    -- Reset bounds
    if self.bounds ~= nil then
        local newBounds = self.dialog.bounds
        newBounds.x = self.bounds.x
        newBounds.y = self.bounds.y
        newBounds.width = self.bounds.width
        self.dialog.bounds = newBounds
    end
end

function TabbedDialog:Refresh()
    self.bounds = self.dialog.bounds

    self:Close()
    self:Create()
    self:Show()
end

function TabbedDialog:Close() self.dialog:close() end
function TabbedDialog:Show() self.dialog:show() end

TabbedDialog:Config("Tabbed Dialog", {
    {
        text = "Tab #1",
        onclick = function(dialog)
            dialog --
            :button{text = "Button #1.1"} --
            :separator() --
            :check{text = "Checkbox #1.1"}:newrow() --
            :check{text = "Checkbox #1.2"}:newrow() --
            :check{text = "Checkbox #1.3"}:newrow() --
            :separator() --
            :entry() --
            :button{text = "Button #1.2"}
        end
    }, {
        text = "Tab #2",
        onclick = function(dialog)
            dialog --
            :entry{text = "Value #2.1"} --
            :entry{text = "Value #2.2"} --
            :button{text = "Button #1"} --
            :separator() --
            :entry{text = "Value #2.3"} --
            :entry{text = "Value #2.4"} --
            :button{text = "Button #2"} --
        end
    }, {
        text = "Tab #3",
        onclick = function(dialog)
            dialog --
            :button{text = "Button #3.1"}:newrow() --
            :button{text = "Button #3.2"}:newrow() --
            :button{text = "Button #3.3"}:newrow() --
            :separator() --
            :button{text = "Button #3.4"} --
        end
    }
})
TabbedDialog:Create()
TabbedDialog:Show()
