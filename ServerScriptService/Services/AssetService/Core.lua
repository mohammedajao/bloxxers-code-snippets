local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Network = require("Network")

local Storage = game.ServerScriptService:WaitForChild("Unity")
local Configuration = Storage:WaitForChild("Configuration")
local Assets = Storage:WaitForChild("Assets")

local Temp = Instance.new("Folder", game.ReplicatedStorage)

local AssetList = { }

Temp.Name = "Temp"

function Recurse(Root)
	for Index, Child in pairs (Root:GetChildren()) do
		Recurse(Child)
	end
	
	if Root:IsA("ImageLabel") and not AssetList[Root.Image] then
		AssetList[Root.Image] = true
	end
end

Network.BindFunction(
	"__reqc",
	Enum.Receiver.Server,
	function(Client, Query)
		return require(Configuration:WaitForChild(Query))
	end
)

Network.BindFunction(
	"__reqcs",
	Enum.Receiver.Self,
	function(Query)
		return require(Configuration:WaitForChild(Query))
	end
)

Network.BindFunction(
	"__reqa",
	Enum.Receiver.Server,
	function(Client, Query)
		if Query == "__LIST" then
			Recurse(Assets)
			return AssetList
		end
		
		local File = Assets:FindFirstChild(Query)
		
		if File then
			local Clone = File:Clone()
			Clone.Parent = Temp
			return Clone
		else
			return nil
		end
	end
)

return true