local DrugActive = false
local muted = false
local invisible = false

local attackers = nil

local PedAmount = 0

local function SpawnPed()
    CreateThread(function()
        while DrugActive do
            Wait(100)
            
            local ped = PlayerPedId()
            SetPedMotionBlur(ped, true)
            SetPedIsDrunk(ped, true)
            SetTimecycleModifier("spectator5")
            AnimpostfxPlay("Rampage", 10000001, true)
            MumbleSetVolumeOverrideByServerId(source, 0.0)
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
                Wait(100)
            end

            if PedAmount < Config.MaxPeds then
                attackers = CreatePed(1, hash, playerCoords.x - math.random(1, 4), playerCoords.y - math.random(1, 4), playerCoords.z - 1, heading, false, true)
                TaskCombatPed(attackers, ped, 0, 16)
                PedAmount = PedAmount + 1
                local attackerCoords = GetEntityCoords(attackers)
            end

            while DrugActive do
                Wait(0)
                for _, player in ipairs(GetActivePlayers()) do
                    local pedID = GetPlayerServerId(ped)
                    local players = GetPlayerPed(player)
                    local OtherPlayers = GetPlayerServerId(player)
                    if OtherPlayers ~= ped then
                        exports["pma-voice"]:toggleMutePlayer(OtherPlayers)
                        if players ~= ped then
                            SetEntityVisible(players, false, 0)
                        end
                    end
                end
            end

            SetTimeout(2500, function()
                DrugActive = false
                for _, player in ipairs(GetActivePlayers()) do
                    local players = GetPlayerPed(player)
                    local OtherPlayers = GetPlayerPed(player)
                    if OtherPlayers ~= ped then
                        SetEntityVisible(players, true)
                    end
                end
                DeletePed(attackers)
                local ped = PlayerPedId()
            end)
        end
    end)
end

RegisterCommand('drugstop', function()
    DrugActive = false
    for _, player in ipairs(GetActivePlayers()) do
        local players = GetPlayerPed(player)
        local OtherPlayers = GetPlayerServerId(player)
        if OtherPlayers ~= ped then
            exports["pma-voice"]:toggleMutePlayer(OtherPlayers)
        end
        SetEntityVisible(players, true, 0)
        DeletePed(attackers)
    end
    SetPedIsDrunk(GetPlayerPed(-1), false)
    SetPedMotionBlur(playerPed, false)
    AnimpostfxStopAll()
    SetTimecycleModifierStrength(0.0)
end)

RegisterCommand('drug', function()
    local ped = PlayerPedId()
    DrugActive = true
    SpawnPed()
end)

RegisterNetEvent('cvt-drug:setinvisible', function(player)
    local ped = PlayerPedId()
    for _, player in ipairs(GetActivePlayers()) do
        local OtherPlayers = GetPlayerPed(player)
        if OtherPlayers ~= ped then
            exports["pma-voice"]:toggleMutePlayer(OtherPlayers, true)
            SetEntityVisible(OtherPlayers, false)
        end
    end
end)