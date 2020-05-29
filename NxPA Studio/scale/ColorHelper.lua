local ColorHelper = {}
function ColorHelper:gray(c) return app.pixelColor.grayaV(c) end
function ColorHelper:getLightValue(c) return self:gray(c) end
function ColorHelper:isLighter(ca, cb)
    return self:getLightValue(ca) > self:getLightValue(cb)
end
function ColorHelper:isDarker(ca, cb)
    return self:getLightValue(ca) < self:getLightValue(cb)
end
function ColorHelper:areEqual(ca, cb, cc)
    return ca == cb and cb == cc and cc == ca
end
function ColorHelper:getLighter(ca, cb)
    return self:isLighter(ca, cb) and ca or cb
end
function ColorHelper:getDarker(ca, cb) return self:isDarker(ca, cb) and ca or cb end
return ColorHelper;
