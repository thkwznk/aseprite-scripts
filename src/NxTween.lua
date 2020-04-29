include("tween/TweenDialog")

-- Check is UI available
if not app.isUIAvailable then return end

do
    local dialog = CreateTweenDialog();

    dialog:show{wait = false}
end
