local Core = {}

local EzUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/ez-rbx-ui/refs/heads/main/ui.lua'))()

Core.UI = EzUI

Core.Players = game:GetService("Players")
Core.ReplicatedStorage = game:GetService("ReplicatedStorage")
Core.TeleportService = game:GetService("TeleportService")
Core.UserInputService = game:GetService("UserInputService")
Core.GuiService = game:GetService("GuiService")
Core.Workspace = game:GetService("Workspace")

Core.LocalPlayer = Players.LocalPlayer
Core.PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
Core.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
Core.Backpack = LocalPlayer:WaitForChild("Backpack")

return Core