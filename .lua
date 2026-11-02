
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ZonesFolder = workspace:WaitForChild("Zones")

local MINING_INTERVAL = 0.01
local TELEPORT_RETRY_DELAY = 0.75
local TELEPORT_SUCCESS_DISTANCE = 5
local TELEPORT_SETTLE_DELAY = 0.15
local ORE_CLEARANCE = 1
local NEXT_ROCK_DELAY = 0.3
local SCAN_DELAY = 0.4
local RESCAN_INTERVAL = 2
local ERROR_RETRY_DELAY = 1
local NO_DAMAGE_TIMEOUT = 0.4
local SKIP_DURATION = 3

local AUTO_BUY_INTERVAL = 10
local CRAFT_REQUEST_DELAY = 0.5

local BOSS_TELEPORT_INTERVAL = 0.10
local BOSS_ATTACK_INTERVAL = 0.05

local CONFIG_FILE = "SWS_Script.json"

local MinerNames = {
    "StoneMiner", "CoalMiner", "CopperMiner", "IronMiner",
    "GoldMiner", "RubyMiner", "SapphireMiner", "EmeraldMiner",
    "DiamondMiner", "VoidstoneMiner", "ToxiteMiner", "StarliteMiner",
    "CelestiumMiner", "MoonstoneMiner", "PrismiteMiner", "AuroriumMiner",
    "FrostiteMiner", "AquamarineMiner", "DragonscaleMiner", "NeoniteMiner",
    "DarkMatterMiner", "BrassiteMiner", "PixeliteMiner", "HaloiteMiner",
    "NebuliteMiner", "SoulstoneMiner", "PumpkinMiner"
}

local zoneOrder = {
    {"Mine1", "Starter Mine"},
    {"Grotto", "Mushroom Grotto"},
    {"Mine2", "Crystal Cave"},
    {"Tomb", "Desert Tomb"},
    {"Mine3", "Magma Depths"},
    {"Mine4", "Void Rift"},
    {"Toxic", "Toxic Abyss"},
    {"Sky", "Sky Ruins"},
    {"Mine5", "Starfall Peak"},
    {"Moon", "Moonlit Temple"},
    {"Mine6", "Prism"},
    {"Glacier", "Frozen"},
    {"Atlantis", "Sunken Atlantis"},
    {"Dragon", "Dragons Lair"},
    {"Neon", "Neon City"},
    {"BlackHole", "Black Hole"},
    {"Clockwork", "Clockwork"},
    {"Glitch", "Glitch Realm"},
    {"Celestial", "Celestial Paradise"},
    {"Genesis", "Genesis Core"},
    {"Crypt", "Haunted Crypt"}
}

local BLACK = Color3.fromRGB(5, 5, 5)
local PANEL = Color3.fromRGB(14, 14, 14)
local PANEL2 = Color3.fromRGB(22, 22, 22)
local WHITE = Color3.fromRGB(255, 255, 255)
local GREY = Color3.fromRGB(155, 155, 155)

local RUNNING = false
local AUTO_BOSS = false
local AUTO_BUY = false
local UNLOADED = false

local SESSION = 0
local BOSS_SESSION = 0
local BUY_SESSION = 0

local selectedZone
local selectedMiners = {}
local availableZones = {}
local zoneRows = {}
local minerRows = {}

local selectorExpanded = true
local guiMinimized = false
local savedGuiPosition

local currentRock
local trackedRock
local trackedRockStartHP
local trackedRockStartTime = 0

local skippedRocks = setmetatable({}, {__mode = "k"})

local nextTeleportAt = 0
local nextRockAt = 0
local lastRescan = 0

local lastBossTeleport = 0
local lastBossAttack = 0

local MineRemote

local savedConfig = {}
local saveQueued = false

local function loadConfig()
    if type(readfile) ~= "function"
        or type(isfile) ~= "function" then
        return
    end

    local success, result = pcall(function()
        if isfile(CONFIG_FILE) then
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end

        local oldFiles = {
            "MultiZoneMinerV25.json"
        }

        for _, oldFile in ipairs(oldFiles) do
            if isfile(oldFile) then
                local oldData = HttpService:JSONDecode(readfile(oldFile))

                if type(oldData) == "table" then
                    writefile(
                        CONFIG_FILE,
                        HttpService:JSONEncode(oldData)
                    )

                    return oldData
                end
            end
        end

        return {}
    end)

    if success and type(result) == "table" then
        savedConfig = result
    end
end

