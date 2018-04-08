
------------------------------------------------------------
--  UI窗口逻辑面板事件容器类
--  简化UI事件关联
------------------------------------------------------------
UIEventContainer = CObject:new
{
    CachedEventList = nil ,        --[ { sender , eventName , handler , receiver , callback } , { trigger , triggerType , handler , receiver , callback } ]
}
------------------------------------------------------------
function UIEventContainer:indexOf( sender , eventName , handler , receiver )
    for i , v in ipairs(self.CachedEventList) do
        if v.sender == sender and v.eventName == eventName and v.handler == handler and v.receiver == receiver then
            return i
        end
    end
    return 0
end
------------------------------------------------------------
function UIEventContainer:indexOfTrigger( trigger , triggerType , handler , receiver )
    for i , v in ipairs(self.CachedEventList) do
        if v.trigger == trigger and v.triggerType == triggerType and v.handler == handler and v.receiver == receiver then
            return i
        end
    end
    return 0
end
------------------------------------------------------------
function UIEventContainer:AddListener( sender , eventName , handler , receiver )
    local unityevent = sender[eventName]
    if nil == unityevent then
        uerror("unityevent is nil : " .. sender.name .. "." .. eventName )
        return
    end
    if nil == self.CachedEventList then
        self.CachedEventList = {}
    end
    -- 已经存在则不重复添加
    if 0 ~= self:indexOf( sender , eventName , handler , receiver ) then
        return
    end
    local item = 
    {
        sender = sender ,
        eventName = eventName ,
        handler = handler ,
        receiver = receiver ,
        callback = function(...) handler(receiver,...) end
    }
    unityevent:AddListener( item.callback )
    table.insert( self.CachedEventList , item )
end
------------------------------------------------------------
function UIEventContainer:RemoveListener( sender , eventName , handler , receiver )
    if nil == self.CachedEventList then
        return
    end
    local unityevent = sender[eventName]
    if nil == unityevent then
        return
    end
    local idx = self:indexOf( sender , eventName , handler , receiver )
    if 0 == idx then
        return
    end
    local item = self.CachedEventList[idx]
    table.remove( self.CachedEventList , idx )
    unityevent:RemoveListener( item.callback )
end
------------------------------------------------------------
function UIEventContainer:AddTriggerListener( sender , triggerType , handler , receiver )
    local trigger = sender:GetComponent(typeof(EventTrigger))
    if nil == trigger then
        return
    end
    if nil == self.CachedEventList then
        self.CachedEventList = {}
    end
    -- 已经存在则不重复添加
    if 0 ~= self.indexOfTrigger( trigger , triggerType , handler , receiver ) then
        return
    end
    local item = 
    {
        trigger = trigger ,
        triggerType = triggerType ,
        handler = handler ,
        receiver = receiver ,
        callback = function(...) handler(receiver,...) end
    }
    local entry = ToLuaX.List_Find( trigger.triggers , function(item) return item.eventID == triggerType end)
    if nil == entry then
        entry = EventTrigger.Entry.New()
        entry.eventID = triggerType
        trigger.triggers:Add(entry)
    end
    entry.callback:AddListener(item.callback)
    table.insert( self.CachedEventList , item )
end
------------------------------------------------------------
function UIEventContainer:RemoveTriggerListener( sender , triggerType , handler , receiver )
    if nil == self.CachedEventList then
        return
    end
    local trigger = sender:GetComponent(typeof(EventTrigger))
    if nil == trigger then
        return
    end
    local idx = self:indexOfTrigger( trigger , triggerType , handler , receiver )
    if 0 == idx then
        return
    end
    local item = self.CachedEventList[idx]
    table.remove( self.CachedEventList , idx )
    local entry = ToLuaX.List_Find( trigger.triggers , function(item) return item.eventID == triggerType end)
    if nil ~= entry then
        entry.callback:RemoveListener(item.callback)
    end
end
------------------------------------------------------------
function UIEventContainer:RemoveAllListeners()
    if nil == self.CachedEventList or 0 == #self.CachedEventList then
        return
    end
    for i , v in ipairs(self.CachedEventList) do
        if nil ~= v.sender then
            local unityevent = v.sender[v.eventName]
            if nil ~= unityevent then
                unityevent:RemoveListener( v.callback )
            end
        end
        if nil ~= v.trigger then
            local entry = ToLuaX.List_Find( trigger.triggers , function(item) return item.eventID == triggerType end)
            if nil ~= entry then
                entry.callback:RemoveListener(item.callback)
            end
        end
    end
    self.CachedEventList = nil
end
------------------------------------------------------------
function UIEventContainer:ClearAllListeners()
    self.CachedEventList = nil
end
------------------------------------------------------------