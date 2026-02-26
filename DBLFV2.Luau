local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB v2 | Dragon Ball: Legendary Forces " .. Fluent.Version,
    SubTitle = "by Ange",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 320),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

Fluent:Notify({
    Title = "Loaded!",
    Content = "Angel Hub has succesfully been loaded!",
    Duration = 5
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

local Options = Fluent.Options

-- Global flag to prevent multiple autofarm loops
_G.AutofarmRunning = false

local function getFolder(path)
    local success, folder = pcall(function()
        local current = game
        for _, part in ipairs(path:split(".")) do
            current = current:WaitForChild(part, 5)
        end
        return current
    end)
    if not success or not folder then
        return nil
    end
    return folder
end

local function refreshMobs(path)
    local folder = getFolder(path)
    if not folder then
        Fluent:Notify({Title = "Error", Content = "Invalid folder path!", Duration = 4})
        return
    end
    
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    
    local mobs = {}
    for _, m in ipairs(folder:GetChildren()) do
        local hrp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
        local hum = m:FindFirstChild("Humanoid")
        if hum and hum.Health > 0 and hrp and (hrp.Position - root.Position).Magnitude <= 600 then
            table.insert(mobs, m.Name)
        end
    end
    
    Options.Dropdown:SetValues(mobs)
    if #mobs > 0 then
        Options.Dropdown:Set(mobs[1])
    end
end

local Section1 = Tabs.Main:AddSection("AutoFarm")

local Input = Tabs.Main:AddInput("Input", {
    Title = "Input Folder",
    Description = "Input the path/link of the folder you want to farm the mobs.",
    Default = "workspace.Bosses",
    Placeholder = "workspace.Bosses",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        refreshMobs(Value)
    end
})

local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
    Title = "Select Mob",
    Description = "Select the mob you want to autofarm.",
    Values = {},
    Multi = false,
    Default = "",
})

local RefreshToggle = Tabs.Main:AddToggle("RefreshToggle", {
    Title = "Refresh",
    Description = "Refreshes the mob list from current folder (auto-off).",
    Default = false,
    Callback = function(state)
        if state then
            local currentPath = Options.Input.Value
            if currentPath and currentPath \~= "" then
                refreshMobs(currentPath)
            else
                Fluent:Notify({Title = "Error", Content = "No folder path set!", Duration = 3})
            end
            Options.RefreshToggle.Value = false  -- Auto turn off
        end
    end
})

local Toggle1 = Tabs.Main:AddToggle("MyToggle1", {
    Title = "Start",
    Description = "Commence the autofarm.",
    Default = false,
    Callback = function(state)
        if state and not _G.AutofarmRunning then
            _G.AutofarmRunning = true
            spawn(function()
                local player = game.Players.LocalPlayer
                local remote = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("CombatAssets"):WaitForChild("CombatRemotes"):WaitForChild("ActivateCombat")
                
                while Options.MyToggle1.Value and _G.AutofarmRunning do
                    local folderPath = Options.Input.Value
                    local folder = getFolder(folderPath)
                    if not folder then
                        task.wait(1)
                        continue
                    end
                    
                    local char = player.Character
                    if not char or not char.Parent then
                        task.wait(1)
                        continue
                    end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp or not hrp.Parent then
                        task.wait(1)
                        continue
                    end
                    
                    if Options.MyToggle2.Value then
                        -- Whole folder: collect all alive, sort by distance, farm one by one
                        local all_mobs = {}
                        for _, child in ipairs(folder:GetChildren()) do
                            local mob_hrp = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")
                            local hum = child:FindFirstChild("Humanoid")
                            if hum and hum.Health > 0 and mob_hrp then
                                table.insert(all_mobs, {model = child, hrp = mob_hrp, dist = (mob_hrp.Position - hrp.Position).Magnitude})
                            end
                        end
                        -- Sort by distance (nearest first)
                        table.sort(all_mobs, function(a, b) return a.dist < b.dist end)
                        
                        for _, mobData in ipairs(all_mobs) do
                            local mob = mobData.model
                            local mobRoot = mobData.hrp
                            while Options.MyToggle1.Value and _G.AutofarmRunning and mob.Parent and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mobRoot and mobRoot.Parent do
                                local behindPos = mobRoot.Position - mobRoot.CFrame.LookVector * 4
                                hrp.CFrame = CFrame.lookAt(behindPos, mobRoot.Position)
                                remote:FireServer()
                                task.wait(0.08)
                            end
                            task.wait(0.3)  -- Short delay before next mob
                        end
                    else
                        -- Single selected mob
                        local selectedName = Options.Dropdown.Value
                        if selectedName and selectedName \~= "" then
                            local mob = folder:FindFirstChild(selectedName)
                            if mob then
                                local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
                                local hum = mob:FindFirstChild("Humanoid")
                                if hum and hum.Health > 0 and mobRoot then
                                    while Options.MyToggle1.Value and _G.AutofarmRunning and mob.Parent and hum.Health > 0 and mobRoot.Parent do
                                        local behindPos = mobRoot.Position - mobRoot.CFrame.LookVector * 4
                                        hrp.CFrame = CFrame.lookAt(behindPos, mobRoot.Position)
                                        remote:FireServer()
                                        task.wait(0.08)
                                    end
                                end
                            end
                        end
                    end
                    
                    task.wait(0.5)  -- Prevent CPU hog between cycles
                end
                _G.AutofarmRunning = false
            end)
        elseif not state then
            _G.AutofarmRunning = false
        end
    end
})

local Section2 = Tabs.Main:AddSection("Settings")

local Toggle2 = Tabs.Main:AddToggle("MyToggle2", {
    Title = "Whole Folder",
    Description = "Autofarm every mob in the folder one by one (ignores dropdown).",
    Default = false,
    Callback = function() end  -- No callback needed, checked in loop
})
