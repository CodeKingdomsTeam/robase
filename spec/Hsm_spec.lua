local lemur = require("modules.lemur.lib")
local LemurUtils = require("spec-source.LemurUtils")

describe(
	"Hsm",
	function()
		local habitat
		local robase
		local Hsm
		before_each(
			function()
				habitat = lemur.Habitat.new()
				robase = LemurUtils.LoadRobase(habitat)
				Hsm = habitat:require(robase.Hsm)
			end
		)
		describe(
			"new",
			function()
				it(
					"should instantiate a new HSM consisting of no FSMs",
					function()
						assert(Hsm)
						local hsm = Hsm.new()
						assert.not_nil(hsm)
						assert.are.same({}, hsm.fsms)
					end
				)
			end
		)
		describe(
			"pushFsm",
			function()
				-- Create an HSM consisting of an FSM with a nested FSM.
				-- Assert that both FSMs are added to the HSM and that the
				-- on_enter callbacks are called at the right time.
				local function testHsmWithInitialStates(initialStates)
					local hsm = Hsm.new()
					local output = {}
					hsm:pushFsm(
						{
							initial = initialStates[1],
							callbacks = {
								on_enter_A = function()
									table.insert(output, "A1")
									hsm:pushFsm(
										{
											initial = initialStates[2],
											callbacks = {
												on_enter_B = function()
													table.insert(output, "B")
												end
											}
										}
									)
									table.insert(output, "A2")
								end
							}
						}
					)
					assert.equal(2, #hsm.fsms)
					assert.are.same({"A1", "B", "A2"}, output)
				end

				it(
					"should add a new FSM to the HSM and move it to its initial state when it is a string",
					function()
						testHsmWithInitialStates({"A", "B"})
					end
				)
				it(
					"should add a new FSM to the HSM and move it to its initial state when it is a table",
					function()
						testHsmWithInitialStates({{state = "A"}, {state = "B"}})
					end
				)
				it(
					"should throw if an FSM's initial state is neither a string nor a table",
					function()
						local hsm = Hsm.new()
						assert.has.errors(
							function()
								hsm:pushFsm(
									{
										initial = 123
									}
								)
							end
						)
					end
				)
			end
		)
		local function createHsm()
			local hsm = Hsm.new()
			local function onEnterB()
				hsm:pushFsm(
					{
						initial = "C"
					}
				)
			end
			local function onEnterA()
				hsm:pushFsm(
					{
						initial = "B",
						callbacks = {
							on_enter_B = onEnterB
						}
					}
				)
			end
			hsm:pushFsm(
				{
					initial = "A",
					callbacks = {
						on_enter_A = onEnterA
					}
				}
			)
			return hsm
		end
		describe(
			"current",
			function()
				it(
					'should return an array containing "none" if there is no initial state for the HSM',
					function()
						local hsm = Hsm.new()
						hsm:pushFsm({})
						assert.are.same({"none"}, hsm:current())
					end
				)
				it(
					"should return an array of states of each of the FSMs in the current state",
					function()
						local hsm = createHsm()
						assert.are.same({"A", "B", "C"}, hsm:current())
					end
				)
			end
		)
		describe(
			"is",
			function()
				it(
					"returns false if the given state is not the state of one of the nested FSMs",
					function()
						local hsm = createHsm()
						assert.is_false(hsm:is("D"))
					end
				)
				it(
					"returns true if the given state is the state of one of the nested FSMs",
					function()
						local hsm = createHsm()
						assert.is_true(hsm:is("A"))
						assert.is_true(hsm:is("B"))
						assert.is_true(hsm:is("C"))
					end
				)
			end
		)
		describe(
			"can",
			function()
				it(
					"returns false if the given transition is not possible for any of the FSMs",
					function()
						local hsm = Hsm.new()
						local onEnterA =
							hsm:pushFsm(
							{
								initial = "C",
								events = {
									{name = "dToC", from = "D", to = "C"}
								}
							}
						)
						hsm:pushFsm(
							{
								initial = "A",
								events = {
									{name = "aToB", from = "A", to = "B"}
								},
								callbacks = {
									on_enter_A = onEnterA
								}
							}
						)
						assert.is_false(hsm:can("dToC"))
						assert.is_true(hsm:cannot("dToC"))
					end
				)
				it(
					"returns true if the given transition is possible for at least one of the FSMs",
					function()
						local hsm = Hsm.new()
						local onEnterA =
							hsm:pushFsm(
							{
								initial = "C",
								events = {
									{name = "cToD", from = "C", to = "D"}
								}
							}
						)
						hsm:pushFsm(
							{
								initial = "A",
								events = {
									{name = "aToB", from = "A", to = "B"}
								},
								callbacks = {
									on_enter_A = onEnterA
								}
							}
						)
						assert.is_true(hsm:can("cToD"))
						assert.is_false(hsm:cannot("cToD"))
					end
				)
			end
		)

		describe(
			"events",
			function()
				it(
					"should call the on_leave callbacks of a nested FSM's state when leaving the substate using that FSM",
					function()
						local hsm = Hsm.new()
						local outputs = {}
						local onEnterC = function()
							hsm:pushFsm(
								{
									initial = "D",
									callbacks = {
										on_leave_D = function()
											table.insert(outputs, "D")
										end
									}
								}
							)
						end
						local onEnterA = function()
							hsm:pushFsm(
								{
									initial = "C",
									callbacks = {
										on_enter_C = onEnterC,
										on_leave_C = function()
											table.insert(outputs, "C")
										end
									}
								}
							)
						end
						hsm:pushFsm(
							{
								initial = "A",
								events = {
									{name = "aToB", from = "A", to = "B"}
								},
								callbacks = {
									on_enter_A = onEnterA
								}
							}
						)
						hsm:aToB()
						assert(hsm:is("B"))
						assert.are.same({"D", "C"}, outputs)
					end
				)
			end
		)
	end
)
