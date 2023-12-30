local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local RBXAnimator = require("RBXAnimator")
local Network = require("Network")

local this = script.Parent
local Showing = false

Network.BindEvent(
	"ShowConnectFailure",
	Enum.Receiver.Self,
	function()
		if not Showing then
			Showing = true
			
			pcall(function()
				this.Parent.Parent.UIBoot_PC:Destroy()
				this.Parent.Parent.UIMain_PC:Destroy()
				this.Parent.Parent.UIModal_PC:Destroy()
			end)
			
			RBXAnimator.Timeline.new({
				{ this, "BackgroundTransparency", 0, "OutSine", 1.5, true, 0 };
				{ this.Content, "TextTransparency", 0, "OutSine", 1.5, true, 0 };
			}):Start()
		end
	end
)
