-- Pet Utilities Module
local PetUtils = {}
local GameServices
local PlayerUtils
local FarmUtils
local PetTeamConfig
local Window
local AutoHatchConnection

function PetUtils:Init(gameServices, playerUtils, farmUtils, petTeamConfig, window)
    GameServices = gameServices
    PlayerUtils = playerUtils
    FarmUtils = farmUtils
    PetTeamConfig = petTeamConfig
    Window = window
    
    -- Auto Hatch Egg When Ready
    local EggReadyToHatchRemote = gameServices.GameEvents.EggReadyToHatch_RE
    AutoHatchConnection = EggReadyToHatchRemote.OnClientEvent:Connect(function(petName, eggUUID)
        print("🥚 Egg Ready to Hatch - Pet:", petName, "UUID:", eggUUID)
        
        local iSEnabledAutoHatch = Window:GetConfigValue("AutoHatchEggs") or false
        if not iSEnabledAutoHatch then
            print("Auto hatch is disabled in settings.")
            return
        end

        self:HatchEgg()
    end)
end

-- =========== Pets ==========
function PetUtils:RemoveAutoHatchConnection()
    if AutoHatchConnection then
        AutoHatchConnection:Disconnect()
        print("Auto Hatch connection removed.")
    else
        print("No Auto Hatch connection to remove.")
    end
end

function PetUtils:GetPetReplicationData()
    local ReplicationClass = require(GameServices.ReplicatedStorage.Modules.ReplicationClass)
    local ActivePetsReplicator = ReplicationClass.new("ActivePetsService_Replicator")
    return ActivePetsReplicator:YieldUntilData().Table
end

function PetUtils:GetPlayerPetData()
    local success, replicationData = pcall(self.GetPetReplicationData, self)
    if not success then
        warn("Failed to get replication data:", replicationData)
        return nil
    end
    
    local playerPetData = replicationData.PlayerPetData
    local playerData = playerPetData[GameServices.LocalPlayer.Name] or playerPetData[tonumber(GameServices.LocalPlayer.Name)]
    return playerData
end

function PetUtils:GetPetData(petUUID)
    local playerData = self:GetPlayerPetData()
    if playerData and playerData.PetInventory then
        return playerData.PetInventory.Data[petUUID]
    end
    return nil
end

function PetUtils:GetAllActivePets()
    local success, replicationData = pcall(function()
        return self:GetPetReplicationData()
    end)
    
    if not success then
        warn("Failed to get replication data:", replicationData)
        return nil
    end
    
    local activePetStates = replicationData.ActivePetStates
    local playerPets = activePetStates[GameServices.LocalPlayer.Name] or activePetStates[tonumber(playerName)]
    return playerPets
end

function PetUtils:BoostPet(petID)
    GameServices.GameEvents.PetBoostService:FireServer(
        "ApplyBoost",
        petID
    )
end

