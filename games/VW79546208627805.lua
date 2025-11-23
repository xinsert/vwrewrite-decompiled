repeat task.wait() until game:IsLoaded()
local vape = shared.vape
local entitylib = vape.Libraries.entity
local entityLibrary = entitylib

local function run(func)
	if shared.VoidDev then
		return func() 
	end
	
	local success, errorMsg = pcall(func)
	if not success then
		errorNotification("99 Nights In The Forest", "Failure executing function: " .. tostring(errorMsg), 3)
		warn(debug.traceback(tostring(errorMsg)))
	end
end

local __services_cache = {}
local Services = setmetatable({}, {
    __index = function(self, key)
        if __services_cache[key] then
            return __services_cache[key]
        end
        local suc, service = pcall(game.GetService, game, key)
        if suc and service then
            __services_cache[key] = service
            return service
        else
            if key ~= "InputService" then
                warn(`[Services] Warning: "{key}" is not a valid Roblox service.`)
                return nil
            else
                service = game:GetService("UserInputService")
                __services_cache[key] = service
                return service
            end
        end
    end
})

local function mprint(tbl, indent, visited)
    indent = indent or 0
    visited = visited or {}

    if visited[tbl] then
        print(string.rep(" ", indent) .. "<Cyclic Reference>")
        return
    end
    visited[tbl] = true

    for key, value in pairs(tbl) do
        local prefix = string.rep(" ", indent)
        if type(value) == "table" then
            print(prefix .. tostring(key) .. " = {")
            mprint(value, indent + 4, visited)
            print(prefix .. "}")
        else
            print(prefix .. tostring(key) .. " = " .. tostring(value))
        end
    end

    local meta = getmetatable(tbl)
    if meta then
        print(string.rep(" ", indent) .. "Metatable:")
        for key, value in pairs(meta) do
            local prefix = string.rep(" ", indent + 4)
            if type(value) == "function" then
                print(prefix .. tostring(key) .. " = <function>")
            elseif type(value) == "table" then
                print(prefix .. tostring(key) .. " = {")
                mprint(value, indent + 8, visited)
                print(prefix .. "}")
            else
                print(prefix .. tostring(key) .. " = " .. tostring(value))
            end
        end
    end
end

local SNF = {

}

