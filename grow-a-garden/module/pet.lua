-- Pet Utilities Module
local PetUtils = {}
local GameServices
local PlayerUtils
local FarmUtils
local PetTeamConfig

function PetUtils:Init(gameServices, playerUtils, farmUtils, petTeamConfig)
    GameServices = gameServices
    PlayerUtils = playerUtils
    FarmUtils = farmUtils
    PetTeamConfig = petTeamConfig
end

function PetUtils:GetPetReplicationData()
    local ReplicationClass = require(GameServices.ReplicatedStorage.Modules.ReplicationClass)
    local ActivePetsReplicator = ReplicationClass.new("ActivePetsService_Replicator")
    ActivePetsReplicator:YieldUntilData()
    return ActivePetsReplicator:YieldUntilData().Table
end

-- =========== Pets ==========
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

function PetUtils:EquipPet(PetID)
    GameServices.ReplicatedStorage.GameEvents.PetsService:FireServer(
        "EquipPet",
        PetID,
        FarmUtils:GetFarmCenterCFrame()
    )
end

function PetUtils:UnequipPet(PetID)
    GameServices.ReplicatedStorage.GameEvents.PetsService:FireServer(
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
        
        local savedObjects = saveSlots.AllSlots[saveSlots.SelectedSlot].SavedObjects
        
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

function GetPetRegistry()
    local success, petRegistry = pcall(function()
        return require(ReplicatedStorage.Data.PetRegistry)
    end)
    
    if success then
        return petRegistry.PetList
    else
        warn("Failed to get pet registry:", petRegistry)
        return {}
    end
end

-- =========== Eggs ==========
function PetUtils:GetAllOwnedEggs()
    local myEggs = {}

    for _, Tool in next, PlayerUtils:GetAllTools() do
        local toolType = Tool:GetAttribute("b")
        toolType = toolType and string.lower(toolType) or ""
        if toolType == "c" then
            table.insert(myEggs, {text = Tool.Name, value = Tool.Name})
        end
    end

    return myEggs
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

    for _, egg in pairs(placedEggs) do
        pcall(function()
            if egg.Name == "PetEgg" then
                local owner = egg:GetAttribute("OWNER")
                local timeToHatch = egg:GetAttribute("TimeToHatch")
                local eggName = egg:GetAttribute("EggName")
                local eggUUID = egg:GetAttribute("OBJECT_UUID")

                if owner == GameServices.LocalPlayer.Name and eggUUID and timeToHatch == 0 then
                    local eggData = self:GetPlacedEggDetail(eggUUID)
                    local baseWeight = eggData and eggData.BaseWeight or 1
                    local petName = eggData and eggData.Type or "Unknown"

                    print("Hatching egg:", eggName, "Pet:", petName, "Weight:", baseWeight)

                    GameServices.ReplicatedStorage.GameEvents.PetEggService:FireServer(
                        "HatchPet",
                        egg
                    )
                end
            end
        end)
    end
end

function PetUtils:PlaceEgg(eggName, maxEggs)
    print("Attempting to place up to", maxEggs, "eggs.")
    local totalPlacedEggs = #self:GetAllPlacedEggs()
    local availableSlots = maxEggs - totalPlacedEggs
    
    if availableSlots <= 0 then
        print("You have reached the maximum number of placed eggs:", maxEggs)
        return
    end
    
    print("Placing egg:", eggName)
    
    local startPosition = FarmUtils:GetBackCornerFarmPoint()
    for i = 1, availableSlots do
        local eggTool = PlayerUtils:GetTool(eggName)
        if eggTool then
            PlayerUtils:EquipTool(eggTool)
        end
        
        local offsetX = (i - 1) * 1
        local randomPoint = Vector3.new(startPosition.X + offsetX, startPosition.Y, startPosition.Z)
        
        GameServices.ReplicatedStorage.GameEvents.PetEggService:FireServer(
            "CreateEgg",
            randomPoint
        )

        print("✅ Placed egg at:", randomPoint)
        wait(0.5)
    end
end

return PetUtils