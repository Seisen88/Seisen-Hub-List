local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local mobsFolder = Workspace:WaitForChild("Mobs")
local profile = ReplicatedStorage:WaitForChild("Profiles"):WaitForChild(player.Name)
local inventory = profile:WaitForChild("Inventory")
local dismantleRemote = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Crafting"):WaitForChild("Dismantle")
local itemsModule = require(ReplicatedStorage.Systems.Items)

-- Daily Quests Setup
local RemoteFolder = ReplicatedStorage:WaitForChild("Systems"):FindFirstChild("WeeklyQuests") or ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DailyQuests")
local ClaimQuestRemote = RemoteFolder:WaitForChild("ClaimIndividualDailyQuest")
local ClaimRewardRemote = RemoteFolder:WaitForChild("ClaimDailyQuestReward")
local UpdateEvent = RemoteFolder:WaitForChild("Update")

-- Achievement Setup
local claimRemote = ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Achievements", 9e9):WaitForChild("ClaimAchievementReward", 9e9)

local AntiCheat = require(ReplicatedStorage.Systems.AntiCheat)
local QuestList = require(ReplicatedStorage.Systems.Quests.QuestList)
local PlayerAttack = ReplicatedStorage.Systems.Combat.PlayerAttack
local DoEffect = ReplicatedStorage.Systems.Effects.DoEffect
local DropsModule = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Drops"))
local SkillSystem = require(ReplicatedStorage.Systems.Skills)
local UseSkillRemote = ReplicatedStorage.Systems.Skills:WaitForChild("UseSkill")
local SkillAttackRemote = ReplicatedStorage.Systems.Combat:WaitForChild("PlayerSkillAttack")
local ChestRemote = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Chests"):WaitForChild("ClaimItem")

--Passive Anti-Afk
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- Modern Notification UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiAFKNotification"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local notificationFrame = Instance.new("Frame")
notificationFrame.Size = UDim2.new(0, 240, 0, 36)
notificationFrame.Position = UDim2.new(0.5, -120, 0.08, 0)
notificationFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
notificationFrame.BackgroundTransparency = 0.15
notificationFrame.BorderSizePixel = 0
notificationFrame.Parent = screenGui

-- Rounded corners
local corner = Instance.new("UICorner", notificationFrame)
corner.CornerRadius = UDim.new(0, 10)

-- Text
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "Anti-AFK is now active"
label.Font = Enum.Font.GothamMedium
label.TextColor3 = Color3.fromRGB(200, 255, 200)
label.TextSize = 17
label.TextStrokeTransparency = 0.8
label.Parent = notificationFrame

-- Fade out and destroy after 4 seconds
task.delay(4, function()
    for i = 1, 20 do
        notificationFrame.BackgroundTransparency += 0.04
        label.TextTransparency += 0.05
        task.wait(0.03)
    end
    screenGui:Destroy()
end)

-- Waystone Setup
local Waystones = Workspace:WaitForChild("Waystones", 9e9)
local teleportEvent = ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Locations", 9e9):WaitForChild("TeleportWaystone", 9e9)
    local teleportFloorEvent = ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Teleport", 9e9):WaitForChild("Teleport", 9e9)
    local voidTowerEvent = ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("TowerDungeon", 9e9):WaitForChild("StartDungeon", 9e9)

-- Crafting Station References
local stations = Workspace:WaitForChild("CraftingStations", 9e9)
local enchantingStation = stations:WaitForChild("Enchanting", 9e9)
local mountsStation = stations:WaitForChild("Mounts", 9e9)
local smithingStation = stations:WaitForChild("Smithing", 9e9)

-- CONFIG
-- CONFIG
local HEIGHT_OFFSET = 20
local FOLLOW_DISTANCE = 3
local BASE_SPEED = 40
local SPEED_CAP = 90
local DISTANCE_THRESHOLD = 200
local KILL_AURA_RANGE = 100
local KILL_AURA_DELAY = 0.26
local AUTO_COLLECT_ENABLED = true
local COLLECT_RADIUS = 50
local CHECK_INTERVAL = 0.3
local SKILL_SLOT = 1
local FALLBACK_COOLDOWN = 2
local QUEST_CHECK_INTERVAL = 1
local TRIGGER_DISTANCE = 500
local AUTO_CLAIM_ENABLED = true
local TELEPORT_DELAY = 2

-- Runtime state
local stopFollowing = true
local killAuraEnabled = false
local autoCollectEnabled = true
local autoSkillEnabled = false
local autoClaimEnabled = true
local autoDismantleEnabled = false
local autoDailyQuestsEnabled = false
local autoAchievementEnabled = false
local openEnchantUIManualEnabled = false
local openMountsUIManualEnabled = false
local openSmithingUIManualEnabled = false
local selectedMobName = "Razor Boar"
local selectedQuestId = nil
local selectedRarity = "Uncommon"
local bodyVelocity = nil
local tween = nil
local lastVelocity = Vector3.zero
local global_isEnabled_autoquest = false
local dropCache = {}
local lastUsed = {}
local claimedQuest = {}
local claimedReward = {}

-- Rarity name to numeric index
local rarityMap = {
    ["Common"] = 1,
    ["Uncommon"] = 2,
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5
}
local rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
local rarityIndex = 2

-- Map quest ID -> mob name
local questToMobMap = {}
for id, data in pairs(QuestList) do
    if data.Type == "Kill" and data.Target then
        questToMobMap[id] = data.Target
    end
end

-- Try to grab drop cache
local success, drops = pcall(function()
    return getupvalue(DropsModule.SpawnDropModel, 7)
end)
if success and type(drops) == "table" then
    dropCache = drops
else
    warn("⚠️ Failed to access u14 drop cache. Auto collect disabled.")
    autoCollectEnabled = false
end

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

    for _, stone in ipairs(Waystones:GetChildren()) do
        if stone:IsA("Model") and tonumber(stone.Name) and not unlocked[stone.Name] then
            -- Teleport to the waystone
            teleportEvent:FireServer(stone)
            task.wait(TELEPORT_DELAY)

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

-- GUI
local UserInputService = game:GetService("UserInputService")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobFollowerKillAuraUI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.8, 0, 0.9, 0) -- 80% width, 90% height
frame.Position = UDim2.new(0.1, 0, 0.05, 0) -- Centered
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.ZIndex = 100
frame.Parent = screenGui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Add mobile scaling without using 'local'
local scale = Instance.new("UIScale")
scale.Scale = UserInputService.TouchEnabled and 0.6 or 0.8
scale.Parent = frame

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(300, 400)
constraint.MaxSize = Vector2.new(800, 1000)
constraint.Parent = frame



-- Title
local titleLabel = Instance.new("TextLabel", frame)
titleLabel.Size = UDim2.new(1, 0, 0, 20)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "Swordburst 3 by Seisen"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.ZIndex = 11

