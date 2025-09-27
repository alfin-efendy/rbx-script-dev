local m = {}
local Window
local ShopModule

function m:Init(windowInstance, shopModuleInstance)
    Window = windowInstance
    ShopModule = shopModuleInstance
end

function m:CreateShopTab()
    local shopTab = Window:AddTab({
        Name = "Shop",
        Icon = "🛍️",
    })

    -- Seed Automation
    shopTab:AddToggle({
        Name = "Auto Buy Seeds 🌱",
        Default = false,
        Flag = "AutoBuySeeds",
        Callback = function(Value)
            if Value then
                ShopModule:StartSeedAutomation()
            else
                ShopModule:StopSeedAutomation()
            end
        end,
    })

    -- Egg Automation
    shopTab:AddToggle({
        Name = "Auto Buy Eggs 🥚",
        Default = false,
        Flag = "AutoBuyEggs",
        Callback = function(Value)
            if Value then
                ShopModule:StartEggAutomation()
            else
                ShopModule:StopEggAutomation()
            end
        end,
    })

    -- Gear Automation
    shopTab:AddToggle({
        Name = "Auto Buy Gears ⚙️",
        Default = false,
        Flag = "AutoBuyGears",
        Callback = function(Value)
            if Value then
                ShopModule:StartGearAutomation()
            else
                ShopModule:StopGearAutomation()
            end
        end,
    })
end

return m