local function saveConfig()
    if type(writefile) ~= "function" then
        return false
    end

    local config = {
        SelectedZone = selectedZone,
        SelectedMiners = selectedMiners,
        SelectorExpanded = selectorExpanded,
        GuiMinimized = guiMinimized,
        GuiPosition = savedGuiPosition,
        AutoBoss = AUTO_BOSS,
        AutoBuy = AUTO_BUY
    }

    return pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end)
end

local function queueSave()
    if saveQueued or UNLOADED then return end

    saveQueued = true

    task.delay(0.5, function()
        saveQueued = false

        if not UNLOADED then
            saveConfig()
        end
    end)
end

loadConfig()

if type(savedConfig.SelectedMiners) == "table" then
    for _, name in ipairs(MinerNames) do
        selectedMiners[name] = savedConfig.SelectedMiners[name] == true
    end
end

if type(savedConfig.SelectorExpanded) == "boolean" then
    selectorExpanded = savedConfig.SelectorExpanded
end

if type(savedConfig.GuiMinimized) == "boolean" then
    guiMinimized = savedConfig.GuiMinimized
end

if type(savedConfig.GuiPosition) == "table" then
    savedGuiPosition = savedConfig.GuiPosition
end

local resumeBoss = savedConfig.AutoBoss == true
local resumeBuy = savedConfig.AutoBuy == true

for _, entry in ipairs(zoneOrder) do
    local zone = ZonesFolder:FindFirstChild(entry[1])

    if zone and zone:FindFirstChild("Rocks") then
        table.insert(availableZones, {
            Folder = entry[1],
            Display = entry[2]
        })
    end
end

selectedZone = availableZones[1] and availableZones[1].Folder

if savedConfig.SelectedZone then
    for _, entry in ipairs(availableZones) do
        if entry.Folder == savedConfig.SelectedZone then
            selectedZone = entry.Folder
            break
        end
    end
end

local function getDisplayName(name)
    for _, entry in ipairs(availableZones) do
        if entry.Folder == name then
            return entry.Display
        end
    end

    return tostring(name or "Unknown")
end

local old = PlayerGui:FindFirstChild("MultiZoneMinerV25")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "MultiZoneMinerV25"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = object
end

local function stroke(object, transparency)
    local s = Instance.new("UIStroke")
    s.Color = WHITE
    s.Thickness = 1
    s.Transparency = transparency or 0.6
    s.Parent = object
    return s
end

local function makeButton(parent, text, size, position)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = PANEL2
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = WHITE
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.Parent = parent

    corner(b, 5)
    stroke(b)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(48, 48, 48)
        }):Play()
    end)

    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = PANEL2
        }):Play()
    end)

    return b
end

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(290, 251)
main.Position = UDim2.new(0.5, -145, 0.5, -125)
main.BackgroundColor3 = BLACK
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui

corner(main, 10)
local mainStroke = stroke(main, 0.45)

if savedGuiPosition then
    pcall(function()
        main.Position = UDim2.new(
            savedGuiPosition.XScale,
            savedGuiPosition.XOffset,
            savedGuiPosition.YScale,
            savedGuiPosition.YOffset
        )
    end)
end

main:GetPropertyChangedSignal("Position"):Connect(function()
    if UNLOADED then return end

    local p = main.Position

    savedGuiPosition = {
        XScale = p.X.Scale,
        XOffset = p.X.Offset,
        YScale = p.Y.Scale,
        YOffset = p.Y.Offset
    }

    queueSave()
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -145, 0, 30)
title.Position = UDim2.fromOffset(12, 3)
title.BackgroundTransparency = 1
title.Text = "AUTO MINER / V25"
title.TextColor3 = WHITE
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local minersOpenButton = makeButton(
    main, "MINERS",
    UDim2.fromOffset(48, 23),
    UDim2.new(1, -113, 0, 5)
)

local minimize = makeButton(
    main, "-",
    UDim2.fromOffset(24, 23),
    UDim2.new(1, -57, 0, 5)
)

local close = makeButton(
    main, "X",
    UDim2.fromOffset(24, 23),
    UDim2.new(1, -29, 0, 5)
)

local zoneToggle = makeButton(
    main, "ZONES ▼",
    UDim2.new(1, -20, 0, 23),
    UDim2.fromOffset(10, 35)
)

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -20, 0, 23)
search.Position = UDim2.fromOffset(10, 63)
search.BackgroundColor3 = PANEL
search.BorderSizePixel = 0
search.PlaceholderText = "Search zones..."
search.PlaceholderColor3 = GREY
search.Text = ""
search.TextColor3 = WHITE
search.TextSize = 10
search.Font = Enum.Font.Gotham
search.ClearTextOnFocus = false
search.TextXAlignment = Enum.TextXAlignment.Left
search.Parent = main

