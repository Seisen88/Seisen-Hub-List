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
    MobileButtonsSide = "Left"
})

-- Store ScreenGui for cleanup
getgenv().SeisenHubUI = Library.Gui

-- Tabs & Groups

local MainTab = Window:AddTab("Main", "atom")
local LeftGroupbox = MainTab:AddLeftGroupbox("Automation")
local StatsGroupbox = MainTab:AddLeftGroupbox("Auto Stats")
local RewardsGroupbox = MainTab:AddRightGroupbox("Auto Rewards")

local TeleportTab = Window:AddTab("Teleport & Dungeon", "map")
local TPGroupbox = TeleportTab:AddLeftGroupbox("Main Teleport")
local DungeonGroupbox = TeleportTab:AddRightGroupbox("Auto Dungeon")

local Roll = Window:AddTab("Rolls", "dice-5")
local RollGroupbox = Roll:AddLeftGroupbox("Auto Rolls")
local RollGroupbox2 = Roll:AddLeftGroupbox("Auto Roll Tokens")
local AutoDeleteGroupbox = Roll:AddRightGroupbox("Auto Delete")

local UP = Window:AddTab("Upgrades", "arrow-up")
local UpgradeGroupbox = UP:AddLeftGroupbox("Upgrades")
local Upgrade2 = UP:AddRightGroupbox("Upgrades 2")

local UISettings = Window:AddTab("UI Settings", "settings")
local UnloadGroupbox = UISettings:AddLeftGroupbox("Utilities")


-- Services & Variables
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local ToServer = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("To_Server", 9e9)
local monstersFolder = Workspace:WaitForChild("Debris", 9e9):WaitForChild("Monsters", 9e9)

local localPlayer = Players.LocalPlayer
local teleportOffset = Vector3.new(0, 0, -3)

local attackCooldown = 0.0001
local currentTarget = nil

if not getgenv().SeisenHubAntiAFK then
    getgenv().SeisenHubAntiAFK = true
    Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

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
local autoAvatarLevelingEnabled = false
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
local mutePetSoundsEnabled = false
local originalVolumes = {}
local autoSpiritualPressureUpgradeEnabled = false
local autoRollReiatsuColorEnabled = false
local autoRollZanpakutoEnabled = false
local config = getgenv().SeisenHubConfig or {}
local autoCursedProgressionUpgradeEnabled = false
local autoRollCursesEnabled = false
local selectedDungeons = config.SelectedDungeons or {"Dungeon_Easy"}

-- Stats options (display names)
local stats = {
    "Damage",
    "Energy",
    "Coins",
    "Luck"
}

-- Internal stat mapping
local statMap = {
    Damage = "Primary_Damage",
    Energy = "Primary_Energy",
    Coins = "Primary_Coins",
    Luck = "Primary_Luck"
}

-- Load config if file exists
if isfile(configFile) then
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(configFile))
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            config[k] = v
        end
    end
end

-- Load config values with defaults
isAuraEnabled = config.AutoFarmToggle or false
fastKillAuraEnabled = config.FastKillAuraToggle or false
slowKillAuraEnabled = config.SlowKillAuraToggle or false
autoRankEnabled = config.AutoRankToggle or false
autoAvatarLevelingEnabled = config.AutoAvatarLevelingToggle or false
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
pointsPerSecond = config.PointsPerSecondSlider or 1
autoSpiritualPressureUpgradeEnabled = config.AutoSpiritualPressureUpgradeToggle or false
autoRollReiatsuColorEnabled = config.AutoRollReiatsuColorToggle or false
mutePetSoundsEnabled = config.MutePetSoundsToggle or false
selectedRaritiesDisplay = config.AutoDeleteRaritiesDropdown or {}
selectedDungeons = config.SelectedDungeons or {"Dungeon_Easy"}
autoRollZanpakutoEnabled = config.AutoRollZanpakutoToggle or false
autoCursedProgressionUpgradeEnabled = config.AutoCursedProgressionUpgradeToggle or false
autoRollCursesEnabled = config.AutoRollCursesToggle or false

-- Helper to save config
local function saveConfig()
    config.SelectedDungeons = selectedDungeons
    config.AutoAssignStatToggle = autoStatsRunning
    config.AutoStatSingleDropdown = selectedStat
    config.PointsPerSecondSlider = pointsPerSecond
    config.AutoAvatarLevelingToggle = autoAvatarLevelingEnabled
    config.MutePetSoundsToggle = mutePetSoundsEnabled
    config.AutoSpiritualPressureUpgradeToggle = autoSpiritualPressureUpgradeEnabled
    config.AutoRollReiatsuColorToggle = autoRollReiatsuColorEnabled
    getgenv().SeisenHubConfig = config
    writefile(configFile, HttpService:JSONEncode(config))
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
        end)
    end
