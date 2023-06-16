
local IndexID = nil

RegisterNetEvent('cvt-drug:GetPlayerID', function()
    local src = source
    local players = GetPlayers()
    local randomPlayer = GetRandomPlayer(players, src)
    if randomPlayer ~= -1 then
        TriggerClientEvent('cvt-drug:SetPlayerVisibility', src, randomPlayer)
    end
end)

function GetRandomPlayer(players, excludedPlayer)
    local numPlayers = #players
    if numPlayers == 0 then
        return -1
    end

    local randomIndex = math.random(1, numPlayers)
    local randomPlayer = players[randomIndex]

    if randomPlayer == excludedPlayer then
        return GetRandomPlayer(players, excludedPlayer)
    end

    return randomPlayer
end