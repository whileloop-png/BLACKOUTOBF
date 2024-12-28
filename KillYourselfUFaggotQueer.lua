--//variables
local CURRENTVERSION = '1.0.0'
local distance = 4
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local SilentSettings = { Main = { Enabled = false, TeamCheck = false, VisibleCheck = false, TargetPart = "Head" }, FOVSettings = { Visible = false, Radius = 360 }, SilentAimColor = Color3.fromRGB(255, 255, 255)};
local ValidTargetParts = {"Head", "Torso"};

local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua'))()
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua'))()

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local events = game:GetService("ReplicatedStorage").Events.Loot.LootObject
local minigame = game:GetService("ReplicatedStorage").Events.Loot.MinigameResult
local playerGui = player:FindFirstChild("PlayerGui")
local debrisfolder = workspace:WaitForChild("Debris")
local LOOTBAGFOLDER = debrisfolder:WaitForChild("Loot")

local resetframe = game:GetService("Players").LocalPlayer.PlayerGui.MainStaticGui.ResetFrame
local TweenInfo_new_result1_upvr_5 = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local TweenInfo_new_result1_upvr_3 = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local tweenservice = game:GetService("TweenService")

local Mouse = player:GetMouse()
local Cam = workspace.CurrentCamera

--//boolvalues
local unlockActive = false
local autoLootActive = false
local killauraBoolValue = false
local fovActive = false
local bashautomatically = false
local blackoutFlyEnabled = false
local flykeyPressed = false
local FLYING = false
local isPerformanceModeEnabled = false -- Tracks the state of performance mode
local instantInteract = false
local isKeycardFinderEnabled = false
local cleanupDone = false
local isnoclipon = false
local hasSetTorsoCollision = false

--//numbervalues
local unlockCooldown = 0 -- Default cooldown for unlock (seconds)
local lootCooldown = 0 -- Default cooldown for loot (seconds)
local Fov = 90

--//tables
local unlockedObjects = {} -- Tracks objects already unlocked
local lootedObjects = {} -- Tracks objects already looted
local defaults = {
    Objects = {}, -- Stores references to the objects you want to modify
    Lighting = {
        Effects = {}, -- Stores references to lighting effects
    }
}

local hookedTorso
local mt = getrawmetatable(game)
local oldNewIndex = mt.__newindex



game:GetService("Players").LocalPlayer.PlayerGui.MainStaticGui.StaticCore.Sounds.GivingUp:Play()

local tween1 = tweenservice:Create(resetframe.Overlay, TweenInfo_new_result1_upvr_5, {
    ImageTransparency = 0;
})

local tween2 = tweenservice:Create(resetframe.ScreenEffect, TweenInfo_new_result1_upvr_3, {
    ImageTransparency = 0;
})
game:GetService("ReplicatedStorage").Notify:Fire("BOYKIZR PRESENTS...", "Warning", true)
tween1:Play()
tween2:Play()

tween1.Completed:Wait()
tween2.Completed:Wait()

game:GetService("ReplicatedStorage").Notify:Fire("BOYKIZR PRESENTS...", "Notification", false)
-- After both tweens are done, tween them back to transparency 1
tweenservice:Create(resetframe.Overlay, TweenInfo_new_result1_upvr_5, {
    ImageTransparency = 1;
}):Play()

tweenservice:Create(resetframe.ScreenEffect, TweenInfo_new_result1_upvr_3, {
    ImageTransparency = 1;
}):Play()



QEfly = true
iyflyspeed = 7
isBlackoutFly = false
local flyKeyDown, flyKeyUp
local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}


local WorldToScreen = Cam.WorldToScreenPoint
local WorldToViewportPoint = Cam.WorldToViewportPoint
local GetPartsObscuringTarget = Cam.GetPartsObscuringTarget

local lootColors = {
    Blue = Color3.fromRGB(0, 0, 255),
    Red = Color3.fromRGB(255, 0, 0),
    Orange = Color3.fromRGB(255, 165, 0),
    Green = Color3.fromRGB(0, 255, 0),
    Purple = Color3.fromRGB(128, 0, 128),
}

-- Function to get color based on item name
local function getLootColor(itemName)
    if type(itemName) == "string" then
        for colorName, color in pairs(lootColors) do
            if string.find(itemName:lower(), colorName:lower()) then
                return color
            end
        end
    end
    return nil  -- Return nil if no color is found
end



-- Function to format the loot text
local function formatLootText(itemName, count)
    local color = getLootColor(itemName)  -- Check for color
    local displayName

    if count > 1 then
        displayName = string.format("%s x%d", itemName, count)  -- Include count if greater than 1
    else
        displayName = itemName
    end

    return displayName, color  -- Return formatted name and color (if found)
end




-- Function to gather loot counts
local function gatherLootCounts(lootTable)
    local lootCounts = {}

    -- Loop through all NumberValues in the LootTable folder
    for _, item in ipairs(lootTable:GetChildren()) do
        if item:IsA("NumberValue") then
            local lootName = item.Name
            lootCounts[lootName] = (lootCounts[lootName] or 0) + item.Value
        end
    end

    return lootCounts
