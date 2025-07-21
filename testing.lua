-- SERVICES
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    Workspace = game:GetService("Workspace"),
    VirtualUser = game:GetService("VirtualUser")
}

-- PLAYER & CHARACTER REFERENCES
local PlayerData = {
    player = Services.Players.LocalPlayer,
    character = nil,
    humanoid = nil,
    hrp = nil,
    profile = nil,
    inventory = nil
}

-- Initialize player data
PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
PlayerData.humanoid = PlayerData.character:WaitForChild("Humanoid")
PlayerData.hrp = PlayerData.character:WaitForChild("HumanoidRootPart")
PlayerData.profile = Services.ReplicatedStorage:WaitForChild("Profiles"):WaitForChild(PlayerData.player.Name)
PlayerData.inventory = PlayerData.profile:WaitForChild("Inventory")

-- GAME FOLDERS & REFERENCES
local GameFolders = {
    mobsFolder = Services.Workspace:WaitForChild("Mobs"),
    waystones = Services.Workspace:WaitForChild("Waystones", 9e9),
    stations = Services.Workspace:WaitForChild("CraftingStations", 9e9)
}

-- CRAFTING STATIONS
local CraftingStations = {
    enchanting = GameFolders.stations:WaitForChild("Enchanting", 9e9),
    mounts = GameFolders.stations:WaitForChild("Mounts", 9e9),
    smithing = GameFolders.stations:WaitForChild("Smithing", 9e9)
}

-- REMOTE EVENTS & FUNCTIONS
local Remotes = {
    -- Crafting
    dismantle = Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Crafting"):WaitForChild("Dismantle"),
    chest = Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Chests"):WaitForChild("ClaimItem"),
    
    -- Combat
    playerAttack = Services.ReplicatedStorage.Systems.Combat.PlayerAttack,
    skillAttack = Services.ReplicatedStorage.Systems.Combat:WaitForChild("PlayerSkillAttack"),
    
    -- Skills
    useSkill = Services.ReplicatedStorage.Systems.Skills:WaitForChild("UseSkill"),
    
    -- Effects
    doEffect = Services.ReplicatedStorage.Systems.Effects.DoEffect,
    
    -- Teleportation
    teleportWaystone = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Locations", 9e9):WaitForChild("TeleportWaystone", 9e9),
    teleportFloor = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Teleport", 9e9):WaitForChild("Teleport", 9e9),
    voidTower = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("TowerDungeon", 9e9):WaitForChild("StartDungeon", 9e9)
}

-- QUEST SYSTEM REMOTES
local QuestRemotes = {
    folder = Services.ReplicatedStorage:WaitForChild("Systems"):FindFirstChild("WeeklyQuests") or Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DailyQuests"),
    claimQuest = nil,
    claimReward = nil,
    update = nil
}

-- Initialize quest remotes
QuestRemotes.claimQuest = QuestRemotes.folder:WaitForChild("ClaimIndividualDailyQuest")
QuestRemotes.claimReward = QuestRemotes.folder:WaitForChild("ClaimDailyQuestReward")
QuestRemotes.update = QuestRemotes.folder:WaitForChild("Update")

-- ACHIEVEMENT REMOTE
local achievementRemote = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Achievements", 9e9):WaitForChild("ClaimAchievementReward", 9e9)

-- MODULES
local Modules = {
    antiCheat = require(Services.ReplicatedStorage.Systems.AntiCheat),
    questList = require(Services.ReplicatedStorage.Systems.Quests.QuestList),
    drops = require(Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Drops")),
    skillSystem = require(Services.ReplicatedStorage.Systems.Skills),
    items = require(Services.ReplicatedStorage.Systems.Items)
}

-- CONFIGURATION & CONSTANTS
local CONFIG = {
    HEIGHT_OFFSET = 20,
    FOLLOW_DISTANCE = 3,
    BASE_SPEED = 40,
    SPEED_CAP = 90,
    DISTANCE_THRESHOLD = 200,
    KILL_AURA_RANGE = 100,
    KILL_AURA_DELAY = 0.26,
    AUTO_COLLECT_ENABLED = true,
    COLLECT_RADIUS = 50,
    CHECK_INTERVAL = 0.3,
    SKILL_SLOT = 1,
    FALLBACK_COOLDOWN = 2,
    QUEST_CHECK_INTERVAL = 1,
    TRIGGER_DISTANCE = 500,
    AUTO_CLAIM_ENABLED = true,
    TELEPORT_DELAY = 2,
}

-- ANTI-AFK SYSTEM
local AntiAfkSystem = {
    -- Passive Anti-AFK
    setup = function()
        PlayerData.player.Idled:Connect(function()
            Services.VirtualUser:Button2Down(Vector2.new(0, 0), Services.Workspace.CurrentCamera.CFrame)
    task.wait(1)
            Services.VirtualUser:Button2Up(Vector2.new(0, 0), Services.Workspace.CurrentCamera.CFrame)
end)
    end,

    -- Notification UI
    createNotification = function()
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiAFKNotification"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = PlayerData.player:WaitForChild("PlayerGui")

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 240, 0, 36)
        frame.Position = UDim2.new(0.5, -120, 0.08, 0)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        frame.Parent = screenGui

        local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 10)

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "Anti-AFK is now active"
label.Font = Enum.Font.GothamMedium
label.TextColor3 = Color3.fromRGB(200, 255, 200)
label.TextSize = 17
label.TextStrokeTransparency = 0.8
        label.Parent = frame

-- Fade out and destroy after 4 seconds
task.delay(4, function()
    for i = 1, 20 do
                frame.BackgroundTransparency += 0.04
        label.TextTransparency += 0.05
        task.wait(0.03)
    end
    screenGui:Destroy()
end)
    end
}

-- Initialize Anti-AFK
AntiAfkSystem.setup()
AntiAfkSystem.createNotification()

-- RUNTIME STATE & VARIABLES
local RuntimeState = {
    -- Automation toggles
    stopFollowing = true,
    killAuraEnabled = false,
    autoCollectEnabled = true,
    autoSkillEnabled = false,
    autoClaimEnabled = true,
    autoDismantleEnabled = false,
    autoDailyQuestsEnabled = false,
    autoAchievementEnabled = false,
    
    -- UI toggles
    openEnchantUIManualEnabled = false,
    openMountsUIManualEnabled = false,
    openSmithingUIManualEnabled = false,
    
    -- FPS Boost
    fpsBoostEnabled = false,
    maxFpsBoostEnabled = false,
    
    -- Selection variables
    selectedMobName = "Razor Boar",
    selectedQuestId = nil,
    selectedRarity = "Uncommon",
    
    -- Movement/physics
    bodyVelocity = nil,
    tween = nil,
    lastVelocity = Vector3.zero,
    
    -- Quest system
    global_isEnabled_autoquest = false,
    
    -- Caches and tracking
    dropCache = {},
    lastUsed = {},
    claimedQuest = {},
    claimedReward = {}
}

-- CONFIG SAVE/LOAD SYSTEM
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "seisenhub.json"

local function saveConfig()
    local config = {
        stopFollowing = RuntimeState.stopFollowing,
        killAuraEnabled = RuntimeState.killAuraEnabled,
        autoCollectEnabled = RuntimeState.autoCollectEnabled,
        autoSkillEnabled = RuntimeState.autoSkillEnabled,
        autoClaimEnabled = RuntimeState.autoClaimEnabled,
        autoDismantleEnabled = RuntimeState.autoDismantleEnabled,
        autoDailyQuestsEnabled = RuntimeState.autoDailyQuestsEnabled,
        autoAchievementEnabled = RuntimeState.autoAchievementEnabled,
        openEnchantUIManualEnabled = RuntimeState.openEnchantUIManualEnabled,
        openMountsUIManualEnabled = RuntimeState.openMountsUIManualEnabled,
        openSmithingUIManualEnabled = RuntimeState.openSmithingUIManualEnabled,
        fpsBoostEnabled = RuntimeState.fpsBoostEnabled,
        maxFpsBoostEnabled = RuntimeState.maxFpsBoostEnabled,
        selectedMobName = RuntimeState.selectedMobName,
        selectedQuestId = RuntimeState.selectedQuestId,
        selectedRarity = RuntimeState.selectedRarity,
        global_isEnabled_autoquest = RuntimeState.global_isEnabled_autoquest,
    }
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end)
end

local function loadConfig()
    if not (isfile and isfile(CONFIG_FILE)) then return end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if success and type(data) == "table" then
        for k, v in pairs(data) do
            if RuntimeState[k] ~= nil then
                RuntimeState[k] = v
            end
        end
    end
end

loadConfig()

-- RARITY SYSTEM
local RaritySystem = {
    map = {
    ["Common"] = 1,
    ["Uncommon"] = 2,
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5
    },
    list = { "Common", "Uncommon", "Rare", "Epic", "Legendary" },
    currentIndex = 2
}

-- Fix: Define QuestSystem before using it
local QuestSystem = {
    toMobMap = {}
}

-- Initialize quest mapping
for id, data in pairs(Modules.questList) do
    if data.Type == "Kill" and data.Target then
        QuestSystem.toMobMap[id] = data.Target
    end
end

-- DROP CACHE INITIALIZATION
local function initializeDropCache()
local success, drops = pcall(function()
        return getupvalue(Modules.drops.SpawnDropModel, 7)
end)
    
if success and type(drops) == "table" then
        RuntimeState.dropCache = drops
        return true
    else
        warn("⚠️ Failed to access drop cache. Auto collect disabled.")
        RuntimeState.autoCollectEnabled = false
        return false
    end
end

-- Initialize drop cache
initializeDropCache()

-- Function to simulate triggering ProximityPrompt
local function triggerPrompt(prompt)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.35)
        prompt:Trigger()
        task.wait(0.2)
        prompt:InputHoldEnd()
    end)
end

-- Unlock all waystones using ProximityPrompt (no movement)
local function unlockAllWaystones()
    local unlocked = {}

    for _, stone in ipairs(GameFolders.waystones:GetChildren()) do
        if stone:IsA("Model") and tonumber(stone.Name) and not unlocked[stone.Name] then
            -- Teleport to the waystone
            Remotes.teleportWaystone:FireServer(stone)
            task.wait(CONFIG.TELEPORT_DELAY)

            local main = stone:FindFirstChild("Main")
            if main then
                local prompt = main:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    triggerPrompt(prompt)
                    unlocked[stone.Name] = true
                end
            end

            task.wait(1.2)
        end
    end
end


-- Calculate scale factor based on screen size
local screenSize = Services.Workspace.CurrentCamera.ViewportSize
local scaleFactor = math.min(screenSize.X, screenSize.Y) / 1080
scaleFactor = math.clamp(scaleFactor, 1.0, 1.0) -- Increased for Android visibility

-- Main UI
local mainScreenGui = Instance.new("ScreenGui")
mainScreenGui.Name = "MobFollowerKillAuraUI"
mainScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainScreenGui.IgnoreGuiInset = true
mainScreenGui.ResetOnSpawn = false
mainScreenGui.Parent = game:GetService("CoreGui")

