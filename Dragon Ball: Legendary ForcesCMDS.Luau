-- Chat Commands System
local ChatCommands = {
    Prefix = "!",
    Commands = {},
    
    -- Settings
    TELEPORT_DELAY = 0.05,
    BACK_OFFSET = 3,
    
    -- State variables
    AutoLoopKillEnabled = false,
    CurrentLoopBoss = nil,
    
    -- Services
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    Camera = workspace.CurrentCamera,
    player = game:GetService("Players").LocalPlayer,
    combatRemote = nil,
}

-- Initialize combat remote
ChatCommands.combatRemote = ChatCommands.ReplicatedStorage:FindFirstChild("Assets") and 
                           ChatCommands.ReplicatedStorage.Assets:FindFirstChild("CombatAssets") and 
                           ChatCommands.ReplicatedStorage.Assets.CombatAssets:FindFirstChild("CombatRemotes") and 
                           ChatCommands.ReplicatedStorage.Assets.CombatAssets.CombatRemotes:FindFirstChild("ActivateCombat")

-- ================= NOTIFICATION FUNCTION =================
function ChatCommands:Notify(title, content, duration)
    duration = duration or 3
    
    -- Try to use Fluent notification if available
    if Fluent and Fluent.Notify then
        Fluent:Notify({
            Title = title,
            Content = content,
            Duration = duration
        })
    else
        -- Fallback to Roblox notification
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = content,
            Duration = duration
        })
    end
end

-- ================= PLAYER FINDER FUNCTION =================
function ChatCommands:FindPlayer(input)
    if not input or input == "" then return nil end
    
    input = input:lower()
    local exactMatches = {}
    local partialMatches = {}
    
    for _, plr in ipairs(self.Players:GetPlayers()) do
        if plr ~= self.player then
            local name = plr.Name:lower()
            local displayName = plr.DisplayName:lower()
            
            -- Check for exact matches first
            if name == input or displayName == input then
                table.insert(exactMatches, plr)
            end
            
            -- Check for partial matches (contains the input)
            if name:find(input, 1, true) or displayName:find(input, 1, true) then
                table.insert(partialMatches, plr)
            end
        end
    end
    
    -- Return exact match if found
    if #exactMatches > 0 then
        return exactMatches[1]
    end
    
    -- Return partial match if found
    if #partialMatches > 0 then
        if #partialMatches == 1 then
            return partialMatches[1]
        else
            -- Multiple partial matches found
            local names = {}
            for _, plr in ipairs(partialMatches) do
                table.insert(names, plr.Name)
            end
            self:Notify("Multiple Players Found", "Matches: " .. table.concat(names, ", "), 5)
            return nil
        end
    end
    
    return nil
end

-- ================= FLING SYSTEM =================
function ChatCommands:FlingPlayer(TargetPlayer)
    if typeof(TargetPlayer) == "string" then
        TargetPlayer = self:FindPlayer(TargetPlayer)
    end
    
    if not TargetPlayer or not TargetPlayer.Character then 
        self:Notify("Error", "Player not found or invalid!", 3)
        return 
    end

    local Character = self.player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle

    if not Character or not Humanoid or not RootPart then
        self:Notify("Error", "Your character not found!", 3)
        return
    end

    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end

    if RootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = RootPart.CFrame
    end
    if THumanoid and THumanoid.Sit then
        self:Notify("Error", "Target is sitting!", 3)
        return
    end

    -- Freeze camera from current position
    local freezeCameraCFrame = self.Camera.CFrame
    local cameraConnection
    cameraConnection = self.RunService.RenderStepped:Connect(function()
        self.Camera.CFrame = freezeCameraCFrame
    end)

    if THead then
        self.Workspace.CurrentCamera.CameraSubject = THead
    elseif not THead and Handle then
        self.Workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid and TRootPart then
        self.Workspace.CurrentCamera.CameraSubject = THumanoid
    end
    if not TCharacter:FindFirstChildWhichIsA("BasePart") then
        cameraConnection:Disconnect()
        return
    end

    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0

        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100

                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                    task.wait()
                end
            else
                break
            end
        until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= self.Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
    end

    self.Workspace.FallenPartsDestroyHeight = 0/0

    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRootPart and THead then
        if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
            SFBasePart(THead)
        else
            SFBasePart(TRootPart)
        end
    elseif TRootPart and not THead then
        SFBasePart(TRootPart)
    elseif not TRootPart and THead then
        SFBasePart(THead)
    elseif not TRootPart and not THead and Accessory and Handle then
        SFBasePart(Handle)
    else
        cameraConnection:Disconnect()
        return
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)

    -- Restore normal camera control
    cameraConnection:Disconnect()
    self.Workspace.CurrentCamera.CameraSubject = Humanoid

    repeat
        RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
        Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
        Humanoid:ChangeState("GettingUp")
        for _, x in pairs(Character:GetChildren()) do
            if x:IsA("BasePart") then
                x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
            end
        end
        task.wait()
    until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
    
    self:Notify("Fling Complete", "Successfully flung " .. TargetPlayer.Name, 3)
