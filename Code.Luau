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
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    AutoFarm = Window:AddTab({ Title = "AutoFarm", Icon = "badge-info" }),
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

Tabs.Main:AddDropdown("SkillDropdown", {
    Title = "Training Type",
    Values = {"Punch", "Durability", "Ki"},
    Default = 1,
    Callback = function(value)
        SelectedSkillId = (value == "Punch" and "1") or (value == "Durability" and "6") or "2"
    end
})

Tabs.Main:AddToggle("TrainToggle", {
    Title = "Train",
    Default = false,
    Callback = function(state)
        TrainEnabled = state
        if state then
            task.spawn(function()
                while TrainEnabled do
                    game:GetService("ReplicatedStorage")
                        :WaitForChild("Remotes")
                        :WaitForChild("SkillRemote")
                        :FireServer({
                            {
                                Camera = CFrame.new(-58.7225,85.5203,-374.1244),
                                SkillId = SelectedSkillId,
                                Began = true,
                                CFrame = CFrame.new(-58.1394,72.9504,-374.5310),
                                ["Typ\208\181"] = 1,
                                Aim = vector.create(-50.9456,23.7233,-379.5251)
                            }
                        })
                    task.wait()
                end
            end)
        end
    end
})

----------------------------------------------------------------
-- AUTOFARM
----------------------------------------------------------------
local SectionB = Tabs.AutoFarm:AddSection("Evee")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mobsFolder = workspace["World Mobs"].Mobs
local SelectedMobName = nil
local running = false

local NearestMobsDropdown = Tabs.AutoFarm:AddDropdown("NearestMobsDropdown", {
    Title = "Select Mob",
    Values = {},
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedMobName = value
    end
})

local function updateNearestMobs()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local mobs, added = {}, {}

    for _, mob in ipairs(mobsFolder:GetChildren()) do
        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
            table.insert(mobs, {
                Name = mob.Name,
                Distance = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
            })
        end
    end

    table.sort(mobs, function(a,b) return a.Distance < b.Distance end)

    local values = {}
    for _, mob in ipairs(mobs) do
        if not added[mob.Name] then
            added[mob.Name] = true
            table.insert(values, mob.Name)
        end
    end

    NearestMobsDropdown:SetValues(values)
end

task.spawn(function()
    while true do
        updateNearestMobs()
        task.wait(0.7)
    end
end)

Tabs.AutoFarm:AddToggle("AutoFarmToggle", {
    Title = "AutoFarm Mob",
    Default = false,
    Callback = function(state)
        running = state
        if not state then return end

        task.spawn(function()
            local SkillRemote = game:GetService("ReplicatedStorage")
                :WaitForChild("Remotes")
                :WaitForChild("SkillRemote")

            local punchArgs = {
                {
                    Camera = CFrame.new(-58.7225,85.5203,-374.1244),
                    SkillId = "1",
                    Began = true,
                    CFrame = CFrame.new(-58.1394,72.9504,-374.5310),
                    ["Typ\208\181"] = 1,
                    Aim = Vector3.new(-50.9456,23.7233,-379.5251)
                }
            }

            while running do
                if not SelectedMobName then
                    task.wait(0.1)
                    continue
                end

                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then task.wait(0.1) continue end

                local nearest, dist = nil, math.huge
                for _, mob in ipairs(mobsFolder:GetChildren()) do
                    if mob.Name == SelectedMobName and mob:FindFirstChild("HumanoidRootPart") then
                        local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if d < dist then
                            dist = d
                            nearest = mob
                        end
                    end
                end

                if nearest then
                    local mobHRP = nearest.HumanoidRootPart
local behindPos = mobHRP.Position - (mobHRP.CFrame.LookVector * 5)

hrp.CFrame = CFrame.new(behindPos, mobHRP.Position)
                    SkillRemote:FireServer(unpack(punchArgs))
                end

                task.wait(0.05)
            end

            punchArgs[1].Began = false
            SkillRemote:FireServer(unpack(punchArgs))
        end)
    end
})
