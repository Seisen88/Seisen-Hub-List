--!> UI + Platoboost Key System + Key Save + Webhook Logging

--// Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--// Webhook URL
local WEBHOOK_URL = "https://discord.com/api/webhooks/1401568771679846541/6ojRCXUGtbL6XKD7DeKXM5VyBzuAjPGKVn_1gO0FD-8hWaVTjcRBRP21iylNuEXhnJzz"

-- Config
local service = 5291
local secret = "54bdfa73-2775-4d6b-b81c-d253b77ed386"
local useNonce = true
local host = "https://api.platoboost.com"

-- Key Save Folder and File
local KEY_FOLDER = "SeisenHub"
local KEY_FILE = KEY_FOLDER .. "/seisen_key.txt"

-- Functions
local fSetClipboard = setclipboard or toclipboard
local fRequest = (syn and syn.request) or request or http_request or fluxus and fluxus.request
local fChar, fFloor, fRand, fTime = string.char, math.floor, math.random, os.time
local fGetHwid = gethwid or function() return Players.LocalPlayer.UserId end

-- Utilities
local function lEncode(tbl) return HttpService:JSONEncode(tbl) end
local function lDecode(str) return HttpService:JSONDecode(str) end
local function lDigest(str) return (hashfunc and hashfunc(str)) or str end
local function generateNonce()
	local str = ""
	for _ = 1, 16 do str = str .. fChar(fFloor(fRand() * (122 - 97 + 1)) + 97) end
	return str
end

--// Webhook Functions
local function getPHTime()
	local offset = 8 * 3600
	local utc = os.time(os.date("!*t"))
	return os.date("%Y-%m-%d %H:%M:%S", utc + offset)
end

local function getGameName()
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	return (success and info and info.Name) or "Unknown Game"
end

local function getHWID()
	return RbxAnalyticsService:GetClientId()
end

local function sendWebhookLog(key, valid)
	local payload = {
		["username"] = "Key System Logger",
		["embeds"] = { {
			["title"] = "🔐 Game Key Check",
			["color"] = valid and 65280 or 16711680,
			["fields"] = {
				{ ["name"] = "👤 Player name", ["value"] = LocalPlayer.Name, ["inline"] = true },
				{ ["name"] = "🔑 Key entered", ["value"] = key, ["inline"] = true },
				{ ["name"] = "🧾 HWID / Device ID", ["value"] = getHWID(), ["inline"] = false },
				{ ["name"] = "🆔 UserId", ["value"] = tostring(LocalPlayer.UserId), ["inline"] = true },
				{ ["name"] = "📅 Account age", ["value"] = LocalPlayer.AccountAge .. " days", ["inline"] = true },
				{ ["name"] = "🗺️ Game name", ["value"] = getGameName(), ["inline"] = true },
				{ ["name"] = "📍 PlaceId", ["value"] = tostring(game.PlaceId), ["inline"] = true },
				{ ["name"] = "🕒 Time in PH timezone", ["value"] = getPHTime(), ["inline"] = false }
			},
			["footer"] = { ["text"] = "Seisen Hub | Platoboost System" },
			["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
		} }
	}

	local success = pcall(function()
		fRequest({
			Url = WEBHOOK_URL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = lEncode(payload)
		})
	end)
	
	return success
end

local function onMessage(msg)
	if StatusLabel then StatusLabel.Text = "Status: " .. msg end
end

-- Cache Key URL
local cachedLink, cachedTime = "", 0
local function cacheLink()
	if cachedTime + (10 * 60) < fTime() then
		local res = fRequest({
			Url = host .. "/public/start",
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = lEncode({service = service, identifier = lDigest(fGetHwid())})
		})
		if res.StatusCode == 200 then
			local decoded = lDecode(res.Body)
			if decoded.success then
				cachedLink = decoded.data.url
				cachedTime = fTime()
				return true, cachedLink
			else
				onMessage(decoded.message)
			end
		else
			onMessage("Link fetch failed.")
		end
		return false
	else
		return true, cachedLink
	end
end

-- Copy Key Link
local function copyLink()
	local ok, link = cacheLink()
	if ok then
		fSetClipboard(link)
		onMessage("Key link copied!")
	else
		onMessage("Failed to copy key link.")
	end
end

-- Redeem Key (if it's a KEY_ string)
local function redeemKey(key)
	local body = {
		identifier = lDigest(fGetHwid()),
		key = key
	}
	if useNonce then body.nonce = generateNonce() end
	local res = fRequest({
		Url = host .. "/public/redeem/" .. service,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = lEncode(body)
	})
	if res.StatusCode == 200 then
		local decoded = lDecode(res.Body)
		if decoded.success and decoded.data.valid then
			if not isfolder(KEY_FOLDER) then makefolder(KEY_FOLDER) end
			writefile(KEY_FILE, key)
			return true
		else
			onMessage(decoded.message or "Invalid key.")
		end
	else
		onMessage("Redeem failed.")
	end
	return false
end

-- Verify Key
local function verifyKey(key)
	local url = host .. "/public/whitelist/" .. service .. "?identifier=" .. lDigest(fGetHwid()) .. "&key=" .. key
	if useNonce then url = url .. "&nonce=" .. generateNonce() end
	local res = fRequest({Url = url, Method = "GET"})
	if res.StatusCode == 200 then
		local decoded = lDecode(res.Body)
		if decoded.success and decoded.data.valid then
			if not isfolder(KEY_FOLDER) then makefolder(KEY_FOLDER) end
			writefile(KEY_FILE, key)
			onMessage("Key valid.")
			return true
		elseif key:sub(1, 4) == "KEY_" then
			return redeemKey(key)
		else
			onMessage("Invalid key.")
		end
	else
		onMessage("Verify failed.")
	end
	return false
end

-- Load Main Script
local function loadSwordburst()
	task.spawn(function()
		local success, err = pcall(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/Seisen88/Seisen-Hub-List/refs/heads/main/Swordburst3_Test.lua"))()
		end)
		if not success then
			warn("Failed to load Swordburst:", err)
			onMessage("Failed to load main script.")
		end
	end)
end

-- Auto-check key before UI
local autoKey = ""
pcall(function()
	if not isfolder(KEY_FOLDER) then makefolder(KEY_FOLDER) end
	if isfile(KEY_FILE) then
		autoKey = readfile(KEY_FILE)
	end
end)

if autoKey ~= "" and verifyKey(autoKey) then
	loadSwordburst()
	return
end

--// Clean up if rerun
pcall(function() game.CoreGui.KeySystemUI:Destroy() end)

--// UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "KeySystemUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local Shadow = Instance.new("Frame", ScreenGui)
Shadow.Size = UDim2.new(0, 310, 0, 190)
Shadow.Position = UDim2.new(0.5, -149, 0.5, -89)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.8
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 0
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 10)

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 310, 0, 190)
Frame.Position = UDim2.new(0.5, -155, 0.5, -95)
Frame.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.ZIndex = 1
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Frame).Color = Color3.fromRGB(60, 60, 70)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, -30, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "🔑 Seisen Hub Key System"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.ZIndex = 2
Title.TextXAlignment = Enum.TextXAlignment.Left

