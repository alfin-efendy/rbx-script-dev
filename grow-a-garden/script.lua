-- Main entry point
local EzUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/ez-rbx-ui/refs/heads/main/ui.lua'))()

-- Import local modules
local Core = require('../module/core.lua')
local PlayerUtils = require('../module/player.lua')
local FarmUtils = require('module/farm.lua')
local PetUtils = require('module/pet.lua')
local PetUI = require('ui/pet.lua')
local ShopModule = require('module/shop.lua')
local ShopUI = require('ui/shop.lua')

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
	print("window is closing! Performing cleanup...")
	
    -- Remove Anti-AFK connections
    PlayerUtils:RemoveAntiAFK()
    
    -- Remove Auto Hatch connection
    PetUtils:RemoveAutoHatchConnection()

    -- Stop all Shop automation
    ShopModule:StopAllAutomation()
	
	print("Cleanup completed!")
end)

-- Wait load config
wait(1) -- Ensure config is loaded

-- Initialize modules with dependencies
PlayerUtils:Init(Core)
FarmUtils:Init(Core, PlayerUtils)
PetUtils:Init(Core, PlayerUtils, FarmUtils, EzUI.NewConfig("PetTeamConfig"), window)
PetUI:Init(window, PetUtils, FarmUtils)

-- Shop
ShopModule:Init(Core, PlayerUtils, window)
ShopUI:Init(window, ShopModule)

-- Create UI
PetUI:CreatePetTab()
ShopUI:CreateShopTab()