-- Cleanup on reload
if getgenv().SeisenHubLoaded then
    if getgenv().SeisenHubUI and getgenv().SeisenHubUI.Parent then
        pcall(function()
            getgenv().SeisenHubUI:Destroy()
        end)
    end
    getgenv().SeisenHubRunning = false
    task.wait(0.25)
end

getgenv().SeisenHubLoaded = true
getgenv().SeisenHubRunning = true

-- Load Obsidian UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local Window = Library:CreateWindow({
    Title = "Seisen Hub",
    Footer = "Anime Eternal",
    ToggleKeybind = Enum.KeyCode.RightControl,
    Center = true,
    AutoShow = true,
    MobileButtonsSide = "Right"
})

-- Store ScreenGui for cleanup
getgenv().SeisenHubUI = Library.Gui

-- Tabs & Groups
local MainTab = Window:AddTab("Main", "box")
local LeftGroupbox = MainTab:AddLeftGroupbox("Automation")
local RollToken = MainTab:AddLeftGroupbox("Auto Roll Tokens")
local StatsGroupbox = MainTab:AddLeftGroupbox("Auto Stats")
local RightGroupbox = MainTab:AddRightGroupbox("Auto Roll")
local RewardsGroupbox = MainTab:AddRightGroupbox("Auto Rewards")
local TeleportTab = Window:AddTab("Teleport & Dungeon")
local TPGroupbox = TeleportTab:AddLeftGroupbox("Main Teleport")
local DungeonGroupbox = TeleportTab:AddRightGroupbox("Auto Dungeon")
local UP = Window:AddTab("Upgrades")
local UpgradeGroupbox = UP:AddLeftGroupbox("Upgrades")
local Upgrade2 = UP:AddRightGroupbox("Upgrades 2")
local RollUpgrade = UP:AddLeftGroupbox("Auto Roll and Upgrade")
local UISettings = Window:AddTab("UI Settings")
local UnloadGroupbox = UISettings:AddLeftGroupbox("Utilities")

-- Services & Variables
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ToServer = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("To_Server", 9e9)
local monstersFolder = Workspace:WaitForChild("Debris", 9e9):WaitForChild("Monsters", 9e9)

local localPlayer = Players.LocalPlayer
local teleportOffset = Vector3.new(0, 0, -3)

local attackCooldown = 0.05
local currentTarget = nil

local configFolder = "SeisenHub"
local configFile = configFolder .. "/seisen_hub_AE.txt"
local HttpService = game:GetService("HttpService")

-- Ensure folder exists
if not isfolder(configFolder) then
    makefolder(configFolder)
end

-- Initialize variables with explicit defaults
local isAuraEnabled = false
local fastKillAuraEnabled = false
local slowKillAuraEnabled = false
local autoRankEnabled = false
local autoAcceptAllQuestsEnabled = false
local autoRollDragonRaceEnabled = false
local autoRollSaiyanEvolutionEnabled = false
local autoRollEnabled = false
local autoDeleteEnabled = false
local autoClaimAchievementsEnabled = false
local autoRollSwordsEnabled = false
local autoRollPirateCrewEnabled = false
local selectedStar = "Star_1"
local selectedDeleteStar = "Star_1"
local delayBetweenRolls = 0.5
local selectedRarities = {}
local autoStatsRunning = false
local isAutoTimeRewardEnabled = false
local isAutoDailyChestEnabled = false
local isAutoVipChestEnabled = false
local isAutoGroupChestEnabled = false
local isAutoPremiumChestEnabled = false
local disableNotificationsEnabled = false
local autoUpgradeEnabled = false
local autoEnterDungeon = false
local selectedStat = "Damage"
local autoHakiUpgradeEnabled = false
local autoRollDemonFruitsEnabled = false
local autoAttackRangeUpgradeEnabled = false
local config = getgenv().SeisenHubConfig or {}
local selectedDungeons = config.SelectedDungeons or {"Dungeon_Easy"}

local stats = {
    "Damage",
    "Energy",
    "Coins",
    "Luck"
}

-- Load config if file exists
if isfile(configFile) then
    print("Config file found:", readfile(configFile))
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(configFile))
    end)
    if ok and type(data) == "table" then
        print("Parsed config:", data)
        for k, v in pairs(data) do
            config[k] = v
        end
    else
        print("Config parse error:", data)
    end
else
    print("Config file missing")
end

-- Load config values with defaults
isAuraEnabled = config.AutoFarmToggle or false
fastKillAuraEnabled = config.FastKillAuraToggle or false
slowKillAuraEnabled = config.SlowKillAuraToggle or false
autoRankEnabled = config.AutoRankToggle or false
autoAcceptAllQuestsEnabled = config.AutoAcceptAllQuestsToggle or false
autoRollDragonRaceEnabled = config.AutoRollDragonRaceToggle or false
autoRollSaiyanEvolutionEnabled = config.AutoRollSaiyanEvolutionToggle or false
autoRollEnabled = config.AutoRollStarsToggle or false
autoDeleteEnabled = config.AutoDeleteUnitsToggle or false
autoClaimAchievementsEnabled = config.AutoClaimAchievement or false
autoRollSwordsEnabled = config.AutoRollSwordsToggle or false
autoRollPirateCrewEnabled = config.AutoRollPirateCrewToggle or false
selectedStar = config.SelectStarDropdown or "Star_1"
selectedDeleteStar = config.SelectDeleteStarDropdown or "Star_1"
delayBetweenRolls = config.DelayBetweenRollsSlider or 0.5
selectedRarities = config.AutoDeleteRaritiesDropdown or {}
autoStatsRunning = config.AutoAssignStatToggle or false
isAutoTimeRewardEnabled = config.AutoClaimTimeRewardToggle or false
isAutoDailyChestEnabled = config.AutoClaimDailyChestToggle or false
isAutoVipChestEnabled = config.AutoClaimVipChestToggle or false
isAutoGroupChestEnabled = config.AutoClaimGroupChestToggle or false
isAutoPremiumChestEnabled = config.AutoClaimPremiumChestToggle or false
disableNotificationsEnabled = config.DisableNotificationsToggle or false
autoUpgradeEnabled = config.AutoUpgradeToggle or false
autoEnterDungeon = config.AutoEnterDungeonToggle or false
selectedStat = config.AutoStatSingleDropdown or "Damage"
autoHakiUpgradeEnabled = config.AutoHakiUpgradeToggle or false
autoRollDemonFruitsEnabled = config.AutoRollDemonFruitsToggle or false
autoAttackRangeUpgradeEnabled = config.AutoAttackRangeUpgradeToggle or false
pointsPerSecond = config.PointsPerSecondSlider or 1 -- 
selectedDungeons = config.SelectedDungeons or {"Dungeon_Easy"}

