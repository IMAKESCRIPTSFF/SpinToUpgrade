 Players = game:GetService("Players")
getgenv().SWS_HUB_UI_STATE = getgenv().SWS_HUB_UI_STATE or {}
getgenv().SWS_HUB_ANIM = getgenv().SWS_HUB_ANIM or {}
do
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local Player = Players.LocalPlayer
    local PlayerGui = Player:WaitForChild("PlayerGui")
    local AuthUrl = "https://sws-key-system.swshub.workers.dev/verify"
    local CacheFile = "SWS_HUB_KEY_" .. tostring(Player.UserId) .. ".json"
    local CurrentKey = ""
    local CurrentType = ""
    local AuthRequest = request or http_request or (syn and syn.request)
    local function getHardwareId()
        if type(get_hwid) == "function" then
            local ok, value = pcall(get_hwid)
            if ok and value then return tostring(value) end
        end
        if type(gethwid) == "function" then
            local ok, value = pcall(gethwid)
            if ok and value then return tostring(value) end
        end
        return nil
    end
    local HardwareId = getHardwareId()
    local function readCachedKey()
        if type(readfile) ~= "function" then return nil end
        local ok, contents = pcall(readfile, CacheFile)
        if not ok or type(contents) ~= "string" or contents == "" then return nil end
        local decodedOK, decoded = pcall(function()
            return HttpService:JSONDecode(contents)
        end)
        if decodedOK and type(decoded) == "table" and decoded.userId == Player.UserId and type(decoded.key) == "string" then
            return decoded.key
        end
        return nil
    end
    local function saveCachedKey(key, keyType, expiry)
        local data = {
            userId = Player.UserId,
            key = key,
            type = keyType,
            expiresAt = expiry,
            savedAt = os.time()
        }
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(data)
        end)
        if ok and type(writefile) == "function" then
            pcall(writefile, CacheFile, encoded)
        end
        local environment = getgenv and getgenv()
        if environment then
            environment.SWS_HUB_KEY_CACHE = data
        end
    end
    local function clearCachedKey()
        local environment = getgenv and getgenv()
        if environment then environment.SWS_HUB_KEY_CACHE = nil end
        if type(delfile) == "function" then pcall(delfile, CacheFile) end
    end
    local function verifyKey(key)
        if not AuthRequest or not HardwareId or type(key) ~= "string" or key == "" then
            return false, "EXECUTOR AUTH SUPPORT MISSING"
        end
        local ok, response = pcall(function()
            return AuthRequest({
                Url = AuthUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    key = key,
                    hwid = HardwareId
                })
            })
        end)
        if not ok or type(response) ~= "table" then
            return nil, "SERVER CHECK FAILED"
        end
        local body = response.Body or response.body
        if type(body) ~= "string" then
            return nil, "INVALID SERVER RESPONSE"
        end
        local decodedOK, decoded = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if not decodedOK or type(decoded) ~= "table" then
            return nil, "INVALID SERVER RESPONSE"
        end
        if decoded.valid == true then
            return true, decoded
        end
        return false, decoded.message or decoded.error or "KEY EXPIRED / REVOKED"
    end
    local screen = Instance.new("ScreenGui")
    screen.Name = "SWSKeyGate"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 10000
    screen.Parent = PlayerGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(330, 190)
    frame.Position = UDim2.new(0.5, -165, 0.5, -95)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    frame.BorderSizePixel = 0
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 9)
    local outline = Instance.new("UIStroke")
    outline.Color = Color3.fromRGB(100, 100, 100)
    outline.Transparency = 0.35
    outline.Parent = frame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 32)
    title.Position = UDim2.fromOffset(12, 10)
    title.BackgroundTransparency = 1
    title.Text = "SWS HUB | KEY VERIFICATION"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = frame
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -28, 0, 38)
    input.Position = UDim2.fromOffset(14, 55)
    input.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    input.BorderSizePixel = 0
    input.PlaceholderText = "Enter your SWS key"
    input.Text = ""
    input.ClearTextOnFocus = false
    input.TextColor3 = Color3.new(1, 1, 1)
    input.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    input.Font = Enum.Font.Gotham
    input.TextSize = 12
    input.Parent = frame
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
    local verify = Instance.new("TextButton")
    verify.Size = UDim2.new(0.5, -21, 0, 34)
    verify.Position = UDim2.fromOffset(14, 103)
    verify.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    verify.BorderSizePixel = 0
    verify.Text = "VERIFY KEY"
    verify.TextColor3 = Color3.new(1, 1, 1)
    verify.Font = Enum.Font.GothamBold
    verify.TextSize = 11
    verify.Parent = frame
    Instance.new("UICorner", verify).CornerRadius = UDim.new(0, 6)
    local getKey = Instance.new("TextButton")
    getKey.Size = UDim2.new(0.5, -21, 0, 34)
    getKey.Position = UDim2.new(0.5, 7, 0, 103)
    getKey.BackgroundColor3 = Color3.fromRGB(45, 75, 115)
    getKey.BorderSizePixel = 0
    getKey.Text = "GET KEY"
    getKey.TextColor3 = Color3.new(1, 1, 1)
    getKey.Font = Enum.Font.GothamBold
    getKey.TextSize = 11
    getKey.Parent = frame
    Instance.new("UICorner", getKey).CornerRadius = UDim.new(0, 6)
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -24, 0, 25)
    status.Position = UDim2.fromOffset(12, 151)
    status.BackgroundTransparency = 1
    status.Text = "CONNECTING TO CLOUDFLARE..."
    status.TextColor3 = Color3.fromRGB(190, 190, 190)
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.Parent = frame
    local completed = false
    local checking = false
    local function isPermanentAccess(keyType, expiry)
        local normalized = tostring(keyType or ""):lower():gsub("[%s_%-]", "")
        if normalized:find("permanent", 1, true)
            or normalized:find("lifetime", 1, true)
            or normalized:find("unlimited", 1, true)
            or normalized:find("forever", 1, true)
            or normalized:find("owner", 1, true) then
            return true
        end
        if type(expiry) == "number" and expiry > os.time() + (10 * 365 * 24 * 60 * 60) then
            return true
        end
        return false
    end
    local function showAccessStatus(keyType, expiry)
        local state = getgenv().SWS_HUB_UI_STATE
        state.permanent = isPermanentAccess(keyType, expiry)
        state.expiry = expiry
        state.active = true
    end
    local function attempt(key)
        if checking or completed then return end
        checking = true
        verify.Text = "CHECKING..."
        status.TextColor3 = Color3.fromRGB(210, 210, 210)
        status.Text = "VERIFYING WITH SERVER..."
        local valid, result = verifyKey(key)
        if valid == true then
            CurrentKey = key
            local accessData = type(result) == "table" and result or {}
            CurrentType = tostring(accessData.type or accessData.accessType or accessData.keyType or accessData.plan or "24h")
            local expiry = tonumber(accessData.expiresAt or accessData.expires_at or accessData.expiry or accessData.expiration)
            local permanent = isPermanentAccess(CurrentType, expiry) or accessData.permanent == true or accessData.isPermanent == true
            if permanent then
                CurrentType = "permanent"
                expiry = nil
            elseif not expiry then
                expiry = os.time() + 86400
            elseif expiry > 100000000000 then
                expiry = math.floor(expiry / 1000)
            end
            saveCachedKey(key, CurrentType, expiry)
            showAccessStatus(CurrentType, expiry)
            completed = true
            status.Text = "KEY VERIFIED"
            status.TextColor3 = Color3.fromRGB(130, 220, 150)
            task.wait(0.25)
            screen:Destroy()
        elseif valid == false then
            clearCachedKey()
            status.Text = tostring(result)
            status.TextColor3 = Color3.fromRGB(255, 115, 115)
        else
            status.Text = tostring(result)
            status.TextColor3 = Color3.fromRGB(255, 190, 100)
        end
        checking = false
        verify.Text = "VERIFY KEY"
    end
    getKey.MouseButton1Click:Connect(function()
        local keyPage = "https://sws-key-system.swshub.workers.dev/"
        local opened = false
        if type(openurl) == "function" then
            opened = pcall(openurl, keyPage)
        elseif type(open_url) == "function" then
            opened = pcall(open_url, keyPage)
        elseif syn and type(syn.open_url) == "function" then
            opened = pcall(syn.open_url, keyPage)
        end
        if not opened and type(setclipboard) == "function" then
            opened = pcall(setclipboard, keyPage)
        end
        if opened then
            status.Text = "KEY PAGE OPENED / LINK COPIED"
            status.TextColor3 = Color3.fromRGB(130, 220, 150)
        else
            status.Text = "OPEN https://sws-key-system.swshub.workers.dev/"
            status.TextColor3 = Color3.fromRGB(255, 190, 100)
        end
    end)
    verify.MouseButton1Click:Connect(function()
        attempt(input.Text)
    end)
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then attempt(input.Text) end
    end)
    local cachedKey = readCachedKey()
    if cachedKey then
        input.Text = cachedKey
        task.spawn(function()
            attempt(cachedKey)
        end)
    else
        status.Text = "ENTER YOUR KEY TO CONTINUE"
    end
    while not completed do
        task.wait(0.1)
        if not screen.Parent then
            error("SWS key verification was closed")
        end
    end
    _G.SWS_HUB_AUTH_KEY = CurrentKey
    _G.SWS_HUB_AUTH_TYPE = CurrentType
