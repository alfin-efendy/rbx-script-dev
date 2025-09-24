local Player = {}

-- Load Core module with error handling
local Core
local success, result = pcall(function()
    return require(script.Parent.core)
end)

if not success then
    Core = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/refs/heads/main/module/core.lua'))()
else
    Core = result
end

function Player:EquipTool(Tool)
    -- Validate inputs
    if not Tool or not Tool:IsA("Tool") then 
        warn("Player:EquipTool - Invalid tool provided")
        return false 
    end
    
    local Character = Core:GetCharacter()
    if not Character then 
        warn("Player:EquipTool - Character not found")
        return false 
    end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    local Backpack = Core:GetBackpack()
    
    if not Humanoid then
        warn("Player:EquipTool - Humanoid not found")
        return false
    end
    
    if not Backpack then
        warn("Player:EquipTool - Backpack not found")
        return false
    end
    
    if Tool.Parent ~= Backpack then 
        warn("Player:EquipTool - Tool not in backpack")
        return false 
    end
    
    -- Try to equip with error handling
    local success, err = pcall(function()
        Humanoid:EquipTool(Tool)
    end)
    
    if not success then
        warn("Player:EquipTool - Failed to equip:", err)
        return false
    end
    
    return true
end

function Player:TeleportToPosition(Position)
    local HRP = Core:GetHumanoidRootPart()
    if HRP then
        HRP.CFrame = CFrame.new(Position)
        return true
    end
    return false
end

function Player:GetPosition()
    local HRP = Core:GetHumanoidRootPart()
    return HRP and HRP.Position or Vector3.new(0, 0, 0)
end

function Player:GetAllTools()
    local Backpack = Core:GetBackpack()
    if not Backpack then 
        warn("Player:GetAllTools - Backpack not found")
        return {} 
    end
    
    local tools = {}
    local success, err = pcall(function()
        for _, item in ipairs(Backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end)
    
    if not success then
        warn("Player:GetAllTools - Error getting tools:", err)
        return {}
    end
    
    print("Player:GetAllTools - Found", #tools, "tools")
    return tools
end

-- Debug function to test if module is working
function Player:Test()
    print("Player module loaded successfully!")
    print("Core module:", Core and "OK" or "FAILED")
    print("LocalPlayer:", Core.LocalPlayer and Core.LocalPlayer.Name or "NOT FOUND")
    local character = Core:GetCharacter()
    print("Character:", character and character.Name or "NOT FOUND")
    local backpack = Core:GetBackpack()
    print("Backpack:", backpack and "OK" or "NOT FOUND")
    return true
end

return Player