local ESP = {}

function ESP.CreateESP(object, options)
    if not object or not options then
        return
    end
    
    -- Prevent duplicate ESP on same object
    if object:FindFirstChild("ESP") then
        return
    end
    
    -- Find the main part to attach ESP to
    local mainPart = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
    if not mainPart then
        return
    end
    
    -- Create ESP container folder
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP"
    espFolder.Parent = object
    
    -- Create BoxHandleAdornment for visual outline
    local boxAdornment = Instance.new("BoxHandleAdornment")
    boxAdornment.Name = "ESP"
    boxAdornment.Size = Vector3.new(1, 0, 1)
    boxAdornment.Transparency = 1
    boxAdornment.AlwaysOnTop = false
    boxAdornment.ZIndex = 0
    boxAdornment.Adornee = mainPart
    boxAdornment.Parent = espFolder
    
    -- Set ESP color if provided
    local espColor = options.Color or Color3.fromRGB(255, 255, 255)
    
    -- Create BillboardGui for text display
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "BillboardGui"
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = espFolder
    
    -- Create TextLabel for displaying information
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "TextLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = options.Text or "ESP"
    textLabel.TextColor3 = espColor
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.Arial
    textLabel.Parent = billboardGui
    
    return espFolder
end

return ESP