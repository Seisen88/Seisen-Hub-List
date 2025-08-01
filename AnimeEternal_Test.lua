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

-- ✅ This is the ScreenGui you need to destroy later
getgenv().SeisenHubUI = Library.Gui


-- Tabs & Groups
local MainTab = Window:AddTab("Main" , "box")
local LeftGroupbox = MainTab:AddLeftGroupbox("Automation")
local StatsGroupbox = MainTab:AddLeftGroupbox("Auto Stats")
local RightGroupbox = MainTab:AddRightGroupbox("Auto Roll")
local RewardsGroupbox = MainTab:AddRightGroupbox("Auto Rewards")
local TPD = Window:AddTab("TP & Dungeon")
local TPGroupbox = TPD:AddLeftGroupbox("Main Teleport")
local DungeonGroupbox = TPD:AddRightGroupbox("Dungeons")
local UP = Window:AddTab("Upgrades")
local UpgradeGroupbox = UP:AddLeftGroupbox("Upgrades")
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

local isAuraEnabled = false
local fastKillAuraEnabled = false
local slowKillAuraEnabled = false
local autoRankEnabled = false
local autoAcceptAllQuestsEnabled = false
local autoRollDragonRaceEnabled = false
local autoRollEnabled = false
local autoDeleteEnabled = false
local selectedStar = "Star_1"
local delayBetweenRolls = 0.5
local selectedRarities = {}
local previouslySelectedRarities = {}
local autoStatsRunning = false
local isAutoTimeRewardEnabled = false
local isAutoDailyChestEnabled = false
local isAutoVipChestEnabled = false
local isAutoGroupChestEnabled = false
local isAutoPremiumChestEnabled = false
local disableNotificationsEnabled = false


local config = {} -- <--- Add this line before loading config

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

-- Helper to save config
local function saveConfig()
    writefile(configFile, HttpService:JSONEncode(config))
end


-- Load config values into script variables
isAuraEnabled = config.AutoFarmToggle or false
fastKillAuraEnabled = config.FastKillAuraToggle or false
slowKillAuraEnabled = config.SlowKillAuraToggle or false
autoRankEnabled = config.AutoRankToggle or false
autoAcceptAllQuestsEnabled = config.AutoAcceptAllQuestsToggle or false
autoRollDragonRaceEnabled = config.AutoRollDragonRaceToggle or false
autoRollEnabled = config.AutoRollStarsToggle or false
autoDeleteEnabled = config.AutoDeleteUnitsToggle or false
selectedStar = config.SelectStarDropdown or "Star_1"
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

-- Auto Farm loop
task.spawn(function()
    while getgenv().SeisenHubRunning do
        if isAuraEnabled then
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
                    pcall(function() ToServer:FireServer(unpack(args)) end)
                end
            end
        end
        task.wait(attackCooldown)
    end
end)

-- Auto Farm Toggle
LeftGroupbox:AddToggle("AutoFarmToggle", {
    Text = "Auto Farm (Kill Aura + Teleport)",
    Default = config.AutoFarmToggle or false,
    Callback = function(Value)
        disableAllAurasExcept("AutoFarm")
        config.AutoFarmToggle = Value
        isAuraEnabled = Value
        saveConfig()
    end
})

