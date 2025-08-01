local gamelist_content = game:HttpGet("https://raw.githubusercontent.com/Seisen88/Seisen-Hub-List/main/gamelist.lua")
if not gamelist_content then return end

local success, Games = pcall(function()
    return loadstring(gamelist_content)()
end)

if not success or type(Games) ~= "table" then return end

local gameId = tostring(game.GameId)
local placeId = tostring(game.PlaceId)

local scriptURL = Games[gameId] or Games[placeId] -- check GameId first, then fallback to PlaceId

if scriptURL then
    loadstring(game:HttpGet(scriptURL))()
else
    warn("No supported script found for this game. GameId: " .. gameId .. ", PlaceId: " .. placeId)
end
