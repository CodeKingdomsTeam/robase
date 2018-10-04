local LemurUtils = {}

function LemurUtils.LoadRobase(habitat)
	local ReplicatedStorage = habitat.game:GetService("ReplicatedStorage")

	local robase = habitat:loadFromFs("lib")
	robase.Parent = ReplicatedStorage

	return robase
end

return LemurUtils
