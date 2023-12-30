local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Network = require("Network")
local RuleSet = Unity:LoadServerConfig("RuleSet")

local SettingsManager = {
	weight = RuleSet.weightMultiplier / 100,
	gravity = RuleSet.gravityMultiplier / 100,
	airControl = RuleSet.airControlMultiplier / 100,
	hitStun = RuleSet.hitStunMultiplier / 100,
	hitLag = RuleSet.hitLagMultiplier / 100,
	shieldStun = RuleSet.shieldStunMultiplier / 100,
	
	ledgeConflict             = RuleSet.ledgeConflict,
	ledgeSweetspotSize        = RuleSet.ledgeSweetspotSize,
	ledgeSweetspotForwardOnly = RuleSet.ledgeSweetspotForwardOnly,
	teamLedgeConflict         = RuleSet.teamLedgeConflict,
	ledgeInvincibilityTime    = RuleSet.ledgeInvincibilityTime,
	regrabInvincibility       = RuleSet.regrabInvincibility,
	slowLedgeWakeupThreshold  = RuleSet.slowLedgeWakeupThreshold,
	
	airDodgeType = RuleSet.airDodgeType,
	freeDodgeSpecialFall = RuleSet.freeDodgeSpecialFall,
	enableWaveDash = RuleSet.enableWaveDash,
	airDodgeLag = RuleSet.airDodgeLag,
	
	respawnDowntime = RuleSet.respawnDowntime,
	respawnLifetime = RuleSet.respawnLifetime,
	respawnInvincibility = RuleSet.respawnInvincibility,

	lagCancel				  = RuleSet.lagCancel
}


function SettingsManager:GetSettting(setting)
	return self[setting]
end

Network.BindFunction(
	"GetSettingManager",
	Enum.Receiver.Client,
	function()
		return SettingsManager
	end
)



return SettingsManager