-- Helper to save config
local function saveConfig()
    config.SelectedDungeons = selectedDungeons
    config.AutoAssignStatToggle = autoStatsRunning
    config.AutoStatSingleDropdown = selectedStat
    config.PointsPerSecondSlider = pointsPerSecond -- Save new variable
    getgenv().SeisenHubConfig = config
    writefile(configFile, HttpService:JSONEncode(config))
    print("Config saved")
end

-- ========== Automations =========

local function disableAllAurasExcept(except)
    if except ~= "AutoFarm" then isAuraEnabled = false end
    if except ~= "FastKillAura" then fastKillAuraEnabled = false end
    if except ~= "SlowKillAura" then slowKillAuraEnabled = false end
end

-- Get nearest monster
local function getNearestValidMonster()
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end

    local closest, closestDist = nil, math.huge
    local myPos = character.HumanoidRootPart.Position

    for _, monster in pairs(monstersFolder:GetChildren()) do
        local hrp = monster:FindFirstChild("HumanoidRootPart")
        local hum = monster:FindFirstChild("Humanoid")
        if monster:IsA("Model") and hrp and hum and hum.Health > 0 then
            local dist = (hrp.Position - myPos).Magnitude
            if dist < closestDist then
                closest = monster
                closestDist = dist
            end
        end
    end

    return closest
end

-- Teleport to monster
local function teleportToMonster(monster)
    local character = localPlayer.Character
    local myHRP = character and character:FindFirstChild("HumanoidRootPart")
    local targetHRP = monster and monster:FindFirstChild("HumanoidRootPart")
    if myHRP and targetHRP then
        pcall(function()
            myHRP.CFrame = CFrame.new(targetHRP.Position + teleportOffset)
            print("Teleported to monster:", monster.Name)
        end, function(err)
            print("Teleport error:", err)
        end)
    end
end

-- Task functions
local function startAutoFarm()
    task.spawn(function()
        while getgenv().SeisenHubRunning and isAuraEnabled do
            local char = localPlayer.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")

            if not currentTarget or not currentTarget:IsDescendantOf(monstersFolder)
                or not currentTarget:FindFirstChild("Humanoid")
                or currentTarget.Humanoid.Health <= 0 then
                currentTarget = getNearestValidMonster()
                if currentTarget then teleportToMonster(currentTarget) end
            end

            if currentTarget and myHRP then
                local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
                local hum = currentTarget:FindFirstChild("Humanoid")

                if hrp and hum and hum.Health > 0 then
                    local args = {
                        [1] = {
                            ["Id"] = currentTarget.Name,
                            ["Action"] = "_Mouse_Click"
                        }
                    }
                    pcall(function()
                        ToServer:FireServer(unpack(args))
                        print("Attacked monster:", currentTarget.Name)
                    end, function(err)
                        print("Attack error:", err)
                    end)
                end
            end
            task.wait(attackCooldown)
        end
    end)
end

local function startFastKillAura()
    task.spawn(function()
        local argsActivator = {
            [1] = {
                ["Gamepass"] = true,
                ["Action"] = "PromptPurchase",
                ["Name"] = "Fast_Clicker",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(argsActivator))
            print("Activated Fast Clicker")
        end, function(err)
            print("Fast Clicker activation error:", err)
        end)
        while fastKillAuraEnabled and getgenv().SeisenHubRunning do
            local monster = getNearestValidMonster()
            if monster then
                local hum = monster:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local argsAttack = {
                        [1] = {
                            ["Id"] = monster.Name,
                            ["Action"] = "_Mouse_Click",
                        }
                    }
                    pcall(function()
                        ToServer:FireServer(unpack(argsAttack))
                        print("Fast Kill Aura attacked:", monster.Name)
                    end, function(err)
                        print("Fast Kill Aura attack error:", err)
                    end)
                end
            end
            task.wait(0.01)
        end
    end)
end

local function startSlowKillAura()
    task.spawn(function()
        local argsActivator = {
            [1] = {
                ["Value"] = true,
                ["Path"] = {
                    [1] = "Settings",
                    [2] = "Is_Auto_Clicker",
                },
                ["Action"] = "Settings",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(argsActivator))
            print("Activated Slow Clicker")
        end, function(err)
            print("Slow Clicker activation error:", err)
        end)
        while slowKillAuraEnabled and getgenv().SeisenHubRunning do
            local monster = getNearestValidMonster()
            if monster then
                local hum = monster:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local argsAttack = {
                        [1] = {
                            ["Id"] = monster.Name,
                            ["Action"] = "_Mouse_Click",
                        }
                    }
                    pcall(function()
                        ToServer:FireServer(unpack(argsAttack))
                        print("Slow Kill Aura attacked:", monster.Name)
                    end, function(err)
                        print("Slow Kill Aura attack error:", err)
                    end)
                end
            end
            task.wait(0.05)
        end
    end)
end

