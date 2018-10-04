local lemur = require("modules.lemur.lib")
local LemurUtils = require("spec-source.LemurUtils")

describe(
	"ProjectileService",
	function()
		local habitat
		local robase
		local Vector3
		local ProjectileService
		before_each(
			function()
				habitat = lemur.Habitat.new()
				robase = LemurUtils.LoadRobase(habitat)
				Vector3 = habitat.environment.Vector3
				ProjectileService = habitat:require(robase.ProjectileService)
			end
		)
		describe(
			"ConnectToEvent",
			function()
				local fireProjectileStub
				before_each(
					function()
						fireProjectileStub = stub.new(ProjectileService, "FireProjectile")
					end
				)
				after_each(
					function()
						fireProjectileStub:revert()
					end
				)
				it(
					"should create a remote event and connect to it its FireProjectile function",
					function()
						-- Assert that a remote event has been created.
						local connection = ProjectileService:ConnectToEvent()
						local fireProjectileEvent = habitat.game:GetService("ReplicatedStorage"):FindFirstChild("FireProjectile")
						assert.not_nil(fireProjectileEvent)
						assert.equals(fireProjectileEvent.ClassName, "RemoteEvent")

						-- Fire the event on the server and assert that the FireProjectile stub was called with the same arguments.
						local projectileName = "Arrow"
						local spawnPosition = Vector3.new(1, 1, 1)
						fireProjectileEvent:FireServer(projectileName, spawnPosition)
						assert.spy(fireProjectileStub).was_called(1)
						assert.spy(fireProjectileStub).was_called_with(ProjectileService, projectileName, spawnPosition)

						-- Disconnect the ProjectileService from the remote event and then assert that the stub does not get called
						-- when the event is fired again.
						assert.not_nil(connection)
						connection:Disconnect()
						fireProjectileStub:clear()
						fireProjectileEvent:FireServer("Bullet", spawnPosition)
						assert.spy(fireProjectileStub).was_not_called()
					end
				)
			end
		)
		describe(
			"FireProjectile",
			function()
				pending(
					"should clone a Part by name from ServerStorage and connect a stepped update to control its flight path",
					function()
						-- TODO: Implement once lemur has CFrame, Part, Clone etc.
					end
				)
			end
		)
	end
)
