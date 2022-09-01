ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
        Citizen.Wait(0)
    end
end)

local open = false
local mainMenu = RageUI.CreateMenu("Armoire", "Interaction", nil, nil, "root_cause5", "img_red")
local sub_menu1 = RageUI.CreateSubMenu(mainMenu, "Armoire", "Interaction")
local sub_menu2 = RageUI.CreateSubMenu(sub_menu1, "Armoire", "Interaction")
mainMenu.Display.Header = true
mainMenu.Closed = function()
    open = false
    FreezeEntityPosition(PlayerPedId(), false)
end

local armoire = {}

local function getCloakroom(id)
    ESX.TriggerServerCallback("xHotel:getCloakroom", function(result) 
        armoire = result
    end, id)
end

function openCloakroomMenu(id)
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
                    RageUI.Button("Enregistrer ma tenue", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                        onSelected = function()
                            local name = KeyboardInput("Nom de votre tenue", "", 30)
                            if name ~= nil and name ~= "" then
                                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                                    TriggerServerEvent("xHotel:saveOutfit", skin, name, id)
                                end)
                            else ESX.ShowNotification("(~r~Erreur~s~)\nNom invalide") end
                        end
                    })
                    RageUI.Line()
                    RageUI.Button("Voir mes tenues", nil, {RightLabel = "→"}, true, {onSelected = function() getCloakroom(id) end}, sub_menu1)
                end)
                RageUI.IsVisible(sub_menu1, function()
                    for _,v in pairs(armoire) do
                        if tonumber(v.use) == 1 then
                            RageUI.Button(("~r~→~s~ %s"):format(v.name), nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                                onSelected = function()
                                    name = v.name
                                    tenue = v.tenue
                                end
                            }, sub_menu2)
                        end
                    end
                end)
                RageUI.IsVisible(sub_menu2, function()
                    RageUI.Separator(("Tenue: ~r~%s"):format(name))
                    RageUI.Line()
                    RageUI.Button("Mettre la tenue", nil, {RightLabel = "→"}, true, {
                        onSelected = function()
                            TriggerEvent('skinchanger:loadSkin', tenue)
                        end
                    })
                    RageUI.Button("Supprimer la tenue", nil, {RightLabel = "→"}, true, {
                        onSelected = function()
                            TriggerServerEvent("xHotel:deleteOutFit", tenue, name, id)
                            RageUI.GoBack()
                            Wait(1000)
                            getCloakroom(id)
                        end
                    })
                end)
            end
        end)
    end
end

--- Xed#1188 | https://discord.gg/HvfAsbgVpM