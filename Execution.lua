local this = script.Parent
local ApiRoot = game.ReplicatedStorage

function Print(Prefix, ...)
	print(Prefix, "-",  ...)
end

--This starts up the modules in our services.

local function ExecuteServices(Root)
	for Index, Child in pairs (Root:GetChildren()) do
		if Child:IsA("ModuleScript") then
			if Child.Name:find(".disabled") then
				print("Unity has disabled the following service: " .. Child.Parent.Name)
			else
				spawn(function()
					local Result = pcall(function() require(Child) end)
				end)	
			end
		end
		ExecuteServices(Child)
	end
end

Print("Initialization", "Booting up Unity System...")

this:WaitForChild("Unity"):WaitForChild("Unity.Api").Parent = ApiRoot
Print("Intialization", "Replicated API...")
Print("Initialization", "Starting Unreal Engine services")

ExecuteServices(this:WaitForChild("Services"))

Print("Startup Complete", "Initiating launch protocol...")

local GM = require(game.ServerScriptService:WaitForChild("GameManager"))
GM:Init()
