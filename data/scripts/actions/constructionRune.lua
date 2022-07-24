local constructionRune = Action()

function constructionRune.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player:isAdmin() then
		return false
	end

	if not target then
		return false
	end
	
	local targetItem
	if target:isItem() then
		targetItem = target
	else
		local tile = Tile(target:getPosition())
		if not tile then
			return false
		end
		
		targetItem = tile:getTopDownItem() or tile:getGround()
	end
	
	if not targetItem then
		return false
	end
	
	local targetPos = targetItem:getPosition()
	local topParent = targetItem:getTopParent()
	if topParent == player then
		targetItem:moveTo(player:getPosition())
		targetPos:sendMagicEffect(CONST_ME_MAGIC_RED)
	else
		local newItem = targetItem:clone()
		if targetItem:isTeleport() then
			newItem:setDestination(targetItem:getDestination())
		elseif targetItem:isPodium() then
			newItem:setOutfit(targetItem:getOutfit())
			newItem:setFlag(PODIUM_SHOW_PLATFORM, targetItem:hasFlag(PODIUM_SHOW_PLATFORM))
			newItem:setFlag(PODIUM_SHOW_OUTFIT, targetItem:hasFlag(PODIUM_SHOW_OUTFIT))
			newItem:setFlag(PODIUM_SHOW_MOUNT, targetItem:hasFlag(PODIUM_SHOW_MOUNT))
			newItem:setDirection(targetItem:getDirection())
		end
		
		
		if targetItem:remove() then
			targetPos:sendMagicEffect(CONST_ME_MAGIC_RED)
			player:getStoreInbox():addItemEx(newItem, -1, bit.bor(FLAG_NOLIMIT, FLAG_IGNORENOTPICKUPABLE))
		else
			player:sendColorMessage("This item cannot be moved!", MESSAGE_COLOR_PURPLE)
		end
	end

	return true
end

constructionRune:id(2309)
constructionRune:register()
