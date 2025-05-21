_properties = {}

_propertiesLoaded = false

_insideProperty = false
_insideInterior = false
_insideFurniture = {}
_AllHousesBlips = {}

_furnitureCategory = {}
_furnitureCategoryCurrent = 1

_placingFurniture = false

_allowBrowse = true
_skipPhone = false

AddEventHandler("MLOInt:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
	Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
	Inventory = exports["mythic-base"]:FetchComponent("Inventory")
	Logger = exports["mythic-base"]:FetchComponent("Logger")
	Utils = exports["mythic-base"]:FetchComponent("Utils")
	Notification = exports["mythic-base"]:FetchComponent("Notification")
	Action = exports["mythic-base"]:FetchComponent("Action")
	Targeting = exports["mythic-base"]:FetchComponent("Targeting")
	Sounds = exports["mythic-base"]:FetchComponent("Sounds")
	Characters = exports["mythic-base"]:FetchComponent("Characters")
	Wardrobe = exports["mythic-base"]:FetchComponent("Wardrobe")
	Interaction = exports["mythic-base"]:FetchComponent("Interaction")
	Inventory = exports["mythic-base"]:FetchComponent("Inventory")
	MLOInt = exports["mythic-base"]:FetchComponent("MLOInt")
	Jobs = exports["mythic-base"]:FetchComponent("Jobs")
	Sync = exports["mythic-base"]:FetchComponent("Sync")
	Blips = exports["mythic-base"]:FetchComponent("Blips")
	Crafting = exports["mythic-base"]:FetchComponent("Crafting")
	Polyzone = exports["mythic-base"]:FetchComponent("Polyzone")
	Animations = exports["mythic-base"]:FetchComponent("Animations")
	Keybinds = exports["mythic-base"]:FetchComponent("Keybinds")
	ObjectPlacer = exports["mythic-base"]:FetchComponent("ObjectPlacer")
	Phone = exports["mythic-base"]:FetchComponent("Phone")
	InfoOverlay = exports["mythic-base"]:FetchComponent("InfoOverlay")
end

AddEventHandler("Core:Shared:Ready", function()
	exports["mythic-base"]:RequestDependencies("MLOInt", {
		"Callbacks",
		"Inventory",
		"Logger",
		"Utils",
		"Notification",
		"Action",
		"Targeting",
		"Sounds",
		"Characters",
		"Wardrobe",
		"Interaction",
		"Inventory",
		"MLOInt",
		"Jobs",
		"Sync",
		"Crafting",
		"Blips",
		"Polyzone",
		"Animations",
		"Keybinds",
		"ObjectPlacer",
		"Phone",
		"InfoOverlay",
	}, function(error)
		if #error > 0 then
			return
		end
		RetrieveComponents()
	end)
end)

RegisterNetEvent("Properties:Client:Load", function(props)
	_properties = props

	_propertiesLoaded = true
end)

RegisterNetEvent("Properties:Client:Update", function(id, data)
	if _properties and _propertiesLoaded then
		_properties[id] = data
	end
end)

RegisterNetEvent('Characters:Client:Logout')
AddEventHandler('Characters:Client:Logout', function()
	_propertiesLoaded = false
	_properties = {}

	DestroyFurniture()

	_insideProperty = false
	_insideInterior = false

	_placingFurniture = false
	LocalPlayer.state.MLOplacingFurniture = false
	LocalPlayer.state.MLOfurnitureEdit = false

	if #_AllHousesBlips > 0 then
		for k, v in ipairs(_AllHousesBlips) do
			RemoveBlip(v)
		end

		_AllHousesBlips = {}
	end
end)

MLOINT = {
	Enter = function(houseId)
		print("we are here",houseId)
		Callbacks:ServerCallback("AHS:EnterProperty", houseId, function(state)
			if state then
				kprint("Entered:", houseId)
			end
			return(state)
		end)
	end,
	GetProperties = function(self)
		if _propertiesLoaded then
			return _properties
		end
		return false
	end,
	GetPropertiesWithAccess = function(self)
		if LocalPlayer.state.loggedIn and _propertiesLoaded then
			local props = {}
			for k, v in pairs(_properties) do
				if v and v.keys and v.keys[LocalPlayer.state.Character:GetData("ID")] then
					table.insert(props, v)
				end
			end
	
			return props
		end
		return false
	end,
	Get = function(pId)
		kprint("[DEBUG] Get called with pId:", pId)
		local property = _properties[pId]
		kprint("[DEBUG] property exists:", property ~= nil)
		kprint("[DEBUG] property.houseId exists:", property and property.houseId ~= nil)
		if property and property.houseId then
			return property
		end
		return nil
	end,	
	GetUpgradesConfig = function(self)
		return PropertyUpgrades
	end,
	GetNearHouseGarage = function(self, coordOverride)
		if LocalPlayer.state.currentRoute ~= 0 or not _propertiesLoaded then
			return false
		end

		local myPos = GetEntityCoords(LocalPlayer.state.ped)
		local closest = nil
		for k, v in pairs(_properties) do
			if v.location.garage then
				local dist = #(myPos - vector3(v.location.garage.x, v.location.garage.y, v.location.garage.z))
				if dist < 3.0 and (not closest or dist < closest.dist) then
					closest = {
						coords = v.location.garage,
						dist = dist,
						propertyId = v.id,
					}
				end
			end
		end
		return closest
	end,
	GetInside = function(self)
		return _insideProperty
	end,
	Extras = {
		Stash = function(self)
			Callbacks:ServerCallback("AHS:Validate", {
				id = GlobalState[string.format("%s:MLO:Property", LocalPlayer.state.ID)],
				type = "stash",
			})
		end,
		Closet = function(self)
			Callbacks:ServerCallback("AHS:Validate", {
				id = GlobalState[string.format("%s:MLO:Property", LocalPlayer.state.ID)],
				type = "closet",
			}, function(state)
				if state then
					Wardrobe:Show()
				end
			end)
		end,
		Logout = function(self)
			Callbacks:ServerCallback("AHS:Validate", {
				id = GlobalState[string.format("%s:MLO:Property", LocalPlayer.state.ID)],
				type = "logout",
			}, function(state)
				if state then
					Characters:Logout()
				end
			end)
		end,
	},
	Keys = {
		HasAccessWithData = function(self, key, value) -- Has Access to a Property with a specific data/key value
			if LocalPlayer.state.loggedIn and _propertiesLoaded then
				local propertyKeys = GlobalState[string.format("AHS:Keys:%s", LocalPlayer.state.Character:GetData("ID"))]

				for _, propertyId in ipairs(propertyKeys) do
					local property = _properties[propertyId]
					if property and property.data and ((value == nil and property.data[key]) or property.data[key] == value) then
						return property.id
					end
				end
			end
			return false
		end,
	},
	Furniture = {
		GetCurrent = function(self, property)
			if _insideProperty and _insideProperty.id == property._id then
				for k, v in ipairs(_insideFurniture) do
					v.dist = #(GetEntityCoords(LocalPlayer.state.ped) - vector3(v.coords.x, v.coords.y, v.coords.z))
				end
				return {
					success = true,
					furniture = _insideFurniture,
					catalog = FurnitureConfig,
					categories = FurnitureCategories,
				}
			end

			return {
				err = "Must be Inside the Property!"
			}
		end,
		EditMode = function(self, state)
			if state == nil then
				state = not LocalPlayer.state.MLOfurnitureEdit
			end

			if _insideProperty then
				SetFurnitureEditMode(state)
			end
		end,
		Place = function(self, model, category, metadata, blockBrowse, skipPhone)
			if not _insideProperty then
				return false
			end

			if not category then
				category = FurnitureConfig[model].cat
			end

			_allowBrowse = not blockBrowse

			_placingFurniture = true
			LocalPlayer.state.MLOplacingFurniture= true

			_furnitureCategory = {}
			for k, v in pairs(FurnitureConfig) do
				if v.cat == category then
					table.insert(_furnitureCategory, k)
				end
			end

			table.sort(_furnitureCategory, function(a,b)
				return (FurnitureConfig[a]?.id or 1) < (FurnitureConfig[b]?.id or 1)
			end)

			for k, v in ipairs(_furnitureCategory) do
				if v == model then
					_furnitureCategoryCurrent = k
				end
			end

			local fData = FurnitureConfig[model]
			if fData then
				InfoOverlay:Show(fData.name, string.format("Category: %s | Model: %s", FurnitureCategories[fData.cat]?.name or "Unknown", model))
			end

			ObjectPlacer:Start(GetHashKey(model), "MLO:Client:Place", metadata, true, "MLO:Client:Cancel", true, fData.placeGround)
			if not skipPhone then
				Phone:Close(true, true)
			end
			_skipPhone = skipPhone

			DisablePauseMenu(true)

			return true
		end,
		Move = function(self, id, skipPhone)
			if not _insideProperty then
				return false
			end

			for k, v in ipairs(_insideFurniture) do
				if v.id == id then
					furn = v
				end
			end

			if not furn then
				return false
			end

			_placingFurniture = true
			LocalPlayer.state.MLOplacingFurniture= true

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

			local fData = FurnitureConfig[model]

			ObjectPlacer:Start(GetHashKey(furn.model), "MLO:Client:Move", { id = id }, true, "MLO:Client:CancelMove", true, fData?.placeGround)
			if not skipPhone then
				Phone:Close(true, true)
			end
			_skipPhone = skipPhone

			DisablePauseMenu(true)

			return true
		end,
		Delete = function(self, id)
			if not _insideProperty then
				return false
			end

			local catCounts = {
				["storage"] = 0,
			}
			local fData
			for k, v in ipairs(_insideFurniture) do
				if v.id == id then
					fData = FurnitureConfig[v.model]
				else
					local d = FurnitureConfig[v.model]
					if not catCounts[d.cat] then
						catCounts[d.cat] = 0
					end

					catCounts[d.cat] += 1
				end
			end

			if fData.cat == "storage" and catCounts["storage"] < 1 then
				Notification:Error("You Are Required to Have At Least One Storage Container!")
				return false
			end

			local p = promise.new()

			Callbacks:ServerCallback("MLO:DeleteFurniture", {
				id = id,
			}, function(success, furniture)
				if success then
					Notification:Success("Deleted Item")
					for k, v in ipairs(furniture) do
						v.dist = #(GetEntityCoords(LocalPlayer.state.ped) - vector3(v.coords.x, v.coords.y, v.coords.z))
					end
					p:resolve(furniture)
				else
					p:resolve(false)
					Notification:Error("Error")
				end
			end)

			return Citizen.Await(p)
		end
	},
}

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["mythic-base"]:RegisterComponent("MLOInt", MLOINT)
end)