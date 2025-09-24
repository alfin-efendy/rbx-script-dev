local Player = {}

local Core = require(script.Parent.core) or loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/refs/heads/main/module/core.lua'))()

function Player:EquipTool(Tool)
    local Character = Core:GetCharacter()
    if not Character then return false end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    local Backpack = Core:GetBackpack()
    
    if not Humanoid or not Backpack or Tool.Parent ~= Backpack then return false end
    
    Humanoid:EquipTool(Tool)
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
    if not Backpack then return {} end
    
    local tools = {}
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item)
        end
    end
    return tools
end

return Player