-- Create main frame with scaled size
local frame = Instance.new("Frame", mainScreenGui)
frame.Size = UDim2.new(0, 600 * scaleFactor, 0, 1000 * scaleFactor)
frame.Position = UDim2.new(0.02, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.ZIndex = 100
local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 8 * scaleFactor)

-- Apply UIScale for dynamic resizing
local uiScale = Instance.new("UIScale", frame)
uiScale.Scale = scaleFactor

-- Add UIScale to all dropdown frames for proper scaling
local dropdownFrames = {questDropdownFrame, dropdownFrame, dismantleDropdownFrame, waystoneDropdownFrame, floorTeleportDropdownFrame}
for _, dropFrame in ipairs(dropdownFrames) do
    local dropScale = Instance.new("UIScale", dropFrame)
    dropScale.Scale = scaleFactor
end

-- Drag Handle
local dragHandle = Instance.new("Frame", frame)
dragHandle.Size = UDim2.new(1, 0, 0.06 * scaleFactor, 0)
dragHandle.Position = UDim2.new(0, 0, 0, 0)
dragHandle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
dragHandle.BackgroundTransparency = 0.3
dragHandle.BorderSizePixel = 0
dragHandle.ZIndex = 10
local dragHandleCorner = Instance.new("UICorner", dragHandle)
dragHandleCorner.CornerRadius = UDim.new(0, 8 * scaleFactor)

-- Title
local titleLabel = Instance.new("TextLabel", dragHandle)
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "Swordburst 3 by Seisen"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15 * scaleFactor
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.ZIndex = 11

-- UI Size Management System
local UISizeManager = {
    currentSizeIndex = 1, -- Always start at default, user can change with button
    sizes = {
        {width = 600, height = 600, scale = 1.0, name = "Large"},
        {width = 540, height = 500, scale = 0.9, name = "Medium"},
        {width = 480, height = 400, scale = 0.8, name = "Small"},
        {width = 420, height = 350, scale = 0.7, name = "Android"}
    }
}

-- Create UI Size Toggle Button
local sizeToggleButton = Instance.new("TextButton", dragHandle)
sizeToggleButton.Size = UDim2.new(0.08 * scaleFactor, 0, 0.7 * scaleFactor, 0)
sizeToggleButton.AnchorPoint = Vector2.new(1, 0.5)
sizeToggleButton.Position = UDim2.new(0.98, 0, 0.5, 0)
sizeToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sizeToggleButton.TextColor3 = Color3.new(1, 1, 1)
sizeToggleButton.Font = Enum.Font.GothamBold
sizeToggleButton.TextSize = 13 * scaleFactor
sizeToggleButton.Text = string.sub(UISizeManager.sizes[UISizeManager.currentSizeIndex].name, 1, 1)
sizeToggleButton.BorderSizePixel = 0
sizeToggleButton.ZIndex = 25
local sizeButtonCorner = Instance.new("UICorner", sizeToggleButton)
sizeButtonCorner.CornerRadius = UDim.new(0, 4 * scaleFactor)

-- Auto Farm Checkbox
local followLabel = Instance.new("TextLabel", frame)
followLabel.Size = UDim2.new(0, 16 * scaleFactor, 0, 16 * scaleFactor)
followLabel.Position = UDim2.new(0.05, 0, 0.11, 0)
followLabel.Text = "Auto Farm: OFF"
followLabel.TextColor3 = Color3.new(1, 1, 1)
followLabel.BackgroundTransparency = 1
followLabel.Font = Enum.Font.GothamBold
followLabel.TextSize = 14 * scaleFactor
followLabel.TextXAlignment = Enum.TextXAlignment.Left
followLabel.ZIndex = 11

local followCheckbox = Instance.new("TextButton", frame)
followCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
followCheckbox.Position = UDim2.new(0.9, 0, 0.11, 0)
followCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
followCheckbox.Text = ""
followCheckbox.AutoButtonColor = false
followCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", followCheckbox).AspectRatio = 1
Instance.new("UICorner", followCheckbox).CornerRadius = UDim.new(1, 0)

-- Kill Aura Checkbox
local killAuraLabel = Instance.new("TextLabel", frame)
killAuraLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
killAuraLabel.Position = UDim2.new(0.05, 0, 0.19, 0)
killAuraLabel.Text = "Kill Aura: OFF"
killAuraLabel.TextColor3 = Color3.new(1, 1, 1)
killAuraLabel.BackgroundTransparency = 1
killAuraLabel.Font = Enum.Font.GothamBold
killAuraLabel.TextSize = 14 * scaleFactor
killAuraLabel.TextXAlignment = Enum.TextXAlignment.Left
killAuraLabel.ZIndex = 11

local killAuraCheckbox = Instance.new("TextButton", frame)
killAuraCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
killAuraCheckbox.Position = UDim2.new(0.9, 0, 0.19, 0)
killAuraCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
killAuraCheckbox.Text = ""
killAuraCheckbox.AutoButtonColor = false
killAuraCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", killAuraCheckbox).AspectRatio = 1
Instance.new("UICorner", killAuraCheckbox).CornerRadius = UDim.new(1, 0)

-- Auto Quest Checkbox
local autoQuestLabel = Instance.new("TextLabel", frame)
autoQuestLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
autoQuestLabel.Position = UDim2.new(0.05, 0, 0.27, 0)
autoQuestLabel.Text = "Auto Quest: OFF (Pick quest below)"
autoQuestLabel.TextColor3 = Color3.new(1, 1, 1)
autoQuestLabel.BackgroundTransparency = 1
autoQuestLabel.Font = Enum.Font.GothamBold
autoQuestLabel.TextSize = 14 * scaleFactor
autoQuestLabel.TextXAlignment = Enum.TextXAlignment.Left
autoQuestLabel.ZIndex = 11

local autoQuestCheckbox = Instance.new("TextButton", frame)
autoQuestCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
autoQuestCheckbox.Position = UDim2.new(0.9, 0, 0.27, 0)
autoQuestCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoQuestCheckbox.Text = ""
autoQuestCheckbox.AutoButtonColor = false
autoQuestCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", autoQuestCheckbox).AspectRatio = 1
Instance.new("UICorner", autoQuestCheckbox).CornerRadius = UDim.new(1, 0)

-- Auto Collect Checkbox
local autoCollectLabel = Instance.new("TextLabel", frame)
autoCollectLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
autoCollectLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
autoCollectLabel.Text = "Auto Collect: ON"
autoCollectLabel.TextColor3 = Color3.new(1, 1, 1)
autoCollectLabel.BackgroundTransparency = 1
autoCollectLabel.Font = Enum.Font.GothamBold
autoCollectLabel.TextSize = 14 * scaleFactor
autoCollectLabel.TextXAlignment = Enum.TextXAlignment.Left
autoCollectLabel.ZIndex = 11

local autoCollectCheckbox = Instance.new("TextButton", frame)
autoCollectCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
autoCollectCheckbox.Position = UDim2.new(0.9, 0, 0.35, 0)
autoCollectCheckbox.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
autoCollectCheckbox.Text = ""
autoCollectCheckbox.AutoButtonColor = false
autoCollectCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", autoCollectCheckbox).AspectRatio = 1
Instance.new("UICorner", autoCollectCheckbox).CornerRadius = UDim.new(1, 0)

-- Auto Skill Checkbox
local autoSkillLabel = Instance.new("TextLabel", frame)
autoSkillLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
autoSkillLabel.Position = UDim2.new(0.05, 0, 0.43, 0)
autoSkillLabel.Text = "Auto Skill: OFF"
autoSkillLabel.TextColor3 = Color3.new(1, 1, 1)
autoSkillLabel.BackgroundTransparency = 1
autoSkillLabel.Font = Enum.Font.GothamBold
autoSkillLabel.TextSize = 14 * scaleFactor
autoSkillLabel.TextXAlignment = Enum.TextXAlignment.Left
autoSkillLabel.ZIndex = 11

local autoSkillCheckbox = Instance.new("TextButton", frame)
autoSkillCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
autoSkillCheckbox.Position = UDim2.new(0.9, 0, 0.43, 0)
autoSkillCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoSkillCheckbox.Text = ""
autoSkillCheckbox.AutoButtonColor = false
autoSkillCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", autoSkillCheckbox).AspectRatio = 1
Instance.new("UICorner", autoSkillCheckbox).CornerRadius = UDim.new(1, 0)

-- Auto Claim Checkbox
local autoClaimLabel = Instance.new("TextLabel", frame)
autoClaimLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
autoClaimLabel.Position = UDim2.new(0.05, 0, 0.51, 0)
autoClaimLabel.Text = "Auto Claim Chest: ON (Click 'Take')"
autoClaimLabel.TextColor3 = Color3.new(1, 1, 1)
autoClaimLabel.BackgroundTransparency = 1
autoClaimLabel.Font = Enum.Font.GothamBold
autoClaimLabel.TextSize = 14 * scaleFactor
autoClaimLabel.TextXAlignment = Enum.TextXAlignment.Left
autoClaimLabel.ZIndex = 11

local autoClaimCheckbox = Instance.new("TextButton", frame)
autoClaimCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
autoClaimCheckbox.Position = UDim2.new(0.9, 0, 0.51, 0)
autoClaimCheckbox.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
autoClaimCheckbox.Text = ""
autoClaimCheckbox.AutoButtonColor = false
autoClaimCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", autoClaimCheckbox).AspectRatio = 1
Instance.new("UICorner", autoClaimCheckbox).CornerRadius = UDim.new(1, 0)

-- Auto Daily Quests Checkbox
local autoDailyQuestsLabel = Instance.new("TextLabel", frame)
autoDailyQuestsLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
autoDailyQuestsLabel.Position = UDim2.new(0.05, 0, 0.59, 0)
autoDailyQuestsLabel.Text = "Auto Claim Daily Quests: OFF"
autoDailyQuestsLabel.TextColor3 = Color3.new(1, 1, 1)
autoDailyQuestsLabel.BackgroundTransparency = 1
autoDailyQuestsLabel.Font = Enum.Font.GothamBold
autoDailyQuestsLabel.TextSize = 14 * scaleFactor
autoDailyQuestsLabel.TextXAlignment = Enum.TextXAlignment.Left
autoDailyQuestsLabel.ZIndex = 11

local autoDailyQuestsCheckbox = Instance.new("TextButton", frame)
autoDailyQuestsCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
autoDailyQuestsCheckbox.Position = UDim2.new(0.9, 0, 0.59, 0)
autoDailyQuestsCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoDailyQuestsCheckbox.Text = ""
autoDailyQuestsCheckbox.AutoButtonColor = false
autoDailyQuestsCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", autoDailyQuestsCheckbox).AspectRatio = 1
Instance.new("UICorner", autoDailyQuestsCheckbox).CornerRadius = UDim.new(1, 0)

