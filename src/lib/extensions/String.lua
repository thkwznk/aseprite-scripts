string.first = function(s) return s:sub(1, 1) end
string.startsWith = function(s, prefix) return s:sub(1, prefix:len()) == prefix end
string.removeLast = function(s) return s:sub(1, -2) end
