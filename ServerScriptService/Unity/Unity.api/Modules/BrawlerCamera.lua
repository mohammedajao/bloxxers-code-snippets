local BrawlerCamera = {}

-- https://www.youtube.com/watch?v=mnJ-p19WDSU

local Settings = {
	DepthUpdateSpeed = 5; -- How quickly it zoomes in/out
	AngleUpdateSpeed = 7; -- How quickly it pans up and down
	PositionUpdateSpeed = 8; -- How quickly it moves left/right/up/down
	DepthMax = -10;
	DeptMin = -22;
	AngleMax = 11;
	AngleMin = 3;
}

function BrawlerCamera:CalculateCameraPositions()
	
end

function BrawlerCamera:MoveCamera()
	
end

function BrawlerCamera:Update()
	local average_center = Vector3.new(0,0,0)
	local total_positions = Vector3.new(0,0,0) -- sum of player positions
	local player_bounds = {}
	for _,player in pairs (game.Workspace:WaitForChild("TestObjects"):GetChildren()) do
		
	end
end
return BrawlerCamera