-- Auto Achievement Checkbox
local autoAchievementLabel = Instance.new("TextLabel", frame)
autoAchievementLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
autoAchievementLabel.Position = UDim2.new(0.05, 0, 0.67, 0)
autoAchievementLabel.Text = "Auto Claim Achievement: OFF"
autoAchievementLabel.TextColor3 = Color3.new(1, 1, 1)
autoAchievementLabel.BackgroundTransparency = 1
autoAchievementLabel.Font = Enum.Font.GothamBold
autoAchievementLabel.TextSize = 14 * scaleFactor
autoAchievementLabel.TextXAlignment = Enum.TextXAlignment.Left
autoAchievementLabel.ZIndex = 11

local autoAchievementCheckbox = Instance.new("TextButton", frame)
autoAchievementCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
autoAchievementCheckbox.Position = UDim2.new(0.9, 0, 0.67, 0)
autoAchievementCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoAchievementCheckbox.Text = ""
autoAchievementCheckbox.AutoButtonColor = false
autoAchievementCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", autoAchievementCheckbox).AspectRatio = 1
Instance.new("UICorner", autoAchievementCheckbox).CornerRadius = UDim.new(1, 0)

-- Dropdown Title
local dropdownTitleLabel = Instance.new("TextLabel", frame)
dropdownTitleLabel.Size = UDim2.new(1, 0, 0.05 * scaleFactor, 0)
dropdownTitleLabel.Position = UDim2.new(0, 0, 0.75 , 0)
dropdownTitleLabel.Text = "Select Quest and Mob"
dropdownTitleLabel.TextColor3 = Color3.new(1, 1, 1)
dropdownTitleLabel.BackgroundTransparency = 1
dropdownTitleLabel.Font = Enum.Font.GothamBold
dropdownTitleLabel.TextSize = 14 * scaleFactor
dropdownTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
dropdownTitleLabel.ZIndex = 11

-- Quest Dropdown
local questDropdown = Instance.new("TextButton", frame)
questDropdown.Size = UDim2.new(0.43 * scaleFactor, 0, 0.1 * scaleFactor, 0)
questDropdown.Position = UDim2.new(0.05, 0, 0.80, 0)
questDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
questDropdown.TextColor3 = Color3.new(1, 1, 1)
questDropdown.Font = Enum.Font.Gotham
questDropdown.TextSize = 14 * scaleFactor
questDropdown.Text = "Quest: (None)"
questDropdown.ZIndex = 14
local questDropdownCorner = Instance.new("UICorner", questDropdown)
questDropdownCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local questDropdownFrame = Instance.new("Frame", frame)
questDropdownFrame.Size = UDim2.new(0.43 * scaleFactor, 0, 0.4 * scaleFactor, 0)
questDropdownFrame.Position = UDim2.new(0.05, 0, 0.90, 0)
questDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
questDropdownFrame.BorderSizePixel = 0
questDropdownFrame.Visible = false
questDropdownFrame.ClipsDescendants = true
questDropdownFrame.ZIndex = 13
local questDropdownFrameCorner = Instance.new("UICorner", questDropdownFrame)
questDropdownFrameCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local questScroll = Instance.new("ScrollingFrame", questDropdownFrame)
questScroll.Size = UDim2.new(1, -10 * scaleFactor, 1, -10 * scaleFactor)
questScroll.Position = UDim2.new(0, 5 * scaleFactor, 0, 5 * scaleFactor)
questScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
questScroll.BackgroundTransparency = 1
questScroll.ScrollBarThickness = 4 * scaleFactor
questScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
questScroll.BorderSizePixel = 0
questScroll.ScrollingDirection = Enum.ScrollingDirection.Y
questScroll.ZIndex = 14

local questLayout = Instance.new("UIListLayout", questScroll)
questLayout.SortOrder = Enum.SortOrder.LayoutOrder
questLayout.Padding = UDim.new(0, 5 * scaleFactor)
questLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    questScroll.CanvasSize = UDim2.new(0, 0, 1.5, questLayout.AbsoluteContentSize.Y + 10 * scaleFactor)
end)

-- Mob Dropdown
local mobDropdown = Instance.new("TextButton", frame)
mobDropdown.Size = UDim2.new(0.43 * scaleFactor, 0, 0.1 * scaleFactor, 0)
mobDropdown.Position = UDim2.new(0.5, 0, 0.80, 0)
mobDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mobDropdown.TextColor3 = Color3.new(1, 1, 1)
mobDropdown.Font = Enum.Font.Gotham
mobDropdown.TextSize = 14 * scaleFactor
mobDropdown.Text = "Mob: Razor Boar"
mobDropdown.ZIndex = 14
local mobDropdownCorner = Instance.new("UICorner", mobDropdown)
mobDropdownCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local dropdownFrame = Instance.new("Frame", frame)
dropdownFrame.Size = UDim2.new(0.43 * scaleFactor, 0, 0.4 * scaleFactor, 0)
dropdownFrame.Position = UDim2.new(0.5, 0, 0.90, 0)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropdownFrame.BorderSizePixel = 0
dropdownFrame.Visible = false
dropdownFrame.ClipsDescendants = true
dropdownFrame.ZIndex = 13
local dropdownFrameCorner = Instance.new("UICorner", dropdownFrame)
dropdownFrameCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local scrollbar = Instance.new("ScrollingFrame", dropdownFrame)
scrollbar.Size = UDim2.new(1, -10 * scaleFactor, 1, -10 * scaleFactor)
scrollbar.Position = UDim2.new(0, 5 * scaleFactor, 0, 5 * scaleFactor)
scrollbar.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollbar.BackgroundTransparency = 1
scrollbar.ScrollBarThickness = 4 * scaleFactor
scrollbar.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollbar.BorderSizePixel = 0
scrollbar.ScrollingDirection = Enum.ScrollingDirection.Y
scrollbar.ZIndex = 14

local listLayout = Instance.new("UIListLayout", scrollbar)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5 * scaleFactor)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollbar.CanvasSize = UDim2.new(0, 0, 1.5, listLayout.AbsoluteContentSize.Y + 10 * scaleFactor)
end)

-- Auto Dismantle Checkbox
local autoDismantleLabel = Instance.new("TextLabel", frame)
autoDismantleLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
autoDismantleLabel.Position = UDim2.new(0.05, 0, 0.11, 0)
autoDismantleLabel.Text = "Auto Dismantle: OFF"
autoDismantleLabel.TextColor3 = Color3.new(1, 1, 1)
autoDismantleLabel.BackgroundTransparency = 1
autoDismantleLabel.Font = Enum.Font.GothamBold
autoDismantleLabel.TextSize = 14 * scaleFactor
autoDismantleLabel.TextXAlignment = Enum.TextXAlignment.Left
autoDismantleLabel.ZIndex = 11

local autoDismantleCheckbox = Instance.new("TextButton", frame)
autoDismantleCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
autoDismantleCheckbox.Position = UDim2.new(0.9, 0, 0.11, 0)
autoDismantleCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoDismantleCheckbox.Text = ""
autoDismantleCheckbox.AutoButtonColor = false
autoDismantleCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", autoDismantleCheckbox).AspectRatio = 1
Instance.new("UICorner", autoDismantleCheckbox).CornerRadius = UDim.new(1, 0)

-- Auto Dismantle Dropdown
local dismantleDropdown = Instance.new("TextButton", frame)
dismantleDropdown.Size = UDim2.new(0.9 * scaleFactor, 0, 0.1 * scaleFactor, 0)
dismantleDropdown.Position = UDim2.new(0.05, 0, 0.17, 0)
dismantleDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dismantleDropdown.TextColor3 = Color3.new(1, 1, 1)
dismantleDropdown.Font = Enum.Font.Gotham
dismantleDropdown.TextSize = 14 * scaleFactor
dismantleDropdown.Text = "Rarity: Uncommon and below"
dismantleDropdown.ZIndex = 12
local dismantleDropdownCorner = Instance.new("UICorner", dismantleDropdown)
dismantleDropdownCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local dismantleDropdownFrame = Instance.new("Frame", frame)
dismantleDropdownFrame.Position = UDim2.new(0.05, 0, 0.26, 0)
dismantleDropdownFrame.Size = UDim2.new(0.9 * scaleFactor, 0, 0.2 * scaleFactor, 0)
dismantleDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dismantleDropdownFrame.BorderSizePixel = 0
dismantleDropdownFrame.Visible = false
dismantleDropdownFrame.ClipsDescendants = true
dismantleDropdownFrame.ZIndex = 13
local dismantleDropdownFrameCorner = Instance.new("UICorner", dismantleDropdownFrame)
dismantleDropdownFrameCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local dismantleScroll = Instance.new("ScrollingFrame", dismantleDropdownFrame)
dismantleScroll.Size = UDim2.new(1, -10 * scaleFactor, 1, -10 * scaleFactor)
dismantleScroll.Position = UDim2.new(0, 5 * scaleFactor, 0, 5 * scaleFactor)
dismantleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
dismantleScroll.BackgroundTransparency = 1
dismantleScroll.ScrollBarThickness = 4 * scaleFactor
dismantleScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
dismantleScroll.BorderSizePixel = 0
dismantleScroll.ScrollingDirection = Enum.ScrollingDirection.Y
dismantleScroll.ZIndex = 14

local dismantleLayout = Instance.new("UIListLayout", dismantleScroll)
dismantleLayout.SortOrder = Enum.SortOrder.LayoutOrder
dismantleLayout.Padding = UDim.new(0, 5 * scaleFactor)
dismantleLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    dismantleScroll.CanvasSize = UDim2.new(0, 0, 0, dismantleLayout.AbsoluteContentSize.Y + 10 * scaleFactor)
end)

-- Open Enchant UI Checkbox
local openEnchantUIManualLabel = Instance.new("TextLabel", frame)
openEnchantUIManualLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
openEnchantUIManualLabel.Position = UDim2.new(0.05, 0, 0.27, 0)
openEnchantUIManualLabel.Text = "Open Enchant UI: OFF"
openEnchantUIManualLabel.TextColor3 = Color3.new(1, 1, 1)
openEnchantUIManualLabel.BackgroundTransparency = 1
openEnchantUIManualLabel.Font = Enum.Font.GothamBold
openEnchantUIManualLabel.TextSize = 14 * scaleFactor
openEnchantUIManualLabel.TextXAlignment = Enum.TextXAlignment.Left
openEnchantUIManualLabel.ZIndex = 11

local openEnchantUIManualCheckbox = Instance.new("TextButton", frame)
openEnchantUIManualCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
openEnchantUIManualCheckbox.Position = UDim2.new(0.9, 0, 0.27, 0)
openEnchantUIManualCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
openEnchantUIManualCheckbox.Text = ""
openEnchantUIManualCheckbox.AutoButtonColor = false
openEnchantUIManualCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", openEnchantUIManualCheckbox).AspectRatio = 1
Instance.new("UICorner", openEnchantUIManualCheckbox).CornerRadius = UDim.new(1, 0)

-- Open Mounts UI Checkbox
local openMountsUIManualLabel = Instance.new("TextLabel", frame)
openMountsUIManualLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
openMountsUIManualLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
openMountsUIManualLabel.Text = "Open Mounts UI: OFF"
openMountsUIManualLabel.TextColor3 = Color3.new(1, 1, 1)
openMountsUIManualLabel.BackgroundTransparency = 1
openMountsUIManualLabel.Font = Enum.Font.GothamBold
openMountsUIManualLabel.TextSize = 14 * scaleFactor
openMountsUIManualLabel.TextXAlignment = Enum.TextXAlignment.Left
openMountsUIManualLabel.ZIndex = 11

