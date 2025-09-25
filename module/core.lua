local Core = {}

-- Services
Core.Players = game:GetService("Players")
Core.ReplicatedStorage = game:GetService("ReplicatedStorage")
Core.TeleportService = game:GetService("TeleportService")
Core.UserInputService = game:GetService("UserInputService")
Core.GuiService = game:GetService("GuiService")
Core.Workspace = game:GetService("Workspace")
Core.VirtualUser = game:GetService("VirtualUser")

-- Player reference
Core.LocalPlayer = Core.Players.LocalPlayer

-- References
Core.GameEvents = Core.ReplicatedStorage.GameEvents

-- Dynamic getters
function Core:GetCharacter()
    return self.LocalPlayer.Character
end

function Core:GetHumanoidRootPart()
    local character = self:GetCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

function Core:GetBackpack()
    return self.LocalPlayer:FindFirstChild("Backpack")
end

function Core:GetPlayerGui()
    return self.LocalPlayer:FindFirstChild("PlayerGui")
end

return Core