local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB | Dragon Ball: Legendary Forces" .. Fluent.Version,
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
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

AUTOFARM
----------------------------------------------------------------
local SectionB = Tabs.Quests:AddSection("AutoFarm")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local SelectedMobName = nil
local running = false
local AutoFarmPosition = "Back"
local AutoFarmType = "Mobs"

-- Nearest Mob / Boss Dropdown
local NearestMobsDropdown = Tabs.Main:AddDropdown("NearestMobsDropdown", {
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
    elseif AutoFarmType == "Event" then
        return workspace["World Mobs"]["Event Mobs"]
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
Tabs.Main:AddToggle("AutoFarmToggle", {
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
local SectionC = Tabs.Main:AddSection("AutoFarm Settings")

Tabs.Main:AddDropdown("AutoFarmPositionDropdown", {
    Title = "AutoFarm Position",
    Values = {"Under", "Front", "Back", "Upper"},
    Multi = false,
    Default = "Back",
    Callback = function(value)
        AutoFarmPosition = value
    end
})