end

 ReplicatedStorage = game:GetService("ReplicatedStorage")
 TweenService = game:GetService("TweenService")
 HttpService = game:GetService("HttpService")

 Player = Players.LocalPlayer
 PlayerGui = Player:WaitForChild("PlayerGui")
 ZonesFolder = workspace:WaitForChild("Zones")

 MINING_INTERVAL = 0.01
 TELEPORT_RETRY_DELAY = 0.75
 TELEPORT_SUCCESS_DISTANCE = 5
 TELEPORT_SETTLE_DELAY = 0.15
 ORE_CLEARANCE = 1
 NEXT_ROCK_DELAY = 0.3
 SCAN_DELAY = 0.4
 RESCAN_INTERVAL = 2
 ERROR_RETRY_DELAY = 1
 NO_DAMAGE_TIMEOUT = 0.4
 SKIP_DURATION = 3

 AUTO_BUY_INTERVAL = 10
 CRAFT_REQUEST_DELAY = 0.5

 BOSS_TELEPORT_INTERVAL = 0.10
 BOSS_ATTACK_INTERVAL = 0.05

 CONFIG_FILE = "SWS_HUB_STU"

 MinerNames = {
    "StoneMiner", "CoalMiner", "CopperMiner", "IronMiner",
    "GoldMiner", "RubyMiner", "SapphireMiner", "EmeraldMiner",
    "DiamondMiner", "VoidstoneMiner", "ToxiteMiner", "StarliteMiner",
    "CelestiumMiner", "MoonstoneMiner", "PrismiteMiner", "AuroriumMiner",
    "FrostiteMiner", "AquamarineMiner", "DragonscaleMiner", "NeoniteMiner",
    "DarkMatterMiner", "BrassiteMiner", "PixeliteMiner", "HaloiteMiner",
    "NebuliteMiner", "SoulstoneMiner", "PumpkinMiner"
}

 zoneOrder = {
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

 knownZoneNames = {}
for _, entry in ipairs(zoneOrder) do
    knownZoneNames[entry[1]] = true
end

 discoveredZones = ZonesFolder:GetChildren()
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

 BLACK = Color3.fromRGB(5, 5, 5)
 PANEL = Color3.fromRGB(14, 14, 14)
 PANEL2 = Color3.fromRGB(22, 22, 22)
 WHITE = Color3.fromRGB(255, 255, 255)
 GREY = Color3.fromRGB(155, 155, 155)

 RUNNING = false
 MINING_MANUALLY_STOPPED = false
 AUTO_BOSS = false
 AUTO_BUY = false
 AUTO_PLAYTIME = false
 AUTO_COLLECT = false
 AUTO_SELL = false
 AUTO_SPIN = false
 AUTO_GUILD_QUESTS = false
 GUILD_COLLECT_ACTIVE = false
 GUILD_MINE_ACTIVE = false
 GUILD_UPGRADE_ACTIVE = false
 GUILD_MINE_ZONE = nil
 UNLOADED = false

 SESSION = 0
 BOSS_SESSION = 0
 BUY_SESSION = 0
 PLAYTIME_SESSION = 0
 COLLECT_SESSION = 0
 SELL_SESSION = 0
 SPIN_SESSION = 0
 GUILD_QUEST_SESSION = 0

 selectedZone
 selectedMiners = {}
 availableZones = {}
 zoneRows = {}
 minerRows = {}

 selectorExpanded = true
 guiMinimized = false
 savedGuiPosition

 startMining
 stopMining

 currentRock
 trackedRock
 trackedRockStartHP
 trackedRockStartTime = 0

 skippedRocks = setmetatable({}, {__mode = "k"})

 nextTeleportAt = 0
 nextRockAt = 0
 lastRescan = 0

 lastBossTeleport = 0
 lastBossAttack = 0

 MineRemote

 savedConfig = {}
 saveQueued = false
 configStatusLabel

 function readConfigFile(fileName)
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

 function loadConfig()
    local result = readConfigFile(CONFIG_FILE)
    if type(result) == "table" then
        savedConfig = result
    end
end

 function setConfigStatus(message, success)
    if configStatusLabel and configStatusLabel.Parent then
        configStatusLabel.Text = "CONFIG: " .. tostring(message)
        configStatusLabel.TextColor3 = success
            and Color3.fromRGB(130, 220, 150)
            or Color3.fromRGB(255, 135, 135)
    end
end

 function saveConfig()
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

 function queueSave()
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

 resumeBoss = savedConfig.AutoBoss == true
 resumeBuy = savedConfig.AutoBuy == true
 resumePlaytime = savedConfig.AutoPlaytime == true
 resumeCollect = savedConfig.AutoCollect == true
 resumeSell = savedConfig.AutoSell == true
 resumeSpin = savedConfig.AutoSpin == true
 resumeGuildQuests = savedConfig.AutoGuildQuests == true

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

 function getDisplayName(name)
    for _, entry in ipairs(availableZones) do
        if entry.Folder == name then
            return entry.Display
        end
    end

    return tostring(name or "Unknown")
end

 old = PlayerGui:FindFirstChild("MultiZoneMinerV25")
if old then old:Destroy() end

 gui = Instance.new("ScreenGui")
gui.Name = "MultiZoneMinerV25"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

 function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = object
end

 function stroke(object, transparency)
    local s = Instance.new("UIStroke")
    s.Color = WHITE
    s.Thickness = 1
    s.Transparency = transparency or 0.6
    s.Parent = object
    return s
end

 function makeButton(parent, text, size, position)
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

 settingsPageOpen = false
 guildStatusPageOpen = false

 main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(290, 269)
main.Position = UDim2.new(0.5, -145, 0.5, -134)
main.BackgroundColor3 = BLACK
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui

corner(main, 10)
 mainStroke = stroke(main, 0.45)

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

 title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -195, 0, 30)
