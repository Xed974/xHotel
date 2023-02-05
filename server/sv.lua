ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback("xHotel:getHotel", function(source, cb)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    MySQL.Async.fetchAll("SELECT * FROM hotel", {}, function(result)
        if (result) then
            cb(result)
        end
    end)
end)

RegisterNetEvent("xHotel:setBucket")
AddEventHandler("xHotel:setBucket", function(id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    SetPlayerRoutingBucket(source, id)
end)

ESX.RegisterServerCallback("xHotel:getPlayerBucket", function(source, cb)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    cb(GetPlayerRoutingBucket(source))
end)

local function dateRented()
    local date = ('%s/%s/%s'):format(tonumber(os.date('%d'))+7, os.date('%m'), os.date('%Y'))

    if tonumber(os.date('%d'))+7 <= 31 then
        return date
    else
        local day = 31 - tonumber(os.date('%d'))
        local calcule = 7 - day
        local result  = 0 + calcule
        date = ('%s/%s/%s'):format(tonumber(result), tonumber(os.date('%m'))+1, os.date('%Y'))
        return date
    end
end

RegisterNetEvent("xHotel:buy")
AddEventHandler("xHotel:buy", function(price, id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    if (xPlayer.getAccount('bank').money) >= price then
        MySQL.Async.fetchAll("SELECT * FROM hotel WHERE owner = @owner", {
            ['@owner'] = xPlayer.getIdentifier()
        }, function(result)
            if result[1] == nil then
                MySQL.Async.execute("UPDATE hotel SET owner = @owner, dateRented = @dateRented WHERE id = @id", {
                    ['@owner'] = xPlayer.getIdentifier(),
                    ['@dateRented'] = dateRented(),
                    ['@id'] = id
                }, function()
                    xPlayer.removeAccountMoney('bank', price)
                    TriggerClientEvent('esx:showNotification', source, ('(~y~Information~s~)\nLe prochain loyer sera le ~r~%s~s~.'):format(dateRented()))
                end)
            else
                TriggerClientEvent('esx:showNotification', source, '(~r~Erreur~s~)\nVous avez déjà une chambre en location.')
            end
        end)

    else
        TriggerClientEvent('esx:showNotification', source, '(~r~Erreur~s~)\nVous n\'avez pas assez d\'argent.')
    end
end)

local listes = {}

ESX.RegisterServerCallback("xHotel:getListeSonner", function(source, cb)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    cb(listes)
end)

RegisterNetEvent("xHotel:sonner")
AddEventHandler("xHotel:sonner", function(owner, id)
    local source = source
    local xPlayere = ESX.GetPlayerFromId(source)

    if (not xPlayere) then return end
    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.getIdentifier() == owner then
            table.insert(listes, {nom = xPlayere.getName(), id = id, source = source})
            TriggerClientEvent("xHotel:notifsonner", xPlayer.source, listes)
            TriggerClientEvent('esx:showNotification', xPlayer.source, '(~y~Information~s~)\nQuelqu\'un à sonner à votre porte.')
        end
    end
end)

RegisterNetEvent("xHotel:enter")
AddEventHandler("xHotel:enter", function(source, id, pos)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    for _,v in pairs(listes) do
        if v.source == source then
            table.remove(listes,  _)
            TriggerClientEvent("xHotel:enterIn", source, id, pos)
        end
    end
end)

-- Chest

ESX.RegisterServerCallback("xHotel:getInventory", function(source, cb)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    local inventaire = xPlayer.getInventory()
    local send = {}
    for _,v in pairs(inventaire) do
        if v.count > 0 then table.insert(send, {name = v.name, label = v.label, count = v.count}) end
    end
    cb(send)
end)

RegisterNetEvent("xHotel:addItemChest")
AddEventHandler("xHotel:addItemChest", function(name, label, count, id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    local send = {}
    if (xPlayer.getInventoryItem(name).count) >= count then
        xPlayer.removeInventoryItem(name, count)
        MySQL.Async.fetchAll("SELECT chest FROM hotel WHERE id = @id", {
            ['@id'] = id
        }, function(result)
            if (result) then
                local data = json.decode(result[1].chest)
        
                if (data == nil) then
                    data = {}
                end
                if (data[name] == nil) then
                    data[name] = {name = name, cb = count, label = label}
                else
                    data[name] = {name = name, cb = data[name].cb + count, label = label}
                end
        
                MySQL.Async.execute("UPDATE hotel SET chest = @chest WHERE id = @id", {
                    ['@chest'] = json.encode(data),
                    ['@id'] = id
                }, function(update)
                    if update ~= nil then
                        TriggerClientEvent('esx:showNotification', source, ('Vous avez déposé ~g~x%s %s~s~.'):format(count, label))
                    end
                end)
            end
        end)
    end
end)

ESX.RegisterServerCallback("xHotel:getStock", function(source, cb, id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    MySQL.Async.fetchAll("SELECT chest FROM hotel WHERE id = @id", {
        ['@id'] = id
    }, function(result)
        if (result) then cb(json.decode(result[1].chest)) end
    end)
end)

RegisterNetEvent("xHotel:removeItemChest")
AddEventHandler("xHotel:removeItemChest", function(name, label, count, id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    MySQL.Async.fetchAll("SELECT chest FROM hotel WHERE id = @id", {
        ['@id'] = id
    }, function(result)
        local data = json.decode(result[1].chest)
        data[name] = {name = name, cb = data[name].cb - count, label = label}
        MySQL.Async.execute("UPDATE hotel SET chest = @chest WHERE id = @id", {
            ['@chest'] = json.encode(data),
            ['@id'] = id
        }, function(update)
            if update ~= nil then
                xPlayer.addInventoryItem(name, count)
                TriggerClientEvent('esx:showNotification', source, ('Vous avez retirer ~g~x%s %s~s~.'):format(count, label))
            end
        end)
    end)
end)

-- Cloakroom

RegisterNetEvent("xHotel:saveOutfit")
AddEventHandler("xHotel:saveOutfit", function(skin, name, id) 
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    MySQL.Async.fetchAll("SELECT cloakroom FROM hotel WHERE id = @id", {
        ['@id'] = id
    }, function(result)
        if (result) then
            local data = json.decode(result[1].cloakroom)
    
            if (data == nil) then
                data = {}
            end
            --if (data[name] == nil) then
                data[name] = {name = name, tenue = skin, use = 1}
            --end
    
            MySQL.Async.execute("UPDATE hotel SET cloakroom = @cloakroom WHERE id = @id", {
                ['@cloakroom'] = json.encode(data),
                ['@id'] = id
            }, function(update)
                if update ~= nil then
                    TriggerClientEvent('esx:showNotification', source, ('Votre tenue ~r~%s~s~ a été enregistrer avec succès.'):format(name))
                end
            end)
        end
    end)
end)

ESX.RegisterServerCallback("xHotel:getCloakroom", function(source, cb, id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    MySQL.Async.fetchAll("SELECT cloakroom FROM hotel WHERE id = @id", {
        ['@id'] = id
    }, function(result)
        if (result) then cb(json.decode(result[1].cloakroom)) end
    end)
end)

RegisterNetEvent("xHotel:deleteOutFit")
AddEventHandler("xHotel:deleteOutFit", function(tenue, name, id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    MySQL.Async.fetchAll("SELECT cloakroom FROM hotel WHERE id = @id", {
        ['@id'] = id
    }, function(result)
        local data = json.decode(result[1].cloakroom)
        
        if data[name] ~= nil then
            data[name] = {name = name, tenue = tenue, use = 0}
        end

        MySQL.Async.execute("UPDATE hotel SET cloakroom = @cloakroom WHERE id = @id", {
            ['@cloakroom'] = json.encode(data),
            ['@id'] = id
        }, function(update)
            if update ~= nil then
                TriggerClientEvent('esx:showNotification', source, ('Votre tenue ~r~%s~s~ a été supprimer.'):format(name))
            end
        end)
    end)
end)

--

RegisterNetEvent("xHotel:addColocataire")
AddEventHandler("xHotel:addColocataire", function(target, id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(target)

    if (not xPlayer) then return end
    MySQL.Async.execute("UPDATE hotel SET colocataire = @colocataire WHERE id = @id", {
        ['@colocataire'] = tPlayer.getIdentifier(),
        ['@id'] = id
    }, function()end)
end)

RegisterNetEvent("xHotel:rendre")
AddEventHandler("xHotel:rendre", function(id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    MySQL.Async.execute("UPDATE hotel SET owner = @owner, dateRented = @dateRented, chest = @chest, cloakroom = @cloakroom, colocataire = @colocataire WHERE owner = @identifier", {
        ['@owner'] = nil,
        ['@dateRented'] = nil,
        ['@chest'] = "[]",
        ['@cloakroom'] = "[]",
        ["@colocataire"] = nil,
        ['@identifier'] = xPlayer.getIdentifier()
    }, function()
        TriggerClientEvent('esx:showNotification', source, '(~g~Succès~s~)\nVous pouvez sortir de la chambre.')
    end)
end)

local function RemoveMoney(owner, price, date)
    local xPlayers = ESX.GetPlayers()
    for i = 1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.getIdentifier() == owner then
            xPlayer.removeAccountMoney('bank', price)
            MySQL.Async.execute("UPDATE hotel SET dateRented = @dataRented WHERE owner = @owner", {
                ['@dateRented'] = date,
                ['@owner'] = owner
            }, function()end)
            return
        end
    end
    MySQL.Async.fetchAll('SELECT accounts FROM users WHERE identifier = @identifier', { 
        ["@identifier"] = owner 
    }, function(result)
        local accounts = json.decode(result[1].accounts)
        if accounts.bank >= price then
            accounts.bank = accounts.bank - price
            MySQL.Async.execute("UPDATE users SET accounts = @accounts WHERE identifier = @identifier", {
                ['@accounts'] = json.encode(accounts),
                ['@identifier'] = owner
            }, function()end)
            MySQL.Async.execute("UPDATE hotel SET dateRented = @dataRented WHERE owner = @owner", {
                ['@dateRented'] = date,
                ['@owner'] = owner
            }, function()end)
        else
            MySQL.Async.execute("UPDATE hotel SET owner = @newowner, dateRented = @dateRented WHERE owner = @owner", {
                ['@newowner'] = nil,
                ['@dateRented'] = nil,
                ['@id'] = owner
            }, function()end)
        end
    end)
end

CreateThread(function()
    while true do
        MySQL.Async.fetchAll("SELECT * FROM hotel", {}, function(result)
            for _, v in pairs(result) do
                if v.dateRented ~= nil then
                    local date = os.date("%d/%m/%Y")
                    if date == v.dateRented and v.owner ~= nil then
                        RemoveMoney(v.owner, tonumber(v.price), ('%s/%s/%s'):format(tonumber(os.date('%d'))+7, os.date('%m'), os.date('%Y')))
                    end
                end
            end
        end)
        Wait(60000)
    end
end)

--- Xed#1188 | https://discord.gg/HvfAsbgVpM