corner(search, 5)
stroke(search, 0.8)

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 8)
searchPadding.Parent = search

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 0, 90)
scroll.Position = UDim2.fromOffset(10, 91)
scroll.BackgroundColor3 = PANEL
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = WHITE
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = main

corner(scroll, 6)
stroke(scroll, 0.85)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 5)
scrollPadding.PaddingLeft = UDim.new(0, 5)
scrollPadding.PaddingRight = UDim.new(0, 5)
scrollPadding.Parent = scroll

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.fromOffset(
        0, layout.AbsoluteContentSize.Y + 10
    )
end)

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, -20, 0, 17)
selectedLabel.Position = UDim2.fromOffset(10, 186)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = WHITE
selectedLabel.TextSize = 10
selectedLabel.Font = Enum.Font.GothamBold
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = main

local startButton = makeButton(
    main, "MINING",
    UDim2.fromOffset(85, 32),
    UDim2.fromOffset(10, 209)
)

local bossButton = makeButton(
    main, "BOSS: OFF",
    UDim2.fromOffset(85, 32),
    UDim2.fromOffset(102, 209)
)

local stopButton = makeButton(
    main, "STOP",
    UDim2.fromOffset(85, 32),
    UDim2.fromOffset(194, 209)
)

local minerWindow = Instance.new("Frame")
minerWindow.Name = "MinerSelection"
minerWindow.Size = UDim2.fromOffset(260, 405)
minerWindow.Position = UDim2.new(0.5, 155, 0.5, -202)
minerWindow.BackgroundColor3 = BLACK
minerWindow.BorderSizePixel = 0
minerWindow.Active = true
minerWindow.Draggable = true
minerWindow.Visible = false
minerWindow.ClipsDescendants = true
minerWindow.Parent = gui

corner(minerWindow, 10)
stroke(minerWindow, 0.45)

local minerTitle = Instance.new("TextLabel")
minerTitle.Size = UDim2.new(1, -45, 0, 32)
minerTitle.Position = UDim2.fromOffset(12, 3)
minerTitle.BackgroundTransparency = 1
minerTitle.Text = "MINER SELECTION"
minerTitle.TextColor3 = WHITE
minerTitle.TextSize = 12
minerTitle.Font = Enum.Font.GothamBold
minerTitle.TextXAlignment = Enum.TextXAlignment.Left
minerTitle.Parent = minerWindow

local minerClose = makeButton(
    minerWindow, "X",
    UDim2.fromOffset(25, 23),
    UDim2.new(1, -31, 0, 5)
)

local minerDescription = Instance.new("TextLabel")
minerDescription.Size = UDim2.new(1, -20, 0, 30)
minerDescription.Position = UDim2.fromOffset(10, 35)
minerDescription.BackgroundTransparency = 1
minerDescription.Text = "Select the miners you want to auto-buy."
minerDescription.TextColor3 = GREY
minerDescription.TextSize = 9
minerDescription.Font = Enum.Font.Gotham
minerDescription.TextXAlignment = Enum.TextXAlignment.Left
minerDescription.Parent = minerWindow

local minerCount = Instance.new("TextLabel")
minerCount.Size = UDim2.new(1, -20, 0, 17)
minerCount.Position = UDim2.fromOffset(10, 62)
minerCount.BackgroundTransparency = 1
minerCount.TextColor3 = WHITE
minerCount.TextSize = 10
minerCount.Font = Enum.Font.GothamBold
minerCount.TextXAlignment = Enum.TextXAlignment.Left
minerCount.Parent = minerWindow

local minerScroll = Instance.new("ScrollingFrame")
minerScroll.Size = UDim2.new(1, -20, 0, 230)
minerScroll.Position = UDim2.fromOffset(10, 83)
minerScroll.BackgroundColor3 = PANEL
minerScroll.BorderSizePixel = 0
minerScroll.ScrollBarThickness = 3
minerScroll.ScrollBarImageColor3 = WHITE
minerScroll.CanvasSize = UDim2.fromOffset(0, 0)
minerScroll.Parent = minerWindow

corner(minerScroll, 6)
stroke(minerScroll, 0.85)

local minerLayout = Instance.new("UIListLayout")
minerLayout.Padding = UDim.new(0, 3)
minerLayout.SortOrder = Enum.SortOrder.LayoutOrder
minerLayout.Parent = minerScroll

