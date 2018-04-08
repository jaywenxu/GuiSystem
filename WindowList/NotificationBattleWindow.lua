-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/03/07
-- 版  本:    1.0
-- 描  述:    战斗信息窗口
-------------------------------------------------------------------

local NotificationBattleWindow = UIWindow:new
{
	windowName = "NotificationBattleWindow",
	m_TimeHander	= nil,
	m_TimerRunning	= false,
	m_NeedUpdate	= false,
	LiveTime		= 3000,
	m_szText = "",
}


local this = NotificationBattleWindow					-- 方便书写

------------------------------------------------------------
function NotificationBattleWindow:Init()
	self.m_TimeHander = function() self:OnTimer() end
end
------------------------------------------------------------
function NotificationBattleWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._SpecialTopLayer)
	self.TweenAnim = self.Controls.m_BGImage.transform:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	--self.Controls.m_Text.color = Color.New(1,0,0,1)
	if m_NeedUpdate then
		m_NeedUpdate = false
		self:UpdateText()
	end
    return self
end

------------------------------------------------------------
function NotificationBattleWindow:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------
--窗口显示
function NotificationBattleWindow:UpdateText()
	print("窗口显示 self.m_szText",self.m_szText)
	self.Controls.m_Text.text = self.m_szText

	self.TweenAnim:DORestart(false)
	--rktTimer.KillTimer( self.m_TimeHander )
	--rktTimer.SetTimer(self.m_TimeHander, self.LiveTime, -1, "NotificationBattleWindow:AddSystemTips")
end

------------------------------------------------------------
--定时器回调函数
function NotificationBattleWindow:OnTimer()
	self:Hide()
	rktTimer.KillTimer( self.m_TimeHander )
end

------------------------------------------------------------
-- 添加新的tpis消息到列表
function NotificationBattleWindow:AddBattleTips(text)
	self.m_szText = text
	self:Show()
	self:Popfront()
	--self.Controls.m_Text.transform:DOKill(false)
end

------------------------------------------------------------
-- 将最前面一条pop出来
function NotificationBattleWindow:Popfront()
	if not self:isLoaded() then
		m_NeedUpdate = true
		return
	end
	self:Show()
	--self.Controls.m_Text.color = Color.New(1,0,0,1)
	self:UpdateText()
end

return NotificationBattleWindow







