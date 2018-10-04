local LemurUtils = {}

function LemurUtils.LoadRobase(habitat)
	local ReplicatedStorage = habitat.game:GetService("ReplicatedStorage")

	-- The paths are relative to the current working directory, which is "robase".
	local MODULES_TO_LOAD = {}

	local robase = habitat:loadFromFs("lib")
	robase.Parent = ReplicatedStorage

	-- Load all of the modules specified above
	for _, module in ipairs(MODULES_TO_LOAD) do
		local container = habitat:loadFromFs(module[1])

		if (not container) then
			print("Missing container for", module[1], module[2])
		end
		container.Name = module[2]
		container.Parent = robase
	end

	return robase
end

return LemurUtils
