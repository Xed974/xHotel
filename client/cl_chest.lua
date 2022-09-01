ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)

    AddTextEntry('FMMC_KEY_TIP1', TextEntry) 
    
    blockinput = true 
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "Somme", ExampleText, "", "", "", MaxStringLenght) 
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Citizen.Wait(0)
    end 

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500) 
        blockinput = false
        return result 
    else
        Citizen.Wait(500) 
        blockinput = false 
        return nil 
    end
end

local open = false
local mainMenu = RageUI.CreateMenu("Coffre", "Interaction", nil, nil, "root_cause5", "img_red")
local inventaire = RageUI.CreateSubMenu(mainMenu, "Inventaire", "Interaction")
local coffre = RageUI.CreateSubMenu(mainMenu, "Coffre", "Interaction")
mainMenu.Display.Header = true
mainMenu.Closed = function()
    open = false
    FreezeEntityPosition(PlayerPedId(), false)
end

local inventory, stock = {}, {}

local function getInventory()
    ESX.TriggerServerCallback("xHotel:getInventory", function(result) 
        inventory = result
    end)
end

local function getStock(id)
    ESX.TriggerServerCallback("xHotel:getStock", function(result) 
        stock = result
    end, id)
end

function openChestMenu(id)
    if open then
        open = false
        RageUI.Visible(mainMenu, false)
    else
        open = true
        RageUI.Visible(mainMenu, true)
        Citizen.CreateThread(function()
            while open do
                Wait(0)
                RageUI.IsVisible(mainMenu, function()
                    RageUI.Button("Déposer des objets", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() getInventory() end}, inventaire)
                    RageUI.Button("Retirer des objets", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() getStock(id) end}, coffre)
                end)
                RageUI.IsVisible(inventaire, function()
                    if #inventory > 0 then
                        for _,v in pairs(inventory) do
                            RageUI.Button(("~r~→~s~ %s"):format(v.label), nil, {RightLabel = ("~r~x%s~s~"):format(v.count)}, true, {
                                onSelected = function()
                                    local count = KeyboardInput("Combien souhaitez vous déposez:", "", 5)
                                    if count ~= nil and count ~= "" then
                                        if tonumber(count) then
                                            count = tonumber(count)
                                            if count > v.count then
                                                ESX.ShowNotification("(~r~Erreur~s~)\nVous n\'en avez pas suffisamment.")
                                            else
                                                TriggerServerEvent("xHotel:addItemChest", v.name, v.label, count, id)
                                                Wait(1000)
                                                getInventory()
                                            end
                                        else ESX.ShowNotification("(~r~Erreur~s~)\nQuantité invalide.") end
                                    else ESX.ShowNotification("(~r~Erreur~s~)\nQuantité invalide.") end
                                end
                            })
                        end
                    else
                        RageUI.Separator("")
                        RageUI.Separator("~r~Votre sac à dos est vide.")
                        RageUI.Separator("")
                    end
                end)
                RageUI.IsVisible(coffre, function()
                    for _,v in pairs(stock) do
                        if v.cb > 0 then
                            RageUI.Button(("~r~→~s~ %s"):format(v.label), nil, {RightLabel = ("~r~x%s~s~"):format(v.cb)}, true, {
                                onSelected = function()
                                    local count = KeyboardInput("Combien souhaitez vous prendre:", "", 5)
                                    if count ~= nil and count ~= "" then
                                        if tonumber(count) then
                                            count = tonumber(count)
                                            if count > v.cb then
                                                ESX.ShowNotification("(~r~Erreur~s~)\nIl y\'en à pas suffisamment dans le coffre.")
                                            else
                                                TriggerServerEvent("xHotel:removeItemChest", v.name, v.label, count, id)
                                                Wait(1000)
                                                getStock(id)
                                            end
                                        else ESX.ShowNotification("(~r~Erreur~s~)\nQuantité invalide.") end
                                    else ESX.ShowNotification("(~r~Erreur~s~)\nQuantité invalide.") end
                                end
                            })
                        end
                    end
                end)
            end
        end)
    end
end

--- Xed#1188 | https://discord.gg/HvfAsbgVpM