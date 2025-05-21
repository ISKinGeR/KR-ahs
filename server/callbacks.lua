function TryGetIdFromLabel(label)
    local p = promise.new()

    Database.Game:find({
        collection = "properties",
        query = {
            houseId = label,
            type = { ["$nin"] = { "container", "warehouse" } }
        },
    }, function(success, results)
        if success and #results > 0 then
            p:resolve(results[1]._id)
        else
            p:resolve(nil)
        end
    end)

    return Citizen.Await(p)
end

function RegisterCallbacks()
	Callbacks:RegisterServerCallback("AHS:EnterProperty", function(source, data, cb)
		local _idForLabel = TryGetIdFromLabel(data)	
		if _idForLabel then
			local char = Fetch:Source(source):GetData("Character")
	
			local property = _properties[_idForLabel]	
			if property then
				if not _insideProperties[property.id] then
					_insideProperties[property.id] = {}
				end
	
				local charSID = char:GetData("SID")
				_insideProperties[property.id][source] = charSID	
				local pInt = property.upgrades and property.upgrades.interior	
				GlobalState[string.format("%s:MLO:Property", source)] = _idForLabel
	
				local furniture = GetPropertyFurniture(property.id, pInt)
	
				TriggerClientEvent("AHS:Client:InnerStuff", source, property, pInt, furniture)
				cb(true)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)	
	
	Callbacks:RegisterServerCallback("AHS:ExitProperty", function(source, data, cb)
		print("[DEBUG] AHS:ExitProperty callback triggered")
		print("[DEBUG] Source:", source)
	
		local property = GlobalState[string.format("%s:MLO:Property", source)]
		print("[DEBUG] Retrieved property from GlobalState:", property)
	
		GlobalState[string.format("%s:MLO:Property", source)] = nil
		print("[DEBUG] Cleared GlobalState property entry for source")
	
		if _insideProperties[property] then
			_insideProperties[property][source] = nil
			print("[DEBUG] Removed player from _insideProperties for property:", property)
		else
			print("[DEBUG] Property not found in _insideProperties")
		end
	
		cb(property)
	end)
	

	Callbacks:RegisterServerCallback("AHS:EditProperty", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		local property = _properties[data.property]
		if property ~= nil and Player(source).state.onDuty == "realestate" and data.location then
			local ped = GetPlayerPed(source)
			local coords = GetEntityCoords(ped)
			local heading = GetEntityHeading(ped)

			if data.location == "garage" then
				local pos = {
					x = coords.x + 0.0,
					y = coords.y + 0.0,
					z = coords.z + 0.0,
					h = heading + 0.0
				}

				cb(MLOInt.Manage:AddGarage(data.property, pos))
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("AHS:Validate", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		local property = _properties[data.id]

		if data.type == "closet" then
			cb(property.keys and property.keys[char:GetData("ID")] ~= nil)
		elseif data.type == "logout" then
			cb(property.keys and property.keys[char:GetData("ID")] ~= nil)
		elseif data.type == "stash" then
			if property.keys and property.keys[char:GetData("ID")] ~= nil and property.id or Police:IsInBreach(source, "property", property.id, true) then
				local invType = 1000

				local capacity = false
				local slots = false

				local level = property.upgrades?.storage or 1
				if PropertyStorage[property.type] and PropertyStorage[property.type][level] then
					local storage = PropertyStorage[property.type][level]

					capacity = storage.capacity
					slots = storage.slots
				end

				local invId = string.format("Property:%s", property.id)

				Callbacks:ClientCallback(source, "Inventory:Compartment:Open", {
					invType = invType,
					owner = invId,
				}, function()
					Inventory:OpenSecondary(
						source,
						invType,
						invId,
						false,
						false,
						false,
						property.label,
						slots,
						capacity
					)
				end)
			end

			cb(true)
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("AHS:Upgrade", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		local property = _properties[data.id]

		if char and property.keys and property.keys[char:GetData("ID")] ~= nil and (property.keys[char:GetData("ID")].Permissions?.upgrade or property.keys[char:GetData("ID")].Owner) then
			local propertyUpgrades = PropertyUpgrades[property.type]
			if propertyUpgrades then
				local thisUpgrade = propertyUpgrades[data.upgrade]
				if thisUpgrade then
					local currentLevel = MLOInt.Upgrades:Get(property.id, data.upgrade)
					local nextLevel = thisUpgrade.levels[currentLevel + 1]
					local p = Banking.Accounts:GetPersonal(char:GetData("SID"))
					if nextLevel and nextLevel.price and p and p.Account then
						local success = Banking.Balance:Charge(p.Account, nextLevel.price, {
							type = "bill",
							title = "Property Upgrade",
							description = string.format("Upgrade %s to Level %s on %s", thisUpgrade.name, currentLevel + 1, property.label),
							data = {
								property = property.id,
								upgrade = data.upgrade,
								level = currentLevel + 1,
							}
						})

						if success then
							local upgraded = MLOInt.Upgrades:Set(property.id, data.upgrade, currentLevel + 1)
							if not upgraded then
								Logger:Error("Properties", string.format("SID %s Failed to Upgrade Property %s After Payment (%s - Level %s)", char:GetData("SID"), property.id, thisUpgrade.name, currentLevel + 1))
							end

							cb(upgraded)
							return
						end
					end
				end
			end
		end

		cb(false)
	end)
end