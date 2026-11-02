
--// MULTI-ZONE AUTO MINER V18
--// Compact Black & Neon White GUI
--// Auto Configuration Save
--// Searchable Zones + Player Counter
--// Real Executor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ZonesFolder = workspace:WaitForChild("Zones")

--==================================================
-- SETTINGS
--==================================================

local MINING_INTERVAL = 0.1
local TELEPORT_RETRY_DELAY = 2.5
local TELEPORT_SUCCESS_DISTANCE = 18

local NEXT_ROCK_DELAY = 0
local SCAN_DELAY = 0.4
local RESCAN_INTERVAL = 2
local ERROR_RETRY_DELAY = 1

local NO_DAMAGE_TIMEOUT = 0.5
local SKIP_DURATION = 3

--==================================================
-- THEME
--==================================================

local BLACK = Color3.fromRGB(5, 5, 5)
local PANEL = Color3.fromRGB(14, 14, 14)
local PANEL2 = Color3.fromRGB(22, 22, 22)
local WHITE = Color3.fromRGB(255, 255, 255)
local GREY = Color3.fromRGB(155, 155, 155)
local DARK_GREY = Color3.fromRGB(65, 65, 65)

--==================================================
-- ZONES
--==================================================

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

--==================================================
-- STATE
--==================================================

local RUNNING = false
local UNLOADED = false
local SESSION = 0

local selectedZone = nil
local currentRock = nil

local trackedRock = nil
local trackedRockStartHP = nil
local trackedRockStartTime = 0

local skippedRocks = setmetatable({}, {__mode = "k"})

local nextTeleportAt = 0
local nextRockAt = 0
local lastRescan = 0

local availableZones = {}
local zoneRows = {}

local selectorExpanded = true
local guiMinimized = false

local MineRemote = nil

--==================================================
-- CONFIGURATION SAVE SYSTEM
--==================================================

local HttpService = game:GetService("HttpService")

local CONFIG_FILE = "MultiZoneMinerV18.json"

local savedConfig = {}
local savedGuiPosition = nil
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
        SelectorExpanded = selectorExpanded,
        GuiMinimized = guiMinimized,
        GuiPosition = savedGuiPosition
    }

    local success = pcall(function()
        writefile(
            CONFIG_FILE,
            HttpService:JSONEncode(config)
        )
    end)

    return success
end

local function queueSave()
    if saveQueued or UNLOADED then
        return
    end

    saveQueued = true

    task.delay(0.5, function()
        saveQueued = false

        if not UNLOADED then
            saveConfig()
        end
    end)
end

--==================================================
-- DETECT AVAILABLE ZONES
--==================================================

for _, entry in ipairs(zoneOrder) do
    local zone = ZonesFolder:FindFirstChild(entry[1])

    if zone and zone:FindFirstChild("Rocks") then
        table.insert(availableZones, {
            Folder = entry[1],
            Display = entry[2]
        })

        if entry[1] == "Glacier" then
            selectedZone = entry[1]
        end
    end
end

if not selectedZone and availableZones[1] then
    selectedZone = availableZones[1].Folder
end

-- Load saved settings AFTER detecting zones.

loadConfig()

if savedConfig.SelectedZone then
    for _, entry in ipairs(availableZones) do
        if entry.Folder == savedConfig.SelectedZone then
            selectedZone = entry.Folder
            break
        end
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

local function getDisplayName(name)
    for _, entry in ipairs(availableZones) do
        if entry.Folder == name then
            return entry.Display
        end
    end

    return tostring(name or "Unknown")
end

--==================================================
-- REMOVE OLD GUI
--==================================================

local old = PlayerGui:FindFirstChild("MultiZoneMinerV18")

if old then
    old:Destroy()
end

--==================================================
-- GUI CREATION
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "MultiZoneMinerV18"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 7)
    c.Parent = object
    return c
end

local function stroke(object, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or WHITE
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = object
    return s
end

local function tween(object, duration, properties)
    local info = TweenInfo.new(
        duration,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )

    local animation = TweenService:Create(
        object,
        info,
        properties
    )

    animation:Play()
    return animation
end

--==================================================
-- MAIN WINDOW
--==================================================

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(290, 310)
main.Position = UDim2.new(0.5, -145, 0.5, -155)
main.BackgroundColor3 = BLACK
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui

corner(main, 10)

local mainStroke = stroke(main, WHITE, 1, 0.45)

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

--==================================================
-- TITLE BAR
--==================================================

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -85, 0, 30)
title.Position = UDim2.fromOffset(12, 3)
title.BackgroundTransparency = 1
title.Text = "AUTO MINER  /  V18"
title.TextColor3 = WHITE
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(24, 23)
minimize.Position = UDim2.new(1, -57, 0, 5)
minimize.BackgroundColor3 = PANEL2
minimize.Text = "-"
minimize.TextColor3 = WHITE
minimize.TextSize = 17
minimize.Font = Enum.Font.GothamBold
minimize.Parent = main