end
-- Function to display loot text with multiple text labels if colors are found
local function displayLootText(part, lootCounts)

    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.Adornee = part
    billboardGui.AlwaysOnTop = true

    -- Add UIListLayout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = billboardGui

    -- Add TextLabels for loot items
    local hasLabels = false
    for itemName, count in pairs(lootCounts) do

        -- Format the text and color
        local displayName, textColor = formatLootText(itemName, count)
        if not displayName then
        else
            -- Create TextLabel
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 0, 20)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = textColor or Color3.fromRGB(200, 200, 200) -- Default color
            textLabel.Font = Enum.Font.GothamBold
            textLabel.TextScaled = true
            textLabel.Text = displayName
            textLabel.Parent = billboardGui
            hasLabels = true
        end
    end

    if hasLabels then
        -- Parent the BillboardGui to the part
        billboardGui.Parent = part
    else
        billboardGui:Destroy()
    end
end




function sendNotification(text, duration)
    local StarterGui = game:GetService("StarterGui")
    local Version = CURRENTVERSION -- Customize this as needed
    StarterGui:SetCore("SendNotification", {
        Title = Version,
        Text = text or "BoyKizr Softworks LLC",
        Icon = "rbxassetid://12509054972",
        Duration = duration or 5
    })
end




--//silent aim funcs

local SilentAIMFov = Drawing.new("Circle")
SilentAIMFov.Thickness = 1
SilentAIMFov.NumSides = 100
SilentAIMFov.Radius = 360
SilentAIMFov.Filled = false
SilentAIMFov.Visible = false
SilentAIMFov.ZIndex = 999
SilentAIMFov.Transparency = 1
SilentAIMFov.Color = SilentSettings.SilentAimColor
SilentSettings.Visible = false

        local function GetPositionOnScreen(Vector)
            local Vec3, OnScreen = WorldToScreen(Cam, Vector)
            return Vector2.new(Vec3.X, Vec3.Y), OnScreen
        end

        local function ValidateArguments(Args, RayMethod)
            local Matches = 0

            if #Args < RayMethod.ArgCountRequired then
                return false
            end

            for Pos, Argument in next, Args do
                if typeof(Argument) == RayMethod.Args[Pos] then
                    Matches = Matches + 1
                end
            end

            return Matches >= RayMethod.ArgCountRequired
        end

        local function GetDirection(Origin, Position)
            return (Position - Origin).Unit * 1000
        end

        local function GetMousePosition()
            return Vector2.new(Mouse.X, Mouse.Y)
        end

        local function IsPlayerVisible(TargetPlayer)
            local PlayerCharacter = TargetPlayer.Character or TargetPlayer.CharacterAdded:Wait()  -- Ensure character is valid
            local LocalPlayerCharacter = player.Character or player.CharacterAdded:Wait()
        
            if not PlayerCharacter and LocalPlayerCharacter then
                warn("No character found for player or local player.")
                return false
            end
        
            local PlayerRoot = PlayerCharacter:FindFirstChild(SilentSettings.Main.TargetPart) or PlayerCharacter:FindFirstChild("HumanoidRootPart")
            if not PlayerRoot then
                warn("No root part found for player:", TargetPlayer.Name, "on part:", SilentSettings.Main.TargetPart)
                return false
            end
        
            local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
            local ObscuringObjects = #GetPartsObscuringTarget(Cam, CastPoints, IgnoreList)
        
            if ObscuringObjects > 0 then
                warn("Target is obscured:", TargetPlayer.Name)
                return false
            end
        
            return true
        end
        
        




        local function GetClosestPlayer()
            if not SilentSettings.Main.TargetPart then
                warn("No target part selected for Silent Aim.")
                return nil
            end
        
            local Closest
            local DistanceToMouse
            local players = game:GetService("Players")
            local player = players.LocalPlayer
        
            for _, v in ipairs(players:GetPlayers()) do
                if v == player then
                    return
                end
        
                if SilentSettings.Main.TeamCheck and v.Team == player.Team then
                    return
                end
        
                local Character = v.Character or v.CharacterAdded:Wait()
                if not Character then
                    warn("No character found for player:", v.Name)
                    return
                end
        
                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                local Humanoid = Character:FindFirstChild("Humanoid")
        
                if not HumanoidRootPart or not Humanoid or (Humanoid and Humanoid.Health <= 0) then
                    warn("Invalid humanoid for player:", v.Name)
                    return
                end
        
                local ScreenPosition, OnScreen = GetPositionOnScreen(HumanoidRootPart.Position)
                if not OnScreen then
                    warn("Target is off-screen:", v.Name)
                    return
                end
        
                local Distance = (GetMousePosition() - ScreenPosition).Magnitude
                if DistanceToMouse == nil or Distance <= DistanceToMouse or (SilentSettings.Main.Enabled and Distance <= SilentSettings.FOVSettings.Radius) then
                    if Character and ValidTargetParts and #ValidTargetParts > 0 then
                        Closest = SilentSettings.Main.TargetPart == "Random"
                            and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]
                            or Character[SilentSettings.Main.TargetPart]
        
                        DistanceToMouse = Distance
                    else
                        warn("Character or ValidTargetParts is invalid.")
                    end
                end
            end
        
            return Closest
        end
        
        








		coroutine.resume(coroutine.create(function()
			game:GetService("RunService").RenderStepped:Connect(function()
				if SilentSettings.FOVSettings.Visible then 
					SilentAIMFov.Visible = SilentSettings.FOVSettings.Visible
					SilentAIMFov.Color = SilentSettings.SilentAimColor
					SilentAIMFov.Position = GetMousePosition() + Vector2.new(0, 36)
				end
			end)
		end))