local minerPadding = Instance.new("UIPadding")
minerPadding.PaddingTop = UDim.new(0, 5)
minerPadding.PaddingLeft = UDim.new(0, 5)
minerPadding.PaddingRight = UDim.new(0, 5)
minerPadding.Parent = minerScroll

minerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    minerScroll.CanvasSize = UDim2.fromOffset(
        0, minerLayout.AbsoluteContentSize.Y + 10
    )
end)

local function getSelectedMinerCount()
    local count = 0

    for _, name in ipairs(MinerNames) do
        if selectedMiners[name] then
            count += 1
        end
    end

    return count
end

local function updateMinerCount()
    minerCount.Text = "SELECTED: "
        .. getSelectedMinerCount()
        .. " / "
        .. #MinerNames
end

local function updateMinerRows()
    for _, name in ipairs(MinerNames) do
        local row = minerRows[name]

        if row then
            local enabled = selectedMiners[name] == true

            row.Text = (enabled and "  [X]  " or "  [ ]  ") .. name
            row.TextColor3 = enabled and WHITE or GREY
            row.BackgroundColor3 = enabled
                and Color3.fromRGB(48, 48, 48)
                or PANEL2
        end
    end

    updateMinerCount()
end

for index, name in ipairs(MinerNames) do
    local row = Instance.new("TextButton")
    row.Name = name
    row.Size = UDim2.new(1, -3, 0, 23)
    row.BackgroundColor3 = PANEL2
    row.BorderSizePixel = 0
    row.TextColor3 = GREY
    row.TextSize = 10
    row.Font = Enum.Font.Gotham
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.LayoutOrder = index
    row.Parent = minerScroll

    corner(row, 4)
    minerRows[name] = row

    row.MouseButton1Click:Connect(function()
        selectedMiners[name] = not selectedMiners[name]
        updateMinerRows()
        queueSave()
    end)
end

local selectAllButton = makeButton(
    minerWindow, "SELECT ALL",
    UDim2.fromOffset(115, 25),
    UDim2.fromOffset(10, 320)
)

local deselectAllButton = makeButton(
    minerWindow, "DESELECT ALL",
    UDim2.fromOffset(115, 25),
    UDim2.fromOffset(135, 320)
)

selectAllButton.MouseButton1Click:Connect(function()
    for _, name in ipairs(MinerNames) do
        selectedMiners[name] = true
    end

    updateMinerRows()
    queueSave()
end)

deselectAllButton.MouseButton1Click:Connect(function()
    for _, name in ipairs(MinerNames) do
        selectedMiners[name] = false
    end

    updateMinerRows()
    queueSave()
end)

local purchaseStatus = Instance.new("TextLabel")
purchaseStatus.Size = UDim2.new(1, -20, 0, 17)
purchaseStatus.Position = UDim2.fromOffset(10, 348)
purchaseStatus.BackgroundTransparency = 1
purchaseStatus.Text = "AUTO BUY: OFF"
purchaseStatus.TextColor3 = GREY
purchaseStatus.TextSize = 9
purchaseStatus.Font = Enum.Font.Gotham
purchaseStatus.TextXAlignment = Enum.TextXAlignment.Left
purchaseStatus.Parent = minerWindow

local autoBuyButton = makeButton(
    minerWindow, "AUTO BUY: OFF",
    UDim2.fromOffset(150, 30),
    UDim2.fromOffset(10, 370)
)

local stopBuyButton = makeButton(
    minerWindow, "STOP",
    UDim2.fromOffset(90, 30),
    UDim2.fromOffset(170, 370)
)

local function setStatus(message)
    return
end

local function setPurchaseStatus(message)
    if not UNLOADED and purchaseStatus.Parent then
        purchaseStatus.Text = tostring(message)
    end
end

local function getCraftRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("CraftMiner")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

local function updateAutoBuyButton()
    autoBuyButton.Text = AUTO_BUY and "AUTO BUY: ON" or "AUTO BUY: OFF"
    autoBuyButton.BackgroundColor3 = AUTO_BUY
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
end

local function stopAutoBuy()
    AUTO_BUY = false
    BUY_SESSION += 1

    updateAutoBuyButton()
    setPurchaseStatus("AUTO BUY STOPPED")
    queueSave()
end