title.Position = UDim2.fromOffset(12, 3)
title.BackgroundTransparency = 1
title.Text = "SWS HUB"
title.TextColor3 = WHITE
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

getgenv().SWS_HUB_UI_STATE.label = Instance.new("TextLabel")
getgenv().SWS_HUB_UI_STATE.label.Name = "KeyTimeStatus"
getgenv().SWS_HUB_UI_STATE.label.AnchorPoint = Vector2.new(0, 1)
getgenv().SWS_HUB_UI_STATE.label.Position = UDim2.new(0, 10, 1, -7)
getgenv().SWS_HUB_UI_STATE.label.Size = UDim2.new(1, -20, 0, 16)
getgenv().SWS_HUB_UI_STATE.label.BackgroundTransparency = 1
getgenv().SWS_HUB_UI_STATE.label.Text = "KEY TIME: CHECKING"
getgenv().SWS_HUB_UI_STATE.label.TextColor3 = Color3.fromRGB(130, 220, 150)
getgenv().SWS_HUB_UI_STATE.label.Font = Enum.Font.GothamBold
getgenv().SWS_HUB_UI_STATE.label.TextSize = 10
getgenv().SWS_HUB_UI_STATE.label.TextXAlignment = Enum.TextXAlignment.Left
getgenv().SWS_HUB_UI_STATE.label.Parent = main