local function startAutoRank()
    task.spawn(function()
        while autoRankEnabled and getgenv().SeisenHubRunning do
            local args = {
                [1] = {
                    ["Upgrading_Name"] = "Rank",
                    ["Action"] = "_Upgrades",
                    ["Upgrade_Name"] = "Rank_Up",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
                print("Rank up attempted")
            end, function(err)
                print("Rank up error:", err)
            end)
            task.wait(1)
        end
    end)
end

local function startAutoQuests()
    task.spawn(function()
        while autoAcceptAllQuestsEnabled and getgenv().SeisenHubRunning do
            for questId = 1, 99 do
                local argsAccept = {
                    [1] = {
                        ["Id"] = tostring(questId),
                        ["Type"] = "Accept",
                        ["Action"] = "_Quest",
                    }
                }
                pcall(function()
                    ToServer:FireServer(unpack(argsAccept))
                    print("Accepted quest:", questId)
                end, function(err)
                    print("Quest accept error:", err)
                end)
                task.wait(0.05)
                local argsComplete = {
                    [1] = {
                        ["Id"] = tostring(questId),
                        ["Type"] = "Complete",
                        ["Action"] = "_Quest",
                    }
                }
                pcall(function()
                    ToServer:FireServer(unpack(argsComplete))
                    print("Completed quest:", questId)
                end, function(err)
                    print("Quest complete error:", err)
                end)
                task.wait(0.05)
            end
            task.wait(2)
        end
    end)
end

local function startAutoAchievements()
    task.spawn(function()
        local achievements = {
            Total_Energy = 20,
            Total_Coins = 15,
            Friends_Bonus = 5,
            Time_Played = 8,
            Stars = 10,
            Defeats = 13,
            Dungeon_Easy = 5,
            Total_Dungeon_Easy = 5,
            Dungeon_Medium = 5,
            Total_Dungeon_Medium = 5,
            Dungeon_Hard = 5,
            Total_Dungeon_Hard = 5,
            Dungeon_Insane = 5,
            Total_Dungeon_Insane = 5,
            Dungeon_Crazy = 5,
            Total_Dungeon_Crazy = 5,
            Leaf_Raid = 9,
            Titan_Defense = 9,
        }

        local function toRoman(num)
            local romanNumerals = {
                [1] = "I", [2] = "II", [3] = "III", [4] = "IV",
                [5] = "V", [6] = "VI", [7] = "VII", [8] = "VIII",
                [9] = "IX", [10] = "X", [11] = "XI", [12] = "XII",
                [13] = "XIII", [14] = "XIV", [15] = "XV", [16] = "XVI",
                [17] = "XVII", [18] = "XVIII", [19] = "XIX", [20] = "XX"
            }
            return romanNumerals[num]
        end

        while autoClaimAchievementsEnabled and getgenv().SeisenHubRunning do
            for name, maxLevel in pairs(achievements) do
                for i = 1, maxLevel do
                    local id = name .. "_" .. toRoman(i)
                    local args = {
                        [1] = {
                            ["Action"] = "Achievements",
                            ["Id"] = id
                        }
                    }
                    pcall(function()
                        ToServer:FireServer(unpack(args))
                        print("Claimed achievement:", id)
                    end, function(err)
                        print("Achievement claim error:", err)
                    end)
                    task.wait(0.2)
                end
            end
            task.wait(3)
        end
    end)
end

local function startAutoRollDragonRace()
    task.spawn(function()
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Dragon_Race_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
            print("Unlocked Dragon Race")
        end, function(err)
            print("Dragon Race unlock error:", err)
        end)
        while getgenv().SeisenHubRunning and autoRollDragonRaceEnabled do
            local args = {
                [1] = {
                    ["Open_Amount"] = 1,
                    ["Action"] = "_Gacha_Activate",
                    ["Name"] = "Dragon_Race",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
                print("Rolled Dragon Race")
            end, function(err)
                print("Dragon Race roll error:", err)
            end)
            task.wait(1)
        end
    end)
end

local function startAutoRollSaiyanEvolution()
    task.spawn(function()
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Saiyan_Evolution_Unlocker",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
            print("Unlocked Saiyan Evolution")
        end, function(err)
            print("Saiyan Evolution unlock error:", err)
        end)
        while getgenv().SeisenHubRunning and autoRollSaiyanEvolutionEnabled do
            local args = {
                [1] = {
                    ["Open_Amount"] = 1,
                    ["Action"] = "_Gacha_Activate",
                    ["Name"] = "Saiyan_Evolution",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
                print("Rolled Saiyan Evolution")
            end, function(err)
                print("Saiyan Evolution roll error:", err)
            end)
            task.wait(1)
        end
    end)
end

local function startAutoRollStars()
    task.spawn(function()
        while getgenv().SeisenHubRunning and autoRollEnabled do
            pcall(function()
                local cacheArgs = {
                    [1] = {
                        ["Action"] = "Star_Cache_Request",
                        ["Name"] = selectedStar
                    }
                }
                ToServer:FireServer(unpack(cacheArgs))
                print("Star cache requested:", selectedStar)
                local rollArgs = {
                    [1] = {
                        ["Open_Amount"] = 5,
                        ["Action"] = "_Stars",
                        ["Name"] = selectedStar
                    }
                }
                ToServer:FireServer(unpack(rollArgs))
                print("Rolled stars:", selectedStar)
            end, function(err)
                print("Star roll error:", err)
            end)
            task.wait(delayBetweenRolls)
        end
    end)
end

local function startAutoDelete()
    task.spawn(function()
        while autoDeleteEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                -- Define rarity mappings for each star
                local starRarityMap = {
                    ["Star_1"] = {
                        ["1"] = {"70001", "70008"},
                        ["2"] = {"70002", "70009"},
                        ["3"] = {"70003", "70010"},
                        ["4"] = {"70004", "70011"},
                        ["5"] = {"70005", "70012"},
                        ["6"] = {"70006", "70013"}
                    },
                    ["Star_2"] = {
                        ["1"] = {"70008"},
                        ["2"] = {"70009"},
                        ["3"] = {"70010"},
                        ["4"] = {"70011"},
                        ["5"] = {"70012"},
                        ["6"] = {"70013"}
                    }
                }

                -- Disable auto-delete for all rarities of all stars
                for star, rarities in pairs(starRarityMap) do
                    for rarity, ids in pairs(rarities) do
                        for _, id in ipairs(ids) do
                            local args = {
                                [1] = {
                                    ["Value"] = false,
                                    ["Path"] = {"Settings", "AutoDelete", "Stars", id, tostring(rarity)},
                                    ["Action"] = "Settings"
                                }
                            }
                            ToServer:FireServer(unpack(args))
                        end
                    end
                end

                -- Enable auto-delete for selected rarities of the selected star
                local rarities = starRarityMap[selectedDeleteStar]
                if rarities then
                    for rarity, _ in pairs(selectedRarities) do
                        local ids = rarities[tostring(rarity)]
                        if ids then
                            for _, id in ipairs(ids) do
                                local args = {
                                    [1] = {
                                        ["Value"] = true,
                                        ["Path"] = {"Settings", "AutoDelete", "Stars", id, tostring(rarity)},
                                        ["Action"] = "Settings"
                                    }
                                }
                                pcall(function()
                                    ToServer:FireServer(unpack(args))
                                    print("Auto delete enabled for star:", selectedDeleteStar, "rarity:", rarity, "ID:", id)
                                end, function(err)
                                    print("Auto delete enable error:", err)
                                end)
                            end
                        end
                    end
                end
            end)
            task.wait(2)
        end
    end)
