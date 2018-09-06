--[[
    Commands are pre-made RemoteEvents that are used to enable proper server-client
    permissions on other utilities, such as various physics helpers.
]]

-- Create return table
local Commands = {}

local Remote = require(game.ReplicatedStorage.Robase.Remote)
local Logger = require(game.ReplicatedStorage.Robase.Logger)

function Commands.PhysicsCommand()
        Remote.Server.AddEvent("PhysicsCommand")
        Remote.Server.ListenToEvent("PhysicsCommand", function( player, command, ... )

            Logger.Debug("PhysicsCommand", player, command, ...)

            local Physics = require(script.Parent.Physics)

            Physics[command](...)

        end )
end

return Commands