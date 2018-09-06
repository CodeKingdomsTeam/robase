--[[
    This is for the client-end of RemoteEvents and RemoteFunctions. A RemoteEvent is something that clients and servers use to communicate information 
    from one another, and is extremely important in nearly every game on Roblox. Further reading on events within Roblox's implementation can 
    be found here: https://www.robloxdev.com/api-reference/class/RemoteEvent
]]

-- Create return table
local Client = {}

-- Import libraries and helper functions
local Logger = require(game.ReplicatedStorage.Robase.Logger)
local RunService = game:GetService("RunService")

--[[
    Listens to a specific event, meaning that if a RemoteEvent is fired at the client, the handler function executes.
]]
--- @ClientOnly
function Client.ListenToEvent(name, handler) --: (string, ...Serializable => void ) => void

    -- Try and retrieve the specified event
    local event = script:WaitForChild(name, 0.1)

    -- As the Client cannot create RemoteEvents, if it doesn't exist, just abort
    if ( not event ) then
        Logger.Warn("Client.ListenToEvent didn't run because the event ", name, " hasn't been added!")
        return
    end
    
    -- Connect the event to the handler function
    event.OnClientEvent:Connect(handler)

end

--[[
    Fires the RemoveEvent by the specified name to the server. This includes any additional parameters that are sent
    across.
]]
--- @ClientOnly
function Client.FireEvent( name, ... ) --: string, ...Serializable => void

    -- Try and retrieve the specified event
    local event = script:WaitForChild(name, 0.1)

    -- As the Client cannot create RemoteEvents, if it doesn't exist, just abort
    if ( not event ) then
        Logger.Warn("Client.FireEvent didn't run because the event ", name, " hasn't been added!")
        return
    end

    -- Fire the event to the server, with any additional specified arguments
    Logger.Debug("FireEvent with name " .. name .. " sent with arguments", ...)
    event:FireServer(game.Players.LocalPlayer, ...)
end

return Client