end

local function startAutoStats()
    task.spawn(function()
        while task.wait(1) do
            if autoStatsRunning and selectedStat then
                local statMap = {
                    Damage = "Primary_Damage",
                    Energy = "Primary_Energy",
                    Coins = "Primary_Coins",
                    Luck = "Primary_Luck"
                }
                local args = {
                    [1] = {
                        ["Name"] = statMap[selectedStat] or selectedStat,
                        ["Action"] = "Assign_Level_Stats",
                        ["Amount"] = pointsPerSecond
                    }
                }
                pcall(function()
                    ToServer:FireServer(unpack(args))
                    print("Assigned stat:", selectedStat, "Points:", pointsPerSecond)
                end, function(err)
                    print("Stat assign error:", err)
                end)
            end
        end
    end)
end

local function startAutoTimeReward()
    task.spawn(function()
        while isAutoTimeRewardEnabled and getgenv().SeisenHubRunning do
            local args = {
                [1] = {
                    ["Action"] = "_Hourly_Rewards",
                    ["Id"] = "All",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
                print("Claimed time reward")
            end, function(err)
                print("Time reward claim error:", err)
            end)
            task.wait(1)
        end
    end)
end

local function startAutoDailyChest()
    task.spawn(function()
        while isAutoDailyChestEnabled and getgenv().SeisenHubRunning do
            local args = {
                [1] = {
                    ["Action"] = "_Chest_Claim",
                    ["Name"] = "Daily",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
                print("Claimed daily chest")
            end, function(err)
                print("Daily chest claim error:", err)
            end)
            task.wait(1)
        end
    end)
end

local function startAutoVipChest()
    task.spawn(function()
        while isAutoVipChestEnabled and getgenv().SeisenHubRunning do
            local args = {
                [1] = {
                    ["Action"] = "_Chest_Claim",
                    ["Name"] = "Vip",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
                print("Claimed VIP chest")
            end, function(err)
                print("VIP chest claim error:", err)
            end)
            task.wait(1)
        end
    end)
end

local function startAutoGroupChest()
    task.spawn(function()
        while isAutoGroupChestEnabled and getgenv().SeisenHubRunning do
            local args = {
                [1] = {
                    ["Action"] = "_Chest_Claim",
                    ["Name"] = "Group",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
                print("Claimed group chest")
            end, function(err)
                print("Group chest claim error:", err)
            end)
            task.wait(1)
        end
    end)
end

local function startAutoPremiumChest()
    task.spawn(function()
        while isAutoPremiumChestEnabled and getgenv().SeisenHubRunning do
            local args = {
                [1] = {
                    ["Action"] = "_Chest_Claim",
                    ["Name"] = "Premium",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
                print("Claimed premium chest")
            end, function(err)
                print("Premium chest claim error:", err)
            end)
            task.wait(1)
        end
    end)
end

local function startAutoEnterDungeon()
    task.spawn(function()
        while autoEnterDungeon and getgenv().SeisenHubRunning do
            for _, dungeon in ipairs(selectedDungeons) do
                pcall(function()
                    print("Firing dungeon entry:", dungeon)
                    local args = {
                        [1] = {
                            ["Action"] = "_Enter_Dungeon",
                            ["Name"] = dungeon
                        }
                    }
                    ToServer:FireServer(unpack(args))
                end)
                task.wait(1) -- 1-second delay between each dungeon attempt
            end
            task.wait(5) -- 5-second delay before restarting the loop
        end
    end)
end

local function startAutoUpgrade()
    task.spawn(function()
        while autoUpgradeEnabled do
            pcall(function()
                for upgradeName, isEnabled in pairs(enabledUpgrades) do
                    if isEnabled then
                        local args = {
                            [1] = {
                                ["Upgrading_Name"] = upgradeName,
                                ["Action"] = "_Upgrades",
                                ["Upgrade_Name"] = "Upgrades",
                            }
                        }
                        ToServer:FireServer(unpack(args))
                        print("Upgraded:", upgradeName)
                    end
                end
            end, function(err)
                print("Upgrade error:", err)
            end)
            task.wait(2)
        end
    end)
end

local function startAutoRollSwords()
    task.spawn(function()
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Swords_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
            print("Unlocked Swords")
        end, function(err)
            print("Swords unlock error:", err)
        end)
        while getgenv().SeisenHubRunning and autoRollSwordsEnabled do
            local rollArgs = {
                [1] = {
                    ["Open_Amount"] = 1,
                    ["Action"] = "_Gacha_Activate",
                    ["Name"] = "Swords",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(rollArgs))
                print("Rolled Swords")
            end, function(err)
                print("Swords roll error:", err)
            end)
            task.wait(1)
        end
    end)
end

local function startAutoRollPirateCrew()
    task.spawn(function()
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Pirate_Crew_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
            print("Unlocked Pirate Crew")
        end, function(err)
            print("Pirate Crew unlock error:", err)
        end)
        while getgenv().SeisenHubRunning and autoRollPirateCrewEnabled do
            local rollArgs = {
                [1] = {
                    ["Open_Amount"] = 1,
                    ["Action"] = "_Gacha_Activate",
                    ["Name"] = "Pirate_Crew",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(rollArgs))
                print("Rolled Pirate Crew")
            end, function(err)
                print("Pirate Crew roll error:", err)
            end)
            task.wait(1)
        end
    end)
end

function startAutoHakiUpgrade()
    task.spawn(function()
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Haki_Upgrade_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
            print("Unlocked Haki Upgrade")
        end, function(err)
            print("Haki unlock error:", err)
        end)
        while autoHakiUpgradeEnabled and getgenv().SeisenHubRunning do
            local upgradeArgs = {
                [1] = {
                    ["Upgrading_Name"] = "Haki_Upgrade",
                    ["Action"] = "_Upgrades",
                    ["Upgrade_Name"] = "Haki_Upgrade",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(upgradeArgs))
                print("Upgraded Haki")
            end, function(err)
                print("Haki upgrade error:", err)
            end)
            task.wait(2)
        end
    end)
end

function startAutoRollDemonFruits()
    task.spawn(function()
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Demon_Fruits_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
            print("Unlocked Demon Fruits")
        end, function(err)
            print("Demon Fruits unlock error:", err)
        end)
        while autoRollDemonFruitsEnabled and getgenv().SeisenHubRunning do
            local rollArgs = {
                [1] = {
                    ["Open_Amount"] = 1,
                    ["Action"] = "_Gacha_Activate",
                    ["Name"] = "Demon_Fruits",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(rollArgs))
                print("Rolled Demon Fruits")
            end, function(err)
                print("Demon Fruits roll error:", err)
            end)
            task.wait(1)
        end
    end)
end

function startAutoAttackRangeUpgrade()
    task.spawn(function()
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Attack_Range_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
            print("Unlocked Attack Range")
        end, function(err)
            print("Attack Range unlock error:", err)
        end)
        while autoAttackRangeUpgradeEnabled and getgenv().SeisenHubRunning do
            local upgradeArgs = {
                [1] = {
                    ["Upgrading_Name"] = "Attack_Range",
                    ["Action"] = "_Upgrades",
                    ["Upgrade_Name"] = "Attack_Range",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(upgradeArgs))
                print("Upgraded Attack Range")
            end, function(err)
                print("Attack Range upgrade error:", err)
            end)
            task.wait(2)
        end
    end)
