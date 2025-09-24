-- UI Components Module
local UIPet = {}
local window
local PetUtils
local FarmUtils
local EzUI

function UIPet:Init(windowInstance, petUtils, farmUtils, ezui)
    window = windowInstance
    PetUtils = petUtils
    FarmUtils = farmUtils
    EzUI = ezui
end

function UIPet:CreatePetTab()
    local petTab = window:AddTab({
        Name = "Pets",
        Icon = "🐾",
    })
    
    self:CreatePetTeamsSection(petTab)
    self:CreateEggsSection(petTab)
end

function UIPet:CreatePetTeamsSection(petTab)
    local accordionPetTeams = petTab:AddAccordion({
        Title = "Pet Teams",
        Icon = "💪",
        Expanded = false,
    })

    accordionPetTeams:AddLabel("Create and manage pet teams for different tasks.")
    
    local petTeamName = accordionPetTeams:AddTextBox({
        Name = "Team Name",
        Placeholder = "Enter team name example: exp, hatch, sell, etc...",
        Default = "",
    })

    accordionPetTeams:AddButton("Save Team", function()
        local teamName = petTeamName.GetText()
        if teamName and teamName ~= "" then
            print("Creating pet team:", teamName)
            PetUtils:SaveTeamPets(teamName)
            petTeamName.Clear()
        else
            print("Please enter a valid team name.")
        end
    end)

    accordionPetTeams:AddSeparator()

    accordionPetTeams:AddLabel("Select a pet team to set as core, change, or delete.")
    
    local selectTeam = accordionPetTeams:AddSelectBox({
        Name = "Select Pet Team",
        Options = PetUtils:GetAllPetTeams(),
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetUtils:GetAllPetTeams()
            local currentOptionsSet = {}
            
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })

    accordionPetTeams:AddButton("Set Core Team", function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            print("Setting core pet team to:", teamName)
            window:SetConfigValue("CorePetTeam", teamName)
        end    
    end)

    accordionPetTeams:AddButton("Change Team", function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            local petsInTeam = petTeamConfig.GetValue(teamName)

            if petsInTeam then
                print("Changing to pet team:", teamName)
                
                -- Deactivate all current active pets
                local activePets = PetUtils:GetActivePets(game.Players.LocalPlayer.Name)
                if activePets then
                    for petUUID, _ in pairs(activePets) do
                        print("Deactivating Active Pet:", petUUID)
                        PetUtils:UnequipPet(petUUID)
                    end
                end

                -- Activate pets in the selected team
                for _, petUUID in pairs(petsInTeam) do
                    print("Activating Pet from Team:", petUUID)
                    PetUtils:EquipPet(petUUID)
                end
            else
                print("No pets found in the selected team.")
            end
        else
            print("Please select a team to change to.")
        end    
    end)

    accordionPetTeams:AddButton("Delete Selected Team", function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            PetUtils:DeleteTeamPets(teamName)
            selectTeam.Clear()
        else
            print("Please select a team to delete.")
        end
    end)
end

function UIPet:CreateEggsSection(petTab)
    local accordionEggs = petTab:AddAccordion({
        Title = "Eggs",
        Icon = "🥚",
        Expanded = false,
    })

    accordionEggs:AddLabel("Select an egg to place in your farm.")
    
    local eggSelect = accordionEggs:AddSelectBox({
        Name = "Select Egg",
        Options = {"Loading..."},
        Placeholder = "Select Egg...",
        MultiSelect = false,
        Flag = "EggPlacing",
        OnInit = function(currentOptions, updateOptions, selectBoxAPI)
            local OwnedEggs = PetUtils:GetAllOwnedEggs()
            updateOptions(OwnedEggs)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local currentOptionsSet = {}
            local OwnedEggs = PetUtils:GetAllOwnedEggs()

            print("Owned Eggs Found:")
            for _, egg in pairs(OwnedEggs) do
                print("Found owned egg:", egg.text)
                table.insert(currentOptionsSet, {text = egg.text, value = egg.value})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })

    accordionEggs:AddLabel("Max Place Eggs")
    
    local maxPlaceEggs = accordionEggs:AddNumberBox({
        Name = "Max Place Eggs",
        Placeholder = "Enter max eggs...",
        Default = 0,
        Min = 0,
        Max = 13,
        Increment = 1,
        Flag = "MaxPlaceEggs",
    })

    accordionEggs:AddButton("Teleport to Back Corner", function()
        local backCorner = FarmUtils:GetBackCornerFarmPoint()
        print("Teleporting to back corner of farm at:", backCorner)
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(backCorner)
    end)

    accordionEggs:AddButton("Place Egg", function()
        local selectedEgg = eggSelect.GetSelected()
        local maxEggs = maxPlaceEggs.GetValue()

        if not selectedEgg or #selectedEgg == 0 then
            print("Please select an egg to place.")
            return
        end

        if not maxEggs or maxEggs <= 0 then
            print("Please enter a valid number for max eggs to place.")
            return
        end

        PetUtils:PlaceEgg(selectedEgg[1], maxEggs)
    end)

    accordionEggs:AddSeparator()

    accordionEggs:AddLabel("Team for Hatching Eggs")

    local selectTeamForHatch = accordionEggs:AddSelectBox({
        Name = "Select Pet Team for Hatch",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "HatchPetTeam",
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = window:GetConfigValue("PetTeamConfig") and window:GetConfigValue("PetTeamConfig").GetAllKeys() or {}
            local currentOptionsSet = {}
            
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })

    accordionEggs:AddSeparator()

    accordionEggs:AddLabel("Select Hatching Special Pet")
    local selectSpecialPet = accordionEggs:AddSelectBox({
        Name = "Select Special Pet",
        Options = {"Loading..."},
        Placeholder = "Select Special Pet...",
        MultiSelect = false,
        Flag = "SpecialHatchingPet",
        OnInit = function(currentOptions, updateOptions, selectBoxAPI)
            local specialPets = PetUtils:GetPetRegistry()
            updateOptions(specialPets)
        end
    })
    
    accordionEggs:AddLabel("Or If Weight is Higher Than")
    local weightThresholdSpecialHatchingInput = accordionEggs:AddNumberBox({
        Name = "Weight Threshold",
        Placeholder = "Enter weight...",
        Default = 0.0,
        Min = 0.0,
        Max = 20.0,
        Increment = 1.0,
        Decimals = 2,
        Flag = "WeightThresholdSpecialHatching",
    })

    accordionEggs:AddToggle({
        Name = "Auto Hatch Eggs",
        Default = false,
        Flag = "AutoHatchEggs",
    })

    accordionEggs:AddButton("Hatch All Ready Eggs", function()
        PetUtils:HatchEgg()
    end)
end

return UIPet