function PetUtils:BoostAllActivePets()
    local activePets = self:GetAllActivePets()
    if not activePets then
        print("No active pets found to boost.")
        return
    end

    local boostTool = {}

    for _, Tool in next, PlayerUtils:GetAllTools() do
        local toolType = Tool:GetAttribute("q")

        if toolType == "PASSIVE_BOOST" then
            table.insert(boostTool, Tool)
        end
    end
    
    if #boostTool == 0 then
        print("No boost tool found in inventory.")
        return
    end
    
    print("Using boost tool(s):", #boostTool)

    for _, Tool in next, boostTool do
        PlayerUtils:EquipTool(Tool)
        wait(0.1)
        for petUUID, _ in pairs(activePets) do
            print("Boosting Active Pet:", petUUID)
            self:BoostPet(petUUID)
            wait(0.5) -- Small delay to avoid spamming the server
        end
    end

    PlayerUtils:UnequipTool()
end


function PetUtils:EquipPet(PetID)
    GameServices.GameEvents.PetsService:FireServer(
        "EquipPet",
        PetID,
        FarmUtils:GetFarmCenterCFrame()
    )
end

function PetUtils:UnequipPet(PetID)
    GameServices.GameEvents.PetsService:FireServer(
        "UnequipPet",
        PetID
    )
end

function PetUtils:SaveTeamPets(teamName)
    local activePets = self:GetAllActivePets()

    if not activePets then
        print("No active pets found.")
        return
    end

    local listActivePets = {}
    for petUUID, petState in pairs(activePets) do
        table.insert(listActivePets, petUUID)
    end

    PetTeamConfig.SetValue(teamName, listActivePets)
end

function PetUtils:GetAllPetTeams()
    return PetTeamConfig.GetAllKeys()
end

function PetUtils:FindPetTeam(teamName)
    return PetTeamConfig.GetValue(teamName)
end

function PetUtils:DeleteTeamPets(teamName)
    PetTeamConfig.DeleteKey(teamName)
end

function PetUtils:ChangeToTeamPets(teamName)
    local petsInTeam = PetTeamConfig.GetValue(teamName)

    if not petsInTeam then
        print("No pets found in the team:", teamName)
        return
    end

    -- Deactivate all current active pets
    local activePets = self:GetAllActivePets(GameServices.LocalPlayer.Name)
    if activePets then
        for petUUID, _ in pairs(activePets) do
            print("Deactivating Active Pet:", petUUID)
            self:UnequipPet(petUUID)
        end
    end

    -- Activate pets in the selected team
    for _, petUUID in pairs(petsInTeam) do
        print("Activating Pet from Team:", petUUID)
        self:EquipPet(petUUID)
        wait(0.5) -- Small delay to avoid spamming the server
    end
end

function PetUtils:GetAllOwnedPets()
    local myPets = {}
    
    for _, Tool in next, PlayerUtils:GetAllTools() do
        local toolType = Tool:GetAttribute("b")
        toolType = toolType and string.lower(toolType) or ""
        if toolType == "l" then
            table.insert(myPets, {text = Tool.Name, value = Tool.Name})
        end
    end

    -- Sort pets alphabetically (ascending order)
    table.sort(myPets, function(a, b)
        return string.lower(a.text) < string.lower(b.text)
    end)

    return myPets
end

function PetUtils:GetPetDetail(petUUID)
    local success, result = pcall(function()
        local dataService = require(GameServices.ReplicatedStorage.Modules.DataService)
        local allData = dataService:GetData()
        
        if not allData then
            warn("No data available from DataService")
            return nil
        end
        
        local saveSlots = allData.SaveSlots
        if not saveSlots then
            warn("SaveSlots not found in data")
            return nil
        end

        print("Debug: SaveSlots keys:")
        print("SaveSlot totals:", #saveSlots.AllSlots, " last: ", saveSlots.SelectedSlot)
        
        local savedObjects = saveSlots.AllSlots[saveSlots.SelectedSlot].SavedObjects
        
        -- print("Debug: SavedObjects keys:")
        -- for key, value in pairs(savedObjects) do
        --     print("  Key:", key, "Type:", type(value))
        -- end

        if savedObjects and petUUID and savedObjects[petUUID] then
            return savedObjects[petUUID].Data
        end
        
        -- Fallback method
        warn("Falling back to ReplicationClass method")
        local ReplicationClass = require(GameServices.ReplicatedStorage.Modules.ReplicationClass)
        local DataStreamReplicator = ReplicationClass.new("DataStreamReplicator")
        DataStreamReplicator:YieldUntilData()
        
        local replicationData = DataStreamReplicator:YieldUntilData().Table
        local playerData = replicationData[GameServices.LocalPlayer.Name] or replicationData[tostring(GameServices.LocalPlayer.UserId)]
        
        print("Debug: Player Data Keys:")
        if playerData then
            for key, value in pairs(playerData) do
                print("  Key:", key, "Type:", type(value))
            end
        else
            print("  Player data is nil")
        end

        if playerData and playerData[petUUID] then
            return playerData[petUUID].Data
        end
        
        return nil
    end)
    
    if success then
        return result
    else
        warn("Failed to get pet data:", result)
        return nil
    end
end

function PetUtils:GetPetRegistry()
    local success, petRegistry = pcall(function()
        return require(GameServices.ReplicatedStorage.Data.PetRegistry)
    end)
    
    if success then           
        local petList = petRegistry.PetList
        
        if petList then
            local count = 0            
            -- Convert PetList to UI format {text = ..., value = ...}
            local formattedPets = {}
            for petName, petData in pairs(petList) do
                table.insert(formattedPets, {
                    text = petName,
                    value = petName
                })
            end
            
            -- Sort pets alphabetically (ascending order)
            table.sort(formattedPets, function(a, b)
                return string.lower(a.text) < string.lower(b.text)
            end)
                        
            return formattedPets
        else
            warn("PetUtils:GetPetRegistry - PetList is nil or not found")
            return {}
        end
    else
        warn("Failed to get pet registry:", petRegistry)
        return {}
    end
end

function PetUtils:SellPet()
    local petName = Window:GetConfigValue("PetToSell") or {}
    local weighLessThan = Window:GetConfigValue("WeightLessThan") or 0
    local ageLessThan = Window:GetConfigValue("AgeLessThan") or 0
    local sellPetTeam = Window:GetConfigValue("SellPetTeam") or nil
    local boostBeforeSelling = Window:GetConfigValue("AutoBoostBeforeSelling") or false
    local corePetTeam = Window:GetConfigValue("CorePetTeam") or nil


    if #petName == 0 then
        print("No pet selected for selling.")
        return
    end

    if weighLessThan <= 0 then
        print("Weight threshold must be greater than 0.")
        return
    end

    if ageLessThan <= 0 then
        print("Age threshold must be greater than 0.")
        return
    end

    if sellPetTeam then
        print("Changing to Sell Pet Team:", sellPetTeam)
        self:ChangeToTeamPets(sellPetTeam)
        wait(2) -- Wait 2 seconds to ensure pets are equipped
        
        if boostBeforeSelling then
            print("Auto boosting pets before selling...")
            self:BoostAllActivePets()
        else
            print("Auto boost before selling is disabled.")
        end
    end

    for _, Tool in next, PlayerUtils:GetAllTools() do
        local toolType = Tool:GetAttribute("b")
        local petUUID = Tool:GetAttribute("PET_UUID")
        local isFavorite = Tool:GetAttribute("d") or false

        if isFavorite then
            print("Skipping favorite pet:", Tool.Name)
            continue
        end

        if toolType == "l" and petUUID then
            local petData = self:GetPetData(petUUID)
            local petDetail = petData.PetData

            local petType = petData.PetType or "Unknown"
            local petWeight = petDetail.BaseWeight or 0
            local petAge = petDetail.Level or math.huge

            for _, selectedPet in ipairs(petName) do
                if petType == selectedPet and petWeight <= weighLessThan and petAge <= ageLessThan then
                    print("Selling Pet:", petType, "Weight:", petWeight, "Age:", petAge)

                    PlayerUtils:EquipTool(Tool)
                    wait(0.1)
                    local getEquippedTool = PlayerUtils:GetEquippedTool()
                    GameServices.GameEvents.SellPet_RE:FireServer(getEquippedTool)
                    wait(0.1) -- Small delay to avoid spamming the server
                end
            end
        end
    end

    if corePetTeam then
        wait(2) -- Wait 2 seconds to ensure pets are equipped
        print("Reverting to Core Pet Team:", corePetTeam)
        self:ChangeToTeamPets(corePetTeam)
        wait(2) -- Wait 2 seconds to ensure pets are equipped
    end
end

-- =========== Eggs ==========
function PetUtils:GetAllOwnedEggs()
    local myEggs = {}

    for _, Tool in next, PlayerUtils:GetAllTools() do
        local toolType = Tool:GetAttribute("b")
        toolType = toolType and string.lower(toolType) or ""
        if toolType == "c" then
            table.insert(myEggs, {text = Tool.Name, value = Tool:GetAttribute("h")})
        end
    end

    -- Sort eggs alphabetically (ascending order)
    table.sort(myEggs, function(a, b)
        return string.lower(a.text) < string.lower(b.text)
    end)

    return myEggs
end

function PetUtils:FindEggOwnedEgg(eggName)
    for _, Tool in next, PlayerUtils:GetAllTools() do
        local toolType = Tool:GetAttribute("b")
        local toolName = Tool:GetAttribute("h")
        
        toolType = toolType and string.lower(toolType) or ""
        toolName = toolName and string.lower(toolName) or ""

        if toolType == "c" and toolName == string.lower(eggName) then
            return Tool
        end
    end
    return nil
end

function PetUtils:GetPlacedEggDetail(eggUUID)
    local success, result = pcall(function()
        local dataService = require(GameServices.ReplicatedStorage.Modules.DataService)
        local allData = dataService:GetData()
        
        if not allData then
            warn("No data available from DataService")
            return nil
        end
        
        local saveSlots = allData.SaveSlots
        if not saveSlots then
            warn("SaveSlots not found in data")
            return nil
        end
        
        local savedObjects = saveSlots.AllSlots[saveSlots.SelectedSlot].SavedObjects
        
        if savedObjects and eggUUID and savedObjects[eggUUID] then
            return savedObjects[eggUUID].Data
        end
        
        -- Fallback method
        warn("Falling back to ReplicationClass method")
        local ReplicationClass = require(GameServices.ReplicatedStorage.Modules.ReplicationClass)
        local DataStreamReplicator = ReplicationClass.new("DataStreamReplicator")
        DataStreamReplicator:YieldUntilData()
        
        local replicationData = DataStreamReplicator:YieldUntilData().Table
        local playerData = replicationData[GameServices.LocalPlayer.Name] or replicationData[tostring(GameServices.LocalPlayer.UserId)]
        
        if playerData and playerData[eggUUID] then
            return playerData[eggUUID].Data
        end
        
        return nil
    end)
    
    if success then
        return result
    else
        warn("Failed to get egg data:", result)
        return nil
    end
end

function PetUtils:GetAllPlacedEggs()
    local placedEggs = {}
    local MyFarm = FarmUtils:GetMyFarm()

    if not MyFarm then
        warn("My farm not found!")
        return placedEggs
    end
    
    local objectsPhysical = MyFarm.Important.Objects_Physical
    if not objectsPhysical then
        warn("Objects_Physical not found!")
        return placedEggs
    end
    
    for _, egg in pairs(objectsPhysical:GetChildren()) do
        pcall(function()
            if egg.Name == "PetEgg" then
                local owner = egg:GetAttribute("OWNER")
                if owner == GameServices.LocalPlayer.Name then
                    table.insert(placedEggs, egg)
                end
            end
        end)
    end
    
    return placedEggs
end

function PetUtils:HatchEgg()
    local placedEggs = self:GetAllPlacedEggs()
    if #placedEggs == 0 then
        print("No placed eggs found to hatch.")
        return
    end

    local isAllEggsIsReady = true
    local eggsToHatch = {}
    
    for _, egg in pairs(placedEggs) do
        if egg.Name == "PetEgg" then
            local owner = egg:GetAttribute("OWNER")
            local timeToHatch = egg:GetAttribute("TimeToHatch")
            local eggName = egg:GetAttribute("EggName")
            
            if owner ~= GameServices.LocalPlayer.Name then
                continue
            end
            
            if timeToHatch and timeToHatch > 0 then
                warn("Egg not ready to hatch:", eggName, "Time left (s):", timeToHatch)
                isAllEggsIsReady = false
                break
            end
            
            table.insert(eggsToHatch, egg)
        end
    end
    
    if not isAllEggsIsReady then
        warn("Some eggs are not ready to hatch. Aborting hatch process.")
        return
    end
    
    if #eggsToHatch == 0 then
        print("No eggs are ready to hatch.")
        return
    end

    local hatchPetTeam = Window:GetConfigValue("HatchPetTeam") or nil
    local specialHatchPetTeam = Window:GetConfigValue("SpecialHatchPetTeam") or nil
    local specialHatchingPets = Window:GetConfigValue("SpecialHatchingPet") or {}
    local weightThresholdSpecialHatching = Window:GetConfigValue("WeightThresholdSpecialHatching") or math.huge
    local boostBeforeHatch = Window:GetConfigValue("AutoBoostBeforeHatch") or false

    print("HatchPetTeam:", hatchPetTeam)
    print("SpecialHatchPetTeam:", specialHatchPetTeam)
    print("SpecialHatchPets:", specialHatchingPets and table.concat(specialHatchingPets, ", ") or "None")
    print("WeightThresholdSpecialHatching:", weightThresholdSpecialHatching or "None")

    if hatchPetTeam then
        print("Changing to Hatch Pet Team:", hatchPetTeam)
        self:ChangeToTeamPets(hatchPetTeam)

        wait(2) -- Wait 2 seconds to ensure pets are equipped
        
        if boostBeforeHatch then
            print("Auto boosting pets before hatching...")
            self:BoostAllActivePets()
        else
            print("Auto boost before hatching is disabled.")
        end
    end
    
    local specialHatchingEgg = {}
    
    for _, egg in pairs(eggsToHatch) do
        local eggUUID = egg:GetAttribute("OBJECT_UUID")
        local eggData = self:GetPlacedEggDetail(eggUUID)
        local baseWeight = eggData and eggData.BaseWeight or 1
        local petName = eggData and eggData.Type or "Unknown"

        if #specialHatchingPets > 0 then
            local isSpecialPet = false

            for _, specialPet in ipairs(specialHatchingPets) do
                if petName == specialPet then
                    table.insert(specialHatchingEgg, egg)
                    isSpecialPet = true
                    break
                end
            end
            
            if isSpecialPet then
                print("Special hatching for pet:", petName)
                continue
            end
        end

        if baseWeight > weightThresholdSpecialHatching then
            print("Skipping egg due to weight limit:", petName, "Weight:", baseWeight)
            table.insert(specialHatchingEgg, egg)
            continue
        end
        
        print("Hatching egg:", eggName, "Pet:", petName, "Weight:", baseWeight)

        GameServices.GameEvents.PetEggService:FireServer(
                "HatchPet",
                egg
        )
    end


    if #specialHatchingEgg <= 0 then
        print("No special eggs to hatch.")
        return
    end

    if specialHatchPetTeam then
        print("Changing to Special Hatch Pet Team:", specialHatchPetTeam)
        self:ChangeToTeamPets(specialHatchPetTeam)
        wait(2) -- Wait 2 seconds to ensure pets are equipped
    end

    print("Hatching special eggs separately to avoid server spam.")
    
    for _, egg in pairs(specialHatchingEgg) do
        local eggUUID = egg:GetAttribute("OBJECT_UUID")
        local eggData = self:GetPlacedEggDetail(eggUUID)
        local baseWeight = eggData and eggData.BaseWeight or 1
        local petName = eggData and eggData.Type or "Unknown"
        print("Hatching special Pet:", petName, "Weight:", baseWeight)
        
        GameServices.GameEvents.PetEggService:FireServer(
                "HatchPet",
                egg
        )
        wait(2) -- Wait 2 seconds between each special egg hatch
    end

    wait(2) -- Wait 2 seconds to ensure all hatches are processed
    
    local isAutoSellAfterHatch = Window:GetConfigValue("AutoSellPetsAfterHatching") or false
    local corePetTeam = Window:GetConfigValue("CorePetTeam") or nil
    
    if not isAutoSellAfterHatch then
        self:SellPet()
    end
    
    self:ChangeToTeamPets(corePetTeam)
    self:PlaceEgg()
end

function PetUtils:PlaceEgg(position)
    local eggName = Window:GetConfigValue("EggPlacing") or ""
    local maxEggs = Window:GetConfigValue("MaxPlaceEggs") or 0
    
    if eggName == "" then
        print("No egg selected for placing.")
        return
    end
    
    local totalPlacedEggs = #self:GetAllPlacedEggs()
    local availableSlots = maxEggs - totalPlacedEggs
    
    if availableSlots <= 0 then
        print("You have reached the maximum number of placed eggs:", maxEggs)
        return
    end

    print("Placing egg:", eggName)
    
    local eggOwnedName = self:FindEggOwnedEgg(eggName)

    if not eggOwnedName then
        print("You do not own any more eggs of type:", eggName)
        return
    end

    PlayerUtils:EquipTool(eggOwnedName)
    for i = 1, availableSlots do
        -- Retry logic for placing egg with more spacing
        local success = false
        local maxRetries = 5
        local retryCount = 0
        
        -- Increase spacing between eggs
        while not success and retryCount < maxRetries do
            local randomPoint = FarmUtils:GetRandomFarmPoint()

            local result, errorMessage = pcall(function()
                GameServices.GameEvents.PetEggService:FireServer(
                    "CreateEgg",
                    randomPoint
                )
            end)
            
            if result then
                success = true
                print("✅ Placed egg at:", randomPoint)
                PlayerUtils:TeleportToPosition(randomPoint) -- Teleport player above the placed egg
            else
                warn("Error placing egg:", errorMessage)
                retryCount = retryCount + 1
                warn("Failed to place egg, retry", retryCount, "/", maxRetries)
                if retryCount < maxRetries then
                    wait(1) -- Wait before retry
                end
            end
        end
        
        if not success then
            warn("Failed to place egg after", maxRetries, "attempts at position:", randomPoint)
        end

        wait(0.5)
    end

    PlayerUtils:UnequipTool() -- Unequip the egg tool after placing
end

return PetUtils