task.spawn(function()
    while gui.Parent and not UNLOADED do
        local state = getgenv().SWS_HUB_UI_STATE
        local label = state.label
        if label and label.Parent then
            if state.active and state.permanent then
                label.Text = "KEY TIME: PERMANENT"
                label.TextColor3 = Color3.fromRGB(130, 220, 150)
            elseif state.active and type(state.expiry) == "number" then
                local remaining = math.max(0, state.expiry - os.time())
                local hours = math.floor(remaining / 3600)
                local minutes = math.floor((remaining % 3600) / 60)
                local seconds = remaining % 60
                label.Text = string.format("KEY TIME: %02d:%02d:%02d", hours, minutes, seconds)
                label.TextColor3 = remaining > 0 and Color3.fromRGB(130, 220, 150) or Color3.fromRGB(255, 115, 115)
                if remaining <= 0 then label.Text = "KEY: EXPIRED" end
            elseif state.active then
                label.Text = "KEY TIME: CHECK SERVER"
            end
        end
        task.wait(1)
    end
end)

 minersOpenButton = makeButton(
    main, "FEATURES",
    UDim2.fromOffset(48, 23),
    UDim2.new(1, -113, 0, 5)
)

 guildStatusOpenButton = makeButton(
    main, "GUILD",
    UDim2.fromOffset(48, 23),
    UDim2.new(1, -165, 0, 5)
)

 minimize = makeButton(
    main, "-",
    UDim2.fromOffset(24, 23),
    UDim2.new(1, -57, 0, 5)
)

 close = makeButton(
    main, "X",
    UDim2.fromOffset(24, 23),
    UDim2.new(1, -29, 0, 5)
)

 zoneToggle = makeButton(
    main, "ZONES ▼",
    UDim2.new(1, -20, 0, 23),
    UDim2.fromOffset(10, 35)
)

 search = Instance.new("TextBox")
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

 searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 8)
searchPadding.Parent = search

 scroll = Instance.new("ScrollingFrame")
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

 layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

 scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 5)
scrollPadding.PaddingLeft = UDim.new(0, 5)
scrollPadding.PaddingRight = UDim.new(0, 5)
scrollPadding.Parent = scroll

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.fromOffset(
        0, layout.AbsoluteContentSize.Y + 10
    )
end)

 selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, -20, 0, 17)
