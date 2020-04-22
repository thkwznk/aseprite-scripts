-- Check is UI available
if not app.isUIAvailable then
    return
end

include("lib/Commands/KeyboardDialog")

do
    local dialog = Dialog("TSHelper")

    dialog
        :button{
            text="Undo",
            onclick=function()
                app.undo()
            end
        }
        :button{
            text="Redo",
            onclick=function()
                app.redo()
            end
        }
        :newrow()
        :button{
            text="Copy",
            onclick=function()
                app.command.Copy()
            end
        }
        :button{
            text="Paste",
            onclick=function()
                app.command.Paste()
            end
        }
        :newrow()
        :button{
            text="Cut",
            onclick=function()
                app.command.Cut()
            end
        }
        :button{
            text="Clear",
            onclick=function()
                -- app.command.Clear()
                app.command['Clear']()
            end
        }
        :newrow()
        :button{
            text="Cancel",
            onclick=function()
                app.command.Cancel()
                -- app.refresh()
            end
        }
        :separator()
        :button{
            text="Toggle Grid",
            selected=false,
            focus=false,
            onclick=function()
                app.command.ShowGrid()
            end
        }
        :newrow()
        :button{
            text="Select All",
            selected=false,
            focus=false,
            onclick=function()
                app.activeSprite.selection:selectAll()
                app.refresh()
            end
        }
        :newrow()
        :button{
            text="New Frame",
            selected=false,
            focus=false,
            onclick=function()
                app.command.NewFrame()
            end
        }
        :newrow()
        :button{
            text="New Layer",
            selected=false,
            focus=false,
            onclick=function()
                app.command.NewLayer()
            end
        }
        :separator()
        :button{
            text="Save",
            onclick=function()
                app.command.SaveFile()
            end
        }
        :separator()
        :button{
            text="Command",
            onclick=function()
                keyboardDialog = CreateKeyboardDialog(commandPrefix)
                keyboardDialog:show{wait=false}
            end
        }
        :show{
            wait=false
        }
end