-- Follow Checkbox
local followLabel = Instance.new("TextLabel", frame)
followLabel.Size = UDim2.new(1, -40, 0, 20)
followLabel.Position = UDim2.new(0, 10, 0, 30)
followLabel.Text = "Follow: OFF"
followLabel.TextColor3 = Color3.new(1, 1, 1)
followLabel.BackgroundTransparency = 1
followLabel.Font = Enum.Font.GothamBold
followLabel.TextSize = 14
followLabel.TextXAlignment = Enum.TextXAlignment.Left
followLabel.ZIndex = 11

local followCheckbox = Instance.new("TextButton", frame)
followCheckbox.Size = UDim2.new(0, 20, 0, 20)
followCheckbox.Position = UDim2.new(1, -30, 0, 30)
followCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
followCheckbox.Text = ""
followCheckbox.AutoButtonColor = false
followCheckbox.ZIndex = 12
local followCorner = Instance.new("UICorner", followCheckbox)
followCorner.CornerRadius = UDim.new(1, 0)

-- Kill Aura Checkbox
local killAuraLabel = Instance.new("TextLabel", frame)
killAuraLabel.Size = UDim2.new(1, -40, 0, 20)
killAuraLabel.Position = UDim2.new(0, 10, 0, 60)
killAuraLabel.Text = "Kill Aura: OFF"
killAuraLabel.TextColor3 = Color3.new(1, 1, 1)
killAuraLabel.BackgroundTransparency = 1
killAuraLabel.Font = Enum.Font.GothamBold
killAuraLabel.TextSize = 14
killAuraLabel.TextXAlignment = Enum.TextXAlignment.Left
killAuraLabel.ZIndex = 11

local killAuraCheckbox = Instance.new("TextButton", frame)
killAuraCheckbox.Size = UDim2.new(0, 20, 0, 20)
killAuraCheckbox.Position = UDim2.new(1, -30, 0, 60)
killAuraCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
killAuraCheckbox.Text = ""
killAuraCheckbox.AutoButtonColor = false
killAuraCheckbox.ZIndex = 12
local killAuraCorner = Instance.new("UICorner", killAuraCheckbox)
killAuraCorner.CornerRadius = UDim.new(1, 0)

-- Auto Quest Checkbox
local autoQuestLabel = Instance.new("TextLabel", frame)
autoQuestLabel.Size = UDim2.new(1, -40, 0, 20)
autoQuestLabel.Position = UDim2.new(0, 10, 0, 90)
autoQuestLabel.Text = "Auto Quest: OFF  ( First choose quest below to work)"
autoQuestLabel.TextColor3 = Color3.new(1, 1, 1)
autoQuestLabel.BackgroundTransparency = 1
autoQuestLabel.Font = Enum.Font.GothamBold
autoQuestLabel.TextSize = 14
autoQuestLabel.TextXAlignment = Enum.TextXAlignment.Left
autoQuestLabel.ZIndex = 11

local autoQuestCheckbox = Instance.new("TextButton", frame)
autoQuestCheckbox.Size = UDim2.new(0, 20, 0, 20)
autoQuestCheckbox.Position = UDim2.new(1, -30, 0, 90)
autoQuestCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoQuestCheckbox.Text = ""
autoQuestCheckbox.AutoButtonColor = false
autoQuestCheckbox.ZIndex = 12
local autoQuestCorner = Instance.new("UICorner", autoQuestCheckbox)
autoQuestCorner.CornerRadius = UDim.new(1, 0)

-- Auto Collect Checkbox
local autoCollectLabel = Instance.new("TextLabel", frame)
autoCollectLabel.Size = UDim2.new(1, -40, 0, 20)
autoCollectLabel.Position = UDim2.new(0, 10, 0, 120)
autoCollectLabel.Text = "Auto Collect: ON"
autoCollectLabel.TextColor3 = Color3.new(1, 1, 1)
autoCollectLabel.BackgroundTransparency = 1
autoCollectLabel.Font = Enum.Font.GothamBold
autoCollectLabel.TextSize = 14
autoCollectLabel.TextXAlignment = Enum.TextXAlignment.Left
autoCollectLabel.ZIndex = 11

local autoCollectCheckbox = Instance.new("TextButton", frame)
autoCollectCheckbox.Size = UDim2.new(0, 20, 0, 20)
autoCollectCheckbox.Position = UDim2.new(1, -30, 0, 120)
autoCollectCheckbox.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
autoCollectCheckbox.Text = ""
autoCollectCheckbox.AutoButtonColor = false
autoCollectCheckbox.ZIndex = 12
local autoCollectCorner = Instance.new("UICorner", autoCollectCheckbox)
autoCollectCorner.CornerRadius = UDim.new(1, 0)

-- Auto Skill Checkbox
local autoSkillLabel = Instance.new("TextLabel", frame)
autoSkillLabel.Size = UDim2.new(1, -40, 0, 20)
autoSkillLabel.Position = UDim2.new(0, 10, 0, 150)
autoSkillLabel.Text = "Auto Skill: OFF"
autoSkillLabel.TextColor3 = Color3.new(1, 1, 1)
autoSkillLabel.BackgroundTransparency = 1
autoSkillLabel.Font = Enum.Font.GothamBold
autoSkillLabel.TextSize = 14
autoSkillLabel.TextXAlignment = Enum.TextXAlignment.Left
autoSkillLabel.ZIndex = 11

local autoSkillCheckbox = Instance.new("TextButton", frame)
autoSkillCheckbox.Size = UDim2.new(0, 20, 0, 20)
autoSkillCheckbox.Position = UDim2.new(1, -30, 0, 150)
autoSkillCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoSkillCheckbox.Text = ""
autoSkillCheckbox.AutoButtonColor = false
autoSkillCheckbox.ZIndex = 12
local autoSkillCorner = Instance.new("UICorner", autoSkillCheckbox)
autoSkillCorner.CornerRadius = UDim.new(1, 0)

-- Auto Claim Checkbox
local autoClaimLabel = Instance.new("TextLabel", frame)
autoClaimLabel.Size = UDim2.new(1, -40, 0, 20)
autoClaimLabel.Position = UDim2.new(0, 10, 0, 180)
autoClaimLabel.Text = "Auto Claim Chest: ON  ( need to manually click the 'Take' Button)"
autoClaimLabel.TextColor3 = Color3.new(1, 1, 1)
autoClaimLabel.BackgroundTransparency = 1
autoClaimLabel.Font = Enum.Font.GothamBold
autoClaimLabel.TextSize = 14
autoClaimLabel.TextXAlignment = Enum.TextXAlignment.Left
autoClaimLabel.ZIndex = 11

local autoClaimCheckbox = Instance.new("TextButton", frame)
autoClaimCheckbox.Size = UDim2.new(0, 20, 0, 20)
autoClaimCheckbox.Position = UDim2.new(1, -30, 0, 180)
autoClaimCheckbox.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
autoClaimCheckbox.Text = ""
autoClaimCheckbox.AutoButtonColor = false
autoClaimCheckbox.ZIndex = 12
local autoClaimCorner = Instance.new("UICorner", autoClaimCheckbox)
autoClaimCorner.CornerRadius = UDim.new(1, 0)

