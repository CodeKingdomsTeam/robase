-- //* Configurable variables *// --

-- Dictates the iteration time of the camera loop.  Default is 0.1.
local cameraUpdateInterval = 0.1
-- Augments speed for camera follow speed. Default is 2. 
local cameraElasticity = 2 
-- Dictates how quickly the camera reacts to movements of the target. Default is 0.3.
local cameraReaction = 0.3
-- Dictates the amount of camera shake that occurs while the target is moving. Default is 0.005.
local cameraShake = 0.005 
-- Dictates the distance the camera needs to be, before teleporting back to the correct place. Default is 50.
local followCutOff = 50 
-- Dictates the minimum (and therefore standard) field of view the camera has. Default is 70.
local floorFoV = 70 
-- Dictates the maximum field of view the camera may have. Default is 140.
local ceilFoV = 140 

-- //* Static variables *// --
local MIN_PLAYER_DISTANCE = 8
local REACT_MODIFIER = 2

-- //* Camera States *// --
--[[ TRACK will make the camera follow the target, as well as rotate around with it. The camera will also teleport back to the target if it falls outside of the followCutOff.
NO_TRACK will make the camera stay where it is, while just rotating around to look at the target.
PULLBACK will cause the camera to slowly pull back from where it is.
NO_TARGET will cause the camera to stop moving, and go very blurry. ]]

local cameraStates = {
	TRACK = 1, NO_TRACK = 2, PULLBACK = 3, NO_TARGET = -1
}

-- A list of HumanoidStateTypes that cause the camera to go into NO_TRACK state
local noTrackStates = {
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.Jumping,
	Enum.HumanoidStateType.Freefall
}

-- A list of HumanoidStateTypes that cause the camera to go into PULLBACK state
local pullbackStates = {
	Enum.HumanoidStateType.Dead
} 

-- Get services
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

-- Get local player, humanoid, and target (which in the case for a 3rd Person camera, is the torso)
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:wait()
local humanoid = character:WaitForChild("Humanoid")
local target = character:WaitForChild("Torso", 1) or character:WaitForChild("UpperTorso", 1)

-- Gets camera
local camera = workspace.CurrentCamera
camera.CameraSubject = target
camera.CameraType = Enum.CameraType.Scriptable

-- Setups tween, taking into account cameraSpeed and cameraElasticity to dictate tween time
local tweenInfo = TweenInfo.new(cameraSpeed * cameraElasticity)
local cameraCFrameTween = nil

-- Creates screen blur that is used when the target is too far from the camera
local blur = Instance.new("BlurEffect", camera)
blur.Size = 0

-- Returns correct camera state, depending on specified humanoidState, defaulting to TRACK
local function GetCameraState(humanoidState)
	
	-- If the target is not in the workspace, there is no target
	if not target:IsDescendantOf(game.Workspace) then
		
		return cameraStates.NO_TARGET
	end
	
	-- Iterate through the no track states to see if humanoidState is in the table
	for _, state in pairs(noTrackStates) do
		
		if humanoidState == state then
			
			return cameraStates.NO_TRACK
		end
	end
	
	-- Iterate through the pullback states to see if humanoidState is in the table
	for _, state in pairs(pullbackStates) do
		
		if humanoidState == state then
			
			return cameraStates.PULLBACK
		end
	end
	
	-- Else return default camera state
	return cameraStates.TRACK
end

-- Returns goal CFrame for the camera while it's in TRACK state
local function Track(currentCFrame)

	local playerOffset = CFrame.new(3, 3, 5)
	
	-- Generates the goalCFrame for tracking taget
	local goalCFrame =  CFrame.new(target.Position)
			* CFrame.Angles( -- Rotated by the target
				math.rad(target.Orientation.X) * cameraShake, -- Camera shake while moving
				math.rad(target.Orientation.Y), 
				math.rad(target.Orientation.Z) * cameraShake -- Camera shake  while moving
			)
			
			* playerOffset
			
	-- If the camera is too far from the goal CFrame, then teleport the camera over
	if (goalCFrame.p - currentCFrame.p).magnitude > followCutOff then
		
		-- Ensure any related tweens are cancelled
		if cameraCFrameTween then
			
			cameraCFrameTween:Cancel()
		end
		
		-- For UX, the camera does not get quite to the goal straight away
		camera.CFrame = goalCFrame:lerp(currentCFrame, 0.1)
	end
	
	return goalCFrame
