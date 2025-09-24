-- Import library
local EzUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/ez-rbx-ui/refs/heads/main/ui.lua'))()
local Player = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/refs/heads/main/module/player.lua'))()

local window = EzUI.CreateWindow({
	Name = "My App", -- Name of the window
	Width = 700, -- Optional: Override default calculated width
	Height = 400, -- Optional: Override default calculated height
	Opacity = 0.9,  -- 0.1 to 1.0 (10% to 100%)
	AutoAdapt = true, -- Optional: Auto-resize on viewport changes (default true)
	AutoShow = false, -- Start hidden, can be shown later
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "My App", -- Name of the window -- Custom folder name
		FileName = "settings", -- Custom file name
		AutoLoad = true, -- Auto-load on window creation
		AutoSave = true, -- Auto-save on window close
	},
})

local exampleTab = window:AddTab({
    Name = "Example",
    Icon = "🚀",
})

exampleTab:AddButton("Equip Random Tool", function()
		local tools = Player:GetAllTools()
		if #tools > 0 then
				local randomIndex = math.random(1, #tools)
				local randomTool = tools[randomIndex]
				local success = Player:EquipTool(randomTool)
				if success then
					print("Equipped tool:", randomTool.Name)
				else
					print("Failed to equip tool:", randomTool.Name)
				end
		else
				print("No tools found in backpack.")
		end
end)