local radios = {}
local currentRadioToken
local currentVolume = -1
local userVolume = 1.0

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function setRadio(radio)
    local netId = tonumber(radio.netId)
    if not netId or type(radio.videoId) ~= 'string' then
        return
    end

    radio.netId = netId
    radio.receivedAt = GetGameTimer()
    radio.offset = tonumber(radio.offset) or 0
    radios[netId] = radio
end

RegisterNetEvent('standaloneCarRadio:sync', function(snapshot)
    radios = {}
    if type(snapshot) == 'table' then
        for _, radio in ipairs(snapshot) do
            setRadio(radio)
        end
    end
end)

RegisterNetEvent('standaloneCarRadio:setRadio', setRadio)

RegisterNetEvent('standaloneCarRadio:removeRadio', function(netId)
    netId = tonumber(netId)
    if netId then
        radios[netId] = nil
    end
end)

RegisterNetEvent('standaloneCarRadio:requestResult', function(success, message)
    SendNUIMessage({
        type = 'requestResult',
        success = success == true,
        message = message
    })
    if success ~= true then
        notify(message)
    end
end)

RegisterCommand(Config.Command, function()
    if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then
        notify('Get in a vehicle to use the car radio.')
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'open' })
end, false)

RegisterNUICallback('close', function(_, callback)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
    callback({ ok = true })
end)

RegisterNUICallback('play', function(data, callback)
    if type(data) == 'table' and type(data.videoId) == 'string' then
        TriggerServerEvent('standaloneCarRadio:play', data.videoId)
    end
    callback({ ok = true })
end)

RegisterNUICallback('stop', function(_, callback)
    TriggerServerEvent('standaloneCarRadio:stop')
    callback({ ok = true })
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local nearest
        local nearestDistance

        for netId, radio in pairs(radios) do
            local vehicle = NetworkGetEntityFromNetworkId(netId)
            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                local distance = #(playerCoords - GetEntityCoords(vehicle))
                if distance <= Config.MaxDistance and (not nearestDistance or distance < nearestDistance) then
                    nearest = radio
                    nearestDistance = distance
                end
            end
        end

        if nearest then
            local token = ('%s:%s'):format(nearest.netId, nearest.revision)
            local volume = Config.MaxVolume * userVolume
            if Config.DistanceFalloff and nearestDistance then
                volume = volume * math.max(0.0, 1.0 - nearestDistance / Config.MaxDistance)
            end

            if token ~= currentRadioToken then
                currentRadioToken = token
                SendNUIMessage({
                    type = 'play',
                    videoId = nearest.videoId,
                    offset = math.max(0, nearest.offset + (GetGameTimer() - nearest.receivedAt) / 1000),
                    volume = volume
                })
                currentVolume = volume
            elseif math.abs(volume - currentVolume) > 0.002 or currentVolume < 0 then
                SendNUIMessage({ type = 'volume', volume = volume })
                currentVolume = volume
            end
        elseif currentRadioToken then
            currentRadioToken = nil
            currentVolume = -1
            SendNUIMessage({ type = 'stop' })
        end

        Wait(500)
    end
end)

RegisterNUICallback('setUserVolume', function(data, callback)
    local volume = tonumber(data and data.volume)
    if volume then
        userVolume = math.max(0.0, math.min(1.0, volume))
    end
    callback({ ok = true })
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1000)
        TriggerServerEvent('standaloneCarRadio:requestSync')
    end
end)
