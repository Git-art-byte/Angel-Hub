-- Toogle.Luau
local LMG2L = {}

LMG2L["ScreenGui_1"] = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
LMG2L["ScreenGui_1"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling

LMG2L["VisibilityToogle"] = Instance.new("TextButton", LMG2L["ScreenGui_1"])
LMG2L["VisibilityToogle"].TextWrapped = true
LMG2L["VisibilityToogle"].BorderSizePixel = 0
LMG2L["VisibilityToogle"].TextScaled = true
LMG2L["VisibilityToogle"].TextColor3 = Color3.fromRGB(255, 255, 255)
LMG2L["VisibilityToogle"].BackgroundColor3 = Color3.fromRGB(39, 39, 39)
LMG2L["VisibilityToogle"].FontFace = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
LMG2L["VisibilityToogle"].BackgroundTransparency = 0.17
LMG2L["VisibilityToogle"].Size = UDim2.new(0, 76, 0, 40)
LMG2L["VisibilityToogle"].Text = [[]]
LMG2L["VisibilityToogle"].Position = UDim2.new(0.45, 0, 0, 0)

local UICorner = Instance.new("UICorner", LMG2L["VisibilityToogle"])
UICorner.CornerRadius = UDim.new(0, 12)

-- RETURN the button so the main script can use it
return LMG2L["VisibilityToogle"]