local openMountsUIManualCheckbox = Instance.new("TextButton", frame)
openMountsUIManualCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
openMountsUIManualCheckbox.Position = UDim2.new(0.9, 0, 0.35, 0)
openMountsUIManualCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
openMountsUIManualCheckbox.Text = ""
openMountsUIManualCheckbox.AutoButtonColor = false
openMountsUIManualCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", openMountsUIManualCheckbox).AspectRatio = 1
Instance.new("UICorner", openMountsUIManualCheckbox).CornerRadius = UDim.new(1, 0)

-- Open Smithing UI Checkbox
local openSmithingUIManualLabel = Instance.new("TextLabel", frame)
openSmithingUIManualLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
openSmithingUIManualLabel.Position = UDim2.new(0.05, 0, 0.43, 0)
openSmithingUIManualLabel.Text = "Open Smithing UI: OFF"
openSmithingUIManualLabel.TextColor3 = Color3.new(1, 1, 1)
openSmithingUIManualLabel.BackgroundTransparency = 1
openSmithingUIManualLabel.Font = Enum.Font.GothamBold
openSmithingUIManualLabel.TextSize = 14 * scaleFactor
openSmithingUIManualLabel.TextXAlignment = Enum.TextXAlignment.Left
openSmithingUIManualLabel.ZIndex = 11

local openSmithingUIManualCheckbox = Instance.new("TextButton", frame)
openSmithingUIManualCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
openSmithingUIManualCheckbox.Position = UDim2.new(0.9, 0, 0.43, 0)
openSmithingUIManualCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
openSmithingUIManualCheckbox.Text = ""
openSmithingUIManualCheckbox.AutoButtonColor = false
openSmithingUIManualCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", openSmithingUIManualCheckbox).AspectRatio = 1
Instance.new("UICorner", openSmithingUIManualCheckbox).CornerRadius = UDim.new(1, 0)

-- Unlock All Waystones Button
local unlockWaystonesButton = Instance.new("TextButton", frame)
unlockWaystonesButton.Size = UDim2.new(0.9 * scaleFactor, 0, 0.1 * scaleFactor, 0)
unlockWaystonesButton.Position = UDim2.new(0.05, 0, 0.50, 0)
unlockWaystonesButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
unlockWaystonesButton.TextColor3 = Color3.new(1, 1, 1)
unlockWaystonesButton.Font = Enum.Font.Gotham
unlockWaystonesButton.TextSize = 14 * scaleFactor
unlockWaystonesButton.Text = "Unlock All Waystones"
unlockWaystonesButton.ZIndex = 12
local unlockWaystonesButtonCorner = Instance.new("UICorner", unlockWaystonesButton)
unlockWaystonesButtonCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

-- Waystone Dropdown
local waystoneDropdown = Instance.new("TextButton", frame)
waystoneDropdown.Size = UDim2.new(0.9 * scaleFactor, 0, 0.1 * scaleFactor, 0)
waystoneDropdown.Position = UDim2.new(0.05, 0, 0.60, 0)
waystoneDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
waystoneDropdown.TextColor3 = Color3.new(1, 1, 1)
waystoneDropdown.Font = Enum.Font.Gotham
waystoneDropdown.TextSize = 14 * scaleFactor
waystoneDropdown.Text = "Waystone: Choose..."
waystoneDropdown.ZIndex = 12
local waystoneDropdownCorner = Instance.new("UICorner", waystoneDropdown)
waystoneDropdownCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local waystoneDropdownFrame = Instance.new("Frame", frame)
waystoneDropdownFrame.Position = UDim2.new(0.05, 0, 0.67, 0)
waystoneDropdownFrame.Size = UDim2.new(0.9 * scaleFactor, 0, 0.2 * scaleFactor, 0)
waystoneDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
waystoneDropdownFrame.BorderSizePixel = 0
waystoneDropdownFrame.Visible = false
waystoneDropdownFrame.ClipsDescendants = true
waystoneDropdownFrame.ZIndex = 13
local waystoneDropdownFrameCorner = Instance.new("UICorner", waystoneDropdownFrame)
waystoneDropdownFrameCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local waystoneScroll = Instance.new("ScrollingFrame", waystoneDropdownFrame)
waystoneScroll.Size = UDim2.new(1, -10 * scaleFactor, 1, -10 * scaleFactor)
waystoneScroll.Position = UDim2.new(0, 5 * scaleFactor, 0, 5 * scaleFactor)
waystoneScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
waystoneScroll.BackgroundTransparency = 1
waystoneScroll.ScrollBarThickness = 4 * scaleFactor
waystoneScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
waystoneScroll.BorderSizePixel = 0
waystoneScroll.ScrollingDirection = Enum.ScrollingDirection.Y
waystoneScroll.ZIndex = 14

local waystoneLayout = Instance.new("UIListLayout", waystoneScroll)
waystoneLayout.SortOrder = Enum.SortOrder.LayoutOrder
waystoneLayout.Padding = UDim.new(0, 5 * scaleFactor)
waystoneLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    waystoneScroll.CanvasSize = UDim2.new(0, 0, 1.5, waystoneLayout.AbsoluteContentSize.Y + 10 * scaleFactor)
end)

-- Floor Teleport Dropdown
local floorTeleportDropdown = Instance.new("TextButton", frame)
floorTeleportDropdown.Size = UDim2.new(0.9 * scaleFactor, 0, 0.1 * scaleFactor, 0)
floorTeleportDropdown.Position = UDim2.new(0.05, 0, 0.70, 0)
floorTeleportDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
floorTeleportDropdown.TextColor3 = Color3.new(1, 1, 1)
floorTeleportDropdown.Font = Enum.Font.Gotham
floorTeleportDropdown.TextSize = 14 * scaleFactor
floorTeleportDropdown.Text = "Teleport: Select Floor..."
floorTeleportDropdown.ZIndex = 12
local floorTeleportDropdownCorner = Instance.new("UICorner", floorTeleportDropdown)
floorTeleportDropdownCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local floorTeleportDropdownFrame = Instance.new("Frame", frame)
floorTeleportDropdownFrame.Position = UDim2.new(0.05, 0, 0.77, 0)
floorTeleportDropdownFrame.Size = UDim2.new(0.9 * scaleFactor, 0, 0.2 * scaleFactor, 0)
floorTeleportDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
floorTeleportDropdownFrame.BorderSizePixel = 0
floorTeleportDropdownFrame.Visible = false
floorTeleportDropdownFrame.ClipsDescendants = true
floorTeleportDropdownFrame.ZIndex = 13
local floorTeleportDropdownFrameCorner = Instance.new("UICorner", floorTeleportDropdownFrame)
floorTeleportDropdownFrameCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)

local floorTeleportScroll = Instance.new("ScrollingFrame", floorTeleportDropdownFrame)
floorTeleportScroll.Size = UDim2.new(1, -10 * scaleFactor, 1, -10 * scaleFactor)
floorTeleportScroll.Position = UDim2.new(0, 5 * scaleFactor, 0, 5 * scaleFactor)
floorTeleportScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
floorTeleportScroll.BackgroundTransparency = 1
floorTeleportScroll.ScrollBarThickness = 4 * scaleFactor
floorTeleportScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
floorTeleportScroll.BorderSizePixel = 0
floorTeleportScroll.ScrollingDirection = Enum.ScrollingDirection.Y
floorTeleportScroll.ZIndex = 14

local floorTeleportLayout = Instance.new("UIListLayout", floorTeleportScroll)
floorTeleportLayout.SortOrder = Enum.SortOrder.LayoutOrder
floorTeleportLayout.Padding = UDim.new(0, 5 * scaleFactor)
floorTeleportLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
floorTeleportScroll.CanvasSize = UDim2.new(0, 0, 0.5, floorTeleportLayout.AbsoluteContentSize.Y + 10 * scaleFactor)
end)

-- FPS Boost Checkbox
local fpsBoostLabel = Instance.new("TextLabel", frame)
fpsBoostLabel.Size = UDim2.new(0.8, 0, 0.05 * scaleFactor, 0)
fpsBoostLabel.Position = UDim2.new(0.05, 0, 0.80, 0)
fpsBoostLabel.Text = "FPS Boost: OFF"
fpsBoostLabel.TextColor3 = Color3.new(1, 1, 1)
fpsBoostLabel.BackgroundTransparency = 1
fpsBoostLabel.Font = Enum.Font.GothamBold
fpsBoostLabel.TextSize = 14 * scaleFactor
fpsBoostLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsBoostLabel.ZIndex = 11

local fpsBoostCheckbox = Instance.new("TextButton", frame)
fpsBoostCheckbox.Size = UDim2.new(0.05 * scaleFactor, 0, 0.05 * scaleFactor, 0)
fpsBoostCheckbox.Position = UDim2.new(0.9, 0, 0.80, 0)
fpsBoostCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
fpsBoostCheckbox.Text = ""
fpsBoostCheckbox.AutoButtonColor = false
fpsBoostCheckbox.ZIndex = 12
Instance.new("UIAspectRatioConstraint", fpsBoostCheckbox).AspectRatio = 1
Instance.new("UICorner", fpsBoostCheckbox).CornerRadius = UDim.new(1, 0)

-- Floor Teleport logic
local teleportFloorEvent = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Teleport", 9e9):WaitForChild("Teleport", 9e9)
local voidTowerEvent = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("TowerDungeon", 9e9):WaitForChild("StartDungeon", 9e9)

local floorList = { "Town", "Floor1", "Floor2", "Floor3", "Floor4", "Floor5", "Floor6", "Floor7", "Floor8", "VoidTower" }

