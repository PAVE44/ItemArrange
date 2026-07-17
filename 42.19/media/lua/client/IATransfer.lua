LuaEventManager.AddEvent("OnTransferItem")

local onTransferItem = function(data, item)
    local player = data.character
    local destination = data.destContainer
    local source = data.srcContainer
    local square
    if destination:getType() == "floor" then
        square = player:getSquare()
    end

    if source:getType() == "floor" then
        square = data.square
    end

    if square then
        print ("floor transfer")
        IA.ArrangeItems(square)
    end
end

Events.OnTransferItem.Remove(onTransferItem)
Events.OnTransferItem.Add(onTransferItem)