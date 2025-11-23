--[[
	Credits:
	Inf Yield (a.k.a. Infinite Yield)
	Please notify me if you need credits
]]

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

local fireproximityprompt = fireproximityprompt or function(prompt)
    prompt.HoldDuration = 0
    prompt:InputHoldBegin()
end

local lplr = Services.Players.LocalPlayer
local LocalPlayer = lplr

local ProximityPromptService = Services.ProximityPromptService
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService

local COOLDOWN = 0.5
local MAX_DISTANCE = 10
local SESSION_COUNTER = 1
local MAX_ITEM_DISTANCE = 20
local VISUALIZER_TIMEOUT = 5
--local ESP_ITEMS = {"Bandage", "Log", "Coal", "Fuel Canister", "Revolver Ammo", "Lost Child", "Lost Child2", "Lost Child3", "Item Chest", "Rifle Ammo", "Rifle", "Ammo", "Revolver", "Leather Body", "Iron Body", "Alpha Wolf Corpse", "Wolf Corpse"}
local ESP_ITEMS = {
    Health = {"Bandage"},
    Fuel = {"Fuel Canister", "Coal", "Sapling", "Log"},
    Food = {"Carrot", "Apple", "Berry"},
    Scrappable = {"Alpha Wolf Corpse", "Wolf Corpse"},
    Other = {"Revolver Ammo", "Lost Child", "Lost Child2", "Lost Child3", "Lost Child4", "Item Chest", "Rifle Ammo", "Rifle", "Ammo", "Revolver", "Leather Body", "Iron Body"}
}
local TARGET_RESOURCES = {"Small Tree", "Coal Deposit", "Fuel Deposit", "Bunny", "Wolf", "Cultist"}
local INTERACTABLE_ATTRIBUTES = {"RifleAmmo", "RevolverAmmo"}
local INTERACTABLE_ITEMS = {"Rifle", "Ammo", "Revolver", "Leather Body", "Iron Body"}

local CustomRoact = {}
function CustomRoact.createElement(elementType, props, children)
    local element = {Type = elementType, Props = props or {}, Children = children or {}}
    if props and props[CustomRoact.Ref] then
        element.Ref = props[CustomRoact.Ref]
        props[CustomRoact.Ref] = nil
    end
    return element
end
function CustomRoact.Ref()
    local ref = {Value = nil}
    function ref:getValue()
        return self.Value
    end
    return ref
end
local function applyProps(instance, props)
    for prop, value in next, props do
        if prop ~= "Parent" and prop ~= "Adornee" then
            instance[prop] = value
        end
    end
    if props.Adornee then
        instance.Adornee = props.Adornee
    end
    if props.Parent then
        instance.Parent = props.Parent
    end
end
local function createInstanceFromElement(element)
    local instance
    if element.Type == "BillboardGui" then
        instance = Instance.new("BillboardGui")
    elseif element.Type == "Frame" then
        instance = Instance.new("Frame")
    elseif element.Type == "UICorner" then
        instance = Instance.new("UICorner")
    elseif element.Type == "TextLabel" then
        instance = Instance.new("TextLabel")
    else
        return nil
    end
    applyProps(instance, element.Props)
    if element.Ref then
        element.Ref.Value = instance
    end
    for _, child in next, element.Children do
        local childInstance = createInstanceFromElement(child)
        if childInstance then
            childInstance.Parent = instance
        end
    end
    return instance
end
function CustomRoact.mount(element, parent)
    local instance = createInstanceFromElement(element)
    if instance then
        instance.Parent = parent
    end
    return {Instance = instance}
end
function CustomRoact.unmount(mounted)
    if mounted and mounted.Instance then
        mounted.Instance:Destroy()
    end
end

-- Healthbar management (inspired by BedWars customHealthbar)
local HealthbarManager = {
    healthbarMaid = {
        _tasks = {},
        DoCleaning = function(self)
            for _, task in pairs(self._tasks) do
                if type(task) == "function" then
                    pcall(task)
                end
            end
            table.clear(self._tasks)
        end,
        GiveTask = function(self, task)
            table.insert(self._tasks, task)
        end
    },
    healthbarPart = nil,
    healthbarBlockRef = nil,
    healthbarProgressRef = CustomRoact.Ref(),
    resourceHealthCache = {} -- Store initial health per resource
}

