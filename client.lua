local DrugActive = false

local attackers = nil

local attackersTable = {}
local playersTable = {}
local mutedTable = {}
local invisbleTable = {}

local randomPlayerFound = false

local invisible = false

local LastSeeTimer = 0

local PlayerAlpha = 255
local EnemyAlpha = 255

local function MutePlayer(playerid)
    local ped = PlayerPedId()
    if not mutedTable[playerid] then
        if mutedTable[playerid] ~= ped then
            mutedTable[playerid] = true
            exports["pma-voice"]:toggleMutePlayer(mutedTable[playerid])
        end 
    end
end

local function ChangePlayerAlpha(playerid)
    local player = GetPlayerPed(playerid)
    local ped = PlayerPedId()
    if not invisbleTable[playerid] then
        if invisbleTable[playerid] ~= ped then
            while PlayerAlpha >= 1 do
                Wait(10)
                PlayerAlpha = PlayerAlpha - 1
                SetEntityAlpha(player, PlayerAlpha, false)
            end
            invisbleTable[playerid] = true
        end
    end
end

local function ResetStatus()
    local ped = PlayerPedId()
    local players = GetPlayersInRadius(50)
    DrugActive = false
    for i, attacker in ipairs(attackersTable) do
        DeletePed(attacker)
        table.remove(attackersTable, i)
    end
    for _, player in ipairs(players) do
        local OtherPlayers = GetPlayerServerId(player)
        local playerPed = GetPlayerPed(player)
        if mutedTable[OtherPlayers] then
            if mutedTable[OtherPlayers] ~= ped then
                exports["pma-voice"]:toggleMutePlayer(mutedTable[OtherPlayers])
                mutedTable[OtherPlayers] = false
            end 
        end
        if invisbleTable[player] then
            if invisbleTable[player] ~= ped then
                while PlayerAlpha <= 254 do
                    Wait(10)
                    PlayerAlpha = PlayerAlpha + 1
                    SetEntityAlpha(playerPed, PlayerAlpha, false)
                    invisbleTable[player] = false
                end
            end
        end
    end
    SetPedIsDrunk(ped, false)
    SetPedMotionBlur(ped, false)
    AnimpostfxStopAll()
    SetTimecycleModifierStrength(0.0)
    Wait(1500)
end

local function SpawnPed()
    local ped = PlayerPedId()
    SetPedMotionBlur(ped, true)
    SetPedIsDrunk(ped, true)
    AnimpostfxPlay("Rampage", 10000001, true)
    SetTimecycleModifier("spectator5")
    CreateThread(function()
        while DrugActive do

            local playerCoords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local models = {}


            for key, value in pairs(Config.PedModels) do
                table.insert(models, value[1])
            end

            local randomModelIndex = math.random(1, #models)
            local randomModel = models[randomModelIndex]

            local hash = GetHashKey(randomModel)

            RequestModel(hash)
            while not HasModelLoaded(hash) do
                Wait(0)
            end

            AddRelationshipGroup("LSDEnemies")
            AddRelationshipGroup("LSDUser")
            SetPedAsGroupLeader(ped, "LSDUser")
            if #attackersTable <= Config.MaxPeds then
                attackers = CreatePed(1, hash, playerCoords.x - math.random(1, 5), playerCoords.y - math.random(1, 5), playerCoords.z - 1, heading, false, true)
                table.insert(attackersTable, attackers)
                SetPedAsGroupMember(attackers, "LSDEnemies")
                SetRelationshipBetweenGroups(0, GetHashKey("LSDEnemies"), GetHashKey("LSDEnemies"))
                SetRelationshipBetweenGroups(5, GetHashKey("LSDEnemies"), GetHashKey("LSDUser"))
                SetRelationshipBetweenGroups(5, GetHashKey("LSDUser"), GetHashKey("LSDEnemies"))
                TaskCombatPed(attackers, ped, 0, 16)
                EnemyAlpha = 0
                SetEntityAlpha(attackers, EnemyAlpha, false)
                while EnemyAlpha <= 254 do
                    Wait(10)
                    EnemyAlpha = EnemyAlpha + 1
                    SetEntityAlpha(attackers, EnemyAlpha, false)
                end
            end

            Wait(6500)
        end
    end)
end

local function SetVisibilty()
    local ped = PlayerPedId()
    local invisible = true
    LastSeeTimer = 0

    while DrugActive and invisible do

        local players = GetPlayersInRadius(100.0)

        local PlayerList = {}

        for _, player in pairs(players) do
            local OtherPlayers = GetPlayerServerId(player)
            
            if OtherPlayers ~= ped then
                MutePlayer(OtherPlayers)
            end
            ChangePlayerAlpha(player)

            table.insert(PlayerList, OtherPlayers)
        end

        LastSeeTimer = LastSeeTimer + 1200

        if LastSeeTimer >= Config.HowLongToSee then
            local PlayerRadius = GetPlayersInRadius(10.0)
            for _, player in ipairs(PlayerRadius) do
                if not randomPlayerFound then
                    TriggerServerEvent('prp-drug:GetPlayerID', PlayerList)
                    randomPlayerFound = true
                end
            end
        end
        Wait(6500)
    end
end

function GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function GetPlayersInRadius(radius)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(playerCoords - targetCoords)

        if distance <= radius and playerPed ~= targetPed then
            table.insert(playersTable, player)
        end
    end

    return playersTable
end


RegisterNetEvent('prp-drug:SetPlayerVisibility', function(player)
    local ped = PlayerPedId()
    local playerId = GetPlayerFromServerId(player)
    local playerPed = GetPlayerPed(playerId)
    local ran = false
    if not ran then
        if mutedTable[player] then
            if mutedTable[player] ~= ped then
                exports["pma-voice"]:toggleMutePlayer(mutedTable[player])
                mutedTable[player] = false
            end 
        end
        PlayerAlpha = 1
        while PlayerAlpha <= 254 do
            Wait(10)
            PlayerAlpha = PlayerAlpha + 1
            SetEntityAlpha(playerPed, PlayerAlpha, false)
            invisbleTable[player] = false
        end
        LastSeeTimer = 0
        ran = true
        Wait(1500)
        randomPlayerFound = false
        while PlayerAlpha >= 1 do
            Wait(10)
            PlayerAlpha = PlayerAlpha - 1
            SetEntityAlpha(playerPed, PlayerAlpha, false)
            invisbleTable[player] = false
        end
    end
end)

AddEventHandler('entityDamaged', function(victim, attacker, weapon, baseDmg)
    for i, npc in ipairs(attackersTable) do
        if victim == npc then
            if attacker == PlayerPedId() then
                local VictimAlpha = 255
                while VictimAlpha >= 1 do
                    Wait(10)
                    VictimAlpha = VictimAlpha - 1
                    SetEntityAlpha(victim, VictimAlpha, false)
                end
                local CurrentAlpha = GetEntityAlpha(victim)
                if CurrentAlpha <= 0 then
                    DeletePed(victim)
                    table.remove(attackersTable, i)
                end
                break
            end
        end
    end
end)

RegisterCommand('drugstop', function()
    if DrugActive then
        ResetStatus()
    end
end)

RegisterCommand('drug', function()
    if not DrugActive then
        DrugActive = true
        SpawnPed()
        
        SetVisibilty()
    end
end)
