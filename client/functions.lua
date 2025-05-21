_HouseList = {}

function ExitProperty()
    kprint("[DEBUG] ExitProperty function called")

    Callbacks:ServerCallback("AHS:ExitProperty", {}, function(pId)
        kprint("[DEBUG] Server callback returned with property ID:", pId)

        _insideProperty = false
        _insideInterior = false
        local property = _properties[pId]

        if not property then
            kprint("[ERROR] Property not found in _properties for ID:", pId)
            return
        end

        kprint("[DEBUG] Found property in _properties, destroying furniture and resetting states")

        DestroyFurniture()
        SetFurnitureEditMode(false)

        if _placingFurniture then
            kprint("[DEBUG] Canceling object placer and resetting phone route")
            ObjectPlacer:Cancel(true, true)
            Phone:ResetRoute()
            _placingFurniture = false
            LocalPlayer.state.placingFurniture = false
            LocalPlayer.state.furnitureEdit = false
        end
    end)

    Notification.Persistent:Remove("furniture")
    kprint("[DEBUG] Removed persistent notification 'furniture'")
end


function drawRectangle(coords, width, length, height, color)
    local halfWidth = width / 2
    local halfLength = length / 2
    local corners = {
        vector3(coords.x - halfWidth, coords.y - halfLength, coords.z),
        vector3(coords.x + halfWidth, coords.y - halfLength, coords.z),
        vector3(coords.x + halfWidth, coords.y + halfLength, coords.z),
        vector3(coords.x - halfWidth, coords.y + halfLength, coords.z)
    }
    for i = 1, #corners do
        local nextCorner = corners[(i % #corners) + 1]
        DrawLine(corners[i].x, corners[i].y, corners[i].z, nextCorner.x, nextCorner.y, nextCorner.z, color.r, color.g, color.b, color.a)
    end
end

function drawBox(coords, width, length, height, color)
    local halfWidth = width / 2
    local halfLength = length / 2
    local halfHeight = height / 2
    local corners = {
        vector3(coords.x - halfWidth, coords.y - halfLength, coords.z - halfHeight),
        vector3(coords.x + halfWidth, coords.y - halfLength, coords.z - halfHeight),
        vector3(coords.x + halfWidth, coords.y + halfLength, coords.z - halfHeight),
        vector3(coords.x - halfWidth, coords.y + halfLength, coords.z - halfHeight),
        vector3(coords.x - halfWidth, coords.y - halfLength, coords.z + halfHeight),
        vector3(coords.x + halfWidth, coords.y - halfLength, coords.z + halfHeight),
        vector3(coords.x + halfWidth, coords.y + halfLength, coords.z + halfHeight),
        vector3(coords.x - halfWidth, coords.y + halfLength, coords.z + halfHeight)
    }
    local edges = {
        {1, 2}, {2, 3}, {3, 4}, {4, 1},  -- Bottom face
        {5, 6}, {6, 7}, {7, 8}, {8, 5},  -- Top face
        {1, 5}, {2, 6}, {3, 7}, {4, 8}   -- Vertical edges
    }
    for _, edge in ipairs(edges) do
        local startCorner = corners[edge[1]]
        local endCorner = corners[edge[2]]
        DrawLine(startCorner.x, startCorner.y, startCorner.z, endCorner.x, endCorner.y, endCorner.z, color.r, color.g, color.b, color.a)
    end
end

function startShapeDebugDrawing()
    Citizen.CreateThread(function()
        while isDebuggingShapes do
            for _, house in ipairs(_HouseList) do
                local coords = vector3(house.coords.x, house.coords.y, house.coords.z)
                local width = house.width
                local length = house.length
                local height = house.options.maxZ - house.options.minZ
                local color = {r = 0, g = 255, b = 0, a = 255}

                drawBox(coords, width, length, height, color)
            end
            Citizen.Wait(0)
        end
    end)
end

exports('CheckPermForHouseClient', function(CharacterID, HouseLabel)
    local havePerm = DoseHeHaveAccessToThisDoor(CharacterID, HouseLabel)
    return havePerm
end)
----------------------- commands -----------------------

RegisterCommand("debugShapes", function()
    if Config.Debug then
        isDebuggingShapes = not isDebuggingShapes
        if isDebuggingShapes then
            kprint("Debug mode for shapes turned on.")
            startShapeDebugDrawing()
        else
            kprint("Debug mode for shapes turned off.")
        end
    end
end, false)

RegisterCommand("TestMe", function(source, args)
    if args[1] == nil then 
        kprint("Please enter house name") 
        return
    end
    local testthing = DoseHeHaveAccessToThisDoor(LocalPlayer.state.Character:GetData("ID"), args[1])
    kprint("Status:", testthing)
end, false)