floorTeleportDropdown.MouseButton1Click:Connect(function()
    if floorTeleportDropdownFrame.Visible then
        floorTeleportDropdownFrame.Visible = false
        for _, child in ipairs(floorTeleportScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        return
    end

    floorTeleportDropdownFrame.Visible = true

    for _, floorName in ipairs(floorList) do
        local option = Instance.new("TextButton")
        option.Size = UDim2.new(1, -10, 0, 25)
        option.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        option.TextColor3 = Color3.new(1, 1, 1)
        option.Font = Enum.Font.Gotham
        option.TextSize = 14
        option.Text = floorName
        option.Name = floorName
        option.BorderSizePixel = 0
        option.BackgroundTransparency = 0.1
        option.ZIndex = 15

        local optionCorner = Instance.new("UICorner", option)
        optionCorner.CornerRadius = UDim.new(0, 4)
        option.Parent = floorTeleportScroll

        option.MouseButton1Click:Connect(function()
            floorTeleportDropdownFrame.Visible = false
            floorTeleportDropdown.Text = "Teleport: " .. floorName
            for _, child in ipairs(floorTeleportScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            if floorName == "VoidTower" then
                voidTowerEvent:FireServer(1)
            else
                teleportFloorEvent:FireServer(floorName)
            end
        end)

        option.MouseEnter:Connect(function()
            Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        end)

        option.MouseLeave:Connect(function()
            Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        end)
    end
end)

-- Draggable UI
local dragging = false
local dragStart = nil
local startPos = nil
local resizing = false
local resizeStart = nil
local startSize = nil

-- Resize Handle
local resizeHandle = Instance.new("Frame", frame)
resizeHandle.Size = UDim2.new(0, 20 * scaleFactor, 0, 20 * scaleFactor)
resizeHandle.Position = UDim2.new(1, -20 * scaleFactor, 1, -20 * scaleFactor)
resizeHandle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
resizeHandle.BackgroundTransparency = 0.5
resizeHandle.BorderSizePixel = 0
resizeHandle.ZIndex = 20

local resizeCorner = Instance.new("UICorner", resizeHandle)
resizeCorner.CornerRadius = UDim.new(0, 4 * scaleFactor)

local resizeCursor = Instance.new("ImageLabel", resizeHandle)
resizeCursor.Size = UDim2.new(1, 0, 1, 0)
resizeCursor.BackgroundTransparency = 1
resizeCursor.Image = "rbxassetid://6022668888"
resizeCursor.ImageColor3 = Color3.fromRGB(200, 200, 200)
resizeCursor.ZIndex = 21

-- Size Toggle Functionality
sizeToggleButton.MouseButton1Click:Connect(function()
    UISizeManager.currentSizeIndex = UISizeManager.currentSizeIndex + 1
    if UISizeManager.currentSizeIndex > #UISizeManager.sizes then
        UISizeManager.currentSizeIndex = 1
    end
    
    local newSize = UISizeManager.sizes[UISizeManager.currentSizeIndex]
    
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local sizeTween = Services.TweenService:Create(frame, tweenInfo, {
        Size = UDim2.new(0, newSize.width * scaleFactor, 0, newSize.height * scaleFactor)
    })
    sizeTween:Play()
    
    uiScale.Scale = newSize.scale * scaleFactor
    sizeToggleButton.Text = string.sub(newSize.name, 1, 1)
    resizeHandle.Position = UDim2.new(1, -20 * scaleFactor, 1, -20 * scaleFactor)
end)

-- Initialize Size
local initialSize = UISizeManager.sizes[UISizeManager.currentSizeIndex]
frame.Size = UDim2.new(0, initialSize.width * scaleFactor, 0, initialSize.height * scaleFactor)
uiScale.Scale = initialSize.scale * scaleFactor
sizeToggleButton.Text = string.sub(initialSize.name, 1, 1)

-- Dragging Logic
local dragging = false
local dragStart = nil
local startPos = nil
local resizing = false
local resizeStart = nil
local startSize = nil

dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local hit = input.Position
        local sizeButtonPos = sizeToggleButton.AbsolutePosition
        local sizeButtonSize = sizeToggleButton.AbsoluteSize
        if hit.X >= sizeButtonPos.X and hit.X <= sizeButtonPos.X + sizeButtonSize.X and 
           hit.Y >= sizeButtonPos.Y and hit.Y <= sizeButtonPos.Y + sizeButtonSize.Y then
            return
        end
        
        local resizePos = resizeHandle.AbsolutePosition
        local resizeSize = resizeHandle.AbsoluteSize
        if hit.X >= resizePos.X and hit.X <= resizePos.X + resizeSize.X and 
           hit.Y >= resizePos.Y and hit.Y <= resizePos.Y + resizeSize.Y then
            resizing = true
            resizeStart = input.Position
            startSize = frame.Size
        end
    end
end)

frame.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        elseif resizing then
            local delta = input.Position - resizeStart
            local newWidth = math.clamp(startSize.X.Offset + delta.X, 200 * scaleFactor, 800 * scaleFactor)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 300 * scaleFactor, 1200 * scaleFactor)
            frame.Size = UDim2.new(0, newWidth, 0, newHeight)
            resizeHandle.Position = UDim2.new(1, -20 * scaleFactor, 1, -20 * scaleFactor)
        end
    end
end)

frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        resizing = false
    end
end)

-- Update Checkbox UI
local function updateFollowCheckboxUI()
    followCheckbox.BackgroundColor3 = RuntimeState.stopFollowing and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 255, 60)
    followLabel.Text = RuntimeState.stopFollowing and "Auto Farm: OFF" or "Auto Farm: ON"
end

local function updateKillAuraCheckboxUI()
    killAuraCheckbox.BackgroundColor3 = RuntimeState.killAuraEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    killAuraLabel.Text = RuntimeState.killAuraEnabled and "Kill Aura: ON" or "Kill Aura: OFF"
end

local function updateAutoQuestCheckboxUI()
    autoQuestCheckbox.BackgroundColor3 = RuntimeState.global_isEnabled_autoquest and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoQuestLabel.Text = RuntimeState.global_isEnabled_autoquest and "Auto Quest: ON (Pick quest below)" or "Auto Quest: OFF (Pick quest below)"
end

local function updateAutoCollectCheckboxUI()
    autoCollectCheckbox.BackgroundColor3 = RuntimeState.autoCollectEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoCollectLabel.Text = RuntimeState.autoCollectEnabled and "Auto Collect: ON" or "Auto Collect: OFF"
end

local function updateAutoSkillCheckboxUI()
    autoSkillCheckbox.BackgroundColor3 = RuntimeState.autoSkillEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoSkillLabel.Text = RuntimeState.autoSkillEnabled and "Auto Skill: ON" or "Auto Skill: OFF"
end

local function updateAutoClaimCheckboxUI()
    autoClaimCheckbox.BackgroundColor3 = RuntimeState.autoClaimEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoClaimLabel.Text = RuntimeState.autoClaimEnabled and "Auto Claim Chest: ON (Click 'Take')" or "Auto Claim Chest: OFF (Click 'Take')"
end

local function updateAutoDismantleCheckboxUI()
    autoDismantleCheckbox.BackgroundColor3 = RuntimeState.autoDismantleEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoDismantleLabel.Text = RuntimeState.autoDismantleEnabled and "Auto Dismantle: ON" or "Auto Dismantle: OFF"
end

local function updateAutoDailyQuestsCheckboxUI()
    autoDailyQuestsCheckbox.BackgroundColor3 = RuntimeState.autoDailyQuestsEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoDailyQuestsLabel.Text = RuntimeState.autoDailyQuestsEnabled and "Auto Claim Daily Quests: ON" or "Auto Claim Daily Quests: OFF"
end

local function updateAutoAchievementCheckboxUI()
    autoAchievementCheckbox.BackgroundColor3 = RuntimeState.autoAchievementEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoAchievementLabel.Text = RuntimeState.autoAchievementEnabled and "Auto Claim Achievement: ON" or "Auto Claim Achievement: OFF"
end

local function updateOpenEnchantUIManualCheckboxUI()
    openEnchantUIManualCheckbox.BackgroundColor3 = RuntimeState.openEnchantUIManualEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    openEnchantUIManualLabel.Text = RuntimeState.openEnchantUIManualEnabled and "Open Enchant UI: ON" or "Open Enchant UI: OFF"
end

local function updateOpenMountsUIManualCheckboxUI()
    openMountsUIManualCheckbox.BackgroundColor3 = RuntimeState.openMountsUIManualEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    openMountsUIManualLabel.Text = RuntimeState.openMountsUIManualEnabled and "Open Mounts UI: ON" or "Open Mounts UI: OFF"
end

local function updateOpenSmithingUIManualCheckboxUI()
    openSmithingUIManualCheckbox.BackgroundColor3 = RuntimeState.openSmithingUIManualEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    openSmithingUIManualLabel.Text = RuntimeState.openSmithingUIManualEnabled and "Open Smithing UI: ON" or "Open Smithing UI: OFF"
end


-- FPS Boost logic
local originalMaterials = {}
local originalCastShadows = {}
local function setAllToSmoothPlastic()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not originalMaterials[obj] then
                originalMaterials[obj] = obj.Material
            end
            obj.Material = Enum.Material.SmoothPlastic
        end
    end
end
local function restoreAllMaterials()
    for obj, mat in pairs(originalMaterials) do
        if obj and obj:IsA("BasePart") then
            obj.Material = mat
        end
    end
    originalMaterials = {}
end

local function setAllCastShadowOff()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if originalCastShadows[obj] == nil then
                originalCastShadows[obj] = obj.CastShadow
            end
            obj.CastShadow = false
        end
    end
end
local function restoreAllCastShadows()
    for obj, val in pairs(originalCastShadows) do
        if obj and obj:IsA("BasePart") then
            obj.CastShadow = val
        end
    end
    originalCastShadows = {}
end

local function removeVisualClutter()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceGui") then
            obj:Destroy()
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") then
            obj.Enabled = false
        end
    end
end
local function restoreVisualClutter() end -- Not reversible, so do nothing

local function updateFPSBoostCheckboxUI()
    if RuntimeState.maxFpsBoostEnabled then
        fpsBoostCheckbox.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        fpsBoostLabel.Text = "Max FPS Boost: ON"
    elseif RuntimeState.fpsBoostEnabled then
        fpsBoostCheckbox.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
        fpsBoostLabel.Text = "FPS Boost: ON"
    else
        fpsBoostCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        fpsBoostLabel.Text = "FPS Boost: OFF"
    end
end

fpsBoostCheckbox.MouseButton1Click:Connect(function()
    if RuntimeState.maxFpsBoostEnabled then
        -- If max is on, turn both off
        RuntimeState.maxFpsBoostEnabled = false
        RuntimeState.fpsBoostEnabled = false
        restoreAllMaterials()
        restoreAllCastShadows()
        -- Can't restore decals/textures
    elseif not RuntimeState.fpsBoostEnabled then
        -- Turn on normal FPS boost
        RuntimeState.fpsBoostEnabled = true
        setAllToSmoothPlastic()
    else
        -- Turn off normal FPS boost
        RuntimeState.fpsBoostEnabled = false
        restoreAllMaterials()
    end
    updateFPSBoostCheckboxUI()
    saveConfig()
end)

fpsBoostCheckbox.MouseButton2Click:Connect(function()
    -- Right click for Max FPS Boost
    if not RuntimeState.maxFpsBoostEnabled then
        RuntimeState.maxFpsBoostEnabled = true
        RuntimeState.fpsBoostEnabled = false
        setAllToSmoothPlastic()
        setAllCastShadowOff()
        removeVisualClutter()
    else
        RuntimeState.maxFpsBoostEnabled = false
        restoreAllMaterials()
        restoreAllCastShadows()
        -- Can't restore decals/textures
    end
    updateFPSBoostCheckboxUI()
    saveConfig()
end)

-- On load, apply FPS boost if enabled
if RuntimeState.maxFpsBoostEnabled then
    setAllToSmoothPlastic()
    setAllCastShadowOff()
    removeVisualClutter()
elseif RuntimeState.fpsBoostEnabled then
    setAllToSmoothPlastic()
end