local function autoBuyWorker(mySession)
    local craftRemote = getCraftRemote()

    if not craftRemote then
        AUTO_BUY = false
        updateAutoBuyButton()
        setPurchaseStatus("CRAFTMINER REMOTE NOT FOUND")
        queueSave()
        return
    end

    while AUTO_BUY and not UNLOADED and BUY_SESSION == mySession do
        local selected = {}

        for _, name in ipairs(MinerNames) do
            if selectedMiners[name] then
                table.insert(selected, name)
            end
        end

        if #selected == 0 then
            setPurchaseStatus("NO MINERS SELECTED")
            task.wait(1)
        else
            local completed = 0
            local failed = 0

            for index, minerName in ipairs(selected) do
                if not AUTO_BUY or UNLOADED or BUY_SESSION ~= mySession then
                    break
                end

                setPurchaseStatus(
                    "CHECKING " .. minerName
                    .. " (" .. index .. "/" .. #selected .. ")"
                )

                local success, result = pcall(function()
                    return craftRemote:InvokeServer(minerName)
                end)

                if success and result ~= false then
                    completed += 1
                else
                    failed += 1
                end

                task.wait(CRAFT_REQUEST_DELAY)
            end

            if AUTO_BUY and not UNLOADED and BUY_SESSION == mySession then
                setPurchaseStatus(
                    "CYCLE DONE: "
                    .. completed
                    .. " SENT / "
                    .. failed
                    .. " FAILED"
                )

                task.wait(AUTO_BUY_INTERVAL)
            end
        end
    end
end

