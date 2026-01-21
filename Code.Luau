local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB | Dragon Blox" .. Fluent.Version,
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
    Main = Window:AddTab({ Title = "Training", Icon = "biceps-flexed" }),
    Quests = Window:AddTab({ Title = "AutoFarm", Icon = "tractor" }),
    Worlds = Window:AddTab({ Title = "Worlds", Icon = "earth" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

----------------------------------------------------------------
-- TRAIN
----------------------------------------------------------------
local SectionA = Tabs.Main:AddSection("Train")

local TrainEnabled = false
local SelectedSkillId = "1"

local SkillDropdown = Tabs.Main:AddDropdown("SkillDropdown", {
    Title = "Training Type",
    Values = {"Punch", "Durability", "Ki"},
    Default = 1,
    Multi = false,
    Callback = function(value)
        if value == "Punch" then
            SelectedSkillId = "1"
        elseif value == "Durability" then
            SelectedSkillId = "6"
        elseif value == "Ki" then
            SelectedSkillId = "2"
        end
    end
})

local TrainToggle = Tabs.Main:AddToggle("TrainToggle", {
    Title = "Train",
    Default = false,
    Callback = function(state)
        TrainEnabled = state

        if state then
            task.spawn(function()
                while TrainEnabled do
                    local args = {
                        {
                            Camera = CFrame.new(-58.72254943847656, 85.52032470703125, -374.1243896484375, 0.5716235637664795, 0.8078518509864807, -0.14360305666923523, 0, 0.17501555383205414, 0.9845656752586365, 0.8205159902572632, -0.562800943851471, 0.10004301369190216),
                            SkillId = SelectedSkillId,
                            Began = true,
                            CFrame = CFrame.new(-58.139434814453125, 72.95044708251953, -374.5310363769531, 0.5714630484580994, 0.8079167604446411, -0.14387644827365875, 0.0002584535686764866, 0.1751476675271988, 0.9845421314239502, 0.820627748966217, -0.562666654586792, 0.099881611764431),
                            ["Typ\208\181"] = 1,
                            Aim = vector.create(-50.945613861083984, 23.723339080810547, -379.5251159667969)
                        }
                    }

                    game:GetService("ReplicatedStorage")
                        :WaitForChild("Remotes")
                        :WaitForChild("SkillRemote")
                        :FireServer(unpack(args))

                    task.wait()
                end
            end)
        else
            local args = {
                {
                    Camera = CFrame.new(-58.72254943847656, 85.52032470703125, -374.1243896484375, 0.5716235637664795, 0.8078518509864807, -0.14360305666923523, 0, 0.17501555383205414, 0.9845656752586365, 0.8205159902572632, -0.562800943851471, 0.10004301369190216),
                    SkillId = SelectedSkillId,
                    Began = false,
                    CFrame = CFrame.new(-58.139434814453125, 72.95044708251953, -374.5310363769531, 0.5714630484580994, 0.8079167604446411, -0.14387644827365875, 0.0002584535686764866, 0.1751476675271988, 0.9845421314239502, 0.820627748966217, -0.562666654586792, 0.099881611764431),
                    ["Typ\208\181"] = 1,
                    Aim = vector.create(-50.945613861083984, 23.723339080810547, -379.5251159667969)
                }
            }

            game:GetService("ReplicatedStorage")
                :WaitForChild("Remotes")
                :WaitForChild("SkillRemote")
                :FireServer(unpack(args))
        end
    end
})

----------------------------------------------------------------
-- AUTOFARM
----------------------------------------------------------------
local SectionB = Tabs.Quests:AddSection("AutoFarm")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local SelectedMobName = nil
local running = false
local AutoFarmPosition = "Back"
local AutoFarmType = "Mobs"

-- Nearest Mob / Boss Dropdown
local NearestMobsDropdown = Tabs.Quests:AddDropdown("NearestMobsDropdown", {
    Title = "Select Mob",
    Values = {},
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedMobName = value
    end
})

-- Helper: get correct folder
local function getCurrentFolder()
    if AutoFarmType == "Boss" then
        return workspace["World Mobs"]["Boss Mobs"]
    end
    return workspace["World Mobs"].Mobs
end

-- Update nearest dropdown
local function updateNearestTargets()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local folder = getCurrentFolder()
    if not folder then return end

    local list, added = {}, {}

    for _, mob in ipairs(folder:GetChildren()) do
        if mob:FindFirstChild("HumanoidRootPart") then
            table.insert(list, {
                Name = mob.Name,
                Dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
            })
        end
    end

    table.sort(list, function(a, b)
        return a.Dist < b.Dist
    end)

    local values = {}
    for _, mob in ipairs(list) do
        if not added[mob.Name] then
            added[mob.Name] = true
            table.insert(values, mob.Name)
        end
    end

    NearestMobsDropdown:SetValues(values)
end

task.spawn(function()
    while true do
        updateNearestTargets()
        task.wait(0.7)
    end
end)

-- AutoFarm Toggle
Tabs.Quests:AddToggle("AutoFarmToggle", {
    Title = "AutoFarm",
    Default = false,
    Callback = function(state)
        running = state
        if not state then return end

        if not SelectedMobName then
            Fluent:Notify({
                Title = "AutoFarm",
                Content = "Select a Mob first.",
                Duration = 3
            })
            running = false
            return
        end

        task.spawn(function()
            local hrp = player.Character:WaitForChild("HumanoidRootPart")
            local SkillRemote = game:GetService("ReplicatedStorage").Remotes.SkillRemote

            local punchArgs = {
                {
                    SkillId = "1",
                    Began = true,
                    ["Typ\208\181"] = 1
                }
            }

            local function getNearestSelected()
                local folder = getCurrentFolder()
                local nearest, dist = nil, math.huge

                for _, mob in ipairs(folder:GetChildren()) do
                    local humanoid = mob:FindFirstChildOfClass("Humanoid")
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")

                    if mob.Name == SelectedMobName and humanoid and humanoid.Health > 0 and mhrp then
                        local d = (hrp.Position - mhrp.Position).Magnitude
                        if d < dist then
                            dist = d
                            nearest = mob
                        end
                    end
                end

                return nearest
            end

            while running do
                local mob = getNearestSelected()
                if not mob then
                    task.wait(0.1)
                    continue
                end

                local humanoid = mob:FindFirstChildOfClass("Humanoid")
                local mhrp = mob:FindFirstChild("HumanoidRootPart")

                while humanoid and humanoid.Health > 0 and running do
                    local pos
                    if AutoFarmPosition == "Back" then
                        pos = mhrp.Position - mhrp.CFrame.LookVector * 5
                    elseif AutoFarmPosition == "Front" then
                        pos = mhrp.Position + mhrp.CFrame.LookVector * 5
                    elseif AutoFarmPosition == "Under" then
                        pos = mhrp.Position - Vector3.new(0, 5, 0)
                    elseif AutoFarmPosition == "Upper" then
                        pos = mhrp.Position + Vector3.new(0, 5, 0)
                    end

                    hrp.CFrame = CFrame.new(pos, mhrp.Position)
                    SkillRemote:FireServer(unpack(punchArgs))
                    task.wait(0.05)
                end

                punchArgs[1].Began = false
                SkillRemote:FireServer(unpack(punchArgs))
                punchArgs[1].Began = true
            end
        end)
    end
})

----------------------------------------------------------------
-- AUTOFARM SETTINGS
----------------------------------------------------------------
local SectionC = Tabs.Quests:AddSection("AutoFarm Settings")

Tabs.Quests:AddDropdown("AutoFarmTypeDropdown", {
    Title = "AutoFarm Type",
    Values = {"Mobs", "Boss"},
    Multi = false,
    Default = "Mobs",
    Callback = function(value)
        AutoFarmType = value
        SelectedMobName = nil
        NearestMobsDropdown:SetValues({})
        NearestMobsDropdown:SetValue(nil)
    end
})

Tabs.Quests:AddDropdown("AutoFarmPositionDropdown", {
    Title = "AutoFarm Position",
    Values = {"Under", "Front", "Back", "Upper"},
    Multi = false,
    Default = "Back",
    Callback = function(value)
        AutoFarmPosition = value
    end
})

local SectionD = Tabs.Worlds:AddSection("Main World")
Tabs.Worlds:AddButton({
    Title = "Join",
    Callback = function()
        game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_knit@1.4.7").knit.Services.PromptService.RE.Prompt:FireServer({["UniqueTag"] = "TeleporterGui",["Description"] = "Join World [Main World]?",["LeftButton"] = "Join",["Timer"] = 30,["Prompt"] = "TeleportDirect",["RightButton"] = "Cancel",["PlaceDataId"] = 1},"Join")
    end
})

local SectionE = Tabs.Worlds:AddSection("Crimson Planet")
Tabs.Worlds:AddButton({
    Title = "Join",
    Callback = function()
        game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_knit@1.4.7").knit.Services.PromptService.RE.Prompt:FireServer({["UniqueTag"] = "TeleporterGui",["Description"] = "Join World [Crimson Planet]?",["LeftButton"] = "Join",["Timer"] = 30,["Prompt"] = "TeleportDirect",["RightButton"] = "Cancel",["PlaceDataId"] = 2},"Join")
    end
})

local SectionF = Tabs.Worlds:AddSection("World Of Tournament")
Tabs.Worlds:AddButton({
    Title = "Join",
    Callback = function()
        game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_knit@1.4.7").knit.Services.PromptService.RE.Prompt:FireServer({["UniqueTag"] = "TeleporterGui",["Description"] = "Join World [World of Tournament]?",["LeftButton"] = "Join",["Timer"] = 30,["Prompt"] = "TeleportDirect",["RightButton"] = "Cancel",["PlaceDataId"] = 3},"Join")
    end
})

local SectionG = Tabs.Worlds:AddSection("Droid Planet")
Tabs.Worlds:AddButton({
    Title = "Join",
    Callback = function()
        game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_knit@1.4.7").knit.Services.PromptService.RE.Prompt:FireServer({["UniqueTag"] = "TeleporterGui",["Description"] = "Join World [Planet Droid]?",["LeftButton"] = "Join",["Timer"] = 30,["Prompt"] = "TeleportDirect",["RightButton"] = "Cancel",["PlaceDataId"] = 4},"Join")
    end
})

local SectionI = Tabs.Worlds:AddSection("Battleground")
Tabs.Worlds:AddButton({
    Title = "Join",
    Callback = function()
        game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_knit@1.4.7").knit.Services.PromptService.RE.Prompt:FireServer({["UniqueTag"] = "TeleporterGui",["Description"] = "Join World [Battlegrounds]?",["LeftButton"] = "Join",["Timer"] = 30,["Prompt"] = "TeleportDirect",["RightButton"] = "Cancel",["PlaceDataId"] = 5},"Join")
    end
})

local SectionJ = Tabs.Worlds:AddSection("AFK World")
Tabs.Worlds:AddButton({
    Title = "Join",
    Callback = function()
        game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_knit@1.4.7").knit.Services.PromptService.RE.Prompt:FireServer({["UniqueTag"] = "TeleporterGui",["Description"] = "Join World [AFK World]?",["LeftButton"] = "Join",["Timer"] = 30,["Prompt"] = "TeleportDirect",["RightButton"] = "Cancel",["PlaceDataId"] = 6},"Join")
    end
})

local SectionK = Tabs.Worlds:AddSection("Trade Hub")
Tabs.Worlds:AddButton({
    Title = "Join",
    Callback = function()
        game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_knit@1.4.7").knit.Services.PromptService.RE.Prompt:FireServer({["UniqueTag"] = "TeleporterGui",["Description"] = "Join World [Trade Hub]?",["LeftButton"] = "Join",["Timer"] = 30,["Prompt"] = "TeleportDirect",["RightButton"] = "Cancel",["PlaceDataId"] = 7},"Join")
    end
})
