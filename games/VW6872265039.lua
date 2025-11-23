repeat task.wait() until game:IsLoaded()
repeat task.wait() until shared.GuiLibrary
repeat task.wait() until shared.GlobalBedwars

local GuiLibrary = shared.GuiLibrary
local vape = GuiLibrary

local vapeConnections
if shared.vapeConnections and type(shared.vapeConnections) == "table" then vapeConnections = shared.vapeConnections else vapeConnections = {}; shared.vapeConnections = vapeConnections; end
GuiLibrary.SelfDestructEvent.Event:Connect(function()
	for i, v in pairs(vapeConnections) do
		if v.Disconnect then pcall(function() v:Disconnect() end) continue end
		if v.disconnect then pcall(function() v:disconnect() end) continue end
	end
end)

local function run(func)
	local suc, err = pcall(function()
		func()
	end)
	if err then warn("[VW6872265039.lua Module Error]: "..tostring(debug.traceback(err))) end
end

local lplr = game:GetService("Players").LocalPlayer

local bedwars = shared.GlobalBedwars

local function BedwarsInfoNotification(mes)
    local bedwars = shared.GlobalBedwars
	local NotificationController = bedwars.NotificationController
	NotificationController:sendInfoNotification({
		message = tostring(mes),
		image = "rbxassetid://18518244636"
	});
end
VoidwareFunctions.GlobaliseObject("BedwarsInfoNotification", BedwarsInfoNotification)
local function BedwarsErrorNotification(mes)
    local bedwars = shared.GlobalBedwars
	local NotificationController = bedwars.NotificationController
	NotificationController:sendErrorNotification({
		message = tostring(mes),
		image = "rbxassetid://18518244636"
	});
end
VoidwareFunctions.GlobaliseObject("BedwarsErrorNotification", BedwarsErrorNotification)

local function queue()
	local args = {
		[1] = {
			["queueType"] = "bedwars_duels"
		}
	}
	game:GetService("ReplicatedStorage"):WaitForChild("events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events"):WaitForChild("joinQueue"):FireServer(unpack(args))
end

if shared.TeleportExploitAutowinEnabled then
	local interactable_buttons_table = {
		[1] = {
			["Name"] = "Yes",
			["Function"] = function()
				shared.MadeChoice = true
				shared.TeleportExploitAutowinEnabled = nil
				queue()
			end
		},
		[2] = {
			["Name"] = "No",
			["Function"] = function()
				shared.TeleportExploitAutowinEnabled = nil
				shared.MadeChoice = true 
			end
		}
	}
	--[[local function InfoNotification2(title, text, delay, button_table)
		local suc, res = pcall(function()
			local frame = GuiLibrary.CreateInteractableNotification(title or "Voidware", text or "Successfully called function", delay or 7, "assets/InfoNotification.png", button_table)
			return frame
		end)
		return (suc and res)
	end
	InfoNotification2("EmptyGameTP - AutowinMode", "An error might have happened while auto-queueing. Would you like to \n join back to the queue?", 10000000, interactable_buttons_table)--]]
	task.wait(3)
	if (not shared.MadeChoice) then queue() end
end

run(function()
    local QueueDisplayConfig = {
        ActiveState = false,
        GradientControl = {Enabled = true},
        ColorSettings = {
            Gradient1 = {Hue = 0, Saturation = 0, Brightness = 1},
            Gradient2 = {Hue = 0, Saturation = 0, Brightness = 0.8}
        },
        Animation = {Speed = 0.5, Progress = 0}
    }

    local DisplayUtils = {
        createGradient = function(parent)
            local gradient = parent:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
            gradient.Parent = parent
            return gradient
        end,
        updateColor = function(gradient, config)
            local time = tick() * config.Animation.Speed
            local interp = (math.sin(time) + 1) / 2
            local h = config.ColorSettings.Gradient1.Hue + (config.ColorSettings.Gradient2.Hue - config.ColorSettings.Gradient1.Hue) * interp
            local s = config.ColorSettings.Gradient1.Saturation + (config.ColorSettings.Gradient2.Saturation - config.ColorSettings.Gradient1.Saturation) * interp
            local b = config.ColorSettings.Gradient1.Brightness + (config.ColorSettings.Gradient2.Brightness - config.ColorSettings.Gradient1.Brightness) * interp
            gradient.Color = ColorSequence.new(Color3.fromHSV(h, s, b))
        end
    }

	local CoreConnection

    local function enhanceQueueDisplay()
		pcall(function() 
			CoreConnection:Disconnect()
		end)
        local success, err = pcall(function()
            if not lplr.PlayerGui:FindFirstChild('QueueApp') then return end
            
            for attempt = 1, 3 do
                if QueueDisplayConfig.GradientControl.Enabled then
                    local queueFrame = lplr.PlayerGui.QueueApp['1']
                    queueFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    
                    local gradient = DisplayUtils.createGradient(queueFrame)
                    gradient.Rotation = 180
                    
                    local displayInterface = {
                        module = vape.watermark,
                        gradient = gradient,
                        GetEnabled = function()
                            return QueueDisplayConfig.ActiveState
                        end,
                        SetGradientEnabled = function(state)
                            QueueDisplayConfig.GradientControl.Enabled = state
                            gradient.Enabled = state
                        end
                    }
                    --vape.whitelistedlines["enhancedQueueDisplay"] = displayInterface
                    CoreConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        if QueueDisplayConfig.ActiveState and QueueDisplayConfig.GradientControl.Enabled then
                            DisplayUtils.updateColor(gradient, QueueDisplayConfig)
                        end
                    end)
                end
                task.wait(0.1)
            end
        end)
        
        if not success then
            warn("Queue display enhancement failed: " .. tostring(err))
        end
    end

    local QueueDisplayEnhancer
    QueueDisplayEnhancer = vape.Categories.Utility:CreateModule({
        Name = 'QueueCardMods',
        Tooltip = 'Enhances the QueueApp display with dynamic gradients',
        Function = function(enabled)
            QueueDisplayConfig.ActiveState = enabled
            if enabled then
                enhanceQueueDisplay()
                QueueDisplayEnhancer:Clean(lplr.PlayerGui.ChildAdded:Connect(enhanceQueueDisplay))
			else
				pcall(function() 
					CoreConnection:Disconnect()
				end)
			end
        end
    })

   	QueueDisplayEnhancer:CreateSlider({
        Name = "Animation Speed",
        Function = function(speed)
            QueueDisplayConfig.Animation.Speed = math.clamp(speed, 0.1, 5)
        end,
        Min = 1,
        Max = 5,
        Default = 5
    })

    QueueDisplayEnhancer:CreateColorSlider({
        Name = "Color 1",
        Function = function(h, s, v)
            QueueDisplayConfig.ColorSettings.Gradient1 = {Hue = h, Saturation = s, Brightness = v}
        end
    })

    QueueDisplayEnhancer:CreateColorSlider({
        Name = "Color 2",
        Function = function(h, s, v)
            QueueDisplayConfig.ColorSettings.Gradient2 = {Hue = h, Saturation = s, Brightness = v}
        end
    })
end)

--[[run(function()
	local AutoCrate = {Enabled = false}
	local aut = 0
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local rbxts_include = replicatedStorage:WaitForChild("rbxts_include")
	local net = rbxts_include:WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")

	local function openCrate(crateType, altarId, crateName)
		local spawnArgs = {
			[1] = {
				["crateType"] = crateType,
				["altarId"] = altarId
			}
		}
		net:WaitForChild("RewardCrate/SpawnRewardCrate"):FireServer(unpack(spawnArgs))

		local crateAltar = game.Workspace:FindFirstChild("CrateAltar_" .. altarId)
		if crateAltar and crateAltar:FindFirstChild(crateName) then
			local openArgs = {
				[1] = {
					["crateId"] = tostring(crateAltar:FindFirstChild(crateName):GetAttribute("crateId"))
				}
			}
			net:WaitForChild("RewardCrate/OpenRewardCrate"):FireServer(unpack(openArgs))
		end
	end

	AutoCrate = vape.Categories.Blatant:CreateModule({
		Name = "AutoCrate",
		Tooltip = "Automatically open crates if you have any.",
		Function = function(callback)
			if callback then
			    task.spawn(function()
			        repeat task.wait()
			        aut = aut + 1
					if aut >= 45 then
						openCrate("level_up_crate", 0, "RewardCrate")
						openCrate("level_up_crate", 1, "RewardCrate")
						openCrate("diamond_lucky_crate", 0, "DiamondLuckyCrate")
						openCrate("diamond_lucky_crate", 1, "DiamondLuckyCrate")
						aut = 0
					end
			        until not AutoCrate.Enabled
			    end)
				--RunLoops:BindToStepped("crate", 1, function()
				--end)
			else
				--RunLoops:UnbindFromStepped("crate")
			end
		end
	})
end)--]]

