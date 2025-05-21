_spawnedFurniture = nil

local _specCategories = {
    .storage,
    .beds,
}

function CreateFurniture(furniture)
    if _spawnedFurniture then
        DestroyFurniture()
    end

    _insideFurniture = furniture
    _spawnedFurniture = {}

    for k, v in ipairs(furniture) do
        PlaceFurniture(v)
    end
end

function PlaceFurniture(v)
    kprint("[DEBUG] Placing furniture", v)

    local model = GetHashKey(v.model)
    if LoadModel(model) then
        local obj = CreateObject(model, v.coords.x, v.coords.y, v.coords.z, false, true, false)
        SetEntityHeading(obj, v.heading + 0.0)
        FreezeEntityPosition(obj, true)

        while not DoesEntityExist(obj) do
            Wait(1)
        end

        kprint("[DEBUG] Furniture entity created", {
            id = v.id,
            model = v.model,
            coords = v.coords,
            heading = v.heading
        })

        local furnData = FurnitureConfig[v.model]
        local hasTargeting = false

        if furnData and furnData.placeGround then
            PlaceObjectOnGroundProperly(obj)
        end

        if furnData and _specCategories[furnData.cat] then
            kprint("[DEBUG] Adding targeting for furniture", {
                id = v.id,
                category = furnData.cat,
                model = v.model
            })

            local icon = "square"
            local menu = {
                {
                    icon = "arrows-up-down-left-right",
                    text = "Move",
                    event = "MLO:Client:OnMove",
                    data = { id = v.id },
                    isEnabled = function() return LocalPlayer.state.MLOfurnitureEdit end
                },
                {
                    icon = "trash",
                    text = "Delete",
                    event = "MLO:Client:OnDelete",
                    data = { id = v.id },
                    isEnabled = function() return LocalPlayer.state.MLOfurnitureEdit end
                },
                {
                    icon = "clone",
                    text = "Clone",
                    event = "MLO:Client:OnClone",
                    data = {
                        id = v.id,
                        model = v.model
                    },
                    isEnabled = function() return LocalPlayer.state.MLOfurnitureEdit end
                }
            }

            if furnData.cat == "storage" then
                icon = "boxes-packing"
                table.insert(menu, {
                    icon = "boxes-packing",
                    text = "Access Storage",
                    event = "AHS:Client:Stash",
                    isEnabled = function(data)
                        kprint("[DEBUG] Access Storage isEnabled called", {
                            insideProperty = _insideProperty,
                            propertiesLoaded = _propertiesLoaded
                        })
            
                        if _insideProperty and _propertiesLoaded then
                            local property = _properties[_insideProperty.id]
                            local cid = LocalPlayer.state.Character:GetData("ID")
                            local hasKey = property.keys and property.keys[cid]
                            local isPolice = LocalPlayer.state.onDuty == "police"
            
                            kprint("[DEBUG] Access Storage permission check", {
                                cid = cid,
                                hasKey = hasKey,
                                isPolice = isPolice
                            })
            
                            return hasKey or isPolice
                        end
            
                        return false
                    end
                })
            
                table.insert(menu, {
                    icon = "shirt",
                    text = "Open Wardrobe",
                    event = "AHS:Client:Closet",
                })
            elseif furnData.cat == "beds" then
                icon = "bed"
                table.insert(menu, {
                    icon = "bed",
                    text = "Logout",
                    event = "AHS:Client:Logout",
                    isEnabled = function(data)
                        kprint("[DEBUG] Logout isEnabled called", {
                            insideProperty = _insideProperty,
                            propertiesLoaded = _propertiesLoaded
                        })
            
                        if _insideProperty and _propertiesLoaded then
                            local property = _properties[_insideProperty.id]
                            local cid = LocalPlayer.state.Character:GetData("ID")
                            local hasKey = property.keys and property.keys[cid]
            
                            kprint("[DEBUG] Logout permission check", {
                                cid = cid,
                                hasKey = hasKey
                            })
            
                            return hasKey
                        end
            
                        return false
                    end
                })
            end            

            hasTargeting = true
            Targeting:AddEntity(obj, icon, menu)
        end

        table.insert(_spawnedFurniture, {
            id = v.id,
            entity = obj,
            model = v.model,
            targeting = hasTargeting,
        })

        Wait(1)
    else
        kprint("[ERROR] Failed to load furniture model", v.model)
    end
end

function DestroyFurniture(s)
    if _spawnedFurniture then
        for k, v in ipairs(_spawnedFurniture) do
            DeleteEntity(v.entity)
            if not s then
                Targeting:RemoveEntity(v.entity)
            end
        end

        _spawnedFurniture = nil
    end
end

function SetFurnitureEditMode(state)
    if _spawnedFurniture then
        if state then
            for k, v in ipairs(_spawnedFurniture) do
                if not v.targeting then
                    Targeting:AddEntity(v.entity, "square", {
                        {
                            icon = "arrows-up-down-left-right",
                            text = "Move",
                            event = "MLO:Client:OnMove",
                            data = {
                                id = v.id,
                            },
                        },
                        {
                            icon = "trash",
                            text = "Delete",
                            event = "MLO:Client:OnDelete",
                            data = {
                                id = v.id,
                            },
                        },
                        {
                            icon = "clone",
                            text = "Clone",
                            event = "MLO:Client:OnClone",
                            data = {
                                id = v.id,
                                model = v.model,
                            },
                        },
                    })
                end
            end

            Notification.Persistent:Standard("furniture", "Furniture Edit Mode Enabled - Third Eye Objects to Move or Delete Them")
        else
            for k, v in ipairs(_spawnedFurniture) do
                if not v.targeting then
                    Targeting:RemoveEntity(v.entity)
                end
            end

            Notification.Persistent:Remove("furniture")
        end

        LocalPlayer.state.MLOfurnitureEdit = state
    end