end

-- Returns goal CFrame for the camera while it's in NO_TRACK state
local function NoTrack(currentCFrame)
	
	return CFrame.new(target.Position:lerp(currentCFrame.p, cameraReaction), target.Position)
end

-- Returns goal CFrame for the camera while it's in PULLBACK state
local function Pullback(currentCFrame)
	
	return CFrame.new(camera.CFrame.p, target.Position)
		* CFrame.new(0, 1, 0)
end

-- Returns goal CFrame for the camera while it's in NO_TARGET state
local function NoTarget(currentCFrame)
	
	return currentCFrame * CFrame.Angles(0, 0, 0.01)
end

-- Function that adds any relevant blur or FoV changes
local function ApplyPostProcess(cameraState)
	
	local blurDistance
	
	-- If there is no target, rapidly increase blur
	if cameraState == cameraStates.NO_TARGET then
		
		blurDistance = blur.Size + 5
		
	-- If the camera is pulling out, there should be a normal blur increase	
	elseif cameraState == cameraStates.PULLBACK then
		
		blurDistance = blur.Size + (camera.CFrame.p - target.Position).magnitude / 5
		
	else
		
		-- Else, slow blur increase
		blurDistance = (camera.CFrame.p - target.Position).magnitude / 10
	end
	
	-- If it's close enough, let's just ensure there's no blur
	if blurDistance < 5 then
		blurDistance = 0
	end
	
	-- Create and play this tween
	tweenService:Create(blur, tweenInfo, {Size = blurDistance}):Play()
	
	-- The FoV of the camera will increase depending on the speed of the target, within the bounds of the ceil and floor FoV
	local targetSpeed = target.Velocity.magnitude
	local goalFoV = math.max(math.min(targetSpeed, ceilFoV), floorFoV)
	
	-- Create and play the FoV tween
	tweenService:Create(camera, tweenInfo, {FieldOfView = ((goalFoV - camera.FieldOfView)/10) + camera.FieldOfView}):Play()
	
end

-- Function that controls the camera
function Render()

	wait(cameraUpdateInterval)
	
	-- Always focus on target
	camera.Focus = target.CFrame
	
	-- Gets current states
	local humanoidState = humanoid:GetState()
	local cameraState = GetCameraState(humanoidState)
	
	-- Setup CFrames
	local currentCFrame = camera.CFrame
	local targetCFrame = nil
	
	-- Calls the correct method depending on the camera state
	if cameraState == cameraStates.TRACK then
		
		targetCFrame = Track(currentCFrame)
		
	elseif cameraState == cameraStates.NO_TRACK then

		targetCFrame = NoTrack(currentCFrame)
	
	elseif cameraState == cameraStates.PULLBACK then
		
		targetCFrame = Pullback(currentCFrame)
			
	elseif cameraState == cameraStates.NO_TARGET then
		
		targetCFrame = NoTarget(currentCFrame)
	end
	
	-- Needs to update incase the cameraState manually changed the CFrame
	currentCFrame = camera.CFrame
	
	-- If the player is very close to the camera, it should react slightly faster
	local tempReaction = cameraReaction
	local playerDistance = (currentCFrame.p - target.Position).magnitude

	if playerDistance < MIN_PLAYER_DISTANCE then
		tempReaction = tempReaction * REACT_MODIFIER
		
	end
	
	local newCFrame = currentCFrame:lerp(targetCFrame, tempReaction)
	
	-- Create and play the tween
	cameraCFrameTween = tweenService:Create(camera, tweenInfo, {CFrame = newCFrame})
	cameraCFrameTween:Play()
	
	-- Generate any necessary post processing
	ApplyPostProcess(cameraState)
end

-- When the player respawns, need to update this
player.CharacterAdded:Connect(function()
	
	character = player.Character
	humanoid = character:WaitForChild("Humanoid")
	target = character:WaitForChild("Torso", 1) or character:WaitForChild("UpperTorso", 1)
end)

-- Camera render loop
while true do
	
	Render()
	
end