task.spawn(function()
    pcall(function()
        local lplr = game:GetService("Players").LocalPlayer
        local char = lplr.Character or lplr.CharacterAdded:wait()
        local displayName = char:WaitForChild("Head"):WaitForChild("Nametag"):WaitForChild("DisplayNameContainer"):WaitForChild("DisplayName")
        repeat task.wait() until shared.vapewhitelist
        repeat task.wait() until shared.vapewhitelist.loaded
        local tag = shared.vapewhitelist:tag(lplr, "", true)
        if displayName.ClassName == "TextLabel" then
            if not displayName.RichText then displayName.RichText = true end
            displayName.Text = tag..lplr.Name
        end
        table.insert(vapeConnections, displayName:GetPropertyChangedSignal("Text"):Connect(function()
            if displayName.Text ~= tag..lplr.Name then
                displayName.Text = tag..lplr.Name
            end
        end))
    end)
end)

local GuiLibrary = shared.GuiLibrary
shared.slowmode = 0
--[[run(function() 
    local function resetSlowmode()
        task.spawn(function()
            repeat shared.slowmode = shared.slowmode - 1 task.wait(1) until shared.slowmode < 1
            shared.slowmode = 0
        end)
    end
    local HS = game:GetService("HttpService")
    local StaffDetector = {}
    local StaffDetector_Games = {Value = "Bedwars"}
    local Custom_Group = {Enabled = false}
	local IgnoreOnlineStaff = {Enabled = false}
	local AutoCheck = {Enabled = false}
    local Roles_List = {ObjectList = {}}
    local Custom_GroupId = {Value = ""}
    local Staff_Members_Limit = {Value = 50}
    local Games_StaffTable = {
        ["Bedwars"] = {
            ["groupid"] = 5774246,
            ["roles"] = {
                79029254,
                86172137,
                43926962,
                37929139,
                87049509,
                37929138
            }
        },
		["PS99"] = {
			["groupid"] = 5060810,
			["roles"] = {
				33738740,
				33738765
			}
		}
    }
    local function getUsersInRole(groupId, roleId, cursor)
        local limit = Staff_Members_Limit.Value or 100
        local url = "https://groups.roblox.com/v1/groups/"..groupId.."/roles/"..roleId.."/users?limit="..limit
        if cursor then
            url = url .. "&cursor=" .. cursor
        end
    
        local response = request({
            Url = url,
            Method = "GET"
        })
    
        return game:GetService("HttpService"):JSONDecode(response.Body)
    end
    local function getUserPresence(userIds)
        local url = "https://presence.roblox.com/v1/presence/users"
        local requestBody = game:GetService("HttpService"):JSONEncode({userIds = userIds})
    
        local response = request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = requestBody
        })
        return game:GetService("HttpService"):JSONDecode(response.Body)
    end
    local function getUsersInRoleWithPresence(groupId, roleId)
        local users = {}
        local cursor = nil
        local userIds = {}
        repeat
            local data = getUsersInRole(groupId, roleId, cursor)
            for _, user in pairs(data.data) do
                table.insert(users, user)
                table.insert(userIds, user.userId)
            end
            cursor = data.nextPageCursor
        until not cursor
        local presenceData = getUserPresence(userIds)
        for _, user in pairs(users) do
            for _, presence in pairs(presenceData.userPresences) do
                if user.userId == presence.userId then
                    user.presenceType = presence.userPresenceType
                    user.lastLocation = presence.lastLocation
                    break
                end
            end
        end
        return users
    end
    local function getGroupRoles(groupId)
        local url = "https://groups.roblox.com/v1/groups/"..groupId.."/roles"
        local res = request({
            Url = url,
            Method = "GET"
        })
        if res.StatusCode == 200 then
            local roles = {}
            for i,v in pairs(HS:JSONDecode(res.Body).roles) do
                table.insert(roles, v.id)
            end
            return true, roles, nil
        else
            return false, nil, "Status Code isnt 200! "..res.StatusCode
        end
    end
    local function getData()
        if Custom_Group.Enabled then
            local suc1, custom_group_id, err1 = false, "", nil
            if Custom_GroupId.Value ~= "" then
                suc1 = true
                custom_group_id = tonumber(Custom_GroupId.Value)
            else 
                suc1 = false
                custom_group_id = nil
                err1 = "Custom GroupID not specified!" 
            end
            local suc2, roles, err2 = false, {}, nil
            if #Roles_List.ObjectList < 1 then
                suc2 = false
                roles = nil
                err2 = "Roles not specified!"
            else
                if suc1 then
                    local suc3, res, err3 = getGroupRoles(custom_group_id)
                    if suc3 then
                        suc2 = true
                        roles = res
                    else
                        err2 = err3
                    end
                end
            end
            return {suc1, custom_group_id, err1}, {suc2, roles, err2}, "Custom"
        else
            if StaffDetector_Games.Value ~= "" then
                local roles = Games_StaffTable[StaffDetector_Games.Value]["roles"]
                local groupid = Games_StaffTable[StaffDetector_Games.Value]["groupid"]
                return {true, groupid, nil}, {true, roles, nil}, "Normal"
            else
                return {false, nil, nil}, {false, nil, nil}, "Normal"
            end
        end
    end
    local core_table = {}
    local function handle_checks(groupid, roleid)
        local res = getUsersInRoleWithPresence(groupid, roleid)
        for _, user in pairs(res) do
            local presenceStatus = "Offline"
            if user.presenceType == 1 then
                presenceStatus = "Online"
            elseif user.presenceType == 2 then
                presenceStatus = "In Game"
            elseif user.presenceType == 3 then
                presenceStatus = "In Studio"
            end
			local function online()
				if IgnoreOnlineStaff.Enabled then
					if presenceStatus == "Online" then
						return true
					else
						return false
					end
				else
					return false
				end
			end
            if (presenceStatus == "In Game" or online()) then
                table.insert(core_table, {["UserID"] = user.userId, ["Username"] = user.username, ["Status"] = presenceStatus})
            end
            print("Username: " .. user.username .. " - UserID: " .. user.userId .. " - Status: " .. presenceStatus)
        end
    end
	local checked_data = {}
	StaffDetector = vape.Categories.Utility:CreateModule({
		Name = 'StaffDetector',
		Function = function(calling)
			if calling then 
				if (not AutoCheck.Enabled) then
					StaffDetector["ToggleButton"](false) 
				end
				if AutoCheck.Enabled then errorNotification("StaffDetector-AutoCheck", "Please disable auto check to manually use this module!", 5) end
                if shared.slowmode > 0 then if (not AutoCheck.Enabled) then return errorNotification("StaffDetector-Slowmode", "You are currently on slowmode! Wait "..tostring(shared.slowmode).."seconds!", shared.slowmode) end end
				shared.slowmode = 5
                resetSlowmode()
				InfoNotification("StaffDetector", "Sent request! Please wait...", 5)
				local function dostuff()
					local limit = Staff_Members_Limit.Value
					local tbl1, tbl2, Type = getData()
                    local suc1, res1, err1 = tbl1[1], tbl1[2], tbl1[3]
                    local suc2, res2, err2 = tbl2[1], tbl2[2], tbl2[3]    
					local handle_table = {}    
					local number = 0      
					if (suc1 and suc2) then
						for i,v in pairs(res2) do handle_checks(res1, v) end
						for i,v in pairs(core_table) do
							if (not table.find(handle_table, tostring(v["UserID"]))) then
								table.insert(handle_table, tostring(v["UserID"]))
								number = number + 1
                                local a, b, c = tostring(v["UserID"]), tostring(v["Username"]), tostring(v["Status"])
								local function checked()
									for i,v in pairs(checked_data) do
										if v["UserID"] == a then
											if v["Status"] == c then
												return true
											end
										end
									end
									return false
								end
								if checked() then return end
								table.insert(checked_data, {["UserID"] = a, ["Status"] = c})
								if tostring(v["Status"]) == "Online" then
									if (not IgnoreOnlineStaff.Enabled) then
										errorNotification("StaffDetector", "@"..b.."("..a..") is currently "..c, 7)
									end
								else
									errorNotification("StaffDetector", "@"..b.."("..a..") is currently "..c, 7)
								end
							end
						end
						InfoNotification("StaffDetector", tostring(number).." total staffs were detected as online/ingame!", 7)
					else
						shared.slowmode = 0
						if (not suc1) then
							errorNotification("StaffDetector-GroupID Error", tostring(err1), 5)
						end
						if (not suc2) then
							errorNotification("StaffDetector-Roles Error", tostring(err2), 5)
						end
					end
				end
				if (not AutoCheck.Enabled) then
					dostuff()
				else
					task.spawn(function()
						repeat 
							dostuff()
							task.wait(30)
						until (not StaffDetector.Enabled) or (not AutoCheck.Enabled)
						StaffDetector["ToggleButton"](false) 
					end)
				end
			end
		end
	}) 
    local list = {}
    for i,v in pairs(Games_StaffTable) do table.insert(list, i) end
    StaffDetector_Games = StaffDetector:CreateDropdown({
		Name = "GameChoice",
		Function = function() end,
		List = list
	})
    Roles_List = StaffDetector:CreateTextList({
		Name = "CustomRoles",
		TempText = "RoleId (number)"
	})
    Custom_GroupId = StaffDetector:CreateTextBox({
        Name = "CustomGroupId",
        TempText = "Type here a groupid",
        TempText = "GroupId (number)",
        Function = function() end
    })
    Custom_GroupId.Object.Visible = false
    Roles_List.Object.Visible = false
    Custom_Group = StaffDetector:CreateToggle({
		Name = "CustomGroup",
		Function = function(calling)
            if calling then
                Custom_GroupId.Object.Visible = true
                Roles_List.Object.Visible = true
                StaffDetector_Games.Object.Visible = false
            else
                Custom_GroupId.Object.Visible = false
                Roles_List.Object.Visible = false
                StaffDetector_Games.Object.Visible = true
            end
        end,
		Tooltip = "Choose another staff group",
		Default = false
	})
	IgnoreOnlineStaff = StaffDetector:CreateToggle({
		Name = "IgnoreOnlineStaff",
		Function = function() end,
		Tooltip = "Make the module ignore online staff and only \n show ingame staff",
		Default = false
	})
    Staff_Members_Limit = StaffDetector:CreateSlider({
		Name = "StaffMembersLimit",
		Min = 1,
		Max = 100,
		Function = function() end,
		Default = 100
	})
	AutoCheck = StaffDetector:CreateToggle({
		Name = "AutoCheck",
		Function = function() end,
		Tooltip = "Checks for new staffs every 30 seconds",
		Default = false
	}) --- work in progress
	task.spawn(function()
		repeat task.wait() until shared.vapewhitelist.loaded
		if shared.vapewhitelist:get(game:GetService("Players").LocalPlayer) ~= 2 then AutoCheck.Object.Visible = false end
	end)
end)--]]