end

-- Task functions
local function startAutoFarm()
    task.spawn(function()
        while getgenv().SeisenHubRunning and isAuraEnabled do
            local char = localPlayer.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")

            if not myHRP then
                task.wait(attackCooldown)
                continue
            end

            local maxDistance = 50
            if not currentTarget or not currentTarget:IsDescendantOf(monstersFolder)
                or not currentTarget:FindFirstChild("Humanoid")
                or currentTarget.Humanoid.Health <= 0
                or (currentTarget:FindFirstChild("HumanoidRootPart") and (currentTarget.HumanoidRootPart.Position - myHRP.Position).Magnitude > maxDistance) then
                currentTarget = getNearestValidMonster()
                if currentTarget then
                    teleportToMonster(currentTarget)
                end
            end

            if currentTarget and myHRP then
                local hum = currentTarget:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local monsterId = currentTarget.Name -- Fallback ID
                    if currentTarget:GetAttribute("Id") then
                        monsterId = currentTarget:GetAttribute("Id")
                    elseif currentTarget:FindFirstChild("Id") and currentTarget.Id:IsA("StringValue") then
                        monsterId = currentTarget.Id.Value
                    end
                    print("Attempting Damage_Event with ID:", monsterId) -- Debug
                    local success = pcall(function()
                        game:GetService("ReplicatedStorage").Events.Damage_Event:FireServer({
                            Damages = { { Value = "5sx", Is_Critical = true, Type = "Damage" } },
                            To = {
                                New_Health = tostring(hum.Health - 5e21), -- Adjust based on current health
                                Player = false,
                                New_Percent = hum.Health / hum.MaxHealth,
                                Id = monsterId,
                                Is_NPC = true
                            },
                            From = {
                                Id = localPlayer.UserId,
                                Player = localPlayer
                            }
                        })
                    end)
                    if not success then
                        print("Damage_Event failed, using _Mouse_Click")
                        pcall(function()
                            local args = {
                                [1] = {
                                    ["Id"] = currentTarget.Name,
                                    ["Action"] = "_Mouse_Click",
                                    ["Is_Critical"] = true
                                }
                            }
                            ToServer:FireServer(unpack(args))
                        end)
                    end
                end
            end
            task.wait(attackCooldown / 2) -- Faster attacks (e.g., 0.00005)
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
            end)
            task.wait(1)
        end
    end)
end

local function startAutoAvatarLeveling()
    task.spawn(function()
        while getgenv().SeisenHubRunning and autoAvatarLevelingEnabled do
            local args = {
                [1] = {
                    ["Value"] = true,
                    ["Path"] = {
                        [1] = "Settings",
                        [2] = "Is_Auto_Avatar_Leveling",
                    },
                    ["Action"] = "Settings",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(args))
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
            end)
            task.wait(1)
        end
    end)
end

function startAutoRollSaiyanEvolution()
    task.spawn(function()
        -- Unlock Saiyan Evolution first
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Saiyan_Evolution_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
            print("Saiyan Evolution unlock request sent") -- Debug
        end)
        -- Wait to ensure unlock is processed
        task.wait(2) -- Adjust delay if needed based on server response time
        -- Now keep rolling while enabled
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
                local rollArgs = {
                    [1] = {
                        ["Open_Amount"] = 5,
                        ["Action"] = "_Stars",
                        ["Name"] = selectedStar
                    }
                }
                ToServer:FireServer(unpack(rollArgs))
            end)
            task.wait(delayBetweenRolls)
        end
    end)
end

