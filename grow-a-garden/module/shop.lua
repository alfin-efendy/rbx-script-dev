local m = {}
local Core
local PlayerUtils
local Window

-- Automation state (dynamic from config)
local AutomationState = {
    connections = {},
    textConnections = {},
    lastStockCheck = {}
}

-- Dynamic getters for automation states from config
function AutomationState:GetSeedState()
    return Window and Window:GetConfigValue("AutoBuySeeds") or false
end

function AutomationState:GetEggState()
    return Window and Window:GetConfigValue("AutoBuyEggs") or false
end

function AutomationState:GetGearState()
    return Window and Window:GetConfigValue("AutoBuyGears") or false
end

-- Compatibility properties for dynamic access
setmetatable(AutomationState, {
    __index = function(self, key)
        if key == "seeds" then
            return self:GetSeedState()
        elseif key == "eggs" then
            return self:GetEggState()
        elseif key == "gears" then
            return self:GetGearState()
        end
        return rawget(self, key)
    end,
    __newindex = function(self, key, value)
        -- Block setting automation states directly
        if key == "seeds" or key == "eggs" or key == "gears" then
            warn("Cannot set automation state directly. Use config values instead.")
            return
        end
        rawset(self, key, value)
    end
})

function m:Init(CoreInstance, PlayerUtilsInstance, WindowInstance)
    Core = CoreInstance
    PlayerUtils = PlayerUtilsInstance
    Window = WindowInstance

    wait(3) -- Ensure GUI is loaded
    
    -- Debug config values (now dynamic)
    print("🔍 Config values (dynamic):")
    print("🌱 Seed Automation:", AutomationState.seeds)
    print("🥚 Egg Automation:", AutomationState.eggs)
    print("⚙️ Gear Automation:", AutomationState.gears)

    self:StopAllAutomation() -- Ensure all automation is stopped on init
    
    -- Initialize connections for all shop types immediately
    task.spawn(function()
        -- Small delay to ensure GUI is loaded
        wait(1)
        
        -- Connect to all shop types regardless of automation state
        self:ConnectToStockChanges("seeds")
        self:ConnectToStockChanges("eggs") 
        self:ConnectToStockChanges("gears")
        
        wait(2)
    end)
end

function m:GetAvailableSeeds()
    local availableSeeds = {}
    
    local SeedShop = Core:GetPlayerGui():FindFirstChild("Seed_Shop")
    if not SeedShop then
        warn("Seed Shop GUI not found")
        return availableSeeds
    end

    local Items = SeedShop:FindFirstChild("Blueberry", true).Parent
    if not Items then
        warn("Items frame not found in Seed Shop")
        return availableSeeds
    end


    for _, Item in pairs(Items:GetChildren()) do
        local MainFrame = Item:FindFirstChild("Main_Frame")
		if not MainFrame then continue end

		local StockText = MainFrame.Stock_Text.Text
		local StockCount = tonumber(StockText:match("%d+"))
        
        availableSeeds[Item.Name] = StockCount
    end

    return availableSeeds
end

function m:BuySeed(seedName)
    if not seedName or seedName == "" then
        warn("Invalid seed name")
        return
    end

    Core.GameEvents.BuySeedStock:FireServer("Tier 1", seedName)
end

function m:BuyAllSeeds()
    local seeds = self:GetAvailableSeeds()
    for seedName, stock in pairs(seeds) do
        if stock and stock > 0 then
            for i = 1, stock do
                self:BuySeed(seedName)
                wait(0.1) -- Small delay to avoid spamming
            end
        end
    end
end

function m:GetAvailableEggs()
    local availableEggs = {}
    
    local PetShop = Core:GetPlayerGui():FindFirstChild("PetShop_UI")
    if not PetShop then
        warn("Pet Shop GUI not found")
        return availableEggs
    end

    local Items = PetShop:FindFirstChild("Common Egg", true).Parent
    if not Items then
        warn("Items frame not found in Pet Shop")
        return availableEggs
    end

    for _, Item in pairs(Items:GetChildren()) do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end

        local StockText = MainFrame.Stock_Text.Text
        local StockCount = tonumber(StockText:match("%d+"))
        
        availableEggs[Item.Name] = StockCount
    end

    return availableEggs
end

function m:BuyEgg(eggName)
    if not eggName or eggName == "" then
        warn("Invalid egg name")
        return
    end

    Core.GameEvents.BuyPetEgg:FireServer(eggName)
end

function m:BuyAllEggs()
    local eggs = self:GetAvailableEggs()
    for eggName, stock in pairs(eggs) do
        if stock and stock > 0 then
            for i = 1, stock do
                self:BuyEgg(eggName)
                wait(0.1) -- Small delay to avoid spamming
            end
        end
    end
end


