local url = "https://raw.githubusercontent.com/xinsert/vwrewrite-decompiled/main/NewMainScript.lua"
local success, res = pcall(function()
    return game:HttpGet(url, true)
end)

if success then
    loadstring(res)()
else
    warn("[VW Loader] Failed to fetch NewMainScript.lua:", res)
end