run(function() 
	local ScytheFunny = {}
	ScytheFunny = vape.Categories.Blatant:CreateModule({
		Name = 'ScytheFunny',
		Function = function(calling)
			if calling then 
				repeat 
					task.wait()
					game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("SkyScytheSpin"):FireServer()
				until (not ScytheFunny.Enabled)
			end
		end
	}) 
end)

--[[run(function()
    local LeaderboardEditor = {Enabled = false}
    local RankIconTable = {["Emerald"] = "rbxassetid://12599231807",["Nightmare"] = "rbxassetid://7904292926",["Voidware"] = "rbxassetid://18518244636"}
    local AllowedMethods = {["Place"] = true,["Username"] = true,["RP"] = true}
    local AllowedEditMethods = {["Place"] = true,["Username"] = true,["RP"] = true, ["CrownIconColor"] = true, ["RankIcon"] = true, ["RankName"] = true}
    local ExtraFunctions = {extractUsername = function(richText) return richText:match("@</font></b>(.+)") end, extractNumberBeforeRP = function(text) return tonumber(text:match("<b>(%d+)%sRP</b>")) end, extractBoldText = function(text) return text:match("<b>(.-)</b>") end, resolvePlayerUserID = function(username) return game:GetService("Players"):GetUserIdFromNameAsync(username) end, resolveProfileImage = function(userid) return "rbxthumb://type=AvatarHeadShot&id="..tostring(userid).."&w=60&h=60" end, resolveUsername = function(username) return string.format('<b><font color="rgb(185, 188, 255)">@</font></b>%s', username) end, resolveNumberBeforeRP = function(number) return string.format('<b>%d RP</b>', number) end, resolveBoldText = function(text) return string.format('<b>%s</b>', text) end, resolveIconID = function(iconName) return RankIconTable[iconName] end, fetchDefaultTable = function() return {Place = nil, CrownIcon = nil, User = {Name = nil, Profile = nil}, Rank = {Name = nil, Icon = nil, RP = nil}} end}
    local function getBoard()
        --assert(game.game.Workspace:findFirstChild("Lobby") and game.game.Workspace:findFirstChild("Lobby").ClassName == "Folder", "Error finding Lobby folder in game.Workspace!")
        local suc, Leaderboard, Statboard = false, "Not found", "Not found"
        for i,v in pairs(game.game.Workspace:WaitForChild("Lobby"):GetChildren()) do
            if v.Name == "Podium" and v.ClassName == "Model" and v:FindFirstChild("Boards") then
                if v:FindFirstChild("Boards").ClassName == "Folder" then
                    suc = true
                    Leaderboard = v:findFirstChild("Boards"):FindFirstChild("Leaderboard") or "Not found"
                    Statboard = v:findFirstChild("Boards"):FindFirstChild("Statboard") or "Not found"
                end
            end
        end
        return {Status = suc, Response = {Leaderboard = Leaderboard, Statboard = Statboard}}
    end
    local function findChild(name, className, children)
        for i,v in pairs(children) do if v.Name == name and v.ClassName == className then return v end end
        local args = {Name = tostring(name), ClassName == tostring(className), Children = children}
        warn("[findChild]: CHILD NOT FOUND! Args: ", game:GetService("HttpService"):JSONEncode(args), name, className, children)
        return nil
    end
    local function getLeaderboardFrame(Leaderboard)
        local board = findChild("Board", "Part", Leaderboard:GetChildren())
        if board then
            local leaderboardApp = findChild("LeaderboardApp", "SurfaceGui", board:GetChildren())
            if leaderboardApp then
                local frame_1 = findChild("1", "Frame", leaderboardApp:GetChildren())
                if frame_1 then
                    local frame_1_1 = findChild("1", "Frame", frame_1:GetChildren())
                    if frame_1_1 then
                        local frame_2 = findChild("2", "Frame", frame_1_1:GetChildren())
                        if frame_2 then
                            local AutoCanvasScrollingFrame = findChild("AutoCanvasScrollingFrame", "ScrollingFrame", frame_2:GetChildren())
                            if AutoCanvasScrollingFrame then return AutoCanvasScrollingFrame end
                        end
                    end
                end
            end
        end
    end
    local function resolveLeaderboardChildData(child)
        local leaderboard_data = ExtraFunctions.fetchDefaultTable()
        local leaderboard_editor = ExtraFunctions.fetchDefaultTable()
        local PlayerContainer, StatValuesContainer, CrownIcon = findChild("PlayerContainer", "Frame", child:GetChildren()), findChild("StatValuesContainer", "Frame", child:GetChildren()), findChild("CrownIcon", "ImageLabel", child.Parent:GetChildren())
        if PlayerContainer then
            local LeaderboardRank, PlayerUsername, PlayerAvatar = findChild("LeaderboardRank", "TextLabel", PlayerContainer:GetChildren()), findChild("PlayerUsername", "TextLabel", PlayerContainer:GetChildren()), findChild("PlayerAvatar", "ImageLabel", PlayerContainer:GetChildren())
            if LeaderboardRank then leaderboard_data.Place = tonumber(LeaderboardRank.Text); leaderboard_editor.Place = LeaderboardRank end
            if PlayerUsername then leaderboard_data.User.Name = ExtraFunctions.extractUsername(PlayerUsername.Text); leaderboard_editor.User.Name = PlayerUsername end
            if PlayerAvatar then leaderboard_data.User.Profile = PlayerAvatar.Image; leaderboard_editor.User.Profile = PlayerAvatar end
        end 
        if StatValuesContainer then
            local StatValue, frame_2 = findChild("StatValue", "TextLabel", StatValuesContainer:GetChildren()), findChild("2", "Frame", StatValuesContainer:GetChildren())
            if StatValue then leaderboard_data.Rank.RP = ExtraFunctions.extractNumberBeforeRP(StatValue.Text); leaderboard_editor.Rank.RP = StatValue end
            if frame_2 then
                local image_2, text_3 = findChild("2", "ImageLabel", frame_2:GetChildren()), findChild("3", "TextLabel", frame_2:GetChildren())
                if image_2 then leaderboard_data.Rank.Icon = image_2.Image; leaderboard_editor.Rank.Icon = image_2 end
                if text_3 then leaderboard_data.Rank.Name = ExtraFunctions.extractBoldText(text_3.Text); leaderboard_editor.Rank.Name = text_3 end
            end
        end
        if CrownIcon then leaderboard_data.CrownIcon = CrownIcon.Image; leaderboard_editor.CrownIcon = CrownIcon end
        return {data = leaderboard_data, editor = leaderboard_editor}
    end
    local function checkResolveResponseOfLeaderboard(methodType, methodArg, res)
        local editor = res.editor
        local MethodTypeMethods = {["Place"] = function(full) return ExtraFunctions.extractBoldText(editor.Place.Text) end,["Username"] = function(full) return ExtraFunctions.extractUsername(editor.User.Name.Text) end,["RP"] = function(full) return ExtraFunctions.extractNumberBeforeRP(editor.Rank.RP.Text) end}
        local a = MethodTypeMethods[methodType](res.editor)
        if a == methodArg or a == tostring(methodArg) or a == tonumber(methodArg) then return true, res else return false, nil end
    end
    local function getResolveResponseOfLeaderboard(leaderboard_frame, methodType, methodArg) 
        if leaderboard_frame then
            for i,v in pairs(leaderboard_frame:GetChildren()) do
                local LeaderboardElementBody = findChild("LeaderboardElementBody", "Frame", v:GetChildren())
                if LeaderboardElementBody then
                    local UserLeaderBoardDataContainer = findChild("UserLeaderBoardDataContainer", "Frame", LeaderboardElementBody:GetChildren()) 
                    if UserLeaderBoardDataContainer then
                        --return resolveLeaderboardChildData(UserLeaderBoardDataContainer)
                        local suc, res = checkResolveResponseOfLeaderboard(methodType, methodArg, resolveLeaderboardChildData(UserLeaderBoardDataContainer))
                        if suc then return res end
                    end
                end
            end
            warn("ERROR FINDING PROPER CHILD!")
            return nil
        else
            warn("Failure getting leaderboard frame!")
        end
    end
    local function getLeaderboardChild(methodType, methodArg, leaderboard) if AllowedMethods[methodType] then return getResolveResponseOfLeaderboard(getLeaderboardFrame(leaderboard), methodType, methodArg) else return false end end
    local function resolveEditArgs(editArgs, editor)
        local resolveTable = {Place = editor.Place, Username = editor.User.Name, ProfileImage = editor.User.Profile, RankName = editor.Rank.Name, RP = editor.Rank.RP, RankIcon = editor.Rank.Icon, CrownIcon = editor.CrownIcon}
        local function handleEditResolve(editName, editArg)
            if resolveTable[editName] then
                if editName == "Place" then resolveTable[editName].Text = ExtraFunctions.resolveBoldText(editArg);
                elseif editName == "Username" then resolveTable[editName].Text = ExtraFunctions.resolveUsername(editArg);
                elseif editName == "ProfileImage" then resolveTable[editName].Image = ExtraFunctions.resolveProfileImage(ExtraFunctions.resolvePlayerUserID(editArg));
                elseif editName == "RankName" then resolveTable[editName].Text = ExtraFunctions.resolveBoldText(editArg);
                elseif editName == "RP" then resolveTable[editName].Text = ExtraFunctions.resolveNumberBeforeRP(editArg);
                elseif editName == "RankIcon" then resolveTable[editName].Image = ExtraFunctions.resolveIconID(editArg);
                elseif editName == "CrownIcon" and resolveTable[editName] then resolveTable[editName].ImageColor3 = editArg end
            end
        end
        for i,v in pairs(editArgs) do handleEditResolve(i, v) end
    end
    local function EditLeaderboard(methodType, methodArg, editArgs)
        local res = getBoard()
        local status, response = res.Status, res.Response
        if status == true then
            local Leaderboard, Statboard = response.Leaderboard, response.Statboard
            local resolve = getLeaderboardChild(methodType, methodArg, Leaderboard)
            local editor
            if resolve then editor = resolve.editor end
            if editor then resolveEditArgs(editArgs, editor) else warn("NO EDITOR FOUND!") end
        end
    end
    local function msend(mes, dur)
        warningNotification("LeaderboardEditor", mes, dur or 5)
    end

    local LeaderboardEditor_Types = {}
    local LeaderboardEditor_Editors = {}

    local Leaderboard_AddOnCreator_Helper = {}

    local function fetchToggleObjectData(name)
        local a = "LeaderboardEditor"..name.."Toggle"
        local b = shared.GuiLibrary.ObjectsThatCanBeSaved[a] or {Api = {Enabled = false}}
        return b.Api
    end

    local function fetchValidEditArgs()
        local validated = {Place = LeaderboardEditor_Editors["Place"][Leaderboard_AddOnCreator_Helper["Place"].ResType]}
        for i,v in pairs(LeaderboardEditor_Editors) do
            --print(fetchToggleObjectData(i).Enabled)
            if fetchToggleObjectData(i).Enabled == true then
                --print("[1]", i)
                if i == "Username" then
                    validated[i] = v[Leaderboard_AddOnCreator_Helper[i].ResType]
                    validated["ProfileImage"] = v[Leaderboard_AddOnCreator_Helper[i].ResType]
                elseif i == "CrownIconColor" then
                    validated[i] = Color3.new(v.Hue, v.Sat, v.Value)
                else
                    validated[i] = v[Leaderboard_AddOnCreator_Helper[i].ResType]
                end
            --else
              --  print("[2]", i)
            end
        end
        --print(game:GetService("HttpService"):JSONEncode(validated))
        return validated
    end

    local function fetchObjectData(name)
        local function convertText(input) return input:gsub("^Create", "") end
        local a = "LeaderboardEditor"..name..convertText(Leaderboard_AddOnCreator_Helper[name].Type)
        if Leaderboard_AddOnCreator_Helper[name].Type == "ColorSlider" then a = a.."Color" end
        return shared.GuiLibrary.ObjectsThatCanBeSaved[a]
    end

    local function checkAddOns()
        for i,v in pairs(LeaderboardEditor_Editors) do if i ~= "Place" then  fetchObjectData(i).Object.Visible = false end end
        for i,v in pairs(LeaderboardEditor_Types) do if fetchToggleObjectData(i).Enabled == true then fetchObjectData(i).Object.Visible = true end end
    end

    LeaderboardEditor = vape.Categories.Utility:CreateModule({
        Name = "LeaderboardEditor",
        Function = function(call)
            checkAddOns()
            if call then
                EditLeaderboard("Place", LeaderboardEditor_Editors.Place[Leaderboard_AddOnCreator_Helper["Place"].ResType], fetchValidEditArgs())
                getgenv().EditLeaderboard = EditLeaderboard
                msend("Hello")
            else
                getgenv().EditLeaderboard = nil
            end
        end
    })
    local function fetchDefaultFunction(call) if call then LeaderboardEditor.Restart() end end
    local function fetchRankIconNames() local iconNames = {}; for i,v in pairs(RankIconTable) do table.insert(iconNames, i) end; return iconNames end

    local function registerType(typeName)
        if typeName == "Place" then LeaderboardEditor_Editors["Place"] = {Value = 1}; Leaderboard_AddOnCreator_Helper["Place"] = {Type = "CreateTextBox", Args = {Name = "Place", TempText = "PlaceNumber", Function = fetchDefaultFunction}, ResType = "Value"}; 
        elseif typeName == "Username" then LeaderboardEditor_Editors["Username"] = {Value = game:GetService("Players").LocalPlayer.Name}; Leaderboard_AddOnCreator_Helper["Username"] = {Type = "CreateTextBox", Args = {Name = "Username", TempText = "username", Function = fetchDefaultFunction}, ResType = "Value"};
        elseif typeName == "RP" then LeaderboardEditor_Editors["RP"] = {Value = 9999}; Leaderboard_AddOnCreator_Helper["RP"] = {Type = "CreateTextBox", Args = {Name = "RP", TempText = "RP (number)", Function = fetchDefaultFunction}, ResType = "Value"}; 
        elseif typeName == "RankIcon" then LeaderboardEditor_Editors["RankIcon"] = {Value = "Voidware"}; Leaderboard_AddOnCreator_Helper["RankIcon"] = {Type = "CreateDropdown", Args = {Name = "RankIcon", List = fetchRankIconNames(), Function = fetchDefaultFunction}, ResType = "Value"};
        elseif typeName == "RankName" then LeaderboardEditor_Editors["RankName"] = {Value = "INFINITY"}; Leaderboard_AddOnCreator_Helper["RankName"] = {Type = "CreateTextBox", Args = {Name = "RankName", TempText = "rankname", Function = fetchDefaultFunction}, ResType = "Value"};
        elseif typeName == "CrownIconColor" then LeaderboardEditor_Editors["CrownIconColor"] = {Hue = 255, Sat = 0, Value = 0}; Leaderboard_AddOnCreator_Helper["CrownIconColor"] = {Type = "CreateColorSlider", Args = {Name = "CrownIconColor", Function = fetchDefaultFunction}, ResType = {"Hue", "Sat", "Value"}}
        else warn("Unknown registerType!", typeName) end
    end

    for i,v in pairs(AllowedEditMethods) do LeaderboardEditor_Types[i] = {Enabled = false}; registerType(i) end

    for i,v in pairs(LeaderboardEditor_Editors) do v = LeaderboardEditor[Leaderboard_AddOnCreator_Helper[i].Type](Leaderboard_AddOnCreator_Helper[i].Args) end
    for i,v in pairs(LeaderboardEditor_Types) do if i ~= "Place" then v = LeaderboardEditor:CreateToggle({Name = i, Function = function(call) fetchObjectData(i).Object.Visible = call end}) end end

    checkAddOns()
end)--]]