--//silent aim funcs




--//vvvvvv RANDOMIZING CLOTHES FUNCTIONS HERE vvvvvv
local function randomColor()
    return Color3.new(math.random(), math.random(), math.random())
end


local leaderboard = playerGui:FindFirstChild("MainStaticGui"):FindFirstChild("RightTab"):FindFirstChild("Leaderboard"):FindFirstChild("PlayerList")


local function getRandomUsername()
    warn("Generating random username")
    local names = { "Player123", "CoolGuy", "Legend27", "NoobSlayer", "ProGamer", "Shadow", "Mystic", "Nightmare", "Hero99", "EpicHunter" }
    return names[math.random(1, #names)]
end






local function updatePlayerList()
    local level = math.random(1, 50)
    local cash = math.random(2500, 100000)
    local bounty = math.random(1, 7500)
    local bank = math.random(54000, 4500000)

    local player = game.Players.LocalPlayer
    local playerGui = player and player:FindFirstChild("PlayerGui")

    if not playerGui then
        warn("playerGui is nil. Attributes not set.")
        return
    end

    playerGui:SetAttribute("Level", level)
    playerGui:SetAttribute("Cash", cash)
    playerGui:SetAttribute("Bounty", bounty)
    playerGui:SetAttribute("Bank", bank)

    -- Initialize leaderboard
    local leaderboard = playerGui:FindFirstChild("Leaderboard")
    if not leaderboard then
        warn("Leaderboard is nil.")
        return
    end

    -- Get leaderboard children
    local children = leaderboard:GetChildren()
    if not children or #children == 0 then
        warn("Leaderboard has no children.")
        return
    end




    -- Iterate over leaderboard children
    for i, v in ipairs(children) do
        if v then
            local displayn = v:FindFirstChild("DisplayName")
            local levelLabel = v:FindFirstChild("Level")
            
            if displayn and levelLabel then
                local randomUsername = getRandomUsername()
                displayn.Text = randomUsername
                levelLabel.Text = tostring(level)
            else
                warn("Missing child properties for:", v.Name)
            end
        else
            warn("Invalid child in leaderboard.")
        end
    end
end




local shirtIds = {
    "rbxassetid://1234567890", -- Replace with actual shirt IDs
    "rbxassetid://2345678901",
    "rbxassetid://3456789012"
}

local pantsIds = {
    "rbxassetid://9876543210", -- Replace with actual pants IDs
    "rbxassetid://8765432109",
    "rbxassetid://7654321098"
}





local function randomizeCharacterAppearance()
    local character = player.Character
    if not character then return end

    -- Randomize Shirt and Pants
    local shirt = character:FindFirstChildOfClass("Shirt")
    local pants = character:FindFirstChildOfClass("Pants")

    
    if shirt then
        shirt.ShirtTemplate = shirtIds[math.random(1, #shirtIds)] -- Random Shirt ID from predefined list
    end
    
    if pants then
        pants.PantsTemplate = pantsIds[math.random(1, #pantsIds)] -- Random Pants ID from predefined list
    end

    -- Randomize Body Colors
    local bodyColors = character:FindFirstChild("Body Colors")
    local function randomColor()
        return Color3.new(math.random(), math.random(), math.random())
    end

    if bodyColors then
        bodyColors.HeadColor3 = randomColor()
        bodyColors.LeftArmColor3 = randomColor()
        bodyColors.RightArmColor3 = randomColor()
        bodyColors.LeftLegColor3 = randomColor()
        bodyColors.RightLegColor3 = randomColor()
        bodyColors.TorsoColor3 = randomColor()
    end




    -- Randomize Hair
    local hair = character:FindFirstChildOfClass("Accessory") -- Assuming first Accessory is hair
    if hair and hair:IsA("Accessory") and hair:FindFirstChild("Handle") then
        hair.Handle.Color = randomColor()
    end

    -- Randomize Accessories
    for _, accessory in ipairs(character:GetChildren()) do
        if accessory:IsA("Accessory") and accessory:FindFirstChild("Handle") then
            accessory.Handle.Color = randomColor()
        end
    end

    warn("Streamer mode on")
end

--//^^^^^^ RANDOMIZING CLOTHES FUNCTIONS HERE ^^^^^^




--//PERFORMANCE MODE

local function togglePerformanceMode(enable)
    local Terrain = workspace:FindFirstChildOfClass('Terrain')
    local Lighting = game:GetService("Lighting")

    if enable and not isPerformanceModeEnabled then
        isPerformanceModeEnabled = true
        print("Performance mode enabled")

        -- Apply performance settings
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

        for obj, _ in pairs(defaults.Objects) do
            if obj:IsA("Part") or obj:IsA("UnionOperation") or obj:IsA("MeshPart") or obj:IsA("CornerWedgePart") or obj:IsA("TrussPart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") then
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Lifetime = NumberRange.new(0)
            elseif obj:IsA("Explosion") then
                obj.BlastPressure = 1
                obj.BlastRadius = 1
            end
        end

        for effect, _ in pairs(defaults.Lighting.Effects) do
            effect.Enabled = false
        end

        workspace.DescendantAdded:Connect(function(child)
            task.spawn(function()
                if child:IsA('ForceField') or child:IsA('Sparkles') or child:IsA('Smoke') or child:IsA('Fire') then
                    task.wait()
                    child:Destroy()
            end
        end)
    end)
end
end



--//PERFORMANCE MODE

local function FLY()
    FLYING = true
    local BG = Instance.new('BodyGyro')
    local BV = Instance.new('BodyVelocity')
    BG.P = 9e4
    BG.Parent = char:FindFirstChild("HumanoidRootPart")
    BV.Parent = char:FindFirstChild("HumanoidRootPart")
    BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.cframe = char.HumanoidRootPart.CFrame
    BV.velocity = Vector3.new(0, 0, 0)
    BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
    local SPEED = 0


    task.spawn(function()
        repeat wait()
            -- Set speed based on controls
            if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                SPEED = isBlackoutFly or iyflyspeed
            elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                SPEED = 0
            end

            -- Apply velocity based on controls
            if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) +
                    ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).Position) -
                        workspace.CurrentCamera.CoordinateFrame.Position)) * SPEED
                lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
            elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) +
                    ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).Position) -
                        workspace.CurrentCamera.CoordinateFrame.Position)) * SPEED
            else
                BV.velocity = Vector3.new(0, 0, 0)
            end

            BG.cframe = workspace.CurrentCamera.CoordinateFrame
        until not FLYING
        CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        SPEED = 0
        BG:Destroy()
        BV:Destroy()
    end)
