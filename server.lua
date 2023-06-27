
local IndexID = nil

RegisterNetEvent('prp-drug:GetPlayerID', function(player)
    local src = source
    local randomPlayer = GetRandomPlayer(player, src)
    print(randomPlayer)
    if randomPlayer ~= GetPlayerPed(src) then
        TriggerClientEvent('prp-drug:SetPlayerVisibility', src, randomPlayer)
        print(randomPlayer)
    end
end)

function GetRandomPlayer(players, excludedPlayer)
    if not players or #players == 0 then
        return -1
    end

    local randomIndex = math.random(1, #players)
    local randomPlayer = players[randomIndex]

    if randomPlayer == excludedPlayer then
        return GetRandomPlayer(players, excludedPlayer)
    end

    return randomPlayer
end
