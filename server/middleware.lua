function RegisterMiddleware()
	Middleware:Add("Characters:Spawning", function(source)
		LoadHousePolyZones(source)
		if Player(source).state.inMLOHouse then
			Player(source).state.inMLOHouse = nil
		end
	end)

	Middleware:Add("Characters:Logout", function(source)
		local char = Fetch:Source(source):GetData("Character")
		if char ~= nil then
			GlobalState[string.format("AHS:Keys:%s", charId)] = nil
		end
		local property = GlobalState[string.format("%s:MLO:Property", source)]
		if property then
			-- TriggerClientEvent("Properties:Client:Cleanup", source, property)
			if _insideProperties[property] then
				_insideProperties[property][source] = nil
			end

			GlobalState[string.format("%s:MLO:Property", source)] = nil
		end
		if Player(source).state.inMLOHouse then
			Player(source).state.inMLOHouse = nil
		end
	end)

	Middleware:Add("Characters:GetSpawnPoints", function(source, charId)
		local p = promise.new()
		Database.Game:find({
			collection = "properties",
			query = {
				[string.format("keys.%s", charId)] = { ["$exists"] = true },
				foreclosed = { ["$ne"] = true },
				type = { ["$nin"] = { "container", "warehouse" } }
			},
		}, function(success, results)        
			if not success or not results or #results == 0 then
				p:resolve({})
				return
			end

			local spawns = {}
			local HousesIds = {}

			for i, property in ipairs(results) do
				if property.location and property.location.front and property.houseId then
					table.insert(HousesIds, property.houseId)
					table.insert(spawns, {
						id = property._id,
						label = property.label,
						location = {
							x = property.location.front.x, 
							y = property.location.front.y,
							z = property.location.front.z,
							h = property.location.front.h,
						},
						icon = "house",
						event = "Characters:GlobalSpawn",
					})
				end
			end
			GlobalState[string.format("AHS:KEYS:%s", charId)] = HousesIds
			p:resolve(spawns)
		end)

		return Citizen.Await(p)
	end, 3)

end