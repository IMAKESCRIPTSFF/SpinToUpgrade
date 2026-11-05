do

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Worker = "https://sws-key-system.swshub.workers.dev"
local GetKeyURL = Worker .. "/"

local Request = request or http_request
local GetHWID = get_hwid or gethwid

if type(Request) ~= "function" or type(GetHWID) ~= "function" then
    return
end

local HWID
local hwidSuccess = pcall(function()
    HWID = GetHWID()
end)

if not hwidSuccess or type(HWID) ~= "string" or HWID == "" then
    return
end

local old = CoreGui:FindFirstChild("SWSKeySystem")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SWSKeySystem"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(340, 215)
main.Position = UDim2.new(0.5, -170, 0.5, -107)
main.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = main

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(85, 85, 95)
outline.Transparency = 0.25
outline.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.fromOffset(10, 10)
title.BackgroundTransparency = 1
title.Text = "SWS HUB  |  KEY SYSTEM"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = main

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -30, 0, 22)
subtitle.Position = UDim2.fromOffset(15, 45)
subtitle.BackgroundTransparency = 1
subtitle.Text = "ENTER YOUR ACCESS KEY TO CONTINUE"
subtitle.TextColor3 = Color3.fromRGB(145, 145, 155)
subtitle.TextSize = 10
subtitle.Font = Enum.Font.GothamBold
subtitle.Parent = main

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -30, 0, 36)
keyBox.Position = UDim2.fromOffset(15, 78)
keyBox.BackgroundColor3 = Color3.fromRGB(29, 29, 34)
keyBox.BorderSizePixel = 0
keyBox.PlaceholderText = "Enter your key..."
keyBox.PlaceholderColor3 = Color3.fromRGB(115, 115, 125)
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyBox.TextSize = 12
keyBox.Font = Enum.Font.Gotham
keyBox.ClearTextOnFocus = false
keyBox.Parent = main

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = keyBox

local function createButton(name, position, width)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(width, 34)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(43, 43, 50)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.fromRGB(245, 245, 245)
    button.TextSize = 10
    button.Font = Enum.Font.GothamBold
    button.Parent = main

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    return button
end

local getButton = createButton("GET KEY", UDim2.fromOffset(15, 128), 150)
local verifyButton = createButton("VERIFY KEY", UDim2.fromOffset(175, 128), 150)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -30, 0, 30)
status.Position = UDim2.fromOffset(15, 170)
status.BackgroundTransparency = 1
status.Text = "STATUS: WAITING FOR KEY"
status.TextColor3 = Color3.fromRGB(155, 155, 165)
status.TextSize = 10
status.Font = Enum.Font.GothamBold
status.Parent = main

local busy = false
local verified = false

getButton.MouseButton1Click:Connect(function()
    if type(setclipboard) == "function" then
        setclipboard(GetKeyURL)
        status.Text = "KEY LINK COPIED - OPEN YOUR BROWSER"
    else
        status.Text = "OPEN: " .. GetKeyURL
    end
end)

verifyButton.MouseButton1Click:Connect(function()
    if busy or verified then return end

    local key = keyBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then
        status.Text = "PLEASE ENTER A KEY"
        status.TextColor3 = Color3.fromRGB(235, 125, 125)
        return
    end

    busy = true
    verifyButton.Text = "VERIFYING..."
    status.Text = "CONTACTING SWS SERVER..."
    status.TextColor3 = Color3.fromRGB(235, 195, 95)

    task.spawn(function()
        local success, response = pcall(function()
            return Request({
                Url = Worker .. "/verify",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    key = key,
                    hwid = HWID
                })
            })
        end)

        if not success or type(response) ~= "table" then
            status.Text = "SERVER CONNECTION FAILED"
            status.TextColor3 = Color3.fromRGB(235, 125, 125)
            busy = false
            verifyButton.Text = "VERIFY KEY"
            return
        end

        local decoded
        local parsed = pcall(function()
            decoded = HttpService:JSONDecode(response.Body or "")
        end)

        if not parsed or type(decoded) ~= "table" then
            status.Text = "INVALID SERVER RESPONSE"
            status.TextColor3 = Color3.fromRGB(235, 125, 125)
            busy = false
            verifyButton.Text = "VERIFY KEY"
            return
        end

        if decoded.valid == true then
            verified = true
            status.Text = decoded.type == "permanent"
                and "PERMANENT KEY VERIFIED"
                or "24-HOUR KEY VERIFIED"
            status.TextColor3 = Color3.fromRGB(130, 220, 150)
            verifyButton.Text = "SUCCESS"
            task.wait(0.8)
            gui:Destroy()
        else
            status.Text = "INVALID KEY: " .. tostring(decoded.error or "UNKNOWN")
            status.TextColor3 = Color3.fromRGB(235, 125, 125)
            busy = false
            verifyButton.Text = "VERIFY KEY"
        end
    end)
end)

local dragging = false
local dragStart
local startPosition

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

while gui.Parent and not verified do
    task.wait(0.2)
end

if not verified then
    return
end
end



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

local CONFIG_FILE = "SWS_HUB_STU"

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

local knownZoneNames = {}
for _, entry in ipairs(zoneOrder) do
    knownZoneNames[entry[1]] = true
end

local discoveredZones = ZonesFolder:GetChildren()
table.sort(discoveredZones, function(a, b)
    return a.Name < b.Name
end)

for _, zone in ipairs(discoveredZones) do
    if not knownZoneNames[zone.Name] and zone:FindFirstChild("Rocks") then
        local displayName = zone.Name
            :gsub("(%l)(%u)", "%1 %2")
            :gsub("(%a)(%d)", "%1 %2")

        table.insert(zoneOrder, {zone.Name, displayName})
        knownZoneNames[zone.Name] = true
    end
end

local BLACK = Color3.fromRGB(5, 5, 5)
local PANEL = Color3.fromRGB(14, 14, 14)
local PANEL2 = Color3.fromRGB(22, 22, 22)
local WHITE = Color3.fromRGB(255, 255, 255)
local GREY = Color3.fromRGB(155, 155, 155)

local RUNNING = false
local MINING_MANUALLY_STOPPED = false
local AUTO_BOSS = false
local AUTO_BUY = false
local AUTO_PLAYTIME = false
local AUTO_COLLECT = false
local AUTO_SELL = false
local AUTO_SPIN = false
local AUTO_GUILD_QUESTS = false
local GUILD_COLLECT_ACTIVE = false
local GUILD_MINE_ACTIVE = false
local GUILD_UPGRADE_ACTIVE = false
local GUILD_MINE_ZONE = nil
local UNLOADED = false

local SESSION = 0
local BOSS_SESSION = 0
local BUY_SESSION = 0
local PLAYTIME_SESSION = 0
local COLLECT_SESSION = 0
local SELL_SESSION = 0
local SPIN_SESSION = 0
local GUILD_QUEST_SESSION = 0

local selectedZone
local selectedMiners = {}
local availableZones = {}
local zoneRows = {}
local minerRows = {}

local selectorExpanded = true
local guiMinimized = false
local savedGuiPosition

local startMining
local stopMining

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
local configStatusLabel

local function readConfigFile(fileName)
    if type(readfile) ~= "function" then
        return nil
    end

    if type(isfile) == "function" then
        local existsOK, exists = pcall(isfile, fileName)
        if not existsOK or not exists then
            return nil
        end
    end

    local readOK, contents = pcall(readfile, fileName)
    if not readOK or type(contents) ~= "string" or contents == "" then
        return nil
    end

    local decodeOK, decoded = pcall(function()
        return HttpService:JSONDecode(contents)
    end)

    if decodeOK and type(decoded) == "table" then
        return decoded
    end

    return nil
end

local function loadConfig()
    local result = readConfigFile(CONFIG_FILE)
    if type(result) == "table" then
        savedConfig = result
    end
end

local function setConfigStatus(message, success)
    if configStatusLabel and configStatusLabel.Parent then
        configStatusLabel.Text = "CONFIG: " .. tostring(message)
        configStatusLabel.TextColor3 = success
            and Color3.fromRGB(130, 220, 150)
            or Color3.fromRGB(255, 135, 135)
    end
end

local function saveConfig()
    if type(writefile) ~= "function" then
        setConfigStatus("SAVE FAILED - EXECUTOR HAS NO writefile", false)
        return false
    end

    local config = {
        Version = 25,
        SelectedZone = selectedZone,
        SelectedMiners = selectedMiners,
        SelectorExpanded = selectorExpanded,
        GuiMinimized = guiMinimized,
        GuiPosition = savedGuiPosition,
        AutoBoss = AUTO_BOSS == true,
        AutoBuy = AUTO_BUY == true,
        AutoPlaytime = AUTO_PLAYTIME == true,
        AutoCollect = AUTO_COLLECT == true,
        AutoSell = AUTO_SELL == true,
        AutoSpin = AUTO_SPIN == true,
        AutoGuildQuests = AUTO_GUILD_QUESTS == true
    }

    local encodeOK, encoded = pcall(function()
        return HttpService:JSONEncode(config)
    end)
    if not encodeOK or type(encoded) ~= "string" then
        setConfigStatus("JSON ENCODE FAILED", false)
        return false
    end

    local writeOK, writeError = pcall(function()
        writefile(CONFIG_FILE, encoded)
    end)
    if not writeOK then
        setConfigStatus("WRITE FAILED: " .. tostring(writeError):sub(1, 35), false)
        return false
    end

    if type(readfile) == "function" then
        local verifyOK, contents = pcall(readfile, CONFIG_FILE)
        if not verifyOK or contents ~= encoded then
            setConfigStatus("VERIFY FAILED", false)
            return false
        end
    end

    setConfigStatus("SAVED", true)
    return true
