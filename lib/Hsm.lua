local Fsm = require(script.Parent.Fsm)

local Hsm = {}

function Hsm.new()
	local hsm = {}
	hsm.fsms = {}

	local function hsmEvent(event)
		local handlingFsmIndex = nil
		for i = #hsm.fsms, 1, -1 do
			if hsm.fsms[i][event] then
				print(event, i)
				handlingFsmIndex = i
			end
		end
		if handlingFsmIndex == nil then
			-- There is no such action on any fsm, so return nil.
			return nil
		else
			return function(...)
				-- Remove nested FSMs we won't need now.
				for i = #hsm.fsms, handlingFsmIndex + 1, -1 do
					-- Call the on_leave_ function for the current state, if there is one.
					local fsm = hsm.fsms[i]
					if fsm.current and fsm["on_leave_" .. fsm.current] then
						fsm["on_leave_" .. fsm.current](fsm, event, fsm.current, nil, ...)
					end

					table.remove(hsm.fsms)
				end

				-- Call the event function on the FSM that can handle it.
				local handlingFsm = hsm.fsms[handlingFsmIndex]
				handlingFsm[event](handlingFsm, event, handlingFsm.current, nil, ...)
			end
		end
	end

	setmetatable(
		hsm,
		{
			__index = function(_, key)
				if Hsm[key] then
					return Hsm[key]
				else
					return hsmEvent(key)
				end
			end
		}
	)

	return hsm
end

-- Adds an FSM representing a substate to the HSM's stack of FSMs.
function Hsm:pushFsm(fsmConfig)
	-- Defer the initial state until the FSM is added to the HSM.
	local initial = fsmConfig.initial
	if type(initial) == "string" then
		initial = {state = initial}
	elseif not initial then
		initial = {state = "none"}
	end
	initial.event = "init"
	initial.defer = true
	fsmConfig.initial = initial

	local fsm = Fsm.create(fsmConfig)
	table.insert(self.fsms, fsm)
	fsm.init()
end

-- Returns an array of the current substates for the HSM, starting with
-- the root FSM's substate.
function Hsm:current()
	local currentStates = {}
	for _, fsm in ipairs(self.fsms) do
		table.insert(currentStates, fsm.current)
	end
	return currentStates
end

-- Returns whether the HSM has the given state for one of
-- its substates.
function Hsm:is(state)
	for _, fsm in ipairs(self.fsms) do
		if fsm.is(state) then
			return true
		end
	end
	return false
end

-- Returns whether the HSM can handle the given event.
function Hsm:can(event)
	for _, fsm in ipairs(self.fsms) do
		if fsm[event] and fsm.can(event) then
			return true
		end
	end
	return false
end

function Hsm:cannot(event)
	return not self:can(event)
end

-- Returns an array of all of the allowed transitions for the HSM.
function Hsm:transitions()
	local transitions = {}
	for _, fsm in ipairs(self.fsms) do
		for transition in ipairs(fsm.transitions()) do
			table.insert(transitions, transition)
		end
	end
	return transitions
end

return Hsm
