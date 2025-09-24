local Player = {}

local Core = require(script.Parent.core) or loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/refs/heads/main/module/core.lua'))()

function Player:EquipTool(Tool)
    local Character = LocalPlayer.Character
    local Humanoid = Character.Humanoid

    if Tool.Parent ~= Backpack then return end
    Humanoid:EquipTool(Tool)
end

function Player:TeleportToPosition(Position)
     local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        Character.HumanoidRootPart.CFrame = CFrame.new(Position)
    end
end

function Player:GetPosition()
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        return Character.HumanoidRootPart.Position
    end
    return Vector3.new(0, 0, 0)
end

function Player:GetAllTools()
    local tools = {}
    for _, item in ipairs(Backpack:GetChildren()) do
        table.insert(tools, item)
    end
    return tools
end

return Player