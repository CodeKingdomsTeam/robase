--[[
    This is for the server-end of RemoteEvents and RemoteFunctions. A RemoteEvent is something that clients and servers use to communicate information 
    from one another, and is extremely important in nearly every game on Roblox. Further reading on events within Roblox's implementation can 
    be found here: https://www.robloxdev.com/api-reference/class/RemoteEvent

    This also includes a virtual RemoteEvents system, which allows developers to 'fire' events while still only testing within Roblox Studio. This negates the
    need for always using a Server<->Client setup, but should not replace any testing of RemoteEvents for an actual game.
]]

-- Create return table
local Server = {}

-- Import libraries and helper functions
local Logger = require(script.Parent.Logger)
local RunService = game:GetService("RunService")

-- The table that holds
local eventHandlersByName = {}

--- Add a particular event that can be used to communicate between the client and server
--- @ServerOnly
function Server.AddEvent( name ) --: string => void
   
    local newEvent = Instance.new("RemoteEvent", script)
    newEvent.Name = name

    eventHandlersByName[name] = {}

end

--- Listens to a specific event and calls a handler function when it fires
--- @ServerOnly
function Server.ListenToEvent(name, handler) --: (string, ...Serializable => void ) => void

    local event = script:WaitForChild(name, 0.1)

    if ( not event ) then
        Server.AddEvent(name)
        event = script:WaitForChild(name, 0.1)
    end

    local eventHandlers = eventHandlersByName[name]
    table.insert(eventHandlers, handler)
    
    event.OnServerEvent:Connect(handler)

    end

end 

--- Listens to a specific event from a specified origin player - when it's fired, the method will run
--- @ServerOnly
function Server.ListenToEventFrom(name, originPlayer, handler) --: (string, Player, ...Serializable => void ) => void

    local event = script:WaitForChild(name)

    if ( not event ) then
        
        Server.AddEvent(name)
        event = script:WaitForChild(name, 0.1)

        return
    end

    local handlerWrapper = function( name, ... )
        local args = {...}

        --Only fire if the event came from the originPlayer
        if(args[1] == originPlayer) then
            handler( ... )
        end		
    end
    Net.ListenToEvent( name, handlerWrapper )
end

-- Fire an event from the server to a specific player
--- @ServerOnly
function Server.FireEventTo ( name, player, ... ) --: string, Player, ...Serializable => void
    
    if(RunService:IsClient()) then
            for _, handler in pairs(eventHandlersByName[name]) do
	            handler( player, ... )
            end
            return
    end

    local event = script:WaitForChild(name, 0.1)

    if ( not event ) then
        Logger.Warn("Server.FireEventTo didn't run because the event hasn't been added!")
        return
    end

    if(not player:IsA("Player")) then
        Logger.Warn(name .. " event that is being sent from the server does not have a target player specified. Aborting!")
        return
    end

    Logger.Debug("FireEvent with name " .. name .. " sent to " .. player.Name)

    event:FireClient( player, player, ...)
end

-- Broadcast an event from the server, sending it to all clients
--- @ServerOnly
function Server.BroadcastEvent( name, ... ) --: string, ...Serializable => void
    
    local event = script:WaitForChild(name, 0.1)

    local arg = {...}
    local argumentsToSend = {}

    -- The first entry in the table always seems to get eaten by FireAllClients, so add a buffer
    table.insert(argumentsToSend, name)
    
    for child, data in pairs(arg) do
        table.insert(argumentsToSend, data)
    end 

    local ok, output = pcall(function()
        event:FireAllClients(unpack(argumentsToSend))
    end)
    if not ok then
        Logger.Error("Failed to broadcast event ", name, "! Error: ", output)
    end

end

return Server