local Utils = {}

--[[
	Creates a debounced function that delays invoking fn until after secondsWait seconds have elapsed since the last time the debounced function was invoked.
]]
function Utils.Debounce(fn, secondsWait) --: () => void, number
	assert(type(fn) == "function" or (type(fn) == "table" and getmetatable(fn) and getmetatable(fn).__call ~= nil))
	assert(type(secondsWait) == "number")

	local lastInvocation = 0
	local lastResult = nil

	return function(...)
		local args = {...}

		lastInvocation = lastInvocation + 1

		local thisInvocation = lastInvocation
		coroutine.wrap(
			function()
				wait(secondsWait)
				if thisInvocation ~= lastInvocation then
					return
				end

				lastResult = fn(unpack(args))
			end
		)()

		return lastResult
	end
end

return Utils
