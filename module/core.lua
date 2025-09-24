local Core = {}

Core.Players = game:GetService("Players")
Core.ReplicatedStorage = game:GetService("ReplicatedStorage")
Core.TeleportService = game:GetService("TeleportService")
Core.UserInputService = game:GetService("UserInputService")
Core.GuiService = game:GetService("GuiService")
Core.Workspace = game:GetService("Workspace")

Core.LocalPlayer = Core.Players.LocalPlayer
Core.PlayerGui = Core.LocalPlayer:WaitForChild("PlayerGui")
Core.Character = Core.LocalPlayer.Character or Core.LocalPlayer.CharacterAdded:Wait()
Core.Backpack = Core.LocalPlayer:WaitForChild("Backpack")

return Core