end



-- KeyDown and KeyUp events for controlling the flying
flyKeyDown = Mouse.KeyDown:Connect(function(KEY)
    if KEY:lower() == 'w' then
        CONTROL.F = (isBlackoutFly or iyflyspeed)
    elseif KEY:lower() == 's' then
        CONTROL.B = - (isBlackoutFly or iyflyspeed)
    elseif KEY:lower() == 'a' then
        CONTROL.L = - (isBlackoutFly or iyflyspeed)
    elseif KEY:lower() == 'd' then
        CONTROL.R = (isBlackoutFly or iyflyspeed)
    elseif QEfly and KEY:lower() == 'e' then
        CONTROL.Q = (isBlackoutFly or iyflyspeed) * 2
    elseif QEfly and KEY:lower() == 'q' then
        CONTROL.E = - (isBlackoutFly or iyflyspeed) * 2
    end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
end)

flyKeyUp = Mouse.KeyUp:Connect(function(KEY)
    if KEY:lower() == 'w' then
        CONTROL.F = 0
    elseif KEY:lower() == 's' then
        CONTROL.B = 0
    elseif KEY:lower() == 'a' then
        CONTROL.L = 0
    elseif KEY:lower() == 'd' then
        CONTROL.R = 0
    elseif KEY:lower() == 'e' then
        CONTROL.Q = 0
    elseif KEY:lower() == 'q' then
        CONTROL.E = 0
    end
end)






--//DISABLE BLACKOUT FLY
function NOFLY()
	FLYING = false
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
--//DISABLE BLACKOUT FLY

local function hookCanCollide(torso, enable)
    if enable then
        mt.__newindex = function(instance, property, value)
            if instance == torso and property == "CanCollide" and value == true then
                return -- Prevent CanCollide from being set to true
            end
            return oldNewIndex(instance, property, value)
        end
    else
        mt.__newindex = oldNewIndex -- Restore the original behavior
    end
end

local function enableNoclip()
    local torso = char:FindFirstChild("Torso")
    local head = char:FindFirstChild("HeadPart")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if torso then
        setreadonly(mt, false)
        torso.CanCollide = false
        if head then head.CanCollide = false end
        if hrp then hrp.CanCollide = false end
        hookedTorso = torso
        hookCanCollide(torso, true)

        game:GetService("RunService").RenderStepped:Connect(function()
            if hookedTorso then
                torso.CanCollide = false
                if head then head.CanCollide = false end
                if hrp then hrp.CanCollide = false end
            end
        end)
    else
        warn("Torso not found in the character")
    end
    setreadonly(mt, true)
end

