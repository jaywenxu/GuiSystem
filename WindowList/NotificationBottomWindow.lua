-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/03/07
-- 版  本:    1.0
-- 描  述:    公告信息窗口
-------------------------------------------------------------------

local NotificationBottomWindow = UIWindow:new
{
	windowName = "NotificationBottomWindow",
	m_TimeHander	= nil,
	m_TimerRunning	= false,
	m_NeedUpdate	= false,
	TextList        = {} ,
}


local this = NotificationBottomWindow					-- 方便书写

------------------------------------------------------------
function NotificationBottomWindow:Init()
	self.m_TimeHander = function() self:OnTimer() end
end
------------------------------------------------------------
function NotificationBottomWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	if m_NeedUpdate then
		m_NeedUpdate = false
		self:UpdateText()
	end
    return self
end

------------------------------------------------------------
function NotificationBottomWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function NotificationBottomWindow:UpdateText()
	self.Controls.m_Text.text = self.TextList[1]
	table.remove(self.TextList,1)
	local anims = self.Controls.m_Text.gameObject:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
	for i = 0 , anims.Length -1 do
		anims[i]:DORestart(false)
	end
end

------------------------------------------------------------
--定时器回调函数
function NotificationBottomWindow:OnTimer()
	if table.getn(self.TextList) == 0 then
		self.m_TimerRunning = false
		self:Hide()
		print("Kill Timer")
		rktTimer.KillTimer( self.m_TimeHander )
		return
	end
	self:Popfront()
end

------------------------------------------------------------
-- 添加新的tpis消息到列表
function NotificationBottomWindow:AddBottomTips(text)
	table.insert( self.TextList , text )
	if not self.m_TimerRunning then
		self.m_TimerRunning = true
		self:OnTimer()
		rktTimer.SetTimer(self.m_TimeHander, NotificationBottomTipsTime, -1, "NotificationBottomWindow:AddSystemTips")
	end
end

------------------------------------------------------------
-- 将最前面一条pop出来
function NotificationBottomWindow:Popfront()
	self:Show()
	if not self:isLoaded() then
		m_NeedUpdate = true
		return
	end
	if table.getn(self.TextList) <= 0 then
		return
	end
	self:UpdateText()
end

return NotificationBottomWindow







