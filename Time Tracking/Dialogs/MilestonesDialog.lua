local Hash = dofile("../Hash.lua")
local Time = dofile("../Time.lua")

return function(options)
    local id = Hash(options.sprite.filename)

    local dialog = Dialog {title = "Milestones"}

    -- TODO: Get milestones from Statistics
    local milestones = options.preferences.milestones[id]

    for i = #milestones, 1, -1 do
        local milestone = milestones[i]
        local milestoneId = "milestone-" .. tostring(i)

        dialog:button{
            id = milestoneId,
            label = Time.Parse(milestone.totalTime) .. " - " .. milestone.title,
            text = "Edit",
            onclick = function()
                local editMilestoneDialog
                editMilestoneDialog = Dialog {
                    title = "Edit Milestone: " .. milestone.title
                }

                editMilestoneDialog:entry{
                    id = "title",
                    label = "Title:",
                    text = milestone.title
                }:entry{
                    id = "totalTime",
                    label = "Time:",
                    text = Time.Parse(milestone.totalTime)
                }:button{
                    text = "&OK",
                    onclick = function()
                        milestone.title = editMilestoneDialog.data.title
                        -- TODO: time
                        dialog:modify{
                            id = milestoneId,
                            label = Time.Parse(milestone.totalTime) .. " - " ..
                                milestone.title
                        }
                        editMilestoneDialog:close()

                        -- TODO: Make the entire milestones dialog scrollable, with default width and height and refresh when editings milestones
                    end
                }:button{text = "&Cancel"}

                editMilestoneDialog:show()
            end
        }
    end

    return dialog
end