local function disableNoclip()
    if hookedTorso then
        setreadonly(mt, false)
        hookCanCollide(hookedTorso, false)
        hookedTorso.CanCollide = true
        local head = char:FindFirstChild("HeadPart")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if head then head.CanCollide = true end
        if hrp then hrp.CanCollide = true end
        hookedTorso = nil
        setreadonly(mt, true)
    end
end


local function setBlackoutFlyState(ItsTrue)
    if ItsTrue and not FLYING then  -- Check if fly mode should be activated and not already active
        warn("Starting fly mode")  -- Debugging: Check if fly is enabled
        FLYING = true  -- Set the flag to true, indicating fly mode is active
        spawn(FLY)  -- Activate flying
        enableNoclip()
    elseif not ItsTrue and FLYING then  -- Check if fly mode should be deactivated and currently active
        warn("Stopping fly mode")  -- Debugging: Check if fly is disabled
        FLYING = false  -- Set the flag to false, indicating fly mode is deactivated
        spawn(NOFLY)  -- Deactivate flying
        disableNoclip()
    end
end

-- Function to reset character appearance to default
local function resetCharacterAppearance()
    local character = player.Character
    if not character then return end

    -- Reset clothing
    local shirt = character:FindFirstChildOfClass("Shirt")
    local pants = character:FindFirstChildOfClass("Pants")

    if shirt then
        shirt.ShirtTemplate = ""
    end
    if pants then
        pants.PantsTemplate = ""
    end

    -- Reset skin color
    local bodyColors = character:FindFirstChild("Body Colors")
    if bodyColors then
        bodyColors.HeadColor3 = Color3.new(1, 0.8, 0.6) -- Default skin tone
        bodyColors.LeftArmColor3 = Color3.new(1, 0.8, 0.6)
        bodyColors.RightArmColor3 = Color3.new(1, 0.8, 0.6)
        bodyColors.LeftLegColor3 = Color3.new(1, 0.8, 0.6)
        bodyColors.RightLegColor3 = Color3.new(1, 0.8, 0.6)
        bodyColors.TorsoColor3 = Color3.new(1, 0.8, 0.6)
    end

    warn("Character reset to default!")
end

local function warnOnce(messageKey, message)
    if not _G.warnedMessages then
        _G.warnedMessages = {}
    end
    if not _G.warnedMessages[messageKey] then
        _G.warnedMessages[messageKey] = true
        warn(message)
    end
end



local function findNearbyLootObjects()
    local playerPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position
    if not playerPos then
    warn("error 203, please report this error!")
        return {}
    end

    local regionRadius = distance -- Set the radius as the search distance
    local success, nearbyParts = pcall(function()
        return workspace:GetPartBoundsInRadius(playerPos, regionRadius) -- Get nearby parts
    end)

    local nearbyLoot = {}
    for _, part in ipairs(nearbyParts) do
        local model = part:FindFirstAncestorOfClass("Model") -- Check if the part belongs to a model
        if model and model:FindFirstChild("LootBase") then
            table.insert(nearbyLoot, model) -- Add the model to nearby loot
        end
    end

    return nearbyLoot
end