-- Auto Daily Quests Checkbox
local autoDailyQuestsLabel = Instance.new("TextLabel", frame)
autoDailyQuestsLabel.Size = UDim2.new(1, -40, 0, 20)
autoDailyQuestsLabel.Position = UDim2.new(0, 10, 0, 210)
autoDailyQuestsLabel.Text = "Auto Claim Daily Quests: OFF"
autoDailyQuestsLabel.TextColor3 = Color3.new(1, 1, 1)
autoDailyQuestsLabel.BackgroundTransparency = 1
autoDailyQuestsLabel.Font = Enum.Font.GothamBold
autoDailyQuestsLabel.TextSize = 14
autoDailyQuestsLabel.TextXAlignment = Enum.TextXAlignment.Left
autoDailyQuestsLabel.ZIndex = 11

local autoDailyQuestsCheckbox = Instance.new("TextButton", frame)
autoDailyQuestsCheckbox.Size = UDim2.new(0, 20, 0, 20)
autoDailyQuestsCheckbox.Position = UDim2.new(1, -30, 0, 210)
autoDailyQuestsCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoDailyQuestsCheckbox.Text = ""
autoDailyQuestsCheckbox.AutoButtonColor = false
autoDailyQuestsCheckbox.ZIndex = 12
local autoDailyQuestsCorner = Instance.new("UICorner", autoDailyQuestsCheckbox)
autoDailyQuestsCorner.CornerRadius = UDim.new(1, 0)

-- Auto Achievement Checkbox
local autoAchievementLabel = Instance.new("TextLabel", frame)
autoAchievementLabel.Size = UDim2.new(1, -40, 0, 20)
autoAchievementLabel.Position = UDim2.new(0, 10, 0, 240)
autoAchievementLabel.Text = "Auto Claim Achievement: OFF"
autoAchievementLabel.TextColor3 = Color3.new(1, 1, 1)
autoAchievementLabel.BackgroundTransparency = 1
autoAchievementLabel.Font = Enum.Font.GothamBold
autoAchievementLabel.TextSize = 14
autoAchievementLabel.TextXAlignment = Enum.TextXAlignment.Left
autoAchievementLabel.ZIndex = 11

local autoAchievementCheckbox = Instance.new("TextButton", frame)
autoAchievementCheckbox.Size = UDim2.new(0, 20, 0, 20)
autoAchievementCheckbox.Position = UDim2.new(1, -30, 0, 240)
autoAchievementCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoAchievementCheckbox.Text = ""
autoAchievementCheckbox.AutoButtonColor = false
autoAchievementCheckbox.ZIndex = 12
local autoAchievementCorner = Instance.new("UICorner", autoAchievementCheckbox)
autoAchievementCorner.CornerRadius = UDim.new(1, 0)

-- Dropdown Title
local dropdownTitleLabel = Instance.new("TextLabel", frame)
dropdownTitleLabel.Size = UDim2.new(1, 0, 0, 20)
dropdownTitleLabel.Position = UDim2.new(0, 0, 0, 270)
dropdownTitleLabel.Text = "Select Quest and Mob"
dropdownTitleLabel.TextColor3 = Color3.new(1, 1, 1)
dropdownTitleLabel.BackgroundTransparency = 1
dropdownTitleLabel.Font = Enum.Font.GothamBold
dropdownTitleLabel.TextSize = 14
dropdownTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
dropdownTitleLabel.ZIndex = 11

-- Quest Dropdown
local questDropdown = Instance.new("TextButton", frame)
questDropdown.Size = UDim2.new(0.5, -15, 0, 35)
questDropdown.Position = UDim2.new(0, 10, 0, 295)
questDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
questDropdown.TextColor3 = Color3.new(1, 1, 1)
questDropdown.Font = Enum.Font.Gotham
questDropdown.TextSize = 14
questDropdown.Text = "Quest: (None)"
questDropdown.ZIndex = 12
local questDropdownCorner = Instance.new("UICorner", questDropdown)
questDropdownCorner.CornerRadius = UDim.new(0, 6)

local questDropdownFrame = Instance.new("Frame", frame)
questDropdownFrame.Position = UDim2.new(0, 10, 0, 335)
questDropdownFrame.Size = UDim2.new(0.5, -15, 0, 120)
questDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
questDropdownFrame.BorderSizePixel = 0
questDropdownFrame.Visible = false
questDropdownFrame.ClipsDescendants = true
questDropdownFrame.ZIndex = 13
local questDropdownFrameCorner = Instance.new("UICorner", questDropdownFrame)
questDropdownFrameCorner.CornerRadius = UDim.new(0, 6)

local questScroll = Instance.new("ScrollingFrame", questDropdownFrame)
questScroll.Size = UDim2.new(1, -10, 1, -10)
questScroll.Position = UDim2.new(0, 5, 0, 5)
questScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
questScroll.BackgroundTransparency = 1
questScroll.ScrollBarThickness = 4
questScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
questScroll.BorderSizePixel = 0
questScroll.ScrollingDirection = Enum.ScrollingDirection.Y
questScroll.ZIndex = 14

local questLayout = Instance.new("UIListLayout", questScroll)
questLayout.SortOrder = Enum.SortOrder.LayoutOrder
questLayout.Padding = UDim.new(0, 5)
questLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    questScroll.CanvasSize = UDim2.new(0, 0, 0, questLayout.AbsoluteContentSize.Y + 10)
end)

-- Mob Dropdown
local mobDropdown = Instance.new("TextButton", frame)
mobDropdown.Size = UDim2.new(0.5, -15, 0, 35)
mobDropdown.Position = UDim2.new(0.5, 5, 0, 295)
mobDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mobDropdown.TextColor3 = Color3.new(1, 1, 1)
mobDropdown.Font = Enum.Font.Gotham
mobDropdown.TextSize = 14
mobDropdown.Text = "Mob: Razor Boar"
mobDropdown.ZIndex = 12
local mobDropdownCorner = Instance.new("UICorner", mobDropdown)
mobDropdownCorner.CornerRadius = UDim.new(0, 6)

local dropdownFrame = Instance.new("Frame", frame)
dropdownFrame.Position = UDim2.new(0.5, 5, 0, 335)
dropdownFrame.Size = UDim2.new(0.5, -15, 0, 120)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropdownFrame.BorderSizePixel = 0
dropdownFrame.Visible = false
dropdownFrame.ClipsDescendants = true
dropdownFrame.ZIndex = 13
local dropdownFrameCorner = Instance.new("UICorner", dropdownFrame)
dropdownFrameCorner.CornerRadius = UDim.new(0, 6)

