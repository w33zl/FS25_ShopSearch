--[[
SHORT DESCRIPTION OF WHAT YOUR MOD DOES GOES HERE

Author:     w33zl
Version:    1.0.0
Modified:   2024-12-28

Changelog:

]]

ShopSearch = Mod:init()

ShopSearch:source("lib/DevHelper.lua")

-- Event that is executed when your mod is loading (after the map has been loaded and before the game starts)
function ShopSearch:loadMap(filename)
    self.shopMenu = g_shopMenu
end

-- Event that is continuously, USE WITH CAUTION! Any demanding code here (even just a simple "print()" command) will cause poor performance, stuttering and FPS drops
function ShopSearch:update(dt)
end

-- Event that is executed when the player chooses to start the mission (after the map has been loaded and before the game starts)
function ShopSearch:startMission()
end

-- ShopController.getItemsByCategory = Utils.overwrittenFunction(ShopController.getItemsByCategory, function(self, superFunc, ...)
--     return XnhancedShopSorting:getItemsByCategory(self, superFunc, ...)
-- end)


-- ShopMenu.onOpen = Utils.overwrittenFunction(ShopMenu.onOpen, function(self, superFunc, ...)
--     Log:debug("ShopMenu.onOpen")
--     return superFunc(self, ...)
-- end)

-- ShopMenu.onClose = Utils.overwrittenFunction(ShopMenu.onClose, function(self, superFunc, ...)
--     Log:debug("ShopMenu.onClose")
--     return superFunc(self, ...)
-- end)

-- -- ShopMenu.onClickMenu = Utils.overwrittenFunction

-- ShopMenu.exitMenu = Utils.overwrittenFunction(ShopMenu.exitMenu, function(self, superFunc, ...)
--     Log:debug("ShopMenu.exitMenu")
--     return superFunc(self, ...)
-- end)

-- ShopMenu.onClickItemCategory = Utils.overwrittenFunction(ShopMenu.onClickItemCategory, function(self, superFunc, ...)
--     Log:debug("ShopMenu.onClickItemCategory")
--     return superFunc(self, ...)
-- end)

function ShopSearch:registerHotkeys()
    -- Log:debug("XnhancedShopSorting.registerHotkeys")
    local triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings = false, true, false, true, nil, true
    local success, actionEventId, otherEvents = g_inputBinding:registerActionEvent(InputAction.SEARCH_SHOP, self, self.mainKeyEvent, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)

    if success then
        Log:debug("Registered main key for XnhancedShopSorting")
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
    -- else
    --     Log:debug("Failed to register main key for XnhancedShopSorting")
    --     Log:var("state", success)
    --     Log:var("actionId", actionEventId)
    end    
    
end

function ShopSearch:mainKeyEvent()
    Log:debug("ShopSearch.mainKeyEvent")
    if g_shopMenu.isOpen then
        Log:debug("Open search...")
        --TODO: here
    end
end

function ShopSearch:getItemsByCategory(shopController, superFunc, ...)
    Log:debug("ShopController.getItemsByCategory")

    local items = superFunc(shopController, ...)

    -- for i = 1, #items do
    --     Log:debug("#%d: %s [%d]: %d", i, items[i].storeItem.name, items[i].storeItem.id, items[i].orderValue)
    -- end

    return items
end


function ShopSearch:updateDisplayItems()
    Log:debug("ShopSearch.updateDisplayItems")
    -- g_shopMenu.pageShopItemDetails:setDisplayItems(g_shopMenu.currentDisplayItems)
end

ShopItemsFrame.setDisplayItems = Utils.overwrittenFunction(ShopItemsFrame.setDisplayItems, function(self, superFunc, items, ...)
    -- Log:debug("ShopItemsFrame.setDisplayItems")
    if items and #items > 0 then 
        
    end
    return superFunc(self, items, ...)
end)

TabbedMenuWithDetails.onOpen = Utils.overwrittenFunction(TabbedMenuWithDetails.onOpen, function(self, superFunc, ...)
    -- Log:debug("TabbedMenuWithDetails.onOpen")
    
    local returnValue superFunc(self, ...)
    -- Log:var("g_shopMenu.isOpen", g_shopMenu.isOpen)
    if g_shopMenu.isOpen then
        ShopSearch:registerHotkeys()
    end
    
    return returnValue
end)

-- TabbedMenuWithDetails.onDetailOpened = Utils.overwrittenFunction(TabbedMenuWithDetails.onDetailOpened, function(self, superFunc, ...)
--     Log:debug("TabbedMenuWithDetails.onDetailOpened")
--     return superFunc(self, ...)
-- end)