include("scale/ScaleDialog")

-- Check is UI available
if not app.isUIAvailable then return end

do
    local dialog = CreateScaleDialog("NxScale");

    dialog:show{wait = false};
end