local scrollbar = Instance.new("ScrollingFrame", dropdownFrame)
scrollbar.Size = UDim2.new(1, -10, 1, -10)
scrollbar.Position = UDim2.new(0, 5, 0, 5)
scrollbar.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollbar.BackgroundTransparency = 1
scrollbar.ScrollBarThickness = 4
scrollbar.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollbar.BorderSizePixel = 0
scrollbar.ScrollingDirection = Enum.ScrollingDirection.Y
scrollbar.ZIndex = 14

local listLayout = Instance.new("UIListLayout", scrollbar)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollbar.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- Auto Dismantle Checkbox
local autoDismantleLabel = Instance.new("TextLabel", frame)
autoDismantleLabel.Size = UDim2.new(1, -40, 0, 20)
autoDismantleLabel.Position = UDim2.new(0, 10, 0, 340)
autoDismantleLabel.Text = "Auto Dismantle: OFF"
autoDismantleLabel.TextColor3 = Color3.new(1, 1, 1)
autoDismantleLabel.BackgroundTransparency = 1
autoDismantleLabel.Font = Enum.Font.GothamBold
autoDismantleLabel.TextSize = 14
autoDismantleLabel.TextXAlignment = Enum.TextXAlignment.Left
autoDismantleLabel.ZIndex = 11

local autoDismantleCheckbox = Instance.new("TextButton", frame)
autoDismantleCheckbox.Size = UDim2.new(0, 20, 0, 20)
autoDismantleCheckbox.Position = UDim2.new(1, -30, 0, 340)
autoDismantleCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoDismantleCheckbox.Text = ""
autoDismantleCheckbox.AutoButtonColor = false
autoDismantleCheckbox.ZIndex = 12
local autoDismantleCorner = Instance.new("UICorner", autoDismantleCheckbox)
autoDismantleCorner.CornerRadius = UDim.new(1, 0)

-- Auto Dismantle Dropdown
local dismantleDropdown = Instance.new("TextButton", frame)
dismantleDropdown.Size = UDim2.new(1, -20, 0, 35)
dismantleDropdown.Position = UDim2.new(0, 10, 0, 370)
dismantleDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dismantleDropdown.TextColor3 = Color3.new(1, 1, 1)
dismantleDropdown.Font = Enum.Font.Gotham
dismantleDropdown.TextSize = 14
dismantleDropdown.Text = "Rarity: Uncommon and below"
dismantleDropdown.ZIndex = 12
local dismantleDropdownCorner = Instance.new("UICorner", dismantleDropdown)
dismantleDropdownCorner.CornerRadius = UDim.new(0, 6)

local dismantleDropdownFrame = Instance.new("Frame", frame)
dismantleDropdownFrame.Position = UDim2.new(0, 10, 0, 400)
dismantleDropdownFrame.Size = UDim2.new(1, -20, 0, 120)
dismantleDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dismantleDropdownFrame.BorderSizePixel = 0
dismantleDropdownFrame.Visible = false
dismantleDropdownFrame.ClipsDescendants = true
dismantleDropdownFrame.ZIndex = 13
local dismantleDropdownFrameCorner = Instance.new("UICorner", dismantleDropdownFrame)
dismantleDropdownFrameCorner.CornerRadius = UDim.new(0, 6)

local dismantleScroll = Instance.new("ScrollingFrame", dismantleDropdownFrame)
dismantleScroll.Size = UDim2.new(1, -10, 1, -10)
dismantleScroll.Position = UDim2.new(0, 5, 0, 5)
dismantleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
dismantleScroll.BackgroundTransparency = 1
dismantleScroll.ScrollBarThickness = 4
dismantleScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
dismantleScroll.BorderSizePixel = 0
dismantleScroll.ScrollingDirection = Enum.ScrollingDirection.Y
dismantleScroll.ZIndex = 14

local dismantleLayout = Instance.new("UIListLayout", dismantleScroll)
dismantleLayout.SortOrder = Enum.SortOrder.LayoutOrder
dismantleLayout.Padding = UDim.new(0, 5)
dismantleLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    dismantleScroll.CanvasSize = UDim2.new(0, 0, 0, dismantleLayout.AbsoluteContentSize.Y + 10)
end)

-- Open Enchant UI Checkbox
local openEnchantUIManualLabel = Instance.new("TextLabel", frame)
openEnchantUIManualLabel.Size = UDim2.new(1, -40, 0, 20)
openEnchantUIManualLabel.Position = UDim2.new(0, 10, 0, 415)
openEnchantUIManualLabel.Text = "Open Enchant UI: OFF"
openEnchantUIManualLabel.TextColor3 = Color3.new(1, 1, 1)
openEnchantUIManualLabel.BackgroundTransparency = 1
openEnchantUIManualLabel.Font = Enum.Font.GothamBold
openEnchantUIManualLabel.TextSize = 14
openEnchantUIManualLabel.TextXAlignment = Enum.TextXAlignment.Left
openEnchantUIManualLabel.ZIndex = 11

local openEnchantUIManualCheckbox = Instance.new("TextButton", frame)
openEnchantUIManualCheckbox.Size = UDim2.new(0, 20, 0, 20)
openEnchantUIManualCheckbox.Position = UDim2.new(1, -30, 0, 415)
openEnchantUIManualCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
openEnchantUIManualCheckbox.Text = ""
openEnchantUIManualCheckbox.AutoButtonColor = false
openEnchantUIManualCheckbox.ZIndex = 12
local openEnchantUIManualCorner = Instance.new("UICorner", openEnchantUIManualCheckbox)
openEnchantUIManualCorner.CornerRadius = UDim.new(1, 0)

-- Open Mounts UI Checkbox
local openMountsUIManualLabel = Instance.new("TextLabel", frame)
openMountsUIManualLabel.Size = UDim2.new(1, -40, 0, 20)
openMountsUIManualLabel.Position = UDim2.new(0, 10, 0, 440)
openMountsUIManualLabel.Text = "Open Mounts UI: OFF"
openMountsUIManualLabel.TextColor3 = Color3.new(1, 1, 1)
openMountsUIManualLabel.BackgroundTransparency = 1
openMountsUIManualLabel.Font = Enum.Font.GothamBold
openMountsUIManualLabel.TextSize = 14
openMountsUIManualLabel.TextXAlignment = Enum.TextXAlignment.Left
openMountsUIManualLabel.ZIndex = 11

local openMountsUIManualCheckbox = Instance.new("TextButton", frame)
openMountsUIManualCheckbox.Size = UDim2.new(0, 20, 0, 20)
openMountsUIManualCheckbox.Position = UDim2.new(1, -30, 0, 440)
openMountsUIManualCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
openMountsUIManualCheckbox.Text = ""
openMountsUIManualCheckbox.AutoButtonColor = false
openMountsUIManualCheckbox.ZIndex = 12
local openMountsUIManualCorner = Instance.new("UICorner", openMountsUIManualCheckbox)
openMountsUIManualCorner.CornerRadius = UDim.new(1, 0)

