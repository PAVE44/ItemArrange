require "TimedActions/ISBaseTimedAction"

IAArrangeAction = ISBaseTimedAction:derive("IAArrangeAction")

local CLIENT_DELAY_FOR_MULTI_TRANSACTION = 10
-- keep only one instance of this action so we can queue item to transfer and avoid ton of instance when moving lot of items.

function IAArrangeAction:isValid()
    if not self.item then
        return false
    end
    if not self.dropSquare or not self.srcContainer then
        return false
    end
    if not IA.CheckSpace(self.dropSquare, self.item) then
        return false
    end

    return true
end

function IAArrangeAction:update()

    self.item:setJobDelta(self.action:getJobDelta())

    self.character:setMetabolicTarget(Metabolics.LightWork)

end

function IAArrangeAction:waitToStart()
    if not isClient() then
        return false
    else
        local timePassed = getTimestampMs() - self.startTime
        return timePassed < CLIENT_DELAY_FOR_MULTI_TRANSACTION
    end
end

function IAArrangeAction:start()
    self:setActionAnim("Loot")
end

function IAArrangeAction:stop()
    self.item:setJobDelta(0.0)
    if self.action then
        self.action:setLoopedAction(false)
    end
    ISBaseTimedAction.stop(self)
end

function IAArrangeAction:perform()

    if isServer() then
        return
    end

    self.item:setJobDelta(0.0)

    if isClient() then
        sendClientCommand(self.character, 'Commands', 'DropItem', {item = self.item, x = self.dropSquare:getX(), y = self.dropSquare:getY(), z = self.dropSquare:getZ()})
    else
        self.dropSquare:AddWorldInventoryItem(self.item, self.dropSquare:getX(), self.dropSquare:getY(), self.dropSquare:getZ())
		IA.ArrangeItems(self.dropSquare)
    end
    self.srcContainer:Remove(self.item)
    sendRemoveItemFromContainer(self.srcContainer, self.item)
    
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)

    ISInventoryPage.renderDirty = true
end

function IAArrangeAction:getTimeDelta()
    return 0
end

function IAArrangeAction:new (character, item, srcContainer, dropSquare, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.srcContainer = srcContainer
    o.dropSquare = dropSquare
    o.startTime = getTimestampMs()
    o.maxTime = 0
    if time then
        o.maxTime = time
    else
        o.maxTime = 120
        local w = item:getActualWeight()
        if w > 3 then 
            w = 3
        end
        o.maxTime = o.maxTime * (w)

        if o.srcContainer == o.character:getInventory() then
            o.maxTime = o.maxTime * 0.1
        elseif o.srcContainer:isInCharacterInventory(o.character) then
            -- Unpack -> drop
        else
            o.maxTime = o.maxTime * 0.2
        end

        if character:hasTrait(CharacterTrait.DEXTROUS) then
            o.maxTime = o.maxTime * 0.5
        end
        if character:hasTrait(CharacterTrait.ALL_THUMBS) or character:isWearingAwkwardGloves() then
            o.maxTime = o.maxTime * 2.0
        end
    end
    if character:isTimedActionInstant() then
        o.maxTime = 1
    end

    return o
end


