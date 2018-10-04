local RunService = game:GetService("RunService")
local Logger = require(script.Parent.Logger)

local function cloneFromServerStorage(projectileName)
	local projectilePrefab = game.ServerStorage:FindFirstChild(projectileName)

	if typeof(projectilePrefab) ~= "Instance" then
		Logger.Error("Could not find projectile part " .. projectileName)
	elseif projectilePrefab.ClassName ~= "Part" then
		Logger.Error("Projectile " .. projectileName .. " is not a Part")
	else
		return projectilePrefab:Clone()
	end
end

local ProjectileService = {
	MAX_FLIGHT_TIME = 10
}

function ProjectileService:FireProjectile(projectileName, from, velocity, options)
	options = options or {}
	local position = from
	local ignoreList = options.ignoreList or {}

	local gravity = game.Workspace.Gravity
	if typeof(options.gravityMultiplier) == "number" then
		gravity = gravity * options.gravityMultiplier
	end

	local ignoreWater = false
	if typeof(options.ignoreWater) == "boolean" then
		ignoreWater = options.ignoreWater
	end

	local projectile = cloneFromServerStorage(projectileName)
	if not projectile then
		-- The projectile failed to be cloned, so exit.
		return
	end

	local baseRotation = projectile.CFrame - projectile.Position
	projectile.CFrame = CFrame.new(position, position + velocity) * baseRotation
	projectile.Parent = game.Workspace

	-- Remove the projectile from the control of the physics engine by anchoring it,
	-- as its path will be controlled by this service.
	projectile.Anchored = true
	projectile.CanCollide = false

	-- The connection used for the stepped update of the projectile.
	local steppedUpdate
	local startTime = tick()
	local lastStepTime = startTime

	local function updateProjectile()
		local currentTime = tick()
		local totalFlightTime = currentTime - startTime
		if totalFlightTime > self.MAX_FLIGHT_TIME then
			-- The projectile has been in flight for longer than the maximum time, so
			-- something has probably gone wrong. Remove it from the control of this
			-- service.
			projectile.Anchored = false
			steppedUpdate:Disconnect()
			return
		end
		local timeDelta = currentTime - lastStepTime
		local bulletRay = Ray.new(position, velocity * timeDelta)
		local hitPart, hitPosition, hitNormal =
			workspace:FindPartOnRayWithIgnoreList(bulletRay, ignoreList, false, ignoreWater)
		if hitPart then
			-- The projectile has hit something. Move it to the point of collision, stop this service from
			-- updating it any more and fire the projectile's Hit event if it has one.
			projectile.CFrame = CFrame.new(hitPosition, hitPosition + velocity) * baseRotation
			steppedUpdate:Disconnect()
			local hitEvent = projectile:FindFirstChild("Hit")
			if typeof(hitEvent) == "Instance" and hitEvent.ClassName == "BindableEvent" then
				hitEvent:Fire(hitPart, hitPosition, hitNormal, velocity)
			end
		else
			projectile.CFrame = CFrame.new(position, position + velocity) * baseRotation
			-- Apply acceleration due to gravity.
			velocity = velocity - (Vector3.new(0, gravity, 0) * timeDelta)
			position = position + velocity * timeDelta
		end
		lastStepTime = currentTime
	end

	updateProjectile()
	steppedUpdate = RunService.Stepped:Connect(updateProjectile)

	return projectile, steppedUpdate
end

function ProjectileService:ConnectToEvent(eventName)
	if not eventName then
		eventName = "FireProjectile"
	end

	local fireProjectileEvent = game.ReplicatedStorage:FindFirstChild(eventName)
	if not fireProjectileEvent then
		fireProjectileEvent = Instance.new("RemoteEvent")
		fireProjectileEvent.Name = eventName
		fireProjectileEvent.Parent = game.ReplicatedStorage
	end

	return fireProjectileEvent.OnServerEvent:Connect(
		function(_, ...)
			self:FireProjectile(...)
		end
	)
end

return ProjectileService
