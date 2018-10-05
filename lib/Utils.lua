local Utils = {}

--[[
	Creates a debounced function that delays invoking fn until after delayS milliseconds have elapsed since the last time the debounced function was invoked.
]]
function Utils.Debounce(fn, delayS)
	local lastInvocation = 0
	local lastResult = nil

	return function(...)
		lastInvocation = lastInvocation + 1

		local thisInvocation = lastInvocation
		delay(
			delayS,
			function()
				if thisInvocation ~= lastInvocation then
					return
				end

				lastResult = fn(unpack(arg))
			end
		)

		return lastResult
	end
end

return Utils