end

-- ================= DRAGON BALL FUNCTION =================
function ChatCommands:CollectDragonBalls()
    local TOUCH_DELAY = 0.2

    local dragonBallFolders = {
        self.Workspace:WaitForChild("DragonBalls"):WaitForChild("PorungaBalls"),
        self.Workspace:WaitForChild("DragonBalls"):WaitForChild("ShenronBalls")
    }

    local function fireTouch(touchInterest)
        if touchInterest then
            firetouchinterest(self.player.Character.HumanoidRootPart, touchInterest.Parent, 0)
            task.wait()
            firetouchinterest(self.player.Character.HumanoidRootPart, touchInterest.Parent, 1)
        end
    end

    -- Collect balls once
    if self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart") then
        for _, folder in ipairs(dragonBallFolders) do
            for i = 1, 7 do
                local ball = folder:FindFirstChild(tostring(i))
                if ball then
                    local corpo = ball:FindFirstChild("corpo")
                    local touchInterest = corpo and corpo:FindFirstChild("TouchInterest")
                    if touchInterest then
                        fireTouch(touchInterest)
                        task.wait(TOUCH_DELAY)
                    end
                end
            end
        end
        self:Notify("Dragon Balls", "Finished collecting Dragon Balls!", 3)
    else
        self:Notify("Error", "Character not found!", 3)
    end
end

-- ================= BOSS KILL FUNCTION =================
function ChatCommands:KillBoss(bossName)
    local bossesFolder = self.Workspace:FindFirstChild("Bosses")
    if not bossesFolder then 
        self:Notify("Error", "Bosses folder not found!", 3)
        return 
    end

    local boss = bossesFolder:FindFirstChild(bossName)
    if not boss then 
        self:Notify("Error", "Boss '" .. bossName .. "' not found!", 3)
        return 
    end

    local bossHrp = boss:FindFirstChild("HumanoidRootPart")
    local bossHumanoid = boss:FindFirstChildOfClass("Humanoid")
    
    if not bossHrp or not bossHumanoid then
        self:Notify("Error", "Boss has no HumanoidRootPart or Humanoid!", 3)
        return
    end

    local character = self.player.Character
    local playerHrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not playerHrp then
        self:Notify("Error", "Your character not found!", 3)
        return
    end

    -- Teleport behind boss and attack
    playerHrp.CFrame = bossHrp.CFrame * CFrame.new(0, 0, self.BACK_OFFSET)
    task.wait(0.1)
    if self.combatRemote then
        self.combatRemote:FireServer()
        self:Notify("Boss Kill", "Attacked " .. bossName, 2)
    else
        self:Notify("Error", "Combat remote not found!", 3)
    end
end

-- ================= DEFAULT COMMANDS =================
function ChatCommands:SetupDefaultCommands()
    -- Fling command
    self:AddCommand("fling", function(args)
        if not args[2] then
            self:Notify("Error", "Usage: ;fling <username/displayname>", 3)
            return
        end
        local targetName = table.concat(args, " ", 2)
        self:Notify("Fling", "Looking for: " .. targetName, 2)
        local targetPlayer = self:FindPlayer(targetName)
        
        if targetPlayer then
            self:Notify("Fling", "Found: " .. targetPlayer.Name, 2)
            self:FlingPlayer(targetPlayer)
        else
            self:Notify("Error", "No player found matching '" .. targetName .. "'", 3)
        end
    end)
    
    -- Dragon Ball command
    self:AddCommand("db", function(args)
        self:Notify("Dragon Balls", "Collecting...", 2)
        self:CollectDragonBalls()
    end)
    
    -- Kill boss command
    self:AddCommand("kill", function(args)
        if not args[2] then
            self:Notify("Error", "Usage: ;kill <bossName>", 3)
            return
        end
        local bossName = table.concat(args, " ", 2)
        self:KillBoss(bossName)
    end)
    
    -- Loop kill command
    self:AddCommand("loopkill", function(args)
        if not args[2] then
            self:Notify("Error", "Usage: ;loopkill <bossName>", 3)
            return
        end
        
        if self.AutoLoopKillEnabled then
            self.AutoLoopKillEnabled = false
            self.CurrentLoopBoss = nil
            self:Notify("Loop Kill", "Stopped", 2)
        else
            self.CurrentLoopBoss = table.concat(args, " ", 2)
            self.AutoLoopKillEnabled = true
            self:Notify("Loop Kill", "Started on " .. self.CurrentLoopBoss, 2)
        end
    end)
    
    -- Help command
    self:AddCommand("help", function(args)
        local commands = {}
        for name, _ in pairs(self.Commands) do
            table.insert(commands, name)
        end
        self:Notify("Available Commands", self.Prefix .. table.concat(commands, ", " .. self.Prefix), 8)
    end)