-- Auto Dismantle Function
local function AutoDismantleByMaxRarity(maxRarityIndex)
    for _, item in ipairs(PlayerData.inventory:GetChildren()) do
        local success, rarity = pcall(function()
            return Modules.items:GetRarity(item)
        end)
        if success and rarity <= maxRarityIndex then
            Remotes.dismantle:FireServer(item)
            task.wait(0.1)
        end
    end
end

-- Populate Dismantle Dropdown
dismantleDropdown.MouseButton1Click:Connect(function()
    if dismantleDropdownFrame.Visible then
        dismantleDropdownFrame.Visible = false
        for _, child in ipairs(dismantleScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        return
    end

    questDropdownFrame.Visible = false
    dropdownFrame.Visible = false
    waystoneDropdownFrame.Visible = false
    dismantleDropdownFrame.Visible = true

    for i, rarity in ipairs(RaritySystem.list) do
        local option = Instance.new("TextButton")
        option.Size = UDim2.new(1, -10, 0, 25)
        option.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        option.TextColor3 = Color3.new(1, 1, 1)
        option.Font = Enum.Font.Gotham
        option.TextSize = 14
        option.Text = rarity .. " and below"
        option.BorderSizePixel = 0
        option.BackgroundTransparency = 0.1
        option.ZIndex = 15
        local optionCorner = Instance.new("UICorner", option)
        optionCorner.CornerRadius = UDim.new(0, 4)
        option.Parent = dismantleScroll

        -- Highlight if selected
        if rarity == RuntimeState.selectedRarity then
            option.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
        end

        option.MouseButton1Click:Connect(function()
            RaritySystem.currentIndex = i
            RuntimeState.selectedRarity = RaritySystem.list[RaritySystem.currentIndex]
            dismantleDropdown.Text = "Rarity: " .. RuntimeState.selectedRarity .. " and below"
            dismantleDropdownFrame.Visible = false
            for _, child in ipairs(dismantleScroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            if RuntimeState.autoDismantleEnabled then
                AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity])
            end
            saveConfig()
        end)

        option.MouseEnter:Connect(function()
            Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        end)
        option.MouseLeave:Connect(function()
            if rarity == RuntimeState.selectedRarity then
                Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 255, 60)}):Play()
            else
                Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
            end
        end)
    end
end)

-- Auto Dismantle Checkbox toggle
autoDismantleCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.autoDismantleEnabled = not RuntimeState.autoDismantleEnabled
    updateAutoDismantleCheckboxUI()
    if RuntimeState.autoDismantleEnabled then
        AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity])
    end
    saveConfig()
end)

-- Function to open chest and claim reward
local function openAndClaimChest(chestModel)
    print("[AutoClaim] Trying to claim chest:", chestModel.Name)
    local root = chestModel:FindFirstChild("RootPart")
    if not root then print("[AutoClaim] No RootPart") return end

    local prompt = root:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then print("[AutoClaim] No ProximityPrompt") return end

    prompt.MaxActivationDistance = RuntimeState.autoClaimEnabled and 500 or 10

    local dist = (PlayerData.hrp.Position - root.Position).Magnitude
    print("[AutoClaim] Distance to chest:", dist)
    if dist <= CONFIG.TRIGGER_DISTANCE then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.15)
            prompt:InputHoldEnd()
        end)

        task.delay(2.5, function()
            print("[AutoClaim] Firing Remotes.chest:FireServer")
            pcall(function()
                Remotes.chest:FireServer(chestModel)
            end)
        end)
    end
end

-- Utility Function for Manual UI Opening
local function openUI(station)
    local success, result = pcall(function()
        local prompt = station:WaitForChild("ProximityPrompt", 9e9)
        fireproximityprompt(prompt)
    end)
    if not success then
        warn("Failed to open UI at", station.Name, ":", result)
    end
end

-- Populate Quest Dropdown
questDropdown.MouseButton1Click:Connect(function()
    if questDropdownFrame.Visible then
        questDropdownFrame.Visible = false
        for _, child in ipairs(questScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        return
    end

    dropdownFrame.Visible = false
    dismantleDropdownFrame.Visible = false
    waystoneDropdownFrame.Visible = false
    questDropdownFrame.Visible = true
    if not GameFolders.mobsFolder then return end

    local mobSet = {}
    for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
        mobSet[mob.Name] = true
    end

    local questIDs = {}
    for id, data in pairs(Modules.questList) do
        if data.Type == "Kill" and mobSet[data.Target] then
            table.insert(questIDs, {id = id, level = data.Level})
        end
    end
    table.sort(questIDs, function(a, b)
        return a.level < b.level
    end)

    for _, entry in ipairs(questIDs) do
        local id = entry.id
        local data = Modules.questList[id]
        local label = data.Target
        if data.Repeatable then
            label = label .. " (Repeatable)"
        end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 25)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = label
        btn.BorderSizePixel = 0
        btn.BackgroundTransparency = 0.1
        btn.ZIndex = 15
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 4)
        btn.Parent = questScroll

        -- Highlight if selected
        if tonumber(id) == tonumber(RuntimeState.selectedQuestId) then
            btn.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
        end

        btn.MouseButton1Click:Connect(function()
            RuntimeState.selectedQuestId = tonumber(id)
            local success, err = pcall(function()
                Services.ReplicatedStorage.Systems.Quests.AcceptQuest:FireServer(RuntimeState.selectedQuestId)
            end)
            if not success then
                warn("Failed to accept quest ID " .. tostring(RuntimeState.selectedQuestId) .. ": " .. tostring(err))
            end
            RuntimeState.selectedMobName = data.Target
            mobDropdown.Text = "Mob: " .. RuntimeState.selectedMobName
            questDropdown.Text = "Quest: " .. label
            questDropdownFrame.Visible = false
            for _, child in ipairs(questScroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            saveConfig()
        end)

        btn.MouseEnter:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            if tonumber(id) == tonumber(RuntimeState.selectedQuestId) then
                Services.TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 255, 60)}):Play()
            else
                Services.TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
            end
        end)
    end
end)

-- Populate Mob Dropdown
mobDropdown.MouseButton1Click:Connect(function()
    if dropdownFrame.Visible then
        dropdownFrame.Visible = false
        for _, child in pairs(scrollbar:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        return
    end

    questDropdownFrame.Visible = false
    dismantleDropdownFrame.Visible = false
    waystoneDropdownFrame.Visible = false
    dropdownFrame.Visible = true
    if not GameFolders.mobsFolder then return end

    local added = {}
    for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
        if not added[mob.Name] then
            added[mob.Name] = true
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, -10, 0, 25)
            option.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            option.TextColor3 = Color3.new(1, 1, 1)
            option.Font = Enum.Font.Gotham
            option.TextSize = 14
            option.Text = mob.Name
            option.BorderSizePixel = 0
            option.BackgroundTransparency = 0.1
            option.ZIndex = 15
            local optionCorner = Instance.new("UICorner", option)
            optionCorner.CornerRadius = UDim.new(0, 4)
            option.Parent = scrollbar

            -- Highlight if selected
            if mob.Name == RuntimeState.selectedMobName then
                option.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
            end

            option.MouseButton1Click:Connect(function()
                RuntimeState.selectedMobName = mob.Name
                mobDropdown.Text = "Mob: " .. mob.Name
                dropdownFrame.Visible = false
                for _, child in pairs(scrollbar:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                saveConfig()
            end)

            option.MouseEnter:Connect(function()
                Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            end)
            option.MouseLeave:Connect(function()
                if mob.Name == RuntimeState.selectedMobName then
                    Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 255, 60)}):Play()
                else
                    Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
                end
            end)
        end
    end
end)