local function startAutoDelete()
    task.spawn(function()
        while autoDeleteEnabled and getgenv().SeisenHubRunning do
            pcall(function()
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
                    },
                    ["Star_3"] = {
                        ["1"] = {"70015"},
                        ["2"] = {"70016"},
                        ["3"] = {"70017"},
                        ["4"] = {"70018"},
                        ["5"] = {"70019"},
                        ["6"] = {"70020"}
                    },
                    ["Star_4"] = {
                        ["1"] = {"70022"},
                        ["2"] = {"70023"},
                        ["3"] = {"70024"},
                        ["4"] = {"70025"},
                        ["5"] = {"70026"},
                        ["6"] = {"70027"}
                    },
                    ["Star_5"] = {
                        ["1"] = {"70029"},
                        ["2"] = {"70030"},
                        ["3"] = {"70031"},
                        ["4"] = {"70032"},
                        ["5"] = {"70033"},
                        ["6"] = {"70034"}
                    },
                    ["Star_6"] = {
                        ["1"] = {"70036"},
                        ["2"] = {"70037"},
                        ["3"] = {"70038"},
                        ["4"] = {"70039"},
                        ["5"] = {"70040"},
                        ["6"] = {"70041"}
                    },
                    ["Star_7"] = {
                        ["1"] = {"70043"},
                        ["2"] = {"70044"},
                        ["3"] = {"70045"},
                        ["4"] = {"70046"},
                        ["5"] = {"70047"},
                        ["6"] = {"70048"}
                    },
                    ["Star_8"] = {
                        ["1"] = {"70050"},
                        ["2"] = {"70051"},
                        ["3"] = {"70052"},
                        ["4"] = {"70053"},
                        ["5"] = {"70054"},
                        ["6"] = {"70055"}
                    },
                    ["Star_9"] = {
                        ["1"] = {"70057"},
                        ["2"] = {"70058"},
                        ["3"] = {"70059"},
                        ["4"] = {"70060"},
                        ["5"] = {"70061"},
                        ["6"] = {"70062"}
                    },
                    ["Star_10"] = {
                        ["1"] = {"70064"},
                        ["2"] = {"70065"},
                        ["3"] = {"70066"},
                        ["4"] = {"70067"},
                        ["5"] = {"70068"},
                        ["6"] = {"70069"}
                    },
                    ["Star_11"] = {
                        ["1"] = {"70071"},
                        ["2"] = {"70072"},
                        ["3"] = {"70073"},
                        ["4"] = {"70074"},
                        ["5"] = {"70075"},
                        ["6"] = {"70076"}
                    },
                    ["Star_12"] = {
                        ["1"] = {"70078"},
                        ["2"] = {"70079"},
                        ["3"] = {"70080"},
                        ["4"] = {"70081"},
                        ["5"] = {"70082"},
                        ["6"] = {"70083"}
                    },
                    ["Star_13"] = {
                        ["1"] = {"70085"},
                        ["2"] = {"70086"},
                        ["3"] = {"70087"},
                        ["4"] = {"70088"},
                        ["5"] = {"70089"},
                        ["6"] = {"70090"}
                    },
                }

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

                local rarities = starRarityMap[selectedDeleteStar]
                if rarities then
                    for rarity, _ in pairs(selectedRarities) do
                        local ids = rarities[rarity]
                        if ids then
                            for _, id in ipairs(ids) do
                                local args = {
                                    [1] = {
                                        ["Value"] = true,
                                        ["Path"] = {"Settings", "AutoDelete", "Stars", id, rarity},
                                        ["Action"] = "Settings"
                                    }
                                }
                                pcall(function()
                                    ToServer:FireServer(unpack(args))
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
                if not statMap then
                    warn("statMap is nil!")
                    return
                end
                local statName = statMap[selectedStat]
                if not statName then
                    warn("Invalid stat selected:", selectedStat)
                    return
                end
                local args = {
                    [1] = {
                        ["Name"] = statName,
                        ["Action"] = "Assign_Level_Stats",
                        ["Amount"] = pointsPerSecond
                    }
                }
                pcall(function()
                    ToServer:FireServer(unpack(args))
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
                    local args = {
                        [1] = {
                            ["Action"] = "_Enter_Dungeon",
                            ["Name"] = dungeon
                        }
                    }
                    ToServer:FireServer(unpack(args))
                end)
                task.wait(1)
            end
            task.wait(5)
        end
    end)
end

local function startAutoUpgrade()
    task.spawn(function()
        while autoUpgradeEnabled and getgenv().SeisenHubRunning do
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
                    end
                end
            end)
            task.wait(0.5)
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
            end)
            task.wait(2)
        end
    end)
end

local function applyNotificationsState()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end

    local notifications = playerGui:WaitForChild("Notifications", 5)
    if not notifications then return end

    if disableNotificationsEnabled then
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
end