end

-- ================= COMMAND SYSTEM =================
function ChatCommands:AddCommand(name, func)
    self.Commands[name:lower()] = func
end

function ChatCommands:HandleCommand(message)
    if not message:sub(1, #self.Prefix) == self.Prefix then return end
    
    -- Remove prefix and split into command and args
    local args = {}
    for word in message:sub(#self.Prefix + 1):gmatch("%S+") do
        table.insert(args, word)
    end
    
    if #args == 0 then return end
    
    local command = args[1]:lower()
    
    if self.Commands[command] then
        local success, err = pcall(function()
            self.Commands[command](self, args)
        end)
        if not success then
            self:Notify("Command Error", "Failed to execute: " .. tostring(err), 4)
        end
    else
        self:Notify("Unknown Command", "Type ;help for commands", 3)
    end
end

-- ================= LOOP KILL LOGIC =================
function ChatCommands:StartLoopKill()
    task.spawn(function()
        while true do
            if self.AutoLoopKillEnabled and self.CurrentLoopBoss then
                self:KillBoss(self.CurrentLoopBoss)
            end
            task.wait(self.TELEPORT_DELAY)
        end
    end)
end

-- ================= CHAT LISTENER =================
function ChatCommands:SetupChatListener()
    local function onChatMessage(message)
        self:HandleCommand(message)
    end
    
    -- Method 1: Players Chat (most common)
    local chatService = self.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatService then
        local sayMessageRequest = chatService:FindFirstChild("SayMessageRequest")
        if sayMessageRequest then
            sayMessageRequest.OnClientEvent:Connect(function(messageData)
                if messageData and messageData.Message then
                    onChatMessage(messageData.Message)
                end
            end)
        end
    end
    
    -- Method 2: Legacy chat
    local chat = self.player.PlayerGui:FindFirstChild("Chat")
    if chat then
        local chatFrame = chat:FindFirstChild("Frame")
        if chatFrame then
            local chatBar = chatFrame:FindFirstChild("ChatBar")
            if chatBar then
                chatBar.FocusLost:Connect(function(enterPressed)
                    if enterPressed then
                        local message = chatBar.Text
                        chatBar.Text = ""
                        onChatMessage(message)
                    end
                end)
            end
        end
    end
    
    -- Method 3: Standard chat remote
    for _, obj in ipairs(self.ReplicatedStorage:GetDescendants()) do
        if obj.Name == "ChatMessage" or obj.Name == "OnMessageDoneFiltering" then
            obj.OnClientEvent:Connect(function(...)
                local args = {...}
                if args[1] and type(args[1]) == "table" and args[1].Message then
                    onChatMessage(args[1].Message)
                elseif args[2] then
                    onChatMessage(args[2])
                end
            end)
        end
    end
    
    self:Notify("Chat Commands", "Loaded! Prefix: '" .. self.Prefix .. "'", 5)
end

-- ================= INITIALIZATION =================
function ChatCommands:Init()
    -- Setup default commands
    self:SetupDefaultCommands()
    
    -- Setup chat listener
    self:SetupChatListener()
    
    -- Start loop kill thread
    self:StartLoopKill()
    
    -- Re-setup on character add
    self.player.CharacterAdded:Connect(function()
        self:SetupChatListener()
    end)
    
    return self
end

-- Create and initialize the command system
local Commands = ChatCommands:Init()

-- ================= HOW TO ADD YOUR OWN COMMANDS =================
--[[
-- Examples of how to add your own commands:

-- Simple command
Commands:AddCommand("test", function(self, args)
    self:Notify("Test Command", "This is a test!", 3)
end)

-- Command with arguments
Commands:AddCommand("echo", function(self, args)
    if args[2] then
        local message = table.concat(args, " ", 2)
        self:Notify("Echo", message, 3)
    end
end)

-- Toggle command
Commands:AddCommand("godmode", function(self, args)
    if not self.GodMode then
        self.GodMode = true
        self:Notify("God Mode", "Enabled", 2)
        -- Your god mode logic here
    else
        self.GodMode = false
        self:Notify("God Mode", "Disabled", 2)
    end
end)

-- Teleport command
Commands:AddCommand("tp", function(self, args)
    if args[2] then
        local target = self:FindPlayer(args[2])
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            self.player.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
            self:Notify("Teleport", "Teleported to " .. target.Name, 2)
        end
    end
end)
--]]
