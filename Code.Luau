local Library = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB | Dragon Blox" .. Fluent.Version,
    SubTitle = "by Ange",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 330),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

Fluent:Notify({
        Title = "Loaded!",
        Content = "Angel Hub has succesfully been loaded!",
        SubContent = nil, -- Optional
        Duration = 5 -- Set to nil to make the notification not disappear
})

-- Fluent provides Lucide Icons, they are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Quests = Window:AddTab({ Title = "Quests", Icon = "circle-question-mark" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

local Section = Tabs.Main:AddSection("Train")

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


local Section = Tabs.Quests:AddSection("Mark")

local SelectedQuestId = 2

local MobDropdown = Tabs.Quests:AddDropdown("MobDropdown", {
    Title = "Select Mob",
    Values = {
        "Bandit",
        "Mad Bandit",
        "Evil Thugs",
        "Tigreal Tribe",
        "Gorillaz Tribe"
    },
    Default = 1,
    Multi = false,
    Callback = function(value)
        if value == "Bandit" then
            SelectedQuestId = 2
        elseif value == "Mad Bandit" then
            SelectedQuestId = 7
        elseif value == "Evil Thugs" then
            SelectedQuestId = 12
        elseif value == "Tigreal Tribe" then
            SelectedQuestId = 17
        elseif value == "Gorillaz Tribe" then
            SelectedQuestId = 22
        end
    end
})

local TakeQuestButton = Tabs.Quests:AddButton({
    Title = "Take Quest",
    Callback = function()
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        -- save current position
        local originalCFrame = hrp.CFrame

        local npc = workspace:WaitForChild("Misc")
            :WaitForChild("NPC")
            :WaitForChild("Quests")
            :WaitForChild("QuestNPCMain1_WestCity")

        -- teleport to NPC head
        hrp.CFrame = npc.Head.CFrame * CFrame.new(0, 0, -3)

        -- wait a short moment to make sure the game registers the teleport
        task.wait(0.2)

        -- take quest
        local args = {
            "NPCQuest_WestCity",
            SelectedQuestId,
            npc
        }

        game:GetService("ReplicatedStorage")
            :WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_knit@1.4.7")
            :WaitForChild("knit")
            :WaitForChild("Services")
            :WaitForChild("DialogService")
            :WaitForChild("RF")
            :WaitForChild("Answer")
            :InvokeServer(unpack(args))

        -- wait 1 second then return to original position
        task.wait(0.75)
        hrp.CFrame = originalCFrame
    end
})
