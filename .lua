--// MULTI-ZONE AUTO MINER V17
--// Periodic rescanning + worker error recovery
--// Real Executor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ZonesFolder = workspace:WaitForChild("Zones")

-- Resolve the mining remote only when Start is pressed.
-- This prevents a missing/late remote from blocking GUI creation.
local MineRemote = nil

local function resolveMineRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("MineRock")

    if remote and (remote:IsA("RemoteEvent")) then
        MineRemote = remote
        return true
    end

    MineRemote = nil
    return false
end

-- SETTINGS
local MINING_INTERVAL = 0.1
local TELEPORT_RETRY_DELAY = 2.5
local TELEPORT_SUCCESS_DISTANCE = 18

local NEXT_ROCK_DELAY = 0
local SCAN_DELAY = 0.4
local RESCAN_INTERVAL = 2
local ERROR_RETRY_DELAY = 1

-- ZONES
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

-- STATE
local RUNNING = false
local UNLOADED = false
local SESSION = 0

local selectedZone = nil
local currentRock = nil
local trackedRock = nil
local trackedRockStartHP = nil
local trackedRockStartTime = 0
local skippedRocks = setmetatable({}, { __mode = "k" })

local nextTeleportAt = 0
local nextRockAt = 0
local lastRescan = 0

local availableZones = {}
local zoneRows = {}

local selectorExpanded = true
local guiMinimized = false

-- FIND AVAILABLE ZONES
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

local function getDisplayName(name)
    if name == nil then
        return "Unknown zone"
    end

    for index = 1, #availableZones do
        local entry = availableZones[index]
        if entry.Folder == name then
            return entry.Display
        end
    end

    return tostring(name)
end

-- REMOVE OLD GUI
local old = PlayerGui:FindFirstChild("MultiZoneMinerV17")

if old then
    old:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MultiZoneMinerV17"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 7)
    corner.Parent = object
end

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(310, 255)
main.Position = UDim2.new(0.5, -155, 0.5, -127)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
addCorner(main)

-- TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -85, 0, 30)
title.Position = UDim2.fromOffset(10, 4)
title.BackgroundTransparency = 1
title.Text = "Multi-Zone Auto Miner V17"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

-- MINIMIZE
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(25, 25)
minimize.Position = UDim2.new(1, -60, 0, 5)
minimize.Text = "-"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 16
minimize.Parent = main
addCorner(minimize)

-- CLOSE
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(25, 25)
close.Position = UDim2.new(1, -30, 0, 5)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(170, 55, 55)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = main
addCorner(close)

-- STATUS
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.fromOffset(10, 34)
status.BackgroundTransparency = 1
status.Text = "Status: Stopped"
status.TextColor3 = Color3.fromRGB(220, 220, 220)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Parent = main

-- ZONE TOGGLE
local zoneToggle = Instance.new("TextButton")
zoneToggle.Size = UDim2.new(1, -20, 0, 25)
zoneToggle.Position = UDim2.fromOffset(10, 57)
zoneToggle.BackgroundColor3 = Color3.fromRGB(48, 58, 78)
zoneToggle.Text = "HIDE ZONES  -"
zoneToggle.TextColor3 = Color3.new(1, 1, 1)
zoneToggle.TextSize = 12
zoneToggle.Font = Enum.Font.GothamBold
zoneToggle.Parent = main
addCorner(zoneToggle)

-- ZONE LIST
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 0, 100)
scroll.Position = UDim2.fromOffset(10, 86)
scroll.BackgroundColor3 = Color3.fromRGB(17, 17, 23)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = main
addCorner(scroll)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.fromOffset(
        0,
        layout.AbsoluteContentSize.Y + 5
    )
end)

-- SELECTED ZONE
local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, -20, 0, 18)
selectedLabel.Position = UDim2.fromOffset(10, 190)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = Color3.fromRGB(170, 200, 230)
selectedLabel.TextSize = 11
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = main