corner(minimize, 5)
local minimizeStroke = stroke(minimize, WHITE, 1, 0.7)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(24, 23)
close.Position = UDim2.new(1, -29, 0, 5)
close.BackgroundColor3 = PANEL2
close.Text = "X"
close.TextColor3 = WHITE
close.TextSize = 12
close.Font = Enum.Font.GothamBold
close.Parent = main

corner(close, 5)
local closeStroke = stroke(close, WHITE, 1, 0.4)

--==================================================
-- HOVER ANIMATIONS
--==================================================

local function addHover(button, normalColor, hoverColor, outline)
    button.MouseEnter:Connect(function()
        tween(button, 0.15, {
            BackgroundColor3 = hoverColor
        })

        if outline then
            tween(outline, 0.15, {
                Transparency = 0
            })
        end
    end)

    button.MouseLeave:Connect(function()
        tween(button, 0.15, {
            BackgroundColor3 = normalColor
        })

        if outline then
            tween(outline, 0.15, {
                Transparency = 0.6
            })
        end
    end)
end

addHover(minimize, PANEL2, Color3.fromRGB(48, 48, 48), minimizeStroke)
addHover(close, PANEL2, Color3.fromRGB(65, 65, 65), closeStroke)

--==================================================
-- STATUS
--==================================================

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 19)
status.Position = UDim2.fromOffset(10, 35)
status.BackgroundTransparency = 1
status.Text = "●  STOPPED"
status.TextColor3 = GREY
status.TextSize = 11
status.Font = Enum.Font.GothamBold
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Parent = main

--==================================================
-- PLAYER COUNTER
--==================================================

local playerCounter = Instance.new("TextLabel")
playerCounter.Size = UDim2.new(1, -20, 0, 17)
playerCounter.Position = UDim2.fromOffset(10, 54)
playerCounter.BackgroundTransparency = 1
playerCounter.TextColor3 = GREY
playerCounter.TextSize = 10
playerCounter.Font = Enum.Font.Gotham
playerCounter.TextXAlignment = Enum.TextXAlignment.Left
playerCounter.Parent = main

local function updatePlayerCount()
    if UNLOADED then return end

    playerCounter.Text = "PLAYERS ONLINE   " .. #Players:GetPlayers()
end

Players.PlayerAdded:Connect(updatePlayerCount)
Players.PlayerRemoving:Connect(updatePlayerCount)

updatePlayerCount()

--==================================================
-- ZONE TOGGLE
--==================================================

local zoneToggle = Instance.new("TextButton")
zoneToggle.Size = UDim2.new(1, -20, 0, 23)
zoneToggle.Position = UDim2.fromOffset(10, 76)
zoneToggle.BackgroundColor3 = PANEL2
zoneToggle.Text = "ZONES  ▼"
zoneToggle.TextColor3 = WHITE
zoneToggle.TextSize = 10
zoneToggle.Font = Enum.Font.GothamBold
zoneToggle.Parent = main

corner(zoneToggle, 5)
local zoneToggleStroke = stroke(zoneToggle, WHITE, 1, 0.75)

addHover(zoneToggle, PANEL2, Color3.fromRGB(42, 42, 42), zoneToggleStroke)

--==================================================
-- SEARCH BOX
--==================================================

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -20, 0, 23)
search.Position = UDim2.fromOffset(10, 104)
search.BackgroundColor3 = PANEL
search.BorderSizePixel = 0
search.PlaceholderText = "Search zones..."
search.PlaceholderColor3 = DARK_GREY
search.Text = ""
search.TextColor3 = WHITE
search.TextSize = 10
search.Font = Enum.Font.Gotham
search.ClearTextOnFocus = false
search.TextXAlignment = Enum.TextXAlignment.Left
search.Parent = main

corner(search, 5)
stroke(search, WHITE, 1, 0.8)

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 8)
searchPadding.Parent = search

--==================================================
-- ZONE SCROLL
--==================================================

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 0, 90)
scroll.Position = UDim2.fromOffset(10, 132)
scroll.BackgroundColor3 = PANEL
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = WHITE
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = main

