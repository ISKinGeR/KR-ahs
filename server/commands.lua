function RegisterChatCommands()
    Chat:RegisterAdminCommand('mloprop', function(source, args, rawCommand)
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local pos = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 1.2,
            h = GetEntityHeading(ped)
        }

        MLOInt.Manage:Add(source, args[1], args[2], tonumber(args[3]), args[4], pos)

        TriggerEvent("Properties:RefreshProperties")

    end, {
        help = 'Add New MLO house To Database (Spawn Location Is Where You\'re At)',
        params = {
            {
                name = 'House ID',
                help = 'ID to reference this house internally (e.g. house_grove1, office1)'
            },
            {
                name = 'Property Label',
                help = 'Name or label of the property (e.g. Grove St House)'
            },
            {
                name = 'Property Price',
                help = 'Cost of the property'
            },
            {
                name = 'Property Type',
                help = 'Type of the property (e.g. house, office), Default: house'
            }
        }        
    }, 4)

    Chat:RegisterAdminCommand('delprop', function(source, args, rawCommand)
        if MLOInt.Manage:Delete(args[1]) then
            Chat.Send.Server:Single(source, id .. " Has Been Deleted")
        end
    end, {
        help = 'Delete Property',
        params = {{
            name = 'Property ID',
            help = 'Unique ID of the Property You Want To Delete'
        }}
    }, 1)
end