-- Main entry point
local EzUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/ez-rbx-ui/refs/heads/main/ui.lua'))()

-- Import local modules
local Core = require('../module/core.lua')
local PlayerUtils = require('../module/player.lua')
local FarmUtils = require('module/farm.lua')
local PetUtils = require('module/pet.lua')
local PetUI = require('ui/pet.lua')

-- Initialize window
local window = EzUI.CreateWindow({
    Name = "EzGarden",
    Width = 700,
    Height = 400,
    Opacity = 0.9,
    AutoAdapt = true,
    AutoShow = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EzGarden",
        FileName = "settings",
        AutoLoad = true,
        AutoSave = true,
    },
})

window:SetCloseCallback(function()
	print("Window is closing! Performing cleanup...")
	
    -- Remove Anti-AFK connections
    PlayerUtils:RemoveAntiAFK()
    
    -- Remove Auto Hatch connection
    PetUtils:RemoveAutoHatchConnection()
	
	print("Cleanup completed!")
end)

-- Initialize modules with dependencies
PlayerUtils:Init(Core)
FarmUtils:Init(Core, PlayerUtils)
PetUtils:Init(Core, PlayerUtils, FarmUtils, EzUI.NewConfig("PetTeamConfig"), window)
PetUI:Init(window, PetUtils, FarmUtils)

-- Create UI
PetUI:CreatePetTab()