--[=[
 d888b  db    db d888888b      .d888b.      db      db    db  .d8b.  
88' Y8b 88    88   `88'        VP  `8D      88      88    88 d8' `8b 
88      88    88    88            odD'      88      88    88 88ooo88 
88  ooo 88    88    88          .88'        88      88    88 88~~~88 
88. ~8~ 88b  d88   .88.        j88.         88booo. 88b  d88 88   88    @uniquadev
 Y888P  ~Y8888P' Y888888P      888888D      Y88888P ~Y8888P' YP   YP  CONVERTER 

designed using localmaze gui creator
]=]

local LMG2L = {};

LMG2L["ScreenGui_1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"));
LMG2L["ScreenGui_1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;


LMG2L["Visibility Toogle_2"] = Instance.new("TextButton", LMG2L["ScreenGui_1"]);
LMG2L["Visibility Toogle_2"]["TextWrapped"] = true;
LMG2L["Visibility Toogle_2"]["BorderSizePixel"] = 0;
LMG2L["Visibility Toogle_2"]["TextScaled"] = true;
LMG2L["Visibility Toogle_2"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
LMG2L["Visibility Toogle_2"]["BackgroundColor3"] = Color3.fromRGB(39, 39, 39);
LMG2L["Visibility Toogle_2"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
LMG2L["Visibility Toogle_2"]["BackgroundTransparency"] = 0.15;
LMG2L["Visibility Toogle_2"]["Size"] = UDim2.new(0, 76, 0, 40);
LMG2L["Visibility Toogle_2"]["Text"] = [[]];
LMG2L["Visibility Toogle_2"]["Name"] = [[Visibility Toogle]];
LMG2L["Visibility Toogle_2"]["Position"] = UDim2.new(0, 8, 0, 22);


LMG2L["UICorner_3"] = Instance.new("UICorner", LMG2L["Visibility Toogle_2"]);
LMG2L["UICorner_3"]["CornerRadius"] = UDim.new(0, 12);



return LMG2L["ScreenGui_1"], require;