selectedLabel.Position = UDim2.fromOffset(10, 186)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = WHITE
selectedLabel.TextSize = 10
selectedLabel.Font = Enum.Font.GothamBold
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = main

 startButton = makeButton(
    main, "MINING",
    UDim2.fromOffset(85, 32),
    UDim2.fromOffset(10, 209)
)

 bossButton = makeButton(
    main, "BOSS: OFF",
    UDim2.fromOffset(85, 32),
    UDim2.fromOffset(102, 209)
)

 stopButton = makeButton(
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

 minerWindow = Instance.new("Frame")
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

 guildWindow = Instance.new("Frame")
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

 guildTitle = Instance.new("TextLabel")
guildTitle.Size = UDim2.new(1, -65, 0, 32)
guildTitle.Position = UDim2.fromOffset(12, 3)
guildTitle.BackgroundTransparency = 1
guildTitle.Text = "GUILD STATUS / PAGE 3"
guildTitle.TextColor3 = WHITE
guildTitle.TextSize = 12
guildTitle.Font = Enum.Font.GothamBold
guildTitle.TextXAlignment = Enum.TextXAlignment.Left
guildTitle.Parent = guildWindow

 guildBackButton = makeButton(
    guildWindow, "BACK",
    UDim2.fromOffset(48, 23),
    UDim2.new(1, -58, 0, 5)
)

 guildRefreshButton = makeButton(
    guildWindow, "REFRESH QUESTS",
    UDim2.new(1, -20, 0, 25),
    UDim2.fromOffset(10, 37)
)

guildRefreshButton.BackgroundColor3 = Color3.fromRGB(42, 54, 70)

 guildRefreshStatus = Instance.new("TextLabel")
guildRefreshStatus.Size = UDim2.new(1, -20, 0, 18)
guildRefreshStatus.Position = UDim2.fromOffset(10, 66)
guildRefreshStatus.BackgroundTransparency = 1
guildRefreshStatus.Text = "OPEN THIS PAGE TO LOAD GUILD QUESTS"
guildRefreshStatus.TextColor3 = GREY
guildRefreshStatus.TextSize = 9
guildRefreshStatus.Font = Enum.Font.Gotham
guildRefreshStatus.TextXAlignment = Enum.TextXAlignment.Left
guildRefreshStatus.Parent = guildWindow

 guildQuestScroll = Instance.new("ScrollingFrame")
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

 guildQuestLayout = Instance.new("UIListLayout")
guildQuestLayout.Padding = UDim.new(0, 6)
guildQuestLayout.SortOrder = Enum.SortOrder.LayoutOrder
guildQuestLayout.Parent = guildQuestScroll

 guildQuestPadding = Instance.new("UIPadding")
guildQuestPadding.PaddingTop = UDim.new(0, 6)
guildQuestPadding.PaddingLeft = UDim.new(0, 6)
guildQuestPadding.PaddingRight = UDim.new(0, 6)
guildQuestPadding.PaddingBottom = UDim.new(0, 6)
guildQuestPadding.Parent = guildQuestScroll

guildQuestLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    guildQuestScroll.CanvasSize = UDim2.fromOffset(0, guildQuestLayout.AbsoluteContentSize.Y + 14)
end)

 minerTitle = Instance.new("TextLabel")
minerTitle.Size = UDim2.new(1, -45, 0, 32)
minerTitle.Position = UDim2.fromOffset(12, 3)
minerTitle.BackgroundTransparency = 1
minerTitle.Text = "AUTOMATION SETTINGS / PAGE 2"
minerTitle.TextColor3 = WHITE
minerTitle.TextSize = 12
minerTitle.Font = Enum.Font.GothamBold
minerTitle.TextXAlignment = Enum.TextXAlignment.Left
minerTitle.Parent = minerWindow

 minerClose = makeButton(
    minerWindow, "BACK",
    UDim2.fromOffset(48, 23),
    UDim2.new(1, -58, 0, 5)
)

 minerDescription = Instance.new("TextLabel")
minerDescription.Size = UDim2.new(1, -20, 0, 30)
minerDescription.Position = UDim2.fromOffset(10, 35)
minerDescription.BackgroundTransparency = 1
minerDescription.Text = "Select miners and manage every automation toggle below."
minerDescription.TextColor3 = GREY
minerDescription.TextSize = 9
minerDescription.Font = Enum.Font.Gotham
minerDescription.TextXAlignment = Enum.TextXAlignment.Left
minerDescription.Parent = minerWindow

 minerCount = Instance.new("TextLabel")
minerCount.Size = UDim2.new(1, -20, 0, 17)
minerCount.Position = UDim2.fromOffset(10, 62)
minerCount.BackgroundTransparency = 1
minerCount.TextColor3 = WHITE
minerCount.TextSize = 10
minerCount.Font = Enum.Font.GothamBold
minerCount.TextXAlignment = Enum.TextXAlignment.Left
minerCount.Parent = minerWindow

 minerScroll = Instance.new("ScrollingFrame")
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

 minerLayout = Instance.new("UIListLayout")
minerLayout.Padding = UDim.new(0, 2)
minerLayout.SortOrder = Enum.SortOrder.LayoutOrder
minerLayout.Parent = minerScroll

 minerPadding = Instance.new("UIPadding")
minerPadding.PaddingTop = UDim.new(0, 5)
minerPadding.PaddingLeft = UDim.new(0, 5)
minerPadding.PaddingRight = UDim.new(0, 5)
minerPadding.Parent = minerScroll

minerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    minerScroll.CanvasSize = UDim2.fromOffset(
        0, minerLayout.AbsoluteContentSize.Y + 12
    )
end)

 function getSelectedMinerCount()
    local count = 0

    for _, name in ipairs(MinerNames) do
        if selectedMiners[name] then
            count += 1
        end
    end

    return count
end

 function updateMinerCount()
    minerCount.Text = "SELECTED: "
        .. getSelectedMinerCount()
        .. " / "
        .. #MinerNames
end

 function updateMinerRows()
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

 selectAllButton = makeButton(
    minerScroll, "SELECT ALL",
    UDim2.new(1, -3, 0, 23),
    UDim2.fromOffset(0, 0)
)

 deselectAllButton = makeButton(
    minerScroll, "DESELECT ALL",
    UDim2.new(1, -3, 0, 23),
    UDim2.fromOffset(0, 0)
)