-- Fast Kill Aura Toggle
LeftGroupbox:AddToggle("FastKillAuraToggle", {
    Text = "Fast Kill Aura",
    Default = config.FastKillAuraToggle or false,
    Callback = function(Value)
        disableAllAurasExcept("FastKillAura")
        fastKillAuraEnabled = Value
        if Value then
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
            task.spawn(function()
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
        else
            local argsOff = {
                [1] = {
                    ["Value"] = false,
                    ["Path"] = {
                        [1] = "Settings",
                        [2] = "Is_Auto_Clicker",
                    },
                    ["Action"] = "Settings",
                }
            }
            pcall(function() ToServer:FireServer(unpack(argsOff)) end)
        end
        config.FastKillAuraToggle = Value
        saveConfig()
    end
})

-- Slow Kill Aura Toggle
LeftGroupbox:AddToggle("SlowKillAuraToggle", {
    Text = "Slow Kill Aura",
    Default = config.SlowKillAuraToggle or false,
    Callback = function(Value)
        disableAllAurasExcept("SlowKillAura")
        slowKillAuraEnabled = Value
        if Value then
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
            pcall(function() ToServer:FireServer(unpack(argsActivator)) end)
            task.spawn(function()
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
        else
            local argsOff = {
                [1] = {
                    ["Value"] = false,
                    ["Path"] = {
                        [1] = "Settings",
                        [2] = "Is_Auto_Clicker",
                    },
                    ["Action"] = "Settings",
                }
            }
            pcall(function() ToServer:FireServer(unpack(argsOff)) end)
        end
        config.SlowKillAuraToggle = Value
        saveConfig()
    end
})


LeftGroupbox:AddToggle("AutoRankToggle", {
    Text = "Auto Rank",
    Default = config.AutoRankToggle or false,
    Callback = function(Value)
        autoRankEnabled = Value
        if Value then
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
        config.AutoRankToggle = Value
        saveConfig()
    end
})

LeftGroupbox:AddToggle("AutoAcceptAllQuestsToggle", {
    Text = "Auto Accept & Claim All Quests",
    Default = config.AutoAcceptAllQuestsToggle or false,
    Callback = function(Value)
        autoAcceptAllQuestsEnabled = Value
        if Value then
            task.spawn(function()
                while autoAcceptAllQuestsEnabled and getgenv().SeisenHubRunning do
                    for questId = 1, 99 do
                        -- Accept quest
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

                        -- Complete quest
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
        config.AutoAcceptAllQuestsToggle = Value
        saveConfig()
    end
})

LeftGroupbox:AddToggle("AutoClaimAchievement", {
    Text = "Auto Achievements",
    Default = config.AutoClaimAchievement or false,
    Callback = function(Value)
        autoClaimAchievementsEnabled = Value

        -- Achievement definitions
        local achievements = {
            Total_Energy = 20,
            Total_Coins = 15,
            Friends_Bonus = 5,
            Time_Player = 8,
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

        -- Function to convert number to Roman numeral
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

        if Value then
            task.spawn(function()
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

        config.AutoClaimAchievement = Value
        saveConfig()
    end
})


-- ========== Auto Roll ==========

RightGroupbox:AddToggle("AutoRollDragonRaceToggle", {
    Text = "Auto Roll Dragon Race",
    Default = config.AutoRollDragonRaceToggle or false,
    Callback = function(Value)
        autoRollDragonRaceEnabled = Value
        if Value then
            -- Unlock Dragon Race before starting auto roll
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
            -- Start auto roll loop
            task.spawn(function()
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
        config.AutoRollDragonRaceToggle = Value
        saveConfig()
    end
})

RightGroupbox:AddToggle("AutoRollSaiyanEvolutionToggle", {
    Text = "Auto Spin Saiyan Evolution",
    Default = config.AutoRollSaiyanEvolutionToggle or false,
    Callback = function(Value)
        autoRollSaiyanEvolutionEnabled = Value
        if Value then
            -- Unlock Saiyan Evolution before starting auto roll
            local unlockArgs = {
                [1] = {
                    ["Upgrading_Name"] = "Unlock",
                    ["Action"] = "_Upgrades",
                    ["Upgrade_Name"] = "Saiyan_Evolution_Unlocker",
                }
            }
            pcall(function()
                ToServer:FireServer(unpack(unlockArgs))
            end)
            -- Start auto roll loop
            task.spawn(function()
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
        config.AutoRollSaiyanEvolutionToggle = Value
        saveConfig()
    end
})

-- Auto Roll: Stars
RightGroupbox:AddToggle("AutoRollStarsToggle", {
    Text = "Auto Roll Stars",
    Default = config.AutoRollStarsToggle or false,
    Callback = function(Value)
        autoRollEnabled = Value
        if Value then
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
        config.AutoRollStarsToggle = Value
        saveConfig()
    end
})

-- Dropdown to select Star
RightGroupbox:AddDropdown("SelectStarDropdown", {
    Values = {"Star_1", "Star_2", "Star_3"},
    Default = config.SelectStarDropdown or "Star_1",
    Multi = false,
    Text = "Select Star",
    Callback = function(Option)
        selectedStar = Option
        config.SelectStarDropdown = Option
        saveConfig()
    end
})

-- Slider for roll delay
RightGroupbox:AddSlider("DelayBetweenRollsSlider", {
    Text = "Delay Between Rolls",
    Min = 0.5,
    Max = 2,
    Default = config.DelayBetweenRollsSlider or 0.5,
    Suffix = "s",
    Callback = function(Value)
        delayBetweenRolls = Value
        config.DelayBetweenRollsSlider = Value 
        saveConfig()
    end
})

-- Section for Auto Delete Units
RightGroupbox:AddLabel("Auto Delete Settings")

RightGroupbox:AddToggle("AutoDeleteUnitsToggle", {
    Text = "Auto Delete Units",
    Default = config.AutoDeleteUnitsToggle or false,
    Callback = function(Value)
        autoDeleteEnabled = Value
        config.AutoDeleteUnitsToggle = Value 
        if Value then
            task.spawn(function()
                while autoDeleteEnabled and getgenv().SeisenHubRunning do
                    pcall(function()
                        for _, rarity in pairs(selectedRarities) do
                            local args = {
                                [1] = {
                                    ["Value"] = true,
                                    ["Path"] = {
                                        "Settings",
                                        "AutoDelete",
                                        "Stars",
                                        "7000" .. tostring(rarity),
                                        tostring(rarity)
                                    },
                                    ["Action"] = "Settings"
                                }
                            }
                            ToServer:FireServer(unpack(args))
                        end
                    end)
                    task.wait(2)
                end
            end)
        end
        saveConfig()
    end
})

RightGroupbox:AddDropdown("AutoDeleteRaritiesDropdown", {
    Values = {
        "Common and Below (1)", "Uncommon and Below (2)", "Rare and Below (3)",
        "Epic and Below (4)", "Legendary and Below (5)", "Mythical and Below (6)"
    },
    Default = config.AutoDeleteRaritiesDropdown or {},
    Multi = true,
    Text = "Rarities to Auto Delete",
    Callback = function(Options)
        if type(Options) == "string" then
        Options = {Options}
        end
        local maxRarity = 0

        for _, option in ipairs(Options) do
            local rarity = option:match("%((%d)%)")
            if rarity then
                local num = tonumber(rarity)
                if num > maxRarity then
                    maxRarity = num
                end
            end
        end

        local newSelected = {}
        for i = 1, maxRarity do
            table.insert(newSelected, i)
        end

        for _, oldRarity in ipairs(previouslySelectedRarities) do
            if not table.find(newSelected, oldRarity) then
                local args = {
                    [1] = {
                        ["Value"] = false,
                        ["Path"] = {
                            "Settings",
                            "AutoDelete",
                            "Stars",
                            "7000" .. tostring(oldRarity),
                            tostring(oldRarity)
                        },
                        ["Action"] = "Settings"
                    }
                }
                ToServer:FireServer(unpack(args))
            end
        end

        selectedRarities = newSelected
        previouslySelectedRarities = newSelected
        config.AutoDeleteRaritiesDropdown = Option
        saveConfig()
    end
})

-- ========== Auto Stats ==========
local autoStatsRunning = false
local selectedStat = "Damage"
local statKeyMap = {
    ["Damage"] = "Primary_Damage",
    ["Energy"] = "Primary_Energy",
    ["Coins"] = "Primary_Coins",
    ["Luck"] = "Primary_Luck"
}

StatsGroupbox:AddDropdown("AutoStatSingleDropdown", {
    Values = {"Damage", "Energy", "Coins", "Luck"},
    Default = config.AutoStatSingleDropdown or "Damage",
    Multi = false,
    Text = "Select Stat to Auto Assign",
    Callback = function(Selected)
        selectedStat = Selected
        config.AutoStatSingleDropdown = Selected
        saveConfig()
    end
})

StatsGroupbox:AddToggle("AutoAssignStatToggle", {
    Text = "Auto Assign Stat",
    Default = config.AutoAssignStatToggle or false,
    Callback = function(Value)
        autoStatsRunning = Value
        if Value then
            print("Auto Stats started for:", selectedStat)
            task.spawn(function()
                while autoStatsRunning and getgenv().SeisenHubRunning do
                    local args = {
                        [1] = {
                            ["Name"] = statKeyMap[selectedStat],
                            ["Action"] = "Assign_Level_Stats",
                            ["Amount"] = 1,
                        }
                    }
                    pcall(function()
                        ToServer:FireServer(unpack(args))
                    end)
                    task.wait(0.5)
                end
            end)
        else
            print("Auto Stats stopped.")
        end
        config.AutoAssignStatToggle = Value
        saveConfig()
    end
})

-- ========= Auto Collect Reward =========

RewardsGroupbox:AddToggle("AutoClaimTimeRewardToggle", {
    Text = "Auto Claim Time Reward",
    Default = config.AutoClaimTimeRewardToggle or false,
    Callback = function(Value)
        isAutoTimeRewardEnabled = Value
        if Value then
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
        config.AutoClaimTimeRewardToggle = Value
        saveConfig()
    end
})

RewardsGroupbox:AddToggle("AutoClaimDailyChestToggle", {
    Text = "Auto Claim Daily Chest",
    Default = config.AutoClaimDailyChestToggle or false,
    Callback = function(Value)
        isAutoDailyChestEnabled = Value
        if Value then
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
        config.AutoClaimDailyChestToggle = Value
        saveConfig()
    end
})

RewardsGroupbox:AddToggle("AutoClaimVipChestToggle", {
    Text = "Auto Claim Vip Chest (VIP Gamepass required)",
    Default = config.AutoClaimVipChestToggle or false,
    Callback = function(Value)
        isAutoVipChestEnabled = Value
        if Value then
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
        config.AutoClaimVipChestToggle = Value
        saveConfig()
    end
})

RewardsGroupbox:AddToggle("AutoClaimGroupChestToggle", {
    Text = "Auto Claim Group Chest",
    Default = config.AutoClaimGroupChestToggle or false,
    Callback = function(Value)
        isAutoGroupChestEnabled = Value
        if Value then
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
        config.AutoClaimGroupChestToggle = Value
        saveConfig()
    end
})

RewardsGroupbox:AddToggle("AutoClaimPremiumChestToggle", {
    Text = "Auto Claim Premium Chest (Premium User required)",
    Default = config.AutoClaimPremiumChestToggle or false,
    Callback = function(Value)
        isAutoPremiumChestEnabled = Value
        if Value then
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
        config.AutoClaimPremiumChestToggle = Value
        saveConfig()
    end
})


-- ========= Teleport & Dungeon =========


local teleportLocations = {
    ["Dungeon Lobby 1"] = "Dungeon_Lobby_1",
    ["Earth City"] = "Earth_City",
    ["Windmill Island"] = "Windmill_Island",
    -- Add more locations here if needed
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
            end)
        end
        config.MainTeleportDropdown = selected
        saveConfig()
    end
})



UnloadGroupbox:AddToggle("DisableNotificationsToggle", {
    Text = "Disable Notifications",
    Default = config.DisableNotificationsToggle or false,
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
            end
        end
        config.DisableNotificationsToggle = Value
        saveConfig()
    end
})


-- Dungeon difficulty options
local dungeonOptions = {
    "Dungeon_Easy",
    "Dungeon_Medium",
    "Dungeon_Hard",
    "Dungeon_Insane",
    "Dungeon_Crazy",
    "Leaf_Raid"
}

-- Store toggle states per dungeon
local selectedDungeons = {}
local autoEnterDungeon = false


-- Initialize selectedDungeons based on config
for _, dungeonName in ipairs(dungeonOptions) do
    selectedDungeons[dungeonName] = config[dungeonName .. "_Toggle"] or false
end


-- Master toggle: Auto Enter Dungeon
DungeonGroupbox:AddToggle("AutoEnterDungeonToggle", {
    Text = "Auto Enter Dungeon",
    Default = config.AutoUpgradeToggle or false,
    Callback = function(Value)
        autoEnterDungeon = Value
        if Value then
            task.spawn(function()
                local toServer = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("To_Server")
                while autoEnterDungeon and getgenv().SeisenHubRunning do
                    pcall(function()
                        for dungeonName, isEnabled in pairs(selectedDungeons) do
                            if isEnabled then
                                local args = {
                                    [1] = {
                                        ["Action"] = "_Enter_Dungeon",
                                        ["Name"] = dungeonName
                                    }
                                }
                                toServer:FireServer(unpack(args))
                                print("Trying to enter dungeon:", dungeonName)
                            end
                        end
                    end)
                    task.wait(2)
                end
            end)
        end
        config.AutoEnterDungeonToggle = Value
        saveConfig()
    end
})

-- Label above individual dungeon toggles
DungeonGroupbox:AddLabel("Dungeon Difficulty Toggles")

-- Create toggles for each dungeon difficulty
for _, dungeonName in ipairs(dungeonOptions) do
    DungeonGroupbox:AddToggle(dungeonName .. "_Toggle", {
        Text = dungeonName:gsub("_", " "), -- more readable
        Default = config[dungeonName .. "_Toggle"] or false,
        Callback = function(Value)
            selectedDungeons[dungeonName] = Value
            config[dungeonName .. "_Toggle"] = Value 
            saveConfig()
        end
    })
end


-- ========= Upgrades =========
local upgradeOptions = {
    "Star_Luck", "Damage", "Energy", "Coins", "Drops",
    "Avatar_Souls_Drop", "Movement_Speed", "Fast_Roll"
}

-- Store toggle states per upgrade
local enabledUpgrades = {}


-- Auto Upgrade toggle (master switch)
UpgradeGroupbox:AddToggle("AutoUpgradeToggle", {
    Text = "Auto Upgrade",
    Default = config.AutoEnterDungeonToggle or false,
    Callback = function(Value)
        autoUpgradeEnabled = Value
        if Value then
            task.spawn(function()
                local toServer = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("To_Server")
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
                                toServer:FireServer(unpack(args))
                            end
                        end
                    end)
                    task.wait(2)
                end
            end)
        end
        config.AutoUpgradeToggle = Value
        saveConfig()
    end
})

-- Add title label above toggles
UpgradeGroupbox:AddLabel("Upgrade List")

-- Create individual toggles
for _, upgradeName in ipairs(upgradeOptions) do
    UpgradeGroupbox:AddToggle(upgradeName .. "_Toggle", {
        Text = upgradeName:gsub("_", " "),
        Default = config[upgradeName .. "_Toggle"] or false,
        Callback = function(Value)
            enabledUpgrades[upgradeName] = Value
            config[upgradeName .. "_Toggle"] = Value
            saveConfig()
        end
    })
end



-- ========= UI SETTINGS =========

UnloadGroupbox:AddButton("Save Config", function()
    saveConfig()
end)

UnloadGroupbox:AddButton("Unload Seisen Hub", function()
    -- Stop all tasks and disable all toggles
    getgenv().SeisenHubRunning = false
    isAuraEnabled = false
    fastKillAuraEnabled = false
    slowKillAuraEnabled = false
    autoRollEnabled = false
    autoDeleteEnabled = false
    autoStatsRunning = false
    autoRankEnabled = false
    autoAcceptAllQuestsEnabled = false
    autoRollDragonRaceEnabled = false
    autoRollSaiyanEvolutionEnabled = false
    isAutoTimeRewardEnabled = false
    isAutoDailyChestEnabled = false
    isAutoVipChestEnabled = false
    isAutoGroupChestEnabled = false
    isAutoPremiumChestEnabled = false
    autoUpgradeEnabled = false
    autoEnterDungeon = false

    -- Disable server-side clicker
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

    -- Properly destroy the UI (Obsidian UI v3)
    if Library and Library.Unload then
        pcall(function()
            Library:Unload()
        end)
    elseif getgenv().SeisenHubUI and getgenv().SeisenHubUI.Parent then
        pcall(function()
            getgenv().SeisenHubUI:Destroy()
        end)
    end

    -- Disconnect any event connections (if you have any, e.g. rollResultEvent)
    if getgenv().SeisenHubConnections then
        for _, conn in ipairs(getgenv().SeisenHubConnections) do
            pcall(function() conn:Disconnect() end)
        end
        getgenv().SeisenHubConnections = nil
    end

    -- Clear all global variables
    getgenv().SeisenHubUI = nil
    getgenv().SeisenHubLoaded = nil
    getgenv().SeisenHubRunning = nil

    -- Optionally, remove config file (uncomment if you want to delete config)
    -- if isfile(configFile) then delfile(configFile) end

    print("[Seisen Hub] Fully unloaded.")
end)

-- Restore UI state for all flags
if Library.Flags then
    for flag, value in pairs(config) do
        if Library.Flags[flag] then
            Library.Flags[flag]:Set(value)
            -- Manually call the callback to ensure logic runs
            if Library.Flags[flag].Callback then
                Library.Flags[flag]:Callback(value)
            end
        end
    end
end
-- Restore UI state for all flags
if Library.Flags then
    for flag, value in pairs(config) do
        if Library.Flags[flag] then
            Library.Flags[flag]:Set(value)
            -- Manually call the callback to ensure logic runs
            if Library.Flags[flag].Callback then
                Library.Flags[flag]:Callback(value)
            end
        end
    end
end
