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
    Quests = Window:AddTab({ Title = "AutoFarm", Icon = "badge-info" }),
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
local SectionB = Tabs.Quests:AddSection("Evee")

local SelectedMobName = nil
Tabs.Quests:AddDropdown("NearestMobsDropdown", {
    Title = "Select Mob",
    Values = {},
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedMobName = value
    end
})

local running = false
Tabs.Quests:AddToggle("AutoFarmToggle", {
    Title = "AutoFarm Mob",
    Default = false,
    Callback = function(state)
        running = state
        if not state then return end

        if not SelectedMobName then
            Fluent:Notify({
                Title = "AutoFarm",
                Content = "Select a mob first.",
                Duration = 3
            })
            running = false
            return
        end

        task.spawn(function()
            local playerHRP = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
            local SkillRemote = game:GetService("ReplicatedStorage").Remotes.SkillRemote

            local punchArgs = {
                {
                    SkillId = "1",
                    Began = true,
                    ["Typ\208\181"] = 1
                }
            }

            local function getNearestSelectedMob()
                local nearest, dist = nil, math.huge
                for _, mob in ipairs(workspace["World Mobs"].Mobs:GetChildren()) do
                    if mob.Name == SelectedMobName and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") then
                        local humanoid = mob:FindFirstChildOfClass("Humanoid")
                        if humanoid.Health > 0 then
                            local d = (playerHRP.Position - mob.HumanoidRootPart.Position).Magnitude
                            if d < dist then
                                dist = d
                                nearest = mob
                            end
                        end
                    end
                end
                return nearest
            end

            while running do
                local mob = getNearestSelectedMob()
                if not mob then
                    task.wait(0.1)
                    continue
                end

                local humanoid = mob:FindFirstChildOfClass("Humanoid")
                while humanoid and humanoid.Health > 0 and running do
                    local mhrp = mob.HumanoidRootPart
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

                    playerHRP.CFrame = CFrame.new(pos, mhrp.Position)
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

local SectionC = Tabs.Quests:AddSection("AutoFarm Settings")

AutoFarmPosition = "Back"
Tabs.Quests:AddDropdown("AutoFarmPositionDropdown", {
    Title = "AutoFarm Position",
    Values = {"Under", "Front", "Back", "Upper"},
    Multi = false,
    Default = "Back",
    Callback = function(value)
        AutoFarmPosition = value
    end
})
