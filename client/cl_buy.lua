ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

local open = false
local mainMenu = RageUI.CreateMenu("Hotel", "Interaction", nil, nil, "root_cause5", "img_red")
mainMenu.Display.Header = true
mainMenu.Closed = function()
    open = false
    FreezeEntityPosition(PlayerPedId(), false)
end

function BuyHotel(price, id, owner)
    if open then
        open = false
        RageUI.Visible(mainMenu, false)
    else
        FreezeEntityPosition(PlayerPedId(), true)
        open = true
        RageUI.Visible(mainMenu, true)
        Citizen.CreateThread(function()
            while open do
                Wait(0)
                RageUI.IsVisible(mainMenu, function()
                    RageUI.Separator(("Prix: ~g~%s$~s~"):format(price))
                    if owner == nil then RageUI.Separator("Status: ~r~Non loué~s~") else RageUI.Separator("Status: ~g~Loué~s~") end
                    RageUI.Line()
                    if owner == nil then
                        RageUI.Button("Louer cette chambre", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                            onSelected = function()
                                TriggerServerEvent("xHotel:buy", price, id)
                                RageUI.CloseAll()
                                FreezeEntityPosition(PlayerPedId(), false)
                            end
                        })
                    else 
                        RageUI.Button("Louer cette chambre", nil, {}, false, {})
                        RageUI.Button("Sonner à cette chambre", nil, {RightLabel = "→"}, true, {
                            onSelected = function()
                                TriggerServerEvent("xHotel:sonner", owner, id)
                            end
                        })
                    end
                end)
            end
        end)
    end
end

--- Xed#1188 | https://discord.gg/HvfAsbgVpM