end

local function queueSave()
    if UNLOADED then return end

    saveConfig()

    if saveQueued then return end
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
else
    selectorExpanded = false
end

if type(savedConfig.GuiMinimized) == "boolean" then
    guiMinimized = savedConfig.GuiMinimized
end

if type(savedConfig.GuiPosition) == "table" then
    savedGuiPosition = savedConfig.GuiPosition
end

local resumeBoss = savedConfig.AutoBoss == true
local resumeBuy = savedConfig.AutoBuy == true
local resumePlaytime = savedConfig.AutoPlaytime == true
local resumeCollect = savedConfig.AutoCollect == true
local resumeSell = savedConfig.AutoSell == true
local resumeSpin = savedConfig.AutoSpin == true
local resumeGuildQuests = savedConfig.AutoGuildQuests == true

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

    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(65, 75, 92)
        }):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(48, 48, 48)
        }):Play()
    end)

    return b
end

local settingsPageOpen = false
local guildStatusPageOpen = false

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
title.Size = UDim2.new(1, -195, 0, 30)
title.Position = UDim2.fromOffset(12, 3)
title.BackgroundTransparency = 1
title.Text = "AUTO MINER / V25"
title.TextColor3 = WHITE
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local minersOpenButton = makeButton(
    main, "FEATURES",
    UDim2.fromOffset(48, 23),
    UDim2.new(1, -113, 0, 5)
)

local guildStatusOpenButton = makeButton(
    main, "GUILD",
    UDim2.fromOffset(48, 23),
    UDim2.new(1, -165, 0, 5)
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

configStatusLabel = Instance.new("TextLabel")
configStatusLabel.Name = "ConfigStatus"
configStatusLabel.Size = UDim2.new(1, -20, 0, 10)
configStatusLabel.Position = UDim2.fromOffset(10, 240)
configStatusLabel.BackgroundTransparency = 1
configStatusLabel.Text = "CONFIG: READY"
configStatusLabel.TextColor3 = GREY
configStatusLabel.TextSize = 8
configStatusLabel.Font = Enum.Font.Gotham
configStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
configStatusLabel.Parent = main

local minerWindow = Instance.new("Frame")
minerWindow.Name = "AutomationSettingsPage"
minerWindow.Size = UDim2.fromScale(1, 1)
minerWindow.Position = UDim2.fromOffset(0, 0)
minerWindow.BackgroundColor3 = BLACK
minerWindow.BorderSizePixel = 0
minerWindow.Active = false
minerWindow.Visible = false
minerWindow.ClipsDescendants = true
minerWindow.Parent = main

corner(minerWindow, 10)
stroke(minerWindow, 0.45)

local guildWindow = Instance.new("Frame")
guildWindow.Name = "GuildStatusPage"
guildWindow.Size = UDim2.fromScale(1, 1)
guildWindow.Position = UDim2.fromOffset(0, 0)
guildWindow.BackgroundColor3 = BLACK
guildWindow.BorderSizePixel = 0
guildWindow.Active = false
guildWindow.Visible = false
guildWindow.ClipsDescendants = true
guildWindow.Parent = main
corner(guildWindow, 10)
stroke(guildWindow, 0.45)

local guildTitle = Instance.new("TextLabel")
guildTitle.Size = UDim2.new(1, -65, 0, 32)
guildTitle.Position = UDim2.fromOffset(12, 3)
guildTitle.BackgroundTransparency = 1
guildTitle.Text = "GUILD STATUS / PAGE 3"
guildTitle.TextColor3 = WHITE
guildTitle.TextSize = 12
guildTitle.Font = Enum.Font.GothamBold
guildTitle.TextXAlignment = Enum.TextXAlignment.Left
guildTitle.Parent = guildWindow

local guildBackButton = makeButton(
    guildWindow, "BACK",
    UDim2.fromOffset(48, 23),
    UDim2.new(1, -58, 0, 5)
)

local guildRefreshButton = makeButton(
    guildWindow, "REFRESH QUESTS",
    UDim2.new(1, -20, 0, 25),
    UDim2.fromOffset(10, 37)
)

guildRefreshButton.BackgroundColor3 = Color3.fromRGB(42, 54, 70)

local guildRefreshStatus = Instance.new("TextLabel")
guildRefreshStatus.Size = UDim2.new(1, -20, 0, 18)
guildRefreshStatus.Position = UDim2.fromOffset(10, 66)
guildRefreshStatus.BackgroundTransparency = 1
guildRefreshStatus.Text = "OPEN THIS PAGE TO LOAD GUILD QUESTS"
guildRefreshStatus.TextColor3 = GREY
guildRefreshStatus.TextSize = 9
guildRefreshStatus.Font = Enum.Font.Gotham
guildRefreshStatus.TextXAlignment = Enum.TextXAlignment.Left
guildRefreshStatus.Parent = guildWindow

local guildQuestScroll = Instance.new("ScrollingFrame")
guildQuestScroll.Name = "UncompletedQuests"
guildQuestScroll.Size = UDim2.new(1, -20, 1, -99)
guildQuestScroll.Position = UDim2.fromOffset(10, 87)
guildQuestScroll.BackgroundColor3 = PANEL
guildQuestScroll.BorderSizePixel = 0
guildQuestScroll.ScrollBarThickness = 3
guildQuestScroll.ScrollBarImageColor3 = WHITE
guildQuestScroll.CanvasSize = UDim2.fromOffset(0, 0)
guildQuestScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
guildQuestScroll.Parent = guildWindow
corner(guildQuestScroll, 6)
stroke(guildQuestScroll, 0.85)

local guildQuestLayout = Instance.new("UIListLayout")
guildQuestLayout.Padding = UDim.new(0, 6)
guildQuestLayout.SortOrder = Enum.SortOrder.LayoutOrder
guildQuestLayout.Parent = guildQuestScroll

local guildQuestPadding = Instance.new("UIPadding")
guildQuestPadding.PaddingTop = UDim.new(0, 6)
guildQuestPadding.PaddingLeft = UDim.new(0, 6)
guildQuestPadding.PaddingRight = UDim.new(0, 6)
guildQuestPadding.PaddingBottom = UDim.new(0, 6)
guildQuestPadding.Parent = guildQuestScroll

guildQuestLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    guildQuestScroll.CanvasSize = UDim2.fromOffset(0, guildQuestLayout.AbsoluteContentSize.Y + 14)
end)

local minerTitle = Instance.new("TextLabel")
minerTitle.Size = UDim2.new(1, -45, 0, 32)
minerTitle.Position = UDim2.fromOffset(12, 3)
minerTitle.BackgroundTransparency = 1
minerTitle.Text = "AUTOMATION SETTINGS / PAGE 2"
minerTitle.TextColor3 = WHITE
minerTitle.TextSize = 12
minerTitle.Font = Enum.Font.GothamBold
minerTitle.TextXAlignment = Enum.TextXAlignment.Left
minerTitle.Parent = minerWindow

local minerClose = makeButton(
    minerWindow, "BACK",
    UDim2.fromOffset(48, 23),
    UDim2.new(1, -58, 0, 5)
)

local minerDescription = Instance.new("TextLabel")
minerDescription.Size = UDim2.new(1, -20, 0, 30)
minerDescription.Position = UDim2.fromOffset(10, 35)
minerDescription.BackgroundTransparency = 1
minerDescription.Text = "Select miners and manage every automation toggle below."
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
minerScroll.Name = "FeaturesScroll"
minerScroll.Size = UDim2.new(1, -20, 1, -94)
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
minerLayout.Padding = UDim.new(0, 2)
minerLayout.SortOrder = Enum.SortOrder.LayoutOrder
minerLayout.Parent = minerScroll

local minerPadding = Instance.new("UIPadding")
minerPadding.PaddingTop = UDim.new(0, 5)
minerPadding.PaddingLeft = UDim.new(0, 5)
minerPadding.PaddingRight = UDim.new(0, 5)
minerPadding.Parent = minerScroll

minerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    minerScroll.CanvasSize = UDim2.fromOffset(
        0, minerLayout.AbsoluteContentSize.Y + 12
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
    row.Size = UDim2.new(1, -3, 0, 20)
    row.BackgroundColor3 = PANEL2
    row.BorderSizePixel = 0
    row.TextColor3 = GREY
    row.TextSize = 10
    row.Font = Enum.Font.Gotham
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Text = "  [ ]  " .. tostring(name)
    row.LayoutOrder = index + 1
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
    minerScroll, "SELECT ALL",
    UDim2.new(1, -3, 0, 23),
    UDim2.fromOffset(0, 0)
)

local deselectAllButton = makeButton(
    minerScroll, "DESELECT ALL",
    UDim2.new(1, -3, 0, 23),
    UDim2.fromOffset(0, 0)
)

selectAllButton.LayoutOrder = 100
deselectAllButton.LayoutOrder = 101

