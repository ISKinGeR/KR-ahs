RegisterNetEvent("AHS:Client:CreateFunPoly", function(polys)
    kprint(json.encode(polys, {indent = true}))
    while Polyzone == nil do 
        Wait(123) 
    end
    for i, polyData in ipairs(polys) do
        local polygon = polyData[1]
        local properties = polyData[2]

        if polygon and properties then
            local zoneName = string.format("AHS:HOUSE:%s:%d", properties.name, i)
            Polyzone.Create:Poly(zoneName, polygon, {
                minZ = properties.minZ,
                maxZ = properties.maxZ
            })
        end
    end
end)