local function startAutoBuy()
    if AUTO_BUY or UNLOADED then return end

    if getSelectedMinerCount() == 0 then
        setPurchaseStatus("SELECT AT LEAST ONE MINER")
        return
    end

    if not getCraftRemote() then
        setPurchaseStatus("CRAFTMINER REMOTE NOT FOUND")
        return
    end

    AUTO_BUY = true
    BUY_SESSION += 1

    local mySession = BUY_SESSION

    updateAutoBuyButton()
    setPurchaseStatus("AUTO BUY STARTED")
    queueSave()

    task.spawn(function()
        local success, err = xpcall(function()
            autoBuyWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success and BUY_SESSION == mySession then
            AUTO_BUY = false
            updateAutoBuyButton()
            setPurchaseStatus("AUTO BUY ERROR: " .. tostring(err):sub(1, 35))
            queueSave()
        end
    end)
end

autoBuyButton.MouseButton1Click:Connect(function()
    if AUTO_BUY then
        stopAutoBuy()
    else
        startAutoBuy()
    end
end)

stopBuyButton.MouseButton1Click:Connect(stopAutoBuy)

minersOpenButton.MouseButton1Click:Connect(function()
    minerWindow.Visible = not minerWindow.Visible
end)

minerClose.MouseButton1Click:Connect(function()
    minerWindow.Visible = false
end)

local function updateSelection()
    selectedLabel.Text = "ZONE: " .. getDisplayName(selectedZone)

    for zoneName, row in pairs(zoneRows) do
        local selected = zoneName == selectedZone

        row.Text = (selected and "  ●  " or "  ○  ")
            .. getDisplayName(zoneName)

        row.BackgroundColor3 = selected
            and Color3.fromRGB(55, 55, 55)
            or PANEL2

        row.TextColor3 = selected and WHITE or GREY
    end
end

local function refreshZoneSearch()
    local query = string.lower(search.Text)

    for _, entry in ipairs(availableZones) do
        local row = zoneRows[entry.Folder]

        if row then
            local matches = string.find(
                string.lower(entry.Display),
                query,
                1,
                true
            )

            row.Visible = query == "" or matches ~= nil
        end
    end
end

for index, entry in ipairs(availableZones) do
    local folderName = entry.Folder

    local row = makeButton(
        scroll,
        getDisplayName(folderName),
        UDim2.new(1, -3, 0, 23),
        UDim2.new()
    )

    row.LayoutOrder = index
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextSize = 10
    zoneRows[folderName] = row

    row.MouseButton1Click:Connect(function()
        selectedZone = folderName

        currentRock = nil
        trackedRock = nil
        trackedRockStartHP = nil
        trackedRockStartTime = 0

        nextTeleportAt = 0
        nextRockAt = 0
        lastRescan = 0

        updateSelection()
        queueSave()
    end)
end

updateSelection()
search:GetPropertyChangedSignal("Text"):Connect(refreshZoneSearch)

local function getRocksFolder(zoneName)
    local zone = ZonesFolder:FindFirstChild(zoneName)
    return zone and zone:FindFirstChild("Rocks")
end

local function getRockPart(rock)
    if not rock then return nil end

    return rock.PrimaryPart
        or rock:FindFirstChildWhichIsA("BasePart", true)
end

local function getPositionAboveOre(rock, root)
    if not rock or not root then return nil end

    local success, boxCFrame, boxSize = pcall(function()
        return rock:GetBoundingBox()
    end)

    if not success or not boxCFrame or not boxSize then
        return nil
    end

    local oreTopY = boxCFrame.Position.Y + boxSize.Y / 2
    local rootHalfHeight = root.Size.Y / 2

    return Vector3.new(
        boxCFrame.Position.X,
        oreTopY + rootHalfHeight + ORE_CLEARANCE,
        boxCFrame.Position.Z
    )
end

local function validRock(rock, zoneName)
    if not rock or not rock:IsA("Model") then
        return false
    end

    local folder = getRocksFolder(zoneName)

    if not folder or rock.Parent ~= folder then
        return false
    end

    local hp = rock:GetAttribute("HP")
    return typeof(hp) == "number" and hp > 0
end

local function getCharacterParts()
    local character = Player.Character

    if not character then return nil, nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return nil, nil
    end

    return humanoid, root
end

local function getMineRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("MineRock")

    if remote and remote:IsA("RemoteEvent") then
        return remote
    end

    return nil
end

local function getDiamondFist()
    local adminEvents = workspace:FindFirstChild("AdminEvents")
    return adminEvents and adminEvents:FindFirstChild("DiamondFist")
end

local function getBossFistPart(boss, root)
    if not boss then return nil end

    if boss:IsA("BasePart") then
        return boss
    end

    local candidates = {}

    for _, obj in ipairs(boss:GetDescendants()) do
        if obj:IsA("BasePart")
            and string.find(string.lower(obj.Name), "fist", 1, true) then
            table.insert(candidates, obj)
        end
    end

    if #candidates > 0 then
        if root then
            table.sort(candidates, function(a, b)
                return (a.Position - root.Position).Magnitude
                    < (b.Position - root.Position).Magnitude
            end)
        end

        return candidates[1]
    end

    if boss:IsA("Model") then
        return boss.PrimaryPart
            or boss:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function updateBossButton()
    bossButton.Text = AUTO_BOSS and "BOSS: ON" or "BOSS: OFF"
    bossButton.BackgroundColor3 = AUTO_BOSS
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
end

local function stopBoss()
    AUTO_BOSS = false
    BOSS_SESSION += 1

    updateBossButton()
    queueSave()
end

local function bossWorker(mySession)
    MineRemote = getMineRemote()

    if not MineRemote then
        AUTO_BOSS = false
        updateBossButton()
        queueSave()
        return
    end

    while AUTO_BOSS and not UNLOADED and BOSS_SESSION == mySession do
        local boss = getDiamondFist()

        if boss then
            local humanoid, root = getCharacterParts()

            if humanoid and root then
                local fist = getBossFistPart(boss, root)

                if fist then
                    local now = os.clock()

                    if now - lastBossTeleport >= BOSS_TELEPORT_INTERVAL then
                        lastBossTeleport = now

                        pcall(function()
                            root.CFrame = fist.CFrame
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end

                    if now - lastBossAttack >= BOSS_ATTACK_INTERVAL then
                        lastBossAttack = now

                        pcall(function()
                            MineRemote:FireServer(boss)
                        end)
                    end
                end
            end
        end

        task.wait(0.03)
    end
end

local function startBoss()
    if AUTO_BOSS or UNLOADED then return end
    if not getMineRemote() then return end

    AUTO_BOSS = true
    BOSS_SESSION += 1

    lastBossTeleport = 0
    lastBossAttack = 0

    local mySession = BOSS_SESSION

    updateBossButton()
    queueSave()

    task.spawn(function()
        local success = xpcall(function()
            bossWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success and BOSS_SESSION == mySession then
            AUTO_BOSS = false
            updateBossButton()
            queueSave()
        end
    end)
end

bossButton.MouseButton1Click:Connect(function()
    if AUTO_BOSS then
        stopBoss()
    else
        startBoss()
    end
end)

local function findRock(zoneName)
    local folder = getRocksFolder(zoneName)

    if not folder then return nil end

    local _, root = getCharacterParts()
    local nearestLucky
    local nearestNormal
    local luckyDistance = math.huge
    local normalDistance = math.huge

    for _, rock in ipairs(folder:GetChildren()) do
        if validRock(rock, zoneName)
            and os.clock() >= (skippedRocks[rock] or 0) then

            local part = getRockPart(rock)

            if part then
                local distance = root
                    and (root.Position - part.Position).Magnitude
                    or 0

                if rock:GetAttribute("Lucky") == true then
                    if distance < luckyDistance then
                        luckyDistance = distance
                        nearestLucky = rock
                    end
                elseif distance < normalDistance then
                    normalDistance = distance
                    nearestNormal = rock
                end
            end
        end
    end

    return nearestLucky or nearestNormal
end

local function rescanZone(zoneName)
    if not getRocksFolder(zoneName) then
        currentRock = nil
        return false
    end

    local candidate = findRock(zoneName)

    if currentRock and not validRock(currentRock, zoneName) then
        currentRock = nil
        trackedRock = nil
        trackedRockStartHP = nil
        trackedRockStartTime = 0

        nextTeleportAt = 0
        nextRockAt = os.clock() + NEXT_ROCK_DELAY
    end

    if currentRock then
        local currentIsLucky = currentRock:GetAttribute("Lucky") == true
        local candidateIsLucky = candidate
            and candidate:GetAttribute("Lucky") == true

        if not currentIsLucky and candidateIsLucky then
            currentRock = candidate
            trackedRock = nil
            trackedRockStartHP = nil
            trackedRockStartTime = 0
            nextTeleportAt = 0
        end
    elseif os.clock() >= nextRockAt then
        currentRock = candidate
        nextTeleportAt = 0
    end

    return true
end

local function miningCycle(mySession)
    if not RUNNING or SESSION ~= mySession then return end

    local zoneName = selectedZone

    if not zoneName then
        task.wait(SCAN_DELAY)
        return
    end

    local now = os.clock()

    if now - lastRescan >= RESCAN_INTERVAL then
        lastRescan = now

        if not rescanZone(zoneName) then
            task.wait(SCAN_DELAY)
            return
        end
    end

    if not currentRock and os.clock() >= nextRockAt then
        currentRock = findRock(zoneName)
        nextTeleportAt = 0
    end

    if not currentRock then
        task.wait(SCAN_DELAY)
        return
    end

    local rock = currentRock

    if not validRock(rock, zoneName) then
        currentRock = nil
        nextTeleportAt = 0
        return
    end

    local humanoid, root = getCharacterParts()
    local part = getRockPart(rock)

    if not humanoid or not root or not part then
        task.wait(SCAN_DELAY)
        return
    end

    local targetPosition = getPositionAboveOre(rock, root)

    if not targetPosition then
        task.wait(SCAN_DELAY)
        return
    end

    local distance = (root.Position - targetPosition).Magnitude

    if distance > TELEPORT_SUCCESS_DISTANCE then
        if os.clock() < nextTeleportAt then
            task.wait(0.2)
            return
        end

        root.CFrame = CFrame.new(targetPosition)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        task.wait(TELEPORT_SETTLE_DELAY)

        if not RUNNING or SESSION ~= mySession
            or selectedZone ~= zoneName then
            return
        end

        humanoid, root = getCharacterParts()
        part = getRockPart(rock)

        if not humanoid or not root or not part then
            task.wait(SCAN_DELAY)
            return
        end

        targetPosition = getPositionAboveOre(rock, root)

        if not targetPosition then return end

        distance = (root.Position - targetPosition).Magnitude

        if distance > TELEPORT_SUCCESS_DISTANCE then
            nextTeleportAt = os.clock() + TELEPORT_RETRY_DELAY
            return
        end

        nextTeleportAt = 0
        return
    end

    local oldHP = rock:GetAttribute("HP")

    if trackedRock ~= rock then
        trackedRock = rock
        trackedRockStartHP = oldHP
        trackedRockStartTime = os.clock()
    end

    local success = pcall(function()
        MineRemote:FireServer(rock)
    end)

    if not success then
        task.wait(ERROR_RETRY_DELAY)
        return
    end

    task.wait(MINING_INTERVAL)

    if not RUNNING or SESSION ~= mySession
        or selectedZone ~= zoneName then
        return
    end

    if validRock(rock, zoneName) then
        local newHP = rock:GetAttribute("HP")

        if newHP >= trackedRockStartHP
            and os.clock() - trackedRockStartTime >= NO_DAMAGE_TIMEOUT then

            skippedRocks[rock] = os.clock() + SKIP_DURATION

            currentRock = nil
            trackedRock = nil
            trackedRockStartHP = nil
            trackedRockStartTime = 0

            nextTeleportAt = 0
            nextRockAt = 0
            return
        end
    else
        currentRock = nil
        trackedRock = nil
        trackedRockStartHP = nil
        trackedRockStartTime = 0

        nextTeleportAt = 0
        nextRockAt = os.clock() + NEXT_ROCK_DELAY
        lastRescan = 0
    end
end

local function miningWorker(mySession)
    while RUNNING and not UNLOADED and SESSION == mySession do
        local success = xpcall(function()
            miningCycle(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success then
            task.wait(ERROR_RETRY_DELAY)
        end

        if not RUNNING or SESSION ~= mySession then
            break
        end

        task.wait(0.05)
    end
end

local function startMining()
    if UNLOADED or RUNNING then return end
    if not selectedZone then return end

    local remote = getMineRemote()
    if not remote then return end

    MineRemote = remote

    SESSION += 1
    RUNNING = true

    currentRock = nil
    trackedRock = nil
    trackedRockStartHP = nil
    trackedRockStartTime = 0

    nextTeleportAt = 0
    nextRockAt = 0
    lastRescan = 0

    local mySession = SESSION

    task.spawn(function()
        local success = xpcall(function()
            miningWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success and SESSION == mySession then
            RUNNING = false
        elseif SESSION == mySession and RUNNING then
            RUNNING = false
        end
    end)
end

local function stopMining()
    RUNNING = false
    SESSION += 1

    currentRock = nil
    trackedRock = nil
    trackedRockStartHP = nil
    trackedRockStartTime = 0

    nextTeleportAt = 0
    nextRockAt = 0
    lastRescan = 0
end

startButton.MouseButton1Click:Connect(startMining)
stopButton.MouseButton1Click:Connect(stopMining)

local function updateLayout(animate)
    if guiMinimized then
        zoneToggle.Visible = false
        search.Visible = false
        scroll.Visible = false
        selectedLabel.Visible = false
        startButton.Visible = false
        bossButton.Visible = false
        stopButton.Visible = false

        minimize.Text = "+"
        main.Size = UDim2.fromOffset(290, 35)
        return
    end

    zoneToggle.Visible = true
    selectedLabel.Visible = true
    startButton.Visible = true
    bossButton.Visible = true
    stopButton.Visible = true

    minimize.Text = "-"

    if selectorExpanded then
        main.Size = UDim2.fromOffset(290, 251)

        zoneToggle.Text = "ZONES ▼"
        search.Visible = true
        scroll.Visible = true

        search.Position = UDim2.fromOffset(10, 63)
        scroll.Position = UDim2.fromOffset(10, 91)

        selectedLabel.Position = UDim2.fromOffset(10, 186)

        startButton.Position = UDim2.fromOffset(10, 209)
        bossButton.Position = UDim2.fromOffset(102, 209)
        stopButton.Position = UDim2.fromOffset(194, 209)
    else
        main.Size = UDim2.fromOffset(290, 129)

        zoneToggle.Text = "ZONES ▲"
        search.Visible = false
        scroll.Visible = false

        selectedLabel.Position = UDim2.fromOffset(10, 63)

        startButton.Position = UDim2.fromOffset(10, 87)
        bossButton.Position = UDim2.fromOffset(102, 87)
        stopButton.Position = UDim2.fromOffset(194, 87)
    end

    if animate then
        local targetSize = main.Size
        main.Size = UDim2.fromOffset(290, 35)

        TweenService:Create(main, TweenInfo.new(0.25), {
            Size = targetSize
        }):Play()
    end
end

zoneToggle.MouseButton1Click:Connect(function()
    selectorExpanded = not selectorExpanded
    queueSave()
    updateLayout(true)
end)

minimize.MouseButton1Click:Connect(function()
    guiMinimized = not guiMinimized
    queueSave()
    updateLayout(true)
end)

close.MouseButton1Click:Connect(function()
    saveConfig()

    UNLOADED = true

    RUNNING = false
    SESSION += 1

    AUTO_BOSS = false
    BOSS_SESSION += 1

    AUTO_BUY = false
    BUY_SESSION += 1

    gui:Destroy()
end)

task.spawn(function()
    while not UNLOADED and gui.Parent do
        task.wait(5)
        saveConfig()
    end
end)

task.spawn(function()
    while not UNLOADED and gui.Parent do
        task.wait(0.7)

        TweenService:Create(mainStroke, TweenInfo.new(0.7), {
            Transparency = 0.25
        }):Play()

        task.wait(0.7)

        TweenService:Create(mainStroke, TweenInfo.new(0.7), {
            Transparency = 0.55
        }):Play()
    end
end)

game:BindToClose(function()
    saveConfig()
end)

updateSelection()
refreshZoneSearch()
updateMinerRows()
updateAutoBuyButton()
updateBossButton()
updateLayout(false)

setPurchaseStatus("AUTO BUY: OFF")

task.spawn(function()
    task.wait(2)

    if UNLOADED then return end

    if resumeBoss then
        startBoss()
        task.wait(1)
    end

    if resumeBuy and not UNLOADED then
        startAutoBuy()
    end

    saveConfig()
end)
