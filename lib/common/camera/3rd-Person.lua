-- Configurable variables
local cameraSpeed = 0.1 -- default 0.1
local cameraElasticity = 2 -- default 2
local cameraReaction = 0.3 -- default 0.3
local cameraShake = 0.005 -- default 0.05
local followCutOff = 50 -- default 50
local floorFoV = 70 -- default 70
local ceilFoV = 140 -- default 140


-- List of possible camera states
local cameraStates = {
	TRACK = 1, NO_TRACK = 2, PULLBACK = 3, NO_TARGET = -1
}

-- Dictates when to go into this state type
local noTrackStates = {
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.Jumping,
	Enum.HumanoidStateType.Freefall
}

-- Dictates when to go into this state type
local pullbackStates = {
	Enum.HumanoidStateType.Dead
} 

-- Grabs services
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

-- Grabs local player
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:wait()
local humanoid = character:WaitForChild("Humanoid")
local target = character:WaitForChild("Torso", 1) or character:WaitForChild("UpperTorso", 1)

-- Intantiates camera
local camera = workspace.CurrentCamera
camera.CameraSubject = target
camera.CameraType = Enum.CameraType.Scriptable

-- Setups tween info
local tweenInfo = TweenInfo.new(cameraSpeed * cameraElasticity)
local cameraCFrameTween = nil

-- Creates screen blur when the player is far from the camera
local blur = Instance.new("BlurEffect", camera)
blur.Size = 0

-- Returns correct camera state, depending on specified humanoidState
-- Default is track
local function GetCameraState(humanoidState)
	
	-- If the target is not in the workspace, there is no target
	if(not target:IsDescendantOf(game.Workspace))then
		
		return cameraStates.NO_TARGET
	end
	
	-- Iterate through the no track states to see if humanoidState is in the table
	for _, state in pairs(noTrackStates)do
		
		if(humanoidState == state)then
			
			return cameraStates.NO_TRACK
		end
	end
	
	-- Iterate through the pullback states to see if humanoidState is in the table
	for _, state in pairs(pullbackStates)do
		
		if(humanoidState == state)then
			
			return cameraStates.PULLBACK
		end
	end
	
	-- Else return default camera state
	return cameraStates.TRACK
end

-- Returns goal CFrame
local function RenderTrack()
	
	-- Generates the goalCFrame for tracking taget
	local goalCFrame =  CFrame.new(target.Position) -- The position of the target
			* CFrame.Angles( -- Rotated by the target
				math.rad(target.Orientation.X) * cameraShake, -- Camera shake while moving
				math.rad(target.Orientation.Y), 
				math.rad(target.Orientation.Z) * cameraShake -- Camera shake  while moving
			)
			
			* CFrame.new(3, 3, 5) -- The offset from the player
			
	-- If the camera is too far from the goal CFrame, then teleport the camera over
	if((goalCFrame.p - camera.CFrame.p).magnitude > followCutOff)then
		
		-- Ensure any related tweens are cancelled
		if(cameraCFrameTween)then
			
			cameraCFrameTween:Cancel()
		end
		
		-- For UX, the camera does not get quite to the goal straight away
		camera.CFrame = goalCFrame:lerp(camera.CFrame, 0.1)
	end
	
	return goalCFrame
end

-- Returns goal CFrame for not tracking
local function RenderNoTrack(currentCFrame)
	
	return CFrame.new(target.Position:lerp(currentCFrame.p, cameraReaction), target.Position)
end

-- Returns goal CFrame for pulling back
local function RenderPullback(currentCFrame)
	
	-- Slowly rotates over, and out from target
	return CFrame.new(camera.CFrame.p, target.Position:lerp(currentCFrame.p, cameraReaction))
		* CFrame.new(0, 1, 0)
end

-- Returns goal CFrame when there is no target
local function RenderNoTarget()
	
	-- Very slowly rotates over
	return camera.CFrame * CFrame.Angles(0, 0, 0.01)
end

-- Function that adds any relevant blur or FoV changes
local function PostProcessing(cameraState)
	
	local blurDistance = 0
	
	
	-- If there is no target, rapidly increase blur
	if(cameraState == cameraStates.NO_TARGET)then
		
		blurDistance = blur.Size + 5
		
	-- If the camera is pulling out, there should be a normal blur increase	
	elseif(cameraState == cameraStates.PULLBACK)then
		
		blurDistance = blur.Size + (camera.CFrame.p - target.Position).magnitude / 5
		
	else
		
		-- Else, slow blur increase
		blurDistance = (camera.CFrame.p - target.Position).magnitude / 10
	end
	
	-- If it's close enough, let's just ensure there's no blur
	if(blurDistance < 5)then
		blurDistance = 0
	end
	
	-- Create and play this tween
	tweenService:Create(blur, tweenInfo, {Size = blurDistance}):Play()
	
	-- Grabs the speed of the target, and dictates goalFoV depending on ceiling and floor as configured
	local targetSpeed = target.Velocity.magnitude
	local goalFoV = math.max(math.min(targetSpeed, ceilFoV), floorFoV)
	
	-- Create and play the FoV tween
	tweenService:Create(camera, tweenInfo, {FieldOfView = ((goalFoV - camera.FieldOfView)/10) + camera.FieldOfView}):Play()
	
end

-- Function that controls the camera
function Render()
	-- Waits camera speed rate
	wait(cameraSpeed)
	
	-- Ensures the camera focus is correct
	camera.Focus = target.CFrame
	
	-- Gets current states
	local humanoidState = humanoid:GetState()
	local cameraState = GetCameraState(humanoidState)
	
	-- Setup CFrames
	local currentCFrame = camera.CFrame
	local targetCFrame = nil
	
	-- Calls the correct method depending on the camera state
	if(cameraState == cameraStates.TRACK)then
		
		targetCFrame = RenderTrack()
		
	elseif(cameraState == cameraStates.NO_TRACK)then

		targetCFrame = RenderNoTrack(currentCFrame)
	
	elseif(cameraState == cameraStates.PULLBACK)then
		
		targetCFrame = RenderPullback(currentCFrame)
			
	elseif(cameraState == cameraStates.NO_TARGET)then
		
		targetCFrame = RenderNoTarget()
	end
	
	-- Needs to update incase the cameraState manually changed the CFrame
	currentCFrame = camera.CFrame
	
	-- If the player is very close to the camera, it should react slightly faster
	local tempReaction = cameraReaction
	if((currentCFrame.p - target.Position).magnitude < 8)then
		tempReaction = tempReaction * 2
		
	end
	
	local newCFrame = currentCFrame:lerp(targetCFrame, tempReaction)
	
	-- Create and play the tween
	cameraCFrameTween = tweenService:Create(camera, tweenInfo, {CFrame = newCFrame})
	cameraCFrameTween:Play()
	
	-- Generate any necessary post processing
	PostProcessing(cameraState)
end

-- When the player respawns, need to update this
player.CharacterAdded:Connect(function()
	
	character = player.Character or player.CharacterAdded:wait()
	humanoid = character:WaitForChild("Humanoid")
	target = character:WaitForChild("Torso", 1) or character:WaitForChild("UpperTorso", 1)
end)

-- Camera render loop
while(true)do
	
	Render()
	
end
