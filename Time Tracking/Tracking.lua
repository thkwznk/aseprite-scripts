return {
    Session = function()
        return {totalTime = 0, changeTime = 0, changes = 0, saves = 0}
    end,
    Data = function()
        return {
            totalTime = 0,
            changeTime = 0,
            changes = 0,
            saves = 0,
            sessions = 0
        }
    end,
    Milestone = function(title, data)
        return {
            title = title,
            totalTime = data.totalTime,
            changeTime = data.changeTime,
            changes = data.changes,
            saves = data.saves,
            sessions = data.sessions
        }
    end,
    Sum = function(a, b)
        return {
            totalTime = a.totalTime + b.totalTime,
            changeTime = a.changeTime + b.changeTime,
            changes = a.changes + b.changes,
            saves = a.saves + b.saves,
            sessions = (a.sessions or 1) + (b.sessions or 1)
        }
    end
}