-- Open Smithing UI Checkbox
local openSmithingUIManualLabel = Instance.new("TextLabel", frame)
openSmithingUIManualLabel.Size = UDim2.new(1, -40, 0, 20)
openSmithingUIManualLabel.Position = UDim2.new(0, 10, 0, 465)
openSmithingUIManualLabel.Text = "Open Smithing UI: OFF"
openSmithingUIManualLabel.TextColor3 = Color3.new(1, 1, 1)
openSmithingUIManualLabel.BackgroundTransparency = 1
openSmithingUIManualLabel.Font = Enum.Font.GothamBold
openSmithingUIManualLabel.TextSize = 14
openSmithingUIManualLabel.TextXAlignment = Enum.TextXAlignment.Left
openSmithingUIManualLabel.ZIndex = 11

local openSmithingUIManualCheckbox = Instance.new("TextButton", frame)
openSmithingUIManualCheckbox.Size = UDim2.new(0, 20, 0, 20)
openSmithingUIManualCheckbox.Position = UDim2.new(1, -30, 0, 465)
openSmithingUIManualCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
openSmithingUIManualCheckbox.Text = ""
openSmithingUIManualCheckbox.AutoButtonColor = false
openSmithingUIManualCheckbox.ZIndex = 12
local openSmithingUIManualCorner = Instance.new("UICorner", openSmithingUIManualCheckbox)
openSmithingUIManualCorner.CornerRadius = UDim.new(1, 0)

-- Unlock All Waystones Button
local unlockWaystonesButton = Instance.new("TextButton", frame)
unlockWaystonesButton.Size = UDim2.new(1, -20, 0, 35)
unlockWaystonesButton.Position = UDim2.new(0, 10, 0, 495)
unlockWaystonesButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
unlockWaystonesButton.TextColor3 = Color3.new(1, 1, 1)
unlockWaystonesButton.Font = Enum.Font.Gotham
unlockWaystonesButton.TextSize = 14
unlockWaystonesButton.Text = "Unlock All Waystones"
unlockWaystonesButton.ZIndex = 12
local unlockWaystonesButtonCorner = Instance.new("UICorner", unlockWaystonesButton)
unlockWaystonesButtonCorner.CornerRadius = UDim.new(0, 6)

-- Waystone Dropdown
local waystoneDropdown = Instance.new("TextButton", frame)
waystoneDropdown.Size = UDim2.new(1, -20, 0, 35)
waystoneDropdown.Position = UDim2.new(0, 10, 0, 535)
waystoneDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
waystoneDropdown.TextColor3 = Color3.new(1, 1, 1)
waystoneDropdown.Font = Enum.Font.Gotham
waystoneDropdown.TextSize = 14
waystoneDropdown.Text = "Waystone: Choose..."
waystoneDropdown.ZIndex = 12
local waystoneDropdownCorner = Instance.new("UICorner", waystoneDropdown)
waystoneDropdownCorner.CornerRadius = UDim.new(0, 6)

local waystoneDropdownFrame = Instance.new("Frame", frame)
waystoneDropdownFrame.Position = UDim2.new(0, 10, 0, 580)
waystoneDropdownFrame.Size = UDim2.new(1, -20, 0, 120)
waystoneDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
waystoneDropdownFrame.BorderSizePixel = 0
waystoneDropdownFrame.Visible = false
waystoneDropdownFrame.ClipsDescendants = true
waystoneDropdownFrame.ZIndex = 13
local waystoneDropdownFrameCorner = Instance.new("UICorner", waystoneDropdownFrame)
waystoneDropdownFrameCorner.CornerRadius = UDim.new(0, 6)

local waystoneScroll = Instance.new("ScrollingFrame", waystoneDropdownFrame)
waystoneScroll.Size = UDim2.new(1, -10, 1, -10)
waystoneScroll.Position = UDim2.new(0, 5, 0, 5)
waystoneScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
waystoneScroll.BackgroundTransparency = 1
waystoneScroll.ScrollBarThickness = 4
waystoneScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
waystoneScroll.BorderSizePixel = 0
waystoneScroll.ScrollingDirection = Enum.ScrollingDirection.Y
waystoneScroll.ZIndex = 14

local waystoneLayout = Instance.new("UIListLayout", waystoneScroll)
waystoneLayout.SortOrder = Enum.SortOrder.LayoutOrder
waystoneLayout.Padding = UDim.new(0, 5)
waystoneLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    waystoneScroll.CanvasSize = UDim2.new(0, 0, 0, waystoneLayout.AbsoluteContentSize.Y + 10)
end)

-- Floor Teleport Dropdown UI
local floorTeleportDropdown = Instance.new("TextButton", frame)
floorTeleportDropdown.Size = UDim2.new(1, -20, 0, 35)
floorTeleportDropdown.Position = UDim2.new(0, 10, 0, 495 + 80) -- below waystone
floorTeleportDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
floorTeleportDropdown.TextColor3 = Color3.new(1, 1, 1)
floorTeleportDropdown.Font = Enum.Font.Gotham
floorTeleportDropdown.TextSize = 14
floorTeleportDropdown.Text = "Teleport: Select Floor..."
floorTeleportDropdown.ZIndex = 12
local floorTeleportDropdownCorner = Instance.new("UICorner", floorTeleportDropdown)
floorTeleportDropdownCorner.CornerRadius = UDim.new(0, 6)

local floorTeleportDropdownFrame = Instance.new("Frame", frame)
floorTeleportDropdownFrame.Position = UDim2.new(0, 10, 0, 495 + 110)
floorTeleportDropdownFrame.Size = UDim2.new(1, -20, 0, 120)
floorTeleportDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
floorTeleportDropdownFrame.BorderSizePixel = 0
floorTeleportDropdownFrame.Visible = false
floorTeleportDropdownFrame.ClipsDescendants = true
floorTeleportDropdownFrame.ZIndex = 13
local floorTeleportDropdownFrameCorner = Instance.new("UICorner", floorTeleportDropdownFrame)
floorTeleportDropdownFrameCorner.CornerRadius = UDim.new(0, 6)

local floorTeleportScroll = Instance.new("ScrollingFrame", floorTeleportDropdownFrame)
floorTeleportScroll.Size = UDim2.new(1, -10, 1, -10)
floorTeleportScroll.Position = UDim2.new(0, 5, 0, 5)
floorTeleportScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
floorTeleportScroll.BackgroundTransparency = 1
floorTeleportScroll.ScrollBarThickness = 4
floorTeleportScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
floorTeleportScroll.BorderSizePixel = 0
floorTeleportScroll.ScrollingDirection = Enum.ScrollingDirection.Y
floorTeleportScroll.ZIndex = 14

local floorTeleportLayout = Instance.new("UIListLayout", floorTeleportScroll)
floorTeleportLayout.SortOrder = Enum.SortOrder.LayoutOrder
floorTeleportLayout.Padding = UDim.new(0, 5)
floorTeleportLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    floorTeleportScroll.CanvasSize = UDim2.new(0, 0, 0, floorTeleportLayout.AbsoluteContentSize.Y + 10)
end)