-- BUTTON CREATOR
local function makeButton(text, x, y, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(140, 35)
    button.Position = UDim2.fromOffset(x, y)
    button.BackgroundColor3 = color
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Parent = main

    addCorner(button)

    return button
end

local startButton = makeButton(
    "START",
    10,
    214,
    Color3.fromRGB(40, 145, 75)
)

local stopButton = makeButton(
    "STOP",
    160,
    214,
    Color3.fromRGB(160, 55, 55)
)

local function setStatus(message)
    if not UNLOADED and status and status.Parent then
        status.Text = tostring(message)
    end
end

-- ZONE SELECTION
local function updateSelection()
    selectedLabel.Text = "Selected zone: "
        .. getDisplayName(selectedZone)

    for zoneName, row in pairs(zoneRows) do
        local selected = zoneName == selectedZone

        row.Text = (selected and "●  " or "○  ")
            .. getDisplayName(zoneName)

        row.BackgroundColor3 = selected
            and Color3.fromRGB(40, 105, 70)
            or Color3.fromRGB(38, 38, 48)
    end
end

for index, entry in ipairs(availableZones) do
    local folderName = entry.Folder

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -8, 0, 25)
    row.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    row.BorderSizePixel = 0
    row.TextColor3 = Color3.new(1, 1, 1)
    row.TextSize = 12
    row.Font = Enum.Font.Gotham
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.LayoutOrder = index
    row.Parent = scroll

    addCorner(row, 5)

    zoneRows[folderName] = row

    row.MouseButton1Click:Connect(function()
        selectedZone = folderName

        currentRock = nil
        nextTeleportAt = 0
        nextRockAt = 0
        lastRescan = 0

        updateSelection()
        setStatus("Selected: " .. getDisplayName(folderName))
    end)
end

updateSelection()

-- ROCK HELPERS
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

    -- The rock's parent folder already identifies its zone.
    -- Some ores may have a missing or inconsistent ZoneId attribute,
    -- so do not reject a rock solely because that attribute differs.
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

-- CHARACTER HELPERS
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

-- PERIODIC SCAN
local function rescanZone(zoneName)
    local folder = getRocksFolder(zoneName)

    if not folder then
        currentRock = nil
        return false
    end

    -- Keep a living target. Clear it only if destroyed or removed.
    if currentRock and not validRock(currentRock, zoneName) then
        currentRock = nil
        trackedRock = nil
        trackedRockStartHP = nil
        trackedRockStartTime = 0
        nextTeleportAt = 0
        nextRockAt = os.clock() + NEXT_ROCK_DELAY
    end

    -- Do not select a second target while the existing one is alive.
    if not currentRock and os.clock() >= nextRockAt then
        currentRock = findRock(zoneName)
        nextTeleportAt = 0
    end

    return true
end

-- ONE MINING CYCLE
local function miningCycle(mySession)
    if not RUNNING or SESSION ~= mySession then
        return
    end

    local zoneName = selectedZone

    if not zoneName then
        setStatus("No zone selected")
        task.wait(SCAN_DELAY)
        return
    end

    -- RESCAN EVERY TWO SECONDS
    local now = os.clock()

    if now - lastRescan >= RESCAN_INTERVAL then
        lastRescan = now

        if not rescanZone(zoneName) then
            setStatus("Rocks folder missing - rescanning")
            task.wait(SCAN_DELAY)
            return
        end
    end

    -- Search again whenever no target is active.
    if not currentRock and os.clock() >= nextRockAt then
        currentRock = findRock(zoneName)
        nextTeleportAt = 0
    end

    if not currentRock then
        setStatus("Scanning " .. getDisplayName(zoneName) .. "...")
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
        setStatus("Waiting for character...")
        task.wait(SCAN_DELAY)
        return
    end

    -- TELEPORT ATTEMPT
    local distance = getDistance(root, part)

    if distance > TELEPORT_SUCCESS_DISTANCE then
        if os.clock() < nextTeleportAt then
            setStatus("Waiting for movement...")
            task.wait(0.2)
            return
        end

        setStatus("Movement attempt: " .. getDisplayName(zoneName))

        -- Client-side movement may be rejected by the game server.
        root.CFrame = part.CFrame * CFrame.new(0, 0, 3)

        -- No post-teleport wait: verify immediately.

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
            setStatus("Movement not accepted - waiting")
            return
        end

        nextTeleportAt = 0
        setStatus("Reached rock - mining")
        return
    end

    -- MINE THE CURRENT ROCK
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
        setStatus("Mine error: " .. tostring(err):sub(1, 65))
        task.wait(ERROR_RETRY_DELAY)
        return
    end

    task.wait(MINING_INTERVAL)

    if not RUNNING or SESSION ~= mySession
        or selectedZone ~= zoneName then
        return
    end

    -- If this target has taken no damage within 0.5 seconds,
    -- temporarily skip it and move to another ore.
    if validRock(rock, zoneName) then
        local newHP = rock:GetAttribute("HP")

        if newHP >= trackedRockStartHP
            and os.clock() - trackedRockStartTime >= 0.5 then
            skippedRocks[rock] = os.clock() + 3
            currentRock = nil
            trackedRock = nil
            trackedRockStartHP = nil
            trackedRockStartTime = 0
            nextTeleportAt = 0
            nextRockAt = 0
            setStatus("No damage in 0.5s - switching ore")
            return
        end

        setStatus(
            getDisplayName(zoneName)
            .. " | HP: "
            .. tostring(newHP)
        )
    else
        currentRock = nil
        trackedRock = nil
        trackedRockStartHP = nil
        trackedRockStartTime = 0
        nextTeleportAt = 0
        nextRockAt = os.clock() + NEXT_ROCK_DELAY
        lastRescan = 0

        setStatus("Rock destroyed - searching for next rock")
    end