corner(scroll, 6)
stroke(scroll, WHITE, 1, 0.85)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 5)
scrollPadding.PaddingLeft = UDim.new(0, 5)
scrollPadding.PaddingRight = UDim.new(0, 5)
scrollPadding.PaddingBottom = UDim.new(0, 5)
scrollPadding.Parent = scroll

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.fromOffset(
        0,
        layout.AbsoluteContentSize.Y + 10
    )
end)

--==================================================
-- SELECTED ZONE
--==================================================

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, -20, 0, 17)
selectedLabel.Position = UDim2.fromOffset(10, 228)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = WHITE
selectedLabel.TextSize = 10
selectedLabel.Font = Enum.Font.GothamBold
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = main

--==================================================
-- ROCK HP
--==================================================

local rockInfo = Instance.new("TextLabel")
rockInfo.Size = UDim2.new(1, -20, 0, 16)
rockInfo.Position = UDim2.fromOffset(10, 246)
rockInfo.BackgroundTransparency = 1
rockInfo.Text = "CURRENT ROCK   --"
rockInfo.TextColor3 = GREY
rockInfo.TextSize = 10
rockInfo.Font = Enum.Font.Gotham
rockInfo.TextXAlignment = Enum.TextXAlignment.Left
rockInfo.Parent = main

--==================================================
-- START / STOP BUTTONS
--==================================================

local function makeButton(text, x, color)
    local button = Instance.new("TextButton")

    button.Size = UDim2.fromOffset(130, 32)
    button.Position = UDim2.fromOffset(x, 267)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = WHITE
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Parent = main

    corner(button, 6)

    local outline = stroke(button, WHITE, 1, 0.7)

    return button, outline
end

local startButton, startStroke = makeButton(
    "START MINING",
    10,
    Color3.fromRGB(28, 28, 28)
)

local stopButton, stopStroke = makeButton(
    "STOP",
    150,
    Color3.fromRGB(28, 28, 28)
)

addHover(startButton, Color3.fromRGB(28, 28, 28), Color3.fromRGB(65, 65, 65), startStroke)
addHover(stopButton, Color3.fromRGB(28, 28, 28), Color3.fromRGB(65, 65, 65), stopStroke)

--==================================================
-- STATUS HELPERS
--==================================================

local function setStatus(message)
    if UNLOADED or not status or not status.Parent then
        return
    end

    status.Text = "●  " .. tostring(message)
end

--==================================================
-- ZONE SELECTION
--==================================================

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

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -3, 0, 23)
    row.BackgroundColor3 = PANEL2
    row.BorderSizePixel = 0
    row.TextColor3 = GREY
    row.TextSize = 10
    row.Font = Enum.Font.Gotham
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.LayoutOrder = index
    row.Parent = scroll

    corner(row, 4)

    zoneRows[folderName] = row

    row.MouseEnter:Connect(function()
        if folderName ~= selectedZone then
            tween(row, 0.12, {
                BackgroundColor3 = Color3.fromRGB(42, 42, 42)
            })
        end
    end)

    row.MouseLeave:Connect(function()
        if folderName ~= selectedZone then
            tween(row, 0.12, {
                BackgroundColor3 = PANEL2
            })
        end
    end)

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

        setStatus("ZONE CHANGED")
        rockInfo.Text = "CURRENT ROCK   --"
    end)
end

updateSelection()

search:GetPropertyChangedSignal("Text"):Connect(refreshZoneSearch)

--==================================================
-- ROCK HELPERS
--==================================================

local function getRocksFolder(zoneName)
    local zone = ZonesFolder:FindFirstChild(zoneName)

    return zone and zone:FindFirstChild("Rocks")
end

local function getRockPart(rock)
    if not rock then
        return nil
    end

    return rock.PrimaryPart
        or rock:FindFirstChildWhichIsA("BasePart", true)
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

local function findRock(zoneName)
    local folder = getRocksFolder(zoneName)

    if not folder then
        return nil
    end

    local bestRock = nil
    local lowestHP = math.huge

    for _, rock in ipairs(folder:GetChildren()) do
        if validRock(rock, zoneName) then
            local hp = rock:GetAttribute("HP")
            local skipUntil = skippedRocks[rock] or 0

            if os.clock() >= skipUntil and hp < lowestHP then
                lowestHP = hp
                bestRock = rock
            end
        end
    end

    return bestRock
end

--==================================================
-- CHARACTER HELPERS
--==================================================

local function getCharacterParts()
    local character = Player.Character

    if not character then
        return nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return nil, nil
    end

    return humanoid, root
end

local function getDistance(root, part)
    return (root.Position - part.Position).Magnitude
