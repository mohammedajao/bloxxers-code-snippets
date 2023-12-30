local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local TimeFormat = require("TimeFormat")
local Network = require("Network")

local Bans = Unity:LoadServerConfig("BanList")

Network.BindFunction(
	"VerifyServerConnection",
	Enum.Receiver.Server,
	function(Client)
		wait(math.random(1, 3))
		return true
	end
)

Network.BindFunction(
	"CheckBanStatus",
	Enum.Receiver.Server,
	function(Client, Query)
		for _, Id in pairs (Bans) do
			if Query == Id[1] then
				if Id[2] and os.time() < Id[2] then
					return {
						true,
						TimeFormat.format(Id[2] - 4 * 60 * 60),
						Id[3],
						Id[2]
					}
				elseif not Id[2] then
					return {
						true,
						"Never",
						Id[3],
						Id[2]
					}
				end
			end
		end
		
		return { false }
	end
)

return true