local Commands = {}



Commands.

if(RunService:IsServer()) then

    Net.AddEvent("PhysicsCommand")
    Net.ListenToEvent("PhysicsCommand", function( player, command, ... )

        Logger.Debug("PhysicsCommand", player, command, ...)

        local Physics = require(script.Parent.Physics)

        Physics[command](...)

    end )

end

return Commands