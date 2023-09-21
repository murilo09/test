function Player:onBrowseField(position)
	local onBrowseField = EventCallback.onBrowseField
	if onBrowseField then
		return onBrowseField(self, position)
	end
	return true
end

function Player:onLook(thing, position, distance)
	local description = ""
	local onLook = EventCallback.onLook
	if onLook then
		description = onLook(self, thing, position, distance, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInBattleList(creature, distance)
	local description = ""
	local onLookInBattleList = EventCallback.onLookInBattleList
	if onLookInBattleList then
		description = onLookInBattleList(self, creature, distance, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInTrade(partner, item, distance)
	local description = "You see " .. item:getDescription(distance)
	local onLookInTrade = EventCallback.onLookInTrade
	if onLookInTrade then
		description = onLookInTrade(self, partner, item, distance, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInShop(itemType, count, npc)
	local description = "You see "
	local onLookInShop = EventCallback.onLookInShop
	if onLookInShop then
		description = onLookInShop(self, itemType, count, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInMarket(itemType, tier)
	local onLookInMarket = EventCallback.onLookInMarket
	if onLookInMarket then
		onLookInMarket(self, itemType)
	end
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	local onMoveItem = EventCallback.onMoveItem
	if onMoveItem then
		return onMoveItem(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
	return RETURNVALUE_NOERROR
end

function Player:onItemMoved(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	local onItemMoved = EventCallback.onItemMoved
	if onItemMoved then
		onItemMoved(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
end

function Player:onMoveCreature(creature, fromPosition, toPosition)
	local onMoveCreature = EventCallback.onMoveCreature
	if onMoveCreature then
		return onMoveCreature(self, creature, fromPosition, toPosition)
	end
	return true
end

function Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
	local onReportRuleViolation = EventCallback.onReportRuleViolation
	if onReportRuleViolation then
		onReportRuleViolation(self, targetName, reportType, reportReason, comment, translation)
	end
end

function Player:onReportBug(message, position, category)
	local onReportBug = EventCallback.onReportBug
	if onReportBug then
		return onReportBug(self, message, position, category)
	end
	return true
end

function Player:onTurn(direction)
	local onTurn = EventCallback.onTurn
	if onTurn then
		return onTurn(self, direction)
	end
	if self:getGroup():getAccess() and self:getDirection() == direction then
		local nextPosition = self:getPosition()
		nextPosition:getNextPosition(direction)

		self:teleportTo(nextPosition, true)
	end
	return true
end

function Player:onTradeRequest(target, item)
	local onTradeRequest = EventCallback.onTradeRequest
	if onTradeRequest then
		return onTradeRequest(self, target, item)
	end
	return true
end

function Player:onTradeAccept(target, item, targetItem)
	local onTradeAccept = EventCallback.onTradeAccept
	if onTradeAccept then
		return onTradeAccept(self, target, item, targetItem)
	end
	return true
end

function Player:onTradeCompleted(target, item, targetItem, isSuccess)
	local onTradeCompleted = EventCallback.onTradeCompleted
	if onTradeCompleted then
		onTradeCompleted(self, target, item, targetItem, isSuccess)
	end
end

function Player:onPodiumRequest(item)
	local podium = Podium(item.uid)
	if not podium then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return
	end
	
	self:sendEditPodium(item)
end

function Player:onPodiumEdit(item, outfit, direction, isVisible)
	local podium = Podium(item.uid)
	if not podium then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return
	end
	
	if not self:getGroup():getAccess() then
		-- check if the player is in melee range
		if getDistanceBetween(self:getPosition(), item:getPosition()) > 1 then
			self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
			return
		end
		
		-- reset outfit if unable to wear
		if not self:canWearOutfit(outfit.lookType, outfit.lookAddons) then
			outfit.lookType = 0
		end
		
		-- reset mount if unable to ride
		local mount = Game.getMountIdByLookType(outfit.lookMount)
		if not (mount and self:hasMount(mount)) then
			outfit.lookMount = 0
		end
	end

	local podiumOutfit = podium:getOutfit()
	local playerOutfit = self:getOutfit()
	
	-- use player outfit if podium is empty
	if podiumOutfit.lookType == 0 then
		podiumOutfit.lookType = playerOutfit.lookType
		podiumOutfit.lookHead = playerOutfit.lookHead
		podiumOutfit.lookBody = playerOutfit.lookBody
		podiumOutfit.lookLegs = playerOutfit.lookLegs
		podiumOutfit.lookFeet = playerOutfit.lookFeet
		podiumOutfit.lookAddons = playerOutfit.lookAddons
	end

	-- set player mount colors podium is empty	
	if podiumOutfit.lookMount == 0 then
		podiumOutfit.lookMount = playerOutfit.lookMount
		podiumOutfit.lookMountHead = playerOutfit.lookMountHead
		podiumOutfit.lookMountBody = playerOutfit.lookMountBody
		podiumOutfit.lookMountLegs = playerOutfit.lookMountLegs
		podiumOutfit.lookMountFeet = playerOutfit.lookMountFeet
	end
	
	-- "outfit" box checked
	if outfit.lookType ~= 0 then
		podiumOutfit.lookType = outfit.lookType
		podiumOutfit.lookHead = outfit.lookHead
		podiumOutfit.lookBody = outfit.lookBody
		podiumOutfit.lookLegs = outfit.lookLegs
		podiumOutfit.lookFeet = outfit.lookFeet
		podiumOutfit.lookAddons = outfit.lookAddons
	end

	-- "mount" box checked
	if outfit.lookMount ~= 0 then
		podiumOutfit.lookMount = outfit.lookMount
		podiumOutfit.lookMountHead = outfit.lookMountHead
		podiumOutfit.lookMountBody = outfit.lookMountBody
		podiumOutfit.lookMountLegs = outfit.lookMountLegs
		podiumOutfit.lookMountFeet = outfit.lookMountFeet
	end

	-- prevent invisible podium state
	if outfit.lookType == 0 and outfit.lookMount == 0 then
		isVisible = true
	end

	-- save player choices
	podium:setFlag(PODIUM_SHOW_PLATFORM, isVisible)
	podium:setFlag(PODIUM_SHOW_OUTFIT, outfit.lookType ~= 0)
	podium:setFlag(PODIUM_SHOW_MOUNT, outfit.lookMount ~= 0)
	podium:setDirection(direction < DIRECTION_NORTHEAST and direction or DIRECTION_SOUTH)
	podium:setOutfit(podiumOutfit)
end

local soulCondition = Condition(CONDITION_SOUL, CONDITIONID_DEFAULT)
soulCondition:setTicks(4 * 60 * 1000)
soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)

local function getSpentStaminaMinutes(player)
	local playerId = player:getId()
	if not nextUseStaminaTime[playerId] then
		nextUseStaminaTime[playerId] = 0
	end

	local currentTime = os.time()
	local timePassed = currentTime - nextUseStaminaTime[playerId]
	if timePassed <= 0 then
		return 0
	end
	
	return timePassed > 60 and 2 or 1
end

function useStamina(player)
	local staminaMinutes = player:getStamina()
	if staminaMinutes == 0 then
		local onUseStamina = EventCallback.onUseStamina
		if onUseStamina then
			local spentMinutes = getSpentStaminaMinutes(player)
			if spentMinutes > 0 then
				staminaMinutes = onUseStamina(player, staminaMinutes, spentMinutes)
				player:setStamina(staminaMinutes)
			end
		end
		return
	end

	local spentMinutes = getSpentStaminaMinutes(player)
	if spentMinutes == 0 then
		return
	elseif spentMinutes > 1 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseStaminaTime[player:getId()] = os.time() + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseStaminaTime[player:getId()] = os.time() + 60
	end

	local onUseStamina = EventCallback.onUseStamina
	if onUseStamina then
		staminaMinutes = onUseStamina(player, staminaMinutes, spentMinutes)
	end

	player:setStamina(staminaMinutes)
end

function Player:onGainExperience(source, exp, rawExp)
	if not source or source:isPlayer() then
		return exp
	end

	-- Soul regeneration
	local vocation = self:getVocation()
	if self:getSoul() < vocation:getMaxSoul() and exp >= self:getLevel() then
		soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks() * 1000)
		self:addCondition(soulCondition)
	end

	-- Apply experience stage multiplier
	exp = exp * Game.getExperienceStage(self:getLevel())

	-- Stamina modifier
	if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		useStamina(self)

		local staminaMinutes = self:getStamina()
		if staminaMinutes > 2340 and self:isPremium() then
			exp = exp * 1.5
		elseif staminaMinutes <= 840 then
			exp = exp * 0.5
		end
	end

	local onGainExperience = EventCallback.onGainExperience
	return onGainExperience and EventCallback.onGainExperience(self, source, exp, rawExp) or exp
end

function Player:onLoseExperience(exp)
	local onLoseExperience = EventCallback.onLoseExperience
	return onLoseExperience and onLoseExperience(self, exp) or exp
end

function Player:onGainSkillTries(skill, tries)
	local onGainSkillTries = EventCallback.onGainSkillTries
	if APPLY_SKILL_MULTIPLIER == false then
		return EventCallback.onGainSkillTries and EventCallback.onGainSkillTries(self, skill, tries) or tries
	end

	if skill == SKILL_MAGLEVEL then
		tries = tries * configManager.getNumber(configKeys.RATE_MAGIC)
		return EventCallback.onGainSkillTries and EventCallback.onGainSkillTries(self, skill, tries) or tries
	end
	tries = tries * configManager.getNumber(configKeys.RATE_SKILL)
	return onGainSkillTries and onGainSkillTries(self, skill, tries) or tries
end

function Player:onWrapItem(item)
	local onWrapItem = EventCallback.onWrapItem
	if onWrapItem then
		onWrapItem(self, item)
	end
end

function Player:onQuickLoot(position, stackPos, spriteId)
	if EventCallback.onQuickLoot then
		EventCallback.onQuickLoot(self, position, stackPos, spriteId)
	end
end

function Player:onInventoryUpdate(item, slot, equip)
	local onInventoryUpdate = EventCallback.onInventoryUpdate
	if onInventoryUpdate then
		onInventoryUpdate(self, item, slot, equip)
	end
end

-- begin inspection feature
function Player:onInspectItem(item)
	local onInspectItem = EventCallback.onInspectItem
	if onInspectItem then
		onInspectItem(self, item)
	end
end

function Player:onInspectTradeItem(tradePartner, item)
	local onInspectTradeItem = EventCallback.onInspectTradeItem
	if onInspectTradeItem then
		onInspectTradeItem(self, tradePartner, item)
	end
end

function Player:onInspectNpcTradeItem(npc, itemId)
	local onInspectNpcTradeItem = EventCallback.onInspectNpcTradeItem
	if onInspectNpcTradeItem then
		onInspectNpcTradeItem(self, npc, itemId)
	end
end

function Player:onInspectCyclopediaItem(itemId)
	local onInspectCyclopediaItem = EventCallback.onInspectCyclopediaItem
	if onInspectCyclopediaItem then
		onInspectCyclopediaItem(self, itemId)
	end
end
-- end inspection feature

function Player:onMinimapQuery(position)
	local onMinimapQuery = EventCallback.onMinimapQuery
	if onMinimapQuery then
		onMinimapQuery(self, position)
	end
	
	-- teleport action for server staff
	-- ctrl + shift + click on minimap
	if not self:getGroup():getAccess() then
		return
	end
	
	local tile = Tile(position)
	if not tile then
		Game.createTile(position)
	end
	
	self:teleportTo(position)
end

function Player:onGuildMotdEdit(message)
	return message
end

function Player:onSetLootList(lootList, mode)
	local onSetLootList = EventCallback.onSetLootList
	if onSetLootList then
		onSetLootList(self, lootList, mode)
	end
end

function Player:onManageLootContainer(item, mode, lootType)
	local onManageLootContainer  = EventCallback.onManageLootContainer 
	if onManageLootContainer then
		onManageLootContainer(self, item, mode, lootType)
	end
end

function Player:onFuseItems(fromItemType, fromTier, toItemType, successCore, tierLossCore)
	local onFuseItems = EventCallback.onFuseItems
	if onFuseItems then
		onFuseItems(self, fromItemType, fromTier, toItemType, successCore, tierLossCore)
	end
end

function Player:onTransferTier(fromItemType, fromTier, toItemType)
	local onTransferTier = EventCallback.onTransferTier
	if onTransferTier then
		onTransferTier(self, fromItemType, fromTier, toItemType)
	end
end

function Player:onForgeConversion(conversionType)
	local onForgeConversion = EventCallback.onForgeConversion
	if onForgeConversion then
		onForgeConversion(self, conversionType)
	end
end

function Player:onForgeHistoryBrowse(page)
	local onForgeHistoryBrowse = EventCallback.onForgeHistoryBrowse
	if onForgeHistoryBrowse then
		onForgeHistoryBrowse(self, page)
	end
end

function Player:onRequestPlayerTab(target, infoType, currentPage, entriesPerPage)
	local onRequestPlayerTab = EventCallback.onRequestPlayerTab
	if onRequestPlayerTab then
		onRequestPlayerTab(self, target, infoType, currentPage, entriesPerPage)
	end
end

function Player:onBestiaryInit()
	local onBestiaryInit = EventCallback.onBestiaryInit
	if onBestiaryInit then
		onBestiaryInit(self)
	end
end

function Player:onBestiaryBrowse(category, raceList)
	local onBestiaryBrowse = EventCallback.onBestiaryBrowse
	if onBestiaryBrowse then
		onBestiaryBrowse(self, category, raceList)
	end
end

function Player:onBestiaryRaceView(raceId)
	local onBestiaryRaceView = EventCallback.onBestiaryRaceView
	if onBestiaryRaceView then
		onBestiaryRaceView(self, raceId)
	end
end

function Player:onFrameView(targetId)
	local player = Player(targetId)
	if player and player:isAdmin() then
		return 3
	end
	
	return 255
end

-- begin onConnect
local function sendForgeTypesAsync(cid)
	local p = Player(cid)
	if p and not p:isRemoved() then
		p:sendItemClasses()
	end
end

local function sendColorTypesAsync(cid)
	local p = Player(cid)
	if p and not p:isRemoved() then
		p:sendMessageColorTypes()
	end
end

function Player:onConnect(isLogin)
	-- schedule sending less important data
	local cid = self:getId()
	addEvent(sendForgeTypesAsync, 100, cid) -- classification info for market and forge
	addEvent(sendColorTypesAsync, 200, cid) -- message colors meta

	local onConnect = EventCallback.onConnect
	if onConnect then
		onConnect(self, isLogin)
	end
end
-- end onConnect

-- begin extended protocol
packetEvents = {}
function getPacketEvent(recvbyte)
	return packetEvents[recvbyte]
end

function setPacketEvent(recvbyte, callback)
	if tonumber(recvbyte) then
		packetEvents[tonumber(recvbyte)] = callback
		return true
	end
	
	return false
end

function callPacketEvent(player, recvbyte, networkMessage)
	if packetEvents[recvbyte] then
		return packetEvents[recvbyte](player, recvbyte, networkMessage)
	end
	
	return false
end

function Player:onExtendedProtocol(recvbyte, networkMessage)
	-- unhnadled login packets:
	-- 0xCE -- allow everyone to inspect me(?)
	-- 0xD0 -- quest tracker
	callPacketEvent(self, recvbyte, networkMessage)
end
-- end extended protocol