-- Floor Teleport logic
local teleportFloorEvent = ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Teleport", 9e9):WaitForChild("Teleport", 9e9)
local voidTowerEvent = ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("TowerDungeon", 9e9):WaitForChild("StartDungeon", 9e9)

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
            game:GetService("TweenService"):Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        end)

        option.MouseLeave:Connect(function()
            game:GetService("TweenService"):Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        end)
    end
end)

-- Draggable UI
local dragging = false
local dragStart = nil
local startPos = nil

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local hit = input.Position
        local objects = screenGui:GetDescendants()
        for _, obj in ipairs(objects) do
            if obj:IsA("GuiButton") and obj.Visible then
                local pos = obj.AbsolutePosition
                local size = obj.AbsoluteSize
                if hit.X >= pos.X and hit.X <= pos.X + size.X and hit.Y >= pos.Y and hit.Y <= pos.Y + size.Y then
                    return
                end
            end
        end
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

frame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Update Checkbox UI
local function updateFollowCheckboxUI()
    followCheckbox.BackgroundColor3 = stopFollowing and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 255, 60)
    followLabel.Text = stopFollowing and "Auto Farm: OFF" or "Auto Farm: ON"
end

local function updateKillAuraCheckboxUI()
    killAuraCheckbox.BackgroundColor3 = killAuraEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    killAuraLabel.Text = killAuraEnabled and "Kill Aura: ON" or "Kill Aura: OFF"
end

local function updateAutoQuestCheckboxUI()
    autoQuestCheckbox.BackgroundColor3 = global_isEnabled_autoquest and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoQuestLabel.Text = global_isEnabled_autoquest and "Auto Quest: ON  ( First choose quest below to work)" or "Auto Quest: OFF  ( First choose quest below to work)"
end

local function updateAutoCollectCheckboxUI()
    autoCollectCheckbox.BackgroundColor3 = autoCollectEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoCollectLabel.Text = autoCollectEnabled and "Auto Collect: ON" or "Auto Collect: OFF"
end

local function updateAutoSkillCheckboxUI()
    autoSkillCheckbox.BackgroundColor3 = autoSkillEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoSkillLabel.Text = autoSkillEnabled and "Auto Skill: ON" or "Auto Skill: OFF"
end

local function updateAutoClaimCheckboxUI()
    autoClaimCheckbox.BackgroundColor3 = autoClaimEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoClaimLabel.Text = autoClaimEnabled and "Auto Claim Chest: ON  ( need to manually click the 'Take' Button)" or "Auto Claim Chest: OFF  ( need to manually click the 'Take' Button)"
end

local function updateAutoDismantleCheckboxUI()
    autoDismantleCheckbox.BackgroundColor3 = autoDismantleEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoDismantleLabel.Text = autoDismantleEnabled and "Auto Dismantle: ON" or "Auto Dismantle: OFF"
end

local function updateAutoDailyQuestsCheckboxUI()
    autoDailyQuestsCheckbox.BackgroundColor3 = autoDailyQuestsEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoDailyQuestsLabel.Text = autoDailyQuestsEnabled and "Auto Claim Daily Quests: ON" or "Auto Claim Daily Quests: OFF"
end

local function updateAutoAchievementCheckboxUI()
    autoAchievementCheckbox.BackgroundColor3 = autoAchievementEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    autoAchievementLabel.Text = autoAchievementEnabled and "Auto Claim Achievement: ON" or "Auto Claim Achievement: OFF"
end

local function updateOpenEnchantUIManualCheckboxUI()
    openEnchantUIManualCheckbox.BackgroundColor3 = openEnchantUIManualEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    openEnchantUIManualLabel.Text = openEnchantUIManualEnabled and "Open Enchant UI: ON" or "Open Enchant UI: OFF"
end

local function updateOpenMountsUIManualCheckboxUI()
    openMountsUIManualCheckbox.BackgroundColor3 = openMountsUIManualEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    openMountsUIManualLabel.Text = openMountsUIManualEnabled and "Open Mounts UI: ON" or "Open Mounts UI: OFF"
end

local function updateOpenSmithingUIManualCheckboxUI()
    openSmithingUIManualCheckbox.BackgroundColor3 = openSmithingUIManualEnabled and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
    openSmithingUIManualLabel.Text = openSmithingUIManualEnabled and "Open Smithing UI: ON" or "Open Smithing UI: OFF"
end

-- Auto Dismantle Function
local function AutoDismantleByMaxRarity(maxRarityIndex)
    for _, item in ipairs(inventory:GetChildren()) do
        local success, rarity = pcall(function()
            return itemsModule:GetRarity(item)
        end)
        if success and rarity <= maxRarityIndex then
            dismantleRemote:FireServer(item)
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

    for i, rarity in ipairs(rarities) do
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

        option.MouseButton1Click:Connect(function()
            rarityIndex = i
            selectedRarity = rarities[rarityIndex]
            dismantleDropdown.Text = "Rarity: " .. selectedRarity .. " and below"
            dismantleDropdownFrame.Visible = false
            for _, child in ipairs(dismantleScroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            if autoDismantleEnabled then
                AutoDismantleByMaxRarity(rarityMap[selectedRarity])
            end
        end)

        option.MouseEnter:Connect(function()
            TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        end)
        option.MouseLeave:Connect(function()
            TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        end)
    end
end)

-- Auto Dismantle Checkbox toggle
autoDismantleCheckbox.MouseButton1Click:Connect(function()
    autoDismantleEnabled = not autoDismantleEnabled
    updateAutoDismantleCheckboxUI()
    if autoDismantleEnabled then
        AutoDismantleByMaxRarity(rarityMap[selectedRarity])
    end
end)

