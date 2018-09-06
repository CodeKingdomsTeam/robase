describe(
	"Proof of Concept Robase test",
	function()
		package.path = package.path .. ";./?/init.lua"
		local lemur = require("modules.lemur")

		it(
			"test 1",
			function()
				-- Create a Habitat
				local habitat = lemur.Habitat.new()
				local ReplicatedStorage = habitat.game:GetService("ReplicatedStorage")

				-- Load `src/roblox` as a Folder containing some ModuleScripts:
				local Api = habitat:loadFromFs("./lib")
				Api.Parent = ReplicatedStorage
				Api.Name = "Api"

				local Objects = habitat:require(Api.Objects)
				Objects.Create("TextLabel")

				local label = habitat.game.Workspace:FindFirstChildOfClass("TextLabel")
				assert(label ~= nil)
			end
		)
	end
)
