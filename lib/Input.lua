local Logger = require(script.Parent.Logger)
local Types = require(script.Parent.Types)
local Events = require(script.Parent.Events)
local Type = Types.Type
local Input = {}
local ContextActionService = game:GetService("ContextActionService")

Input.ButtonEventMap = Type("ButtonEventMap", {             --: <T>{[event:string]: Events.EventHandler<T>}
    OnPressed = Type("OnPressed"),          				--: <this T>() => void
    OnReleased = Type("OnReleased"),						--: <this T>() => void
})

local buttonsByName = {}

--- Add a virtual button bound to provided input keys
--- @ClientOnly
function Input.AddButton( buttonName, events, ... ) --: string, ButtonEventMap, ...KeyCode => void

	local button = {
		Name = buttonName,
		Events = events,
		Keys = {...},
		IsPressed = false
	}
	buttonsByName[buttonName] = button

	local OnInput = function( buttonName, inputState )
	
		if inputState == Enum.UserInputState.Begin then
			
			button.IsPressed = true
			if ( button.Events.OnPressed ) then 
				button.Events.OnPressed( game.Players.LocalPlayer, button, buttonName )
			end
	
		elseif inputState == Enum.UserInputState.End then
	
			button.IsPressed = false
			if ( button.Events.OnReleased ) then 
				button.Events.OnReleased( game.Players.LocalPlayer, button, buttonName )
			end
	
		else
	
			Logger:Warn("Unexpected input state for button " .. buttonName .. ": " .. inputState)
	
		end
	
	end

	ContextActionService:BindAction(buttonName, OnInput, true, ...)

end

--- Remove a virtual button
--- @ClientOnly
function Input.RemoveButton(buttonName)

	buttonsByName[buttonName] = nil

end

--- Check if a virtual button is pressed
--- @ClientOnly
function Input.IsPressed( buttonName )

	if ( not buttonsByName[buttonName] ) then

		Logger:Warn("Button doesn't exist " .. buttonName)
		return false

	end

	return buttonsByName[buttonName].IsPressed
	
end

return Input