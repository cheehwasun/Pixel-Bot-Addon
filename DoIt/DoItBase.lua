-- Configurable Variables
local size = 5;	-- this is the size of the "pixels" at the top of the screen that will show stuff, currently 5x5 because its easier to see and debug with
local cooldowns = {  -- These should be spellIDs for the spell you want to track for cooldowns
	642, -- Divine Shield
	633	 -- Lay on hands
}

-- Actual Addon Code below
local f = CreateFrame("frame")
f:SetSize(5 * size, size);  -- Width, Height
f:SetPoint("TOPLEFT", 0, 0)
f:RegisterEvent("ADDON_LOADED")

local hpframes = {}
local cooldownframes = {}
local healthFrames = {}

local hpPrev = 0
local lastCooldownState = {}

local function updateHP()
	local power = UnitPower("player", 9)
	
	if power ~= hpPrev then	
		print("Holy Power: " .. power)   
	   
		local i = 1

		while i <= power do
			hpframes[i].t:SetTexture(255, 0, 0, 1)
			hpframes[i].t:SetAllPoints(false)
			i = 1 + i
		end
		
		while i <= 5 do
			hpframes[i].t:SetTexture(255, 255, 255, 1)
			hpframes[i].t:SetAllPoints(false)
			i = 1 + i
		end
		
		hpPrev = power
	 end
 end

local function updateCD() 
	for _, spellId in pairs(cooldowns) do
		-- start is the value of GetTime() at the point the spell began cooling down
		-- duration is the total duration of the cooldown, NOT the remaining
		local start, duration, enable = GetSpellCooldown(spellId)
		if start and duration then -- the spell is on cooldown
			local getTime = GetTime()

			-- start + duration gives us the value of GetTime() at the point when the cd will end
			-- the time when the cd ends (a time in the future) minus the current time gives us the remaining duration on the cooldown
			local remainingCD = start + duration - getTime

			if (remainingCD > 0) then
																-- if (spellId == 642) Divine Shield is on CD
																-- BUG: when trigger global CD on ANY spell this increases to 1 second
																-- dont have a workaround for now
				if (lastCooldownState[spellId] ~= "onCD") then										 
					print("Spell with Id = " .. spellId .. " is on CD: " .. remainingCD)
					
					cooldownframes[spellId].t:SetTexture(255, 0, 0, 1)
					cooldownframes[spellId].t:SetAllPoints(false)
					
					lastCooldownState[spellId] = "onCD"
				end				
			else
				if (lastCooldownState[spellId] ~= "offCD") then
					print("Spell with Id = " .. spellId .. " is off CD and can be cast")
					
					cooldownframes[spellId].t:SetTexture(255, 255, 255, 1)
					cooldownframes[spellId].t:SetAllPoints(false)
					
					lastCooldownState[spellId] = "offCD"
				end
			end				
		end
	end
end

function healthToBinary(num)
	local bits = 7

    -- returns a table of bits
    local t={} -- will contain the bits
    for b=bits,1,-1 do
        rest=math.fmod(num,2)
        t[b]=rest
        num=(num-rest)/2
    end
	
	return table.concat(t)
end

local lastHealth = 0

local function updateHealth()
	local health = UnitHealth("player");		
	local maxHealth = UnitHealthMax("player");
	local percHealth = ceil((health / maxHealth) * 100)
	
	if (percHealth ~= lastHealth) then		
		local binaryHealth = healthToBinary(percHealth)
		print ("Health = " .. percHealth .. " binary = ".. binaryHealth)
		
		for i = 1, string.len(binaryHealth) do
			local currentBit = string.sub(binaryHealth, i, i)
			
			if (currentBit == "1") then
				healthFrames[i].t:SetTexture(255, 0, 0, 1)
			else
				healthFrames[i].t:SetTexture(255, 255, 255, 1)
			end
			healthFrames[i].t:SetAllPoints(false)
		end
		
		lastHealth = percHealth
	end
end
 
local function initFrames()
	print ("Initialising Holy Power Frames")
	for i = 1, 5 do
		hpframes[i] = CreateFrame("frame");
		hpframes[i]:SetSize(size, size)
		hpframes[i]:SetPoint("TOPLEFT", (i - 1) * size, 0)        
		hpframes[i].t = hpframes[i]:CreateTexture()        
		hpframes[i].t:SetTexture(255, 255, 255, 1)
		hpframes[i].t:SetAllPoints(hpframes[i])
		hpframes[i]:Show()
		
		hpframes[i]:SetScript("OnUpdate", updateHP)
	end
	
	print ("Initialising Cooldown Frames")
	local i = 5
	for _, spellId in pairs(cooldowns) do	
		cooldownframes[spellId] = CreateFrame("frame")
		cooldownframes[spellId]:SetSize(size, size)
		cooldownframes[spellId]:SetPoint("TOPLEFT", i * size, 0)        
		cooldownframes[spellId].t = cooldownframes[spellId]:CreateTexture()        
		cooldownframes[spellId].t:SetTexture(255, 255, 255, 1)
		cooldownframes[spellId].t:SetAllPoints(cooldownframes[spellId])
		cooldownframes[spellId]:Show()
		               
		cooldownframes[spellId]:SetScript("OnUpdate", updateCD)
		i = i + 1
	end
	
	print ("Initialising Health Frames")
	for i = 1, 7 do
		healthFrames[i] = CreateFrame("frame")
		healthFrames[i]:SetSize(size, size)
		healthFrames[i]:SetPoint("TOPLEFT", (i - 1) * size, -size)        
		healthFrames[i].t = healthFrames[i]:CreateTexture()        
		healthFrames[i].t:SetTexture(255, 255, 255, 1)
		healthFrames[i].t:SetAllPoints(healthFrames[i])
		healthFrames[i]:Show()		
		
		healthFrames[i]:SetScript("OnUpdate", updateHealth)
	end
	print ("Initialization Complete")
end

local function eventHandler(self, event, ...)
	local arg1 = ...
	if event == "ADDON_LOADED" then
		if (arg1 == "DoIt") then
			print("Addon Loaded... DoIt")
			print("Tracking " .. table.getn(cooldowns) .. " cooldowns")
			print("Health: " .. healthToBinary(100))
			initFrames()
		end
	end
end	

f:SetScript("OnEvent", eventHandler)