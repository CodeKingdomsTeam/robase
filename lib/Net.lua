local Logger = require(script.Parent.Logger)
local RunService = game:GetService("RunService")
local Net = {}

local eventHandlersByName = {}

--- Add a particular event that can be used to communicate between the client and server
--- @ServerOnly
function Net.AddEvent(name) --: string => void
	if (RunService:IsServer()) then
		local newEvent = Instance.new("RemoteEvent", script)
		newEvent.Name = name

		eventHandlersByName[name] = {}
	else
		Logger.Warn(
			"Tried to add event ",
			name,
			". Net.AddEvent can only be called from a non-local script. Also make sure you are testing with a local server and clients!"
		)
	end
end

--- Listens to a specific event and calls a handler function when it fires
function Net.ListenToEvent(name, handler) --: (string, ...Serializable => void ) => void
	local event = script:WaitForChild(name, 0.1)

	if (not event) then
		Logger.Warn("Net.ListenToEvent didn't run because the event ", name, " hasn't been added!")
		return
	end

	if (RunService:IsServer()) then
		local eventHandlers = eventHandlersByName[name]
		table.insert(eventHandlers, handler)
	end

	if (RunService:IsClient()) then
		event.OnClientEvent:Connect(handler)
	elseif (RunService:IsServer()) then
		event.OnServerEvent:Connect(handler)
	else
		-- Only servers and clients can listen to events
		Logger.Warn("Net.ListenToEvent cannot be called when running in Studio. Test with local server and clients instead!")
	end
end

--- Listens to a specific event from a specified origin player - when it's fired, the method will run
--- @ServerOnly
function Net.ListenToEventFrom(name, originPlayer, handler) --: (string, Player, ...Serializable => void ) => void
	local event = script:WaitForChild(name)

	if (not event) then
		Logger.Warn("Net.ListenToEvent didn't run because the event ", name, " hasn't been added!")
		return
	end

	local handlerWrapper = function(name, ...)
		local args = {...}

		--Only fire if the event came from the originPlayer
		if (args[1] == originPlayer) then
			handler(...)
		end
	end
	Net.ListenToEvent(name, handlerWrapper)
end
--- Fire an event by name and pass any number of args
function Net.FireEvent(name, ...) --: string, ...Serializable => void
	local event = script:WaitForChild(name, 0.1)

	if (RunService:IsServer()) then
		for _, handler in pairs(eventHandlersByName[name]) do
			handler(game.Players.LocalPlayer, ...)
		end
		return
	end
	local event = script:WaitForChild(name, 0.1)
	Logger.Debug("FireEvent with name " .. name .. " sent with arguments", ...)
	event:FireServer(game.Players.LocalPlayer, ...)
end
-- Fire an event from the server to a specific player
--- @ServerOnly
function Net.FireEventTo(name, player, ...) --: string, Player, ...Serializable => void
	local event = script:WaitForChild(name, 0.1)

	if (RunService:IsClient()) then
		if (RunService:IsServer()) then
			for _, handler in pairs(eventHandlersByName[name]) do
				handler(player, ...)
			end
			return
		end
		Logger.Warn("Using FireEventTo can't be used on the client so this didn't do anything. Event:", name)
		return
	end

	if (not event) then
		Logger.Warn("Net.ListenToEvent didn't run because the event hasn't been added!")
		return
	end

	if (not player:IsA("Player")) then
		Logger.Warn(name .. " event that is being sent from the server does not have a target player specified. Aborting!")
		return
	end
	Logger.Debug("FireEvent with name " .. name .. " sent to " .. player.Name)
	event:FireClient(player, player, ...)
end
-- Broadcast an event from the server, sending it to all clients
--- @ServerOnly
function Net.BroadcastEvent(name, ...) --: string, ...Serializable => void
	local event = script:WaitForChild(name, 0.1)
	local arg = {...}
	if (RunService:IsServer()) then
		local argumentsToSend = {}
		-- The first entry in the table always seems to get eaten by FireAllClients, so add a buffer
		table.insert(argumentsToSend, "buffer")
		for child, data in pairs(arg) do
			table.insert(argumentsToSend, data)
		end
		local ok, output =
			pcall(
			function()
				event:FireAllClients(unpack(argumentsToSend))
			end
		)
		if not ok then
			Logger.Error("Failed to broadcast event ", name, "! Error: ", output)
		end
	else
		-- This can only be fired from the server!
		Logger.Warn(
			"Net.Broadcast can only be called from a non-local script. Also make sure you are testing with a local server and clients!"
		)
	end
end

if (RunService:IsServer()) then
	Net.AddEvent("PhysicsCommand")
	Net.ListenToEvent(
		"PhysicsCommand",
		function(player, command, ...)
			Logger.Debug("PhysicsCommand", player, command, ...)

			local Physics = require(script.Parent.Physics)

			Physics[command](...)
		end
	)
end

return Net
