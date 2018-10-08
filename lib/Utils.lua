local Utils = {}

--[[
	Creates a debounced function that delays invoking fn until after delayS milliseconds have elapsed since the last time the debounced function was invoked.
]]
function Utils.Debounce(fn, delayS)
	assert(type(fn) == "function" or (type(fn) == "table" and getmetatable(fn) and getmetatable(fn).__call ~= nil))
	assert(type(delayS) == "number")

	local lastInvocation = 0
	local lastResult = nil

	return function(...)
		local args = {...}

		lastInvocation = lastInvocation + 1

		local thisInvocation = lastInvocation
		delay(
			delayS,
			function()
				if thisInvocation ~= lastInvocation then
					return
				end

				lastResult = fn(unpack(args))
			end
		)

		return lastResult
	end
end

return Utils
