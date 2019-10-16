local LemurUtils = {}

function LemurUtils.LoadRobase(habitat)
	local ReplicatedStorage = habitat.game:GetService("ReplicatedStorage")

	local robase = habitat:loadFromFs("lib")
	robase.Parent = ReplicatedStorage

	local luafsm = habitat:loadFromFs("modules/lua-fsm/src/fsm.lua")
	luafsm.Name = "Fsm"
	luafsm.Parent = robase

	return robase
end

return LemurUtils
