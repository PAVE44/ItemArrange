require "TimedActions/ISInventoryTransferAction"

local transferItem = ISInventoryTransferAction.transferItem

function ISInventoryTransferAction:canDropOnFloor(square)
	if not square then
		return false
	end
	if not square:TreatAsSolidFloor() then
		return false
	end
    --[[
	if square:isSolid() or square:isSolidTrans() then
		return false
	end]]
	local current = self.character:getCurrentSquare()
	if current ~= nil and square ~= current then
		if current:isBlockedTo(square) or current:isWindowTo(square) then
			return false
		end
		if current:HasStairs() ~= square:HasStairs() then
			return false
		end
		if current:HasStairs() and not current:isSameStaircase(square:getX(), square:getY(), square:getZ()) then
			return false
		end
	end
	return true
end

function ISInventoryTransferAction:floorHasRoomFor(square, character, item, destContainer)
	local res = IA.CheckSpace(square, self.item)
    if res then
        return true
    end
    return false
end

function ISInventoryTransferAction:getNotFullFloorSquare(item)
    
    if not self.square then
        local cx = math.floor(self.character:getX())
        local cy = math.floor(self.character:getY())
        local cz = math.floor(self.character:getZ())
        local mx = getMouseX()
        local my = getMouseY()
        local tx = math.floor(screenToIsoX(0, mx, my, cz))
        local ty = math.floor(screenToIsoY(0, mx, my, cz))

        if tx > cx + 1 then tx = cx + 1 end
        if tx < cx - 1 then tx = cx - 1 end
        if ty > cy + 1 then ty = cy + 1 end
        if ty < cy - 1 then ty = cy - 1 end

        self.square = getCell():getGridSquare(tx, ty, cz)
    end

    --local square = self.character:getCurrentSquare()
    if self:canDropOnFloor(self.square) and self:floorHasRoomFor(self.square, item) then
        return self.square
    end

    return nil
end

function ISInventoryTransferAction:transferItem(item)
    -- transferItem(self, item)

    if self:isAlreadyTransferred(item) then
		return
	end
	
	if self.dontAdd then
		-- Crafting ingredient was destroyed and can't be put back into the container it came from.
		return
	end

--	print("transfering ", item)
	self.item = item;
	--self.character:ClearVariable("LootPosition");
	self.item:setJobDelta(0.0);
	if self.item:isFavorite() and not self.destContainer:isInCharacterInventory(self.character) then
--		ISBaseTimedAction.perform(self);
		return;
	end

	local square = self:getNotFullFloorSquare(item)
	self.item = ISTransferAction:transferItem(self.character, self.item, self.srcContainer, self.destContainer, square)

	-- clear it from the queue.
	self.srcContainer:setDrawDirty(true);
	self.srcContainer:setHasBeenLooted(true);
	self.destContainer:setDrawDirty(true);

	if instanceof(self.srcContainer:getParent(), "IsoDeadBody") then
		self.item:setAttachedSlot(-1);
		self.item:setAttachedSlotType(nil);
		self.item:setAttachedToModel(nil);
	end

	if instanceof(self.destContainer:getParent(), 'IsoMannequin') then
		local mannequin = self.destContainer:getParent()
		mannequin:wearItem(self.item, self.character)
	end
	
	-- Hack for giving cooking XP.
	if instanceof(self.item, "Food") then
		self.item:setChef(self.character:getFullName())
	end
	if self.destContainer:getType() == "stonefurnace" then
		self.item:setWorker(self.character:getFullName());
	end

	ISInventoryPage.renderDirty = true

	-- do the overlay sprite
    if self.srcContainer:getParent() and self.srcContainer:getParent():getOverlaySprite() then
        ItemPicker.updateOverlaySprite(self.srcContainer:getParent())
    end
    if self.destContainer:getParent() then
        ItemPicker.updateOverlaySprite(self.destContainer:getParent())
    end

    if not isServer() then
        self:playTransferCompleteSound(item)
    end


    local player = self.character
    local destination = self.destContainer
    local source = self.srcContainer
    if destination:getType() == "floor" then
        IA.ArrangeItems(square)
    end

    if source:getType() == "floor" then
        local wob = item:getWorldItem()
        if wob then
            local square = wob:getSquare()
            IA.ArrangeItems(square)
        end
    end

    
    -- triggerEvent("OnTransferItem", self, item)
end
