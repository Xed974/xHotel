ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
    getHotel()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    getHotel()
end)

local hotel = {}
function getHotel()
    ESX.TriggerServerCallback("xHotel:getHotel", function(result) 
        hotel = result 
    end)
end

local bucketPlayer, id = 0, 0
function getPlayerBucket()
    ESX.TriggerServerCallback("xHotel:getPlayerBucket", function(result) 
        bucketPlayer = result
    end)
end

Citizen.CreateThread(function()
    getHotel()
    for _, v in pairs(xHotel.Position) do
        local blip = AddBlipForCoord(v.x, v.y, v.z)
        SetBlipSprite(blip, xHotel.Blips.id)
        SetBlipDisplay(blip, xHotel.Blips.display)
        SetBlipScale(blip, xHotel.Blips.scale)
        SetBlipColour(blip, xHotel.Blips.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(xHotel.Blips.title)
        EndTextCommandSetBlipName(blip)
    end
    while true do
        local wait = 1000
        
        for _,v in pairs(hotel) do
            local pPos = GetEntityCoords(PlayerPedId())
            local dstExit = Vdist(pPos.x, pPos.y, pPos.z, json.decode(v.posOut).x, json.decode(v.posOut).y, json.decode(v.posOut).z)
            local dstEnter = Vdist(pPos.x, pPos.y, pPos.z, json.decode(v.posIn).x, json.decode(v.posIn).y, json.decode(v.posIn).z)
            local dstChest = Vdist(pPos.x, pPos.y, pPos.z, json.decode(v.posChest).x, json.decode(v.posChest).y, json.decode(v.posChest).z)
            local dstCloakroom = Vdist(pPos.x, pPos.y, pPos.z, json.decode(v.posCloakroom).x, json.decode(v.posCloakroom).y, json.decode(v.posCloakroom).z)

            if dstExit <= xHotel.MarkerDistance then
                wait = 0
                DrawMarker(xHotel.MarkerType, json.decode(v.posOut).x, json.decode(v.posOut).y, (json.decode(v.posOut).z)-1.0, 0.0, 0.0, 0.0, 0.0,0.0,0.0, xHotel.MarkerSizeLargeur, xHotel.MarkerSizeEpaisseur, xHotel.MarkerSizeHauteur, xHotel.MarkerColorR, xHotel.MarkerColorG, xHotel.MarkerColorB, xHotel.MarkerOpacite, xHotel.MarkerSaute, true, p19, xHotel.MarkerTourne)
            end
            if dstExit <= xHotel.OpenMenuDistance then
                wait = 0
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour intéragir avec la chambre.")
                if IsControlJustPressed(1, 51) then
                    if ESX.PlayerData.identifier == v.owner then
                        TriggerServerEvent("xHotel:setBucket", tonumber(v.id))
                        DoScreenFadeOut(200)
                        Wait(200)
                        ESX.Game.Teleport(PlayerPedId(), json.decode(v.posIn), function()end)
                        Wait(1000)
                        DoScreenFadeIn(200)
                        getHotel()
                        getPlayerBucket()
                    elseif ESX.PlayerData.identifier == v.colocataire then
                        TriggerServerEvent("xHotel:setBucket", tonumber(v.id))
                        DoScreenFadeOut(200)
                        Wait(200)
                        ESX.Game.Teleport(PlayerPedId(), json.decode(v.posIn), function()end)
                        Wait(1000)
                        DoScreenFadeIn(200)
                        getHotel()
                        getPlayerBucket()
                    else
                        BuyHotel(tonumber(v.price), tonumber(v.id), v.owner)
                        getHotel()
                    end
                end
            end
            if tonumber(bucketPlayer) == tonumber(v.id) then
                if dstEnter <= xHotel.MarkerDistance then
                    wait = 0
                    DrawMarker(xHotel.MarkerType, json.decode(v.posIn).x, json.decode(v.posIn).y, (json.decode(v.posIn).z)-1.0, 0.0, 0.0, 0.0, 0.0,0.0,0.0, xHotel.MarkerSizeLargeur, xHotel.MarkerSizeEpaisseur, xHotel.MarkerSizeHauteur, xHotel.MarkerColorR, xHotel.MarkerColorG, xHotel.MarkerColorB, xHotel.MarkerOpacite, xHotel.MarkerSaute, true, p19, xHotel.MarkerTourne)
                end
                if dstEnter <= xHotel.OpenMenuDistance then
                    wait = 0
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour sortir de la chambre.")
                    if IsControlJustPressed(1, 51) then
                        TriggerServerEvent("xHotel:setBucket", 0)
                        DoScreenFadeOut(200)
                        Wait(200)
                        ESX.Game.Teleport(PlayerPedId(), json.decode(v.posOut), function()end)
                        Wait(1000)
                        DoScreenFadeIn(200)
                        getHotel()
                        bucketPlayer = 0
                    end
                end
                if dstChest <= xHotel.MarkerDistance then
                    wait = 0
                    DrawMarker(xHotel.MarkerType, json.decode(v.posChest).x, json.decode(v.posChest).y, (json.decode(v.posChest).z)-1.0, 0.0, 0.0, 0.0, 0.0,0.0,0.0, xHotel.MarkerSizeLargeur, xHotel.MarkerSizeEpaisseur, xHotel.MarkerSizeHauteur, xHotel.MarkerColorR, xHotel.MarkerColorG, xHotel.MarkerColorB, xHotel.MarkerOpacite, xHotel.MarkerSaute, true, p19, xHotel.MarkerTourne)
                end
                if dstChest <= xHotel.OpenMenuDistance then
                    wait = 0
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le coffre.")
                    if IsControlJustPressed(1, 51) then
                        FreezeEntityPosition(PlayerPedId(), true)
                        openChestMenu(tonumber(v.id))
                        getHotel()
                    end
                end
                if dstCloakroom <= xHotel.MarkerDistance then
                    wait = 0
                    DrawMarker(xHotel.MarkerType, json.decode(v.posCloakroom).x, json.decode(v.posCloakroom).y, (json.decode(v.posCloakroom).z)-1.0, 0.0, 0.0, 0.0, 0.0,0.0,0.0, xHotel.MarkerSizeLargeur, xHotel.MarkerSizeEpaisseur, xHotel.MarkerSizeHauteur, xHotel.MarkerColorR, xHotel.MarkerColorG, xHotel.MarkerColorB, xHotel.MarkerOpacite, xHotel.MarkerSaute, true, p19, xHotel.MarkerTourne)
                end
                if dstCloakroom <= xHotel.OpenMenuDistance then
                    wait = 0
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir l'armoire.")
                    if IsControlJustPressed(1, 51) then
                        FreezeEntityPosition(PlayerPedId(), true)
                        openCloakroomMenu(v.id)
                        getHotel()
                    end
                end
            end
            if ESX.PlayerData.identifier == v.owner then id = tonumber(v.id) end
        end    
        Citizen.Wait(wait)
    end
end)

RegisterCommand("openOwnerMenu", function()
    getPlayerBucket()
    if tonumber(bucketPlayer) ~= 0 then
        OwnerMenu(id)
    end
end)

--- Xed#1188 | https://discord.gg/HvfAsbgVpM