game:GetService("RunService").RenderStepped:Connect(function()
   if unlockActive then
        local minigameState = player:FindFirstChild("PlayerGui")
            and player.PlayerGui:FindFirstChild("Minigames")
            and player.PlayerGui.Minigames:FindFirstChild("MinigameState")

        if minigameState and minigameState.Visible then
            local nearbyLoot = findNearbyLootObjects()
            for _, lootObj in ipairs(nearbyLoot) do
                if not unlockedObjects[lootObj] then
                    local unlockedMinigame = false
                    local unlockedDA = false

                    -- Fire minigame event if not unlocked
                    if not unlockedMinigame then
                        task.wait(unlockCooldown)
                        minigame:FireServer(lootObj, true)
                        unlockedMinigame = true
                    end

                    -- Fire DA event if not unlocked
                    if not unlockedDA then
                        game:GetService("ReplicatedStorage").DA:Fire()
                        unlockedDA = true
                    end

                    unlockedObjects[lootObj] = true
                    warn("Unlocked:", lootObj.Name)
                end
            end
        end
    end




local processedParts = {} -- Table to track processed parts

if isKeycardFinderEnabled then
    for _, child in ipairs(LOOTBAGFOLDER:GetChildren()) do
        if not processedParts[child] and child:IsA("BasePart") and not child:FindFirstChildOfClass("BillboardGui") then

            local lootTable = child:FindFirstChild("LootTable")
            if lootTable and lootTable:IsA("Folder") then
                local lootCounts = gatherLootCounts(lootTable)
                for k, v in pairs(lootCounts) do
                    warn(" - " .. k .. ": " .. v)
                end

                -- Display loot text with counts
                displayLootText(child, lootCounts)

                -- Mark the part as processed
                processedParts[child] = true
            else
            end
        end
    end
elseif not cleanupDone then
    cleanupDone = true -- Ensure cleanup only happens once

    for _, child in ipairs(LOOTBAGFOLDER:GetChildren()) do
        if processedParts[child] and child:IsA("BasePart") then

            local billboard = child:FindFirstChildOfClass("BillboardGui")
            if billboard then
                billboard:Destroy()
            else
            end

            -- Remove from processedParts
            processedParts[child] = nil
        end
    end
end







if killauraBoolValue then
    if char and char:FindFirstChild("HumanoidRootPart") then
        local rootPart = char.HumanoidRootPart
        local radius = 13
        local region = Region3.new(rootPart.Position - Vector3.new(radius, radius, radius), rootPart.Position + Vector3.new(radius, radius, radius))

        local partsInRegion = game.Workspace:FindPartsInRegion3(region, nil, math.huge)
        for _, part in pairs(partsInRegion) do
            local model = part.Parent
            if model:IsA("Model") and model ~= char and model:FindFirstChild("HumanoidRootPart") then
                local humanoidRootPart = model.HumanoidRootPart
                local head = model:FindFirstChild("Head")

                if head and (rootPart.Position - humanoidRootPart.Position).Magnitude <= radius then
                    task.wait(2)
                    game:GetService("ReplicatedStorage").MeleeStorage.Events.Swing:InvokeServer()
                    game:GetService("ReplicatedStorage").MeleeStorage.Events.Hit:FireServer(head, head.Position)
                end
            end
        end
    end
end





if autoLootActive then
    local lootFrame = player:FindFirstChild("PlayerGui")
        and player.PlayerGui:FindFirstChild("MainGui")
        and player.PlayerGui.MainGui:FindFirstChild("LootFrame")

    if lootFrame and lootFrame.Visible then
        local nearbyLoot = findNearbyLootObjects()
        for _, lootObj in ipairs(nearbyLoot) do
            if not lootedObjects[lootObj] then
                local lootTable = lootObj:FindFirstChild("LootBase") and lootObj.LootBase:FindFirstChild("LootTable")
                if lootTable then
                    local lootedCash = false
                    local lootedValuables = false

                    -- Loot Cash if not already looted
                    if not lootedCash then
                        events:FireServer(lootTable, "Cash")
                        lootedCash = true
                    end

                    -- Loot Valuables if not already looted
                    if not lootedValuables then
                        events:FireServer(lootTable, "Valuables")
                        lootedValuables = true
                    end

                    lootedObjects[lootObj] = true
                    warn("Looted:", lootObj.Name)
                else
                    warnOnce("InvalidLootTable", lootObj.Name)
                end
            end
        end
    end
end

local interactedObjects = {} -- Table to store objects that have already been interacted with

    if instantInteract then
        -- Check if ProximityPrompts are within range of the player
        local nearbyObjects = findNearbyLootObjects() -- Assuming findNearbyLootObjects() can find other interactable objects
        
        for _, obj in ipairs(nearbyObjects) do
            -- Skip objects that have already been interacted with
            if interactedObjects[obj] then
                return
            end

            -- Iterate through all descendants of the object to find ProximityPrompt
            for _, descendant in ipairs(obj:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    -- Set HoldDuration to 0 to make the interaction instant
                    descendant.HoldDuration = 0

                    -- Mark this object as interacted with
                    interactedObjects[obj] = true

                    -- Optionally, you can trigger the interaction instantly if needed
                    -- descendant.ActionText = "Instant Interact" -- Optionally update the ActionText
                    -- descendant:InputBegan() -- You can also simulate input if needed (like a button press)
                    
                    warn("Instantly interacted with:", obj.Name)
                end
            end
        end
    end







if bashautomatically then
    if char and char:FindFirstChild("HumanoidRootPart") then
        local rootPart = char.HumanoidRootPart
        local radius = 15
        local region = Region3.new(rootPart.Position - Vector3.new(radius, radius, radius), rootPart.Position + Vector3.new(radius, radius, radius))

        --// Use GetPartsInRegion3 for parts in the area instead of searching through all workspace parts
        local partsInRegion = game.Workspace:FindPartsInRegion3(region, nil, math.huge)
        
        -- Counter to track how many times the event is fired
        local bashCounter = 0
        local maxBashCount = math.random(5, 8)  -- Randomize the stop count between 5 and 8
        
        for _, part in pairs(partsInRegion) do
            local model = part.Parent
            if model:IsA("Model") and string.lower(model.Name):find("door") then
                -- Debug print to check what's being found
                print("Found model:", model.Name)

                if (rootPart.Position - part.Position).Magnitude <= radius then
                    print("Bashing door:", model.Name)  -- Debug print for the door being bashed
                    game:GetService("ReplicatedStorage").Events.Player.Bash:FireServer(model, true)
                    bashCounter = bashCounter + 1
                    task.wait(0.5)

                    -- Stop firing the event once the limit is reached
                    if bashCounter >= maxBashCount then
                        print("Reached max bash count, stopping.")
                        break
                    end
                end
            end
        end
    end
end

    if blackoutFlyEnabled then
        if flykeyPressed then
            setBlackoutFlyState(flykeyPressed)
    else

    if not flykeyPressed then
        setBlackoutFlyState(flykeyPressed)

        end
    end
end

end)



-- Toggles for unlocking and looting
local Window = Library:CreateWindow({
    Title = 'Boykizr Softworks LLC',
    Center = true,
    AutoShow = true,
    TabPadding = 8
})

local Tabs = {
    main = Window:AddTab('CURRENT BUILD'),
    esc = Window:AddTab('MISCELLANEOUS'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local LeftGroupBox = Tabs.main:AddLeftGroupbox("COMBAT")

local RightGroupBox = Tabs.main:AddRightGroupbox("MOVEMENT")

local LootGroupBox = Tabs.main:AddRightGroupbox("LOOT")

local KeyBindsGroupBox = Tabs.esc:AddRightGroupbox("KEYBINDS")

local OneRightGroupBox = Tabs.main:AddRightGroupbox("MISCELLANEOUS")

local extMISC = Tabs.esc:AddLeftGroupbox("ext")



LeftGroupBox:AddToggle('killaura', {
    Text = 'Melee Aura',
    Default = false,
    Tooltip = 'toggles kill aura.',
    Callback = function(v)
        killauraBoolValue = v
    end
})



LeftGroupBox:AddToggle('autobash', {
    Text = 'Bash Aura',
    Default = false,
    Tooltip = 'automatically bashes every door near you (INSTANT BASH)',
    Callback = function(v)
        bashautomatically = v

    end
})

RightGroupBox:AddToggle('BlackoutFlyToggle', {
    Text = 'fly',
    Default = false,
    Tooltip = 'Toggles blackout fly mode.',
    Callback = function(v)
        blackoutFlyEnabled = v
    end
})

RightGroupBox:AddSlider('FlySpeedSlider', {
    Text = 'Fly Speed m/s',
    Default = 1,
    Min = 1,
    Max = 15,
    Rounding = 1,
    Compact = true,
    Callback = function(v)
        iyflyspeed = v
    end
})

RightGroupBox:AddToggle('player noclip', {
    Text = 'player noclip',
    Default = false,
    Tooltip = 'erm.. no.. clip..',
    Callback = function(v)
        local torso = char:FindFirstChild("Torso")
        local head = char:FindFirstChild("HeadPart")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if torso then
            if v then
                -- Hook CanCollide when setting to false for torso
                setreadonly(mt, false)
                torso.CanCollide = false -- Set CanCollide to false for torso initially
                if head then
                    head.CanCollide = false -- Set CanCollide to false for head (no hook)
                end
                if hrp then
                    hrp.CanCollide = false -- Set CanCollide to false for HumanoidRootPart (no hook)
                end
                hookedTorso = torso
                hookCanCollide(torso, true) -- Start hooking for false CanCollide on torso
                
                -- Keep CanCollide as false every frame
                game:GetService("RunService").RenderStepped:Connect(function()
                    if hookedTorso then
                        torso.CanCollide = false -- Keep setting CanCollide to false for torso
                        if head then
                            head.CanCollide = false -- Keep setting CanCollide to false for head
                        end
                        if hrp then
                            hrp.CanCollide = false -- Keep setting CanCollide to false for HumanoidRootPart
                        end
                    end
                end)
            else
                setreadonly(mt, false)
                -- Hook CanCollide when setting to true for torso
                hookCanCollide(hookedTorso, false) -- Stop hooking for false CanCollide
                hookedTorso.CanCollide = true -- Reset to default behavior (true CanCollide) for torso
                if head then
                    head.CanCollide = true -- Reset CanCollide to true for head (no hook)
                end
                if hrp then
                    hrp.CanCollide = true -- Reset CanCollide to true for HumanoidRootPart (no hook)
                end
                hookedTorso = nil
            end
        else
            warn("torso not found in the character")
        end

        setreadonly(mt, true) -- Restore read-only state of the metatable
    end
})

local brokencharfix = extMISC:AddButton({
    Text = 'FIX BROKEN CHARACTER',
    Func = function()
    game:GetService("ReplicatedStorage").Events.Player.Ragdoll:FireServer()
    end,
    DoubleClick = false,
    Tooltip = 'FIXES CHARACTER NOT ROTATING AFTER RAGDOLLING WITH NOCLIP ENABLED.'
})

local Button = extMISC:AddButton({
    Text = "soundspam (server sided)",
    Func = function()
        local args = {
            [1] = 0,
            [2] = 0
        }
        
        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Player"):WaitForChild("Damage"):FireServer(unpack(args))
    end,
    DoubleClick = false,
    Tooltip = 'yaw'
})

local UserInputService = game:GetService("UserInputService")


LootGroupBox:AddToggle('UnlockToggle', {
    Text = 'Auto Unlock',
    Default = false,
    Tooltip = 'automatically unlocks for you.',
    Callback = function(v)
        unlockActive = v
    end
})

LootGroupBox:AddToggle('AutoLootToggle', {
    Text = 'Auto Loot',
    Default = false,
    Tooltip = 'automatically loots cash and valuables for you.',
    Callback = function(v)
        autoLootActive = v

    end
})


LootGroupBox:AddToggle('loot esp', {
    Text = 'Loot Chams',
    Default = false,
    Tooltip = 'finds loot for u.',
    Callback = function(v)
        isKeycardFinderEnabled = v
    end
})

LootGroupBox:AddToggle('instantinteract', {
    Text = 'Instant Interaction',
    Default = false,
    Tooltip = 'interacts instantly instead of having to wait for a holdDuration.',
    Callback = function(v)
        instantInteract = v
    end
})

LootGroupBox:AddSlider('legitunlock', { 
    Text = 'unlock delay m/s',
    Default = 0,
    Min = 0,
    Max = 6,
    Rounding = 1,
    Compact = true,
    Callback = function(Value)
        unlockCooldown = Value
    end
})

LootGroupBox:AddSlider('legitloot', {
    Text = 'loot delay m/s',
    Default = 0,
    Min = 0,
    Max = 4,
    Rounding = 1,
    Compact = true,
    Callback = function(Value)
        lootCooldown = Value
    end
})

--[[ LeftGroupBox:AddToggle('silentaim', {
    Text = 'silent aim',
    Default = false,
    Tooltip = 'unlike traditional aimbot, silent aim redirects bullets instead of your camera, for more legit use!',
    Callback = function(v)
    SilentSettings.Main.Enabled = v
    end
})

LeftGroupBox:AddToggle('silentaimfov', {
    Text = 'silent aim FOV',
    Default = false,
    Tooltip = 'obviously displays the fov, duuuh.',
    Callback = function(v)
    SilentSettings.FOVSettings.Visible = v
    SilentAIMFov.Visible = v
    end
})

LeftGroupBox:AddSlider('silentfovS', { 
    Text = '',
    Default = 50,
    Min = 10,
    Max = 140,
    Rounding = 1,
    Compact = true,
    Callback = function(v)
    SilentSettings.FOVSettings.Radius = v
    SilentAIMFov.Radius = v
    end
})


LeftGroupBox:AddDropdown('hitparts', {
    Values = { 'Head', 'Torso'},
    Default = 1, -- number index of the value / string
    Multi = true, -- true / false, allows multiple choices to be selected

    Text = 'hitparts',
    Tooltip = 'where you want bullets to redirect to.', -- Information shown when you hover over the dropdown

    Callback = function(v)
        SilentSettings.Main.TargetPart = v
    end
})
 ]]

local randomchar = extMISC:AddButton({
    Text = 'streamer mode',
    Func = function()
        randomizeCharacterAppearance()
        updatePlayerList()
    end,
    DoubleClick = false,
    Tooltip = 'THIS ACTION CAN NOT BE UNDONE. REJOIN FOR A FRESH RESET.'
})

local performancemode = extMISC:AddButton({
    Text = 'performance mode',
    Func = function()
    togglePerformanceMode()
    end,
    DoubleClick = false,
    Tooltip = 'self explanatory, are you retar? :skull:'
})

OneRightGroupBox:AddToggle('FieldOfView', {
    Text = 'FOV',
    Default = false,
    Tooltip = 'Modify your camera\'s FOV.',
    Callback = function(v)
        fovActive = v
        if fovActive then
            -- Wait for the camera to be available before changing the FOV
            local camera = workspace.CurrentCamera
            camera.FieldOfView = Fov  -- Apply the FOV when toggled on
        else
            local camera = workspace.CurrentCamera
            camera.FieldOfView = 70  -- Reset to default FOV when toggled off
        end
    end
})

OneRightGroupBox:AddSlider('fieldofviewslider', { 
    Text = 'FOV m/s',
    Default = 80,
    Min = 80,
    Max = 140,
    Rounding = 1,
    Compact = true,
    Callback = function(Value)
        Fov = Value  -- Update Fov value from the slider
        if fovActive then
            -- Immediately apply the new FOV if it's active
            local camera = workspace.CurrentCamera
            camera.FieldOfView = Fov
        end
    end
})

KeyBindsGroupBox:AddLabel('Keybind'):AddKeyPicker('flyToggleButton', {
    Default = 'F',  -- Default key is 'F'
    SyncToggleState = false,  -- Don't sync with the toggle (toggle should not control keybind)
    Mode = 'Toggle',  -- Toggle mode for the keybind
    Text = 'Player Fly',  -- Text to display in the keybind menu
    NoUI = false,  -- Show in the keybind menu

    Callback = function(Value)
        -- Check if the player is typing or interacting with UI
        local isTyping = UserInputService:GetFocusedTextBox() ~= nil

        -- Only toggle fly if not typing and the fly toggle is enabled
        if blackoutFlyEnabled and not isTyping then
            flykeyPressed = Value  -- Set flykeyPressed to true or false based on key press
        end
    end,

    ChangedCallback = function(New)
        -- Handle changes to the keybind if necessary (optional)
    end
})


local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind
Library.KeybindFrame.Visible = true
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()