local function applyMutePetSoundsState()
    local audioFolder = ReplicatedStorage:WaitForChild("Audio", 5)
    if not audioFolder then return end

    local petSounds = {"Pets_Appearing_Sound", "Pets_Drumroll", "Loot"}
    for _, soundName in ipairs(petSounds) do
        local sound = audioFolder:FindFirstChild(soundName)
        if sound and sound:IsA("Sound") then
            if mutePetSoundsEnabled then
                if not originalVolumes[soundName] then
                    originalVolumes[soundName] = sound.Volume
                end
                sound.Volume = 0
            else
                sound.Volume = originalVolumes[soundName] or 0.5
            end
        end
    end

    local mergeFolder = audioFolder:FindFirstChild("Merge")
    if mergeFolder then
        local mergeSounds = {"PetsAppearingSound", "Drumroll", "ChestOpen"}
        for _, soundName in ipairs(mergeSounds) do
            local sound = mergeFolder:FindFirstChild(soundName)
            if sound and sound:IsA("Sound") then
                if mutePetSoundsEnabled then
                    if not originalVolumes[soundName] then
                        originalVolumes[soundName] = sound.Volume
                    end
                    sound.Volume = 0
                else
                    sound.Volume = originalVolumes[soundName] or 0.5
                end
            end
        end
    end
end

task.defer(function()
    repeat task.wait() until Library.Flags
    for flag, value in pairs(config) do
        if Library.Flags[flag] then
            pcall(function()
                Library.Flags[flag]:Set(value)
            end)
        end
    end

    local maxRetries = 5
    local retryDelay = 1
    for i = 1, maxRetries do
        if disableNotificationsEnabled then
            applyNotificationsState()
            if Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild("Notifications") then
                break
            end
        end
        task.wait(retryDelay)
    end
end)

function startAutoSpiritualPressureUpgrade()
    task.spawn(function()
        -- Unlock Spiritual Pressure first
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Spiritual_Pressure_Unlock"
            }
        }
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("To_Server", 9e9):FireServer(unpack(unlockArgs))
        end)
        -- Wait to ensure unlock is processed
        task.wait(2) -- Adjust delay if needed based on server response time
        while autoSpiritualPressureUpgradeEnabled and getgenv().SeisenHubRunning do
            local upgradeArgs = {
                [1] = {
                    ["Upgrading_Name"] = "Spiritual_Pressure",
                    ["Action"] = "_Upgrades",
                    ["Upgrade_Name"] = "Spiritual_Pressure"
                }
            }
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("To_Server", 9e9):FireServer(unpack(upgradeArgs))
            end)
            task.wait(2)
        end
    end)
end

function startAutoRollReiatsuColor()
    task.spawn(function()
        -- Unlock Reiatsu Color first (only once)
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Reiatsu_Color_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
        end)
        -- Now keep rolling while enabled
        while autoRollReiatsuColorEnabled and getgenv().SeisenHubRunning do
            local rollArgs = {
                [1] = {
                    ["Open_Amount"] = 1,
                    ["Action"] = "_Gacha_Activate",
                    ["Name"] = "Reiatsu_Color",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(rollArgs))
            end)
            task.wait(1)
        end
    end)
end

local function startAutoRollZanpakuto()
    task.spawn(function()
        -- Unlock Zanpakuto first (only once)
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Zanpakuto_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
        end)
        -- Now keep rolling while enabled
        while autoRollZanpakutoEnabled and getgenv().SeisenHubRunning do
            local rollArgs = {
                [1] = {
                    ["Open_Amount"] = 1,
                    ["Action"] = "_Gacha_Activate",
                    ["Name"] = "Zanpakuto",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(rollArgs))
            end)
            task.wait(1)
        end
    end)
end

function startAutoCursedProgressionUpgrade()
    task.spawn(function()
        -- Unlock Cursed Progression first (only once)
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Cursed_Progression_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
        end)
        -- Now keep upgrading while enabled
        while autoCursedProgressionUpgradeEnabled and getgenv().SeisenHubRunning do
            local upgradeArgs = {
                [1] = {
                    ["Upgrading_Name"] = "Curse",
                    ["Action"] = "_Upgrades",
                    ["Upgrade_Name"] = "Cursed_Progression",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(upgradeArgs))
            end)
            task.wait(2)
        end
    end)
end

local function startAutoRollCurses()
    task.spawn(function()
        -- Unlock Curses first (only once)
        local unlockArgs = {
            [1] = {
                ["Upgrading_Name"] = "Unlock",
                ["Action"] = "_Upgrades",
                ["Upgrade_Name"] = "Curses_Unlock",
            }
        }
        pcall(function()
            ToServer:FireServer(unpack(unlockArgs))
        end)
        -- Now keep rolling while enabled
        while autoRollCursesEnabled and getgenv().SeisenHubRunning do
            local rollArgs = {
                [1] = {
                    ["Open_Amount"] = 1,
                    ["Action"] = "_Gacha_Activate",
                    ["Name"] = "Curses",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(rollArgs))
            end)
            task.wait(1)
        end
    end)
