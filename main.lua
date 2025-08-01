local gamelist_content = game:HttpGet("https://raw.githubusercontent.com/Seisen88/Seisen-Hub-List/refs/heads/main/gamelist.lua")

if not gamelist_content then
    return 
end

local success, Games = pcall(function()
    return loadstring(gamelist_content)()
end)

if not success or type(Games) ~= "table" then
    return 
end

for PlaceID, Execute in pairs(Games) do
    if tonumber(PlaceID) == game.PlaceId then
        loadstring(game:HttpGet(Execute))()
        break 
    end
end