-- Populate Waystone Dropdown
waystoneDropdown.MouseButton1Click:Connect(function()
    if waystoneDropdownFrame.Visible then
        waystoneDropdownFrame.Visible = false
        for _, child in ipairs(waystoneScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        return
    end

    questDropdownFrame.Visible = false
    dropdownFrame.Visible = false
    dismantleDropdownFrame.Visible = false
    waystoneDropdownFrame.Visible = true

    if GameFolders.waystones then
        for _, child in pairs(GameFolders.waystones:GetChildren()) do
            if child:IsA("Model") and tonumber(child.Name) then
                local option = Instance.new("TextButton")
                option.Size = UDim2.new(1, -10, 0, 25)
                option.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                option.TextColor3 = Color3.new(1, 1, 1)
                option.Font = Enum.Font.Gotham
                option.TextSize = 14
                option.Text = "Waystone " .. child.Name
                option.Name = child.Name
                option.BorderSizePixel = 0
                option.BackgroundTransparency = 0.1
                option.ZIndex = 15
                local optionCorner = Instance.new("UICorner", option)
                optionCorner.CornerRadius = UDim.new(0, 4)
                option.Parent = waystoneScroll

                option.MouseButton1Click:Connect(function()
                    waystoneDropdownFrame.Visible = false
                    waystoneDropdown.Text = "Waystone: " .. option.Name
                    local args = { GameFolders.waystones:WaitForChild(option.Name, 9e9) }
                    Remotes.teleportWaystone:FireServer(unpack(args))
                    for _, child in ipairs(waystoneScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                end)

                option.MouseEnter:Connect(function()
                    Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
                end)
                option.MouseLeave:Connect(function()
                    Services.TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
                end)
            end
        end
    else
        warn("Waystones folder not found in Workspace!")
    end
end)


-- Unlock All Waystones Button Click
unlockWaystonesButton.MouseButton1Click:Connect(function()
    unlockAllWaystones()
end)
-- Tween to mob
local function tweenTo(position, speed)
    if RuntimeState.tween then RuntimeState.tween:Cancel() end
    local distance = (position - PlayerData.hrp.Position).Magnitude
    local duration = distance / speed
    RuntimeState.tween = Services.TweenService:Create(PlayerData.hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(position)
    })
    RuntimeState.tween:Play()
    Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
    return duration
end

-- Hover logic
local function activateHover(mobHRP)
    if not RuntimeState.bodyVelocity then
        RuntimeState.bodyVelocity = Instance.new("BodyVelocity")
        RuntimeState.bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        RuntimeState.bodyVelocity.P = 3000
        RuntimeState.bodyVelocity.Velocity = Vector3.zero
        RuntimeState.bodyVelocity.Parent = PlayerData.hrp
    end

    RuntimeState.lastVelocity = RuntimeState.bodyVelocity.Velocity

    Services.RunService:BindToRenderStep("FollowMobStep", Enum.RenderPriority.Character.Value, function()
        if RuntimeState.stopFollowing or not mobHRP or not mobHRP.Parent then return end
        local targetPos = mobHRP.Position + Vector3.new(0, CONFIG.HEIGHT_OFFSET, -CONFIG.FOLLOW_DISTANCE)
        local offset = targetPos - PlayerData.hrp.Position
        if offset.Magnitude > 0.5 then
            local desired = offset.Unit * 50
            local smooth = RuntimeState.lastVelocity:Lerp(desired, 0.2)
            RuntimeState.bodyVelocity.Velocity = smooth
            RuntimeState.lastVelocity = smooth
        else
            RuntimeState.bodyVelocity.Velocity = Vector3.zero
            RuntimeState.lastVelocity = Vector3.zero
        end
        Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
    end)
end

local function deactivateHover()
    Services.RunService:UnbindFromRenderStep("FollowMobStep")
    if RuntimeState.bodyVelocity then RuntimeState.bodyVelocity:Destroy() RuntimeState.bodyVelocity = nil end
    RuntimeState.lastVelocity = Vector3.zero
end

-- Find closest mob
local function findClosestMob()
    if not GameFolders.mobsFolder then return nil end
    local closest, minDist = nil, math.huge
    for _, mob in pairs(GameFolders.mobsFolder:GetChildren()) do
        if mob:IsA("Model") and string.find(mob.Name, RuntimeState.selectedMobName) then
            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
            local mobHum = mob:FindFirstChild("Humanoid")
            if mobHRP and (not mobHum or mobHum.Health > 0) then
                local dist = (mobHRP.Position - PlayerData.hrp.Position).Magnitude
                if dist < minDist then
                    closest = mob
                    minDist = dist
                end
            end
        end
    end
    return closest
end

-- Start following
local function startFollowing()
    RuntimeState.stopFollowing = false
    PlayerData.humanoid.AutoRotate = false
    task.spawn(function()
        while not RuntimeState.stopFollowing do
            local mob = findClosestMob()
            if mob then
                local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                if mobHRP then
                    local target = mobHRP.Position + Vector3.new(0, CONFIG.HEIGHT_OFFSET, -CONFIG.FOLLOW_DISTANCE)
                    local dist = (PlayerData.hrp.Position - target).Magnitude
                    local speed = CONFIG.BASE_SPEED
                    if dist > CONFIG.DISTANCE_THRESHOLD then speed = CONFIG.BASE_SPEED
                    elseif dist > 60 then speed = 70
                    elseif dist > 40 then speed = 90
                    else speed = 110 end
                    speed = math.clamp(speed, CONFIG.BASE_SPEED, CONFIG.SPEED_CAP)
                    local duration = tweenTo(target, speed)
                    task.wait(duration + 0.1)
                    if not RuntimeState.stopFollowing and mobHRP and mobHRP.Parent then
                        activateHover(mobHRP)
                    end
                else
                    deactivateHover()
                end
            else
                deactivateHover()
                task.wait(0.2)
            end
            task.wait(0.2)
        end
    end)
end

-- Stop following
local function stopFollowingNow()
    RuntimeState.stopFollowing = true
    PlayerData.humanoid.AutoRotate = true
    if RuntimeState.tween then RuntimeState.tween:Cancel() RuntimeState.tween = nil end
    deactivateHover()
end

-- Auto Skill Helper Functions
local function getNearestMob(maxDistance)
    local closest, minDist = nil, maxDistance or 100
    local char = PlayerData.player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

    for _, mob in ipairs(Services.Workspace:WaitForChild("Mobs"):GetChildren()) do
        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
            local dist = (mob.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                closest, minDist = mob, dist
            end
        end
    end
    return closest
end

local function faceTarget(target)
    local char = PlayerData.player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not target then return end
    local dir = (target.Position - hrp.Position).Unit
    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(dir.X, 0, dir.Z))
end

local function getSkillName()
    return Modules.skillSystem:GetSkillInActiveSlot(PlayerData.player, tostring(CONFIG.SKILL_SLOT))
end

local function getCooldown(skillName)
    local data = Modules.skillSystem:GetSkillData(skillName)
    return data and data.Cooldown or CONFIG.FALLBACK_COOLDOWN
end

local function multiHitAttack(target, skillName)
    local skillData = Modules.skillSystem:GetSkillData(skillName)
    local hits = (skillData and skillData.Hits) or {}

    if #hits == 0 then
        Remotes.skillAttack:FireServer({ target }, skillName, 1)
        return
    end

    for hitIndex = 1, #hits do
        Remotes.skillAttack:FireServer({ target }, skillName, hitIndex)
        task.wait(0.05)
    end
end

-- Follow Checkbox toggle
followCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.stopFollowing = not RuntimeState.stopFollowing
    updateFollowCheckboxUI()
    if not RuntimeState.stopFollowing then
        startFollowing()
    else
        stopFollowingNow()
    end
    saveConfig()
end)

-- Kill Aura Checkbox toggle
killAuraCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.killAuraEnabled = not RuntimeState.killAuraEnabled
    updateKillAuraCheckboxUI()
    saveConfig()
end)

-- Auto Quest Checkbox toggle
autoQuestCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.global_isEnabled_autoquest = not RuntimeState.global_isEnabled_autoquest
    updateAutoQuestCheckboxUI()
    saveConfig()
end)

-- Auto Collect Checkbox toggle
autoCollectCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.autoCollectEnabled = not RuntimeState.autoCollectEnabled
    updateAutoCollectCheckboxUI()
    saveConfig()
end)

-- Auto Skill Checkbox toggle
autoSkillCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.autoSkillEnabled = not RuntimeState.autoSkillEnabled
    updateAutoSkillCheckboxUI()
    saveConfig()
end)

-- Auto Claim Checkbox toggle
autoClaimCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.autoClaimEnabled = not RuntimeState.autoClaimEnabled
    updateAutoClaimCheckboxUI()
    saveConfig()
end)

-- Auto Daily Quests Checkbox toggle
autoDailyQuestsCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.autoDailyQuestsEnabled = not RuntimeState.autoDailyQuestsEnabled
    updateAutoDailyQuestsCheckboxUI()
    saveConfig()
    if RuntimeState.autoDailyQuestsEnabled then
        for i = 1, 10 do
            local success, err = pcall(function()
                QuestRemotes.claimQuest:FireServer(unpack({i}))
            end)
        end
        for _, milestone in ipairs({1, 3, 6}) do
            local success, err = pcall(function()
                QuestRemotes.claimReward:FireServer(milestone)
            end)
        end
    end
end)

-- Auto Achievement Checkbox toggle
autoAchievementCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.autoAchievementEnabled = not RuntimeState.autoAchievementEnabled
    updateAutoAchievementCheckboxUI()
    saveConfig()
end)

-- New Checkbox Toggles for Manual UI Opening
openEnchantUIManualCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.openEnchantUIManualEnabled = not RuntimeState.openEnchantUIManualEnabled
    if RuntimeState.openEnchantUIManualEnabled then
        openUI(CraftingStations.enchanting)
        RuntimeState.openMountsUIManualEnabled = false
        RuntimeState.openSmithingUIManualEnabled = false
        updateOpenMountsUIManualCheckboxUI()
        updateOpenSmithingUIManualCheckboxUI()
    end
    updateOpenEnchantUIManualCheckboxUI()
    saveConfig()
end)

openMountsUIManualCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.openMountsUIManualEnabled = not RuntimeState.openMountsUIManualEnabled
    if RuntimeState.openMountsUIManualEnabled then
        openUI(CraftingStations.mounts)
        RuntimeState.openEnchantUIManualEnabled = false
        RuntimeState.openSmithingUIManualEnabled = false
        updateOpenEnchantUIManualCheckboxUI()
        updateOpenSmithingUIManualCheckboxUI()
    end
    updateOpenMountsUIManualCheckboxUI()
    saveConfig()
end)

openSmithingUIManualCheckbox.MouseButton1Click:Connect(function()
    RuntimeState.openSmithingUIManualEnabled = not RuntimeState.openSmithingUIManualEnabled
    if RuntimeState.openSmithingUIManualEnabled then
        openUI(CraftingStations.smithing)
        RuntimeState.openEnchantUIManualEnabled = false
        RuntimeState.openMountsUIManualEnabled = false
        updateOpenEnchantUIManualCheckboxUI()
        updateOpenMountsUIManualCheckboxUI()
    end
    updateOpenSmithingUIManualCheckboxUI()
    saveConfig()
end)

-- Auto Quest Logic
local Profile = require(Services.ReplicatedStorage.Systems.Profile)
local Quests = Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Quests")
local CompleteQuest = Quests:WaitForChild("CompleteQuest")
local AcceptQuest = Quests:WaitForChild("AcceptQuest")

local function getActiveQuestId()
    local success, profile = pcall(function()
        return Profile:GetProfile(PlayerData.player)
    end)
    if success and profile and profile.Quests then
        return profile.Quests.Active.Value
    else
        warn("Failed to get player profile or quests: " .. tostring(profile))
        return nil
    end
end

task.spawn(function()
    while true do
        if RuntimeState.global_isEnabled_autoquest and RuntimeState.selectedQuestId then
            local activeQuestId = getActiveQuestId()
            if activeQuestId and activeQuestId ~= 0 then
                local success, err = pcall(function()
                    CompleteQuest:FireServer(activeQuestId)
                end)
                if not success then
                    warn("Failed to complete quest ID " .. tostring(activeQuestId) .. ": " .. tostring(err))
                end
                task.wait(0.5)
                local newActiveQuestId = getActiveQuestId()
                if newActiveQuestId == 0 or newActiveQuestId == nil then
                    local success, err = pcall(function()
                        AcceptQuest:FireServer(RuntimeState.selectedQuestId)
                    end)
                    if not success then
                        warn("Failed to accept quest ID " .. tostring(RuntimeState.selectedQuestId) .. ": " .. tostring(err))
                    end
                end
            else
                local success, err = pcall(function()
                    AcceptQuest:FireServer(RuntimeState.selectedQuestId)
                end)
                if not success then
                    warn("Failed to accept quest ID " .. tostring(RuntimeState.selectedQuestId) .. ": " .. tostring(err))
                end
            end
        end
        task.wait(CONFIG.QUEST_CHECK_INTERVAL)
    end
end)

-- Auto Daily Quests Logic
local function claimDailyQuestsAndRewards()
    if not RuntimeState.autoDailyQuestsEnabled then return end
    for i = 1, 6 do
        local success, err = pcall(function()
            QuestRemotes.claimQuest:FireServer(unpack({i}))
        end)
    end
    for _, milestone in ipairs({1, 3, 6}) do
        local success, err = pcall(function()
            QuestRemotes.claimReward:FireServer(milestone)
        end)
    end
end

-- Trigger Auto Daily Quests on load (if enabled) and on UpdateEvent
task.spawn(function()
    if RuntimeState.autoDailyQuestsEnabled then
        task.wait(3)
        claimDailyQuestsAndRewards()
    end
end)

QuestRemotes.update.OnClientEvent:Connect(function()
    if RuntimeState.autoDailyQuestsEnabled then
        claimDailyQuestsAndRewards()
    end
end)

-- Auto Achievement Logic
task.spawn(function()
    while true do
        if RuntimeState.autoAchievementEnabled then
            for id = 1, 50 do
                local success, err = pcall(function()
                    achievementRemote:FireServer(id)
                end)
            end
        end
        task.wait(2)
    end
end)

