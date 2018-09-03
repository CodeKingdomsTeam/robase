local Logger = require(script.Parent.Logger)
local Types = require(script.Parent.Types)
local Type = Types.Type
local Physics = {}

local OrientatedObject = Type("OrientatedObject", {
	position = Vector3,
	lookVector = Vector3
})
Physics.OrientatedObject = OrientatedObject

--- Fire a projectile from a particular position on the server
--- @ServerOnly
function Physics.FireProjectile( projectile, speed, sourcePosition, targetPosition ) --: (Player, Instance, number, Vector3) => void

	local OFFSET_DISTANCE = 3.0
	local projectilePosition = sourcePosition + (targetPosition - sourcePosition).Unit * OFFSET_DISTANCE
	local clone = projectile:Clone()
	clone.Position = projectilePosition
    clone.Parent = game.Workspace
	Physics.PushTowards( clone, speed, targetPosition )

	return clone

end

--- Fire a projectile from a particular player on the client
--- @ClientOnly
--- @Command
function Physics.DoFireProjectile( projectile, speed, sourcePosition, targetPosition ) --: (Player, Instance, number, Vector3) => void

	local Net = require(script.Parent.Net)
	Net.FireEvent("PhysicsCommand", "FireProjectile", projectile, speed, sourcePosition, targetPosition)

end

function Physics.PushTowards( object, speed, targetPosition ) --: ( Instance, Vector3, number ) => void
    local lookVector = targetPosition - object.Position
	local velocity = lookVector / lookVector.magnitude * speed
	object.Velocity = object.Velocity + velocity
	object.CFrame = CFrame.new(object.Position, lookVector)
end

return Physics