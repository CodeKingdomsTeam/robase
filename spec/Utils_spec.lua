local lemur = require("modules.lemur.lib")
local Utils = require("Utils")

describe(
	"Utils",
	function()
		describe(
			"Debounce",
			function()
				local habitat
				local scheduler
				local callSpy
				local debounced
				local oldDelay

				before_each(
					function()
						habitat = lemur.Habitat.new()
						scheduler = habitat.taskScheduler

						oldDelay = _G.delay
						_G.delay = habitat.environment.delay

						callSpy =
							spy.new(
							function(...)
								local printResult = ""

								for _, v in ipairs(arg) do
									printResult = printResult .. tostring(v) .. "\t"
								end
								printResult = printResult .. "\n"

								print("Called with " .. printResult)

								return arg
							end
						)

						debounced = Utils.Debounce(callSpy, 100)
					end
				)

				after_each(
					function()
						_G.delay = oldDelay
					end
				)

				it(
					"should not call before the delay has elapsed",
					function()
						debounced("hi")

						assert.spy(callSpy).was_not_called()

						scheduler:step(99)

						assert.spy(callSpy).was_not_called()
					end
				)

				it(
					"should call after the delay",
					function()
						debounced("hi")

						scheduler:step(100)

						assert.spy(callSpy).was_called(1)
						assert.spy(callSpy).was_called_with("hi")
					end
				)

				it(
					"should group calls and call the debounced function with the last arguments",
					function()
						local result = debounced("hi")

						assert.are.same(result, nil)

						local result2 = debounced("guys")

						assert.are.same(result2, nil)

						scheduler:step(100)

						assert.spy(callSpy).was_called(1)
						assert.spy(callSpy).was_called_with("guys")

						local result3 = debounced("stuff")

						assert.are.same(result3, {[1] = "guys", n = 1})
					end
				)
			end
		)
	end
)
