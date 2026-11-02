--// MULTI-ZONE AUTO MINER V14
--// Real Executor
--// Teleport verification and retry
--// Stay on rock until destroyed
--// 21 zones, exclusive selection
--// Draggable, minimize, hide zones, X unload

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ZonesFolder = workspace:WaitForChild("Zones")

local MineRemote = ReplicatedStorage
    :WaitForChild("Shared")
    :WaitForChild("Remotes")
    :WaitForChild("MineRock")

-- SETTINGS
local MINING_INTERVAL = 0.1
local AFTER_TELEPORT_WAIT = 0.2
local TELEPORT_RETRY_DELAY = 0.2
local TELEPORT_SUCCESS_DISTANCE = 18
local NEXT_ROCK_DELAY = 0.2
local SCAN_DELAY = 0.4

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

local selectedZone
local currentRock
local teleportedRock
local teleportedCharacter
local nextTeleportAt = 0
local nextRockAt = 0

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
    for _, entry in ipairs(availableZones) do
        if entry.Folder == name then
            return entry.Display
        end
    end
    return tostring(name)
end

-- REMOVE OLD GUI
local old = PlayerGui:FindFirstChild("MultiZoneMinerV14")
if old then
    old:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MultiZoneMinerV14"
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

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -85, 0, 30)
title.Position = UDim2.fromOffset(10, 4)
title.BackgroundTransparency = 1
title.Text = "Multi-Zone Auto Miner V14"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

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

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.fromOffset(10, 34)
status.BackgroundTransparency = 1
status.Text = "Status: Stopped"
status.TextColor3 = Color3.fromRGB(220, 220, 220)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

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

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, -20, 0, 18)
selectedLabel.Position = UDim2.fromOffset(10, 190)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = Color3.fromRGB(170, 200, 230)
selectedLabel.TextSize = 11
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = main

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
    "START", 10, 214, Color3.fromRGB(40, 145, 75)
)

local stopButton = makeButton(
    "STOP", 160, 214, Color3.fromRGB(160, 55, 55)
)

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
        teleportedRock = nil
        teleportedCharacter = nil
        nextTeleportAt = 0
        nextRockAt = 0

        updateSelection()
        status.Text = "Selected: " .. getDisplayName(folderName)
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

    if rock:GetAttribute("ZoneId") ~= zoneName then
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

    local bestRock
    local lowestHP = math.huge

    for _, rock in ipairs(folder:GetChildren()) do
        if validRock(rock, zoneName) then
            local hp = rock:GetAttribute("HP")

            if hp < lowestHP then
                lowestHP = hp
                bestRock = rock
            end
        end
    end

    return bestRock
end

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

-- MINING WORKER
local function miningWorker(mySession)
    while RUNNING and not UNLOADED and SESSION == mySession do
        local zoneName = selectedZone

        if not zoneName then
            status.Text = "No zone selected"
            task.wait(SCAN_DELAY)
            continue
        end

        -- Check that the selected zone still contains the current target.
        if currentRock and not validRock(currentRock, zoneName) then
            currentRock = nil
            teleportedRock = nil
            teleportedCharacter = nil
            nextRockAt = os.clock() + NEXT_ROCK_DELAY
            status.Text = "Rock destroyed - scanning next"
        end

        -- Find a new target only after the previous one is gone.
        if not currentRock then
            if os.clock() < nextRockAt then
                task.wait(0.1)
                continue
            end

            currentRock = findRock(zoneName)

            if not currentRock then
                status.Text = "Waiting for "
                    .. getDisplayName(zoneName)
                    .. " rocks..."
                task.wait(SCAN_DELAY)
                continue
            end
        end

        local rock = currentRock

        if not validRock(rock, zoneName) then
            task.wait(0.1)
            continue
        end

        local humanoid, root = getCharacterParts()
        local part = getRockPart(rock)

        if not humanoid or not root or not part then
            status.Text = "Waiting for character..."
            task.wait(SCAN_DELAY)
            continue
        end

        -- Reset teleport tracking if the character respawned.
        if teleportedCharacter ~= Player.Character then
            teleportedRock = nil
            teleportedCharacter = Player.Character
            nextTeleportAt = 0
        end

        local distance = getDistance(root, part)

        -- TELEPORT / VERIFY
        if distance > TELEPORT_SUCCESS_DISTANCE then
            if os.clock() >= nextTeleportAt then
                status.Text = "Teleport attempt: "
                    .. getDisplayName(zoneName)

                -- Local movement may be rejected by the game server.
                -- This does not bypass server-side movement checks.
                root.CFrame = part.CFrame * CFrame.new(0, 0, 3)

                task.wait(AFTER_TELEPORT_WAIT)

                if not RUNNING or SESSION ~= mySession then
                    break
                end

                humanoid, root = getCharacterParts()
                part = getRockPart(rock)

                if not humanoid or not root or not part then
                    task.wait(SCAN_DELAY)
                    continue
                end

                distance = getDistance(root, part)

                if distance <= TELEPORT_SUCCESS_DISTANCE then
                    teleportedRock = rock
                    teleportedCharacter = Player.Character
                    status.Text = "Reached rock - mining"
                else
                    teleportedRock = nil
                    nextTeleportAt = os.clock() + TELEPORT_RETRY_DELAY
                    status.Text = "Movement not accepted - retry cooldown"
                end
            else
                status.Text = "Waiting to retry movement..."
                task.wait(0.2)
            end

            continue
        end

        -- We are close enough to mine this same rock.
        teleportedRock = rock

        local oldHP = rock:GetAttribute("HP")

        pcall(function()
            MineRemote:FireServer(rock)
        end)

        task.wait(MINING_INTERVAL)

        if not RUNNING or SESSION ~= mySession then
            break
        end

        if not validRock(rock, zoneName) then
            currentRock = nil
            teleportedRock = nil
            teleportedCharacter = nil
            nextRockAt = os.clock() + NEXT_ROCK_DELAY
            status.Text = "Rock destroyed - next rock soon"
        else
            local newHP = rock:GetAttribute("HP")

            status.Text = getDisplayName(zoneName)
                .. " | HP: "
                .. tostring(newHP)

            -- Do not abandon a rock just because HP did not change.
        end
    end
end

-- START
startButton.MouseButton1Click:Connect(function()
    if UNLOADED or RUNNING then
        return
    end

    if not selectedZone then
        status.Text = "No zone available"
        return
    end

    SESSION += 1
    RUNNING = true

    currentRock = nil
    teleportedRock = nil
    teleportedCharacter = nil
    nextTeleportAt = 0
    nextRockAt = 0

    status.Text = "Starting: " .. getDisplayName(selectedZone)

    local mySession = SESSION
    task.spawn(miningWorker, mySession)
end)

-- STOP
stopButton.MouseButton1Click:Connect(function()
    RUNNING = false
    SESSION += 1

    currentRock = nil
    teleportedRock = nil
    teleportedCharacter = nil
    nextTeleportAt = 0
    nextRockAt = 0

    status.Text = "Stopped"
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

zoneToggle.MouseButton1Click:Connect(function()
    selectorExpanded = not selectorExpanded
    updateLayout()
end)

minimize.MouseButton1Click:Connect(function()
    guiMinimized = not guiMinimized
    updateLayout()
end)

close.MouseButton1Click:Connect(function()
    UNLOADED = true
    RUNNING = false
    SESSION += 1
    gui:Destroy()
end)

updateLayout()