function m:GetAvailableGears()
    local availableGears = {}
    
    local GearShop = Core:GetPlayerGui():FindFirstChild("Gear_Shop")
    if not GearShop then
        warn("Gear Shop GUI not found")
        return availableGears
    end

    local Items = GearShop:FindFirstChild("Watering Can", true).Parent
    if not Items then
        warn("Items frame not found in Gear Shop")
        return availableGears
    end

    for _, Item in pairs(Items:GetChildren()) do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end

        local StockText = MainFrame.Stock_Text.Text
        local StockCount = tonumber(StockText:match("%d+"))
        
        availableGears[Item.Name] = StockCount
    end

    return availableGears
end

function m:BuyGear(gearName)
    if not gearName or gearName == "" then
        warn("Invalid gear name")
        return
    end

    Core.GameEvents.BuyGearStock:FireServer(gearName)
end

function m:BuyAllGears()
    local gears = self:GetAvailableGears()
    for gearName, stock in pairs(gears) do
        if stock and stock > 0 then
            for i = 1, stock do
                self:BuyGear(gearName)
                wait(0.1) -- Small delay to avoid spamming
            end
        end
    end
end

-- ===== AUTOMATION FUNCTIONS =====

-- Helper function to connect to stock text changes
function m:ConnectToStockChanges(shopType)
    local shopGUI, itemsParent, buyFunction
    
    if shopType == "seeds" then
        shopGUI = Core:GetPlayerGui():WaitForChild("Seed_Shop", 10)
        if shopGUI then
            itemsParent = shopGUI:FindFirstChild("Blueberry", true)
            if itemsParent then itemsParent = itemsParent.Parent end
        end
        buyFunction = function() self:BuyAllSeeds() end
    elseif shopType == "eggs" then
        shopGUI = Core:GetPlayerGui():WaitForChild("PetShop_UI", 10)
        if shopGUI then
            itemsParent = shopGUI:FindFirstChild("Common Egg", true)
            if itemsParent then itemsParent = itemsParent.Parent end
        end
        buyFunction = function() self:BuyAllEggs() end
    elseif shopType == "gears" then
        shopGUI = Core:GetPlayerGui():WaitForChild("Gear_Shop", 10)
        if shopGUI then
            itemsParent = shopGUI:FindFirstChild("Watering Can", true)
            if itemsParent then itemsParent = itemsParent.Parent end
        end
        buyFunction = function() self:BuyAllGears() end
    end

    if not shopGUI or not itemsParent then
        warn("Could not find shop GUI for", shopType)
        return
    end

    print("📋 Connecting to " .. shopType .. " shop, automation status: " .. tostring(AutomationState[shopType]))

    -- Connect to existing items
    for _, item in pairs(itemsParent:GetChildren()) do
        local mainFrame = item:FindFirstChild("Main_Frame")
        if mainFrame and mainFrame:FindFirstChild("Stock_Text") then
            self:ConnectToStockText(item, shopType, buyFunction)
        end
    end

    -- If automation is enabled, also trigger one global purchase after all connections
    if AutomationState[shopType] then
        print("🔥 Global purchase trigger for " .. shopType .. " (automation enabled)")
        task.spawn(function()
            wait(0.5) -- Wait for all connections to complete
            local success, err = pcall(buyFunction)
            if success then
                print("✅ Global " .. shopType .. " purchase completed")
            else
                warn("❌ Error in global " .. shopType .. " purchase:", err)
            end
        end)
    end

    -- Connect to new items added
    AutomationState.connections[shopType .. "_childAdded"] = itemsParent.ChildAdded:Connect(function(item)
        wait(0.1) -- Wait for item to fully load
        local mainFrame = item:FindFirstChild("Main_Frame")
        if mainFrame and mainFrame:FindFirstChild("Stock_Text") then
            self:ConnectToStockText(item, shopType, buyFunction)
        end
    end)
end

function m:ConnectToStockText(item, shopType, buyFunction)
    local mainFrame = item:FindFirstChild("Main_Frame")
    if not mainFrame then return end
    
    local stockText = mainFrame:FindFirstChild("Stock_Text")
    if not stockText then return end

    local connectionKey = shopType .. "_" .. item.Name
    
    -- Disconnect existing connection if any
    if AutomationState.textConnections[connectionKey] then
        AutomationState.textConnections[connectionKey]:Disconnect()
    end

    -- Initialize last stock check FIRST (before connecting)
    local currentStock = tonumber(stockText.Text:match("%d+")) or 0
    
    -- Set initial stock to 0 to ensure first restock triggers purchase
    -- This fixes the issue where initial load doesn't trigger auto-buy
    AutomationState.lastStockCheck[connectionKey] = 0
    
    -- Connect to text changes
    AutomationState.textConnections[connectionKey] = stockText:GetPropertyChangedSignal("Text"):Connect(function()
        if not AutomationState[shopType] then return end
        
        local stockCount = tonumber(stockText.Text:match("%d+")) or 0
        local lastStock = AutomationState.lastStockCheck[connectionKey] or 0
        
        print("🔍 RESTOCK EVENT for " .. item.Name .. ": " .. stockCount .. " (was " .. lastStock .. "), automation: " .. tostring(AutomationState[shopType]))
        
        -- Enhanced trigger conditions:
        -- 1. Stock increased (normal restock)
        -- 2. Stock went from 0 to any positive number (first restock)
        -- 3. Stock is available and we haven't seen it before
        local shouldBuy = false
        
        if stockCount > 0 and AutomationState[shopType] then
            if stockCount > lastStock then
                shouldBuy = true
            elseif lastStock == 0 then
                shouldBuy = true  
            end
        end
        
        if shouldBuy then
            
            -- Immediate purchase for restock events
            task.spawn(function()
                wait(0.1) -- Minimal delay
                if AutomationState[shopType] then
                    local success, err = pcall(buyFunction)
                    if success then
                        print("✅ Restock purchase successful for " .. item.Name)
                    else
                        warn("❌ Error in restock purchase:", err)
                    end
                end
            end)
        end
        
        AutomationState.lastStockCheck[connectionKey] = stockCount
    end)
    
    -- If automation is already enabled and there's stock, trigger immediate purchase
    if AutomationState[shopType] and currentStock > 0 then
        task.spawn(function()
            wait(1) -- Wait a bit for full initialization
            if AutomationState[shopType] then
                local success, err = pcall(buyFunction)
                if not success then
                    warn("Error in immediate " .. shopType .. " purchase:", err)
                end
            end
        end)
    end