end

function CycleFurniture(direction)
    if direction then
        if _furnitureCategoryCurrent < #_furnitureCategory then
            _furnitureCategoryCurrent += 1
        else
            return
        end
    else
        if _furnitureCategoryCurrent > 1 then
            _furnitureCategoryCurrent -= 1
        else
            return
        end
    end

    InfoOverlay:Close()
    ObjectPlacer:Cancel(true, true)
    Wait(200)
    local fKey = _furnitureCategory[_furnitureCategoryCurrent]
    local fData = FurnitureConfig[fKey]
    if fData then
        InfoOverlay:Show(fData.name, string.format("Category: %s | Model: %s", FurnitureCategories[fData.cat]?.name or "Unknown", fKey))
    end
    ObjectPlacer:Start(GetHashKey(fKey), "MLO:Client:Place", {}, true, "MLO:Client:Cancel", true, fData.placeGround)
end

AddEventHandler("MLO:Client:Place", function(data, placement)
    if _placingFurniture then

        Callbacks:ServerCallback("MLO:PlaceFurniture", {
            model = _furnitureCategory[_furnitureCategoryCurrent],
            coords = {
                x = placement.coords.x,
                y = placement.coords.y,
                z = placement.coords.z,
            },
            heading = placement.rotation,
            data = data,
        }, function(success)
            if success then
                Notification:Success("Placed Item")
            else
                Notification:Error("Error")
            end

            _placingFurniture = false
            LocalPlayer.state.MLOplacingFurniture= false
            InfoOverlay:Close()

            if not _skipPhone then
                Phone:Open()
            end
        end)
    end
    DisablePauseMenu(false)
end)

AddEventHandler("MLO:Client:Cancel", function()
    if _placingFurniture then
        _placingFurniture = false
        LocalPlayer.state.MLOplacingFurniture= false

        if not _skipPhone then
            Phone:Open()
        end

        Wait(200)
        DisablePauseMenu(false)
        InfoOverlay:Close()
    end
end)

AddEventHandler("MLO:Client:Move", function(data, placement)
    if _placingFurniture and data.id then

        Callbacks:ServerCallback("MLO:MoveFurniture", {
            id = data.id,
            coords = {
                x = placement.coords.x,
                y = placement.coords.y,
                z = placement.coords.z,
            },
            heading = placement.rotation,
        }, function(success)
            if success then
                Notification:Success("Moved Item")
            else
                Notification:Error("Error")
            end

            _placingFurniture = false
            LocalPlayer.state.MLOplacingFurniture= false
            InfoOverlay:Close()

            if not _skipPhone then
                Phone:Open()
            end
        end)
    end
    DisablePauseMenu(false)
end)

AddEventHandler("MLO:Client:CancelMove", function(data)
    if _placingFurniture and data.id then
        if _insideFurniture then
            for k, v in ipairs(_insideFurniture) do
                if v.id == data.id then
                    PlaceFurniture(v)
                end
            end
        end

        Notification:Error("Move Cancelled")
        _placingFurniture = false
        LocalPlayer.state.MLOplacingFurniture= false
        if not _skipPhone then
            Phone:Open()
        end

        Wait(200)
        DisablePauseMenu(false)
    end
end)

RegisterNetEvent("MLO:Client:AddItem", function(property, index, item)
    if _insideProperty and _insideProperty.id == property and _spawnedFurniture then
        PlaceFurniture(item)
        table.insert(_insideFurniture, item)

        if LocalPlayer.state.MLOfurnitureEdit then
            SetFurnitureEditMode(false)
            Wait(100)
            SetFurnitureEditMode(true)
        end
    end
end)

RegisterNetEvent("MLO:Client:MoveItem", function(property, id, item)
    if _insideProperty and _insideProperty.id == property and _spawnedFurniture then

        local ns = {}
        local shouldUpdate = false
        for k, v in ipairs(_spawnedFurniture) do
            if v.id == id then
                DeleteEntity(v.entity)
                Targeting:RemoveEntity(v.entity)
                shouldUpdate = true
            else
                table.insert(ns, v)
            end
        end
        if shouldUpdate then
            _spawnedFurniture = ns
        end

        PlaceFurniture(item)

        if LocalPlayer.state.MLOfurnitureEdit then
            SetFurnitureEditMode(false)
            Wait(100)
            SetFurnitureEditMode(true)
        end

        for k, v in ipairs(_insideFurniture) do
            if v.id == id then
                _insideFurniture[k] = item
                break
            end
        end
    end
end)

RegisterNetEvent("MLO:Client:DeleteItem", function(property, id, furniture)
    if _insideProperty and _insideProperty.id == property and _spawnedFurniture then
        local ns = {}
        for k, v in ipairs(_spawnedFurniture) do
            if v.id == id then
                DeleteEntity(v.entity)
                Targeting:RemoveEntity(v.entity)
            else
                table.insert(ns, v)
            end
        end

        _spawnedFurniture = ns
        _insideFurniture = furniture
    end
end)

AddEventHandler("MLO:Client:OnMove", function(entity, data)
    MLOInt.Furniture:Move(data.id, true)
end)

AddEventHandler("MLO:Client:OnDelete", function(entity, data)
    MLOInt.Furniture:Delete(data.id)
end)

AddEventHandler("MLO:Client:OnClone", function(entity, data)
    MLOInt.Furniture:Place(data.model, false, {}, false, true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DestroyFurniture()
    end
end)

local _disablePause = false

function DisablePauseMenu(state)
    if _disablePause ~= state then
        _disablePause = state
        if _disablePause then
            CreateThread(function()
				while _disablePause do
					DisableControlAction(0, 200, true)
					Wait(1)
				end
			end)
        end
    end
end