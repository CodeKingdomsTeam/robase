local Database = {}
local Logger = require(script.Parent.Logger)

local backend = game:GetService("DataStoreService")

--- @ServerOnly
function Database.SavePlayerData(player, storeName, keyName, data) --: <T extends Serializable>(Player, string, string, T) => void
	local scope = "player_" .. player.UserId
	local ok, output =
		pcall(
		function()
			backend:GetDataStore(storeName, scope):UpdateAsync(
				keyName,
				function(oldValue)
					if (oldValue == nil) then
						Logger.Debug(
							"Database: Creating player data for ",
							player.Name,
							" at ",
							storeName,
							".",
							keyName,
							" with value of ",
							data
						)
					else
						Logger.Debug(
							"Database: Updating player data for ",
							player.Name,
							" at ",
							storeName,
							".",
							keyName,
							" from ",
							oldValue,
							" to ",
							data
						)
					end
					return data
				end
			)
		end
	)
	if not ok then
		Logger.Error("Database load error at ", scope, ".", storeName, ".", keyName, ". Stacktrace: ", output)
	end
end

--- @ServerOnly
function Database.LoadPlayerData(player, storeName, keyName) --: <T extends Serializable>(Player, string, string) => T
	local scope = "player_" .. player.UserId
	local response = nil
	local ok, output =
		pcall(
		function()
			Logger.Debug("Database: Getting player data for ", player.Name, " at ", storeName, ".", keyName)
			response = backend:GetDataStore(storeName, scope):GetAsync(keyName)

			if response == nil then
				Logger.Warn("Database: Could not get data from ", scope, ".", storeName, ".", keyName)
			end
		end
	)
	if not ok then
		Logger.Error("Database load error at ", scope, ".", storeName, ".", keyName, ". Stacktrace: ", output)
	end
	return response
end

--- @ServerOnly
function Database.SaveGameData(storeName, keyName, data) --: <T extends Serializable>(string, string, T) => void
	local ok, output =
		pcall(
		function()
			backend:GetDataStore(storeName, "game"):UpdateAsync(
				keyName,
				function(oldValue)
					if (oldValue == nil) then
						Logger.Debug("Database: Creating game data at ", storeName, ".", keyName, " with value of ", data)
					else
						Logger.Debug("Database: Updating game data at ", storeName, ".", keyName, " from ", oldValue, " to ", data)
					end
					return data
				end
			)
		end
	)
	if not ok then
		Logger.Error("Database save error at game.", storeName, ".", keyName, ". Stacktrace: ", output)
	end
end

--- @ServerOnly
function Database.LoadGameData(storeName, keyName) --: <T extends Serializable>(string, string) => T
	local response = nil
	local ok, output =
		pcall(
		function()
			Logger.Debug("Database: Getting game data at ", storeName, ".", keyName)
			response = backend:GetDataStore(storeName, "game"):GetAsync(keyName)

			if response == nil then
				Logger.Debug("Database: Could not get data from ", scope, ".", storeName, ".", keyName)
			end
		end
	)
	if not ok then
		Logger.Error("Database load error at game.", storeName, ".", keyName, ". Stacktrace: ", output)
	end
	return response
end

return Database