end

--==================================================
-- PERIODIC SCAN
--==================================================

local function rescanZone(zoneName)
    local folder = getRocksFolder(zoneName)

    if not folder then
        currentRock = nil
        return false
    end

    if currentRock and not validRock(currentRock, zoneName) then
        currentRock = nil
        trackedRock = nil
        trackedRockStartHP = nil
        trackedRockStartTime = 0

        nextTeleportAt = 0
        nextRockAt = os.clock() + NEXT_ROCK_DELAY
    end

    if not currentRock and os.clock() >= nextRockAt then
        currentRock = findRock(zoneName)
        nextTeleportAt = 0
    end

    return true
end

--==================================================
-- MINING CYCLE
--==================================================

local function miningCycle(mySession)
    if not RUNNING or SESSION ~= mySession then
        return
    end

    local zoneName = selectedZone

    if not zoneName then
        setStatus("NO ZONE SELECTED")
        task.wait(SCAN_DELAY)
        return
    end

    local now = os.clock()

    if now - lastRescan >= RESCAN_INTERVAL then
        lastRescan = now

        if not rescanZone(zoneName) then
            setStatus("SCANNING FOR ZONE")
            task.wait(SCAN_DELAY)
            return
        end
    end

    if not currentRock and os.clock() >= nextRockAt then
        currentRock = findRock(zoneName)
        nextTeleportAt = 0
    end

    if not currentRock then
        setStatus("SCANNING " .. string.upper(getDisplayName(zoneName)))
        rockInfo.Text = "CURRENT ROCK   --"
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
        setStatus("WAITING FOR CHARACTER")
        task.wait(SCAN_DELAY)
        return
    end

    -- TELEPORT

    local distance = getDistance(root, part)

    if distance > TELEPORT_SUCCESS_DISTANCE then
        if os.clock() < nextTeleportAt then
            setStatus("WAITING FOR MOVEMENT")
            task.wait(0.2)
            return
        end

        setStatus("MOVING TO ROCK")

        root.CFrame = part.CFrame * CFrame.new(0, 0, 3)

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

        distance = getDistance(root, part)

        if distance > TELEPORT_SUCCESS_DISTANCE then
            nextTeleportAt = os.clock() + TELEPORT_RETRY_DELAY
            setStatus("MOVEMENT NOT ACCEPTED")
            return
        end

        nextTeleportAt = 0
        setStatus("REACHED ROCK")
        return
    end

    -- MINE

    local oldHP = rock:GetAttribute("HP")

    if trackedRock ~= rock then
        trackedRock = rock
        trackedRockStartHP = oldHP
        trackedRockStartTime = os.clock()
    end

    local success, err = pcall(function()
        MineRemote:FireServer(rock)
    end)

    if not success then
        setStatus("MINE ERROR: " .. tostring(err):sub(1, 50))
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

        rockInfo.Text = "CURRENT ROCK   HP: " .. tostring(newHP)

        -- NO DAMAGE DETECTION

        if newHP >= trackedRockStartHP
            and os.clock() - trackedRockStartTime >= NO_DAMAGE_TIMEOUT then

            skippedRocks[rock] = os.clock() + SKIP_DURATION

            currentRock = nil
            trackedRock = nil
            trackedRockStartHP = nil
            trackedRockStartTime = 0

            nextTeleportAt = 0
            nextRockAt = 0

            setStatus("NO DAMAGE - SWITCHING ORE")
            return
        end

        setStatus("MINING " .. string.upper(getDisplayName(zoneName)))

    else
        currentRock = nil
        trackedRock = nil
        trackedRockStartHP = nil
        trackedRockStartTime = 0

        nextTeleportAt = 0
        nextRockAt = os.clock() + NEXT_ROCK_DELAY
        lastRescan = 0

        rockInfo.Text = "CURRENT ROCK   DESTROYED"
        setStatus("ROCK DESTROYED - SEARCHING")
    end
end

--==================================================
-- WORKER SUPERVISOR
--==================================================

