-- Copyright (C) 2018 Kacper Woźniak
--
-- This file is released under the terms of the CC BY 4.0 license.
-- See https://creativecommons.org/licenses/by/4.0/ for more information.
--
-- Version: 1.0.1, May 24, 2019

include("lib/Tweener")

-- Check is UI available
if not app.isUIAvailable then
    return
end

do
    local dialog = Dialog("Tween")

    dialog
        :number{
            id="frames",
            label="Frames:",
            text="2",
            decimals=false
        }
        :button{
            text="Tween",
            onclick=function()
                Tweener:tween{
                    sprite=app.activeSprite,
                    loop=dialog.data["loop"],
                    frames=dialog.data["frames"]
                }
            end
        }
        :check{
            id="loop",
            label="Loop:",
            selected=false
        }
        :show{
            wait=false
        }
end