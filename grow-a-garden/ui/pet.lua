-- UI Components Module
local UIPet = {}
local window
local PetUtils
local FarmUtils

function UIPet:Init(windowInstance, petUtils, farmUtils)
    window = windowInstance
    PetUtils = petUtils
    FarmUtils = farmUtils
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

    -- Declare labelCoreTeam variable first (forward declaration)
    local labelCoreTeam

    accordionPetTeams:AddButton("Set Core Team", function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            window:SetConfigValue("CorePetTeam", teamName)
            labelCoreTeam.SetText("Current Core Team: " .. teamName)
        end    
    end)

    -- Create the label after the button
    labelCoreTeam = accordionPetTeams:AddLabel("Current Core Team: " .. (window:GetConfigValue("CorePetTeam") or "None"))

    accordionPetTeams:AddSeparator()

    accordionPetTeams:AddButton("Change Team", function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            local petsInTeam = PetUtils:FindPetTeam(teamName)

            if petsInTeam then
                print("Changing to pet team:", teamName)
                
                -- Deactivate all current active pets
                local activePets = PetUtils:GetAllActivePets()
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

    accordionEggs:AddButton("Place Selected Egg", function()
        PetUtils:PlaceEgg()    
    end)

    accordionEggs:AddSeparator()

    accordionEggs:AddLabel("Team for Hatching Eggs")

    local selectTeamForHatch = accordionEggs:AddSelectBox({
        Name = "Select Pet Team for Hatch",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "HatchPetTeam",
        OnInit = function(currentOptions, updateOptions)
            local listTeamPet = PetUtils:GetAllPetTeams()
            local currentOptionsSet = {}

            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            updateOptions(currentOptionsSet)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetUtils:GetAllPetTeams()
            local currentOptionsSet = {}
            
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })

    accordionEggs:AddToggle({
        Name = "Auto Boost Pets Before Hatching",
        Default = false,
        Flag = "AutoBoostBeforeHatch",
    })

    accordionEggs:AddSeparator()

    accordionEggs:AddLabel("Select Hatching Special Pet")
    local selectSpecialPet = accordionEggs:AddSelectBox({
        Name = "Select Special Pet",
        Options = {"Loading..."},
        Placeholder = "Select Special Pet...",
        MultiSelect = true,
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

    accordionEggs:AddLabel("Select Team for Special Hatching")
    local selectTeamForSpecialHatch = accordionEggs:AddSelectBox({
        Name = "Select Pet Team for Special Hatch",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "SpecialHatchPetTeam",
        OnInit = function(currentOptions, updateOptions)
            local listTeamPet = PetUtils:GetAllPetTeams()
            local currentOptionsSet = {}

            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            updateOptions(currentOptionsSet)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetUtils:GetAllPetTeams()
            local currentOptionsSet = {}

            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            updateOptions(currentOptionsSet)
        end
    })

    accordionEggs:AddToggle({
        Name = "Auto Boost Pets Before Special Hatching",
        Default = false,
        Flag = "AutoBoostBeforeSpecialHatch",
    })

    accordionEggs:AddSeparator()

    local toggleAutoHatch = accordionEggs:AddToggle({
        Name = "Auto Hatch Eggs",
        Default = false,
        Flag = "AutoHatchEggs",
        Callback = function(value)
            if value then
                PetUtils:QueueHatchRequest()
            end
        end
    })

    local accordionSellPets = petTab:AddAccordion({
        Title = "Sell Pets",
        Icon = "💰",
        Expanded = false,
    })

    accordionSellPets:AddLabel("Select a pet to sell.")
    local selectPetToSell = accordionSellPets:AddSelectBox({
        Name = "Select Pet to Sell",
        Options = {"Loading..."},
        Placeholder = "Select Pet...",
        MultiSelect = true,
        Flag = "PetToSell",
        OnInit = function(currentOptions, updateOptions, selectBoxAPI)
            local specialPets = PetUtils:GetPetRegistry()
            updateOptions(specialPets)
        end,
    })

    accordionSellPets:AddLabel("And If Base Weight Is Less Than Or Equal")
    local weightThresholdSellPet = accordionSellPets:AddNumberBox({
        Name = "Weight Threshold",
        Placeholder = "Enter weight...",
        Default = 1.0,
        Min = 0.5,
        Max = 20.0,
        Increment = 1.0,
        Decimals = 2,
        Flag = "WeightThresholdSellPet",
    })

    accordionSellPets:AddLabel("And If Age Is Less Than Or Equal")
    local ageThresholdSellPet = accordionSellPets:AddNumberBox({
        Name = "Age Threshold (in days)",
        Placeholder = "Enter age...",
        Default = 1,
        Min = 1,
        Max = 100,
        Increment = 1,
        Flag = "AgeThresholdSellPet",
    })

    accordionSellPets:AddLabel("Pet Team to Use for Selling")
    local selectTeamForSell = accordionSellPets:AddSelectBox({
        Name = "Select Pet Team for Sell",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "SellPetTeam",
        OnInit = function(currentOptions, updateOptions)
            local listTeamPet = PetUtils:GetAllPetTeams()
            local currentOptionsSet = {}
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            updateOptions(currentOptionsSet)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetUtils:GetAllPetTeams()
            local currentOptionsSet = {}
            
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })
    accordionSellPets:AddToggle({
        Name = "Auto Boost Pets Before Selling",
        Default = false,
        Flag = "AutoBoostBeforeSelling",
    })

    accordionSellPets:AddToggle({
        Name = "Auto Sell Pets After Hatching",
        Default = false,
        Flag = "AutoSellPetsAfterHatching",
    })

    accordionSellPets:AddButton("Sell Selected Pet", function()
        PetUtils:SellPet()
    end)
end

return UIPet