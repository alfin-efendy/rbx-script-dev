-- UI Components Module
local UIComponents = {}
local window
local PetUtils
local FarmUtils
local EzUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/ez-rbx-ui/refs/heads/main/ui.lua'))()

function UIComponents:Init(windowInstance, petUtils, farmUtils)
    window = windowInstance
    PetUtils = petUtils
    FarmUtils = farmUtils
end

function UIComponents:CreatePetTab()
    local petTab = window:AddTab({
        Name = "Pets",
        Icon = "🐾",
    })
    
    self:CreatePetTeamsSection(petTab)
    self:CreateEggsSection(petTab)
end

function UIComponents:CreatePetTeamsSection(petTab)
    local petTeamConfig = EzUI.NewConfig("PetTeamConfig")

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
            local activePets = PetUtils:GetActivePets(game.Players.LocalPlayer.Name)
           
            if activePets then
                local listActivePets = {}
                for petUUID, petState in pairs(activePets) do
                    print("Adding Active Pet to Team:", petUUID)
                    table.insert(listActivePets, petUUID)
                end

                petTeamConfig.SetValue(teamName, listActivePets)
                petTeamName.Clear()

                local listTeamPet = petTeamConfig.GetAllKeys()
                print("=== SAVED PET TEAMS ===")
                for _, team in pairs(listTeamPet) do
                    local petsInTeam = petTeamConfig.GetValue(team)
                    print("Team:", team, "Pets:", table.concat(petsInTeam, ", "))
                end
            else
                print("No active pets found to add to team.")
            end
        else
            print("Please enter a valid team name.")
        end
    end)

    accordionPetTeams:AddSeparator()

    accordionPetTeams:AddLabel("Select a pet team to set as core, change, or delete.")
    
    local selectTeam = accordionPetTeams:AddSelectBox({
        Name = "Select Pet Team",
        Options = petTeamConfig.GetAllKeys(),
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = petTeamConfig.GetAllKeys()
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
            petTeamConfig.DeleteKey(teamName)
            selectTeam.Clear()
        else
            print("Please select a team to delete.")
        end
    end)
end

function UIComponents:CreateEggsSection(petTab)
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
            local OwnedEggs = PetUtils:GetEggsInventory()
            updateOptions(OwnedEggs)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local currentOptionsSet = {}
            local OwnedEggs = PetUtils:GetEggsInventory()

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

    accordionEggs:AddButton("Hatch All Ready Eggs", function()
        PetUtils:HatchEgg()
    end)
end

return UIComponents