-- Kill Aura loop
task.spawn(function()
    while true do
        if RuntimeState.killAuraEnabled and PlayerData.character and PlayerData.character:FindFirstChild("HumanoidRootPart") then
            local targets = {}
            for _, mob in pairs(GameFolders.mobsFolder:GetChildren()) do
                local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                if mobHRP and (mobHRP.Position - PlayerData.hrp.Position).Magnitude <= CONFIG.KILL_AURA_RANGE then
                    table.insert(targets, mob)
                    Remotes.doEffect:FireServer("SlashHit", mobHRP.Position, { mobHRP.CFrame })
                end
            end
            if #targets > 0 then
                Remotes.playerAttack:FireServer(targets)
            end
        end
        task.wait(CONFIG.KILL_AURA_DELAY)
    end
end)

-- Auto Collect loop
task.spawn(function()
    while true do
        if RuntimeState.autoCollectEnabled and CONFIG.AUTO_COLLECT_ENABLED then
            PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
            PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
            if not PlayerData.hrp then task.wait(CONFIG.CHECK_INTERVAL) continue end

            for _, drop in pairs(RuntimeState.dropCache) do
                local model = drop.model
                local itemRef = drop.itemRef
                if model and model.PrimaryPart and itemRef then
                    local distance = (PlayerData.hrp.Position - model.PrimaryPart.Position).Magnitude
                    if distance <= CONFIG.COLLECT_RADIUS then
                        pcall(function()
                            Modules.drops:Pickup(PlayerData.player, itemRef)
                            if RuntimeState.autoDismantleEnabled then
                                task.wait(0.1)
                                AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity])
                            end
                        end)
                    end
                end
            end
        end
        task.wait(CONFIG.CHECK_INTERVAL)
    end
end)

-- Robust recursive chest finder
local function findAllChests()
    local chests = {}
    local function recurse(parent)
        for _, obj in ipairs(parent:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("RootPart") then
                table.insert(chests, obj)
            end
            recurse(obj)
        end
    end
    recurse(Services.Workspace)
    return chests
end

-- Auto Claim Chest loop
task.spawn(function()
    while true do
        if RuntimeState.autoClaimEnabled and CONFIG.AUTO_CLAIM_ENABLED then
            print("[AutoClaim] Loop running")
            PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
            PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
            if not PlayerData.hrp then task.wait(CONFIG.CHECK_INTERVAL) continue end

            for _, chest in ipairs(findAllChests()) do
                print("[AutoClaim] Found chest:", chest.Name)
                openAndClaimChest(chest)
                if RuntimeState.autoDismantleEnabled then
                    task.wait(0.1)
                    AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity])
                end
            end
        end
        task.wait(CONFIG.CHECK_INTERVAL)
    end
end)

-- Auto Skill loop
task.spawn(function()
    while true do
        if RuntimeState.autoSkillEnabled and PlayerData.player.Character and PlayerData.player.Character:FindFirstChild("HumanoidRootPart") then
            local skill = getSkillName()
            if skill and skill ~= "" then
                local cooldown = getCooldown(skill)
                local last = RuntimeState.lastUsed[skill] or 0
                if tick() - last >= cooldown then
                    local target = getNearestMob()
                    if target then
                        faceTarget(target.HumanoidRootPart)
                        pcall(function()
                            Remotes.useSkill:FireServer(skill)
                            multiHitAttack(target, skill)
                        end)
                        RuntimeState.lastUsed[skill] = tick()
                    end
                end
            end
        end
        Services.RunService.Heartbeat:Wait()
    end
end)

-- Respawn cleanup
PlayerData.player.CharacterAdded:Connect(function(char)
    PlayerData.character = char
    PlayerData.humanoid = char:WaitForChild("Humanoid")
    PlayerData.hrp = char:WaitForChild("HumanoidRootPart")
    stopFollowingNow()
end)

-- Initialize checkbox UI
updateFollowCheckboxUI()
updateKillAuraCheckboxUI()
updateAutoQuestCheckboxUI()
updateAutoCollectCheckboxUI()
updateAutoSkillCheckboxUI()
updateAutoClaimCheckboxUI()
updateAutoDismantleCheckboxUI()
updateAutoDailyQuestsCheckboxUI()
updateAutoAchievementCheckboxUI()
updateOpenEnchantUIManualCheckboxUI()
updateOpenMountsUIManualCheckboxUI()
updateOpenSmithingUIManualCheckboxUI()
updateFPSBoostCheckboxUI()

-- After AutoDismantleByMaxRarity is defined and before update...CheckboxUI() calls:
-- Restore dropdown button texts after loading config
if RuntimeState.selectedMobName and mobDropdown then
    mobDropdown.Text = "Mob: " .. RuntimeState.selectedMobName
end
if RuntimeState.selectedQuestId and questDropdown then
    local questData = Modules.questList[tostring(RuntimeState.selectedQuestId)]
    if questData then
        local label = questData.Target
        if questData.Repeatable then
            label = label .. " (Repeatable)"
        end
        questDropdown.Text = "Quest: " .. label
    end
end
if RuntimeState.selectedRarity and dismantleDropdown then
    dismantleDropdown.Text = "Rarity: " .. RuntimeState.selectedRarity .. " and below"
end

-- Ensure script logic acts as if user made the selection
-- For Quest: Accept the quest if selectedQuestId is set
if RuntimeState.selectedQuestId then
    local success, err = pcall(function()
        Services.ReplicatedStorage.Systems.Quests.AcceptQuest:FireServer(RuntimeState.selectedQuestId)
    end)
    if not success then
        warn("Failed to accept quest ID " .. tostring(RuntimeState.selectedQuestId) .. ": " .. tostring(err))
    end
end
-- For Dismantle: If enabled, auto-dismantle by selected rarity
if RuntimeState.autoDismantleEnabled and RuntimeState.selectedRarity then
    local rarityIndex = RaritySystem.map[RuntimeState.selectedRarity]
    if rarityIndex then
        AutoDismantleByMaxRarity(rarityIndex)
    end
end

-- Tab Bar UI
local tabBar = Instance.new("Frame", frame)
tabBar.Size = UDim2.new(0, 100 * scaleFactor, 1, 0)
tabBar.Position = UDim2.new(0, 0, 0, 40)
tabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 20
local tabBarCorner = Instance.new("UICorner", tabBar)
tabBarCorner.CornerRadius = UDim.new(0, 8 * scaleFactor)
local tabBarLayout = Instance.new("UIListLayout", tabBar)
tabBarLayout.FillDirection = Enum.FillDirection.Vertical
tabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabBarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
tabBarLayout.Padding = UDim.new(0, 6 * scaleFactor)

local tabNames = {"Main", "Utility"}
local tabButtons = {}
local tabContentFrames = {}
local selectedTab = "Main"

for i, tabName in ipairs(tabNames) do
    local btn = Instance.new("TextButton", tabBar)
    btn.Size = UDim2.new(1, -10 * scaleFactor, 0, 36 * scaleFactor)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14 * scaleFactor
    btn.Text = tabName
    btn.ZIndex = 21
    btn.Name = tabName .. "TabButton"
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6 * scaleFactor)
    tabButtons[tabName] = btn
end

-- Main Tab Content Frame
local mainTabFrame = Instance.new("Frame", frame)
mainTabFrame.Name = "MainTabContent"
mainTabFrame.Size = UDim2.new(1, -120 * scaleFactor, 1, 0)
mainTabFrame.Position = UDim2.new(0, 120 * scaleFactor, 0, 0)
mainTabFrame.BackgroundTransparency = 1
mainTabFrame.ZIndex = 10
tabContentFrames["Main"] = mainTabFrame

-- Utility Tab Content Frame
local utilityTabFrame = Instance.new("Frame", frame)
utilityTabFrame.Name = "UtilityTabContent"
utilityTabFrame.Size = UDim2.new(1, -120 * scaleFactor, 1, 0)
utilityTabFrame.Position = UDim2.new(0, 120 * scaleFactor, 0, 0)
utilityTabFrame.BackgroundTransparency = 1
utilityTabFrame.ZIndex = 10
tabContentFrames["Utility"] = utilityTabFrame

-- Move all automation checkboxes and dropdowns into mainTabFrame
followLabel.Parent = mainTabFrame
followCheckbox.Parent = mainTabFrame
killAuraLabel.Parent = mainTabFrame
killAuraCheckbox.Parent = mainTabFrame
autoQuestLabel.Parent = mainTabFrame
autoQuestCheckbox.Parent = mainTabFrame
autoCollectLabel.Parent = mainTabFrame
autoCollectCheckbox.Parent = mainTabFrame
autoSkillLabel.Parent = mainTabFrame
autoSkillCheckbox.Parent = mainTabFrame
autoClaimLabel.Parent = mainTabFrame
autoClaimCheckbox.Parent = mainTabFrame
autoDailyQuestsLabel.Parent = mainTabFrame
autoDailyQuestsCheckbox.Parent = mainTabFrame
autoAchievementLabel.Parent = mainTabFrame
autoAchievementCheckbox.Parent = mainTabFrame
questDropdown.Parent = mainTabFrame
dropdownTitleLabel.Parent = mainTabFrame
questDropdownFrame.Parent = mainTabFrame
mobDropdown.Parent = mainTabFrame
dropdownFrame.Parent = mainTabFrame
dismantleDropdown.Parent = utilityTabFrame
dismantleDropdownFrame.Parent = utilityTabFrame
autoDismantleLabel.Parent = utilityTabFrame
autoDismantleCheckbox.Parent = utilityTabFrame
openEnchantUIManualLabel.Parent = utilityTabFrame
openEnchantUIManualCheckbox.Parent = utilityTabFrame
openMountsUIManualLabel.Parent = utilityTabFrame
openMountsUIManualCheckbox.Parent = utilityTabFrame
openSmithingUIManualLabel.Parent = utilityTabFrame
openSmithingUIManualCheckbox.Parent = utilityTabFrame
unlockWaystonesButton.Parent = utilityTabFrame
waystoneDropdown.Parent = utilityTabFrame
waystoneDropdownFrame.Parent = utilityTabFrame
floorTeleportDropdown.Parent = utilityTabFrame
floorTeleportDropdownFrame.Parent = utilityTabFrame
fpsBoostLabel.Parent = utilityTabFrame
fpsBoostCheckbox.Parent = utilityTabFrame

-- Tab switching logic
local function selectTab(tabName)
    selectedTab = tabName
    for name, frame in pairs(tabContentFrames) do
        frame.Visible = (name == tabName)
    end
    for name, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = (name == tabName) and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(60, 60, 60)
    end
end
for name, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)
end
selectTab("Main")

-- Automatically set to smallest scale on Android
if Services.UserInputService.TouchEnabled then
    UISizeManager.currentSizeIndex = #UISizeManager.sizes
    local newSize = UISizeManager.sizes[UISizeManager.currentSizeIndex]
    frame.Size = UDim2.new(0, newSize.width * scaleFactor, 0, newSize.height * scaleFactor)
    uiScale.Scale = newSize.scale * scaleFactor
    -- Also update dropdown frame scales
    for _, dropFrame in ipairs(dropdownFrames) do
        for _, child in ipairs(dropFrame:GetChildren()) do
            if child:IsA("UIScale") then
                child.Scale = newSize.scale * scaleFactor
            end
        end
    end
end
