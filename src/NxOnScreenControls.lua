-- Check is UI available
if not app.isUIAvailable then return end

include("on-screen-controls/Controlsdialog")

do
    local dialog = CreateTouchScreenHelperDialog("NxOSC");

    dialog:show{wait = false};
end