local minerListExpanded = false
local minerSelectionHeader = makeButton(
    minerScroll, "SELECT MINERS  [+]",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)
minerSelectionHeader.LayoutOrder = 1

local function setMinerListExpanded(expanded, animate)
    minerListExpanded = expanded == true
    minerSelectionHeader.Text = minerListExpanded and "SELECT MINERS  [-]" or "SELECT MINERS  [+]"
    for _, name in ipairs(MinerNames) do
        local row = minerRows[name]
        if row then row.Visible = minerListExpanded end
    end
    selectAllButton.Visible = minerListExpanded
    deselectAllButton.Visible = minerListExpanded
    if animate then
        local target = minerListExpanded and 0.16 or 0.10
        TweenService:Create(minerSelectionHeader, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = minerListExpanded and Color3.fromRGB(54, 65, 82) or PANEL2
        }):Play()
    end
end
minerSelectionHeader.MouseButton1Click:Connect(function()
    setMinerListExpanded(not minerListExpanded, true)
end)

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

setMinerListExpanded(false, false)

local purchaseStatus = Instance.new("TextLabel")
purchaseStatus.Size = UDim2.new(1, -6, 0, 14)
purchaseStatus.Position = UDim2.fromOffset(0, 0)
purchaseStatus.BackgroundTransparency = 1
purchaseStatus.Text = "AUTO BUY: OFF"
purchaseStatus.TextColor3 = GREY
purchaseStatus.TextSize = 9
purchaseStatus.Font = Enum.Font.Gotham
purchaseStatus.TextXAlignment = Enum.TextXAlignment.Left
purchaseStatus.Parent = minerScroll
purchaseStatus.LayoutOrder = 103

