local showAtkWeaponTypes = {WEAPON_FIST, WEAPON_CLUB, WEAPON_SWORD, WEAPON_AXE, WEAPON_DISTANCE}
local showDefWeaponTypes = {WEAPON_FIST, WEAPON_CLUB, WEAPON_SWORD, WEAPON_AXE, WEAPON_DISTANCE, WEAPON_SHIELD}

local ec = EventCallback

ec.onLookInMarket = function(self, itemType, tier)
	local response = NetworkMessage()
	response:addByte(0xF8)
	response:addU16(itemType:getClientId())
	
	-- tier label (byte)
	do
		if itemType:getClassification() > 0 then
			response:addByte(tier)
		end
	end
	
	-- armor
	do
		local armor = itemType:getArmor()
		if armor > 0 then
			response:addString(armor)
		else
			response:addU16(0)
		end
	end
	
	-- weapon data (will be reused)
	local weaponType = itemType:getWeaponType()
	
	-- attack
	do
		local showAtk = table.contains(showAtkWeaponTypes, weaponType)
		if showAtk then
			local atkAttrs = {}	
			local atk = itemType:getAttack()
			if itemType:isBow() then
				if atk ~= 0 then
					atkAttrs[#atkAttrs + 1] = string.format("%+d", atk)
				end
				
				local hitChance = itemType:getHitChance()
				if hitChance ~= 0 then
					atkAttrs[#atkAttrs + 1] = string.format("chance to hit %+d%%", hitChance)
				end
				
				atkAttrs[#atkAttrs + 1] = string.format("%d fields", itemType:getShootRange())
			else
				atkAttrs[#atkAttrs + 1] = atk
				local elementDmg = itemType:getElementDamage()
				if elementDmg ~= 0 then
					atkAttrs[#atkAttrs] = string.format("%d physical %+d %s", atkAttrs[#atkAttrs], elementDmg, getCombatName(itemType:getElementType()))
				end
			end
			
			response:addString(table.concat(atkAttrs, ", "))
		else
			response:addU16(0)
		end
	end
	
	-- container slots
	do
		if itemType:isContainer() then
			response:addString(itemType:getCapacity())
		else
			response:addU16(0)
		end
	end
	
	-- defense
	do
		local showDef = table.contains(showDefWeaponTypes, weaponType)
		if showDef then
			local def = itemType:getDefense()
			if weaponType == WEAPON_DISTANCE then
				-- throwables
				if ammoType ~= AMMO_ARROW and ammoType ~= AMMO_BOLT then
					response:addString(def)
				else
					response:addU16(0)
				end
			else
				-- extra def
				local xD = itemType:getExtraDefense()
				if xD ~= 0 then
					def = string.format("%d %+d", def, xD)
				end
				
				response:addString(def)
			end
		else
			response:addU16(0)
		end
	end
	
	-- description
	do
		local desc = itemType:getDescription()
		if desc and #desc > 0 then
			response:addString(desc:sub(1, -2))
		else
			response:addU16(0)
		end
	end
	
	-- duration
	do
		local duration = itemType:getDuration()
		if duration == 0 then
			local transferType = itemType:getTransformEquipId()
			
			-- magic light wand (exception)
			if itemType:getId() == 2162 then
				transferType = 2163
			end
				
			if transferType ~= 0 then
				transferType = ItemType(transferType)
				duration = transferType and transferType:getDuration() or duration
			end
		end
		
		if duration > 0 then
			response:addString(Game.getCountdownString(duration, true, true))
		else
			response:addU16(0)	
		end
	end
	
	-- item abilities (will be reused)
	local abilities = itemType:getAbilities()
	
	-- element protections	
	do
		local protections = {}
		for element, value in pairs(abilities.absorbPercent) do
			if value ~= 0 then
				protections[#protections + 1] = string.format("%s %+d%%", getCombatName(2^(element-1)), value)
			end
		end
		
		if #protections > 0 then
			response:addString(table.concat(protections, ", "))
		else
			response:addU16(0)
		end
	end
	
	-- level req
	do
		local minLevel = itemType:getMinReqLevel()
		if minLevel > 0 then
			response:addString(minLevel)
		else
			response:addU16(0)
		end
	end
	
	-- magic level req
	do
		local minMagicLevel = itemType:getMinReqMagicLevel()
		if minMagicLevel > 0 then
			response:addString(minMagicLevel)
		else
			response:addU16(0)
		end
	end
	
	-- vocation
	do
		local vocations = itemType:getVocationString()
		if vocations and vocations:len() > 0 then
			response:addString(vocations)
		else
			response:addU16(0)
		end
	end
	
	-- rune words
	do
		local spellName = itemType:getRuneSpellName()
		if spellName and spellName:len() > 0 then
			response:addString(spellName)
		else
			response:addU16(0)
		end
	end
	
	-- "skill boost" category
	do
		-- atk speed
		local atkSpeed = itemType:getAttackSpeed()
		if atkSpeed ~= 0 then
			skillBoosts[#skillBoosts + 1] = string.format("attack speed %0.2f/turn", 2000 / atkSpeed)
		end
	
		-- skill boost
		local skillBoosts = {}
		if abilities.manaGain > 0 or abilities.healthGain > 0 or abilities.regeneration then
			skillBoosts[#skillBoosts + 1] = "faster regeneration"
		end		
		
		-- invisibility
		if abilities.invisible then
			skillBoosts[#skillBoosts + 1] = "invisibility"
		end
		
		-- magic shield (classic)
		if abilities.manaShield then
			skillBoosts[#skillBoosts + 1] = "magic shield"
		end
		
		-- stats (hp/mp/soul/ml)
		for stat, value in pairs(abilities.stats) do
			if value ~= 0 then
				if stat ~= STAT_CAPACITY+1 then
					skillBoosts[#skillBoosts + 1] = string.format("%s %+d", getStatName(stat-1), value)
				else
					skillBoosts[#skillBoosts + 1] = string.format("%s %+d", getStatName(stat-1), value/100)			
				end
			end
		end
		
		-- stats but in %
		for stat, value in pairs(abilities.statsPercent) do
			if value ~= 0 then
				skillBoosts[#skillBoosts + 1] = string.format("%s %+d%%", getStatName(stat-1), value - 100)
			end
		end
			
		-- speed
		if abilities.speed ~= 0 then
			skillBoosts[#skillBoosts + 1] = string.format("speed %+d", math.floor(abilities.speed / 2))
		end
		
		-- skills
		for skill, value in pairs(abilities.skills) do
			if value ~= 0 then
				skillBoosts[#skillBoosts + 1] = string.format("%s %+d", getSkillName(skill-1), value)
			end
		end
		
		-- element magic level
		for element, value in pairs(abilities.specialMagicLevel) do
			if value ~= 0 then
				skillBoosts[#skillBoosts + 1] = string.format("%s magic level %+d", getCombatName(2^(element-1)), value)
			end
		end
	
		-- special skills
		for skill, value in pairs(abilities.specialSkills) do
			if value ~= 0 then
				-- add + symbol to special skill "amount" fields
				if skill-1 < 6 and skill % 2 == 1 then
					value = string.format("%+d", value)
				elseif skill-1 >= 6 then
					-- fatal, dodge, momentum coming from the item natively
					-- (stats coming from tier are near tier info)
					value = string.format("%0.2f", value/100)
				end
				
				skillBoosts[#skillBoosts + 1] = string.format("%s %s%%", getSpecialSkillName(skill-1), value)
			end
		end
		
		-- damage boost
		local damageBoosts = {}
		local allElements = true
		
		local identicalAmount = true
		local currentAmount = -1
		
		for combatType, value in pairs(abilities.boostPercent) do
			if value ~= 0 then
				damageBoosts[#damageBoosts + 1] = {element = getCombatName(2^(combatType-1)), value = value}
				
				if currentAmount == -1 then
					currentAmount = value
				elseif currentAmount ~= value then
					identicalAmount = false
				end
			else
				allElements = false
			end
		end
		

		if #damageBoosts > 0 then
			if allElements and identicalAmount then
				-- all elements upped by same amount
				-- display single value
				skillBoosts[#skillBoosts + 1] = string.format("damage and healing %+d%%", damageBoosts[1].value)
			else
				-- incomplete elements list or all elements but different chances
				-- display full info
				local boostValues = {}
				for i = 1, #damageBoosts do
					boostValues[#boostValues + 1] = string.format("%s %+d%%", damageBoosts[i].element, damageBoosts[i].value)
				end
				
				skillBoosts[#skillBoosts + 1] = string.format("damage %s", table.concat(boostValues, ", "))
			end
		end
		
		-- add to response
		if #skillBoosts > 0 then
			response:addString(table.concat(skillBoosts, ", "))
		else
			response:addU16(0)
		end
	end
	
	-- charges
	do
		if itemType:hasShowCharges() then
			response:addString(itemType:getCharges())
		else
			response:addU16(0)
		end
	end
	
	-- weapon type
	do
		if itemType:isWeapon() then
			response:addString(itemType:getWeaponString())
		else
			response:addU16(0)
		end
	end
	
	-- weight
	response:addString(string.format("%0.2f", itemType:getWeight()/100))

	response:addU16(0) -- Augment
	
	-- Imbuement Slots
	if ImbuingSystem then
		response:addString(itemType:getSocketCount())
	else
		response:addU16(0)
	end
		
	-- to do
	response:addU16(0) -- Magic Shield Capacity
	response:addU16(0) -- Cleave
	
	-- damage reflection
	do
		local reflects = {}
		
		local allElements = true
		
		local identicalChance = true
		local currentChance = -1
		
		for combatId, chance in pairs(abilities.reflectChance) do
			local amount = abilities.reflectPercent[combatId]
			if chance > 0 and amount > 0 then
				reflects[#reflects + 1] = {element = getCombatName(2^(combatId-1)), amount = amount, chance = chance}
				
				if currentChance == -1 then
					currentChance = chance
				elseif currentChance ~= chance then
					identicalChance = false
				end
			else
				allElements = false
			end
		end
		
		if #reflects > 0 then
			local reflectResponse = ""
			if allElements and identicalChance then
				-- chance and amount are identical
				-- display single values for chance and amount
				local chanceInfo = reflects[1].chance ~= 100 and string.format(" (%d%% chance)", reflects[1].chance) or ""
				reflectResponse = string.format("%+d%%%s", reflects[1].amount, chanceInfo)
				
			elseif identicalChance then
				-- incomplete elements list (chances still identical)
				-- display single value for chance only
				local reflectValues = {}
				for i = 1, #reflects do
					reflectValues[#reflectValues + 1] = string.format("%s %+d%%", reflects[i].element, reflects[i].amount)
				end
				
				local chanceInfo = reflects[1].chance ~= 100 and string.format(" (%d%% chance)", reflects[1].chance) or ""
				reflectResponse = string.format("%s%s", table.concat(reflectValues, ", "), chanceInfo)
			else
				-- chances or amounts are different
				-- display full info
				local reflectValues = {}
				for i = 1, #reflects do
					reflectValues[#reflectValues + 1] = string.format("%s %+d%% (%d%% chance)", reflects[i].element, reflects[i].amount, reflects[i].chance)
				end
				
				reflectResponse = table.concat(reflectValues, ", ")
			end
			
			-- display reflect stats
			response:addString(reflectResponse)
		else
			-- no stats to display
			response:addU16(0)
		end
	end
	
	-- to do
	response:addU16(0) -- Perfect Shot

	-- classification
	do
		local classification = itemType:getClassification()
		if classification > 0 then
			response:addString(classification)
		else
			response:addU16(0)
		end
	end

	-- tier info: "tier (0.01% bonusName)"
	if tier > 0 then
		local tierString = tier
		local bonusType, bonusValue = itemType:getTierBonus(tier)
		if bonusType ~= -1 then
			if bonusType > 5 then
				tierString = string.format("%d (%0.2f%% %s)", tier, bonusValue, getSpecialSkillName(bonusType))
			else
				tierString = string.format("%d (%d%% %s)", tier, bonusValue, getSpecialSkillName(bonusType))
			end
		end
		
		response:addString(tierString)
	else
		response:addU16(0)
	end

	-- buy stats
	do
		local stats = itemType:getMarketBuyStatistics(tier)
		if stats then
			response:addByte(0x01)
			response:addU32(stats.numTransactions)
			response:addU64(stats.totalPrice)
			response:addU64(stats.highestPrice)
			response:addU64(stats.lowestPrice)
		else
			response:addByte(0x00)
		end
	end

	-- sell stats
	do
		local stats = itemType:getMarketSellStatistics(tier)
		if stats then
			response:addByte(0x01)
			response:addU32(stats.numTransactions)
			response:addU64(stats.totalPrice)
			response:addU64(stats.highestPrice)
			response:addU64(stats.lowestPrice)
		else
			response:addByte(0x00)
		end
	end

	response:sendToPlayer(self)
end

ec:register()