end

function m:StartSeedAutomation()
    if AutomationState.seeds then
        warn("Seed automation is already running")
        return
    end
    
    print("🌱 Starting Seed Automation (event-based)")
    
    for key, _ in pairs(AutomationState.lastStockCheck) do
        if key:match("^seeds_") then
            AutomationState.lastStockCheck[key] = 0
        end
    end
    
    -- Initial purchase (immediate)
    task.spawn(function()
        wait(0.5) -- Small delay to ensure connections are ready
        local success, err = pcall(function() self:BuyAllSeeds() end)
        if not success then
            warn("Error in initial seed purchase:", err)
        end
    end)
    
    -- Ensure connections exist (if not already connected from init)
    local hasConnections = false
    for key, _ in pairs(AutomationState.textConnections) do
        if key:match("^seeds_") then
            hasConnections = true
            break
        end
    end
    
    if not hasConnections then
        print("🔌 Creating seed connections...")
        self:ConnectToStockChanges("seeds")
    end
end

function m:StartEggAutomation()
    if AutomationState.eggs then
        warn("Egg automation is already running")
        return
    end

    -- Reset stock tracking to ensure next restock triggers purchase
    for key, _ in pairs(AutomationState.lastStockCheck) do
        if key:match("^eggs_") then
            AutomationState.lastStockCheck[key] = 0
        end
    end
    
    -- Initial purchase (immediate)
    task.spawn(function()
        wait(0.5) -- Small delay to ensure connections are ready
        local success, err = pcall(function() self:BuyAllEggs() end)
        if not success then
            warn("Error in initial egg purchase:", err)
        end
    end)
    
    -- Ensure connections exist (if not already connected from init)
    local hasConnections = false
    for key, _ in pairs(AutomationState.textConnections) do
        if key:match("^eggs_") then
            hasConnections = true
            break
        end
    end
    
    if not hasConnections then
        print("🔌 Creating egg connections...")
        self:ConnectToStockChanges("eggs")
    end
end

function m:StartGearAutomation()
    if AutomationState.gears then
        warn("Gear automation is already running")
        return
    end
    
    -- Reset stock tracking to ensure next restock triggers purchase
    for key, _ in pairs(AutomationState.lastStockCheck) do
        if key:match("^gears_") then
            AutomationState.lastStockCheck[key] = 0
        end
    end
    
    -- Initial purchase (immediate)
    task.spawn(function()
        wait(0.5) -- Small delay to ensure connections are ready
        local success, err = pcall(function() self:BuyAllGears() end)
        if not success then
            warn("Error in initial gear purchase:", err)
        end
    end)
    
    -- Ensure connections exist (if not already connected from init)
    local hasConnections = false
    for key, _ in pairs(AutomationState.textConnections) do
        if key:match("^gears_") then
            hasConnections = true
            break
        end
    end
    
    if not hasConnections then
        print("🔌 Creating gear connections...")
        self:ConnectToStockChanges("gears")
    end
end

function m:StartAllAutomation()
    self:StartSeedAutomation()
    self:StartEggAutomation()
    self:StartGearAutomation()
end

function m:StopSeedAutomation()
    if not AutomationState.seeds then
        warn("Seed automation is not running")
        return
    end
    
    print("🛑 Stopped Seed Automation")
end

function m:StopEggAutomation()
    if not AutomationState.eggs then
        warn("Egg automation is not running")
        return
    end
    
    print("🛑 Stopped Egg Automation")
end

function m:StopGearAutomation()
    if not AutomationState.gears then
        warn("Gear automation is not running")
        return
    end
    
    print("🛑 Stopped Gear Automation")
end

function m:StopAllAutomation()
    self:StopSeedAutomation()
    self:StopEggAutomation()
    self:StopGearAutomation()
end


return m