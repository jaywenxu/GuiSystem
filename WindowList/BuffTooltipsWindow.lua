-- tooltips窗口
------------------------------------------------------------
local max_icon_count = 6
local BuffTooltipsWindow = UIWindow:new
{
	windowName = "BuffTooltipsWindow",
    m_needUpdate = false,
}
------------------------------------------------------------
function BuffTooltipsWindow:Init()
    self.callback_OnTimer = function() self:OnTimer() end
	self.callback_OnAddBuff = function(event, srctype, srcid, msg) self:OnAddBuff(msg) end
	self.callback_OnRemoveBuff = function(event, srctype, srcid, msg) self:OnRemoveBuff(msg) end
end
------------------------------------------------------------
function BuffTooltipsWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	UIFunction.AddEventTriggerListener(self.Controls.m_CloseButton, EventTriggerType.PointerClick, function(eventData) self:OnCloseButtonClick(eventData) end)
	
	rktEventEngine.SubscribeExecute(EVENT_CREATURE_ADDBUFF, SOURCE_TYPE_PERSON, 0, self.callback_OnAddBuff)
	rktEventEngine.SubscribeExecute(EVENT_CREATURE_REMOVEBUFF, SOURCE_TYPE_PERSON, 0, self.callback_OnRemoveBuff)
	
    if self.m_needUpdate then
        self:Update()
        self.m_needUpdate = false
    end
end
------------------------------------------------------------
function BuffTooltipsWindow:OnDestroy()
	rktTimer.KillTimer(self.callback_OnTimer)
	rktEventEngine.UnSubscribeExecute(EVENT_CREATURE_ADDBUFF, SOURCE_TYPE_PERSON, 0, self.callback_OnAddBuff)
	rktEventEngine.UnSubscribeExecute(EVENT_CREATURE_REMOVEBUFF, SOURCE_TYPE_PERSON, 0, self.callback_OnRemoveBuff)
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function BuffTooltipsWindow:OnCloseButtonClick( eventData )
	rktTimer.KillTimer(self.callback_OnTimer)
    self:Hide()
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end
------------------------------------------------------------
function BuffTooltipsWindow:OnAddBuff(msg)
    local hero = GetHero()
    if not hero then
        return false
    end
    
    if tostring(hero:GetUID()) ~= tostring(msg.uidMaster) then
        return   
    end
    
	self:OnTimer()
end
------------------------------------------------------------
function BuffTooltipsWindow:OnRemoveBuff(msg)
    local hero = GetHero()
    if not hero then
        return false
    end
    
    if tostring(hero:GetUID()) ~= tostring(msg.uidMaster) then
        return   
    end
    
	self:OnTimer()
end
------------------------------------------------------------
function BuffTooltipsWindow:UpdateBuffInfo()
	local buffPart = GetHero():GetEntityPart(ENTITYPART_ENTITY_BUFF)
	if not buffPart then
		return
	end
	
	local buffTable = buffPart:GetAllBuff()
	if not buffTable then
		return
	end
	
	local hasBuff = false
	local Controls = self.Controls
	for i = 1, max_icon_count do
        local needShow = false
		local buff = buffTable[i]
		if buff ~= nil and not buff:IsAboutToRemove() then
			local scheme = IGame.rktScheme:GetSchemeInfo(BUFF_CSV, buff:GetBuffID(), buff:GetLevel())
			if scheme and IGame.BuffClient:NeedShowIcon(scheme) then
				hasBuff = true
				if scheme.strBigIconPath ~= nil and scheme.strBigIconPath ~= "" then
					UIFunction.SetImageSprite(Controls["m_Icon"..i], AssetPath.TextureGUIPath..scheme.strBigIconPath)
                    Controls["m_Icon"..i].gameObject:SetActive(true)
				else
                    Controls["m_Icon"..i].gameObject:SetActive(false)
                end
				
				Controls["m_Name"..i].text = "<color=#fac309>".. (scheme.szDesc[1] or "") .."</color>"
				Controls["m_Desc"..i].text = scheme.szDesc[2] or ""
				Controls["m_Time"..i].text = self:GetTimeDesc(buff:GetLeftTime()) or ""
				Controls["m_Buff"..i].gameObject:SetActive(true)
                needShow = true
			end
		end
        
        if not needShow then
            Controls["m_Buff"..i].gameObject:SetActive(false)
        end
	end
	
	return hasBuff
end
------------------------------------------------------------
function BuffTooltipsWindow:Update()
    if not self:isLoaded() then
        self.m_needUpdate = true
        return
    end

	local hasBuff = self:UpdateBuffInfo()
	if hasBuff then
		rktTimer.KillTimer(self.callback_OnTimer)
		rktTimer.SetTimer(self.callback_OnTimer, 1000, -1, "BuffTooltipsWindow:Update()")
	else
		rktTimer.KillTimer(self.callback_OnTimer)
		UIManager.BuffTooltipsWindow:Hide()
	end
end
------------------------------------------------------------
function BuffTooltipsWindow:GetTimeDesc(time)
	if time == 0 then
		return "<color=#10a41b>永久</color>"
	end
	
	local seconds = math.floor(time / 1000)
	if seconds >= 0 and seconds < 60 then
		return "<color=#10a41b>"..seconds.."秒</color>"
	elseif seconds >= 60 and seconds < 3600 then
		return "<color=#10a41b>"..math.floor(seconds / 60).."分"..math.fmod(seconds, 60).."秒</color>"
	elseif seconds >= 3600 and seconds < 3600 * 24 then
		return "<color=#10a41b>"..math.floor(seconds / 3600).."小时"..math.floor(math.fmod(seconds, 3600) / 60).."分</color>"
	elseif seconds >= 3600 * 24 then
		return "<color=#10a41b>"..math.floor(seconds / 3600 / 24).."天"..math.floor(math.fmod(seconds, 3600 * 24) / 3600).."小时</color>"
	end
end
------------------------------------------------------------
function BuffTooltipsWindow:OnTimer()
	local hasBuff = self:UpdateBuffInfo()
	if not hasBuff then
		rktTimer.KillTimer(self.callback_OnTimer)
		UIManager.BuffTooltipsWindow:Hide()
	end
end
------------------------------------------------------------
return BuffTooltipsWindow
