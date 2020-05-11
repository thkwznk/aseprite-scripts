include("KeyboardDialog")

local ControlsDialog = {dialog = nil, preferences = nil};

function ControlsDialog:ToggleWidgets(widgetIds, areVisible)
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

            self.preferences.dialogBounds = self.dialog.bounds;
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
    self:AddCommandButton("Cancel");
    self.dialog:separator()

    self.dialog:newrow():button{
        text = "Select All",
        selected = false,
        focus = false,
        onclick = function()
            app.activeSprite.selection:selectAll()
            app.refresh()
        end
    }:newrow();
    self.dialog:separator();

    -- Grid Controls
    self.dialog:check{
        id = "isGridEnabled",
        text = "Grid",
        selected = true,
        onclick = function()
            self:ToggleWidgets({"ShowGrid", "SnapToGrid", "GridSettings"},
                               self.dialog.data["isGridEnabled"]);
        end
    }

    self:AddCommandButton("Toggle", "ShowGrid");
    self:AddCommandButton("Snap to", "SnapToGrid");
    self.dialog:newrow()
    self:AddCommandButton("Settings", "GridSettings");
    self.dialog:separator()

    -- Frame Controls
    self.dialog:check{
        id = "isFrameEnabled",
        text = "Frame",
        selected = true,
        onclick = function()
            self:ToggleWidgets({
                "GotoFirstFrame", "GotoPreviousFrame", "GotoNextFrame",
                "GotoLastFrame", "NewFrame", "RemoveFrame"
            }, self.dialog.data["isFrameEnabled"]);
        end
    }
    self:AddCommandButton("|<", "GotoFirstFrame");
    self:AddCommandButton("<", "GotoPreviousFrame");
    self:AddCommandButton(">", "GotoNextFrame");
    self:AddCommandButton(">|", "GotoLastFrame");
    self.dialog:newrow();
    self:AddCommandButton("+", "NewFrame");
    self:AddCommandButton("-", "RemoveFrame");
    self.dialog:separator();

    -- Layer Controls
    self.dialog:check{
        id = "isLayerEnabled",
        text = "Layer",
        selected = true,
        onclick = function()
            self:ToggleWidgets({"NewLayer"}, self.dialog.data["isLayerEnabled"]);
        end
    }
    self:AddCommandButton("New Layer", "NewLayer");
    self.dialog:separator()
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

function ControlsDialog:AddCommandButton(text, command)
    addCommandButton(self.dialog, text, command);
end

function ControlsDialog:Show()
    self.dialog:show{wait = false};

    if self.preferences and self.preferences.dialogBounds then
        self.dialog.bounds = self.preferences.dialogBounds;
    end
end
