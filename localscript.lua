--local script put this inside starterplayerscripts

local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local event = game.ReplicatedStorage:WaitForChild("SteelChainEvent")

local cooldown = false
local cooldownTime = 5

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or cooldown then return end

	if input.KeyCode == Enum.KeyCode.Z then
		local target = mouse.Target
		if target then
			local humanoid = target.Parent:FindFirstChild("Humanoid") or 
				target.Parent.Parent:FindFirstChild("Humanoid")
			if humanoid then
				print("Z pressed - targeting:", target.Parent.Name)
				cooldown = true
				event:FireServer(target.Parent)

				-- Simple cooldown message
				task.wait(cooldownTime)
				cooldown = false
				print("Cooldown ended")
			end
		end
	end
end)
