-- Check is UI available
if not app.isUIAvailable then return end

include("touch-screen-helper/TouchScreenHelperDialog")

do
    local dialog = CreateTouchScreenHelperDialog("NxTSHelper");

    dialog:show{wait = false};
end
