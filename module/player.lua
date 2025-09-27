local Player = {}

-- Load Core module with error handling
local Core
local antiAFKConnection -- Store the connection reference

function Player:Init(core)
    if not core then
        error("Player:Init - Core module is required")
    end
    Core = core

    -- Store the connection so we can disconnect it later
    antiAFKConnection = Core.LocalPlayer.Idled:Connect(function()
        Core.VirtualUser:CaptureController()
        Core.VirtualUser:ClickButton2(Vector2.new())
        print("Anti-AFK: Clicked to prevent idle kick")
    end)
end

function Player:RemoveAntiAFK()
    -- Disconnect the stored connection
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
        print("Anti-AFK: Disconnected idle connection")
    else
        print("Anti-AFK: No connection to disconnect")
    end
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

function Player:UnequipTool()
    local Character = Core:GetCharacter()
    if not Character then 
        warn("Player:UnequipTool - Character not found")
        return false 
    end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then
        warn("Player:UnequipTool - Humanoid not found")
        return false
    end
    
    -- Try to unequip with error handling
    local success, err = pcall(function()
        Humanoid:UnequipTools()
    end)
    
    if not success then
        warn("Player:UnequipTool - Failed to unequip:", err)
        return false
    end
    
    return true
end

function Player:GetEquippedTool()
    local workspace = Core.Workspace
    local player

    for _, item in ipairs(workspace:GetChildren()) do
        if item.Name == Core.LocalPlayer.Name and item:FindFirstChildOfClass("Tool") then
            player = item
            break
        end
    end

    if not player then
        warn("Player:GetEquippedTool - Player model not found in workspace")
        return nil
    end

    for _, item in ipairs(player:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end

    warn("Player:GetEquippedTool - No tool equipped")
    return nil
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
    self:UnequipTool() -- Ensure no tool is equipped before fetching
    wait(0.5) -- Small delay to ensure state is updated
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
    
    return tools
end

function Player:GetTool(toolName)
    if not toolName or type(toolName) ~= "string" then
        warn("Player:GetTool - Invalid tool name")
        return nil
    end
    
    local Backpack = Core:GetBackpack()
    if not Backpack then 
        warn("Player:GetTool - Backpack not found")
        return nil 
    end
    
    local tool = nil
    local success, err = pcall(function()
        tool = Backpack:FindFirstChild(toolName)
        if tool and not tool:IsA("Tool") then
            tool = nil
        end
    end)
    
    if not success then
        warn("Player:GetTool - Error finding tool:", err)
        return nil
    end
    
    if not tool then
        warn("Player:GetTool - Tool not found:", toolName)
    end
    
    return tool
end

return Player