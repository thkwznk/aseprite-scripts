-- Copyright (C) 2020 Kacper Woźniak
--
-- This file is released under the terms of the CC BY 4.0 license.
-- See https://creativecommons.org/licenses/by/4.0/ for more information.
--
-- Version: 1.0.2, April 16, 2020

include("lib/Run")
include("lib/Color")
include("lib/ScaleAlgorithm")

-- Check is UI available
if not app.isUIAvailable then
    return
end

-- Run script
do
    local dlg = Dialog("Scale")
    dlg
        :separator{
            text="Nearest Neighbour"
        }
        :number{
            id="scale",
            label="Scale",
            text="2",
            decimals=false
        }
        :button{
            text="Scale",
            onclick=function()
                Run:ForActiveSprite(function(activeSprite)
                    Run:Transaction(function()
                        ScaleAlgorithm:NearestNeighbour(activeSprite, dlg.data["scale"])
                    end)
                end)
            end
        }
        :separator{
            text="Advanced"
        }
        :button{
            text="Eagle",
            onclick=function()
                Run:ForActiveSprite(function(activeSprite)
                    Run:Transaction(function()
                        ScaleAlgorithm:Eagle(activeSprite)
                    end)
                end)
            end
        }
        :button{
            text="Scale2x",
            onclick=function()
                Run:ForActiveSprite(function(activeSprite)
                    Run:Transaction(function()
                        ScaleAlgorithm:Scale2x(activeSprite)
                    end)
                end)
            end}
        :newrow()
        :button{
            text="Hawk D",
            onclick=function()
                Run:ForActiveSprite(function(activeSprite)
                    Run:Transaction(function()
                        ScaleAlgorithm:Hawk(activeSprite, false)
                    end)
                end)
            end}
        :button{
            text="Hawk N",
            onclick=function()
                Run:ForActiveSprite(function(activeSprite)
                    Run:Transaction(function()
                        ScaleAlgorithm:Hawk(activeSprite, true)
                    end)
                end)
            end}
        :separator()
        :button{
            text="Undo",
            onclick=function()
                app.command.Undo()
            end
        }
        :show{wait=false}
end