-- Main entry point
local EzUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/ez-rbx-ui/refs/heads/main/ui.lua'))()

-- Import modules
-- Load Core module with error handling
local Core = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/refs/heads/main/module/core.lua'))()
local PlayerUtils = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/refs/heads/main/module/player.lua'))()
local FarmUtils = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/grow-a-garden/refs/heads/main/grow-a-garden/module/farm.lua'))()
local PetUtils = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/grow-a-garden/refs/heads/main/grow-a-garden/module/pet.lua'))()
local PetUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/grow-a-garden/refs/heads/main/grow-a-garden/ui/pet.lua'))()

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

-- Initialize modules with dependencies
PlayerUtils:Init(Core)
FarmUtils:Init(Core, PlayerUtils)
PetUtils:Init(Core, PlayerUtils, FarmUtils)
PetUI:Init(window, PetUtils, FarmUtils)

-- Create UI
PetUI:CreatePetTab()