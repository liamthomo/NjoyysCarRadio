local radios = {}
local revision = 0

local function getDriverVehicle(source)
    local ped = GetPlayerPed(source)
    if ped == 0 then
        return nil
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return nil
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then
        return nil
    end

    return netId
end

local function snapshot()
    local result = {}
    for _, radio in pairs(radios) do
        result[#result + 1] = {
            netId = radio.netId,
            videoId = radio.videoId,
            startedAt = radio.startedAt,
            revision = radio.revision,
            offset = math.max(0, os.time() - radio.startedAt)
        }
    end
    return result
end

RegisterNetEvent('standaloneCarRadio:requestSync', function()
    TriggerClientEvent('standaloneCarRadio:sync', source, snapshot())
end)

RegisterNetEvent('standaloneCarRadio:play', function(videoId)
    local player = source
    local netId = getDriverVehicle(player)

    if not netId then
        TriggerClientEvent('standaloneCarRadio:requestResult', player, false, 'You must be the driver to change this radio.')
        return
    end

    if type(videoId) ~= 'string' or #videoId ~= 11 or not videoId:match('^[%w_%-]+$') then
        TriggerClientEvent('standaloneCarRadio:requestResult', player, false, 'That does not look like a valid YouTube video ID.')
        return
    end

    revision = revision + 1
    local radio = {
        netId = netId,
        videoId = videoId,
        startedAt = os.time(),
        revision = revision,
        offset = 0
    }

    radios[netId] = radio
    TriggerClientEvent('standaloneCarRadio:setRadio', -1, radio)
    TriggerClientEvent('standaloneCarRadio:requestResult', player, true, 'Now playing.')
end)

RegisterNetEvent('standaloneCarRadio:stop', function()
    local player = source
    local netId = getDriverVehicle(player)

    if not netId then
        TriggerClientEvent('standaloneCarRadio:requestResult', player, false, 'You must be the driver to stop this radio.')
        return
    end

    if radios[netId] then
        radios[netId] = nil
        TriggerClientEvent('standaloneCarRadio:removeRadio', -1, netId)
    end

    TriggerClientEvent('standaloneCarRadio:requestResult', player, true, 'Radio stopped.')
end)

CreateThread(function()
    while true do
        Wait(10000)
        for netId in pairs(radios) do
            local vehicle = NetworkGetEntityFromNetworkId(netId)
            if vehicle == 0 or not DoesEntityExist(vehicle) then
                radios[netId] = nil
                TriggerClientEvent('standaloneCarRadio:removeRadio', -1, netId)
            end
        end
    end
end)
