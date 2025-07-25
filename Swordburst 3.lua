--!> UI + Platoboost Key System

-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- UI Elements
local ScreenGui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "KeySystemUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 180)
Frame.Position = UDim2.new(0.5, -150, 0.5, -90)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🔐 Platoboost Key System"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18

local KeyBox = Instance.new("TextBox", Frame)
KeyBox.PlaceholderText = "Enter Key Here"
KeyBox.Size = UDim2.new(0.9, 0, 0, 30)
KeyBox.Position = UDim2.new(0.05, 0, 0, 40)
KeyBox.Text = ""
KeyBox.TextSize = 14
KeyBox.ClearTextOnFocus = false
KeyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
KeyBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 6)

local GetKeyBtn = Instance.new("TextButton", Frame)
GetKeyBtn.Text = "📎 Get Key"
GetKeyBtn.Size = UDim2.new(0.43, 0, 0, 30)
GetKeyBtn.Position = UDim2.new(0.05, 0, 0, 80)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
GetKeyBtn.TextColor3 = Color3.new(1, 1, 1)
GetKeyBtn.Font = Enum.Font.Gotham
GetKeyBtn.TextSize = 14
Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 6)

local CheckKeyBtn = Instance.new("TextButton", Frame)
CheckKeyBtn.Text = "✔️ Check Key"
CheckKeyBtn.Size = UDim2.new(0.43, 0, 0, 30)
CheckKeyBtn.Position = UDim2.new(0.52, 0, 0, 80)
CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CheckKeyBtn.TextColor3 = Color3.new(1, 1, 1)
CheckKeyBtn.Font = Enum.Font.Gotham
CheckKeyBtn.TextSize = 14
Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel", Frame)
StatusLabel.Text = "🔒 Status: Waiting..."
StatusLabel.Size = UDim2.new(0.9, 0, 0, 30)
StatusLabel.Position = UDim2.new(0.05, 0, 0, 120)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Platoboost Config
local service = 5291
local secret = "54bdfa73-2775-4d6b-b81c-d253b77ed386"
local useNonce = true
local fSetClipboard = setclipboard or toclipboard
local fRequest = (syn and syn.request) or request or http_request or fluxus and fluxus.request
local fChar, fToString, fSub, fTime, fRand, fFloor = string.char, tostring, string.sub, os.time, math.random, math.floor
local fGetHwid = gethwid or function() return Players.LocalPlayer.UserId end

local cachedLink, cachedTime = "", 0
local requestSending = false
local host = "https://api.platoboost.com"

local function lEncode(tbl)
	return game:GetService("HttpService"):JSONEncode(tbl)
end

local function lDecode(str)
	return game:GetService("HttpService"):JSONDecode(str)
end

local function lDigest(str)
    if hashfunc then
        return hashfunc(str)
    else
        return str
    end
end

local function onMessage(msg)
	StatusLabel.Text = "📣 Status: " .. msg
end

local function cacheLink()
	if cachedTime + (10*60) < fTime() then
        local response = fRequest({
            Url = host .. "/public/start",
            Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = lEncode({ service = service, identifier = lDigest(fGetHwid()) })
		})
        if response.StatusCode == 200 then
			local decoded = lDecode(response.Body)
			if decoded.success then
				cachedLink = decoded.data.url
				cachedTime = fTime()
				return true, cachedLink
			else
				onMessage(decoded.message)
				return false
			end
		else
			onMessage("Link fetch failed")
			return false
		end
	else
		return true, cachedLink
    end
end

local function generateNonce()
    local str = ""
    for _ = 1, 16 do
		str = str .. fChar(fFloor(fRand() * (122 - 97 + 1)) + 97)
    end
    return str
end

local function copyLink()
	local success, link = cacheLink()
    if success then
		fSetClipboard(link)
		onMessage("Key link copied!")
	else
		onMessage("Failed to copy key link.")
    end
end

local function redeemKey(key)
	local nonce = generateNonce()
    local body = {
        identifier = lDigest(fGetHwid()),
        key = key
    }
	if useNonce then body.nonce = nonce end
    local response = fRequest({
		Url = host .. "/public/redeem/" .. service,
        Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = lEncode(body)
	})
    if response.StatusCode == 200 then
		local decoded = lDecode(response.Body)
		if decoded.success and decoded.data.valid then
			return true
		else
			onMessage(decoded.message or "Invalid key.")
			return false
        end    
    else
		onMessage("Redeem failed.")
		return false
    end
end

local function verifyKey(key)
	if requestSending then
		onMessage("Request in progress...")
		return false
	end
	requestSending = true
	local nonce = generateNonce()
	local url = host.."/public/whitelist/"..service.."?".."identifier="..lDigest(fGetHwid()).."&key="..key
	if useNonce then url = url.."&nonce="..nonce end
	local response = fRequest({ Url = url, Method = "GET" })
	requestSending = false
    if response.StatusCode == 200 then
		local decoded = lDecode(response.Body)
		if decoded.success and decoded.data.valid then
			onMessage("✅ Key valid.")
			return true
		elseif key:sub(1, 4) == "KEY_" then
			return redeemKey(key)
		else
			onMessage("❌ Invalid key.")
			return false
        end
    else
		onMessage("Verify failed.")
		return false
    end
end

-- Callbacks
GetKeyBtn.MouseButton1Click:Connect(copyLink)

CheckKeyBtn.MouseButton1Click:Connect(function()
	local key = KeyBox.Text
	if key == "" then
		onMessage("Please enter a key.")
		return
	end
	onMessage("Verifying key...")
	local valid = verifyKey(key)
	if valid then
		ScreenGui:Destroy()
		task.spawn(function()
			local success, result = pcall(function()
				return loadstring(game:HttpGet("https://raw.githubusercontent.com/Seisen88/Seisen-Hub-List/refs/heads/main/Swordburst3_Test.lua"))()
			end)
			if not success then
				warn("❌ Failed to load Swordburst 3 script:", result)
				onMessage("❌ Failed to load Swordburst 3 script.")
			end
		end)
	end
end)