end

-- Start tasks based on config
if isAuraEnabled then startAutoFarm() end
if fastKillAuraEnabled then startFastKillAura() end
if slowKillAuraEnabled then startSlowKillAura() end
if autoRankEnabled then startAutoRank() end
if autoAcceptAllQuestsEnabled then startAutoQuests() end
if autoClaimAchievementsEnabled then startAutoAchievements() end
if autoRollDragonRaceEnabled then startAutoRollDragonRace() end
if autoRollSaiyanEvolutionEnabled then startAutoRollSaiyanEvolution() end
if autoRollEnabled then startAutoRollStars() end
if autoDeleteEnabled then startAutoDelete() end
if autoStatsRunning then startAutoStats() end
if isAutoTimeRewardEnabled then startAutoTimeReward() end
if isAutoDailyChestEnabled then startAutoDailyChest() end
if isAutoVipChestEnabled then startAutoVipChest() end
if isAutoGroupChestEnabled then startAutoGroupChest() end
if isAutoPremiumChestEnabled then startAutoPremiumChest() end
if autoEnterDungeon then startAutoEnterDungeon() end
if autoUpgradeEnabled then startAutoUpgrade() end
if autoRollSwordsEnabled then startAutoRollSwords() end
if autoRollPirateCrewEnabled then startAutoRollPirateCrew() end
if autoRollDemonFruitsEnabled then startAutoRollDemonFruits() end
if autoHakiUpgradeEnabled then startAutoHakiUpgrade() end
if autoAttackRangeUpgradeEnabled then startAutoAttackRangeUpgrade() end

-- Auto Farm Toggle
LeftGroupbox:AddToggle("AutoFarmToggle", {
    Text = "Auto Farm (Kill Aura + Teleport)",
    Default = isAuraEnabled,
    Callback = function(Value)
        disableAllAurasExcept("AutoFarm")
        config.AutoFarmToggle = Value
        isAuraEnabled = Value
        if Value then startAutoFarm() end
        saveConfig()
        print("Auto Farm toggle:", Value)
    end
})

-- Fast Kill Aura Toggle
LeftGroupbox:AddToggle("FastKillAuraToggle", {
    Text = "Fast Kill Aura",
    Default = fastKillAuraEnabled,
    Callback = function(Value)
        disableAllAurasExcept("FastKillAura")
        fastKillAuraEnabled = Value
        config.FastKillAuraToggle = Value
        if Value then startFastKillAura() end
        saveConfig()
        print("Fast Kill Aura toggle:", Value)
    end
})

-- Slow Kill Aura Toggle
LeftGroupbox:AddToggle("SlowKillAuraToggle", {
    Text = "Slow Kill Aura",
    Default = slowKillAuraEnabled,
    Callback = function(Value)
        disableAllAurasExcept("SlowKillAura")
        slowKillAuraEnabled = Value
        config.SlowKillAuraToggle = Value
        if Value then startSlowKillAura() end
        saveConfig()
        print("Slow Kill Aura toggle:", Value)
    end
})

-- Auto Rank Toggle
LeftGroupbox:AddToggle("AutoRankToggle", {
    Text = "Auto Rank",
    Default = autoRankEnabled,
    Callback = function(Value)
        autoRankEnabled = Value
        config.AutoRankToggle = Value
        if Value then startAutoRank() end
        saveConfig()
        print("Auto Rank toggle:", Value)
    end
})

-- Auto Accept Quests Toggle
LeftGroupbox:AddToggle("AutoAcceptAllQuestsToggle", {
    Text = "Auto Accept & Claim All Quests",
    Default = autoAcceptAllQuestsEnabled,
    Callback = function(Value)
        autoAcceptAllQuestsEnabled = Value
        config.AutoAcceptAllQuestsToggle = Value
        if Value then startAutoQuests() end
        saveConfig()
        print("Auto Quests toggle:", Value)
    end
})