local autoBuyButton = makeButton(
    minerScroll, "AUTO BUY: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

local stopBuyButton = makeButton(
    minerScroll, "STOP",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

local playtimeStatus = Instance.new("TextLabel")
playtimeStatus.Size = UDim2.new(1, -6, 0, 14)
playtimeStatus.Position = UDim2.fromOffset(0, 0)
playtimeStatus.BackgroundTransparency = 1
playtimeStatus.Text = "PLAYTIME: OFF"
playtimeStatus.TextColor3 = GREY
playtimeStatus.TextSize = 9
playtimeStatus.Font = Enum.Font.Gotham
playtimeStatus.TextXAlignment = Enum.TextXAlignment.Left
playtimeStatus.Parent = minerScroll
playtimeStatus.LayoutOrder = 106

local playtimeButton = makeButton(
    minerScroll, "PLAYTIME: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

local collectStatus = Instance.new("TextLabel")
collectStatus.Size = UDim2.new(1, -6, 0, 14)
collectStatus.Position = UDim2.fromOffset(0, 0)
collectStatus.BackgroundTransparency = 1
collectStatus.Text = "AUTO COLLECT: OFF"
collectStatus.TextColor3 = GREY
collectStatus.TextSize = 9
collectStatus.Font = Enum.Font.Gotham
collectStatus.TextXAlignment = Enum.TextXAlignment.Left
collectStatus.Parent = minerScroll
collectStatus.LayoutOrder = 108

local collectButton = makeButton(
    minerScroll, "AUTO COLLECT: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

local guildQuestStatus = Instance.new("TextLabel")
guildQuestStatus.Size = UDim2.new(1, -6, 0, 14)
guildQuestStatus.Position = UDim2.fromOffset(0, 0)
guildQuestStatus.BackgroundTransparency = 1
guildQuestStatus.Text = "GUILD QUESTS: OFF"
guildQuestStatus.TextColor3 = GREY
guildQuestStatus.TextSize = 9
guildQuestStatus.Font = Enum.Font.Gotham
guildQuestStatus.TextXAlignment = Enum.TextXAlignment.Left
guildQuestStatus.Parent = minerScroll
guildQuestStatus.LayoutOrder = 110

local guildQuestButton = makeButton(
    minerScroll, "GUILD QUESTS: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

local sellStatus = Instance.new("TextLabel")
sellStatus.Size = UDim2.new(1, -6, 0, 14)
sellStatus.Position = UDim2.fromOffset(0, 0)
sellStatus.BackgroundTransparency = 1
sellStatus.Text = "AUTO SELL: OFF"
sellStatus.TextColor3 = GREY
sellStatus.TextSize = 9
sellStatus.Font = Enum.Font.Gotham
sellStatus.TextXAlignment = Enum.TextXAlignment.Left
sellStatus.Parent = minerScroll
sellStatus.LayoutOrder = 112

local sellButton = makeButton(
    minerScroll, "AUTO SELL: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

autoBuyButton.LayoutOrder = 104
stopBuyButton.LayoutOrder = 105
playtimeButton.LayoutOrder = 107
collectButton.LayoutOrder = 109
guildQuestButton.LayoutOrder = 111
sellButton.LayoutOrder = 113

local spinStatus = Instance.new("TextLabel")
spinStatus.Size = UDim2.new(1, -6, 0, 14)
spinStatus.Position = UDim2.fromOffset(0, 0)
spinStatus.BackgroundTransparency = 1
spinStatus.Text = "AUTO SPIN: OFF"
spinStatus.TextColor3 = GREY
spinStatus.TextSize = 9
spinStatus.Font = Enum.Font.Gotham
spinStatus.TextXAlignment = Enum.TextXAlignment.Left
spinStatus.Parent = minerScroll
spinStatus.LayoutOrder = 114

local spinButton = makeButton(
    minerScroll, "AUTO SPIN: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)
spinButton.LayoutOrder = 115

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

local function getPlaytimeRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("ClaimPlaytimeGift")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

local function updatePlaytimeButton()
    playtimeButton.Text = AUTO_PLAYTIME and "PLAYTIME: ON" or "PLAYTIME: OFF"
    playtimeButton.BackgroundColor3 = AUTO_PLAYTIME
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
    playtimeStatus.Text = AUTO_PLAYTIME and "PLAYTIME CLAIM: RUNNING" or "PLAYTIME: OFF"
end

local function stopAutoPlaytime()
    AUTO_PLAYTIME = false
    PLAYTIME_SESSION += 1
    updatePlaytimeButton()
    queueSave()
end

local function autoPlaytimeWorker(mySession)
    local remote = getPlaytimeRemote()

    if not remote then
        AUTO_PLAYTIME = false
        updatePlaytimeButton()
        playtimeStatus.Text = "CLAIMPLAYTIMEGIFT REMOTE NOT FOUND"
        queueSave()
        return
    end

    while AUTO_PLAYTIME and not UNLOADED and PLAYTIME_SESSION == mySession do
        local claimed = 0
        local failed = 0

        for rewardId = 1, 8 do
            if not AUTO_PLAYTIME or UNLOADED or PLAYTIME_SESSION ~= mySession then
                break
            end

            local ok, result = pcall(function()
                return remote:InvokeServer(rewardId)
            end)

            if ok and result ~= false then
                claimed += 1
            else
                failed += 1
            end
            task.wait(1)
        end

        if AUTO_PLAYTIME and not UNLOADED and PLAYTIME_SESSION == mySession then
            local ok, result = pcall(function()
                return remote:InvokeServer("Bonus")
            end)

            if ok and result ~= false then
                claimed += 1
            else
                failed += 1
            end

            playtimeStatus.Text = "PLAYTIME CYCLE: " .. claimed .. " SENT / " .. failed .. " FAILED"
            task.wait(1)
        end
    end
end

local function startAutoPlaytime()
    if AUTO_PLAYTIME or UNLOADED then return end

    if not getPlaytimeRemote() then
        playtimeStatus.Text = "CLAIMPLAYTIMEGIFT REMOTE NOT FOUND"
        return
    end

    AUTO_PLAYTIME = true
    PLAYTIME_SESSION += 1
    local mySession = PLAYTIME_SESSION

    updatePlaytimeButton()
    queueSave()

    task.spawn(function()
        local success, err = xpcall(function()
            autoPlaytimeWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success and PLAYTIME_SESSION == mySession then
            AUTO_PLAYTIME = false
            updatePlaytimeButton()
            playtimeStatus.Text = "PLAYTIME ERROR: " .. tostring(err):sub(1, 45)
            queueSave()
        end
    end)
end

playtimeButton.MouseButton1Click:Connect(function()
    if AUTO_PLAYTIME then
        stopAutoPlaytime()
    else
        startAutoPlaytime()
    end
end)

local function getSellOresRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("SellOres")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

local function updateAutoSellButton()
    if not sellButton.Parent then return end

    sellButton.Text = AUTO_SELL and "AUTO SELL: ON" or "AUTO SELL: OFF"
    sellButton.BackgroundColor3 = AUTO_SELL
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
    sellStatus.Text = AUTO_SELL and "AUTO SELL: RUNNING" or "AUTO SELL: OFF"
end

local function stopAutoSell()
    AUTO_SELL = false
    SELL_SESSION += 1
    updateAutoSellButton()
    queueSave()
end

local function autoSellWorker(mySession)
    local remote = getSellOresRemote()

    if not remote then
        AUTO_SELL = false
        updateAutoSellButton()
        sellStatus.Text = "SELLORES REMOTE NOT FOUND"
        queueSave()
        return
    end

    while AUTO_SELL and not UNLOADED and SELL_SESSION == mySession do
        local ok, result = pcall(function()
            return remote:InvokeServer("All")
        end)

        if ok then
            sellStatus.Text = "AUTO SELL: ACTIVE"
        else
            sellStatus.Text = "SELL ERROR: " .. tostring(result):sub(1, 42)
        end

        task.wait(3)
    end
end

local function startAutoSell()
    if AUTO_SELL or UNLOADED then return end

    if not getSellOresRemote() then
        sellStatus.Text = "SELLORES REMOTE NOT FOUND"
        return
    end

    AUTO_SELL = true
    SELL_SESSION += 1
    local mySession = SELL_SESSION

    updateAutoSellButton()
    queueSave()

    task.spawn(function()
        local success, err = xpcall(function()
            autoSellWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success and SELL_SESSION == mySession then
            AUTO_SELL = false
            updateAutoSellButton()
            sellStatus.Text = "SELL ERROR: " .. tostring(err):sub(1, 42)
            queueSave()
        end
    end)
end

sellButton.MouseButton1Click:Connect(function()
    if AUTO_SELL then
        stopAutoSell()
    else
        startAutoSell()
    end
end)

local function getSpinRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("SpinWheel")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

local function updateAutoSpinButton()
    if not spinButton.Parent then return end

    spinButton.Text = AUTO_SPIN and "AUTO SPIN: ON" or "AUTO SPIN: OFF"
    spinButton.BackgroundColor3 = AUTO_SPIN
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
    spinStatus.Text = AUTO_SPIN and "AUTO SPIN: RUNNING" or "AUTO SPIN: OFF"
end

local function stopAutoSpin()
    AUTO_SPIN = false
    SPIN_SESSION += 1
    updateAutoSpinButton()
    queueSave()
end

local function autoSpinWorker(mySession)
    local remote = getSpinRemote()

    if not remote then
        AUTO_SPIN = false
        updateAutoSpinButton()
        spinStatus.Text = "SPINWHEEL REMOTE NOT FOUND"
        queueSave()
        return
    end

    while AUTO_SPIN and not UNLOADED and SPIN_SESSION == mySession do
        local ok, result = pcall(function()
            return remote:InvokeServer()
        end)

        if ok then
            spinStatus.Text = "AUTO SPIN: ACTIVE"
        else
            spinStatus.Text = "SPIN ERROR: " .. tostring(result):sub(1, 42)
        end

        task.wait(3)
    end
end

local function startAutoSpin()
    if AUTO_SPIN or UNLOADED then return end

    if not getSpinRemote() then
        spinStatus.Text = "SPINWHEEL REMOTE NOT FOUND"
        return
    end

    AUTO_SPIN = true
    SPIN_SESSION += 1
    local mySession = SPIN_SESSION

    updateAutoSpinButton()
    queueSave()

    task.spawn(function()
        local success, err = xpcall(function()
            autoSpinWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success and SPIN_SESSION == mySession then
            AUTO_SPIN = false
            updateAutoSpinButton()
            spinStatus.Text = "SPIN ERROR: " .. tostring(err):sub(1, 42)
            queueSave()
        end
    end)
end

spinButton.MouseButton1Click:Connect(function()
    if AUTO_SPIN then
        stopAutoSpin()
    else
        startAutoSpin()
    end
end)

local function getCollectPrompt()
    local plots = workspace:FindFirstChild("Plots")
    local plot = plots and plots:FindFirstChild("Plot1")
    local collector = plot and plot:FindFirstChild("Collector")
    local bin = collector and collector:FindFirstChild("Bin")
    local prompt = bin and bin:FindFirstChild("CollectPrompt")

    if prompt and prompt:IsA("ProximityPrompt") then
        return prompt
    end

    return nil
end

local function updateAutoCollectButton()
    if not collectButton.Parent then return end

    collectButton.Text = AUTO_COLLECT and "AUTO COLLECT: ON" or "AUTO COLLECT: OFF"
    collectButton.BackgroundColor3 = AUTO_COLLECT
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
    collectStatus.Text = AUTO_COLLECT and "AUTO COLLECT: RUNNING" or "AUTO COLLECT: OFF"
end

local function stopAutoCollect()
    AUTO_COLLECT = false
    COLLECT_SESSION += 1
    updateAutoCollectButton()
    queueSave()
end

local function autoCollectWorker(mySession)
    while AUTO_COLLECT and not UNLOADED and COLLECT_SESSION == mySession do
        local prompt = getCollectPrompt()

        if prompt and prompt.Enabled and type(fireproximityprompt) == "function" then
            pcall(function()
                fireproximityprompt(prompt)
            end)
        end

        task.wait(0.5)
    end
end

local function startAutoCollect()
    if AUTO_COLLECT or UNLOADED then return end

    if type(fireproximityprompt) ~= "function" then
        collectStatus.Text = "PROXIMITY PROMPT API NOT AVAILABLE"
        return
    end

    AUTO_COLLECT = true
    COLLECT_SESSION += 1
    local mySession = COLLECT_SESSION

    updateAutoCollectButton()
    queueSave()

    task.spawn(function()
        local success, err = xpcall(function()
            autoCollectWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not success and COLLECT_SESSION == mySession then
            AUTO_COLLECT = false
            updateAutoCollectButton()
            collectStatus.Text = "COLLECT ERROR: " .. tostring(err):sub(1, 40)
            queueSave()
        end
    end)
end

collectButton.MouseButton1Click:Connect(function()
    if AUTO_COLLECT then
        stopAutoCollect()
    else
        startAutoCollect()
    end
end)

local updateLayout
local pageReturnPosition
local refreshGuildStatus

local function showMainPage()
    settingsPageOpen = false
    guildStatusPageOpen = false
    for _, page in ipairs({minerWindow, guildWindow}) do
        if page.Visible then
            TweenService:Create(page, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.fromOffset(290, 0)
            }):Play()
            task.delay(0.17, function()
                if not UNLOADED and not settingsPageOpen and not guildStatusPageOpen then
                    page.Visible = false
                    page.Position = UDim2.fromOffset(0, 0)
                end
            end)
        end
    end
    main.Size = UDim2.fromOffset(290, 251)
    if pageReturnPosition then
        main.Position = pageReturnPosition
        pageReturnPosition = nil
    end
    if updateLayout then updateLayout(false) end
end

local function showSettingsPage()
    if guiMinimized then
        guiMinimized = false
        queueSave()
    end
    guildStatusPageOpen = false
    guildWindow.Visible = false
    guildWindow.Position = UDim2.fromOffset(0, 0)
    settingsPageOpen = true
    pageReturnPosition = main.Position
    main.Size = UDim2.fromOffset(290, 251)
    minerWindow.Position = UDim2.fromOffset(290, 0)
    minerWindow.Visible = true
    TweenService:Create(minerWindow, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(0, 0)
    }):Play()
end

local function showGuildStatusPage()
    if guiMinimized then
        guiMinimized = false
        queueSave()
    end
    settingsPageOpen = false
    minerWindow.Visible = false
    minerWindow.Position = UDim2.fromOffset(0, 0)
    guildStatusPageOpen = true
    pageReturnPosition = main.Position
    main.Size = UDim2.fromOffset(290, 251)
    guildWindow.Position = UDim2.fromOffset(290, 0)
    guildWindow.Visible = true
    TweenService:Create(guildWindow, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(0, 0)
    }):Play()
    task.defer(function()
        if not UNLOADED and guildStatusPageOpen then
            refreshGuildStatus()
        end
    end)
end

minersOpenButton.Text = "FEATURES"
minersOpenButton.MouseButton1Click:Connect(function()
    if settingsPageOpen then showMainPage() else showSettingsPage() end
end)

guildStatusOpenButton.MouseButton1Click:Connect(function()
    if guildStatusPageOpen then showMainPage() else showGuildStatusPage() end
end)

minerClose.MouseButton1Click:Connect(showMainPage)
guildBackButton.MouseButton1Click:Connect(showMainPage)
guildRefreshButton.MouseButton1Click:Connect(function()
    refreshGuildStatus()
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

    row.LayoutOrder = index + 1
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

local function getRockBoss()
    local adminEvents = workspace:FindFirstChild("AdminEvents")
    return adminEvents and adminEvents:FindFirstChild("RockBoss")
end

local function getGemPinata()
    local adminEvents = workspace:FindFirstChild("AdminEvents")
    return adminEvents and adminEvents:FindFirstChild("GemPinata")
end

local function getBossFistPart(boss, root)
    if not boss then return nil end

    local candidates = {}

    if boss:IsA("BasePart") then
        table.insert(candidates, boss)
    else
        for _, obj in ipairs(boss:GetDescendants()) do
            if obj:IsA("BasePart") then
                table.insert(candidates, obj)
            end
        end
    end

    if #candidates == 0 then
        return nil
    end

    local namedCandidates = {}
    for _, part in ipairs(candidates) do
        local lowerName = string.lower(part.Name)
        if string.find(lowerName, "fist", 1, true)
            or string.find(lowerName, "hand", 1, true) then
            table.insert(namedCandidates, part)
        end
    end

    if #namedCandidates > 0 then
        candidates = namedCandidates
    end

    if root then
        table.sort(candidates, function(a, b)
            return (a.Position - root.Position).Magnitude
                < (b.Position - root.Position).Magnitude
        end)
    end

    return candidates[1]
end

local function getBossHealthObject(boss)
    if not boss then return nil end

    if boss:IsA("Model") then
        return boss:FindFirstChildWhichIsA("Humanoid", true)
    end

    return nil
end

local function getBossPosition(boss)
    if not boss then return nil end

    if boss:IsA("BasePart") then
        return boss.CFrame
    end

    if boss:IsA("Model") then
        local success, pivot = pcall(function()
            return boss:GetPivot()
        end)

        if success then
            return pivot
        end
    end

    local part = boss:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame
end

local function getBossHealth(boss)
    if not boss then return nil end

    local humanoid = getBossHealthObject(boss)

    if humanoid then
        return humanoid.Health
    end

    for _, attributeName in ipairs({
        "Health",
        "HP",
        "CurrentHealth",
        "CurrentHP"
    }) do
        local value = boss:GetAttribute(attributeName)

        if typeof(value) == "number" then
            return value
        end
    end

    for _, obj in ipairs(boss:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            local name = string.lower(obj.Name)

            if string.find(name, "health", 1, true)
                or name == "hp"
                or string.find(name, "currenthp", 1, true) then
                return obj.Value
            end
        end
    end

    return nil
end

local function teleportToBossTarget(root, targetCFrame)
    if not root or not targetCFrame then
        return false
    end

    local success = pcall(function()
        root.CFrame = targetCFrame * CFrame.new(0, 3, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    return success
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

local function teleportToZone(zoneName)
    if UNLOADED or not zoneName then
        return false
    end

    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local teleportRemote = remotes and remotes:FindFirstChild("TeleportToZone")

    if not teleportRemote or not teleportRemote:IsA("RemoteEvent") then
        return false
    end

    local success, err = pcall(function()
        teleportRemote:FireServer(zoneName)
    end)

    if not success then
        return false
    end

    return true
end

local function teleportToSelectedZone()
    return teleportToZone(selectedZone)
end

local function stripRichText(value)
    value = tostring(value or "")
    value = value:gsub("<[^>]->", "")
    return value:gsub("&nbsp;", " ")
end

local function getGuildQuestStates()
    local hud = PlayerGui:FindFirstChild("Hud")
    local windows = hud and hud:FindFirstChild("Windows")
    local guild = windows and windows:FindFirstChild("Guild", true)
    if not guild then return {} end

    local list = guild:FindFirstChild("List", true) or guild
    local cards = {}

    for _, obj in ipairs(list:GetDescendants()) do
        local name = string.lower(obj.Name)
        local number = name:match("myquest%s*(%d+)")
            or name:match("quest[_%s%-]*(%d+)")
        if number then
            local slot = tonumber(number)
            if slot and slot >= 1 and slot <= 3 and not cards[slot] then
                cards[slot] = obj
            end
        end
    end

    for index = 1, 3 do
        if not cards[index] then
            local direct = list:FindFirstChild("MyQuest" .. index, true)
                or list:FindFirstChild("Quest" .. index, true)
                or guild:FindFirstChild("MyQuest" .. index, true)
                or guild:FindFirstChild("Quest" .. index, true)
            if direct then
                cards[index] = direct
            end
        end
    end

    local states = {}
    for index = 1, 3 do
        local card = cards[index]
        if card then
            local description = ""
            local labels = {}
            local claimed = false
            local textObjects = {}

            if card:IsA("TextLabel") or card:IsA("TextButton") or card:IsA("TextBox") then
                table.insert(textObjects, card)
            end

            for _, obj in ipairs(card:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    table.insert(textObjects, obj)
                end
            end

            for _, obj in ipairs(textObjects) do
                local value = stripRichText(obj.Text)
                if value ~= "" then
                    table.insert(labels, value)
                    local lower = string.lower(value)
                    if string.find(lower, "rewards collected", 1, true)
                        or string.find(lower, "reward claimed", 1, true) then
                        claimed = true
                    end

                    local cleaned = value:gsub("[★☆⭐]", ""):gsub("%s+", "")
                    local isProgress = string.find(value, "/", 1, true) ~= nil
                        or string.find(lower, "done", 1, true) ~= nil
                        or string.find(lower, "progress", 1, true) ~= nil
                    local isDecoration = cleaned == ""
                        or lower == "easy"
                        or lower == "medium"
                        or lower == "hard"
                        or lower == "quest"
                        or string.find(lower, "reward", 1, true) ~= nil

                    if not isProgress and not isDecoration then
                        local objectiveWords = {
                            "break", "mine", "collect", "play", "ore", "rock",
                            "land", "critical", "hit", "find", "rare", "defeat",
                            "damage", "win", "open", "sell", "upgrade", "craft"
                        }
                        local matchesObjective = false
                        for _, word in ipairs(objectiveWords) do
                            if string.find(lower, word, 1, true) then
                                matchesObjective = true
                                break
                            end
                        end
                        if matchesObjective and #value > #description then
                            description = value
                        end
                    end
                end
            end

            if description == "" then
                for _, value in ipairs(labels) do
                    local lower = string.lower(value)
                    local cleaned = value:gsub("[★☆⭐]", ""):gsub("%s+", "")
                    local isProgress = string.find(value, "/", 1, true) ~= nil
                        or string.find(lower, "done", 1, true) ~= nil
                        or string.find(lower, "progress", 1, true) ~= nil
                    if #value > 4 and cleaned ~= "" and not isProgress
                        and not string.find(lower, "reward", 1, true)
                        and not string.find(lower, "quest", 1, true)
                        and lower ~= "easy" and lower ~= "medium" and lower ~= "hard"
                        and not string.match(value, "^%d+$") then
                        if #value > #description then
                            description = value
                        end
                    end
                end
            end

            if description ~= "" then
                local bar = card:FindFirstChild("Bar", true)
                local progressObject = bar and bar:FindFirstChild("Progress", true)
                local progress = progressObject
                    and (progressObject:IsA("TextLabel") or progressObject:IsA("TextButton") or progressObject:IsA("TextBox"))
                    and stripRichText(progressObject.Text) or ""

                if progress == "" then
                    for _, value in ipairs(labels) do
                        if string.find(value, "/", 1, true)
                            or string.find(string.lower(value), "done", 1, true) then
                            progress = value
                            break
                        end
                    end
                end

                local progressCurrent, progressTotal = tostring(progress):match("(%d+)%s*/%s*(%d+)")
                local progressFinished = progressCurrent and progressTotal
                    and tonumber(progressTotal) > 0
                    and tonumber(progressCurrent) >= tonumber(progressTotal)
                local done = claimed
                    or progressFinished == true
                    or string.find(string.upper(progress), "DONE", 1, true) ~= nil
                    or string.find(description, "✔", 1, true) ~= nil

                table.insert(states, {
                    Slot = index,
                    Description = description,
                    Lower = string.lower(description),
                    Progress = progress,
                    Done = done,
                    Claimed = claimed,
                    Labels = labels
                })
            end
        end
    end

    return states
end

local function triggerNativeGuildRefresh()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local guildRemote = remotes and remotes:FindFirstChild("Guild")
    if not guildRemote or not guildRemote:IsA("RemoteFunction") then
        return false, "GUILD REMOTE NOT FOUND"
    end

    local ok, result = pcall(function()
        return guildRemote:InvokeServer("Refresh", {})
    end)

    if ok then
        return true, "GUILD REFRESH REQUEST SENT"
    end

    return false, "GUILD REFRESH FAILED: " .. tostring(result):sub(1, 45)
end

local function clearGuildQuestCards()
    for _, child in ipairs(guildQuestScroll:GetChildren()) do
        if child ~= guildQuestLayout and child ~= guildQuestPadding then
            child:Destroy()
        end
    end
end

local function renderGuildQuestStates(states)
    clearGuildQuestCards()
    states = states or {}

    if #states == 0 then
        local message = Instance.new("TextLabel")
        message.Name = "EmptyState"
        message.Size = UDim2.new(1, -4, 0, 54)
        message.BackgroundColor3 = PANEL2
        message.BorderSizePixel = 0
        message.TextColor3 = GREY
        message.TextSize = 11
        message.Font = Enum.Font.GothamBold
        message.TextWrapped = true
        message.Text = "WAITING FOR GUILD QUEST DATA - OPEN THE GUILD PAGE"
        message.LayoutOrder = 1
        message.Parent = guildQuestScroll
        corner(message, 6)
        return 0, 0
    end

    local completed = 0
    for _, state in ipairs(states) do
        if state.Done then completed += 1 end
    end

    table.sort(states, function(a, b)
        return (tonumber(a.Slot) or 99) < (tonumber(b.Slot) or 99)
    end)

    for index, state in ipairs(states) do
        local isDone = state.Done == true
        local card = Instance.new("Frame")
        card.Name = "Quest" .. tostring(state.Slot)
        card.Size = UDim2.new(1, -4, 0, 72)
        card.BackgroundColor3 = PANEL2
        card.BorderSizePixel = 0
        card.LayoutOrder = index
        card.Parent = guildQuestScroll
        corner(card, 6)
        stroke(card, 0.82)

        local heading = Instance.new("TextLabel")
        heading.Size = UDim2.new(1, -14, 0, 17)
        heading.Position = UDim2.fromOffset(7, 5)
        heading.BackgroundTransparency = 1
        heading.Text = "QUEST " .. tostring(state.Slot) .. (isDone and "  •  COMPLETED" or "  •  INCOMPLETE")
        heading.TextColor3 = isDone and Color3.fromRGB(130, 220, 150) or Color3.fromRGB(235, 195, 95)
        heading.TextSize = 9
        heading.Font = Enum.Font.GothamBold
        heading.TextXAlignment = Enum.TextXAlignment.Left
        heading.Parent = card

        local objective = Instance.new("TextLabel")
        objective.Size = UDim2.new(1, -14, 0, 29)
        objective.Position = UDim2.fromOffset(7, 23)
        objective.BackgroundTransparency = 1
        objective.Text = stripRichText(state.Description)
        objective.TextColor3 = WHITE
        objective.TextSize = 10
        objective.Font = Enum.Font.Gotham
        objective.TextWrapped = true
        objective.TextXAlignment = Enum.TextXAlignment.Left
        objective.TextYAlignment = Enum.TextYAlignment.Top
        objective.Parent = card

        local progress = Instance.new("TextLabel")
        progress.Size = UDim2.new(1, -14, 0, 14)
        progress.Position = UDim2.fromOffset(7, 54)
        progress.BackgroundTransparency = 1
        progress.Text = isDone and "STATUS: COMPLETED" or "PROGRESS: " .. ((state.Progress ~= "" and state.Progress) or "In progress")
        progress.TextColor3 = isDone and Color3.fromRGB(130, 220, 150) or GREY
        progress.TextSize = 9
        progress.Font = Enum.Font.GothamBold
        progress.TextXAlignment = Enum.TextXAlignment.Left
        progress.Parent = card
    end

    return #states - completed, completed
end

local guildRefreshSession = 0
refreshGuildStatus = function()
    if UNLOADED then return end
    guildRefreshSession += 1
    local thisRefresh = guildRefreshSession
    guildRefreshStatus.Text = "SENDING GUILD REFRESH..."
    guildRefreshStatus.TextColor3 = Color3.fromRGB(235, 195, 95)

    task.spawn(function()
        local sent, message = triggerNativeGuildRefresh()
        if thisRefresh ~= guildRefreshSession or UNLOADED then return end
        guildRefreshStatus.Text = message
        task.wait(sent and 0.8 or 0.25)
        if thisRefresh ~= guildRefreshSession or UNLOADED then return end

        local states = getGuildQuestStates()
        local count, completed = renderGuildQuestStates(states)
        if sent then
            guildRefreshStatus.Text = "UPDATED  •  " .. tostring(completed) .. " COMPLETED / " .. tostring(count) .. " ACTIVE"
            guildRefreshStatus.TextColor3 = Color3.fromRGB(130, 220, 150)
        elseif #states > 0 then
            guildRefreshStatus.Text = message .. "  •  SHOWING CURRENT DATA"
            guildRefreshStatus.TextColor3 = Color3.fromRGB(235, 195, 95)
        else
            guildRefreshStatus.Text = message .. "  •  OPEN GUILD ONCE, THEN REOPEN THIS PAGE"
            guildRefreshStatus.TextColor3 = Color3.fromRGB(235, 125, 125)
        end

        while not UNLOADED and thisRefresh == guildRefreshSession do
            task.wait(1)
            if UNLOADED or thisRefresh ~= guildRefreshSession then
                break
            end

            local refreshed, refreshMessage = triggerNativeGuildRefresh()
            task.wait(0.2)

            if UNLOADED or thisRefresh ~= guildRefreshSession then
                break
            end

            local liveStates = getGuildQuestStates()
            local liveCount, liveCompleted = renderGuildQuestStates(liveStates)
            if refreshed then
                guildRefreshStatus.Text = "AUTO REFRESH  •  " .. tostring(liveCompleted) .. " COMPLETED / " .. tostring(liveCount) .. " ACTIVE"
                guildRefreshStatus.TextColor3 = Color3.fromRGB(130, 220, 150)
            else
                guildRefreshStatus.Text = refreshMessage
                guildRefreshStatus.TextColor3 = Color3.fromRGB(235, 125, 125)
            end
        end
    end)
end

task.defer(function()
    if not UNLOADED then
        refreshGuildStatus()
    end
end)

local function resolveGuildQuestZone(description)
    local lower = string.lower(stripRichText(description))
    for _, entry in ipairs(zoneOrder) do
        local folderName = entry[1]
        local displayName = entry[2]
        if string.find(lower, string.lower(displayName), 1, true)
            or string.find(lower, string.lower(folderName), 1, true) then
            return folderName, displayName
        end
    end
    return nil, nil
end

local function isGuildMiningQuest(state)
    if not state or state.Done then return false end
    local lower = state.Lower
    local hasMiningTarget = string.find(lower, "rock", 1, true)
        or string.find(lower, "ore", 1, true)
        or string.find(lower, "mineral", 1, true)
    local hasMiningVerb = string.find(lower, "break", 1, true)
        or string.find(lower, "mine", 1, true)
    return hasMiningTarget ~= nil and hasMiningVerb ~= nil
end

local function normalizeQuestDescription(value)
    value = stripRichText(value)
    value = value:gsub("✔", "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return string.lower(value)
end

local function findGuildQuestByDescription(states, description, slot)
    local wanted = normalizeQuestDescription(description)
    for _, state in ipairs(states) do
        if state.Slot == slot
            and normalizeQuestDescription(state.Description) == wanted then
            return state
        end
    end
    return nil
end

local function getGuildCollectQuestState(states)
    for _, state in ipairs(states or getGuildQuestStates()) do
        if not state.Done and string.find(state.Lower, "collect your plot coins", 1, true) then
            return state
        end
    end
    return nil
end

local function getGuildUpgradeQuestState(states)
    for _, state in ipairs(states or getGuildQuestStates()) do
        if not state.Done and string.find(state.Lower, "upgrad", 1, true) then
            return state
        end
    end
    return nil
end

local function getGuildUpgradeAmount(state)
    local current, total = tostring(state.Progress or ""):match("(%d+)%s*/%s*(%d+)")
    if total then
        return math.max(1, tonumber(total) - tonumber(current))
    end

    local amount = state.Description:match("[Uu]pgrad%w*%s+(%d+)")
        or state.Description:match("(%d+)%s+[Uu]pgrad")
    return amount and math.max(1, tonumber(amount)) or nil
end

local function updateGuildQuestButton(message)
    if not guildQuestButton or not guildQuestButton.Parent then return end
    guildQuestButton.Text = AUTO_GUILD_QUESTS
        and "GUILD QUESTS: ON" or "GUILD QUESTS: OFF"
    guildQuestButton.BackgroundColor3 = AUTO_GUILD_QUESTS
        and Color3.fromRGB(55, 55, 55) or PANEL2
    if message then
        guildQuestStatus.Text = message
    elseif AUTO_GUILD_QUESTS then
        if GUILD_COLLECT_ACTIVE then
            guildQuestStatus.Text = "GUILD QUEST: COLLECTING PLOT COINS"
        elseif GUILD_UPGRADE_ACTIVE then
            guildQuestStatus.Text = "GUILD QUEST: UPGRADING"
        elseif GUILD_MINE_ACTIVE then
            guildQuestStatus.Text = "GUILD QUEST: MINING " .. string.upper(getDisplayName(GUILD_MINE_ZONE))
        else
            guildQuestStatus.Text = "GUILD QUESTS: WATCHING"
        end
    else
        guildQuestStatus.Text = "GUILD QUESTS: OFF"
    end
end

local function resetMiningAfterGuildTrip()
    currentRock = nil
    trackedRock = nil
    trackedRockStartHP = nil
    trackedRockStartTime = 0
    nextTeleportAt = 0
    nextRockAt = 0
    lastRescan = 0
end

local function completeGuildCollectQuest(mySession, quest)
    if type(fireproximityprompt) ~= "function" then
        updateGuildQuestButton("GUILD QUEST: PROMPT API MISSING")
        task.wait(2)
        return
    end

    GUILD_COLLECT_ACTIVE = true
    updateGuildQuestButton("GUILD QUEST: TELEPORTING TO PLOT")
    teleportToZone("Plot")
    task.wait(2)

    updateGuildQuestButton("GUILD QUEST: COLLECTING PLOT COINS")
    while AUTO_GUILD_QUESTS and not UNLOADED
        and GUILD_QUEST_SESSION == mySession do
        local latest = getGuildQuestStates()
        local current = findGuildQuestByDescription(latest, quest.Description, quest.Slot)
        if not current or current.Done then break end

        local prompt = getCollectPrompt()
        if prompt and prompt.Enabled and not AUTO_COLLECT then
            pcall(function() fireproximityprompt(prompt) end)
        end
        task.wait(0.5)
    end

    GUILD_COLLECT_ACTIVE = false
    resetMiningAfterGuildTrip()
    if not UNLOADED then
        updateGuildQuestButton("GUILD QUEST COMPLETE - RETURNING")
        teleportToSelectedZone()
        task.wait(1.5)
        if not RUNNING then
            startMining()
        end
    end
end

local function completeGuildUpgradeQuest(mySession, quest)
    local amount = getGuildUpgradeAmount(quest)
    if not amount then
        updateGuildQuestButton("UPGRADE QUEST: CANNOT READ REQUIRED AMOUNT")
        task.wait(3)
        return
    end

    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local upgradeRemote = remotes and remotes:FindFirstChild("RequestUpgrade")

    if not upgradeRemote or not upgradeRemote:IsA("RemoteFunction") then
        updateGuildQuestButton("UPGRADE QUEST: REMOTE NOT FOUND")
        task.wait(3)
        return
    end

    GUILD_UPGRADE_ACTIVE = true
    if RUNNING then
        stopMining()
    end

    updateGuildQuestButton("GUILD QUEST: TELEPORTING TO UPGRADER")
    teleportToZone("Upgrader")
    task.wait(1.5)

    local completedRequests = 0
    while completedRequests < amount and AUTO_GUILD_QUESTS and not UNLOADED
        and GUILD_QUEST_SESSION == mySession do

        local latest = getGuildQuestStates()
        local current = findGuildQuestByDescription(latest, quest.Description, quest.Slot)
        if not current or current.Done then
            break
        end

        local success, result = pcall(function()
            return upgradeRemote:InvokeServer({Coal = 1}, "Copper")
        end)

        if not success or result == false then
            updateGuildQuestButton("UPGRADE QUEST: REQUEST FAILED - RETRYING")
            task.wait(1)
        else
            completedRequests += 1
            updateGuildQuestButton("GUILD QUEST: UPGRADING " .. tostring(completedRequests) .. "/" .. tostring(amount))
            if completedRequests < amount then
                task.wait(1)
            end
        end
    end

    GUILD_UPGRADE_ACTIVE = false
    resetMiningAfterGuildTrip()

    if not UNLOADED then
        updateGuildQuestButton("UPGRADE QUEST FINISHED - RETURNING")
        teleportToSelectedZone()
        task.wait(1.5)
        if not RUNNING then
            startMining()
        end
    end
end

local function completeGuildMiningQuest(mySession, quest, zoneName, displayName)
    local rocksFolder = getRocksFolder(zoneName)
    if not rocksFolder then
        updateGuildQuestButton("QUEST ZONE LOCKED / ROCKS NOT FOUND: " .. string.upper(displayName))
        task.wait(3)
        return
    end

    GUILD_MINE_ACTIVE = true
    GUILD_MINE_ZONE = zoneName

    if RUNNING then
        stopMining()
    end

    resetMiningAfterGuildTrip()
    updateGuildQuestButton("GUILD QUEST: TELEPORTING TO " .. string.upper(displayName))
    teleportToZone(zoneName)
    task.wait(1.5)

    startMining()
    GUILD_STARTED_MINING = RUNNING

    updateGuildQuestButton("GUILD QUEST: MINING " .. string.upper(displayName))
    local lastStatusUpdate = 0
    while AUTO_GUILD_QUESTS and not UNLOADED
        and GUILD_QUEST_SESSION == mySession do

        local latest = getGuildQuestStates()
        local current = findGuildQuestByDescription(latest, quest.Description, quest.Slot)
        if not current or current.Done then
            break
        end

        if not RUNNING then
            startMining()
            if RUNNING then GUILD_STARTED_MINING = true end
        end

        if os.clock() - lastStatusUpdate >= 5 then
            updateGuildQuestButton("QUEST " .. tostring(quest.Slot) .. ": " .. string.upper(displayName) .. " | " .. current.Progress)
            lastStatusUpdate = os.clock()
        end
        task.wait(1)
    end

    if RUNNING then
        stopMining()
    end

    GUILD_MINE_ACTIVE = false
    GUILD_MINE_ZONE = nil
    GUILD_STARTED_MINING = false
    resetMiningAfterGuildTrip()

    if not UNLOADED then
        updateGuildQuestButton("GUILD QUEST COMPLETE - RETURNING")
        teleportToSelectedZone()
        task.wait(1.5)
        startMining()
    end
end

local function getGuildResetSeconds()
    local hud = PlayerGui:FindFirstChild("Hud")
    local windows = hud and hud:FindFirstChild("Windows")
    local guild = windows and windows:FindFirstChild("Guild", true)
    if not guild then return nil end

    for _, object in ipairs(guild:GetDescendants()) do
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            local value = stripRichText(object.Text)
            local lower = string.lower(value)
            if string.find(lower, "reset", 1, true) or string.find(lower, "next quest", 1, true) then
                local hours, minutes, seconds = value:match("(%d+):(%d+):(%d+)")
                if hours then
                    return tonumber(hours) * 3600 + tonumber(minutes) * 60 + tonumber(seconds), value
                end
                minutes, seconds = value:match("(%d+):(%d+)")
                if minutes then
                    return tonumber(minutes) * 60 + tonumber(seconds), value
                end
                local minutesOnly = value:match("(%d+)%s*[Mm][Ii][Nn]")
                if minutesOnly then
                    return tonumber(minutesOnly) * 60, value
                end
            end
        end
    end
    return nil
end

local function isGuildPlaytimeQuest(state)
    return state and string.find(state.Lower, "play for", 1, true) ~= nil
end

local function guildQuestWorker(mySession)
    while AUTO_GUILD_QUESTS and not UNLOADED
        and GUILD_QUEST_SESSION == mySession do

        local states = getGuildQuestStates()
        local upgradeQuest = getGuildUpgradeQuestState(states)
        if upgradeQuest then
            completeGuildUpgradeQuest(mySession, upgradeQuest)
        else
            local miningQuest
            local miningZone
            local miningDisplay

            for _, state in ipairs(states) do
            if isGuildMiningQuest(state) then
                local zoneName, displayName = resolveGuildQuestZone(state.Description)
                zoneName = zoneName or selectedZone
                displayName = displayName or getDisplayName(zoneName)

                if zoneName then
                    miningQuest = state
                    miningZone = zoneName
                    miningDisplay = displayName
                    break
                end
            end
        end

        if miningQuest then
            completeGuildMiningQuest(mySession, miningQuest, miningZone, miningDisplay)
        else
            local collectQuest = getGuildCollectQuestState(states)

            if collectQuest then
                completeGuildCollectQuest(mySession, collectQuest)
            else
                local unfinishedOtherQuest = false
                for _, state in ipairs(states) do
                    if not state.Done and not isGuildPlaytimeQuest(state) then
                        unfinishedOtherQuest = true
                        break
                    end
                end

                if not unfinishedOtherQuest then
                    local resetSeconds, resetText = getGuildResetSeconds()
                    if resetSeconds and resetSeconds > 0 then
                        local remaining = resetSeconds
                        while remaining > 0 and AUTO_GUILD_QUESTS and not UNLOADED
                            and GUILD_QUEST_SESSION == mySession do
                            local hours = math.floor(remaining / 3600)
                            local minutes = math.floor((remaining % 3600) / 60)
                            local seconds = remaining % 60
                            updateGuildQuestButton(string.format("NEXT GUILD QUESTS IN %02d:%02d:%02d", hours, minutes, seconds))
                            task.wait(1)
                            remaining -= 1
                        end
                    else
                        updateGuildQuestButton("GUILD QUESTS COMPLETE • WAITING FOR RESET")
                        task.wait(15)
                    end
                else
                    updateGuildQuestButton("GUILD QUESTS: CHECKING OBJECTIVES")
                    task.wait(3)
                end
            end
        end
        end
    end

    if GUILD_COLLECT_ACTIVE or GUILD_MINE_ACTIVE or GUILD_UPGRADE_ACTIVE then
        GUILD_COLLECT_ACTIVE = false
        GUILD_MINE_ACTIVE = false
        GUILD_UPGRADE_ACTIVE = false
        GUILD_MINE_ZONE = nil
        GUILD_STARTED_MINING = false
        resetMiningAfterGuildTrip()
        if not UNLOADED then
            teleportToSelectedZone()
            task.wait(1.5)
            if not RUNNING then startMining() end
        end
    end
end

local function stopGuildQuestAutomation()
    AUTO_GUILD_QUESTS = false
    GUILD_QUEST_SESSION += 1
    updateGuildQuestButton()
    queueSave()
end

local function startGuildQuestAutomation()
    if AUTO_GUILD_QUESTS or UNLOADED then return end

    AUTO_GUILD_QUESTS = true
    GUILD_QUEST_SESSION += 1
    local mySession = GUILD_QUEST_SESSION
    updateGuildQuestButton("GUILD QUESTS: SCANNING")
    queueSave()

    task.spawn(function()
        local ok, err = xpcall(function()
            guildQuestWorker(mySession)
        end, function(errorMessage)
            return tostring(errorMessage)
        end)

        if not ok and GUILD_QUEST_SESSION == mySession then
            AUTO_GUILD_QUESTS = false
            GUILD_COLLECT_ACTIVE = false
            GUILD_MINE_ACTIVE = false
            GUILD_UPGRADE_ACTIVE = false
            GUILD_MINE_ZONE = nil
            GUILD_STARTED_MINING = false
            updateGuildQuestButton("GUILD QUEST ERROR: " .. tostring(err):sub(1, 35))
            resetMiningAfterGuildTrip()
            teleportToSelectedZone()
            task.wait(1.5)
            if not RUNNING then startMining() end
            queueSave()
        end
    end)
end

guildQuestButton.MouseButton1Click:Connect(function()
    if AUTO_GUILD_QUESTS then
        stopGuildQuestAutomation()
    else
        startGuildQuestAutomation()
    end
end)

local function bossWorker(mySession)
    MineRemote = getMineRemote()

    if not MineRemote then
        AUTO_BOSS = false
        updateBossButton()
        queueSave()
        return
    end

    local bossWasActive = false
    local missingSince = nil
    local missingTimedOut = false

    local lastTarget = nil
    local lastHealth = nil
    local lastDamageAt = 0
    local lastTeleportAt = 0
    local lastAttackAt = 0

    local DAMAGE_TIMEOUT = 1.5
    local KNOCKBACK_DISTANCE = 3
    local TELEPORT_COOLDOWN = 0.35
    local BOSS_MISSING_TIMEOUT = 30

    while AUTO_BOSS
        and not UNLOADED
        and BOSS_SESSION == mySession do

        if GUILD_COLLECT_ACTIVE then
            task.wait(0.25)
            continue
        end

        local diamondFist = getDiamondFist()
        local rockBoss = getRockBoss()
        local gemPinata = getGemPinata()
        local humanoid, root = getCharacterParts()

        local fist = nil
        if diamondFist then
            fist = getBossFistPart(diamondFist, root)
        end

        local rockBossCFrame = rockBoss and getBossPosition(rockBoss)
        local hasRockBoss = rockBoss ~= nil and rockBossCFrame ~= nil
        local hasDiamondFist = fist ~= nil and fist.Parent ~= nil
        local pinataCFrame = gemPinata and getBossPosition(gemPinata)
        local hasGemPinata = gemPinata ~= nil and pinataCFrame ~= nil
        local hasBoss = hasRockBoss or hasDiamondFist or hasGemPinata

        if hasBoss then
            missingSince = nil
            missingTimedOut = false

            if not bossWasActive then
                bossWasActive = true
                lastTarget = nil
                lastHealth = nil
                lastDamageAt = os.clock()
                lastTeleportAt = 0

                for attempt = 1, 3 do
                    if not AUTO_BOSS or UNLOADED
                        or BOSS_SESSION ~= mySession then
                        break
                    end

                    teleportToZone("Spawn")
                    task.wait(0.5)
                end
            end

            local now = os.clock()

            if now - lastAttackAt >= BOSS_ATTACK_INTERVAL then
                lastAttackAt = now

                if hasRockBoss then
                    pcall(function()
                        MineRemote:FireServer(rockBoss)
                    end)
                end

                if hasDiamondFist then
                    pcall(function()
                        MineRemote:FireServer(diamondFist)
                    end)
                end

                if hasGemPinata then
                    pcall(function()
                        MineRemote:FireServer(gemPinata)
                    end)
                end
            end

            if humanoid and root then

                local target
                local targetCFrame

                if hasRockBoss then
                    target = rockBoss
                    targetCFrame = rockBossCFrame
                elseif hasDiamondFist then
                    target = fist
                    targetCFrame = fist.CFrame
                elseif hasGemPinata then
                    target = gemPinata
                    targetCFrame = pinataCFrame
                end

                if target and targetCFrame then
                    now = os.clock()
                    local health = getBossHealth(target)

                    if target ~= lastTarget then
                        lastTarget = target
                        lastHealth = health
                        lastDamageAt = now
                    elseif health ~= nil then
                        if lastHealth == nil or health < lastHealth then
                            lastDamageAt = now
                        end
                        lastHealth = health
                    end

                    local distance = (
                        root.Position - targetCFrame.Position
                    ).Magnitude

                    local knockedAway = distance > KNOCKBACK_DISTANCE
                    local stoppedTakingDamage = health ~= nil
                        and now - lastDamageAt >= DAMAGE_TIMEOUT

                    if (knockedAway or stoppedTakingDamage)
                        and now - lastTeleportAt >= TELEPORT_COOLDOWN then

                        teleportToBossTarget(root, targetCFrame)
                        lastTeleportAt = now
                        lastDamageAt = now
                    end
                end
            end
        else
            lastTarget = nil
            lastHealth = nil
            lastDamageAt = 0

            if not missingSince then
                missingSince = os.clock()
            end

            if bossWasActive
                and not missingTimedOut
                and os.clock() - missingSince >= BOSS_MISSING_TIMEOUT then

                bossWasActive = false
                missingTimedOut = true

                if not AUTO_BOSS
                    or UNLOADED
                    or BOSS_SESSION ~= mySession then
                    break
                end

                teleportToSelectedZone()
            end
        end

        task.wait(BOSS_ATTACK_INTERVAL)
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

    if GUILD_COLLECT_ACTIVE then
        task.wait(0.2)
        return
    end

    local zoneName = GUILD_MINE_ZONE or selectedZone

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
            or (GUILD_MINE_ZONE or selectedZone) ~= zoneName then
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
        or (GUILD_MINE_ZONE or selectedZone) ~= zoneName then
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

startMining = function()
    if UNLOADED or RUNNING or MINING_MANUALLY_STOPPED then return end
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

stopMining = function()
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

local function visitGuildPlot()
    if UNLOADED or GUILD_MINE_ACTIVE or GUILD_COLLECT_ACTIVE then
        return
    end

    local humanoid, root = getCharacterParts()
    if not humanoid or not root then
        return
    end

    local returnCFrame = root.CFrame
    local wasMining = RUNNING

    if wasMining then
        stopMining()
    end

    local character = Player.Character
    if not character or not character.Parent then
        if wasMining then startMining() end
        return
    end

    local currentRoot = character:FindFirstChild("HumanoidRootPart")
    if not currentRoot then
        if wasMining then startMining() end
        return
    end

    currentRoot.CFrame = CFrame.new(-31, 3, 47)
    task.wait(0.15)

    local inputService
    pcall(function()
        inputService = game:GetService("VirtualInputManager")
    end)

    local keySent = false
    if inputService then
        keySent = pcall(function()
            inputService:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.12)
            inputService:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
    end

    if not keySent and type(fireproximityprompt) == "function" then
        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("ProximityPrompt") and object.Enabled then
                local parent = object.Parent
                local promptPart = parent and (parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart", true))
                if promptPart and (promptPart.Position - Vector3.new(-31, 3, 47)).Magnitude <= 18 then
                    pcall(function() fireproximityprompt(object) end)
                    break
                end
            end
        end
    end

    task.wait(1)

    if not UNLOADED then
        local returnCharacter = Player.Character
        local returnRoot = returnCharacter and returnCharacter:FindFirstChild("HumanoidRootPart")
        if returnRoot then
            returnRoot.CFrame = returnCFrame
        end
        if wasMining and selectedZone then
            startMining()
        end
    end
end

task.spawn(function()
    while not UNLOADED do
        task.wait(120)
        if not UNLOADED and not GUILD_MINE_ACTIVE and not GUILD_COLLECT_ACTIVE then
            visitGuildPlot()
        end
    end
end)

startButton.MouseButton1Click:Connect(function()
    MINING_MANUALLY_STOPPED = false
    startMining()
end)

stopButton.MouseButton1Click:Connect(function()
    MINING_MANUALLY_STOPPED = true
    stopMining()
end)

updateLayout = function(animate)
    if settingsPageOpen then
        minerWindow.Visible = true
        guildWindow.Visible = false
        main.Size = UDim2.fromOffset(290, 251)
        return
    elseif guildStatusPageOpen then
        guildWindow.Visible = true
        minerWindow.Visible = false
        main.Size = UDim2.fromOffset(290, 251)
        return
    end

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
    if settingsPageOpen or guildStatusPageOpen then
        showMainPage()
    end
    guiMinimized = not guiMinimized
    queueSave()
    updateLayout(true)
end)

close.MouseButton1Click:Connect(function()
    saveConfig()

    UNLOADED = true
    settingsPageOpen = false
    guildStatusPageOpen = false

    RUNNING = false
    SESSION += 1

    AUTO_BOSS = false
    BOSS_SESSION += 1

    AUTO_BUY = false
    BUY_SESSION += 1

    AUTO_PLAYTIME = false
    PLAYTIME_SESSION += 1

    AUTO_COLLECT = false
    COLLECT_SESSION += 1

    AUTO_SELL = false
    SELL_SESSION += 1

    AUTO_SPIN = false
    SPIN_SESSION += 1

    AUTO_GUILD_QUESTS = false
    GUILD_COLLECT_ACTIVE = false
    GUILD_QUEST_SESSION += 1

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
updatePlaytimeButton()
updateAutoCollectButton()
updateAutoSellButton()
updateAutoSpinButton()
updateGuildQuestButton()
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
        task.wait(1)
    end

    if resumePlaytime and not UNLOADED then
        startAutoPlaytime()
        task.wait(1)
    end

    if resumeCollect and not UNLOADED then
        startAutoCollect()
        task.wait(1)
    end

    if resumeSell and not UNLOADED then
        startAutoSell()
        task.wait(1)
    end

    if resumeSpin and not UNLOADED then
        startAutoSpin()
        task.wait(1)
    end

    if resumeGuildQuests and not UNLOADED then
        startGuildQuestAutomation()
    end

    saveConfig()
end)