function HealthbarManager:customHealthbar(resource, health, maxHealth, changeHealth)
    if not resource:GetAttribute("Health") then return end
    local resourceKey = tostring(resource)
    
    -- Store initial health if not already cached
    if not self.resourceHealthCache[resourceKey] then
        self.resourceHealthCache[resourceKey] = maxHealth or resource:GetAttribute("Health") or 50
    end
    maxHealth = self.resourceHealthCache[resourceKey]
    
    local blockPosition = resource:GetPrimaryPartCFrame().p / 3 -- Adjust for scaling if needed
    local blockRef = {blockPosition = blockPosition}
    
    if not self.healthbarPart or not self.healthbarBlockRef or self.healthbarBlockRef.blockPosition ~= blockRef.blockPosition then
        self.healthbarMaid:DoCleaning()
        self.healthbarBlockRef = blockRef
        
        local percent = math.clamp(health / maxHealth, 0, 1)
        local cleanCheck = true
        local part = Instance.new("Part")
        part.Size = Vector3.one
        part.CFrame = CFrame.new(blockPosition * 3)
        part.Transparency = 1
        part.Anchored = true
        part.CanCollide = false
        part.Parent = Workspace
        self.healthbarPart = part
        
        local mounted = CustomRoact.mount(CustomRoact.createElement("BillboardGui", {
            Size = UDim2.fromOffset(160, 50),
            StudsOffset = Vector3.new(0, 3, 0),
            Adornee = part,
            MaxDistance = 80,
            AlwaysOnTop = true
        }, {
            CustomRoact.createElement("Frame", {
                Size = UDim2.fromOffset(160, 50),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 0.5
            }, {
                CustomRoact.createElement("UICorner", {CornerRadius = UDim.new(0, 5)}),
                CustomRoact.createElement("TextLabel", {
                    Size = UDim2.fromOffset(145, 14),
                    Position = UDim2.fromOffset(7, 5),
                    BackgroundTransparency = 1,
                    Text = resource.Name,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextScaled = true,
                    Font = Enum.Font.Arial
                }),
                CustomRoact.createElement("Frame", {
                    Size = UDim2.fromOffset(138, 4),
                    Position = UDim2.fromOffset(11, 30),
                    BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                }, {
                    CustomRoact.createElement("UICorner", {CornerRadius = UDim.new(1, 0)}),
                    CustomRoact.createElement("Frame", {
                        [CustomRoact.Ref] = self.healthbarProgressRef,
                        Size = UDim2.fromScale(percent, 1),
                        BackgroundColor3 = Color3.fromHSV(math.clamp(percent / 2.5, 0, 1), 0.89, 0.75)
                    }, {
                        CustomRoact.createElement("UICorner", {CornerRadius = UDim.new(1, 0)})
                    })
                })
            })
        }), part)
        
        self.healthbarMaid:GiveTask(function()
            cleanCheck = false
            self.healthbarBlockRef = nil
            CustomRoact.unmount(mounted)
            if self.healthbarPart then
                self.healthbarPart:Destroy()
                self.healthbarPart = nil
            end
            self.resourceHealthCache[resourceKey] = nil
        end)
        
        task.spawn(function()
            task.wait(VISUALIZER_TIMEOUT)
            if cleanCheck then
                self.healthbarMaid:DoCleaning()
            end
        end)
    end
    
    local newPercent = math.clamp((health - changeHealth) / maxHealth, 0, 1)
    if self.healthbarProgressRef:getValue() then
        TweenService:Create(self.healthbarProgressRef:getValue(), TweenInfo.new(0.3), {
            Size = UDim2.fromScale(newPercent, 1),
            BackgroundColor3 = Color3.fromHSV(math.clamp(newPercent / 2.5, 0, 1), 0.89, 0.75)
        }):Play()
    end
end

local ESPManager = {
    modules = {},
    createLabel = function(parent)
        if parent:FindFirstChild("ESP_Label") then
            return
        end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Label"
        billboard.Adornee = parent
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = parent
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = parent.Name
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0.5
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Parent = billboard
    end,
    createHighlight = function(item)
        if item:FindFirstChild("Highlight") then
            return
        end
        local highlight = Instance.new("Highlight")
        highlight.Name = "Highlight"
        highlight.Parent = item
        highlight.Adornee = item
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        if item.Name == "Bandage" then
            highlight.FillColor = Color3.fromRGB(0, 0, 0)
            --[[if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                LocalPlayer.Character:PivotTo(item:GetPrimaryPartCFrame())
            end--]]
        elseif item.Name == "Log" then
            highlight.FillColor = Color3.fromRGB(139, 69, 19)
        elseif item.Name == "Coal" then
            highlight.FillColor = Color3.fromRGB(50, 50, 50)
        elseif item.Name == "Fuel Canister" then
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
        elseif item.Name == "Revolver Ammo" then
            highlight.FillColor = Color3.fromRGB(255, 215, 0) -- Gold for ammo
        end
    end,
    removeESP = function(item)
        if item:FindFirstChild("Highlight") then
            item.Highlight:Destroy()
        end
        if item:FindFirstChild("ESP_Label") then
            item.ESP_Label:Destroy()
        end
    end
}

local SNF = {
    autoconsume = false
}

local function hook(parent, customRes)
    local res = customRes or {}
    for _, v in pairs(parent:GetChildren()) do
        table.insert(res, v)
    end
    parent.ChildAdded:Connect(function(v)
        local i = table.find(res, v)
        if i then
            pcall(function()
                table.remove(res, i)
            end)
        end
        table.insert(res, v)
    end)
    parent.ChildRemoved:Connect(function(v)
        local i = table.find(res, v)
        if i then
            pcall(function()
                table.remove(res, i)
            end)
        end
    end)
    return res
end

local characters = {}
local resources = {}
local items = {}

run(function()
    hook(Workspace:WaitForChild("Map"):WaitForChild("Landmarks"), resources)
    hook(Workspace:WaitForChild("Characters"), resources)
    hook(Workspace:WaitForChild("Map"):WaitForChild("Foliage"), resources)

    hook(Workspace:WaitForChild("Items"), items)
    hook(Workspace:WaitForChild("Characters"), characters)
end)