-- Auto Claim Achievements Toggle
LeftGroupbox:AddToggle("AutoClaimAchievement", {
    Text = "Auto Achievements",
    Default = autoClaimAchievementsEnabled,
    Callback = function(Value)
        autoClaimAchievementsEnabled = Value
        config.AutoClaimAchievement = Value
        if Value then startAutoAchievements() end
        saveConfig()
        print("Auto Achievements toggle:", Value)
    end
})

-- Auto Roll Dragon Race Toggle
RollToken:AddToggle("AutoRollDragonRaceToggle", {
    Text = "Auto Roll Dragon Race",
    Default = autoRollDragonRaceEnabled,
    Callback = function(Value)
        autoRollDragonRaceEnabled = Value
        config.AutoRollDragonRaceToggle = Value
        if Value then startAutoRollDragonRace() end
        saveConfig()
        print("Auto Roll Dragon Race toggle:", Value)
    end
})

-- Auto Roll Saiyan Evolution Toggle
RollToken:AddToggle("AutoRollSaiyanEvolutionToggle", {
    Text = "Auto Spin Saiyan Evolution",
    Default = autoRollSaiyanEvolutionEnabled,
    Callback = function(Value)
        autoRollSaiyanEvolutionEnabled = Value
        config.AutoRollSaiyanEvolutionToggle = Value
        if Value then startAutoRollSaiyanEvolution() end
        saveConfig()
        print("Auto Roll Saiyan Evolution toggle:", Value)
    end
})

-- Auto Roll Stars Toggle
RightGroupbox:AddToggle("AutoRollStarsToggle", {
    Text = "Auto Roll Stars",
    Default = autoRollEnabled,
    Callback = function(Value)
        autoRollEnabled = Value
        config.AutoRollStarsToggle = Value
        if Value then startAutoRollStars() end
        saveConfig()
        print("Auto Roll Stars toggle:", Value)
    end
})

-- Select Star Dropdown
RightGroupbox:AddDropdown("SelectStarDropdown", {
    Values = {"Star_1", "Star_2", "Star_3"},
    Default = selectedStar,
    Multi = false,
    Text = "Select Star",
    Callback = function(Option)
        selectedStar = Option
        config.SelectStarDropdown = Option
        saveConfig()
        print("Selected star:", Option)
    end
})

-- Delay Slider
RightGroupbox:AddSlider("DelayBetweenRollsSlider", {
    Text = "Delay Between Rolls",
    Min = 0.5,
    Max = 2,
    Default = delayBetweenRolls,
    Suffix = "s",
    Callback = function(Value)
        delayBetweenRolls = Value
        config.DelayBetweenRollsSlider = Value
        saveConfig()
        print("Roll delay set:", Value)
    end
})

-- Auto Delete Settings
RightGroupbox:AddLabel("Auto Delete Settings")

-- Auto Delete Toggle
RightGroupbox:AddToggle("AutoDeleteUnitsToggle", {
    Text = "Auto Delete Units",
    Default = autoDeleteEnabled,
    Callback = function(Value)
        autoDeleteEnabled = Value
        config.AutoDeleteUnitsToggle = Value
        if Value then startAutoDelete() end
        saveConfig()
        print("Auto Delete toggle:", Value)
    end
})

-- Select Star for Auto Delete Dropdown
RightGroupbox:AddDropdown("SelectDeleteStarDropdown", {
    Values = {"Star_1", "Star_2"},
    Default = selectedDeleteStar,
    Multi = false,
    Text = "Select Star for Auto Delete",
    Callback = function(Option)
        selectedDeleteStar = Option
        config.SelectDeleteStarDropdown = Option
        saveConfig()
        print("Selected star for auto delete:", Option)
    end
})


-- Auto Delete Rarities Dropdown
RightGroupbox:AddDropdown("AutoDeleteRaritiesDropdown", {
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"},
    Default = {},
    Multi = true,
    Text = "Select Rarities to Delete",
    Callback = function(Selected)
        -- Map display names to numeric rarities
        local rarityMap = {
            Common = "1",
            Uncommon = "2",
            Rare = "3",
            Epic = "4",
            Legendary = "5",
            Mythical = "6"
        }
        local numericRarities = {}
        for displayName, _ in pairs(Selected) do
            if rarityMap[displayName] then
                numericRarities[rarityMap[displayName]] = true
            end
        end
        selectedRarities = numericRarities
        config.AutoDeleteRaritiesDropdown = Selected
        saveConfig()
        print("Selected rarities for auto delete:", Selected)
    end
})

-- Auto Stats
local statKeyMap = {
    ["Damage"] = "Primary_Damage",
    ["Energy"] = "Primary_Energy",
    ["Coins"] = "Primary_Coins",
    ["Luck"] = "Primary_Luck"
}

StatsGroupbox:AddDropdown("AutoStatSingleDropdown", {
    Values = stats,
    Default = selectedStat,
    Multi = false,
    Text = "Select Stat",
    Callback = function(Value)
        local statMap = {
            Damage = "Primary_Damage",
            Energy = "Primary_Energy",
            Coins = "Primary_Coins",
            Luck = "Primary_Luck"
        }
        selectedStat = statMap[Value] or Value
        config.AutoStatSingleDropdown = selectedStat
        saveConfig()
        print("Selected stat:", Value)
    end
})


StatsGroupbox:AddToggle("AutoAssignStatToggle", {
    Text = "Enable Auto Stat",
    Default = autoStatsRunning,
    Callback = function(Value)
        autoStatsRunning = Value
        config.AutoAssignStatToggle = Value
        if Value then startAutoStats() end
        saveConfig()
        print("Auto Stats toggle:", Value, "for stat:", selectedStat)
    end
})

StatsGroupbox:AddSlider("PointsPerSecondSlider", {
    Text = "Points/Second",
    Default = pointsPerSecond,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        pointsPerSecond = Value
        config.PointsPerSecondSlider = Value
        saveConfig()
        print("Points per second set:", Value)
    end
})

