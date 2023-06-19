local DrugActive = false

local attackers = nil

local attackersTable = {}
local playersTable = {}
local mutedTable = {}
local invisbleTable = {}

local randomPlayerFound = false

local invisible = false

local LastSeeTimer = 0

local function MutePlayer(playerid)
    for _, player in ipairs(mutedTable) do
        if not mutedTable[playerid] then
            exports["pma-voice"]:toggleMutePlayer(playerid)
            mutedTable[playerid] = true
        else
            exports["pma-voice"]:toggleMutePlayer(playerid)
            mutedTable[playerid] = false
        end
    end
end

local function ChangePlayerAlpha(playerid)
    for _, player in ipairs(invisbleTable) do
        if not invisbleTable[playerid] then
            while alpha > 0 do
                Wait(15)
                alpha = alpha - 5
                SetEntityAlpha(players, alpha, false)
            end
            invisbleTable[playerid] = true
        else
            while alpha < 255 do
                Wait(15)
                alpha = alpha + 5
                SetEntityAlpha(players, alpha, false)
            end
            invisbleTable[playerid] = false
        end
    end
end

local function ResetStatus()
    local players = GetPlayersInRadius(50)
    for _, player in ipairs(players) do
        local OtherPlayers = GetPlayerServerId(player)
        if OtherPlayers ~= ped then
            MutePlayer(OtherPlayers)
        end
        ChangePlayerAlpha(player)
    end
    for i, attacker in ipairs(attackersTable) do
        DeletePed(attacker)
        table.remove(attackersTable, i)
    end
    SetPedIsDrunk(GetPlayerPed(-1), false)
    SetPedMotionBlur(playerPed, false)
    AnimpostfxStopAll()
    SetTimecycleModifierStrength(0.0)
    Wait(1500)
end

local function SpawnPed()
    CreateThread(function()
        while DrugActive do
            local ped = PlayerPedId()
            SetPedMotionBlur(ped, true)
            SetPedIsDrunk(ped, true)
            SetTimecycleModifier("spectator5")
            AnimpostfxPlay("Rampage", 10000001, true)
            MumbleSetVolumeOverrideByServerId(source, 0.0)
            local playerCoords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local PedPool = GetGamePool('CPed')
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
                attackers = CreatePed(1, hash, playerCoords.x - math.random(15, 150), playerCoords.y - math.random(15, 150), playerCoords.z - 1, heading, false, true)
                table.insert(attackersTable, attackers)
                alpha = 0
                SetEntityAlpha(attackers, alpha, false)
                while alpha < 255 do
                    Wait(15)
                    alpha = alpha + 5
                    SetEntityAlpha(attackers, alpha, false)
                end
                SetPedAsGroupMember(attackers, "LSDEnemies")
                SetRelationshipBetweenGroups(5, GetHashKey("LSDEnemies"), GetHashKey("LSDUser"))
                SetRelationshipBetweenGroups(5, GetHashKey("LSDUser"), GetHashKey("LSDEnemies"))
                TaskCombatPed(attackers, ped, 0, 16)
            end
            Wait(6500)
        end
    end)
end

local function SetVisibilty()
    local ped = PlayerPedId()
    local invisible = true

    while DrugActive and invisible do
        Wait(0)

        local players = GetPlayersInRadius(50)

        for _, player in ipairs(players) do
            local OtherPlayers = GetPlayerServerId(player)
            if OtherPlayers ~= ped then
                MutePlayer(OtherPlayers)
            end
            ChangePlayerAlpha(player)
        end

        LastSeeTimer = LastSeeTimer + 1

        if LastSeeTimer >= Config.HowLongToSee then
            local PlayerRadius = GetPlayersInRadius(20)
            for _, player in ipairs(PlayerRadius) do
                if not randomPlayerFound then
                    TriggerServerEvent('cvt-drug:GetPlayerID', player)
                    randomPlayerFound = true
                end
            end
        end
    end
end

function GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function GetPlayersInRadius(radius)
    local players = {}
    local playerPed = GetPlayerPed(-1)
    local playerCoords = GetEntityCoords(playerPed)

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(playerCoords - targetCoords)

        if distance <= radius and playerPed ~= targetPed then
            table.insert(players, player)
        end
    end

    return players
end


RegisterNetEvent('cvt-drug:SetPlayerVisibility', function(player)
    invisible = false
    while not invisible do
        Wait(0)
        exports["pma-voice"]:toggleMutePlayer(player)
        alpha = 0
        while alpha < 255 do
            Wait(15)
            alpha = alpha + 5
            SetEntityAlpha(player, alpha, false)
        end
        LastSeeTimer = 0
        Wait(4500)
        randomPlayerFound = false
        LastSeeTimer = 0
        SetVisibilty()
    end
end)

AddEventHandler('entityDamaged', function(victim, attacker, weapon, baseDmg)
    for i, npc in ipairs(attackersTable) do
        if victim == npc then
            if attacker == PlayerPedId() then
                alpha = 255
                while alpha > 0 do
                    Wait(15)
                    alpha = alpha - 5
                    SetEntityAlpha(victim, alpha, false)
                end
                DeletePed(victim)
                table.remove(attackersTable, i)
                print(#attackersTable)
                break
            end
        end
    end
end)

RegisterCommand('drugstop', function()
    if DrugActive then
        DrugActive = false
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
