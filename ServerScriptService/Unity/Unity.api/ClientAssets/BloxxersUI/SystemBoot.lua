local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local RBXAnimator = require("RBXAnimator")
local Network = require("Network")

print("Starting up Bloxxers...")

local RunService = game:GetService("RunService")

local this = script.Parent
local Player = game.Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera
local Music = Unity:LoadClientAsset("LoadTheme", this.Parent.Parent)
local Indicator = this:WaitForChild("Hourglass")

local BootSettings = Unity:LoadClientConfig("BootSettings")
local DebugSettings = Unity:LoadClientConfig("DebugSettings")

function Initialize()
	--while not Player.Character do wait() end
	
	--Player.Character:Destroy()
	Camera.CameraType = Enum.CameraType.Scriptable

	--[[
	Camera.CoordinateFrame = BootSettings.CameraOrigin
	Camera.Focus = BootSettings.CameraFocus
	]]
	
	wait()
	pcall(function()
		local starterGui = game:GetService('StarterGui')
		starterGui:SetCore("TopbarEnabled", false)
	end)
	
	if workspace:FindFirstChild("Message") then
		workspace.Message:Destroy()
	end
	
	game:GetService("UserInputService").MouseIconEnabled = true
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	
	Player.PlayerGui:SetTopbarTransparency(BootSettings.TopbarAlpha)
	
	wait(1)
	
	if BootSettings.MusicEnabled then
		Music.SoundId = BootSettings.MusicId
		Music:Play()
		spawn(function()
			while wait() do
				if _G["GAME READY"] then
					for i=Music.Volume,0,-0.01 do
						Music.Volume = i
						wait(0.05)
					end
					Music:Destroy()
				end
			end
		end)
	end

	if not BootSettings.SkipPreload then
		--Introduce preload screen
		RBXAnimator.Timeline.new({
			{this.Hourglass, "ImageTransparency", 0, "OutQuart", 1, true, 0};
			{this.Hourglass.Bottom.Sand, "ImageTransparency", 0, "OutQuart", 1, true, 0};
			{this.Hourglass.Top.Sand, "ImageTransparency", 0, "OutQuart", 1, true, 0};
			{this.Loading, "TextTransparency", 0, "OutQuart", 1, true, 0};
			{this.Title, "TextTransparency", 0, "OutQuart", 1, true, 0};
		}):Start()
	end
	
	wait(1)
	
	_G["CAMERA_BEGIN"] = true
	
	wait(1)
end

Initialize()

if not BootSettings.SkipPreload then
	--Preload
	local Assets = { }
	local Count = 0
	local SCount = 0
	
	local function Recurse(Root)
		if type(Root) == "table" then
			for Index, Value in pairs (Root) do
				SCount = SCount + 1
				this.Loading.Text = "Loading Server Asset #" .. SCount
				if Index ~= "" then
					game:GetService("ContentProvider"):PreloadAsync({ Index })
					wait(0.03)
				end
			end
			return
		end
		
		for _, Child in pairs (Root:GetChildren()) do
			Recurse(Child)
		end
		
		if Root:IsA("ImageLabel") and not Assets[Root.Image] then
			Count = Count + 1
			Assets[Root.Image] = true
			this.Loading.Text = "Loading Client Asset #" .. Count
			if Root.Image ~= "" then
				local success, message = pcall(function()
					game:GetService("ContentProvider"):PreloadAsync({ Root.Image })
				end)
				if not success then
					warn("Could not load Client Asset #" .. Count)
				end
			end
		end
	end
	
	wait(2)
	
	this.Loading.Text = "Connecting to Main Server Node"
	
	--We'll add this later
	--[[ 
	if not Network.Invoke("VerifyServerConnection", Enum.Receiver.Server) then
		Network.Fire("ShowConnectFailure", Enum.Receiver.Self)
		return
	end
	]]
	
	Recurse(this.Parent.Parent.Parent)
	this.Loading.Text = "Waiting for server to send asset list"
	wait(0.5)
	Recurse(Unity:LoadServerAsset("__LIST"))
	

	this.Loading.Text = "Waiting for Unity to load first page"
	
	print("Loading default page...")
	
	_G["GAME READY"] = true
		
	wait(1)
	
	Network.Fire("RequestPage", Enum.Receiver.Self, Network.Invoke("FetchGamePage", Enum.Receiver.Server))
	
	this.Loading.Text = "Done!"
	
	Network.Fire("ShowModalClient", Enum.Receiver.Self, "PageLoading")
	Network.Fire("RequestPage", Enum.Receiver.Self, "PC_Selection")
	RBXAnimator.Timeline.new({
		{this, "BackgroundTransparency", 1, "OutQuart", 1, true, 0};
		{this.Hourglass, "ImageTransparency", 1, "OutQuart", 1, true, 0};
		{this.Hourglass.Top.Sand, "ImageTransparency", 1, "OutQuart", 1, true, 0};
		{this.Loading, "TextTransparency", 1, "OutQuart", 1, true, 0};
		{this.Title, "TextTransparency", 1, "OutQuart", 1, true, 0};
	}):Start()
	
	wait(1)
	
	this.Loading.Visible = false
	Indicator.Visible = false
	this.Visible = false
	this.Parent.Parent.UIChat_PC.Visible = false

	
	wait(1)
	
	Network.Fire("HideModalClient", Enum.Receiver.Self, "PageLoading")
end