-- Auto Collect Rewards
RewardsGroupbox:AddToggle("AutoClaimTimeRewardToggle", {
    Text = "Auto Claim Time Reward",
    Default = isAutoTimeRewardEnabled,
    Callback = function(Value)
        isAutoTimeRewardEnabled = Value
        config.AutoClaimTimeRewardToggle = Value
        if Value then startAutoTimeReward() end
        saveConfig()
        print("Auto Time Reward toggle:", Value)
    end
})

RewardsGroupbox:AddToggle("AutoClaimDailyChestToggle", {
    Text = "Auto Claim Daily Chest",
    Default = isAutoDailyChestEnabled,
    Callback = function(Value)
        isAutoDailyChestEnabled = Value
        config.AutoClaimDailyChestToggle = Value
        if Value then startAutoDailyChest() end
        saveConfig()
        print("Auto Daily Chest toggle:", Value)
    end
})

RewardsGroupbox:AddToggle("AutoClaimVipChestToggle", {
    Text = "Auto Claim Vip Chest (VIP Gamepass required)",
    Default = isAutoVipChestEnabled,
    Callback = function(Value)
        isAutoVipChestEnabled = Value
        config.AutoClaimVipChestToggle = Value
        if Value then startAutoVipChest() end
        saveConfig()
        print("Auto Vip Chest toggle:", Value)
    end
})

RewardsGroupbox:AddToggle("AutoClaimGroupChestToggle", {
    Text = "Auto Claim Group Chest",
    Default = isAutoGroupChestEnabled,
    Callback = function(Value)
        isAutoGroupChestEnabled = Value
        config.AutoClaimGroupChestToggle = Value
        if Value then startAutoGroupChest() end
        saveConfig()
        print("Auto Group Chest toggle:", Value)
    end
})

RewardsGroupbox:AddToggle("AutoClaimPremiumChestToggle", {
    Text = "Auto Claim Premium Chest (Premium User required)",
    Default = isAutoPremiumChestEnabled,
    Callback = function(Value)
        isAutoPremiumChestEnabled = Value
        config.AutoClaimPremiumChestToggle = Value
        if Value then startAutoPremiumChest() end
        saveConfig()
        print("Auto Premium Chest toggle:", Value)
    end
})

-- Teleport
local teleportLocations = {
    ["Dungeon Lobby 1"] = "Dungeon_Lobby_1",
    ["Earth City"] = "Earth_City",
    ["Windmill Island"] = "Windmill_Island",
}

