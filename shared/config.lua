Config = {}
Config.collection = "KR_Houses"
Config.Debug = false

_RPolyzones = {
	-- {
	-- 	{
	-- 	vector2(-60.743541717529, -1096.7081298828),
	-- 	vector2(-58.178604125977, -1101.0942382812),
	-- 	vector2(-52.037307739258, -1103.3557128906),
	-- 	vector2(-34.802547454834, -1109.6293945312),
	-- 	vector2(-31.709390640259, -1101.4549560547),
	-- 	vector2(-32.955589294434, -1100.9743652344),
	-- 	vector2(-30.981006622314, -1095.2191162109),
	-- 	vector2(-36.394088745117, -1093.1420898438),
	-- 	vector2(-36.659427642822, -1093.7624511719),
	-- 	vector2(-56.928714752197, -1085.9456787109)
	--   }, {
	-- 	name="KRHouse",
	-- 	minZ = 23.422344207764,
	-- 	maxZ = 29.422513961792
	--   }
	-- },
	-- {
	-- 	{
	-- 	vector2(-13.083868980408, -1096.8612060547),
	-- 	vector2(-7.6785612106323, -1099.1123046875),
	-- 	vector2(-6.3940210342407, -1095.1242675781),
	-- 	vector2(-9.5194444656372, -1093.7762451172),
	-- 	vector2(-7.1773400306702, -1087.2132568359),
	-- 	vector2(-15.071125030518, -1084.0810546875),
	-- 	vector2(-18.837236404419, -1094.5056152344)
	--   }, {
	-- 	name="KRHouse",
	-- 	minZ = 23.422344207764,
	-- 	maxZ = 29.422513961792
	--   }
	-- },
	-- --Name: LOL | 2025-05-21T11:27:03Z
	-- {
	-- 	{
	-- 		vector2(144.65913391113, -1035.3406982422),
	-- 		vector2(141.51457214355, -1044.4090576172),
	-- 		vector2(143.50019836426, -1045.1320800781),
	-- 		vector2(143.87278747559, -1044.1461181641),
	-- 		vector2(144.14865112305, -1044.2541503906),
	-- 		vector2(143.75387573242, -1045.2923583984),
	-- 		vector2(147.16993713379, -1046.5460205078),
	-- 		vector2(148.17655944824, -1043.9404296875),
	-- 		vector2(144.69599914551, -1042.6678466797),
	-- 		vector2(144.55679321289, -1043.0889892578),
	-- 		vector2(144.28016662598, -1042.9498291016),
	-- 		vector2(144.76567077637, -1041.9361572266),
	-- 		vector2(145.18804931641, -1041.9932861328),
	-- 		vector2(145.98292541504, -1039.7015380859),
	-- 		vector2(153.31533813477, -1042.3972167969),
	-- 		vector2(154.47605895996, -1039.2078857422)
	-- 	}, {
	-- 		name="LOL",
	-- 		minZ = 26.146337509155,
	-- 		maxZ = 33.146337509155
	-- 	}
	-- }
}

function DoseHeHaveAccessToThisDoor(CharacterID, HouseName)
    local key = string.format("AHS:KEYS:%s", CharacterID)
    local propertyNames = GlobalState[key]
    kprint(json.encode(propertyNames, {indent = true}))
    if type(propertyNames) == "table" then
        if propertyNames[HouseName] ~= nil then
            return true
        else
            for _, name in ipairs(propertyNames) do
                if name == HouseName then
                    return true
                end
            end
        end
    end
    return false
end

function kprint(...)
    if Config.Debug then
        local args = {...}
        local output = {}

        for i = 1, #args do
            if type(args[i]) == "table" then
                output[i] = json.encode(args[i])  -- Pretty and readable
            else
                output[i] = tostring(args[i])
            end
        end

        local messageToPrint = "[DEBUG] " .. table.concat(output, "   ")
        print(messageToPrint)
    end
end
