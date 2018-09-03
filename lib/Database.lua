--[[
	Roblox's DataStoreService is how you can save and load information about your game
	and players permanently - across servers. For full information on the DataStoreService,
	please take a look here: http://wiki.roblox.com/index.php?title=API:Class/DataStoreService 
]]

-- Create return table
local Database = {}

-- Import libraries and helper functions
local Logger = require(script.Parent.Logger)
local DataStoreService = game:GetService("DataStoreService")

--[[
	Saves a key, value set for the specified player in Roblox's DataStoreService. Player's
	data is split down by scope, so you do not have to worry about safely storing different
	player information together. 

	Note that this function does not return anything, and will not immediately save, as it 
	is an async call. 
]]
--- @ServerOnly
function Database.SavePlayerData(player, storeName, keyName, data) --: <T extends Serializable>(Player, string, string, T) => void

	-- The scope is automatically defined, as this function saves player-specific data
	local scope = "player_" .. player.UserId

	-- Saving data isn't surefire, so a pcall check is required
	 local ok, output = pcall(function()

		-- Retrieve the data store, and update - note that this is asynchronous 
		DataStoreService:GetDataStore(storeName, scope):UpdateAsync(keyName, function(oldValue)

			-- If there wasn't an previous value, player data is being created
			if(oldValue == nil) then
			Logger.Debug("Database: Creating player data for ", player.Name,  " at ", storeName, ".", keyName, " with value of ", data)

			else
				-- Else it is being updated
				Logger.Debug("Database: Updating player data for ", player.Name,  " at ", storeName, ".", keyName, " from ", oldValue, " to ", data)
			end 

			-- UpdateAsync requires data to be returned
			return data
		end) 
	end)

	-- Should it not successfully save the player data, throw an error
 	if not ok then
		Logger.Error("Database load error at ", scope, ".", storeName, ".", keyName, ". Stacktrace: ", output)
	end
 end

 --[[
	Loads the value of a key for the specified player in Roblox's DataStoreService. Player's
	data is split down by scope, so you do not have to worry about safely storing different
	player information together. 

	Note that this function returns async, so do not expect to immediately get the data.
]]
--- @ServerOnly
function Database.LoadPlayerData(player, storeName, keyName) --: <T extends Serializable>(Player, string, string) => T
	
	-- The scope is automaticall defined, as this function loads player-specific data
	local scope = "player_" .. player.UserId

	-- If this is not overridden, the function will return nil
	local response = nil

	-- Loading from data store can throw errors, so need to catch and deal with them properly
 	local ok, output = pcall(function()
		Logger.Debug("Database: Getting player data for ", player.Name, " at ", storeName, ".", keyName)
		
		-- Get the key from the data store - is async. Will be nil if it cannot get the data
		response = DataStoreService:GetDataStore(storeName, scope):GetAsync(keyName)
		
		-- This means there is no data with the specified keyName
		if response == nil then
			Logger.Warn("Database: Could not get data from ", scope, ".", storeName, ".", keyName)
		end 
	end)

	-- If the load request threw an error, print it out here so it can be fixed
	if not ok then
		Logger.Error("Database load error at ", scope, ".", storeName, ".", keyName, ". Stacktrace: ", output)
	end

	-- Will either be nil, or the data
 	return response
end

 --[[
	Saves a key, value set for the game in Roblox's DataStoreService. This is intended for saving
	data such as monsters left, and is not per player. Take care you are not overwriting previous
	data within the same keyName that you do not want to. 

	Note that this function does not return anything, and will not immediately save, as it 
	is an async call. 
]]
--- @ServerOnly
function Database.SaveGameData(storeName, keyName, data) --: <T extends Serializable>(string, string, T) => void

	-- Saving to the data store can 
	 local ok, output = pcall(function()
		
		-- Retrieve the data store, and update - note that this is asynchronous 
		DataStoreService:GetDataStore(storeName, "game"):UpdateAsync(keyName, function(oldValue)

			-- This means new data is being created
			if(oldValue == nil) then
            Logger.Debug("Database: Creating game data at ", storeName, ".", keyName, " with value of ", data)
			else
				-- Else existing data is being overwritten
				Logger.Debug("Database: Updating game data at ", storeName, ".", keyName, " from ", oldValue, " to ", data)
			end 

			-- Roblox function requires this to be returned
			return data
		end) 
	 end)
	 
	-- If there was an error while getting the data, catch and log it
 	if not ok then
		Logger.Error("Database save error at game.", storeName, ".", keyName, ". Stacktrace: ", output)
	end
 end

--[[
	Loads the value of a key for the game in Roblox's DataStoreService. This is intended for 
	loading data such as monsters left, and is not per player.

	Note that this function returns async, so do not expect to immediately get the data.
]]
--- @ServerOnly
function Database.LoadGameData(storeName, keyName) --: <T extends Serializable>(string, string) => T
	-- If this is not overridden, the function will return nil
	local response = nil

	-- Loading from data store can throw errors, so need to catch and deal with them properly
 	local ok, output = pcall(function()
		Logger.Debug("Database: Getting game data at ", storeName, ".", keyName)
		
		-- Get the key from the data store - is async. Will be nil if it cannot get the data
		response = DataStoreService:GetDataStore(storeName, "game"):GetAsync(keyName)
		
		-- This means there is no data with the specified keyName
		if response == nil then
			Logger.Debug("Database: Could not get data from ", scope, ".", storeName, ".", keyName)
		end 
	end)

	-- If the load request threw an error, print it out here so it can be fixed
	if not ok then
		Logger.Error("Database load error at game.", storeName, ".", keyName, ". Stacktrace: ", output)
	end

	-- Will either be nil, or the data
 	return response
end

return Database