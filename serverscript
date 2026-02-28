local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event = ReplicatedStorage:WaitForChild("SteelChainEvent")

-- Function to find the floor precisely
local function getFloor(position)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {workspace:FindFirstChild("Debris")}
	
	local raycastResult = workspace:Raycast(position, Vector3.new(0, -100, 0), raycastParams)
	if raycastResult then
		return raycastResult.Position
	end
	return position
end

-- Function to create chain links in a spiral around a target
local function createChainWrap(targetHrp, playerChar)
	local links = {}
	local linkCount = 12
	local spiralHeight = 8
	local spiralRadius = 3
	
	-- Get hand position for chain start
	local hand = playerChar:FindFirstChild("RightHand") or playerChar:FindFirstChild("Right Arm")
	if not hand then return links end
	
	local handPos = hand.Position
	
	for i = 1, linkCount do
		-- Calculate spiral position around the victim
		local progress = i / linkCount
		local angle = progress * math.pi * 4 -- 2 full rotations
		local heightOffset = progress * spiralHeight - spiralHeight/2 -- from -4 to +4
		local radius = spiralRadius * (1 - progress * 0.5) -- radius shrinks as it wraps
		
		local xOffset = math.cos(angle) * radius
		local zOffset = math.sin(angle) * radius
		
		-- Position relative to victim's HRP
		local linkPos = targetHrp.Position + Vector3.new(xOffset, heightOffset, zOffset)
		
		-- Create chain link
		local link = Instance.new("Part", workspace)
		link.Size = Vector3.new(0.4, 0.4, 0.8)
		link.Material = Enum.Material.Metal
		link.Color = Color3.fromRGB(150, 150, 170)
		link.Anchored = true
		link.CanCollide = false
		link.Position = linkPos
		
		-- Rotate to face outward from center
		local direction = (linkPos - targetHrp.Position).Unit
		if direction.Magnitude > 0 then
			link.CFrame = CFrame.lookAt(linkPos, linkPos + direction) * CFrame.Angles(0, math.rad(90), 0)
		end
		
		-- Add slight transparency for metal look
		link.Transparency = 0.2
		
		table.insert(links, link)
		
		-- Create connecting beam to next link (except last)
		if i < linkCount then
			local nextPos = targetHrp.Position + Vector3.new(
				math.cos(angle + (math.pi * 4 / linkCount)) * radius,
				heightOffset + (spiralHeight / linkCount),
				math.sin(angle + (math.pi * 4 / linkCount)) * radius
			)
			
			local beamPart = Instance.new("Part", workspace)
			beamPart.Size = Vector3.new(0.2, 0.2, (nextPos - linkPos).Magnitude)
			beamPart.Material = Enum.Material.Metal
			beamPart.Color = Color3.fromRGB(140, 140, 160)
			beamPart.Anchored = true
			beamPart.CanCollide = false
			beamPart.CFrame = CFrame.lookAt(linkPos, nextPos) * CFrame.new(0, 0, -beamPart.Size.Z/2)
			beamPart.Transparency = 0.3
			
			table.insert(links, beamPart)
		end
	end
	
	-- Add a chain from hand to the first link
	if hand then
		local firstLink = links[1]
		if firstLink then
			local connectingChain = Instance.new("Part", workspace)
			connectingChain.Size = Vector3.new(0.3, 0.3, (handPos - firstLink.Position).Magnitude)
			connectingChain.Material = Enum.Material.Metal
			connectingChain.Color = Color3.fromRGB(160, 160, 180)
			connectingChain.Anchored = true
			connectingChain.CanCollide = false
			connectingChain.CFrame = CFrame.lookAt(handPos, firstLink.Position) * CFrame.new(0, 0, -connectingChain.Size.Z/2)
			connectingChain.Transparency = 0.2
			
			table.insert(links, connectingChain)
		end
	end
	
	return links
end

