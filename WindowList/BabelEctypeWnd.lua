--BabelEctypeWnd.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	聂敏隆
-- 日  期:	2017.12.8
-- 版  本:	1.0
-- 描  述:	通天塔副本窗口
-------------------------------------------------------------------

local BabelEctypeWnd = UIControl:new
{
	windowName      = "BabelEctypeWnd",
		
	m_LeftTime      = 0,   -- 战斗结束倒计时剩余时间
	m_TimerCallBack = nil, -- 战斗结束倒计时回调

}

-- 初始化
function BabelEctypeWnd:Attach( obj )
	
	UIControl.Attach(self,obj)
	
	obj:SetActive(false)
end

-- 销毁
function BabelEctypeWnd:OnDestroy()
	
	self:Hide()
	
	UIControl.OnDestroy(self)
end

-- 显示
function BabelEctypeWnd:Show()
	UIControl.Show(self)
	
	local tMsg = IGame.BabelEctype:GetBaseInfo()
	if not tMsg then
		return
	end
	
	self.Controls.m_TextFloor.text = tMsg[1]
	self.Controls.m_TextTarget.text = tMsg[2]
	
	local nTime = IGame.BabelEctype:GetTimeEnd() - IGame.EntityClient:GetZoneServerTime()

	local tData = {timer_interval = nTime, strFunLeave = "RequestBabelServer_Leave()"}
	
	ZC_TimerAndAssistInit(tData)
end

-- 关闭
function BabelEctypeWnd:Hide()
	UIControl.Hide(self)

	UIManager.EctypeTimerWindow:hideWindow()
end

-- 设置战斗结束倒计时
function BabelEctypeWnd:SetCDTimer(nTime)
	
	self:StopCDTimer()

	local nTimeCount = nTime - IGame.EntityClient:GetZoneServerTime()
	local strText = "活动结束"
	
	if nTimeCount > 1 then
		strText = GetCDTime(nTimeCount, 3, 3)

		self.m_TimerCallBack = function() self:OnTimer() end
	end
	
	self.Controls.m_TextTime.text = strText
	
	self.m_LeftTime = nTimeCount

	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "BabelEctypeWnd:SetCDTimer")
end

-- 定时器
function BabelEctypeWnd:OnTimer()
	
	self.m_LeftTime = self.m_LeftTime - 1
	if self.m_LeftTime < 1 then
		self.Controls.m_TextTime.text = "活动结束"
		self:StopCDTimer()
		return
	end

	self.Controls.m_TextTime.text = GetCDTime(self.m_LeftTime, 3, 3)
end

-- 停止倒计时
function BabelEctypeWnd:StopCDTimer()
	
	if self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

return BabelEctypeWnd
------------------------------------------------------------