local Functions = {
    joinQueue = function(val)
        local args = {
            "Add",
            val
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TeleportEvent"):FireServer(unpack(args))
    end,
    createQueue = function(queue, val)
        local args = {
            "Chosen",
            [queue] = val
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TeleportEvent"):FireServer(unpack(args))
    end,
    leaveQueue = function()
        local args = {
            "Remove"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TeleportEvent"):FireServer(unpack(args))
    end,
    applyCustomBadge = function(val)
        local args = {
            {
                Stars = 2,
                Image = val,
                Name = "Survive 10 Days",
                ID = 2310366779580636,
                Description = "Survive until day 10",
                Owned = true
            }
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("EquipBadge"):FireServer(unpack(args))
    end,
    sortVapeWindows = function()
        for _, v in pairs({"Combat", "Blatant", "Utility", "World", "Inventory", "Minigames", "Render", "Friends", "Targets", "Misc", "Profiles"}) do
            if vape.Categories[v] then
                if vape.Categories[v].Object then
                    vape.Categories[v].Object.Visible = false
                end
                if vape.Categories[v].Button and vape.Categories[v].Button.Object then
                    vape.Categories[v].Button.Object.Visible = false
                end
            end
        end

        local mainapi = vape
        local priority = {
			GUICategory = 1,
			CombatCategory = 2,
			BlatantCategory = 3,
			RenderCategory = 4,
			UtilityCategory = 5,
			WorldCategory = 6,
			InventoryCategory = 7,
			MinigamesCategory = 8,
			FriendsCategory = 9,
			ProfilesCategory = 10
		}
		local categories = {}
		for _, v in mainapi.Categories do
			if v.Type ~= 'Overlay' then
				table.insert(categories, v)
			end
		end
		table.sort(categories, function(a, b)
			return (priority[a.Object.Name] or 99) < (priority[b.Object.Name] or 99)
		end)

		local ind = 1.1
		for _, v in categories do
			if v.Object.Visible then
				v.Object.Position = UDim2.fromOffset(6 + (ind % 8 * 230), 100 + (ind > 7 and 360 or 0))
				ind += 1
			end
		end

        for _, v in pairs(SNF.windows) do
            v.Object.Visible = true
            if not v.Expanded then
                v:Expand()
            end
        end
    end
}

run(function()
    vape:CreateCategory({
        Name = "99 Nights in the Forest",
        Icon = 'rbxassetid://138008620313588',
        Size = UDim2.fromOffset(14, 14)
    })

    vape:CreateCategory({
        Name = "99 Nights - Other",
        Icon = 'rbxassetid://138008620313588',
        Size = UDim2.fromOffset(14, 14)
    })

    SNF.window = vape.Categories["99 Nights in the Forest"]
    SNF.otherWindow = vape.Categories["99 Nights - Other"]

    SNF.windows = {SNF.window, SNF.otherWindow}

    pcall(function()
        for _, v in pairs(SNF.windows) do
            v.Object.Visible = true
            if not v.Expanded then
                v:Expand()
            end
        end

        vape.Categories.Main.Object.Visible = false
        vape.Categories.Main.Options["GUI Theme"]:SetValue(Color3.fromRGB(255, 255, 255):ToHSV())
    end)

    task.spawn(function()
        repeat task.wait() until vape.Loaded
        Functions.sortVapeWindows()
        vape.Categories.Main.Options["GUI Theme"]:SetValue(Color3.fromRGB(255, 255, 255):ToHSV())
    end)
end)

run(function()
    local JoinQueue = {}
    local queueValue = 1
    JoinQueue = SNF.window:CreateModule({
        Name = "Join Queue",
        Function = function(call)
            if call then
                JoinQueue:Toggle()
                Functions.joinQueue(queueValue)
            end
        end
    })
    JoinQueue:CreateDropdown({
        Name = "Queue Number",
        Function = function(val)
            if val == nil then return end
            val = tonumber(val)
            if not val then return end
            queueValue = val > 0 and val or 1
        end,
        List = {"1", "2", "3"},
        Default = "1"
    })
end)

run(function()
    local CreateQueue = {}
    local QueueSize = 1
    local queueValue = 1
    CreateQueue = SNF.window:CreateModule({
        Name = "Create Queue",
        Function = function(call)
            if call then
                CreateQueue:Toggle()
                Functions.joinQueue(queueValue)
                Functions.createQueue(queueValue, QueueSize)
            end
        end
    })
    CreateQueue:CreateSlider({
        Name = "Size",
        Function = function(val)
            QueueSize = val > 0 and val or 1
        end,
        Min = 1,
        Max = 5,
        Default = 5
    })
    CreateQueue:CreateDropdown({
        Name = "Queue Number",
        Function = function(val)
            if val == nil then return end
            val = tonumber(val)
            if not val then return end
            queueValue = val > 0 and val or 1
        end,
        List = {"1", "2", "3"},
        Default = "1"
    })
end)

run(function()
    local CustomBadge = {}
    --"rbxassetid://115516656043326" - Grow A Garden Icon
    local Value = {Value = "rbxassetid://93751776432268"}
    local badgeAssetId = "rbxassetid://93751776432268"
    CustomBadge = SNF.window:CreateModule({
        Name = "Custom Badge",
        Function = function(call)
            if call then
                badgeAssetId = Value.Value
                Functions.applyCustomBadge(badgeAssetId)
            else
                Functions.applyCustomBadge("rbxassetid://97388450213635")
            end
        end,
        Tooltip = "Changes your badge's image to something u choose \n requires the survive 10 days badge"
    })
    Value = CustomBadge:CreateTextBox({
        Name = "Image Id",
        Function = function(val, second)
            if val == nil then return end
            badgeAssetId = Value.Value
            if CustomBadge.Enabled then
                CustomBadge:Toggle()
                CustomBadge:Toggle()
            end
        end,
        Default = badgeAssetId
    })
end)

run(function()
    local LeaveQueue
    LeaveQueue = SNF.window:CreateModule({
        Name = "Leave Queue",
        Function = function(call)
            if call then
                LeaveQueue:Toggle()
                Functions.leaveQueue()
            end
        end,
        Tooltip = "Leaves the queue you are in"
    })
end)

run(function()
    local SW
    SW = SNF.otherWindow:CreateModule({
        Name = "Sort Windows ⭐",
        Function = function(call)
            if call then
                SW:Toggle()
                Functions.sortVapeWindows()
            end
        end,
        Tooltip = "Sorts the gui windows"
    })
end)

run(function()
    local Uninject
    Uninject = SNF.otherWindow:CreateModule({
        Name = "Uninject ⭐",
        Function = function(call)
            if call then
                Uninject:Toggle()
                vape:Uninject()
            end
        end
    })
end)

run(function()
    local Restart
    Restart = SNF.otherWindow:CreateModule({
        Name = "Restart ⭐",
        Function = function(call)
            if call then
                Restart:Toggle()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VWRewrite/main/NewMainScript.lua", true))()
            end
        end
    })
end)