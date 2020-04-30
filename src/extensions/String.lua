string.first = function(s) return s:sub(1, 1) end
string.startsWith = function(s, prefix) return s:sub(1, prefix:len()) == prefix end
string.startsWithCaseInsensitive = function(s, prefix) return s:lower():sub(1, prefix:len()) == prefix:lower() end
string.removeLast = function(s) return s:sub(1, -2) end
string.matchCaseInsensitive = function(s, match) return s:lower():match(match:lower()) end 