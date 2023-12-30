local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Network = Unity:LoadLibrary("Network")

Network.BindFunction(
	"Ping",
	Enum.Receiver.Client,
	function(client)
		return true
	end
)
return true