-- Function to open chest and claim reward
local function openAndClaimChest(chestModel)
    local root = chestModel:FindFirstChild("RootPart")
    if not root then return end

    local prompt = root:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt then return end

    prompt.MaxActivationDistance = autoClaimEnabled and 500 or 10

    local dist = (hrp.Position - root.Position).Magnitude
    if dist <= TRIGGER_DISTANCE then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.15)
            prompt:InputHoldEnd()
        end)

        task.delay(2.5, function()
            pcall(function()
                ChestRemote:FireServer(chestModel)
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
    if not mobsFolder then return end

    local mobSet = {}
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        mobSet[mob.Name] = true
    end

    local questIDs = {}
    for id, data in pairs(QuestList) do
        if data.Type == "Kill" and mobSet[data.Target] then
            table.insert(questIDs, {id = id, level = data.Level})
        end
    end
    table.sort(questIDs, function(a, b)
        return a.level < b.level
    end)

    for _, entry in ipairs(questIDs) do
        local id = entry.id
        local data = QuestList[id]
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

        btn.MouseButton1Click:Connect(function()
            selectedQuestId = tonumber(id)
            local success, err = pcall(function()
                ReplicatedStorage.Systems.Quests.AcceptQuest:FireServer(selectedQuestId)
            end)
            if not success then
                warn("Failed to accept quest ID " .. tostring(selectedQuestId) .. ": " .. tostring(err))
            end
            selectedMobName = data.Target
            mobDropdown.Text = "Mob: " .. selectedMobName
            questDropdown.Text = "Quest: " .. label
            questDropdownFrame.Visible = false
            for _, child in ipairs(questScroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
        end)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
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
    if not mobsFolder then return end

    local added = {}
    for _, mob in ipairs(mobsFolder:GetChildren()) do
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

            option.MouseButton1Click:Connect(function()
                selectedMobName = mob.Name
                mobDropdown.Text = "Mob: " .. mob.Name
                dropdownFrame.Visible = false
                for _, child in pairs(scrollbar:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
            end)

            option.MouseEnter:Connect(function()
                TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            end)
            option.MouseLeave:Connect(function()
                TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
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

    for _, child in pairs(Waystones:GetChildren()) do
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
                local args = { Waystones:WaitForChild(option.Name, 9e9) }
                teleportEvent:FireServer(unpack(args))
                for _, child in ipairs(waystoneScroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
            end)

            option.MouseEnter:Connect(function()
                TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            end)
            option.MouseLeave:Connect(function()
                TweenService:Create(option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
            end)
        end
    end
end)


-- Unlock All Waystones Button Click
unlockWaystonesButton.MouseButton1Click:Connect(function()
    unlockAllWaystones()
end)
-- Tween to mob
local function tweenTo(position, speed)
    if tween then tween:Cancel() end
    local distance = (position - hrp.Position).Magnitude
    local duration = distance / speed
    tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(position)
    })
    tween:Play()
    AntiCheat:UpdatePosition(player, hrp.CFrame)
    return duration
end

-- Hover logic
local function activateHover(mobHRP)
    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bodyVelocity.P = 3000
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = hrp
    end

    lastVelocity = bodyVelocity.Velocity

    RunService:BindToRenderStep("FollowMobStep", Enum.RenderPriority.Character.Value, function()
        if stopFollowing or not mobHRP or not mobHRP.Parent then return end
        local targetPos = mobHRP.Position + Vector3.new(0, HEIGHT_OFFSET, -FOLLOW_DISTANCE)
        local offset = targetPos - hrp.Position
        if offset.Magnitude > 0.5 then
            local desired = offset.Unit * 50
            local smooth = lastVelocity:Lerp(desired, 0.2)
            bodyVelocity.Velocity = smooth
            lastVelocity = smooth
        else
            bodyVelocity.Velocity = Vector3.zero
            lastVelocity = Vector3.zero
        end
        AntiCheat:UpdatePosition(player, hrp.CFrame)
    end)
end

local function deactivateHover()
    RunService:UnbindFromRenderStep("FollowMobStep")
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    lastVelocity = Vector3.zero
end

-- Find closest mob
local function findClosestMob()
    if not mobsFolder then return nil end
    local closest, minDist = nil, math.huge
    for _, mob in pairs(mobsFolder:GetChildren()) do
        if mob:IsA("Model") and string.find(mob.Name, selectedMobName) then
            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
            local mobHum = mob:FindFirstChild("Humanoid")
            if mobHRP and (not mobHum or mobHum.Health > 0) then
                local dist = (mobHRP.Position - hrp.Position).Magnitude
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
    stopFollowing = false
    humanoid.AutoRotate = false
    task.spawn(function()
        while not stopFollowing do
            local mob = findClosestMob()
            if mob then
                local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                if mobHRP then
                    local target = mobHRP.Position + Vector3.new(0, HEIGHT_OFFSET, -FOLLOW_DISTANCE)
                    local dist = (hrp.Position - target).Magnitude
                    local speed = BASE_SPEED
                    if dist > DISTANCE_THRESHOLD then speed = BASE_SPEED
                    elseif dist > 60 then speed = 70
                    elseif dist > 40 then speed = 90
                    else speed = 110 end
                    speed = math.clamp(speed, BASE_SPEED, SPEED_CAP)
                    local duration = tweenTo(target, speed)
                    task.wait(duration + 0.1)
                    if not stopFollowing and mobHRP and mobHRP.Parent then
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
    stopFollowing = true
    humanoid.AutoRotate = true
    if tween then tween:Cancel() tween = nil end
    deactivateHover()
end

-- Auto Skill Helper Functions
local function getNearestMob(maxDistance)
    local closest, minDist = nil, maxDistance or 100
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

    for _, mob in ipairs(Workspace:WaitForChild("Mobs"):GetChildren()) do
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
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not target then return end
    local dir = (target.Position - hrp.Position).Unit
    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(dir.X, 0, dir.Z))
end

local function getSkillName()
    return SkillSystem:GetSkillInActiveSlot(player, tostring(SKILL_SLOT))
end

local function getCooldown(skillName)
    local data = SkillSystem:GetSkillData(skillName)
    return data and data.Cooldown or FALLBACK_COOLDOWN
end

local function multiHitAttack(target, skillName)
    local skillData = SkillSystem:GetSkillData(skillName)
    local hits = (skillData and skillData.Hits) or {}

    if #hits == 0 then
        SkillAttackRemote:FireServer({ target }, skillName, 1)
        return
    end

    for hitIndex = 1, #hits do
        SkillAttackRemote:FireServer({ target }, skillName, hitIndex)
        task.wait(0.05)
    end
end

-- Follow Checkbox toggle
followCheckbox.MouseButton1Click:Connect(function()
    stopFollowing = not stopFollowing
    updateFollowCheckboxUI()
    if not stopFollowing then
        startFollowing()
    else
        stopFollowingNow()
    end
end)

-- Kill Aura Checkbox toggle
killAuraCheckbox.MouseButton1Click:Connect(function()
    killAuraEnabled = not killAuraEnabled
    updateKillAuraCheckboxUI()
end)

-- Auto Quest Checkbox toggle
autoQuestCheckbox.MouseButton1Click:Connect(function()
    global_isEnabled_autoquest = not global_isEnabled_autoquest
    updateAutoQuestCheckboxUI()
end)

-- Auto Collect Checkbox toggle
autoCollectCheckbox.MouseButton1Click:Connect(function()
    autoCollectEnabled = not autoCollectEnabled
    updateAutoCollectCheckboxUI()
end)

-- Auto Skill Checkbox toggle
autoSkillCheckbox.MouseButton1Click:Connect(function()
    autoSkillEnabled = not autoSkillEnabled
    updateAutoSkillCheckboxUI()
end)

-- Auto Claim Checkbox toggle
autoClaimCheckbox.MouseButton1Click:Connect(function()
    autoClaimEnabled = not autoClaimEnabled
    updateAutoClaimCheckboxUI()
end)

-- Auto Daily Quests Checkbox toggle
autoDailyQuestsCheckbox.MouseButton1Click:Connect(function()
    autoDailyQuestsEnabled = not autoDailyQuestsEnabled
    updateAutoDailyQuestsCheckboxUI()
    if autoDailyQuestsEnabled then
        for i = 1, 10 do
            local success, err = pcall(function()
                ClaimQuestRemote:FireServer(unpack({i}))
            end)
        end
        for _, milestone in ipairs({1, 3, 6}) do
            local success, err = pcall(function()
                ClaimRewardRemote:FireServer(milestone)
            end)
        end
    end
end)

-- Auto Achievement Checkbox toggle
autoAchievementCheckbox.MouseButton1Click:Connect(function()
    autoAchievementEnabled = not autoAchievementEnabled
    updateAutoAchievementCheckboxUI()
end)

-- New Checkbox Toggles for Manual UI Opening
openEnchantUIManualCheckbox.MouseButton1Click:Connect(function()
    openEnchantUIManualEnabled = not openEnchantUIManualEnabled
    if openEnchantUIManualEnabled then
        openUI(enchantingStation)
        openMountsUIManualEnabled = false
        openSmithingUIManualEnabled = false
        updateOpenMountsUIManualCheckboxUI()
        updateOpenSmithingUIManualCheckboxUI()
    end
    updateOpenEnchantUIManualCheckboxUI()
end)

openMountsUIManualCheckbox.MouseButton1Click:Connect(function()
    openMountsUIManualEnabled = not openMountsUIManualEnabled
    if openMountsUIManualEnabled then
        openUI(mountsStation)
        openEnchantUIManualEnabled = false
        openSmithingUIManualEnabled = false
        updateOpenEnchantUIManualCheckboxUI()
        updateOpenSmithingUIManualCheckboxUI()
    end
    updateOpenMountsUIManualCheckboxUI()
end)

openSmithingUIManualCheckbox.MouseButton1Click:Connect(function()
    openSmithingUIManualEnabled = not openSmithingUIManualEnabled
    if openSmithingUIManualEnabled then
        openUI(smithingStation)
        openEnchantUIManualEnabled = false
        openMountsUIManualEnabled = false
        updateOpenEnchantUIManualCheckboxUI()
        updateOpenMountsUIManualCheckboxUI()
    end
    updateOpenSmithingUIManualCheckboxUI()
end)

-- Auto Quest Logic
local Profile = require(ReplicatedStorage.Systems.Profile)
local Quests = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Quests")
local CompleteQuest = Quests:WaitForChild("CompleteQuest")
local AcceptQuest = Quests:WaitForChild("AcceptQuest")

local function getActiveQuestId()
    local success, profile = pcall(function()
        return Profile:GetProfile(player)
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
        if global_isEnabled_autoquest and selectedQuestId then
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
                        AcceptQuest:FireServer(selectedQuestId)
                    end)
                    if not success then
                        warn("Failed to accept quest ID " .. tostring(selectedQuestId) .. ": " .. tostring(err))
                    end
                end
            else
                local success, err = pcall(function()
                    AcceptQuest:FireServer(selectedQuestId)
                end)
                if not success then
                    warn("Failed to accept quest ID " .. tostring(selectedQuestId) .. ": " .. tostring(err))
                end
            end
        end
        task.wait(QUEST_CHECK_INTERVAL)
    end
end)

-- Auto Daily Quests Logic
local function claimDailyQuestsAndRewards()
    if not autoDailyQuestsEnabled then return end
    for i = 1, 6 do
        local success, err = pcall(function()
            ClaimQuestRemote:FireServer(unpack({i}))
        end)
    end
    for _, milestone in ipairs({1, 3, 6}) do
        local success, err = pcall(function()
            ClaimRewardRemote:FireServer(milestone)
        end)
    end
end

-- Trigger Auto Daily Quests on load (if enabled) and on UpdateEvent
task.spawn(function()
    if autoDailyQuestsEnabled then
        task.wait(3)
        claimDailyQuestsAndRewards()
    end
end)

UpdateEvent.OnClientEvent:Connect(function()
    if autoDailyQuestsEnabled then
        claimDailyQuestsAndRewards()
    end
end)

-- Auto Achievement Logic
task.spawn(function()
    while true do
        if autoAchievementEnabled then
            for id = 1, 50 do
                local success, err = pcall(function()
                    claimRemote:FireServer(id)
                end)
            end
        end
        task.wait(2)
    end
end)

-- Kill Aura loop
task.spawn(function()
    while true do
        if killAuraEnabled and character and character:FindFirstChild("HumanoidRootPart") then
            local targets = {}
            for _, mob in pairs(mobsFolder:GetChildren()) do
                local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                if mobHRP and (mobHRP.Position - hrp.Position).Magnitude <= KILL_AURA_RANGE then
                    table.insert(targets, mob)
                    DoEffect:FireServer("SlashHit", mobHRP.Position, { mobHRP.CFrame })
                end
            end
            if #targets > 0 then
                PlayerAttack:FireServer(targets)
            end
        end
        task.wait(KILL_AURA_DELAY)
    end
end)

-- Auto Collect loop
task.spawn(function()
    while true do
        if autoCollectEnabled and AUTO_COLLECT_ENABLED then
            character = player.Character or player.CharacterAdded:Wait()
            hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(CHECK_INTERVAL) continue end

            for _, drop in pairs(dropCache) do
                local model = drop.model
                local itemRef = drop.itemRef
                if model and model.PrimaryPart and itemRef then
                    local distance = (hrp.Position - model.PrimaryPart.Position).Magnitude
                    if distance <= COLLECT_RADIUS then
                        pcall(function()
                            DropsModule:Pickup(player, itemRef)
                            if autoDismantleEnabled then
                                task.wait(0.1)
                                AutoDismantleByMaxRarity(rarityMap[selectedRarity])
                            end
                        end)
                    end
                end
            end
        end
        task.wait(CHECK_INTERVAL)
    end
end)

-- Auto Claim Chest loop
task.spawn(function()
    while true do
        if autoClaimEnabled and AUTO_CLAIM_ENABLED then
            character = player.Character or player.CharacterAdded:Wait()
            hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(CHECK_INTERVAL) continue end

            for _, chest in ipairs(Workspace:GetChildren()) do
                if chest:IsA("Model") and chest:FindFirstChild("RootPart") then
                    openAndClaimChest(chest)
                    if autoDismantleEnabled then
                        task.wait(0.1)
                        AutoDismantleByMaxRarity(rarityMap[selectedRarity])
                    end
                end
            end
        end
        task.wait(CHECK_INTERVAL)
    end
end)

-- Auto Skill loop
task.spawn(function()
    while true do
        if autoSkillEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local skill = getSkillName()
            if skill and skill ~= "" then
                local cooldown = getCooldown(skill)
                local last = lastUsed[skill] or 0
                if tick() - last >= cooldown then
                    local target = getNearestMob()
                    if target then
                        faceTarget(target.HumanoidRootPart)
                        pcall(function()
                            UseSkillRemote:FireServer(skill)
                            multiHitAttack(target, skill)
                        end)
                        lastUsed[skill] = tick()
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
end)

-- Respawn cleanup
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
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
