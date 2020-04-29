include("tween/TweenDialog")

-- Check is UI available
if not app.isUIAvailable then return end

do
    local dialog = CreateTweenDialog("NxTween");

    dialog:show{wait = false};
end