local ReportDetector_Cooldown = 0
run(function()
    local ReportDetector = {Enabled = false}
    local HttpService = game:GetService("HttpService")
    local ReportDetector_GUIObjects = {}
    local ReportDetector_Connections = {}

    local function fetchReports(username)
        if not username then return {Suc = false, Error = "Username not specified!"} end
        local url = 'https://detections.vapevoidware.xyz/reportdetector?user=' .. tostring(username)
        local res = request({Url = url, Method = "GET"})

        if res and res.StatusCode == 200 then
            return {Suc = true, Data = res.Body}
        else
            return {Suc = false, Error = "HTTP Error: " .. tostring(res.StatusCode) .. " | " .. tostring(res.Body), StatusCode = res.StatusCode, Body = res.Body}
        end
    end

    local function resolveData(data)
        if not data then return {Suc = false, Error = "No data to resolve"} end
        local suc, decodedData = pcall(function() return HttpService:JSONDecode(data) end)
        if not suc then return {Suc = false, Error = "Failed to decode JSON"} end

        local resolvedReports = {}
        for _, guildData in pairs(decodedData) do
            if guildData.guild_id and guildData.Reports then
                for reportID, report in pairs(guildData.Reports) do
                    table.insert(resolvedReports, {
                        Message = report.content or "No message",
                        AuthorData = {
                            UserID = report.author.id or "Unknown",
                            Username = report.author.username or "Unknown",
                            ReporterHashNumber = report.author.discriminator or "Unknown"
                        },
                        ChannelID = report.channel.id or "Unknown",
                        GuildID = guildData.guild_id
                    })
                end
            end
        end
        return {Suc = true, ResolvedReports = resolvedReports}
    end

    local function convertData(data)
        local convertedData = {}
        for i, v in ipairs(data) do
            table.insert(convertedData, {
                ReportNumber = tostring(i),
                TotalReports = tostring(#data),
                Notifications = {
                    {Title = "ReportInfo - Message/Sender", Message = "[Sender:" .. v.AuthorData.Username .. "#" .. v.AuthorData.ReporterHashNumber .. "] - [Message:" .. v.Message .. "]           ", Duration = 7},
                    {Title = "ReportInfo - ServerInfo", Message = "[ServerID:" .. v.GuildID .. "] - [ChannelID:" .. v.ChannelID .. "]           ", Duration = 7}
                }
            })
        end
        return convertedData
    end

    local function handleError(res)
        local ErrorHandling = {
            ["404"] = "Critical error in the API endpoint!",
            ["400"] = "No username specified! Contact erchodev#0 on discord.",
            ["500"] = "Critical server error! Try again later.",
            ["429"] = "You are being rate-limited. Please wait."
        }
        local message = ErrorHandling[tostring(res.StatusCode)] or "Unknown error! StatusCode: " .. tostring(res.StatusCode)
        errorNotification("ReportDetector_ErrorHandler ["..tostring(res.StatusCode).."]", message, 10)
    end

    local function getPlayers()
        local plrs = {}
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            table.insert(plrs, player.Name)
        end
        return plrs
    end

    local function createGUIElement(api, argsTbl)
        local name = argsTbl.GUI_Name
        local creationType = argsTbl.GUI_Args.Type
        local creationArgs = argsTbl.GUI_Args.Creation_Args

        ReportDetector_GUIObjects[name] = api[creationType](creationType, creationArgs)
    end

	local function getObject(name)
		return ReportDetector_GUIObjects[name] and ReportDetector_GUIObjects[name].Object
	end

    local Methods_Functions = {
        ["Self"] = function() getObject("ServerUsername").Visible = false; getObject("CustomUsername").Visible = false end,
        ["Server"] = function() getObject("ServerUsername").Visible = true; getObject("CustomUsername").Visible = false end,
        ["Global"] = function() getObject("ServerUsername").Visible = false; getObject("CustomUsername").Visible = true end,
    }

	local function getUsername()
		local CorresponderTable = {
			["Self"] = nil,
			["Server"] = "ServerUsername",
			["Global"] = "CustomUsername"
		}
		local val = ReportDetector_GUIObjects["Mode"].Value
		local function verifyVal(value) if value ~= nil and value ~= "" then return true, value else return false, value end end
		if val ~= "Self" then 
			local suc, res = verifyVal(ReportDetector_GUIObjects[CorresponderTable[val]].Value)
			if suc then return res else return nil, {Step = 1, ErrorInfo = "Invalid value!", Debug = {Type = val, Res = tostring(res)}} end
		else
			return game:GetService("Players").LocalPlayer.Name
		end
	end

	ReportDetector = vape.Categories.Utility:CreateModule({
		Name = "ReportDetector",
		Function = function(call)
			if call then
				ReportDetector:Toggle(false)
				local targetUsername, errorInfo = getUsername()
				if (not targetUsername) then return errorNotification("ReportDetector_ErrorHandler_V2", game:GetService("HttpService"):JSONEncode(errorInfo), 10) end
				warningNotification("ReportDetector", "Request sent to VW API for user: "..tostring(targetUsername).."!           ", 3)
				local res = fetchReports(targetUsername)
				if res.Suc then
					local resolvedData = resolveData(res.Data)
					if resolvedData.Suc then
						local convertedData = convertData(resolvedData.ResolvedReports)
                        local saveTable = {}
						for _, report in ipairs(convertedData) do
							for _, notification in ipairs(report.Notifications) do
                                saveTable["[Report #" .. report.ReportNumber .. "/" .. report.TotalReports .. "]"] = saveTable["[Report #" .. report.ReportNumber .. "/" .. report.TotalReports .. "]"] or {}
                                table.insert(saveTable["[Report #" .. report.ReportNumber .. "/" .. report.TotalReports .. "]"], {
                                    Title = notification.Title,
                                    Message = notification.Message
                                })
								warningNotification("[Report #" .. report.ReportNumber .. "/" .. report.TotalReports .. "] " .. notification.Title, notification.Message, notification.Duration)
							end
						end
						if #convertedData < 1 then warningNotification("ReportDetector", "No reports found for " .. targetUsername .. "!", 10) end
                        writefile("ReportDetectorLog.json", game:GetService("HttpService"):JSONEncode(saveTable))
                        warningNotification("ReportDetector_LogSaver", "Successfully saved the report logs to ReportDetectorLog.json in your \n executor's game.Workspace folder!", 10)
					else
						errorNotification("ReportDetector", "Data sorting failed: " .. resolvedData.Error, 10)
					end
				else
					handleError(res)
					errorNotification("ReportDetector", "Failed to fetch reports: " .. res.Error, 10)
				end
			end
		end,
		Tooltip = "Detects if anyone has reported you."
	})
	local GUI_Elements = {
		{GUI_Name = "Mode", GUI_Args = {Type = "CreateDropdown", Arg = {Value = "Self"}, Creation_Args = {Name = "Mode", List = {"Self", "Server", "Global"}, Function = function(val) Methods_Functions[val]() end}}},
		{GUI_Name = "ServerUsername", GUI_Args = {Type = "CreateDropdown", Arg = {Value = game:GetService("Players").LocalPlayer.Name}, Creation_Args = {Name = "Players", List = getPlayers(), Function = function() end}}},
		{GUI_Name = "CustomUsername", GUI_Args = {Type = "CreateTextBox", Arg = {Value = game:GetService("Players").LocalPlayer.Name}, Creation_Args = {Name = "Username", TempText = "Type here a username", Function = function() end}}}
	}

	for _, element in ipairs(GUI_Elements) do
		createGUIElement(ReportDetector, element)
	end
end)

--[[run(function()
	local PlayerChanger = {Enabled = false}
	if GuiLibrary.ObjectsThatCanBeSaved["PlayerChangerOptionsButton"] then
		PlayerChanger = GuiLibrary.ObjectsThatCanBeSaved["PlayerChangerOptionsButton"]
		local API = PlayerChanger.Api
		local PlayerChanger_Functions = shared.PlayerChanger_Functions
		local PlayerName = {Value = "Nigger"}
		PlayerName = API:CreateTextBox({
			Name = "Player Name",
			TempText = "Type here a name",
			Function = function(val)
				if GuiLibrary.ObjectsThatCanBeSaved["PlayerChangerOptionsButton"].Api.Enabled then
					local targetUser = shared.PlayerChanger_GUI_Elements_PlayersDropdown_Value
					local plr = PlayerChanger_Functions.getPlayerFromUsername(targetUser)
					if plr then
						local char = PlayerChanger_Functions.getPlayerCharacter(plr)
						if char then
                            local displayName = char:WaitForChild("Head"):WaitForChild("Nametag"):WaitForChild("DisplayNameContainer"):WaitForChild("DisplayName")
                            if displayName.ClassName == "TextLabel" then
                                if not displayName.RichText then displayName.RichText = true end
                                displayName.Text = val
                            end
                            table.insert(vapeConnections, displayName:GetPropertyChangedSignal("Text"):Connect(function()
                                if displayName.Text ~= val and targetUser == shared.PlayerChanger_GUI_Elements_PlayersDropdown_Value then
                                    displayName.Text = val
                                end
                            end))
						else warn("Error fetching player CHARACTER! Player: "..tostring(targetUser).." Character Result: "..tostring(char)) end
					else warn("Error fetching player! Player: "..tostring(targetUser)) end
				end
			end
		})
	else warn("PlayerChangerOptionsButton NOT found!") end
end)--]]

run(function()
	local cheat = {57,84,142,96,195,198,254,218,104,79,208,20,197,34,10,112,20,53,226,37,133,215,119,171,130,96,107,239,245,109,145,250}
	if shared.EGGHUNTCHATTINGCONNECTION then
		pcall(function() shared.EGGHUNTCHATTINGCONNECTION:Disconnect() end)
	end
	shared.EGGHUNTCHATTINGCONNECTION = lplr.Chatted:Connect(function(msg)
		if (msg:split(" "))[1] == "/eggclaim" then
			game:GetService("ReplicatedStorage").rbxts_include.node_modules["@rbxts"].net.out._NetManaged.EggHunt2025_CheatcodeActivatedFromClient:FireServer({
				hash = cheat
			})
			game:GetService('StarterGui'):SetCore('SendNotification', {
				Title = 'Voidware',
				Text = 'Successfully claimed the Cheatcode Egg!',
				Duration = 10,
			})
			pcall(function() shared.EGGHUNTCHATTINGCONNECTION:Disconnect() end)
		end
	end)
end)

--[[run(function()
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 500)
    mainFrame.Position = UDim2.new(1, 0, 0.8, -250)
    mainFrame.AnchorPoint = Vector2.new(0, 0.5) 
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = shared.vape.gui.ScaledGui
    shared.GuiLibrary.SelfDestructEvent.Event:Connect(function()
        mainFrame:Destroy()
    end)
    
    local groupId = 5774246
    local roleIds = {
        79029254,
        86172137,
        43926962,
        37929139,
        87049509,
        37929138
    }
    
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
    scrollingFrame.ScrollBarThickness = 5
    scrollingFrame.BackgroundTransparency = 1 
    scrollingFrame.Parent = mainFrame
    
    local function createUICorner(instance, radius)
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, radius)
        uiCorner.Parent = instance
    end
    
    local tweenService = game:GetService("TweenService")
    local function fadeOut(frame)
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = tweenService:Create(frame, tweenInfo, {Transparency = 1, Position = frame.Position + UDim2.new(0, 100, 0, 0)})
        tween:Play()
        tween.Completed:Connect(function() frame:Destroy() end)
    end
    
    local function fadeIn(frame)
        frame.Transparency = 1
        frame.Position = frame.Position - UDim2.new(0, 100, 0, 0)
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = tweenService:Create(frame, tweenInfo, {Position = frame.Position + UDim2.new(0, 100, 0, 0)})
        tween:Play()
    end
    
    local function updateUsers(users)
        for _, child in pairs(scrollingFrame:GetChildren()) do
            if child:IsA("Frame") then
                fadeOut(child)
            end
        end
    
        for index, user in ipairs(users) do
            local userFrame = Instance.new("Frame")
            userFrame.Size = UDim2.new(1, -10, 0, 50)
            userFrame.Position = UDim2.new(0, 5, 0, (index - 1) * 55) 
            userFrame.BackgroundTransparency = 1
            userFrame.Parent = scrollingFrame
    
            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(0, 40, 0, 40)
            avatar.Position = UDim2.new(0, 5, 0, 5)
            avatar.Image = "rbxthumb://type=AvatarHeadShot&id="..user.userId.."&w=420&h=420"
            avatar.Parent = userFrame
            avatar.BackgroundTransparency = 1
    
            createUICorner(avatar, 40)
    
            local statusIndicator = Instance.new("Frame")
            statusIndicator.Size = UDim2.new(0, 10, 0, 10)
            statusIndicator.Position = UDim2.new(1, -10, 1, -10)
            statusIndicator.BackgroundColor3 = user.StatusColor
            statusIndicator.BorderSizePixel = 2
            statusIndicator.BorderColor3 = Color3.fromRGB(255, 255, 255)
            statusIndicator.Parent = avatar
    
            createUICorner(statusIndicator, 10)
    
            local userInfo = Instance.new("TextLabel")
            userInfo.Size = UDim2.new(1, -60, 1, 0)
            userInfo.Position = UDim2.new(0, 55, 0, 0)
            userInfo.Text = tostring(user.displayName) .. "(@".. tostring(user.username) ..")\nStatus: "..tostring(user.StatusType).."    ID: " .. tostring(user.userId)
            userInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
            userInfo.TextXAlignment = Enum.TextXAlignment.Left
            userInfo.TextYAlignment = Enum.TextYAlignment.Center
            userInfo.Font = Enum.Font.ArialBold
            userInfo.TextSize = 14
            userInfo.Parent = userFrame
            userInfo.BackgroundTransparency = 1
    
            fadeIn(userFrame)
        end
    end
    
    local function getUsersInRole(groupId, roleId, cursor)
        local limit = 100
        local url = "https://groups.roblox.com/v1/groups/"..groupId.."/roles/"..roleId.."/users?limit="..limit
        if cursor then
            url = url .. "&cursor=" .. cursor
        end
    
        local response = request({
            Url = url,
            Method = "GET"
        })
    
        return game:GetService("HttpService"):JSONDecode(response.Body)
    end
    
    local function getUserPresence(userIds)
        local url = "https://presence.roblox.com/v1/presence/users"
        local requestBody = game:GetService("HttpService"):JSONEncode({userIds = userIds})
    
        local response = request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = requestBody
        })
        return game:GetService("HttpService"):JSONDecode(response.Body)
    end
    
    local function getUsersForRolesWithPresence(groupId, roleIds)
        local users = {}
        local userIds = {}
        for _, roleId in pairs(roleIds) do
            local cursor = nil
            repeat
                local data = getUsersInRole(groupId, roleId, cursor)
                for _, user in pairs(data.data) do
                    table.insert(users, user)
                    table.insert(userIds, user.userId)
                end
                cursor = data.nextPageCursor
            until not cursor
        end
    
        local presenceData = getUserPresence(userIds)
        for _, user in pairs(users) do
            for _, presence in pairs(presenceData.userPresences) do
                if user.userId == presence.userId then
                    user.presenceType = presence.userPresenceType
                    user.lastLocation = presence.lastLocation
                    break
                end
            end
        end
        return users
    end
    
    local function filterUsersByPresence(users, presenceType)
        local filteredUsers = {}
        for _, user in pairs(users) do
            if user.presenceType == presenceType then
                table.insert(filteredUsers, user)
            end
        end
        updateUsers(filteredUsers)
    end
    
    local function getUsersForRolesPresence(groupId, roleIds)
        local users = getUsersForRolesWithPresence(groupId, roleIds)
    
        local StatusTypes = {
            ["0"] = "Offline",
            ["1"] = "Online",
            ["2"] = "InGame"
        }
        
        for _, user in pairs(users) do
            local statusColor = Color3.fromRGB(0, 255, 0)
            if user.presenceType == 0 then
                statusColor = Color3.fromRGB(255, 0, 0)
            elseif user.presenceType == 2 then
                statusColor = Color3.fromRGB(0, 0, 255)
            end
            user.StatusColor = statusColor
            user.StatusType = StatusTypes[tostring(user.presenceType)]
        end
        updateUsers(users)
    end
    
    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0, 80, 0, 30)
    refreshButton.Position = UDim2.new(0.5, -40, 0, -40)
    refreshButton.Text = "Refresh"
    refreshButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.Parent = mainFrame
    refreshButton.TextScaled = true
    refreshButton.BackgroundTransparency = 1
    refreshButton.MouseButton1Click:Connect(function()
        getUsersForRolesPresence(groupId, roleIds)
    end)
    getUsersForRolesPresence(groupId, roleIds)    
