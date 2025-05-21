RegisterNetEvent("AHS:Furniture:Previous", function()
	if _placingFurniture then
		CycleFurniture()
	elseif _previewingInterior and not _previewingInteriorSwitching then
		PrevPreview()
	end
end)

RegisterNetEvent("AHS:Furniture:Next", function()
	if _placingFurniture then
		CycleFurniture(true)
	elseif _previewingInterior and not _previewingInteriorSwitching then
		PrevPreview()
	end
end)

RegisterNetEvent("OpenRealStash", function(data)
    kprint("Inventory Data: " .. json.encode(data.menu[1].data.data.inventory))
    Inventory.Dumbfuck:Open(data.menu[1].data.data.inventory)
end)

RegisterNetEvent("AHS:Client:InnerStuff", function(propertyData, int, furniture)
	_insideProperty = propertyData
	_insideInterior = int	
	CreateFurniture(furniture)
end)

function extractHouseId(zoneId)
    if string.sub(zoneId, 1, 10) == "AHS:HOUSE:" then
        return string.match(zoneId, "AHS:HOUSE:([^:]+)")
    end
    return nil
end

AddEventHandler('Polyzone:Enter', function(id, point, insideZone, data)
    if string.sub(id, 1, 10) == "AHS:HOUSE:" then
        local houseId = extractHouseId(id)
        kprint("Extracted House ID:", houseId)
        
        if houseId then
            kprint(houseId)
            MLOInt.Enter(houseId)
            LocalPlayer.state.inMLOHouse = houseId
        else
            kprint("Failed to extract House ID from zone ID:", id)
        end
    end
end)

AddEventHandler('Polyzone:Exit', function(id, point, insideZone, data)
    if string.sub(id, 1, 10) == "AHS:HOUSE:" then
        kprint("[DEBUG] Detected house zone, extracting house ID...")
        local houseId = extractHouseId(id)
        
        if houseId then
            kprint("[DEBUG] Extracted house ID:", houseId)
            ExitProperty()
            LocalPlayer.state.inMLOHouse = nil
        else
            kprint("[ERROR] Failed to extract house ID from zone ID:", id)
        end
    end
end)

---- TARGETTING EVENTS ----
AddEventHandler("AHS:Client:Stash", function(t, data)
	MLOInt.Extras:Stash()
end)

AddEventHandler("AHS:Client:Closet", function(t, data)
	MLOInt.Extras:Closet()
end)

AddEventHandler("AHS:Client:Logout", function(t, data)
	MLOInt.Extras:Logout()
end)

AddEventHandler("AHS:Client:Crafting", function(t, data)
	Crafting.Benches:Open('property-'..data)
end)

AddEventHandler("AHS:Client:Duty", function(t, data)
	if not _propertiesLoaded then
		return
	end

	local property = _properties[data]
	if property?.data?.jobDuty then
		if LocalPlayer.state.onDuty == property?.data?.jobDuty then
			Jobs.Duty:Off(property?.data?.jobDuty)
		else
			Jobs.Duty:On(property?.data?.jobDuty)
		end
	end
end)