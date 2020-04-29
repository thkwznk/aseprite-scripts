string.first = function(s) return s:sub(1, 1) end
string.startsWith = function(s, prefix) return s:sub(1, prefix:len()) == prefix end
string.removeLast = function(s) return s:sub(1, -2) end
string.matchCaseInsensitive = function(s, match) return s:lower():match(match:lower()) end 