KeyboardDialog = dofile("./KeyboardDialog.lua");

local ControlsDialog = {dialog = nil, preferences = nil};

function ControlsDialog:ToggleWidgets(toggleId, widgetIds)
    local areVisible = self.dialog.data[toggleId];
    self.preferences[toggleId] = areVisible;

    for _, widgetId in ipairs(widgetIds) do
        self.dialog:modify{id = widgetId, visible = areVisible};
    end
end

function ControlsDialog:Create(dialogTitle, preferences, savePreferences)
    self.preferences = preferences;

    self.dialog = Dialog {
        title = dialogTitle,
        onclose = function()
            KeyboardDialog:Close();

            self.preferences.x = self.dialog.bounds.x;
            self.preferences.y = self.dialog.bounds.y;
            savePreferences(self.preferences);
        end
    };

    self:AddCommandButton("Undo");
    self:AddCommandButton("Redo");
    self.dialog:newrow()
    self:AddCommandButton("Copy");
    self:AddCommandButton("Paste");
    self.dialog:newrow()
    self:AddCommandButton("Cut");
    self:AddCommandButton("Clear");
    self.dialog:newrow()
    self.dialog:button{
        text = "Cancel",
        selected = false,
        focus = false,
        onclick = function() app.command.Cancel {type = "all"}; end
    };
    self.dialog:separator()

    self.dialog:button{
        text = "Select All",
        selected = false,
        focus = false,
        onclick = function()
            app.activeSprite.selection:selectAll()
            app.refresh()
        end
    };
    self.dialog:separator();

    -- Grid Controls
    self:AddSection("Grid", {
        {text = "Toggle", command = "ShowGrid"},
        {text = "Snap to", command = "SnapToGrid", newRow = true},
        {text = "Settings", command = "GridSettings"}
    });

    -- Frame Controls
    self:AddSection("Frame", {
        {text = "|<", command = "GotoFirstFrame"},
        {text = "<", command = "GotoPreviousFrame"},
        {text = ">", command = "GoToNextFrame"},
        {text = ">|", command = "GoToLastFrame", newRow = true},
        {text = "+", command = "NewFrame"},
        {text = "-", command = "RemoveFrame"}
    });

    -- Layer Controls
    self:AddSection("Layer", {{text = "New Layer", command = "NewLayer"}});

    self:AddCommandButton("Save", "SaveFile");
    self.dialog:separator()
    self.dialog:button{
        text = "Command",
        onclick = function()
            KeyboardDialog:Create(commandPrefix)
            KeyboardDialog:Show()
        end
    };
end

function ControlsDialog:AddSection(section, widgets)
    local sectionId = section .. "Section";

    local widgetCommands = table.map(widgets, function(w) return w.command end);

    self.dialog:check{
        id = sectionId,
        text = section,
        selected = self.preferences[sectionId],
        onclick = function()
            self:ToggleWidgets(sectionId, widgetCommands);
        end
    }

    for _, widget in ipairs(widgets) do
        self:AddCommandButton(widget.text, widget.command);

        if widget.newRow then self.dialog:newrow(); end
    end

    self:ToggleWidgets(sectionId, widgetCommands);

    self.dialog:separator();
end

function ControlsDialog:AddCommandButton(text, command)
    self.dialog:button{
        id = command,
        text = text,
        onclick = function() app.command[command or text]() end
    };
end

function ControlsDialog:Show()
    self.dialog:show{wait = false};

    if self.preferences.x and self.preferences.y then
        local bounds = self.dialog.bounds;
        bounds.x = self.preferences.x;
        bounds.y = self.preferences.y;
        self.dialog.bounds = bounds;
    end
end

return ControlsDialog;
