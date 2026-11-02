--// GLACIER AUTO MINER V10.1
--// Real Executor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local RocksFolder = workspace
    :WaitForChild("Zones")
    :WaitForChild("Glacier")
    :WaitForChild("Rocks")

local MineRemote = ReplicatedStorage
    :WaitForChild("Shared")
    :WaitForChild("Remotes")
    :WaitForChild("MineRock")

-- SETTINGS
local MINING_DELAY = 0.4
local SCAN_DELAY = 0.15

-- STATE
local RUNNING = false
local UNLOADED = false
local SESSION = 0
local currentRock = nil
local minimized = false

-- REMOVE OLD GUI
local old = PlayerGui:FindFirstChild("GlacierMinerV101")
if old then
    old:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "GlacierMinerV101"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(250, 150)
main.Position = UDim2.new(0.5, -125, 0.5, -75)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = object
end

addCorner(main)

-- TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -75, 0, 30)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.Text = "Glacier Auto Miner V10.1"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
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
status.Size = UDim2.new(1, -20, 0, 30)
status.Position = UDim2.fromOffset(10, 40)
status.BackgroundTransparency = 1
status.Text = "Status: Stopped"
status.TextColor3 = Color3.fromRGB(220, 220, 220)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.Parent = main

-- BUTTON CREATOR
local function makeButton(text, x, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(105, 35)
    button.Position = UDim2.fromOffset(x, 85)
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BackgroundColor3 = color
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Parent = main
    addCorner(button)
    return button
end

local startButton = makeButton(
    "START",
    10,
    Color3.fromRGB(40, 145, 75)
)

local stopButton = makeButton(
    "STOP",
    135,
    Color3.fromRGB(160, 55, 55)
)

-- ROCK VALIDATION
local function validRock(rock)
    if not rock then return false end
    if not rock:IsA("Model") then return false end
    if rock.Parent ~= RocksFolder then return false end
    if rock:GetAttribute("ZoneId") ~= "Glacier" then return false end

    local hp = rock:GetAttribute("HP")

    return typeof(hp) == "number" and hp > 0
end

-- FIND LOWEST HP ROCK
local function findRock()
    local selected = nil
    local lowestHP = math.huge

    for _, rock in ipairs(RocksFolder:GetChildren()) do
        if validRock(rock) then
            local hp = rock:GetAttribute("HP")

            if hp < lowestHP then
                lowestHP = hp
                selected = rock
            end
        end
    end

    return selected
end

-- CHARACTER
local function getRoot()
    local character = Player.Character
    if not character then return nil end

    return character:FindFirstChild("HumanoidRootPart")
end

-- MINING WORKER
local function miningWorker(mySession)
    while RUNNING and not UNLOADED and SESSION == mySession do

        if not validRock(currentRock) then
            currentRock = findRock()
        end

        if not currentRock then
            status.Text = "Waiting for rocks..."
            task.wait(SCAN_DELAY)
            continue
        end

        local rock = currentRock
        local root = getRoot()

        local part = rock.PrimaryPart
            or rock:FindFirstChildWhichIsA("BasePart", true)

        if not root or not part then
            currentRock = nil
            task.wait(SCAN_DELAY)
            continue
        end

        -- MOVE CLOSE TO ROCK
        root.CFrame = part.CFrame * CFrame.new(0, 0, 3)

        task.wait(0.15)

        if not RUNNING or SESSION ~= mySession then
            break
        end

        if validRock(rock) then
            local oldHP = rock:GetAttribute("HP")

            local success = pcall(function()
                MineRemote:FireServer(rock)
            end)

            if not success then
                status.Text = "Remote error"
                task.wait(0.5)
            else
                task.wait(MINING_DELAY)

                if not validRock(rock) then
                    currentRock = nil
                    status.Text = "Rock destroyed - rescanning"

                else
                    local newHP = rock:GetAttribute("HP")

                    if typeof(newHP) == "number" and newHP < oldHP then
                        status.Text = "Mining | HP: " .. newHP
                    else
                        status.Text = "Waiting for damage..."
                    end
                end
            end
        else
            currentRock = nil
        end

        task.wait(0.05)
    end
end

-- START
startButton.MouseButton1Click:Connect(function()
    if UNLOADED or RUNNING then return end

    SESSION += 1
    RUNNING = true
    currentRock = nil

    status.Text = "Starting..."

    local mySession = SESSION
    task.spawn(miningWorker, mySession)
end)

-- STOP
stopButton.MouseButton1Click:Connect(function()
    RUNNING = false
    SESSION += 1
    currentRock = nil

    status.Text = "Stopped"
end)

-- MINIMIZE / RESTORE
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized

    if minimized then
        main.Size = UDim2.fromOffset(250, 35)

        status.Visible = false
        startButton.Visible = false
        stopButton.Visible = false

        minimize.Text = "+"
    else
        main.Size = UDim2.fromOffset(250, 150)

        status.Visible = true
        startButton.Visible = true
        stopButton.Visible = true

        minimize.Text = "-"
    end
end)

-- UNLOAD
close.MouseButton1Click:Connect(function()
    UNLOADED = true
    RUNNING = false
    SESSION += 1

    gui:Destroy()
end)

print("Glacier Auto Miner V10.1 loaded successfully!")
