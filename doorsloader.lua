local isNew = false
if (not isfolder('mspaint')) then makefolder('mspaint'); isNew = true end
if (not isfolder('mspaint/doors')) then makefolder('mspaint/doors'); isNew = true end
if (not isfolder('mspaint/doors/settings')) then makefolder('mspaint/doors/settings'); isNew = true end
if isNew then
    local dir = 'mspaint/doors/settings'
    writefile(dir.."/autoload.txt", "pro")
    local suc, data = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Erchobg/VoidwareProfiles/main/mspaint/doors/settings/pro.json", true)
    end)
    if suc then
        writefile(dir.."/pro.json", data)
    end
end
local function errorNotification(title, msgtext, dur)
    local text = "["..tostring(title).."]: "..tostring(msgtext)
    game:GetService('StarterGui'):SetCore(
        'ChatMakeSystemMessage', 
        {
            Text = text, 
            Color = Color3.fromRGB(255, 0, 0), 
            Font = Enum.Font.GothamBold,
            FontSize = Enum.FontSize.Size24
        }
    )
end
local function load()
    local suc2, err2 = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/mspaint.lua", true))() end)
    return {Data1 = suc2, Data2 = err2}
end
local data = load()
if (not data.Data1) then
    errorNotification("Voidware x mspaint - Doors", "Failure loading mspaint! Error: "..tostring(data.Data2), 7)
end