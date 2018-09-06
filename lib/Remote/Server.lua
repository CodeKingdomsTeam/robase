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

-- The table that holds all event handlers/functions, as sorted by event name
local eventHandlersByName = {}

--[[
    Creates a RemoteEvent within the Robase ReplicatedStorage. This is used when sending or
    recieving event fires. Note that this also adds the event to a virtual event system that allows
    RemoteEvents to 'work' while testing without a proper client-server.
]]
--- @ServerOnly
function Server.AddEvent( name ) --: string => void
   
    -- Creates a new RemoteEvent instance
    local newEvent = Instance.new("RemoteEvent", script)
    newEvent.Name = name

    -- Adds entry to virtual event system
    eventHandlersByName[name] = {}

end

--[[
    When an event by the specified name is fired, the handler function will execute. Note that this will also
    listen to the virtual event firing system as well. If the server tries to listen to an event that doesn't 
    exist, it will create one as well. 
]]
--- @ServerOnly
function Server.ListenToEvent(name, handler) --: (string, ...Serializable => void ) => void

    local event = script:WaitForChild(name, 0.1)

    -- If the event doesn't exist, create it, and then grab it
    if ( not event ) then

        Server.AddEvent(name)
        event = script:WaitForChild(name, 0.1)
    end

    -- Insert the handler to the virtual event system
    local eventHandlers = eventHandlersByName[name]
    table.insert(eventHandlers, handler)
    
    -- Connect the event firing to the handler
    event.OnServerEvent:Connect(handler)

end 

--[[
    The handler function will fire only when the event has originated from the originPlayer, allowing
    selective listening. Please note that this also works with the virtual event system as well.
]]
--- @ServerOnly
function Server.ListenToEventFrom(name, originPlayer, handler) --: (string, Player, ...Serializable => void ) => void

    local event = script:WaitForChild(name)

    -- If the event doesn't exist, create it first
    if ( not event ) then
        
        Server.AddEvent(name)
        event = script:WaitForChild(name, 0.1)
    end

    -- Add a wrapper around the handler to ensure that it only executes if the event is from the target player
    local handlerWrapper = function( name, ... )
        local args = {...}

        --Only fire if the event came from the originPlayer
        if(args[1] == originPlayer) then
            handler( ... )
        end		
    end

    -- Listen to the event with the wrapped handler
    Server.ListenToEvent( name, handlerWrapper )
end

--[[
    Fires an event with any additional parameters to the target player only, instead of all online clients. Note
    that this also makes use of the virtual event systems. 
]]
--- @ServerOnly
function Server.FireEventTo ( name, player, ... ) --: string, Player, ...Serializable => void
    
    -- If the RunService is also a client, then this is executed within Studio
    if(RunService:IsClient()) then

            -- Iterate through, and execute all the virtual event handlers
            for _, handler in pairs(eventHandlersByName[name]) do

	            handler( player, ... )
            end

            -- The rest of this function isn't necessary, so return now
            return
    end

    -- Try and get the specified event
    local event = script:WaitForChild(name, 0.1)

    -- If there is no event, then it cannot fire! 
    if ( not event ) then
        Logger.Warn("Server.FireEventTo didn't run because the event hasn't been added!")
        return
    end

    -- Should ensure that the specified player is a legimate player
    if(not player:IsA("Player")) then
        Logger.Warn(name .. " event that is being sent from the server does not have a target player specified. Aborting!")
        return
    end

    Logger.Debug("FireEvent with name " .. name .. " sent to " .. player.Name)

    -- Fire the event to the target client
    event:FireClient( player, player, ...)
end

--[[
    Will fire the target event, along with any parameters, to all currently connected clients. Note this also works
    with the virtual event system. 
]]
--- @ServerOnly
function Server.BroadcastEvent( name, ... ) --: string, ...Serializable => void
    
    -- Try and find the script
    local event = script:WaitForChild(name, 0.1)
 
    local arg = {...}
    local argumentsToSend = {}

    -- The first entry in the table always seems to get eaten by FireAllClients, so add a buffer
    table.insert(argumentsToSend, name)
    
    for _, data in pairs(arg) do
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