local Purchases = {}
local Logger = require(script.Parent.Logger)

local backend = game:GetService("MarketplaceService")
local callbacksByPlayerName = {}

local function handleProductPurchase(player, gamepassId, wasPurchased)
	--If it's nil, it'll be a non gamepass purchase - this is fine
	if (wasPurchased == false) then
		return
	end

	local callbackName = player.Name

	local callbacks = callbacksByPlayerName[callbackName]
	for _, callback in pairs(callbacks) do
		callback(player, gamepassId)
	end
end

function Purchases.ConnectPlayerPurchased(playerName, callback)
	local callbackName = playerName
	if (not callbacksByPlayerName[callbackName]) then
		callbacksByPlayerName[callbackName] = {}
	end
	table.insert(callbacksByPlayerName[callbackName], callback)
end

function Purchases.PromptGamePassPurchase(player, gamePassId) --: (Player, number) => void
	local ok, error =
		pcall(
		function()
			backend:PromptGamePassPurchase(player, gamePassId)
		end
	)
	if not ok then
		Logger.Error(
			"PromptGamePassPurchase error for ",
			player.name,
			" with gamePass of ",
			gamePassId,
			". Stacktrace: ",
			error
		)
	end
end

function Purchases.PromptPurchase(player, assetId) --: (Player, number) => void
	backend:PromptProductPurchase(player, assetId)
end

function Purchases.UserOwnsGamePassAsync(userId, gamePassId) --: (number, number) => bool
	local ok, error =
		pcall(
		function()
			return backend:UserOwnsGamePassAsync(userId, gamePassId)
		end
	)
	if not ok then
		Logger.Error("UserOwnsGamePassAsync error for ", userId, " with gamePass of ", gamePassId, ". Stacktrace: ", error)
	end
end

function Purchases.PlayerOwnsAsset(player, assetId) --: (Player, number) => bool
	return backend:PlayerOwnsAsset(player, assetId)
end

function Purchases.GetProductInfo(assetId) --: <T extends Serializable>(number) => T
	return backend:GetProductInfo(assetId)
end

-- If the executor is a server, create relevant listeners and callbacks from Roblox upon a purchase
if (game:GetService("RunService"):IsServer()) then
	-- This deals with all purchases that are not Game Passes
	function backend.ProcessReceipt(receiptInfo)
		local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		handleProductPurchase(player, receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- This deals with Game Passes
	backend.PromptGamePassPurchaseFinished:Connect(handleProductPurchase)
end

return Purchases