TPGroupbox:AddDropdown("MainTeleportDropdown", {
    Values = {"Earth City", "Dungeon Lobby 1", "Windmill Island"},
    Default = config.MainTeleportDropdown or "Earth City",
    Multi = false,
    Text = "Teleport To",
    Callback = function(selected)
        local locationKey = teleportLocations[selected]
        if locationKey then
            local args = {
                [1] = {
                    ["Location"] = locationKey,
                    ["Type"] = "Map",
                    ["Action"] = "Teleport",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
                print("Teleported to:", selected)
            end, function(err)
                print("Teleport error:", err)
            end)
        end
        config.MainTeleportDropdown = selected
        saveConfig()
    end
})

-- Dungeon Toggles
local dungeonList = {
    "Dungeon_Easy",
    "Dungeon_Medium",
    "Dungeon_Hard",
    "Dungeon_Insane",
    "Dungeon_Crazy",
    "Leaf_Raid"
}

-- Create toggles for each dungeon
for _, dungeon in ipairs(dungeonList) do
    local default = table.find(selectedDungeons, dungeon) ~= nil
    DungeonGroupbox:AddToggle("Toggle_" .. dungeon, {
        Text = dungeon:gsub("_", " "),
        Default = default,
        Callback = function(Value)
            if Value then
                if not table.find(selectedDungeons, dungeon) then
                    table.insert(selectedDungeons, dungeon)
                end
            else
                for i, v in ipairs(selectedDungeons) do
                    if v == dungeon then
                        table.remove(selectedDungeons, i)
                        break
                    end
                end
            end
            config.SelectedDungeons = selectedDungeons
            saveConfig()
            print("Selected Dungeons:", table.concat(selectedDungeons, ", "))
        end
    })
end

-- Toggle: Auto enter dungeon
DungeonGroupbox:AddToggle("AutoEnterDungeonToggle", {
    Text = "Auto Enter Dungeon(s)",
    Default = autoEnterDungeon,
    Callback = function(Value)
        autoEnterDungeon = Value
        config.AutoEnterDungeonToggle = Value
        saveConfig()
        if Value then
            print("Auto Dungeon enabled. Selected:", table.concat(selectedDungeons, ", "))
            startAutoEnterDungeon()
        else
            print("Auto Dungeon disabled.")
        end
    end
})

-- Upgrades
local upgradeOptions = {
    "Star_Luck", "Damage", "Energy", "Coins", "Drops",
    "Avatar_Souls_Drop", "Movement_Speed", "Fast_Roll"
}

local enabledUpgrades = {}
for _, upgradeName in ipairs(upgradeOptions) do
    enabledUpgrades[upgradeName] = config[upgradeName .. "_Toggle"] or false
end

UpgradeGroupbox:AddToggle("AutoUpgradeToggle", {
    Text = "Auto Upgrade",
    Default = autoUpgradeEnabled,
    Callback = function(Value)
        autoUpgradeEnabled = Value
        config.AutoUpgradeToggle = Value
        if Value then startAutoUpgrade() end
        saveConfig()
        print("Auto Upgrade toggle:", Value)
    end
})

UpgradeGroupbox:AddLabel("Upgrade List")
for _, upgradeName in ipairs(upgradeOptions) do
    UpgradeGroupbox:AddToggle(upgradeName .. "_Toggle", {
        Text = upgradeName:gsub("_", " "),
        Default = enabledUpgrades[upgradeName],
        Callback = function(Value)
            enabledUpgrades[upgradeName] = Value
            config[upgradeName .. "_Toggle"] = Value
            saveConfig()
            print("Upgrade toggle:", upgradeName, Value)
        end
    })
end

-- Auto Upgrade Haki
Upgrade2:AddToggle("AutoHakiUpgradeToggle", {
    Text = "Auto Haki Upgrade",
    Default = autoHakiUpgradeEnabled,
    Callback = function(Value)
        autoHakiUpgradeEnabled = Value
        config.AutoHakiUpgradeToggle = Value
        if Value then startAutoHakiUpgrade() end
        saveConfig()
        print("Auto Haki Upgrade toggle:", Value)
    end
})

Upgrade2:AddToggle("AutoAttackRangeUpgradeToggle", {
    Text = "Auto Attack Range Upgrade",
    Default = autoAttackRangeUpgradeEnabled,
    Callback = function(Value)
        autoAttackRangeUpgradeEnabled = Value
        config.AutoAttackRangeUpgradeToggle = Value
        if Value then startAutoAttackRangeUpgrade() end
        saveConfig()
        print("Auto Attack Range Upgrade toggle:", Value)
    end
})

-- Auto Roll Swords
RollUpgrade:AddToggle("AutoRollSwordsToggle", {
    Text = "Auto Roll Swords",
    Default = autoRollSwordsEnabled,
    Callback = function(Value)
        autoRollSwordsEnabled = Value
        config.AutoRollSwordsToggle = Value
        if Value then startAutoRollSwords() end
        saveConfig()
        print("Auto Roll Swords toggle:", Value)
    end
})

-- Auto Roll Pirate Crew
RollUpgrade:AddToggle("AutoRollPirateCrewToggle", {
    Text = "Auto Roll Pirate Crew",
    Default = autoRollPirateCrewEnabled,
    Callback = function(Value)
        autoRollPirateCrewEnabled = Value
        config.AutoRollPirateCrewToggle = Value
        if Value then startAutoRollPirateCrew() end
        saveConfig()
        print("Auto Roll Pirate Crew toggle:", Value)
    end
})

-- Auto Roll Demon Fruits
RollUpgrade:AddToggle("AutoRollDemonFruitsToggle", {
    Text = "Auto Roll Demon Fruits",
    Default = autoRollDemonFruitsEnabled,
    Callback = function(Value)
        autoRollDemonFruitsEnabled = Value
        config.AutoRollDemonFruitsToggle = Value
        if Value then startAutoRollDemonFruits() end
        saveConfig()
        print("Auto Roll Demon Fruits toggle:", Value)
    end
})

-- UI Settings
UnloadGroupbox:AddToggle("DisableNotificationsToggle", {
    Text = "Disable Notifications",
    Default = disableNotificationsEnabled,
    Callback = function(Value)
        disableNotificationsEnabled = Value
        local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local notifications = playerGui:FindFirstChild("Notifications")
            if notifications then
                if Value then
                    if notifications:IsA("ScreenGui") or notifications:IsA("BillboardGui") or notifications:IsA("SurfaceGui") then
                        notifications.Enabled = false
                    elseif notifications:IsA("GuiObject") then
                        notifications.Visible = false
                    end
                else
                    if notifications:IsA("ScreenGui") or notifications:IsA("BillboardGui") or notifications:IsA("SurfaceGui") then
                        notifications.Enabled = true
                    elseif notifications:IsA("GuiObject") then
                        notifications.Visible = true
                    end
                end
                print("Notifications toggle:", Value)
            end
        end
        config.DisableNotificationsToggle = Value
        saveConfig()
    end
})

UnloadGroupbox:AddButton("Save Config", function()
    saveConfig()
end)

UnloadGroupbox:AddButton("Unload Seisen Hub", function()
    getgenv().SeisenHubRunning = false
    isAuraEnabled = false
    fastKillAuraEnabled = false
    slowKillAuraEnabled = false
    autoRollEnabled = false
    autoDeleteEnabled = false
    autoStatsRunning = false
    autoRankEnabled = false
    autoAcceptAllQuestsEnabled = false
    autoClaimAchievementsEnabled = false
    autoRollDragonRaceEnabled = false
    autoRollSaiyanEvolutionEnabled = false
    isAutoTimeRewardEnabled = false
    isAutoDailyChestEnabled = false
    isAutoVipChestEnabled = false
    isAutoGroupChestEnabled = false
    isAutoPremiumChestEnabled = false
    autoUpgradeEnabled = false
    autoEnterDungeon = false
    autoRollSwordsEnabled = false
    autoRollPirateCrewEnabled = false
    autoHakiUpgradeEnabled = false
    autoRollDemonFruitsEnabled = false
    autoAttackRangeUpgradeEnabled = false

    local argsOff = {
        [1] = {
            ["Value"] = false,
            ["Path"] = { "Settings", "Is_Auto_Clicker" },
            ["Action"] = "Settings",
        }
    }
    pcall(function()
        ToServer:FireServer(unpack(argsOff))
        print("Disabled auto clicker")
    end, function(err)
        print("Auto clicker disable error:", err)
    end)

    if Library and Library.Unload then
        pcall(function()
            Library:Unload()
            print("Unloaded Library")
        end)
    elseif getgenv().SeisenHubUI and getgenv().SeisenHubUI.Parent then
        pcall(function()
            getgenv().SeisenHubUI:Destroy()
            print("Destroyed SeisenHub UI")
        end)
    end

    if getgenv().SeisenHubConnections then
        for _, conn in ipairs(getgenv().SeisenHubConnections) do
            pcall(function() conn:Disconnect() end)
        end
        getgenv().SeisenHubConnections = nil
        print("Disconnected all connections")
    end

    getgenv().SeisenHubUI = nil
    getgenv().SeisenHubLoaded = nil
    getgenv().SeisenHubRunning = nil
    getgenv().SeisenHubConfig = nil
    print("[Seisen Hub] Fully unloaded.")
end)

-- Restore UI state
task.defer(function()
    repeat task.wait() until Library.Flags
    print("Restoring flags:", config)
    for flag, value in pairs(config) do
        if Library.Flags[flag] then
            pcall(function()
                Library.Flags[flag]:Set(value)
                print("Set flag", flag, "to", value)
            end, function(err)
                print("Flag set error:", flag, err)
            end)
        else
            print("Flag not found:", flag)
        end
    end
end)