end


if isAuraEnabled then startAutoFarm() end
if fastKillAuraEnabled then startFastKillAura() end
if slowKillAuraEnabled then startSlowKillAura() end
if autoRankEnabled then startAutoRank() end
if autoAvatarLevelingEnabled then startAutoAvatarLeveling() end
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
if autoRollReiatsuColorEnabled then startAutoRollReiatsuColor() end
if disableNotificationsEnabled then applyNotificationsState() end
if mutePetSoundsEnabled then applyMutePetSoundsState() end
if autoRollZanpakutoEnabled then startAutoRollZanpakuto() end
if autoCursedProgressionUpgradeEnabled then startAutoCursedProgressionUpgrade() end
if autoRollCursesEnabled then startAutoRollCurses() end

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
    end
})

-- Auto Avatar Leveling Toggle
LeftGroupbox:AddToggle("AutoAvatarLevelingToggle", {
    Text = "Auto Avatar Leveling",
    Default = autoAvatarLevelingEnabled,
    Callback = function(Value)
        autoAvatarLevelingEnabled = Value
        config.AutoAvatarLevelingToggle = Value
        if Value then
            startAutoAvatarLeveling()
        else
            -- Only call this ONCE when toggled off
            local argsOff = {
                [1] = {
                    ["Value"] = false,
                    ["Path"] = { "Settings", "Is_Auto_Avatar_Leveling" },
                    ["Action"] = "Settings",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(argsOff))
            end)
        end
        saveConfig()
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
    end
})

-- Auto Roll Dragon Race Toggle
RollGroupbox2:AddToggle("AutoRollDragonRaceToggle", {
    Text = "Auto Roll Dragon Race",
    Default = autoRollDragonRaceEnabled,
    Callback = function(Value)
        autoRollDragonRaceEnabled = Value
        config.AutoRollDragonRaceToggle = Value
        if Value then startAutoRollDragonRace() end
        saveConfig()
    end
})

-- Auto Roll Saiyan Evolution Toggle
RollGroupbox2:AddToggle("AutoRollSaiyanEvolutionToggle", {
    Text = "Auto Roll Saiyan Evolution",
    Default = autoRollSaiyanEvolutionEnabled,
    Callback = function(Value)
        autoRollSaiyanEvolutionEnabled = Value
        config.AutoRollSaiyanEvolutionToggle = Value
        if Value then startAutoRollSaiyanEvolution() end
        saveConfig()
    end
})

-- Auto Roll Stars Toggle
RollGroupbox:AddToggle("AutoRollStarsToggle", {
    Text = "Auto Roll Stars",
    Default = autoRollEnabled,
    Callback = function(Value)
        autoRollEnabled = Value
        config.AutoRollStarsToggle = Value
        if Value then startAutoRollStars() end
        saveConfig()
    end
})

local placeToStar = {
    ["Earth City"] = "Star_1",
    ["Windmill Island"] = "Star_2",
    ["Soul Society"] = "Star_3",
    ["Cursed School"] = "Star_4",
    ["Slayer Village"] = "Star_5",
    ["Solo Island"] = "Star_6",
    ["Clover Village"] = "Star_7",
    ["Leaf Village"] = "Star_8",
    ["Spirit Residence"] = "Star_9",
    ["Magic_Hunter_City"] = "Star_10",
    ["Titan Village"] = "Star_11",
    ["Villageof Sins"] = "Star_12",
    ["Dungeon Lobby 1"] = "Star_13"
}
local starToPlace = {}
for place, star in pairs(placeToStar) do
    starToPlace[star] = place
end
-- Select Star Dropdown
RollGroupbox:AddDropdown("SelectStarDropdown", {
    Values = {"Earth City", "Dungeon Lobby 1", "Windmill Island", "Soul Society", "Cursed School", "Slayer Village", "Solo Island", "Clover Village", "Leaf Village", "Spirit Residence", "Magic_Hunter_City", "Titan Village", "Villageof Sins"},
    Default = starToPlace[selectedStar] or "Earth City",
    Multi = false,
    Text = "Select Star (by Place)",
    Callback = function(Option)
        selectedStar = placeToStar[Option] or "Star_1"
        config.SelectStarDropdown = selectedStar
        saveConfig()
    end
})