local Functions = {
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
    end,
    lobby = function()
        Services.TeleportService:Teleport(79546208627805)
    end,
    generateSessionID = function()
        local sessionID = SESSION_COUNTER .. "_" .. math.abs(lplr.UserId)
        SESSION_COUNTER = SESSION_COUNTER + 1
        return sessionID
    end,
    findNearestResource = function()
        local character = lplr.Character
        if not (character and character:FindFirstChild("HumanoidRootPart")) then
            return nil
        end
        local rootPart = character.HumanoidRootPart
        local closestResource, closestDistance = nil, math.huge
        local final = {}
        for i,v in pairs(resources) do
            table.insert(final, v)
        end
        for i,v in pairs(characters) do
            table.insert(final, v)
        end
        for _, resource in pairs(final) do
            pcall(function()
                if table.find(TARGET_RESOURCES, resource.Name) then
                    local primaryPart = resource:GetPrimaryPartCFrame().p
                    if primaryPart then
                        local distance = (rootPart.Position - primaryPart).Magnitude
                        if distance < closestDistance and distance <= MAX_DISTANCE then
                            closestResource = resource
                            closestDistance = distance
                        end
                    end
                end
            end)
        end
        table.clear(final)
        return closestResource
    end,
    findNearestItem = function(self, whitelist)
        whitelist = whitelist or {
            Food = true,
            Fuel = true,
            Scrappables = true
        }
        local character = lplr.Character
        if not (character and character:FindFirstChild("HumanoidRootPart")) then
            return nil
        end
        local rootPart = character.HumanoidRootPart
        local closestItem, closestDistance = nil, math.huge
        for _, item in pairs(items) do
            pcall(function()
                --if table.find(TARGET_RESOURCES, item.Name) then
                    local primaryPart = item:GetPrimaryPartCFrame().p
                    if primaryPart then
                        if self.isFood(item) and not whitelist.Food then return end
                        if self.isFuel(item) and not whitelist.Fuel then return end
                        if self.isScrappable(item) and not whitelist.Scrappables then return end

                        local distance = (rootPart.Position - primaryPart).Magnitude
                        if distance < closestDistance and distance <= MAX_ITEM_DISTANCE then
                            closestItem = item
                            closestDistance = distance
                        end
                    end
                --end
            end)
        end
        return closestItem
    end,
    getAxe = function()
        return lplr:WaitForChild("Inventory"):FindFirstChild("Old Axe") or lplr:WaitForChild("Inventory"):FindFirstChild("Good Axe") or lplr:WaitForChild("Inventory"):FindFirstChild("Strong Axe")
    end,
    damageResource = function(self, resource)
        local tool = self.getAxe()
        if not tool then
            warn("Old Axe not found in inventory")
            return
        end
        local sessionID = self.generateSessionID()
        local cframe = lplr.Character and lplr.Character.HumanoidRootPart and lplr.Character.HumanoidRootPart.CFrame
        if not cframe then
            warn("Character or HumanoidRootPart not found")
            return
        end
        local args = {
            resource,
            tool,
            sessionID,
            cframe
        }

        local currentHealth = resource:GetAttribute("Health") or 50

        local success, result = pcall(function()
            return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
        end)
        if success and result and result.Success then
            print("Successfully damaged", resource.Name, "with session ID", sessionID)
            local newHealth = resource:GetAttribute("Health") or currentHealth
            local changeHealth = currentHealth - newHealth
            HealthbarManager:customHealthbar(resource, newHealth, nil, changeHealth)
            return true
        else
            --SESSION_COUNTER = 1
            warn("Failed to damage", resource.Name, "with session ID", sessionID, result)
        end
    end,
    equipTool = function(tool)
        local args = {
            "FireAllClients",
            tool
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("EquipItemHandle"):FireServer(unpack(args))
    end,
    getSack = function()
        return lplr:WaitForChild("Inventory"):FindFirstChild("Old Sack") or lplr:WaitForChild("Inventory"):FindFirstChild("Good Sack") or lplr:WaitForChild("Inventory"):FindFirstChild("Giant Sack")
    end,
    storeItem = function(self, item)
        local suc, err = pcall(function()
            local args = {
                self.getSack(),
                item
            }
            game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagStoreItem"):InvokeServer(unpack(args))
        end)
        if not suc then
            warn("[storeItem | "..tostring(item).."]: "..tostring(err))
        end
    end,
    dropItem = function(self, item)
        local args = {
            self.getSack(),
            item
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagDropItem"):FireServer(unpack(args))
    end,
    burnItem = function(item)
        local args = {
            workspace:WaitForChild("Map"):WaitForChild("Campground"):WaitForChild("MainFire"),
            item
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBurnItem"):FireServer(unpack(args))
    end,
    cookItem = function(item)
        local args = {
            workspace:WaitForChild("Map"):WaitForChild("Campground"):WaitForChild("MainFire"),
            item
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestCookItem"):FireServer(unpack(args))
    end,
    cookBagItem = function(self, item)
        local args = {
            self.getSack(),
            item
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagDropItem"):FireServer(unpack(args))
    end,
    scrapItem = function(item)
        local args = {
	        workspace:WaitForChild("Map"):WaitForChild("Campground"):WaitForChild("CraftingBench"),
            item
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestScrapItem"):InvokeServer(unpack(args))
    end,
    biofuelItem = function(item)
        local args = {
            workspace:WaitForChild("Structures"):WaitForChild("Biofuel Processor"),
            item
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestProcessToBiofuel"):InvokeServer(unpack(args))
    end,
    cookStewItem = function(item)
        local args = {
            workspace:WaitForChild("Structures"):WaitForChild("Crock Pot"),
            item
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestCrockpotItem"):InvokeServer(unpack(args))
    end,
    isInteractable = function(item)
        if string.find(item.Name, "Flashlight") then
            return true
        end
        if table.find(INTERACTABLE_ITEMS, item.Name) then
            return true
        end
        for i, v in pairs(item:GetAttributes()) do
            if table.find(INTERACTABLE_ATTRIBUTES, i) then
                return true 
            end
        end
    end, 
    isFood = function(item)
        return item:GetAttribute("RestoreHunger")
    end,
    isScrappable = function(item)
        return item:GetAttribute("Scrappable")
    end,
    isFuel = function(item)
        return item:GetAttribute("BurnFuel")
    end, 
    acceptPlayAgain = function()
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("AcceptPlayAgain"):FireServer()
    end,
    consume = function(item)
        local args = {
            item
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(unpack(args))
    end,
    createCategoryModule = function(categoryName, itemNames, checkFunction)
        local toggles = {}
        for _, itemName in pairs(itemNames) do
            toggles[itemName] = true
        end

        local core = {}
        local index = tostring(Services.HttpService:GenerateGUID(false))
        core[index] = core[index] or {}

        local blocked = {}

        local mon = {}

        local module
        module = SNF.espWindow:CreateModule({
            Name = categoryName .. " ESP",
            Function = function(call)
                for i,v in pairs(mon) do
                    pcall(function()
                        v:Toggle()
                        v:Toggle()
                    end)
                end
                if call then
                    for _, item in pairs(Workspace.Items:GetChildren()) do
                        if  ((itemNames[item.Name] and toggles[item.Name]) or (checkFunction and checkFunction(item))) then
                            ESPManager.createHighlight(item)
                            ESPManager.createLabel(item)
                        end
                    end
                    for _, item in pairs(Workspace.Characters:GetChildren()) do
                        if ((itemNames[item.Name] and toggles[item.Name]) or (checkFunction and checkFunction(item))) then
                            ESPManager.createHighlight(item)
                            ESPManager.createLabel(item)
                        end
                    end
                    core[index].connection = Workspace.Items.ChildAdded:Connect(function(item)
                        if ((itemNames[item.Name] and toggles[item.Name]) or (checkFunction and checkFunction(item))) then
                            ESPManager.createHighlight(item)
                            ESPManager.createLabel(item)
                        end
                    end)
                    core[index].connection2 = Workspace.Characters.ChildAdded:Connect(function(item)
                        if ((itemNames[item.Name] and toggles[item.Name]) or (checkFunction and checkFunction(item))) then
                            ESPManager.createHighlight(item)
                            ESPManager.createLabel(item)
                        end
                    end)
                else
                    for _, item in pairs(Workspace.Items:GetChildren()) do
                        if ((itemNames[item.Name] and toggles[item.Name]) or (checkFunction and checkFunction(item))) then
                            ESPManager.removeESP(item)
                        end
                    end
                    for _, item in pairs(Workspace.Characters:GetChildren()) do
                        if ((itemNames[item.Name] and toggles[item.Name]) or (checkFunction and checkFunction(item))) then
                            ESPManager.removeESP(item)
                        end
                    end
                    if core[index].connection then
                        core[index].connection:Disconnect()
                        core[index].connection = nil
                    end
                    if core[index].connection2 then
                        core[index].connection2:Disconnect()
                        core[index].connection2 = nil
                    end
                end
            end
        })

        for _, itemName in pairs(itemNames) do
            local a = module:CreateToggle({
                Name = "Include " .. (itemName == "Bandage" and "Medkit" or itemName),
                Function = function(call)
                    toggles[itemName] = call
                    if not call then
                        for _, item in pairs(Workspace.Items:GetChildren()) do
                            if item.Name == itemName then
                                ESPManager.removeESP(item)
                            end
                        end
                        for _, item in pairs(Workspace.Characters:GetChildren()) do
                            if item.Name == itemName then
                                ESPManager.removeESP(item)
                            end
                        end
                    elseif module.Enabled then
                        for _, item in pairs(Workspace.Items:GetChildren()) do
                            if item.Name == itemName then
                                ESPManager.createHighlight(item)
                                ESPManager.createLabel(item)
                            end
                        end
                        for _, item in pairs(Workspace.Characters:GetChildren()) do
                            if item.Name == itemName then
                                ESPManager.createHighlight(item)
                                ESPManager.createLabel(item)
                            end
                        end
                        --[[pcall(function()
                            if module.Enabled then
                                module:Toggle()
                                module:Toggle()
                            end
                        end)--]]
                    end
                end,
                Default = true,
                Tooltip = "Toggle ESP for " .. (itemName == "Bandage" and "Medkit" or itemName)
            })
            table.insert(mon, a)
        end
        return module
    end
}

run(function()
    vape:CreateCategory({
        Name = "99 Nights in the Forest",
        Icon = 'rbxassetid://138008620313588',
        Size = UDim2.fromOffset(14, 14)
    })

    vape:CreateCategory({
        Name = "99 Nights - ESP",
        Icon = 'rbxassetid://138008620313588',
        Size = UDim2.fromOffset(14, 14)
    })

    vape:CreateCategory({
        Name = "99 Nights - Utility",
        Icon = 'rbxassetid://138008620313588',
        Size = UDim2.fromOffset(14, 14)
    })

    vape:CreateCategory({
        Name = "99 Nights - Other",
        Icon = 'rbxassetid://138008620313588',
        Size = UDim2.fromOffset(14, 14)
    })

    SNF.utilityWindow = vape.Categories["99 Nights - Utility"]
    SNF.window = vape.Categories["99 Nights in the Forest"]
    SNF.otherWindow = vape.Categories["99 Nights - Other"]
    SNF.espWindow = vape.Categories["99 Nights - ESP"]

    SNF.windows = {SNF.window, SNF.espWindow, SNF.otherWindow, SNF.utilityWindow}

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

--[[run(function()
    for _, itemName in pairs(ESP_ITEMS) do
        local moduleName = itemName == "Bandage" and "Medkit ESP" or itemName .. " ESP"
        ESPManager.modules[itemName] = SNF.espWindow:CreateModule({
            Name = moduleName,
            Function = function(call)
                if call then
                    for _, item in pairs(items) do
                        if item.Name == itemName and item.Name ~= "Bolt" then
                            ESPManager.createHighlight(item)
                            ESPManager.createLabel(item)
                        end
                    end
                    for _, item in pairs(characters) do
                        if item.Name == itemName and item.Name ~= "Bolt" then
                            ESPManager.createHighlight(item)
                            ESPManager.createLabel(item)
                        end
                    end
                    ESPManager.modules[itemName].connection = Workspace.Items.ChildAdded:Connect(function(item)
                        if item.Name == itemName and item.Name ~= "Bolt" then
                            ESPManager.createHighlight(item)
                            ESPManager.createLabel(item)
                        end
                    end)
                    ESPManager.modules[itemName].connection2 = Workspace.Characters.ChildAdded:Connect(function(item)
                        if item.Name == itemName and item.Name ~= "Bolt" then
                            ESPManager.createHighlight(item)
                            ESPManager.createLabel(item)
                        end
                    end)
                else
                    for _, item in pairs(items) do
                        if item.Name == itemName and item.Name ~= "Bolt" then
                            ESPManager.removeESP(item)
                        end
                    end
                    for _, item in pairs(characters) do
                        if item.Name == itemName and item.Name ~= "Bolt" then
                            ESPManager.removeESP(item)
                        end
                    end
                    if ESPManager.modules[itemName].connection then
                        ESPManager.modules[itemName].connection:Disconnect()
                        ESPManager.modules[itemName].connection = nil
                    end
                    if ESPManager.modules[itemName].connection2 then
                        ESPManager.modules[itemName].connection2:Disconnect()
                        ESPManager.modules[itemName].connection2 = nil
                    end
                end
            end
        })
    end
end)

run(function()
    local itemName = "Food"
    ESPManager.modules[itemName] = SNF.espWindow:CreateModule({
        Name = itemName.." ESP",
        Function = function(call)
            if call then
                for _, item in pairs(items) do
                    if Functions.isFood(item) and item.Name ~= "Bolt" then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end
                ESPManager.modules[itemName].connection = Workspace.Items.ChildAdded:Connect(function(item)
                    if Functions.isFood(item) and item.Name ~= "Bolt" then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end)
            else
                for _, item in pairs(items) do
                    if Functions.isFuel(item) and item.Name ~= "Bolt" then
                        ESPManager.removeESP(item)
                    end
                end
                if ESPManager.modules[itemName].connection then
                    ESPManager.modules[itemName].connection:Disconnect()
                    ESPManager.modules[itemName].connection = nil
                end
            end
        end
    })
end)

run(function()
    local itemName = "Fuel"
    ESPManager.modules[itemName] = SNF.espWindow:CreateModule({
        Name = itemName.." ESP",
        Function = function(call)
            if call then
                for _, item in pairs(items) do
                    if Functions.isFuel(item) and item.Name ~= "Bolt" then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end
                for _, item in pairs(characters) do
                    if Functions.isFuel(item) and item.Name ~= "Bolt" then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end
                ESPManager.modules[itemName].connection = Workspace.Items.ChildAdded:Connect(function(item)
                    if Functions.isFuel(item) and item.Name ~= "Bolt" then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end)
                ESPManager.modules[itemName].connection2 = Workspace.Characters.ChildAdded:Connect(function(item)
                    if Functions.isFuel(item) and item.Name ~= "Bolt" then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end)
            else
                for _, item in pairs(items) do
                    if Functions.isFuel(item) and item.Name ~= "Bolt" then
                        ESPManager.removeESP(item)
                    end
                end
                for _, item in pairs(characters) do
                    if Functions.isFuel(item) and item.Name ~= "Bolt" then
                        ESPManager.removeESP(item)
                    end
                end
                if ESPManager.modules[itemName].connection then
                    ESPManager.modules[itemName].connection:Disconnect()
                    ESPManager.modules[itemName].connection = nil
                end
                if ESPManager.modules[itemName].connection2 then
                    ESPManager.modules[itemName].connection2:Disconnect()
                    ESPManager.modules[itemName].connection2 = nil
                end
            end
        end
    })
end)

run(function()
    local itemName = "Scrappable"
    ESPManager.modules[itemName] = SNF.espWindow:CreateModule({
        Name = itemName.." ESP",
        Function = function(call)
            if call then
                for _, item in pairs(items) do
                    if Functions.isScrappable(item) then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end
                for _, item in pairs(characters) do
                    if Functions.isScrappable(item) and then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end
                ESPManager.modules[itemName].connection = Workspace.Items.ChildAdded:Connect(function(item)
                    if Functions.isScrappable(item) and then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end)
                ESPManager.modules[itemName].connection2 = Workspace.Characters.ChildAdded:Connect(function(item)
                    if Functions.isScrappable(item) then
                        ESPManager.createHighlight(item)
                        ESPManager.createLabel(item)
                    end
                end)
            else
                for _, item in pairs(items) do
                    if Functions.isScrappable(item) then
                        ESPManager.removeESP(item)
                    end
                end
                for _, item in pairs(characters) do
                    if Functions.isScrappable(item) then
                        ESPManager.removeESP(item)
                    end
                end
                if ESPManager.modules[itemName].connection then
                    ESPManager.modules[itemName].connection:Disconnect()
                    ESPManager.modules[itemName].connection = nil
                end
                if ESPManager.modules[itemName].connection2 then
                    ESPManager.modules[itemName].connection2:Disconnect()
                    ESPManager.modules[itemName].connection2 = nil
                end
            end
        end
    })
end)--]]

run(function()
    ESPManager.modules["Health"] = Functions.createCategoryModule("Health", ESP_ITEMS.Health, nil)
    ESPManager.modules["Fuel"] = Functions.createCategoryModule("Fuel", ESP_ITEMS.Fuel, Functions.isFuel)
    ESPManager.modules["Food"] = Functions.createCategoryModule("Food", ESP_ITEMS.Food, Functions.isFood)
    ESPManager.modules["Scrappable"] = Functions.createCategoryModule("Scrappable", ESP_ITEMS.Scrappable, Functions.isScrappable)
    ESPManager.modules["Other"] = Functions.createCategoryModule("Other", ESP_ITEMS.Other, nil)
end)

run(function()
    local AConsume
    AConsume = SNF.window:CreateModule({
        Name = "Auto Consume",
        Function = function(call)
            SNF.autoconsume = call
        end
    })
end)

local oldLocation

run(function()
    local TTF
    TTF = SNF.window:CreateModule({
        Name = "Teleport To Fire",
        Function = function(call)
            if call then
                TTF:Toggle()
                local suc = pcall(function()
                    oldLocation = lplr.Character:GetPrimaryPartCFrame()
                    lplr.Character:PivotTo(Services.Workspace.Map.Campground.MainFire:GetPrimaryPartCFrame() + Vector3.new(0, 20, 0))
                end)
                if suc then
                    InfoNotification("Teleport To Fire", "Use Teleport Back to get back to your position", 1.5)
                end
            end
        end
    })
end)

run(function()
    local TTFB
    TTFB = SNF.window:CreateModule({
        Name = "Teleport Back",
        Function = function(call)
            if call then
                TTFB:Toggle()
                pcall(function()
                    if not oldLocation then return end
                    lplr.Character:PivotTo(oldLocation)
                end)
            end
        end
    })
end)

run(function()
    local ACT
    local lastSwing = 0
    ACT = SNF.window:CreateModule({
        Name = "Auto Chop Trees",
        Function = function(call)
            if call then
                Functions.equipTool(Functions.getAxe())
                task.spawn(function()
                    lastSwing = 0
                    repeat
                        if time() >= lastSwing + COOLDOWN then
                            lastSwing = time()
                            local resource = Functions.findNearestResource()
                            if resource then
                                local res = Functions:damageResource(resource)
                                if not res then
                                    Functions.equipTool(Functions.getAxe())
                                end
                            else
                                --print("No nearby resource found")
                            end
                        end
                        task.wait(COOLDOWN)
                    until not ACT.Enabled
                end)
            end
        end
    })
end)

local disabledTick = tick()
local disabledAC = false
run(function()
    local ACI
    local Carrots = false
    local Berries = false

    local Core = {
        Scrappables = false,
        Food = false,
        Fuel = false
    }

    ACI = SNF.window:CreateModule({
        Name = "Auto Collect Items",
        Function = function(call)
            if call then
                task.spawn(function()
                    repeat
                        task.wait()
                        if disabledAC and tick() - disabledTick > 5 then
                            disabledAC = false
                        end
                        if disabledAC then print("blocked", tick() - disabledTick); return end
                        pcall(function()
                            local item = Functions:findNearestItem(Core)
                            if item then
                                if Functions.isScrappable(item) and not Core.Scrappables then return end
                                if Functions.isFood(item) and not Core.Food then return end
                                if Functions.isFuel(item) and not Core.Fuel then return end

                                if tostring(item) == "Carrot" and not Carrots then return end
                                if tostring(item) == "Berry" and not Berries then return end

                                if Functions.isInteractable(item) and SNF.autoconsume then
                                    Functions.consume(item)
                                else
                                    Functions:storeItem(item)
                                end
                            end
                        end)
                    until not ACI.Enabled
                end)
            end
        end
    })
    for i, _ in pairs(Core) do
        ACI:CreateToggle({
            Name = "Include "..tostring(i),
            Function = function(call)
                Core[i] = call
            end,
            Default = true
        })
    end
    ACI:CreateToggle({
        Name = "Include carrots",
        Function = function(call)
            Carrots = call
        end
    })
    ACI:CreateToggle({
        Name = "Include Berries",
        Function = function(call)
            Berries = call
        end
    })
end)

run(function()
    local DAI
    DAI = SNF.window:CreateModule({
        Name = "Drop All Items",
        Function = function(call)
            if call then
                DAI:Toggle()
                disabledAC = true
                disabledTick = tick()
                pcall(function()
                    for _, item in pairs(Services.Workspace.Items:GetChildren()) do
                        if Functions.isFood(item) and item:GetAttribute("LastOwner") ~= nil and tostring(item:GetAttribute("LastOwner")) == tostring(lplr.UserId) then
                            --Functions:cookBagItem(item)
                            --Functions.cookItem(item)
                        end
                    end
                    for _, item in pairs(lplr:WaitForChild("ItemBag"):GetChildren()) do
                        if Functions.isFuel(item) then
                            Functions.burnItem(item)
                        elseif Functions.isFood(item) then
                            --Functions:dropItem(item)
                            --Functions:cookBagItem(item)
                            --Functions.cookItem(item)
                        elseif Functions.isScrappable(item) then
                            Functions.scrapItem(item)
                        else
                            Functions:dropItem(item)
                        end
                    end
                end)
                task.wait(1)
                disabledAC = false
            end
        end
    })
end)

run(function()
    local SA
    SA = SNF.window:CreateModule({
        Name = "Scrap All",
        Function = function(call)
            if call then
                SA:Toggle()
                disabledAC = true
                disabledTick = tick()
                pcall(function()
                    for _, item in pairs(lplr:WaitForChild("ItemBag"):GetChildren()) do
                        Functions.scrapItem(item)
                    end
                end)
                task.wait(1)
                disabledAC = false
            end
        end
    })
end)

run(function()
    local BA
    BA = SNF.window:CreateModule({
        Name = "Biofuel All",
        Function = function(call)
            if call then
                BA:Toggle()
                disabledAC = true
                disabledTick = tick()
                if not workspace:WaitForChild("Structures"):FindFirstChild("Biofuel Processor") then
                    errorNotification("Biofuel All", "Biofuel Processor required!", 3)
                end
                
                pcall(function()
                    for _, item in pairs(lplr:WaitForChild("ItemBag"):GetChildren()) do
                        if Functions.isFuel(item) or Functions.isFood(item) then
                            Functions.biofuelItem(item)
                        end
                    end
                end)
                task.wait(1)
                disabledAC = false
            end
        end
    })
end)

run(function()
    local CSA
    CSA = SNF.window:CreateModule({
        Name = "Cook Stew All",
        Function = function(call)
            if call then
                CSA:Toggle()
                disabledAC = true
                disabledTick = tick()
                if not workspace:WaitForChild("Structures"):FindFirstChild("Crock Pot") then
                    errorNotification("Cook Stew All", "Crock Pot required!", 3)
                end
                
                pcall(function()
                    for _, item in pairs(lplr:WaitForChild("ItemBag"):GetChildren()) do
                        print(item, Functions.isFood(item), tostring(item) == "Berry")
                        if Functions.isFood(item) and tostring(item) == "Berry" then
                            Functions.cookStewItem(item)
                        end
                    end
                end)
                task.wait(1)
                disabledAC = false
            end
        end
    })
end)

run(function()
    local FB
    local b = 5
    local Original = {
        Brightness = Services.Lighting.Brightness,
        GlobalShadows = Services.Lighting.GlobalShadows,
        Ambient = Services.Lighting.Ambient
    }
    FB = SNF.window:CreateModule({
        Name = "Fullbright",
        Function = function(call)
            if call then
                Original = {
                    Brightness = Services.Lighting.Brightness,
                    GlobalShadows = Services.Lighting.GlobalShadows,
                    Ambient = Services.Lighting.Ambient
                }
                task.spawn(function()
                    repeat
                        task.wait()

                        Services.Lighting.Brightness = b
                        Services.Lighting.GlobalShadows = false
                        Services.Lighting.FogEnd = 100000
                        Services.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                    until not FB.Enabled
                end)
            else
                for i,v in pairs(Original) do
                    pcall(function()
                        Services.Lighting[i] = v
                    end)
                end
            end
        end
    })
    FB:CreateSlider({
        Name = "Brightness",
        Function = function(val, final)
            if not (val ~= nil and val > 0) then return end
            b = val
            if final and FB.Enabled then
                FB:Toggle()
                FB:Toggle()
            end
        end,
        Min = 1,
        Max = 15,
        Default = 5
    })
end)

run(function()
    local GTL
    GTL = SNF.window:CreateModule({
        Name = "Go To Lobby",
        Function = function(call)
            if call then
                GTL:Toggle()
                InfoNotification("Go To Lobby", "Teleporting back to lobby...", 3)
                Functions.lobby()
            end
        end,
        Tooltip = "Teleports you back to the lobby"
    })
end)

run(function()
    local PA
    PA = SNF.window:CreateModule({
        Name = "Play Again",
        Function = function(call)
            if call then
                PA:Toggle()
                Functions.acceptPlayAgain()
            end
        end
    })
end)

-- TP Walk (Credits to Infinite Yield)
local tpwalking = false
local tpwalkConnection = nil
run(function()
    local TPW
    local speed = 10
    TPW = SNF.utilityWindow:CreateModule({
        Name = "Teleport Walk",
        Function = function(call)
            if call then
                tpwalking = true
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    tpwalkConnection = RunService.Heartbeat:Connect(function(delta)
                        if tpwalking and character and humanoid and humanoid.Parent then
                            if humanoid.MoveDirection.Magnitude > 0 then
                                character:TranslateBy(humanoid.MoveDirection * speed * delta * 10)
                            end
                        else
                            tpwalking = false
                            if tpwalkConnection then
                                tpwalkConnection:Disconnect()
                                tpwalkConnection = nil
                            end
                        end
                    end)
                    --InfoNotification("Teleport Walk", "Teleport Walk Enabled", 1.5)
                end
            else
                tpwalking = false
                if tpwalkConnection then
                    tpwalkConnection:Disconnect()
                    tpwalkConnection = nil
                end
                --InfoNotification("Teleport Walk", "Teleport Walk Disabled", 1.5)
            end
        end
    })

    TPW:CreateSlider({
        Name = "Speed",
        Function = function(val)
            if val and val > 0 then
                speed = val
            end
        end,
        Min = 1,
        Max = 50,
        Default = 10
    })
end)

-- NoClip Module (Credits: Infinite Yield)
local Clip = true
local noclipConnection = nil
run(function()
    local NC = SNF.utilityWindow:CreateModule({
        Name = "NoClip",
        Function = function(call)
            if call then
                Clip = false
                noclipConnection = RunService.Stepped:Connect(function()
                    if Clip == false and LocalPlayer.Character then
                        for _, child in pairs(LocalPlayer.Character:GetDescendants()) do
                            if child:IsA("BasePart") and child.CanCollide == true then
                                child.CanCollide = false
                            end
                        end
                    end
                end)
                --InfoNotification("NoClip", "NoClip Enabled", 1.5)
            else
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
                Clip = true
                if LocalPlayer.Character then
                    for _, child in pairs(LocalPlayer.Character:GetDescendants()) do
                        if child:IsA("BasePart") then
                            child.CanCollide = true
                        end
                    end
                end
                --InfoNotification("NoClip", "NoClip Disabled", 1.5)
            end
        end
    })
end)

run(function()
	local AntiVoid
	local Method
	local Mode
	local Material
	local Color
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local part
	
	AntiVoid = SNF.utilityWindow:CreateModule({
		Name = 'AntiVoid',
		Function = function(callback)
			if callback then
				if Method.Value == 'Part' then 
					local debounce = tick()
					part = Instance.new('Part')
					part.Size = Vector3.new(10000, 1, 10000)
					part.Transparency = 1 - Color.Opacity
					part.Material = Enum.Material[Material.Value]
					part.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
					part.CanCollide = Mode.Value == 'Collide'
					part.Anchored = true
					part.CanQuery = false
					part.Parent = game.Workspace
					AntiVoid:Clean(part)
					AntiVoid:Clean(part.Touched:Connect(function(touchedpart)
						if touchedpart.Parent == lplr.Character and entitylib.isAlive and debounce < tick() then
							local root = entitylib.character.RootPart
							debounce = tick() + 0.1
							if Mode.Value == 'Velocity' then
								root.Velocity = Vector3.new(root.Velocity.X, 100, root.Velocity.Z)
							end
						end
					end))
	
					repeat
						if entitylib.isAlive then 
							local root = entitylib.character.RootPart
							rayCheck.FilterDescendantsInstances = {gameCamera, lplr.Character, part}
							rayCheck.CollisionGroup = root.CollisionGroup
							local ray = game.Workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
							if ray then
								part.Position = ray.Position - Vector3.new(0, 15, 0)
							end
						end
						task.wait(0.1)
					until not AntiVoid.Enabled
				else
					local lastpos
					AntiVoid:Clean(RunService.PreSimulation:Connect(function()
						if entitylib.isAlive then
							local root = entitylib.character.RootPart
							lastpos = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and root.Position or lastpos
							if (root.Position.Y + (root.Velocity.Y * 0.016)) <= (game.Workspace.FallenPartsDestroyHeight + 10) then
								lastpos = lastpos or Vector3.new(root.Position.X, (game.Workspace.FallenPartsDestroyHeight + 20), root.Position.Z)
								root.CFrame += (lastpos - root.Position)
								root.Velocity *= Vector3.new(1, 0, 1)
							end
						end
					end))
				end
			end
		end,
		Tooltip = 'Help\'s you with your Parkinson\'s\nPrevents you from falling into the void.'
	})
	Method = AntiVoid:CreateDropdown({
		Name = 'Method',
		List = {'Part', 'Classic'},
		Function = function(val)
			if Mode.Object then 
				Mode.Object.Visible = val == 'Part'
				Material.Object.Visible = val == 'Part'
				Color.Object.Visible = val == 'Part'
			end
			if AntiVoid.Enabled then 
				AntiVoid:Toggle()
				AntiVoid:Toggle()
			end
		end,
		Tooltip = 'Part - Moves a part under you that does various methods to stop you from falling\nClassic - Teleports you out of the void after reaching the part destroy plane'
	})
	Mode = AntiVoid:CreateDropdown({
		Name = 'Move Mode',
		List = {'Velocity', 'Collide'},
		Darker = true,
		Function = function(val)
			if part then
				part.CanCollide = val == 'Collide'
			end
		end,
		Tooltip = 'Velocity - Launches you upward after touching\nCollide - Allows you to walk on the part'
	})
	local materials = {'ForceField'}
	for _, v in Enum.Material:GetEnumItems() do
		if v.Name ~= 'ForceField' then
			table.insert(materials, v.Name)
		end
	end
	Material = AntiVoid:CreateDropdown({
		Name = 'Material',
		List = materials,
		Darker = true,
		Function = function(val)
			if part then 
				part.Material = Enum.Material[val] 
			end
		end
	})
	Color = AntiVoid:CreateColorSlider({
		Name = 'Color',
		DefaultOpacity = 0.5,
		Darker = true,
		Function = function(h, s, v, o)
			if part then
				part.Color = Color3.fromHSV(h, s, v)
				part.Transparency = 1 - o
			end
		end
	})
end)

local vec3 = function(a, b, c) return Vector3.new(a, b, c) end
run(function() 
	local CustomJump = {Enabled = false}
	local CustomJumpMode = {Value = "Normal"}
	local CustomJumpVelocity = {Value = 50}
	local UIS_Connection = {Disconnect = function() end}
	CustomJump = SNF.utilityWindow:CreateModule({
		Name = "InfJUmp",
        Tooltip = "Gives you infinite jumps.",
		Function = function(callback)
			if callback then
				UIS_Connection = Services.InputService.JumpRequest:Connect(function()
					if CustomJumpMode.Value == "Normal" then
						entityLibrary.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					elseif CustomJumpMode.Value == "Velocity" then
						entityLibrary.character.HumanoidRootPart.Velocity += vec3(0,CustomJumpVelocity.Value,0)
					end 
				end)
			else
				pcall(function()
					UIS_Connection:Disconnect()
				end)
			end
		end,
		ExtraText = function()
			return CustomJumpMode.Value
		end
	})
	CustomJumpMode = CustomJump:CreateDropdown({
		Name = "Mode",
		List = {
			"Normal",
			"Velocity"
		},
		Function = function() end,
	})
	CustomJumpVelocity = CustomJump:CreateSlider({
		Name = "Velocity",
		Min = 1,
		Max = 100,
		Function = function() end,
		Default = 50
	})
end)

local PromptButtonHoldBegan = nil
run(function()
    local IPP 
    IPP = SNF.utilityWindow:CreateModule({
        Name = "Instant Proximity Prompts",
        Function = function(call)
            if call then
                if fireproximityprompt then
                    if PromptButtonHoldBegan then
                        PromptButtonHoldBegan:Disconnect()
                        PromptButtonHoldBegan = nil
                    end
                    task.wait(0.1)
                    PromptButtonHoldBegan = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
                        fireproximityprompt(prompt)
                    end)
                    --InfoNotification("Instant Proximity Prompts", "Instant Proximity Prompts Enabled", 1.5)
                else
                    IPP:Toggle()
                    InfoNotification("Incompatible Exploit", "Your exploit does not support this feature (missing fireproximityprompt)", 3)
                end
            else
                if PromptButtonHoldBegan then
                    PromptButtonHoldBegan:Disconnect()
                    PromptButtonHoldBegan = nil
                end
                --InfoNotification("Instant Proximity Prompts", "Instant Proximity Prompts Disabled", 1.5)
            end
        end
    })
end)

run(function()
	local ZoomUnlocker = {Enabled = false}
	local ZoomUnlockerMode = {Value = 'Infinite'}
	local ZoomUnlockerZoom = {Value = 500}
	local ZoomConnection, OldZoom = nil, nil
	ZoomUnlocker = SNF.utilityWindow:CreateModule({
		Name = 'Zoom Unlocker',
        Tooltip = 'Unlocks the abillity to zoom more.',
		Function = function(callback)
			if callback then
				OldZoom = lplr.CameraMaxZoomDistance
				ZoomUnlocker = runService.Heartbeat:Connect(function()
					if ZoomUnlockerMode.Value == 'Infinite' then
						lplr.CameraMaxZoomDistance = 9e9
					else
						lplr.CameraMaxZoomDistance = ZoomUnlockerZoom.Value
					end
				end)
			else
				if ZoomUnlocker then ZoomUnlocker:Disconnect() end
				lplr.CameraMaxZoomDistance = OldZoom
				OldZoom = nil
			end
		end,
        Default = false,
		ExtraText = function()
            return ZoomUnlockerMode.Value
        end
	})
	ZoomUnlockerMode = ZoomUnlocker:CreateDropdown({
		Name = 'Mode',
		List = {
			'Infinite',
			'Custom'
		},
		Tooltip = 'Mode to unlock the zoom.',
		Value = 'Infinite',
		Function = function() end
	})
	ZoomUnlockerZoom = ZoomUnlocker:CreateSlider({
		Name = 'Zoom',
		Min = OldZoom or 13,
		Max = 1000,
		Tooltip = 'Amount to unlock the zoom.',
		Function = function() end,
		Default = 500
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