local listUrl = "https://raw.githubusercontent.com/Seisen88/Seisen-Hub-List/refs/heads/main/GameList.lua"

local function safeHttpGet(url)
    local ok, res = pcall(game.HttpGet, game, url)
    return ok and res or nil
end

local data = safeHttpGet(listUrl)
if data then
    local games = loadstring("return " .. data)()
    local id = tostring(game.PlaceId)
    local scriptUrl = games[id]
    if scriptUrl then
        loadstring(safeHttpGet(scriptUrl))()
    end
end