selectAllButton.LayoutOrder = 100
deselectAllButton.LayoutOrder = 101

 minerListExpanded = false
 minerSelectionHeader = makeButton(
    minerScroll, "SELECT MINERS  [+]",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)
minerSelectionHeader.LayoutOrder = 1

 function setMinerListExpanded(expanded, animate)
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

 purchaseStatus = Instance.new("TextLabel")
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

 autoBuyButton = makeButton(
    minerScroll, "AUTO BUY: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

 stopBuyButton = makeButton(
    minerScroll, "STOP",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

 playtimeStatus = Instance.new("TextLabel")
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

 playtimeButton = makeButton(
    minerScroll, "PLAYTIME: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

 collectStatus = Instance.new("TextLabel")
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

 collectButton = makeButton(
    minerScroll, "AUTO COLLECT: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

 guildQuestStatus = Instance.new("TextLabel")
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

 guildQuestButton = makeButton(
    minerScroll, "GUILD QUESTS: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)

 sellStatus = Instance.new("TextLabel")
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

 sellButton = makeButton(
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

 spinStatus = Instance.new("TextLabel")
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

 spinButton = makeButton(
    minerScroll, "AUTO SPIN: OFF",
    UDim2.new(1, -3, 0, 24),
    UDim2.fromOffset(0, 0)
)
spinButton.LayoutOrder = 115

 function setStatus(message)
    return
end

 function setPurchaseStatus(message)
    if not UNLOADED and purchaseStatus.Parent then
        purchaseStatus.Text = tostring(message)
    end
end

 function getCraftRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("CraftMiner")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

 function updateAutoBuyButton()
    autoBuyButton.Text = AUTO_BUY and "AUTO BUY: ON" or "AUTO BUY: OFF"
    autoBuyButton.BackgroundColor3 = AUTO_BUY
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
end

 function stopAutoBuy()
    AUTO_BUY = false
    BUY_SESSION += 1

    updateAutoBuyButton()
    setPurchaseStatus("AUTO BUY STOPPED")
    queueSave()
end

 function autoBuyWorker(mySession)
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

 function startAutoBuy()
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

 function getPlaytimeRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("ClaimPlaytimeGift")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

 function updatePlaytimeButton()
    playtimeButton.Text = AUTO_PLAYTIME and "PLAYTIME: ON" or "PLAYTIME: OFF"
    playtimeButton.BackgroundColor3 = AUTO_PLAYTIME
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
    playtimeStatus.Text = AUTO_PLAYTIME and "PLAYTIME CLAIM: RUNNING" or "PLAYTIME: OFF"
end

 function stopAutoPlaytime()
    AUTO_PLAYTIME = false
    PLAYTIME_SESSION += 1
    updatePlaytimeButton()
    queueSave()
end

 function autoPlaytimeWorker(mySession)
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

 function startAutoPlaytime()
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

 function getSellOresRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("SellOres")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

 function updateAutoSellButton()
    if not sellButton.Parent then return end

    sellButton.Text = AUTO_SELL and "AUTO SELL: ON" or "AUTO SELL: OFF"
    sellButton.BackgroundColor3 = AUTO_SELL
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
    sellStatus.Text = AUTO_SELL and "AUTO SELL: RUNNING" or "AUTO SELL: OFF"
end

 function stopAutoSell()
    AUTO_SELL = false
    SELL_SESSION += 1
    updateAutoSellButton()
    queueSave()
end

 function autoSellWorker(mySession)
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

 function startAutoSell()
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

 function getSpinRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("SpinWheel")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

 function updateAutoSpinButton()
    if not spinButton.Parent then return end

    spinButton.Text = AUTO_SPIN and "AUTO SPIN: ON" or "AUTO SPIN: OFF"
    spinButton.BackgroundColor3 = AUTO_SPIN
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
    spinStatus.Text = AUTO_SPIN and "AUTO SPIN: RUNNING" or "AUTO SPIN: OFF"
end

 function stopAutoSpin()
    AUTO_SPIN = false
    SPIN_SESSION += 1
    updateAutoSpinButton()
    queueSave()
end

 function autoSpinWorker(mySession)
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

 function startAutoSpin()
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

 function getCollectPrompt()
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

 function updateAutoCollectButton()
    if not collectButton.Parent then return end

    collectButton.Text = AUTO_COLLECT and "AUTO COLLECT: ON" or "AUTO COLLECT: OFF"
    collectButton.BackgroundColor3 = AUTO_COLLECT
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
    collectStatus.Text = AUTO_COLLECT and "AUTO COLLECT: RUNNING" or "AUTO COLLECT: OFF"
end

 function stopAutoCollect()
    AUTO_COLLECT = false
    COLLECT_SESSION += 1
    updateAutoCollectButton()
    queueSave()
end

 function autoCollectWorker(mySession)
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

 function startAutoCollect()
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

 updateLayout
 pageReturnPosition
 refreshGuildStatus

 function showMainPage()
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

 function showSettingsPage()
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

 function showGuildStatusPage()
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

 function updateSelection()
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

 function refreshZoneSearch()
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

 function getRocksFolder(zoneName)
    local zone = ZonesFolder:FindFirstChild(zoneName)
    return zone and zone:FindFirstChild("Rocks")
end

 function getRockPart(rock)
    if not rock then return nil end

    return rock.PrimaryPart
        or rock:FindFirstChildWhichIsA("BasePart", true)
end

 function getPositionAboveOre(rock, root)
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

 function validRock(rock, zoneName)
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

 function getCharacterParts()
    local character = Player.Character

    if not character then return nil, nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return nil, nil
    end

    return humanoid, root
end

 function getMineRemote()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local remotes = shared and shared:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("MineRock")

    if remote and remote:IsA("RemoteEvent") then
        return remote
    end

    return nil
end

 function getDiamondFist()
    local adminEvents = workspace:FindFirstChild("AdminEvents")
    return adminEvents and adminEvents:FindFirstChild("DiamondFist")
end

 function getRockBoss()
    local adminEvents = workspace:FindFirstChild("AdminEvents")
    return adminEvents and adminEvents:FindFirstChild("RockBoss")
end

 function getGemPinata()
    local adminEvents = workspace:FindFirstChild("AdminEvents")
    return adminEvents and adminEvents:FindFirstChild("GemPinata")
end

 function getBossFistPart(boss, root)
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

 function getBossHealthObject(boss)
    if not boss then return nil end

    if boss:IsA("Model") then
        return boss:FindFirstChildWhichIsA("Humanoid", true)
    end

    return nil
end

 function getBossPosition(boss)
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

 function getBossHealth(boss)
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

 function teleportToBossTarget(root, targetCFrame)
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

 function updateBossButton()
    bossButton.Text = AUTO_BOSS and "BOSS: ON" or "BOSS: OFF"
    bossButton.BackgroundColor3 = AUTO_BOSS
        and Color3.fromRGB(55, 55, 55)
        or PANEL2
end

 function stopBoss()
    AUTO_BOSS = false
    BOSS_SESSION += 1

    updateBossButton()
    queueSave()
end

 function teleportToZone(zoneName)
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

 function teleportToSelectedZone()
    return teleportToZone(selectedZone)
end

 function stripRichText(value)
    value = tostring(value or "")
    value = value:gsub("<[^>]->", "")
    return value:gsub("&nbsp;", " ")
end

 function getGuildQuestStates()
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

 function triggerNativeGuildRefresh()
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

 function clearGuildQuestCards()
    for _, child in ipairs(guildQuestScroll:GetChildren()) do
        if child ~= guildQuestLayout and child ~= guildQuestPadding then
            child:Destroy()
        end
    end
end

 function renderGuildQuestStates(states)
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

 guildRefreshSession = 0
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

 function resolveGuildQuestZone(description)
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

 function isGuildMiningQuest(state)
    if not state or state.Done then return false end
    local lower = state.Lower
    local hasMiningTarget = string.find(lower, "rock", 1, true)
        or string.find(lower, "ore", 1, true)
        or string.find(lower, "mineral", 1, true)
    local hasMiningVerb = string.find(lower, "break", 1, true)
        or string.find(lower, "mine", 1, true)
    return hasMiningTarget ~= nil and hasMiningVerb ~= nil
end

 function normalizeQuestDescription(value)
    value = stripRichText(value)
    value = value:gsub("✔", "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return string.lower(value)
end

 function findGuildQuestByDescription(states, description, slot)
    local wanted = normalizeQuestDescription(description)
    for _, state in ipairs(states) do
        if state.Slot == slot
            and normalizeQuestDescription(state.Description) == wanted then
            return state
        end
    end
    return nil
end

 function getGuildCollectQuestState(states)
    for _, state in ipairs(states or getGuildQuestStates()) do
        if not state.Done and string.find(state.Lower, "collect your plot coins", 1, true) then
            return state
        end
    end
    return nil
end

 function getGuildUpgradeQuestState(states)
    for _, state in ipairs(states or getGuildQuestStates()) do
        if not state.Done and string.find(state.Lower, "upgrad", 1, true) then
            return state
        end
    end
    return nil
end

 function getGuildUpgradeAmount(state)
    local current, total = tostring(state.Progress or ""):match("(%d+)%s*/%s*(%d+)")
    if total then
        return math.max(1, tonumber(total) - tonumber(current))
    end

    local amount = state.Description:match("[Uu]pgrad%w*%s+(%d+)")
        or state.Description:match("(%d+)%s+[Uu]pgrad")
    return amount and math.max(1, tonumber(amount)) or nil
end

 function updateGuildQuestButton(message)
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

 function resetMiningAfterGuildTrip()
    currentRock = nil
    trackedRock = nil
    trackedRockStartHP = nil
    trackedRockStartTime = 0
    nextTeleportAt = 0
    nextRockAt = 0
    lastRescan = 0
end

 function completeGuildCollectQuest(mySession, quest)
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

 function completeGuildUpgradeQuest(mySession, quest)
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

 function completeGuildMiningQuest(mySession, quest, zoneName, displayName)
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

 function getGuildResetSeconds()
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

 function isGuildPlaytimeQuest(state)
    return state and string.find(state.Lower, "play for", 1, true) ~= nil
end

 function guildQuestWorker(mySession)
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

 function stopGuildQuestAutomation()
    AUTO_GUILD_QUESTS = false
    GUILD_QUEST_SESSION += 1
    updateGuildQuestButton()
    queueSave()
end

 function startGuildQuestAutomation()
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

 function bossWorker(mySession)
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

 function startBoss()
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

 function findRock(zoneName)
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

 function rescanZone(zoneName)
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

 function miningCycle(mySession)
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

 function miningWorker(mySession)
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

 function visitGuildPlot()
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
    local targetSize

    if settingsPageOpen or guildStatusPageOpen then
        minerWindow.Visible = settingsPageOpen
        guildWindow.Visible = guildStatusPageOpen
        targetSize = UDim2.fromOffset(290, 269)
    elseif guiMinimized then
        zoneToggle.Visible = false
        search.Visible = false
        scroll.Visible = false
        selectedLabel.Visible = false
        startButton.Visible = false
        bossButton.Visible = false
        stopButton.Visible = false
        if getgenv().SWS_HUB_UI_STATE.label then
            getgenv().SWS_HUB_UI_STATE.label.Visible = false
        end
        minimize.Text = "+"
        targetSize = UDim2.fromOffset(290, 35)
    else
        zoneToggle.Visible = true
        selectedLabel.Visible = true
        startButton.Visible = true
        bossButton.Visible = true
        stopButton.Visible = true
        if getgenv().SWS_HUB_UI_STATE.label then
            getgenv().SWS_HUB_UI_STATE.label.Visible = true
        end
        minimize.Text = "-"

        if selectorExpanded then
            targetSize = UDim2.fromOffset(290, 269)
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
            targetSize = UDim2.fromOffset(290, 147)
            zoneToggle.Text = "ZONES ▲"
            search.Visible = false
            scroll.Visible = false
            selectedLabel.Position = UDim2.fromOffset(10, 63)
            startButton.Position = UDim2.fromOffset(10, 87)
            bossButton.Position = UDim2.fromOffset(102, 87)
            stopButton.Position = UDim2.fromOffset(194, 87)
        end
    end

    local anim = getgenv().SWS_HUB_ANIM
    if anim.layout then
        anim.layout:Cancel()
        anim.layout = nil
    end

    if animate then
        anim.layout = TweenService:Create(main, TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = targetSize
        })
        anim.layout:Play()
    else
        main.Size = targetSize
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
    local anim = getgenv().SWS_HUB_ANIM
    if anim.unloading then return end
    anim.unloading = true

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
    GUILD_MINE_ACTIVE = false
    GUILD_QUEST_SESSION += 1

    if anim.layout then
        anim.layout:Cancel()
        anim.layout = nil
    end

    for _, object in ipairs(gui:GetDescendants()) do
        if object:IsA("GuiObject") then
            local properties = {BackgroundTransparency = 1}
            if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                properties.TextTransparency = 1
                properties.TextStrokeTransparency = 1
            elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
                properties.ImageTransparency = 1
            end
            TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), properties):Play()
        elseif object:IsA("UIStroke") then
            TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
        end
    end

    TweenService:Create(main, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(290, 18),
        Position = main.Position + UDim2.fromOffset(0, 10)
    }):Play()

    task.wait(0.34)
    local state = getgenv().SWS_HUB_UI_STATE
    if state.label then
        state.label:Destroy()
        state.label = nil
    end
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

task.spawn(function()
    while not UNLOADED and gui.Parent do
        task.wait(30)
        if UNLOADED or not gui.Parent then break end
        local authKey = _G.SWS_HUB_AUTH_KEY
        local authRequest = request or http_request or (syn and syn.request)
        local hardwareId
        if type(get_hwid) == "function" then
            local ok, value = pcall(get_hwid)
            if ok and value then hardwareId = tostring(value) end
        elseif type(gethwid) == "function" then
            local ok, value = pcall(gethwid)
            if ok and value then hardwareId = tostring(value) end
        end
        local checkOK, response = pcall(function()
            if not authRequest or not hardwareId or not authKey then error("AUTH SUPPORT MISSING") end
            return authRequest({
                Url = "https://sws-key-system.swshub.workers.dev/verify",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ key = authKey, hwid = hardwareId })
            })
        end)
        if checkOK and type(response) == "table" then
            local body = response.Body or response.body
            local decodeOK, decoded = pcall(function() return HttpService:JSONDecode(body) end)
            if decodeOK and type(decoded) == "table" and decoded.valid == false then
                local environment = getgenv and getgenv()
                if environment then environment.SWS_HUB_KEY_CACHE = nil end
                if type(delfile) == "function" then
                    pcall(delfile, "SWS_HUB_KEY_" .. tostring(Player.UserId) .. ".json")
                end
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
                GUILD_MINE_ACTIVE = false
                GUILD_QUEST_SESSION += 1
                UNLOADED = true
                local state = getgenv().SWS_HUB_UI_STATE
                if state.label then
                    state.label:Destroy()
                    state.label = nil
                end
                gui:Destroy()
                break
            end
        end
    end
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
