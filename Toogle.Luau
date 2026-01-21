--[=[
 d888b  db    db d888888b      .d888b.      db      db    db  .d8b.  
88' Y8b 88    88   `88'        VP  `8D      88      88    88 d8' `8b 
88      88    88    88            odD'      88      88    88 88ooo88 
88  ooo 88    88    88          .88'        88      88    88 88~~~88 
88. ~8~ 88b  d88   .88.        j88.         88booo. 88b  d88 88   88    @uniquadev
 Y888P  ~Y8888P' Y888888P      888888D      Y88888P ~Y8888P' YP   YP  CONVERTER 

designed using localmaze gui creator
]=]

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LMG2L = {}

LMG2L["ScreenGui_1"] = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
LMG2L["ScreenGui_1"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling

LMG2L["TextButton_2"] = Instance.new("TextButton", LMG2L["ScreenGui_1"])
LMG2L["TextButton_2"].TextWrapped = true
LMG2L["TextButton_2"].BorderSizePixel = 0
LMG2L["TextButton_2"].TextScaled = true
LMG2L["TextButton_2"].TextColor3 = Color3.fromRGB(255, 255, 255)
LMG2L["TextButton_2"].BackgroundColor3 = Color3.fromRGB(16, 16, 16)
LMG2L["TextButton_2"].FontFace = Font.new(
    "rbxasset://fonts/families/GothamSSm.json",
    Enum.FontWeight.Bold,
    Enum.FontStyle.Normal
)
LMG2L["TextButton_2"].AnchorPoint = Vector2.new(0.5, 0.5)
LMG2L["TextButton_2"].BackgroundTransparency = 0.2
LMG2L["TextButton_2"].Size = UDim2.new(0, 168, 0, 58)
LMG2L["TextButton_2"].Text = ""
LMG2L["TextButton_2"].Position = UDim2.new(0.5, 0, 0.1, 0)

LMG2L["UICorner_3"] = Instance.new("UICorner", LMG2L["TextButton_2"])
LMG2L["UICorner_3"].CornerRadius = UDim.new(0, 15)

-- 🔑 LeftShift simulation (MERGED)
LMG2L["TextButton_2"].MouseButton1Click:Connect(function()
    Fluent:Visible
end)

return LMG2L["ScreenGui_1"], require
