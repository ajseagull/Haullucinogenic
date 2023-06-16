local DrugActive = false

local attackers = nil
local attackersTable = {}
local playersTable = {}

local PedAmount = 0

local randomPlayerFound = false
local dict = "core"
local particleName = "ent_amb_smoke_foundry"

local invisible = false

local loop = false

local LastSeeTimer = 0

local function ResetStatus()
    for _, player in ipairs(GetActivePlayers()) do
        local players = GetPlayerPed(player)
        local OtherPlayers = GetPlayerServerId(player)
        if OtherPlayers ~= ped then
            for _, playerID in ipairs(GetActivePlayers()) do
                exports["pma-voice"]:toggleMutePlayer(playerID)
            end
        end
        SetEntityVisible(players, true, 0)
        for _, attacker in ipairs(attackersTable) do
            DeletePed(attacker)
        end
    end
    SetPedIsDrunk(GetPlayerPed(-1), false)
    SetPedMotionBlur(playerPed, false)
    AnimpostfxStopAll()
    SetTimecycleModifierStrength(0.0)
    Wait(1500)
    for _, attacker in ipairs(attackersTable) do
        DeletePed(attacker)
    end
end

local function SpawnPed()
    CreateThread(function()
        while DrugActive do
            Wait(0)
            
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


            RequestNamedPtfxAsset(dict)
            while not HasNamedPtfxAssetLoaded(dict) do
                Citizen.Wait(0)
            end

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
            Wait(2000)
            if PedAmount <= Config.MaxPeds then
                attackers = CreatePed(1, hash, playerCoords.x - math.random(15, 150), playerCoords.y - math.random(15, 150), playerCoords.z - 1, heading, false, true)
                table.insert(attackersTable, attackers)
                UseParticleFxAssetNextCall(dict)
                local attackersCoords = GetEntityCoords(attackers)
                local particle = StartParticleFxLoopedOnEntity(particleName, attackers, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
                SetPedAsGroupMember(attackers, "LSDEnemies")
                SetRelationshipBetweenGroups(5, GetHashKey("LSDEnemies"), GetHashKey("LSDUser"))
                SetRelationshipBetweenGroups(5, GetHashKey("LSDUser"), GetHashKey("LSDEnemies"))
                TaskCombatPed(attackers, ped, 0, 16)
                PedAmount = PedAmount + 1
                SetTimeout(1750, function()
                    RemoveParticleFx(particle, false)
                end)
            end
        end
    end)
end

local function SetVisibilty()
    local ped = PlayerPedId()
    local invisible = true
    local playersToContact = {}

    for _, player in ipairs(GetActivePlayers()) do
        local pedID = GetPlayerServerId(ped)
        local players = GetPlayerPed(player)
        local OtherPlayers = GetPlayerServerId(player)

        if otherPlayers ~= pedID then
            table.insert(playersToContact, OtherPlayers)
        end

        while DrugActive and invisible do
            Wait(0)

            for _, playerID in ipairs(GetActivePlayers()) do
                exports["pma-voice"]:toggleMutePlayer(playerID)
            end

            for _, player in ipairs(GetActivePlayers()) do
                local players = GetPlayerPed(player)
                if players ~= ped then
                    SetEntityVisible(players, false, 0)
                end
            end
                LastSeeTimer = LastSeeTimer + 1

            if LastSeeTimer >= Config.HowLongToSee then
                GetPlayersInRadius(10)
                for _, player in ipairs(GetActivePlayers()) do
                    if not randomPlayerFound then
                        TriggerServerEvent('cvt-drug:GetPlayerID')
                        randomPlayerFound = true
                    end
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
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = GetDistanceBetweenCoords(
                playerCoords.x, playerCoords.y, playerCoords.z,
                targetCoords.x, targetCoords.y, targetCoords.z
            )

            if distance <= radius then
                table.insert(players, player)
            end
        end
    end

    return players
end

RegisterNetEvent('cvt-drug:SetPlayerVisibility', function(player)
    invisible = false
    while not invisible do
        Wait(0)
        exports["pma-voice"]:toggleMutePlayer(player)
        SetEntityVisible(player, true, 0)
        LastSeeTimer = 0
        Wait(4500)
        randomPlayerFound = false
        LastSeeTimer = 0
        SetVisibilty()
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