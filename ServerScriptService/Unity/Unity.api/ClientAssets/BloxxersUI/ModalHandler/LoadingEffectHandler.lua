local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local RBXAnimator = Unity:LoadLibrary("RBXAnimator")
local Network = Unity:LoadLibrary("Network")

local this = script.Parent


local Animations = {
	RBXAnimator.Timeline.new({
		{ this, "BackgroundTransparency", 0, "OutSine", 0.25, true, 0 };
		{ this.Loading, "TextTransparency", 0, "OutSine", 0.25, true, 0 };
		{ this.ProgressIndicator, "ImageTransparency", 0, "OutSine", 0.25, true, 0 };
		{ this.ProgressIndicator.Bottom.Indicator, "ImageTransparency", 0, "OutSine", 0.25, true, 0 };
		{ this.ProgressIndicator.Top.Indicator, "ImageTransparency", 0, "OutSine", 0.25, true, 0 };
	}),
	RBXAnimator.Timeline.new({
		{ this, "BackgroundTransparency", 1, "OutSine", 2, true, 0 };
		{ this.Loading, "TextTransparency", 1, "OutSine", 1, true, 0 };
		{ this.ProgressIndicator, "ImageTransparency", 1, "OutSine", 1, true, 0 };
		{ this.ProgressIndicator.Bottom.Indicator, "ImageTransparency", 1, "OutSine", 1, true, 0 };
		{ this.ProgressIndicator.Top.Indicator, "ImageTransparency", 1, "OutSine", 1, false, 0 };
	})
}

Network.BindEvent(
	"ShowModalClient",
	Enum.Receiver.Self,
	function(Query)
	if Query == "PageLoading" then
		this.Visible = true
		Animations[1]:Start()
		Network.Fire("LoadPage", Enum.Receiver.Self, true)
	end
end)

Network.BindEvent(
	"HideModalClient",
	Enum.Receiver.Self,
	function(Query)
	if Query == "PageLoading" then
		Network.Fire("LoadPage", Enum.Receiver.Self, false)
		Animations[2]:Start()
		wait(2)
		this.Visible = false
	end
end)