local Close = Instance.new("TextButton", Frame)
Close.Text = "✖"
Close.Size = UDim2.new(0, 25, 0, 25)
Close.Position = UDim2.new(1, -30, 0, 5)
Close.BackgroundTransparency = 1
Close.TextColor3 = Color3.fromRGB(200, 80, 80)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 18
Close.ZIndex = 2
Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local KeyBox = Instance.new("TextBox", Frame)
KeyBox.PlaceholderText = "Enter Key Here"
KeyBox.Size = UDim2.new(0.9, 0, 0, 30)
KeyBox.Position = UDim2.new(0.05, 0, 0, 45)
KeyBox.Text = ""
KeyBox.TextSize = 14
KeyBox.ClearTextOnFocus = false
KeyBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
KeyBox.TextColor3 = Color3.new(1,1,1)
KeyBox.Font = Enum.Font.Gotham
KeyBox.ZIndex = 2
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", KeyBox).Color = Color3.fromRGB(70, 70, 80)

local GetKeyBtn = Instance.new("TextButton", Frame)
GetKeyBtn.Text = "📎 Get Key"
GetKeyBtn.Size = UDim2.new(0.43, 0, 0, 30)
GetKeyBtn.Position = UDim2.new(0.05, 0, 0, 90)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyBtn.Font = Enum.Font.Gotham
GetKeyBtn.TextSize = 14
GetKeyBtn.ZIndex = 2
Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", GetKeyBtn).Color = Color3.fromRGB(80, 80, 90)

local CheckKeyBtn = Instance.new("TextButton", Frame)
CheckKeyBtn.Text = "✔️ Check Key"
CheckKeyBtn.Size = UDim2.new(0.43, 0, 0, 30)
CheckKeyBtn.Position = UDim2.new(0.52, 0, 0, 90)
CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
CheckKeyBtn.TextColor3 = Color3.new(1, 1, 1)
CheckKeyBtn.Font = Enum.Font.Gotham
CheckKeyBtn.TextSize = 14
CheckKeyBtn.ZIndex = 2
Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", CheckKeyBtn).Color = Color3.fromRGB(90, 90, 100)

StatusLabel = Instance.new("TextLabel", Frame)
StatusLabel.Text = "Status: Waiting..."
StatusLabel.Size = UDim2.new(0.9, 0, 0, 30)
StatusLabel.Position = UDim2.new(0.05, 0, 0, 135)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex = 2

--// Dragging Logic
local UIS = game:GetService("UserInputService")
local dragging, dragInput, mousePos, framePos = false

Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		mousePos = input.Position
		framePos = Frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - mousePos
		Frame.Position = UDim2.new(
			framePos.X.Scale,
			framePos.X.Offset + delta.X,
			framePos.Y.Scale,
			framePos.Y.Offset + delta.Y
		)
		Shadow.Position = Frame.Position + UDim2.new(0, 6, 0, 6)
	end
end)

-- Button Events
GetKeyBtn.MouseButton1Click:Connect(copyLink)

CheckKeyBtn.MouseButton1Click:Connect(function()
	local key = KeyBox.Text
	if key == "" then
		onMessage("Please enter a key.")
		return
	end
	onMessage("Verifying key...")
	local valid = verifyKey(key)
	
	-- Send webhook log
	sendWebhookLog(key, valid)
	
	if valid then
		ScreenGui:Destroy()
		loadSwordburst()
	end
end)