end)--]]

run(function()
    local anim
	local asset
	local lastPosition
    local NightmareEmote
	NightmareEmote = vape.Categories.World:CreateModule({
		Name = "NightmareEmote",
		Function = function(call)
			if call then
				local l__GameQueryUtil__8
				if (not shared.CheatEngineMode) then 
					l__GameQueryUtil__8 = require(game:GetService("ReplicatedStorage")['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil 
				else
					local backup = {}; function backup:setQueryIgnored() end; l__GameQueryUtil__8 = backup;
				end
				local l__TweenService__9 = game:GetService("TweenService")
				local player = game:GetService("Players").LocalPlayer
				local p6 = player.Character
				
				if not p6 then NightmareEmote:Toggle() return end
				
				local v10 = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("NightmareEmote"):Clone();
				asset = v10
				v10.Parent = game.Workspace
				lastPosition = p6.PrimaryPart and p6.PrimaryPart.Position or Vector3.new()
				
				task.spawn(function()
					while asset ~= nil do
						local currentPosition = p6.PrimaryPart and p6.PrimaryPart.Position
						if currentPosition and (currentPosition - lastPosition).Magnitude > 0.1 then
							asset:Destroy()
							asset = nil
							NightmareEmote:Toggle()
							break
						end
						lastPosition = currentPosition
						v10:SetPrimaryPartCFrame(p6.LowerTorso.CFrame + Vector3.new(0, -2, 0));
						task.wait()
					end
				end)
				
				local v11 = v10:GetDescendants();
				local function v12(p8)
					if p8:IsA("BasePart") then
						l__GameQueryUtil__8:setQueryIgnored(p8, true);
						p8.CanCollide = false;
						p8.Anchored = true;
					end;
				end;
				for v13, v14 in ipairs(v11) do
					v12(v14, v13 - 1, v11);
				end;
				local l__Outer__15 = v10:FindFirstChild("Outer");
				if l__Outer__15 then
					l__TweenService__9:Create(l__Outer__15, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = l__Outer__15.Orientation + Vector3.new(0, 360, 0)
					}):Play();
				end;
				local l__Middle__16 = v10:FindFirstChild("Middle");
				if l__Middle__16 then
					l__TweenService__9:Create(l__Middle__16, TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = l__Middle__16.Orientation + Vector3.new(0, -360, 0)
					}):Play();
				end;
                anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://9191822700"
				anim = p6.Humanoid:LoadAnimation(anim)
				anim:Play()
			else 
                if anim then 
					anim:Stop()
					anim = nil
				end
				if asset then
					asset:Destroy() 
					asset = nil
				end
			end
		end
	})
end)