-- Delay Slider
RollGroupbox:AddSlider("DelayBetweenRollsSlider", {
    Text = "Delay Between Rolls",
    Min = 0.5,
    Max = 2,
    Default = delayBetweenRolls,
    Suffix = "s",
    Callback = function(Value)
        delayBetweenRolls = Value
        config.DelayBetweenRollsSlider = Value
        saveConfig()
    end
})

-- Auto Roll Swords
RollGroupbox2:AddToggle("AutoRollSwordsToggle", {
    Text = "Auto Roll Swords",
    Default = autoRollSwordsEnabled,
    Callback = function(Value)
        autoRollSwordsEnabled = Value
        config.AutoRollSwordsToggle = Value
        if Value then startAutoRollSwords() end
        saveConfig()
    end
})

-- Auto Roll Pirate Crew
RollGroupbox2:AddToggle("AutoRollPirateCrewToggle", {
    Text = "Auto Roll Pirate Crew",
    Default = autoRollPirateCrewEnabled,
    Callback = function(Value)
        autoRollPirateCrewEnabled = Value
        config.AutoRollPirateCrewToggle = Value
        if Value then startAutoRollPirateCrew() end
        saveConfig()
    end
})

-- Auto Roll Demon Fruits
RollGroupbox2:AddToggle("AutoRollDemonFruitsToggle", {
    Text = "Auto Roll Demon Fruits",
    Default = autoRollDemonFruitsEnabled,
    Callback = function(Value)
        autoRollDemonFruitsEnabled = Value
        config.AutoRollDemonFruitsToggle = Value
        if Value then startAutoRollDemonFruits() end
        saveConfig()
    end
})

RollGroupbox2:AddToggle("AutoRollReiatsuColorToggle", {
    Text = "Auto Roll Reiatsu Color",
    Default = autoRollReiatsuColorEnabled,
    Callback = function(Value)
        autoRollReiatsuColorEnabled = Value
        config.AutoRollReiatsuColorToggle = Value
        if Value then startAutoRollReiatsuColor() end
        saveConfig()
    end
})

RollGroupbox2:AddToggle("AutoRollZanpakutoToggle", {
    Text = "Auto Roll Zanpakuto",
    Default = autoRollZanpakutoEnabled,
    Callback = function(Value)
        autoRollZanpakutoEnabled = Value
        config.AutoRollZanpakutoToggle = Value
        if Value then startAutoRollZanpakuto() end
        saveConfig()
    end
})

RollGroupbox2:AddToggle("AutoRollCursesToggle", {
    Text = "Auto Roll Curses",
    Default = autoRollCursesEnabled,
    Callback = function(Value)
        autoRollCursesEnabled = Value
        config.AutoRollCursesToggle = Value
        if Value then startAutoRollCurses() end
        saveConfig()
    end
})

-- Auto Delete Settings
AutoDeleteGroupbox:AddLabel("Auto Delete Settings")

-- Auto Delete Toggle
AutoDeleteGroupbox:AddToggle("AutoDeleteUnitsToggle", {
    Text = "Auto Delete Units",
    Default = autoDeleteEnabled,
    Callback = function(Value)
        autoDeleteEnabled = Value
        config.AutoDeleteUnitsToggle = Value
        if Value then startAutoDelete() end
        saveConfig()
    end
})

-- Select Star for Auto Delete Dropdown
AutoDeleteGroupbox:AddDropdown("SelectDeleteStarDropdown", {
    Values = {"Earth City", "Dungeon Lobby 1", "Windmill Island", "Soul Society", "Cursed School", "Slayer Village", "Solo Island", "Clover Village", "Leaf Village", "Spirit Residence", "Magic_Hunter_City", "Titan Village", "Villageof Sins"},
    Default = starToPlace[selectedDeleteStar] or "Earth City",
    Multi = false,
    Text = "Select Star for Auto Delete (by Place)",
    Callback = function(Option)
        selectedDeleteStar = placeToStar[Option] or "Star_1"
        config.SelectDeleteStarDropdown = selectedDeleteStar
        saveConfig()
    end
})

local rarityMap = {
    Common = "1",
    Uncommon = "2",
    Rare = "3",
    Epic = "4",
    Legendary = "5",
    Mythical = "6"
}
for _, displayName in ipairs(selectedRaritiesDisplay) do
    if rarityMap[displayName] then
        selectedRarities[rarityMap[displayName]] = true
    end
end

