local Logger = require(game.ReplicatedStorage.Robase.Logger)
local Purchases = require(game.ReplicatedStorage.Robase.Purchases)
local Types = require(game.ReplicatedStorage.Robase.Types)
local Type = Types.Type

local Events = {}

Events.EventHandler = Type("EventHandler")          --: <this T>(...any) => void
Events.EventMap = Type("EventMap", {                --: <T>{[event:string]: EventHandler<T>}
    OnCreated = Type("OnCreated"),                    --: <this T>() => void
    OnPlayerTouched = Type("OnPlayerTouched"),      --: OnPlayerTouched: <this T>(player: Player, playerPart: BasePart) => void
    OnActivated = Type("OnActivated")               --: OnActivated: <this T>(player: Player) => void
})

function Events.ConnectPlayers( listeners )

    game.Players.PlayerAdded:Connect( function( player )

        if ( listeners.OnJoined ) then

            Events.Run( function() 
                repeat wait(0.1) until player.Character
                listeners.OnJoined( player )

            end )

        end

        if ( listeners.OnPurchased ) then

            Purchases.ConnectPlayerPurchased( player.Name, listeners.OnPurchased )

        end

    end)

end

function Events.Connect( object, listeners ) --: <T extends Instance>(T, EventMap<T>) => void

    if ( listeners.OnCreated ) then

        if ( object:IsDescendantOf( game.Workspace )) then

            Events.Run( function()
                
                listeners.OnCreated( object )

            end)

        end

    end

    --- OnPlayerTouched only fires once every tick even if multiple body parts are touching the objects
    --- The event will only fire if the player is "alive" and the object has not been destroyed, making
    --- this event perfect for objects which must interact once with the player, such as a Killer or
    --- a pickup
    if ( listeners.OnPlayerTouched ) then

        local debounce = false

        object.Touched:connect(function( playerPart )

            local player = game.Players:GetPlayerFromCharacter( playerPart.Parent )
            if player and not debounce then
                debounce = true
                Events.Run(function()

                    listeners.OnPlayerTouched(object, player, playerPart)
                    debounce = false

                end)

            end
        end)

    end

    if ( listeners.OnActivated ) then

        if ( object:IsDescendantOf( game.Players )) then

            object.Activated:connect(function()

                local player = game.Players:GetPlayerFromCharacter( object.Parent )
                if player then

                    Events.Run(function()

                        listeners.OnActivated(object, player)

                    end)

                end

            end)

        end

    end

end


function Events.ConnectMany( objectName, listeners, parent ) --: ( string, EventMap, Instance? ) => void

    if ( not parent ) then
        parent = game.Workspace
    end

    local descendants = parent:GetDescendants()

    for _, descendant in pairs(descendants) do
        if descendant.Name == objectName and Events.ObjectHasEvents( descendant) then
            Events.Connect( descendant, listeners )
        end
    end

end

function Events.ObjectHasEvents( object ) --: Instance => boolean

    local ok = pcall(function() return object.Touched end)
    return ok

end

function Events.Run( fn, ... ) --: (EventHandler, ...any) => void

	local runArgs = {...}

	coroutine.wrap(function()

		wait()

		local ok, err = ypcall(fn, self, unpack(runArgs))

		if ( not ok ) then

			Logger.Error(err)

		end

	end)()

end

return Events