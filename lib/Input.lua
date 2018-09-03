--[[
	This deals with all input from a user to their client. Including mouse, keyboard, and other platforms that
	Roblox runs on. For additional reading, it is recommended that you take a look at the input section of 
	the Roblox API reference: https://www.robloxdev.com/api-reference/class/Mouse.
]]

-- Create return table
local Input = {}

-- Import libraries and helper functions
local Logger = require(script.Parent.Logger)
local Types = require(script.Parent.Types)
local Events = require(script.Parent.Events)
local Type = Types.Type
local ContextActionService = game:GetService("ContextActionService")

-- Create a ButtonEventMap for the virtual button system
Input.ButtonEventMap = Type("ButtonEventMap", {             --: <T>{[event:string]: Events.EventHandler<T>}
    OnPressed = Type("OnPressed"),          				--: <this T>() => void
    OnReleased = Type("OnReleased"),						--: <this T>() => void
})

-- Create a table to hold all the virtual buttons
local buttonsByName = {}

--[[
	This creates a virtual button, allowing multiple different Roblox inputs to be bound to the same
	'button'. It acts like a base Roblox button, heavily reducing the amount of code required to make 
	a game cross-platform compatible. 
]]
--- @ClientOnly
function Input.AddButton( buttonName, events, ... ) --: string, ButtonEventMap, ...KeyCode => void

	-- Creates the virtual button object
	local button = {
		Name = buttonName,
		Events = events,
		Keys = {...},
		IsPressed = false
	}

	-- Places the button into the table of buttons
	buttonsByName[buttonName] = button

	-- Creates a local function that will be fired by Roblox's ActionService when the state of the button changes
	local OnInput = function( buttonName, inputState )
	
		-- If the button has just been pressed
		if inputState == Enum.UserInputState.Begin then
			
			-- Set the button object to be pressed
			button.IsPressed = true

			-- If the button has an OnPressed event, fire it for the local player
			if ( button.Events.OnPressed ) then 
				button.Events.OnPressed( game.Players.LocalPlayer, button, buttonName )
			end
	
		-- Else if the button has just stopped being pressed
		elseif inputState == Enum.UserInputState.End then
	
			-- Set the button object to no longer be pressed
			button.IsPressed = false

			-- If the button has an OnReleased event, fire it for the local player
			if ( button.Events.OnReleased ) then 
				button.Events.OnReleased( game.Players.LocalPlayer, button, buttonName )
			end
	
		else
			-- Not an input state we want!
			Logger:Warn("Unexpected input state for button " .. buttonName .. ": " .. inputState)

		end
	
	end

	-- Bind the above function to all the different unput types
	ContextActionService:BindAction(buttonName, OnInput, true, ...)

end

--[[
	This removes a virtual button that has been created.
]]
--- @ClientOnly
function Input.RemoveButton(buttonName)

	-- If the virtual button exists, delete it
	if(buttonsByName[buttonName])then

		buttonsByName[buttonName] = nil

	else

		Logger:Warn("Tried to remove button " .. buttonName .. ", but it does not exist!")
	end 

end

--[[
	Returns true or false depending on if the specified virtual button is pressed
]]
--- @ClientOnly
function Input.IsPressed( buttonName )

	-- Check that the button exists first of all
	if ( not buttonsByName[buttonName] ) then

		Logger:Warn("Button doesn't exist " .. buttonName)

		-- If the button doesn't exist, then it cannot be pressed
		return false

	end

	-- Return 
	return buttonsByName[buttonName].IsPressed
	
end

return Input