local function miningWorker(mySession)
    while RUNNING
        and not UNLOADED
        and SESSION == mySession do

        local success, err = xpcall(function()
            miningCycle(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success then
            setStatus("WORKER ERROR: " .. tostring(err):sub(1, 55))
            task.wait(ERROR_RETRY_DELAY)
        end

        if not RUNNING or SESSION ~= mySession then
            break
        end

        task.wait(0.05)
    end
end

--==================================================
-- START BUTTON
--==================================================

startButton.MouseButton1Click:Connect(function()
    if UNLOADED or RUNNING then
        return
    end

    if not selectedZone then
        setStatus("NO ZONE AVAILABLE")
        return
    end

    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("MineRock")

    if not remote or not remote:IsA("RemoteEvent") then
        MineRemote = nil
        setStatus("MINEROCK REMOTE NOT FOUND")
        return
    end

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

    setStatus("STARTING MINER")
    rockInfo.Text = "CURRENT ROCK   SEARCHING"

    tween(startButton, 0.15, {
        BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    })

    task.spawn(function()
        local success, err = xpcall(function()
            miningWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success and SESSION == mySession then
            RUNNING = false
            setStatus("FATAL ERROR: " .. tostring(err):sub(1, 50))

        elseif SESSION == mySession and RUNNING then
            RUNNING = false
            setStatus("WORKER EXITED")
        end
    end)
end)

--==================================================
-- STOP BUTTON
--==================================================

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

    setStatus("STOPPED")
    rockInfo.Text = "CURRENT ROCK   --"

    tween(stopButton, 0.15, {
        BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    })
end

stopButton.MouseButton1Click:Connect(stopMining)

--==================================================
-- GUI LAYOUT
--==================================================

local function updateLayout(animate)
    if guiMinimized then
        status.Visible = false
        playerCounter.Visible = false
        zoneToggle.Visible = false
        search.Visible = false
        scroll.Visible = false
        selectedLabel.Visible = false
        rockInfo.Visible = false
        startButton.Visible = false
        stopButton.Visible = false

        minimize.Text = "+"

        tween(main, animate and 0.22 or 0, {
            Size = UDim2.fromOffset(290, 35)
        })

        return
    end

    status.Visible = true
    playerCounter.Visible = true
    zoneToggle.Visible = true
    selectedLabel.Visible = true
    rockInfo.Visible = true
    startButton.Visible = true
    stopButton.Visible = true

    minimize.Text = "-"

    if selectorExpanded then
        main.Size = UDim2.fromOffset(290, 310)

        zoneToggle.Text = "ZONES  ▼"

        search.Visible = true
        scroll.Visible = true

        search.Position = UDim2.fromOffset(10, 104)
        scroll.Position = UDim2.fromOffset(10, 132)

        selectedLabel.Position = UDim2.fromOffset(10, 228)
        rockInfo.Position = UDim2.fromOffset(10, 246)

        startButton.Position = UDim2.fromOffset(10, 267)
        stopButton.Position = UDim2.fromOffset(150, 267)

    else
        main.Size = UDim2.fromOffset(290, 195)

        zoneToggle.Text = "ZONES  ▲"

        search.Visible = false
        scroll.Visible = false

        selectedLabel.Position = UDim2.fromOffset(10, 107)
        rockInfo.Position = UDim2.fromOffset(10, 125)

        startButton.Position = UDim2.fromOffset(10, 151)
        stopButton.Position = UDim2.fromOffset(150, 151)
    end

    if animate then
        local targetSize = main.Size

        main.Size = UDim2.fromOffset(290, 35)

        tween(main, 0.25, {
            Size = targetSize
        })
    end
end

--==================================================
-- ZONE LIST ANIMATION
--==================================================

zoneToggle.MouseButton1Click:Connect(function()
    selectorExpanded = not selectorExpanded

    queueSave()
    updateLayout(true)
end)

--==================================================
-- MINIMIZE / RESTORE
--==================================================

minimize.MouseButton1Click:Connect(function()
    guiMinimized = not guiMinimized

    queueSave()
    updateLayout(true)
end)

--==================================================
-- CLOSE / UNLOAD
--==================================================

close.MouseButton1Click:Connect(function()
    saveConfig()

    UNLOADED = true
    RUNNING = false
    SESSION += 1

    gui:Destroy()
end)

--==================================================
-- ANIMATED STATUS INDICATOR
--==================================================

task.spawn(function()
    local pulse = false

    while not UNLOADED and gui.Parent do
        pulse = not pulse

        tween(mainStroke, 0.7, {
            Transparency = pulse and 0.2 or 0.55
        })

        task.wait(0.7)
    end
end)

--==================================================
-- SAVE CONFIGURATION ON UNLOAD
--==================================================

game:BindToClose(function()
    if not UNLOADED then
        saveConfig()
    end
end)

--==================================================
-- INITIALIZE
--==================================================

updateSelection()
refreshZoneSearch()
updateLayout(false)

setStatus("STOPPED")

print("[Multi-Zone Miner V18] Loaded successfully")
print("[Multi-Zone Miner V18] Available zones: " .. #availableZones)
