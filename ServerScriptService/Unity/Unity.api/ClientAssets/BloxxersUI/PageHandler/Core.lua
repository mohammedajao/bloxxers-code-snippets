local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local RBXAnimator = Unity:LoadLibrary("RBXAnimator")
local Network = Unity:LoadLibrary("Network")

local this = script.Parent
local Settings = Unity:LoadClientConfig("UIMain_PC")
local CurrentPage = ""
local Player = game.Players.LocalPlayer
local Tweening = false

repeat wait() until _G["GAME READY"]

Network.BindEvent("ServerRequestPage", Enum.Receiver.Client, function(Query) Network.Fire("RequestPage", Enum.Receiver.Self, Query) end)

Network.BindEvent("RequestPage", Enum.Receiver.Self, function(Query)
	if not Tweening then
		Tweening = true
		
		if CurrentPage ~= Query then
			Network.Fire("ShowModalClient", Enum.Receiver.Self, "PageLoading")
			
			wait(0.2)
			
			local PageAsset = Unity:LoadServerAsset(Query)
			if PageAsset then
				PageAsset.Position = UDim2.new(0, 0, 1, 0)
				PageAsset.Parent = this

				
				if CurrentPage ~= "" then
					RBXAnimator.Timeline.new({
						{
							PageAsset,
							"Position",
							UDim2.new(0, 0, 0, 0),
							Settings.PageTweenStyle,
							Settings.PageTweenLength,
							false,
							0
						};
						{
							this[CurrentPage],
							"Position",
							UDim2.new(0, 0, 1, 0),
							Settings.PageTweenStyle,
							Settings.PageTweenLength,
							true,
							0
						};
					}):Start()
					
					this[CurrentPage]:Destroy()
					CurrentPage = Query
					Network.Fire("LaunchPage", Enum.Receiver.Self, Query)
				else
					RBXAnimator.Tween(PageAsset, "Position", UDim2.new(0, 0, 0, 0), Settings.PageTweenStyle, Settings.PageTweenLength)
					CurrentPage = Query
					Network.Fire("LaunchPage", Enum.Receiver.Self, Query)
				end
			end
			wait(0.5)
			Network.Fire("HideModalClient", Enum.Receiver.Self, "PageLoading")
		end
		
		Tweening = false
	end
	wait(0.5)
	Network.Fire("HideModalClient", Enum.Receiver.Self, "PageLoading")
end)