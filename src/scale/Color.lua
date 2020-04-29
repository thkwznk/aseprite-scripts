local Color = {}
function Color:gray(c) return app.pixelColor.grayaV(c) end
function Color:getLightValue(c) return self:gray(c) end
function Color:isLighter(ca, cb) return self:getLightValue(ca) > self:getLightValue(cb) end
function Color:isDarker(ca, cb) return self:getLightValue(ca) < self:getLightValue(cb) end
function Color:areEqual(ca, cb, cc) return ca == cb and cb == cc and cc == ca end
function Color:getLighter(ca, cb) return self:isLighter(ca, cb) and ca or cb end
function Color:getDarker(ca, cb) return self:isDarker(ca, cb) and ca or cb end
