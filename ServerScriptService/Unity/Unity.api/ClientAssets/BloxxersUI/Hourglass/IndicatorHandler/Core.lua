local Unity 		= require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local RBXAnimator 	= require("RBXAnimator")

local this = script.Parent

local AnimationSettings = require(script:WaitForChild("Animation"))

local HorizontalSandPosition = UDim2.new(0, .25*AnimationSettings.HourGlassSize - 1, 0, .25*AnimationSettings.HourGlassSize - (AnimationSettings.HourGlassSize <= 64 and 1))
local HorizontalSandSize = UDim2.new(0, .5*AnimationSettings.HourGlassSize + 2, 0, 2 + 38*AnimationSettings.HourGlassSize / 64)

local function Init()
	this.Position = AnimationSettings.HourGlassCenter - UDim2.new(0, .5*AnimationSettings.HourGlassSize, 0, AnimationSettings.HourGlassSize)
	this.Size = UDim2.new(0, AnimationSettings.HourGlassSize, 0, 2*AnimationSettings.HourGlassSize)
		
	this.Top.Position = HorizontalSandPosition
	this.Top.Size = HorizontalSandSize
	this.Top.Sand.Size = this.Top.Size
	this.Top.Sand.Position = this.Top.Sand.Position
		
	this.Bottom.Position = UDim2.new(0, HorizontalSandPosition.X.Offset,0, 1.125*AnimationSettings.HourGlassSize)
	this.Bottom.Size = UDim2.new(0, HorizontalSandSize.X.Offset, 0, 0)
	this.Bottom.Sand.Position = UDim2.new()
	this.Bottom.Sand.Size = UDim2.new(0,HorizontalSandSize.X.Offset, 0, HorizontalSandSize.Y.Offset)
end

Init()

while not _G["GAME READY"] do
	this.Bottom.Visible = true
	RBXAnimator.Timeline.new({
		{this.Top, "Position", HorizontalSandPosition + UDim2.new(0, 0, 0,HorizontalSandPosition.Y.Offset*5), "Linear", AnimationSettings.AnimationTime, true};
		{this.Top.Sand, "Position",UDim2.new(0, 0, 0, -HorizontalSandPosition.Y.Offset*5), "Linear", AnimationSettings.AnimationTime, true};	
		{this.Bottom, "Size", HorizontalSandSize, "Linear", AnimationSettings.AnimationTime+.03, false};		
	}):Start()
	this.Top.Visible = false
			
	RBXAnimator.Timeline.new({
		{this, "Rotation", 180, "OutQuart", AnimationSettings.Duration, false};
	}):Start()

	this.Rotation = 180
	this.Top.Position = HorizontalSandPosition
	this.Top.Sand.Position = UDim2.new()
	this.Bottom.Size = UDim2.new(0, 0.5*AnimationSettings.HourGlassSize + 2, 0, 0)
	this.Top.Visible = true
	this.Bottom.Visible = false
	this.Rotation = 0	
end