-- Auto Delete Rarities Dropdown
AutoDeleteGroupbox:AddDropdown("AutoDeleteRaritiesDropdown", {
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"},
    Default = selectedRaritiesDisplay,
    Multi = true,
    Text = "Select Rarities to Delete",
    Callback = function(Selected)
        selectedRarities = {}
        for displayName, _ in pairs(Selected) do
            if rarityMap[displayName] then
                selectedRarities[rarityMap[displayName]] = true
            end
        end
        config.AutoDeleteRaritiesDropdown = {}
        for displayName, _ in pairs(Selected) do
            table.insert(config.AutoDeleteRaritiesDropdown, displayName)
        end
        saveConfig()
    end
})

-- Auto Stats



StatsGroupbox:AddDropdown("AutoStatSingleDropdown", {
    Values = stats,
    Default = selectedStat, -- display name
    Multi = false,
    Text = "Select Stat",
    Callback = function(Value)
        selectedStat = Value -- display name
        config.AutoStatSingleDropdown = Value
        saveConfig()
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
    end
})

-- Teleport
local teleportLocations = {
    ["Dungeon Lobby 1"] = "Dungeon_Lobby_1",
    ["Earth City"] = "Earth_City",
    ["Windmill Island"] = "Windmill_Island",
    ["Soul Society"] = "Soul_Society",
    ["Cursed School"] = "Cursed_School",
    ["Slayer Village"] = "Slayer_Village",
    ["Solo Island"] = "Solo_Island",
    ["Clover Village"] = "Clover_Village",
    ["Leaf Village"] = "Leaf_Village",
    ["Spirit Residence"] = "Spirit_Residence",
    ["Magic Hunter_City"] = "Magic_Hunter_City",
    ["Titan Village"] = "Titan_Village",
    ["Villageof Sins"] = "Village_of_Sins",
}

TPGroupbox:AddDropdown("MainTeleportDropdown", {
    Values = {"Earth City", "Dungeon Lobby 1", "Windmill Island", "Soul Society", "Cursed School", "Slayer Village", "Solo Island", "Clover Village", "Leaf Village", "Spirit Residence", "Magic_Hunter_City", "Titan Village", "Villageof Sins"},
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
            startAutoEnterDungeon()
        end
    end
})

-- Upgrades
local upgradeOptions = {
    "Star_Luck", "Damage", "Energy", "Coins", "Drops",
    "Avatar_Souls_Drop", "Movement_Speed", "Fast_Roll", "Star_Speed"
}
enabledUpgrades = enabledUpgrades or {}
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
    end
})

Upgrade2:AddToggle("AutoSpiritualPressureUpgradeToggle", {
    Text = "Auto Spiritual Pressure Upgrade",
    Default = autoSpiritualPressureUpgradeEnabled,
    Callback = function(Value)
        autoSpiritualPressureUpgradeEnabled = Value
        config.AutoSpiritualPressureUpgradeToggle = Value
        if Value then startAutoSpiritualPressureUpgrade() end
        saveConfig()
    end
})

Upgrade2:AddToggle("AutoCursedProgressionUpgradeToggle", {
    Text = "Auto Cursed Progression Upgrade",
    Default = autoCursedProgressionUpgradeEnabled,
    Callback = function(Value)
        autoCursedProgressionUpgradeEnabled = Value
        config.AutoCursedProgressionUpgradeToggle = Value
        if Value then startAutoCursedProgressionUpgrade() end
        saveConfig()
    end
})

-- Disable Sound
UnloadGroupbox:AddToggle("MutePetSoundsToggle", {
    Text = "Mute Pet Sounds",
    Default = mutePetSoundsEnabled,
    Callback = function(Value)
        mutePetSoundsEnabled = Value
        config.MutePetSoundsToggle = Value
        applyMutePetSoundsState()
        saveConfig()
    end
})