shared.slowmode = 0
run(function()
    local HttpService = game:GetService("HttpService")
    local StaffDetectionSystem = {
        Enabled = false
    }
    local StaffDetectionSystemConfig = {
        GameMode = "Bedwars",
        CustomGroupEnabled = false,
        IgnoreOnline = false,
        AutoCheck = false,
        MemberLimit = 50,
        CustomGroupId = "",
        CustomRoles = {}
    }
    local StaffDetectionSystemStaffData = {
        Games = {
            Bedwars = {groupId = 5774246, roles = {79029254, 86172137, 43926962, 37929139, 87049509, 37929138}},
            PS99 = {groupId = 5060810, roles = {33738740, 33738765}}
        },
        Detected = {}
    }

    local DetectionUtils = {
        resetSlowmode = function() end,
        fetchUsersInRole = function() end,
        fetchUserPresence = function() end,
        fetchGroupRoles = function() end,
        getDetectionConfig = function() end,
        scanStaff = function() end
    }

    DetectionUtils = {
        resetSlowmode = function()
            task.spawn(function()
                while shared.slowmode > 0 do
                    shared.slowmode = shared.slowmode - 1
                    task.wait(1)
                end
                shared.slowmode = 0
            end)
        end,

        fetchUsersInRole = function(groupId, roleId, cursor)
            local url = string.format("https://groups.roblox.com/v1/groups/%d/roles/%d/users?limit=%d%s", groupId, roleId, StaffDetectionSystemConfig.MemberLimit, cursor and "&cursor=" .. cursor or "")
            local success, response = pcall(function()
                return request({Url = url, Method = "GET"})
            end)
            return success and HttpService:JSONDecode(response.Body) or {}
        end,

        fetchUserPresence = function(userIds)
            local success, response = pcall(function()
                return request({
                    Url = "https://presence.roblox.com/v1/presence/users",
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({userIds = userIds})
                })
            end)
            return success and HttpService:JSONDecode(response.Body) or {userPresences = {}}
        end,

        fetchGroupRoles = function(groupId)
            local success, response = pcall(function()
                return request({
                    Url = "https://groups.roblox.com/v1/groups/" .. groupId .. "/roles",
                    Method = "GET"
                })
            end)
            if success and response.StatusCode == 200 then
                local roles = {}
                for _, role in pairs(HttpService:JSONDecode(response.Body).roles) do
                    table.insert(roles, role.id)
                end
                return true, roles
            end
            return false, nil, "Failed to fetch roles: " .. (success and response.StatusCode or "Network error")
        end,

        getDetectionConfig = function()
            if StaffDetectionSystemConfig.CustomGroupEnabled then
                if not StaffDetectionSystemConfig.CustomGroupId or StaffDetectionSystemConfig.CustomGroupId == "" then
                    return false, nil, "Custom Group ID not specified", false, nil, "Custom"
                end
                if #StaffDetectionSystemConfig.CustomRoles == 0 then
                    return true, tonumber(StaffDetectionSystemConfig.CustomGroupId), nil, false, nil, "Custom roles not specified"
                end
                local success, roles, error = DetectionUtils.fetchGroupRoles(StaffDetectionSystemConfig.CustomGroupId)
                return true, tonumber(StaffDetectionSystemConfig.CustomGroupId), nil, success, roles, error, "Custom"
            else
                local gameData = StaffDetectionSystemStaffData.Games[StaffDetectionSystemConfig.GameMode]
                return true, gameData.groupId, nil, true, gameData.roles, nil, "Normal"
            end
        end,

        scanStaff = function(groupId, roleId)
            local users, userIds = {}, {}
            local cursor = nil
            repeat
                local data = DetectionUtils.fetchUsersInRole(groupId, roleId, cursor)
                for _, user in pairs(data.data or {}) do
                    table.insert(users, user)
                    table.insert(userIds, user.userId)
                end
                cursor = data.nextPageCursor
            until not cursor

            local presenceData = DetectionUtils.fetchUserPresence(userIds)
            for _, user in pairs(users) do
                for _, presence in pairs(presenceData.userPresences) do
                    if user.userId == presence.userId then
                        user.presenceType = presence.userPresenceType
                        user.lastLocation = presence.lastLocation
                        break
                    end
                end
            end
            return users
        end
    }

    local function processStaffCheck()
        if shared.slowmode > 0 and not StaffDetectionSystemConfig.AutoCheck then
            errorNotification("StaffDetector", "Slowmode active! Wait " .. shared.slowmode .. " seconds", shared.slowmode)
            return
        end

        shared.slowmode = 5
        DetectionUtils.resetSlowmode()
        InfoNotification("StaffDetector", "Checking staff presence...", 5)

        local groupSuccess, groupId, groupError, rolesSuccess, roles, rolesError, mode = DetectionUtils.getDetectionConfig()
        if not groupSuccess or not rolesSuccess then
            shared.slowmode = 0
            if groupError then errorNotification("StaffDetector", groupError, 5) end
            if rolesError then errorNotification("StaffDetector", rolesError, 5) end
            return
        end

        local detectedStaff, uniqueIds = {}, {}
        for _, roleId in pairs(roles) do
            for _, user in pairs(DetectionUtils.scanStaff(groupId, roleId)) do
				local resolve = {
					["Offline"] = '<font color="rgb(128,128,128)">Offline</font>',
					["Online"] = '<font color="rgb(0,255,0)">Online</font>',
					["In Game"] = '<font color="rgb(16, 150, 234)">In Game</font>',
					["In Studio"] = '<font color="rgb(255,165,0)">In Studio</font>'
				}
                local status = ({
                    [0] = "Offline",
                    [1] = "Online",
                    [2] = "In Game",
                    [3] = "In Studio"
                })[user.presenceType or 0]

                if (status == "In Game" or (not StaffDetectionSystemConfig.IgnoreOnline and status == "Online")) and
                   not table.find(uniqueIds, user.userId) then
                    table.insert(uniqueIds, user.userId)
                    local userData = {UserID = tostring(user.userId), Username = user.username, Status = status}
                    if not table.find(detectedStaff, userData) then
                        table.insert(detectedStaff, userData)
                        errorNotification("StaffDetector", "@" .. userData.Username .. "(" .. userData.UserID .. ") is " .. resolve[status], 7)
                    end
                end
            end
        end
        InfoNotification("StaffDetector", #detectedStaff .. " staff members detected online/in-game!", 7)
    end

    StaffDetectionSystem = vape.Categories.Utility:CreateModule({
        Name = 'StaffFetcher - Roblox',
        Function = function(enabled)
            StaffDetectionSystem.Enabled = enabled
            if enabled then
                if StaffDetectionSystemConfig.AutoCheck then
                    task.spawn(function()
                        repeat
                            processStaffCheck()
                            task.wait(30)
                        until not StaffDetectionSystem.Enabled or not StaffDetectionSystemConfig.AutoCheck
                        StaffDetectionSystem:Toggle(false)
                    end)
                else
                    processStaffCheck()
                    StaffDetectionSystem:Toggle(false)
                end
            end
        end
    })

    local StaffDetectionSystemUI = {}

    local gameList = {}
    for game in pairs(StaffDetectionSystemStaffData.Games) do table.insert(gameList, game) end
    StaffDetectionSystemUI.GameSelector = StaffDetectionSystem:CreateDropdown({
        Name = "Game Mode",
        Function = function(value) StaffDetectionSystemConfig.GameMode = value end,
        List = gameList
    })

    StaffDetectionSystemUI.RolesList = StaffDetectionSystem:CreateTextList({
        Name = "Custom Roles",
        TempText = "Role ID (number)",
        Function = function(values) StaffDetectionSystemConfig.CustomRoles = values end
    })

    StaffDetectionSystemUI.GroupIdInput = StaffDetectionSystem:CreateTextBox({
        Name = "Custom Group ID",
        TempText = "Group ID (number)",
        Function = function(value) StaffDetectionSystemConfig.CustomGroupId = value end
    })

    StaffDetectionSystem:CreateToggle({
        Name = "Custom Group",
        Function = function(enabled)
            StaffDetectionSystemConfig.CustomGroupEnabled = enabled
            StaffDetectionSystemUI.GroupIdInput.Object.Visible = enabled
            StaffDetectionSystemUI.RolesList.Object.Visible = enabled
            StaffDetectionSystemUI.GameSelector.Object.Visible = not enabled
        end,
        Tooltip = "Use a custom staff group",
        Default = false
    })

    StaffDetectionSystem:CreateToggle({
        Name = "Ignore Online Staff",
        Function = function(enabled) StaffDetectionSystemConfig.IgnoreOnline = enabled end,
        Tooltip = "Only show in-game staff, ignoring online staff",
        Default = false
    })

    StaffDetectionSystem:CreateSlider({
        Name = "Member Limit",
        Min = 1,
        Max = 100,
        Function = function(value) StaffDetectionSystemConfig.MemberLimit = value end,
        Default = 50
    })

    StaffDetectionSystem:CreateToggle({
        Name = "Auto Check",
        Function = function(enabled)
            StaffDetectionSystemConfig.AutoCheck = enabled
            if enabled and shared.slowmode > 0 then
                errorNotification("StaffDetector", "Disable Auto Check to use manually during slowmode!", 5)
            end
        end,
        Tooltip = "Automatically check every 30 seconds",
        Default = false
    })

    StaffDetectionSystemUI.GroupIdInput.Object.Visible = false
    StaffDetectionSystemUI.RolesList.Object.Visible = false
end)