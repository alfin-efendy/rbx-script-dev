local FarmUtils = {}
-- Load Core module with error handling
local Core
local PlayerUtils

function FarmUtils:GetFarm(PlayerName: string): Folder?
	local Farms = Core.Workspace.Farm:GetChildren()

	for _, Farm in next, Farms do
    local Important = Farm.Important
    local Data = Important.Data
    local Owner = Data.Owner

		if Owner.Value == PlayerName then
			return Farm
		end
	end
    return
end

function FarmUtils:Init(core, playerUtils)
    if not core then
        error("FarmUtils:Init - Core module is required")
    end
    if not playerUtils then
        error("FarmUtils:Init - PlayerUtils module is required")
    end
    Core = core
    PlayerUtils = playerUtils
    
    -- Initialize MyFarm after Core is set
    FarmUtils.MyFarm = FarmUtils:GetFarm(Core.LocalPlayer.Name)
end

function FarmUtils:GetArea(Base: Part)
	local Center = Base:GetPivot()
	local Size = Base.Size

	-- Bottom left
	local X1 = math.ceil(Center.X - (Size.X/2))
	local Z1 = math.ceil(Center.Z - (Size.Z/2))

	-- Top right
	local X2 = math.floor(Center.X + (Size.X/2))
	local Z2 = math.floor(Center.Z + (Size.Z/2))

	return X1, Z1, X2, Z2
end

-- Get center CFrame point of the farm
function FarmUtils:GetFarmCenterCFrame()    
    local important = FarmUtils.MyFarm:FindFirstChild("Important")
    if not important then
        warn("Important folder not found in farm")
        return nil
    end
    
    -- Try to find Plant_Locations first
    local plantLocations = important:FindFirstChild("Plant_Locations")
    if plantLocations then
        local farmParts = plantLocations:GetChildren()
        if #farmParts > 0 then
            -- Calculate center from all farm parts
            local totalX, totalZ = 0, 0
            local totalY = 4 -- Default height for farm
            local partCount = 0
            
            for _, part in pairs(farmParts) do
                if part:IsA("BasePart") then
                    local pos = part.Position
                    totalX = totalX + pos.X
                    totalZ = totalZ + pos.Z
                    totalY = math.max(totalY, pos.Y + part.Size.Y/2) -- Use highest Y position
                    partCount = partCount + 1
                end
            end
            
            if partCount > 0 then
                local centerX = totalX / partCount
                local centerZ = totalZ / partCount
                return CFrame.new(centerX, totalY, centerZ)
            end
        end
    end
    
    -- Fallback: try to find any farm area parts
    local farmAreas = {"Farm_Area", "Dirt", "Farmland", "Ground"}
    for _, areaName in pairs(farmAreas) do
        local area = important:FindFirstChild(areaName, true)
        if area and area:IsA("BasePart") then
            local pos = area.Position
            return CFrame.new(pos.X, pos.Y + area.Size.Y/2 + 1, pos.Z)
        end
    end
    
    -- Final fallback: use farm folder position if available
    if farm.PrimaryPart then
        local pos = farm.PrimaryPart.Position
        return CFrame.new(pos.X, pos.Y + 4, pos.Z)
    end
    
    warn("Could not determine farm center for player:", playerName or Core.LocalPlayer.Name)
    return CFrame.new(0, 4, 0) -- Default position
end

-- Get random point within farm boundaries
function FarmUtils:GetRandomFarmPoint()
    local farm = GetFarm(Core.LocalPlayer.Name)
    if not farm then
        return Vector3.new(0, 4, 0)
    end
    
    local important = farm:FindFirstChild("Important")
    if not important then
        return Vector3.new(0, 4, 0)
    end
    
    local plantLocations = important:FindFirstChild("Plant_Locations")
    if plantLocations then
        local farmParts = plantLocations:GetChildren()
        if #farmParts > 0 then
            -- Pick random farm part
            local randomPart = farmParts[math.random(1, #farmParts)]
            if randomPart:IsA("BasePart") then
                local X1, Z1, X2, Z2 = GetArea(randomPart)
                local X = math.random(X1, X2)
                local Z = math.random(Z1, Z2)
                return Vector3.new(X, 4, Z)
            end
        end
    end
    
    -- Fallback to center point
    local centerCFrame = GetFarmCenterCFrame()
    return centerCFrame and centerCFrame.Position or Vector3.new(0, 4, 0)
end

function FarmUtils:GetBackCornerFarmPoint()
    local farm = GetFarm(Core.LocalPlayer.Name)
    if not farm then
        return Vector3.new(0, 4, 0)
    end
    
    local important = farm:FindFirstChild("Important")
    if not important then
        return Vector3.new(0, 4, 0)
    end
    
    local plantLocations = important:FindFirstChild("Plant_Locations")
    if plantLocations then
        local farmParts = plantLocations:GetChildren()
        if #farmParts > 0 then
            -- Pick random farm part
            local randomPart = farmParts[math.random(1, #farmParts)]
            if randomPart:IsA("BasePart") then
                local X1, Z1, X2, Z2 = GetArea(randomPart)
                return Vector3.new(X1, 4, Z2) -- Back corner (X1,Z2)
            end
        end
    end
    
    -- Fallback to center point
    local centerCFrame = GetFarmCenterCFrame()
    return centerCFrame and centerCFrame.Position or Vector3.new(0, 4, 0)
end

return FarmUtils