-- UI Settings
UnloadGroupbox:AddToggle("DisableNotificationsToggle", {
    Text = "Disable Notifications",
    Default = disableNotificationsEnabled,
    Callback = function(Value)
        disableNotificationsEnabled = Value
        config.DisableNotificationsToggle = Value
        applyNotificationsState()
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
    autoRankEnabled = false
    autoAvatarLevelingEnabled = false
    autoAcceptAllQuestsEnabled = false
    autoRollDragonRaceEnabled = false
    autoRollSaiyanEvolutionEnabled = false
    autoRollEnabled = false
    autoDeleteEnabled = false
    autoClaimAchievementsEnabled = false
    autoRollSwordsEnabled = false
    autoRollPirateCrewEnabled = false
    isAutoTimeRewardEnabled = false
    isAutoDailyChestEnabled = false
    isAutoVipChestEnabled = false
    isAutoGroupChestEnabled = false
    isAutoPremiumChestEnabled = false
    autoUpgradeEnabled = false
    autoEnterDungeon = false
    autoHakiUpgradeEnabled = false
    autoRollDemonFruitsEnabled = false
    autoAttackRangeUpgradeEnabled = false
    autoAvatarLevelingEnabled = false
    autoSpiritualPressureUpgradeEnabled = false
    selectedStat = false
    autoRollZanpakutoEnabledfalse = false
    autoCursedProgressionUpgradeEnabled = false
    autoRollCursesEnabled = false

    local argsOff = {
        [1] = {
            ["Value"] = false,
            ["Path"] = { "Settings", "Is_Auto_Clicker" },
            ["Action"] = "Settings",
        }
    }
    pcall(function()
        ToServer:FireServer(unpack(argsOff))
    end)

    if mutePetSoundsEnabled then
        local audioFolder = ReplicatedStorage:FindFirstChild("Audio")
        if audioFolder then
            local petSounds = {"Pets_Appearing_Sound", "Pets_Drumroll", "Loot"}
            for _, soundName in ipairs(petSounds) do
                local sound = audioFolder:FindFirstChild(soundName)
                if sound and sound:IsA("Sound") then
                    sound.Volume = originalVolumes[soundName] or 0.5
                end
            end
            local mergeFolder = audioFolder:FindFirstChild("Merge")
            if mergeFolder then
                local mergeSounds = {"PetsAppearingSound", "Drumroll", "ChestOpen"}
                for _, soundName in ipairs(mergeSounds) do
                    local sound = mergeFolder:FindFirstChild(soundName)
                    if sound and sound:IsA("Sound") then
                        sound.Volume = originalVolumes[soundName] or 0.5
                    end
                end
            end
        end
    end

    if disableNotificationsEnabled then
        local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local notifications = playerGui:FindFirstChild("Notifications")
            if notifications then
                if notifications:IsA("ScreenGui") or notifications:IsA("BillboardGui") or notifications:IsA("SurfaceGui") then
                    notifications.Enabled = true
                elseif notifications:IsA("GuiObject") then
                    notifications.Visible = true
                end
            end
        end
    end

    if Library and Library.Unload then
        pcall(function()
            Library:Unload()
        end)
    elseif getgenv().SeisenHubUI and getgenv().SeisenHubUI.Parent then
        pcall(function()
            getgenv().SeisenHubUI:Destroy()
        end)
    end

    if getgenv().SeisenHubConnections then
        for _, conn in ipairs(getgenv().SeisenHubConnections) do
            pcall(function() conn:Disconnect() end)
        end
        getgenv().SeisenHubConnections = nil
    end

    getgenv().SeisenHubUI = nil
    getgenv().SeisenHubLoaded = nil
    getgenv().SeisenHubRunning = nil
    getgenv().SeisenHubConfig = nil
end)

task.defer(function()
    repeat task.wait() until Library.Flags
    for flag, value in pairs(config) do
        if Library.Flags[flag] then
            pcall(function()
                Library.Flags[flag]:Set(value)
            end)
        end
    end

    if disableNotificationsEnabled then
        local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local notifications = playerGui:FindFirstChild("Notifications")
            if notifications then
                if notifications:IsA("ScreenGui") or notifications:IsA("BillboardGui") or notifications:IsA("SurfaceGui") then
                    notifications.Enabled = false
                elseif notifications:IsA("GuiObject") then
                    notifications.Visible = false
                end
            end
        end
    end

    if mutePetSoundsEnabled then
        local audioFolder = ReplicatedStorage:FindFirstChild("Audio")
        if audioFolder then
            local petSounds = {"Pets_Appearing_Sound", "Pets_Drumroll", "Loot"}
            for _, soundName in ipairs(petSounds) do
                local sound = audioFolder:FindFirstChild(soundName)
                if sound and sound:IsA("Sound") then
                    if not originalVolumes[soundName] then
                        originalVolumes[soundName] = sound.Volume
                    end
                    sound.Volume = 0
                end
            end
            local mergeFolder = audioFolder:FindFirstChild("Merge")
            if mergeFolder then
                local mergeSounds = {"PetsAppearingSound", "Drumroll", "ChestOpen"}
                for _, soundName in ipairs(mergeSounds) do
                    local sound = mergeFolder:FindFirstChild(soundName)
                    if sound and sound:IsA("Sound") then
                        if not originalVolumes[soundName] then
                            originalVolumes[soundName] = sound.Volume
                        end
                        sound.Volume = 0
                    end
                end
            end
        end
    end
end)