event.OnServerEvent:Connect(function(player, victim)
	local victimHrp = victim:FindFirstChild("HumanoidRootPart")
	local playerChar = player.Character
	
	if not victimHrp or not playerChar or victimHrp:FindFirstChild("IsBeingSlammed") then return end

	-- Tag to prevent double grabs
	local tag = Instance.new("BoolValue", victimHrp)
	tag.Name = "IsBeingSlammed"
	Debris:AddItem(tag, 2)

	-- Calculate ground position BEFORE any movement
	local groundPos = getFloor(victimHrp.Position)
	local startPos = victimHrp.Position
	local liftHeight = 15
	
	-- Store the exact target positions
	local liftTarget = Vector3.new(startPos.X, startPos.Y + liftHeight, startPos.Z)
	local slamTarget = Vector3.new(startPos.X, groundPos.Y + 3, startPos.Z)
	
	print("Chain Grab Started - Wrapping target...")
	
	-- CREATE CHAIN WRAP EFFECT
	local chainLinks = createChainWrap(victimHrp, playerChar)
	
	-- Wait a moment to show the wrap
	task.wait(0.3)
	
	-- Make chain links glow before lift
	for _, link in ipairs(chainLinks) do
		if link and link.Parent then
			-- Quick flash effect
			local originalColor = link.Color
			link.Color = Color3.fromRGB(255, 255, 255)
			link.Material = Enum.Material.Neon
			
			-- Tween back to metal
			task.delay(0.1, function()
				if link and link.Parent then
					link.Color = originalColor
					link.Material = Enum.Material.Metal
				end
			end)
		end
	end
	
	task.wait(0.2)
	
	-- Anchor the victim
	victimHrp.Anchored = true
	
	-- 1. LIFT TWEEN (smooth up with slight ease out)
	local liftTween = TweenService:Create(victimHrp, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.new(liftTarget)
	})
	
	liftTween:Play()
	
	-- Make chain links follow during lift
	local liftStartTime = tick()
	local liftConnection
	liftConnection = game:GetService("RunService").Heartbeat:Connect(function()
		local elapsed = tick() - liftStartTime
		local progress = math.min(elapsed / 0.3, 1)
		
		-- Move chain links with victim
		for i, link in ipairs(chainLinks) do
			if link and link.Parent then
				-- Simple follow - links will be destroyed after lift anyway
				-- This creates a stretching effect
				if i % 3 == 0 then -- Only move some links to save performance
					link.Position = link.Position + Vector3.new(0, liftHeight * progress / 2, 0)
				end
			end
		end
		
		if progress >= 1 then
			liftConnection:Disconnect()
		end
	end)
	
	liftTween.Completed:Wait()
	
	-- Clean up chain links
	for _, link in ipairs(chainLinks) do
		if link and link.Parent then
			-- Fade out and destroy
			TweenService:Create(link, TweenInfo.new(0.2), {Transparency = 1}):Play()
			Debris:AddItem(link, 0.3)
		end
	end
	
	-- Brief pause at the top
	task.wait(0.15)
	
	-- 2. SLAM TWEEN - LINEAR (constant speed)
	local slamTween = TweenService:Create(victimHrp, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(slamTarget)
	})
	
	slamTween:Play()
	slamTween.Completed:Wait()
	
	---------------------------------------------------------
	-- IMPACT VFX (Triggered EXACTLY at ground)
	---------------------------------------------------------
	local impactOrigin = groundPos
	
	print("VFX triggering at ground level:", impactOrigin)
	
	-- 1. MAIN SHOCKWAVE RING
	local ring = Instance.new("Part", workspace)
	ring.Size = Vector3.new(2, 0.5, 2)
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(180, 180, 200)
	ring.Anchored = true
	ring.CanCollide = false
	ring.Position = impactOrigin
	ring.Transparency = 0.2
	
	TweenService:Create(ring, TweenInfo.new(0.5), {
		Size = Vector3.new(20, 0.5, 20),
		Transparency = 1
	}):Play()
	Debris:AddItem(ring, 0.6)
	
	-- 2. METAL SPLASH
	for i = 1, 15 do
		local metal = Instance.new("Part", workspace)
		metal.Size = Vector3.new(math.random(3, 8)/10, math.random(3, 8)/10, math.random(3, 8)/10)
		metal.Shape = Enum.PartType.Ball
		metal.Material = Enum.Material.Metal
		metal.Color = Color3.fromRGB(180 + math.random(0, 40), 180 + math.random(0, 40), 200 + math.random(0, 40))
		metal.Anchored = false
		metal.CanCollide = false
		metal.Position = impactOrigin + Vector3.new(math.random(-20, 20)/10, 0.2, math.random(-20, 20)/10)
		
		local velocity = Instance.new("BodyVelocity", metal)
		velocity.Velocity = Vector3.new(
			math.random(-300, 300)/10,
			math.random(400, 700)/10,
			math.random(-300, 300)/10
		)
		velocity.MaxForce = Vector3.new(1000, 1000, 1000)
		
		Debris:AddItem(metal, 1.2)
	end
	
	-- 3. GROUND DEBRIS
	for i = 1, 10 do
		local debris = Instance.new("Part", workspace)
		debris.Size = Vector3.new(math.random(8, 15)/10, math.random(4, 10)/10, math.random(8, 15)/10)
		debris.Material = Enum.Material.Slate
		debris.Color = Color3.fromRGB(80 + math.random(0, 30), 80 + math.random(0, 30), 80 + math.random(0, 30))
		debris.Anchored = false
		debris.CanCollide = false
		debris.Position = impactOrigin + Vector3.new(math.random(-25, 25)/10, 0.3, math.random(-25, 25)/10)
		
		local velocity = Instance.new("BodyVelocity", debris)
		velocity.Velocity = Vector3.new(
			math.random(-250, 250)/10,
			math.random(300, 500)/10,
			math.random(-250, 250)/10
		)
		velocity.MaxForce = Vector3.new(1000, 1000, 1000)
		
		Debris:AddItem(debris, 1.2)
	end
	
	-- 4. DUST CLOUD
	local dust = Instance.new("Part", workspace)
	dust.Size = Vector3.new(4, 1, 4)
	dust.Transparency = 0.4
	dust.Material = Enum.Material.Slate
	dust.Color = Color3.fromRGB(120, 120, 120)
	dust.Anchored = true
	dust.CanCollide = false
	dust.Position = impactOrigin
	
	TweenService:Create(dust, TweenInfo.new(0.4), {
		Size = Vector3.new(14, 1, 14),
		Transparency = 1
	}):Play()
	Debris:AddItem(dust, 0.5)
	
	-- 5. SPARK RING
	local sparkRing = Instance.new("Part", workspace)
	sparkRing.Size = Vector3.new(0.5, 0.2, 0.5)
	sparkRing.Material = Enum.Material.Neon
	sparkRing.Color = Color3.fromRGB(255, 255, 255)
	sparkRing.Anchored = true
	sparkRing.CanCollide = false
	sparkRing.Position = impactOrigin + Vector3.new(0, 0.5, 0)
	
	TweenService:Create(sparkRing, TweenInfo.new(0.3), {
		Size = Vector3.new(8, 0.2, 8),
		Transparency = 1
	}):Play()
	Debris:AddItem(sparkRing, 0.4)
	
	-- Damage and Release
	if victim:FindFirstChild("Humanoid") then
		victim.Humanoid:TakeDamage(25)
	end
	
	victimHrp.Anchored = false
	tag:Destroy()
end)