end

-- WORKER SUPERVISOR
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
            setStatus("Worker error: " .. tostring(err):sub(1, 90))
            task.wait(ERROR_RETRY_DELAY)
        end

        if not RUNNING or SESSION ~= mySession then
            break
        end

        task.wait(0.05)
    end
end

-- START
startButton.MouseButton1Click:Connect(function()
    if UNLOADED or RUNNING then
        return
    end

    if not selectedZone then
        setStatus("No zone available")
        return
    end

    if not resolveMineRemote() then
        setStatus("MineRock RemoteEvent not found")
        return
    end

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

    setStatus("Starting: " .. getDisplayName(selectedZone))

    task.spawn(function()
        local success, err = xpcall(function()
            miningWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success and SESSION == mySession then
            RUNNING = false
            setStatus("Fatal worker error: " .. tostring(err):sub(1, 80))
        elseif SESSION == mySession and RUNNING then
            RUNNING = false
            setStatus("Worker exited unexpectedly")
        end
    end)
end)

-- STOP
stopButton.MouseButton1Click:Connect(function()
    RUNNING = false
    SESSION += 1

    currentRock = nil
    trackedRock = nil
    trackedRockStartHP = nil
    trackedRockStartTime = 0
    nextTeleportAt = 0
    nextRockAt = 0
    lastRescan = 0

    setStatus("Stopped")
end)

-- GUI LAYOUT
local function updateLayout()
    if guiMinimized then
        main.Size = UDim2.fromOffset(310, 35)

        status.Visible = false
        zoneToggle.Visible = false
        scroll.Visible = false
        selectedLabel.Visible = false
        startButton.Visible = false
        stopButton.Visible = false

        minimize.Text = "+"
        return
    end

    status.Visible = true
    zoneToggle.Visible = true
    startButton.Visible = true
    stopButton.Visible = true

    minimize.Text = "-"

    if selectorExpanded then
        main.Size = UDim2.fromOffset(310, 255)
        zoneToggle.Text = "HIDE ZONES  -"

        scroll.Visible = true
        selectedLabel.Visible = true

        selectedLabel.Position = UDim2.fromOffset(10, 190)
        startButton.Position = UDim2.fromOffset(10, 214)
        stopButton.Position = UDim2.fromOffset(160, 214)
    else
        main.Size = UDim2.fromOffset(310, 150)
        zoneToggle.Text = "SHOW ZONES  +"

        scroll.Visible = false
        selectedLabel.Visible = true

        selectedLabel.Position = UDim2.fromOffset(10, 88)
        startButton.Position = UDim2.fromOffset(10, 109)
        stopButton.Position = UDim2.fromOffset(160, 109)
    end
end

-- HIDE / SHOW ZONES
zoneToggle.MouseButton1Click:Connect(function()
    selectorExpanded = not selectorExpanded
    updateLayout()
end)

-- MINIMIZE / RESTORE
minimize.MouseButton1Click:Connect(function()
    guiMinimized = not guiMinimized
    updateLayout()
end)

-- UNLOAD
close.MouseButton1Click:Connect(function()
    UNLOADED = true
    RUNNING = false
    SESSION += 1

    gui:Destroy()
end)

updateLayout()
