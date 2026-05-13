' utils.brs
' Shared helper functions

' Clamp a value between min and max
function clamp(val as float, minVal as float, maxVal as float) as float
    if val < minVal then return minVal
    if val > maxVal then return maxVal
    return val
end function

' Truncate string with ellipsis
function truncateStr(str as string, maxLen as integer) as string
    if len(str) <= maxLen then return str
    return left(str, maxLen - 3) + "..."
end function

' Format seconds to M:SS
function formatSeconds(sec as integer) as string
    mins = sec \ 60
    secs = sec mod 60
    secStr = secs.toStr()
    if secs < 10 then secStr = "0" + secStr
    return mins.toStr() + ":" + secStr
end function

' Safe AA field get
function safeGet(aa as object, key as string, default as dynamic) as dynamic
    if aa = invalid then return default
    if not aa.doesExist(key) then return default
    val = aa[key]
    if val = invalid then return default
    return val
end function
