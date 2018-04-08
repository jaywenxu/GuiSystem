--LigeanceWnd.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	聂敏隆
-- 日  期:	2017.11.20
-- 版  本:	1.0
-- 描  述:	领地战窗口
-------------------------------------------------------------------

local LigeanceWnd = UIControl:new
{
	windowName      = "LigeanceWnd",
		
	m_LeftTime      = 0,   -- 战斗结束倒计时剩余时间
	m_TimerCallBack = nil, -- 战斗结束倒计时回调

}

-- 初始化
function LigeanceWnd:Attach( obj )
	
	UIControl.Attach(self,obj)
	
	obj:SetActive(false)

	local tControl = self.Controls

	tControl.m_BtnWarList.onClick:AddListener(handler(self, self.OnBtnWarList))
	tControl.m_BtnLeave.onClick:AddListener(handler(self, self.OnBtnLeave))
	
	self.OnEventWarEnd = function(nEventID, nSrctype, nSrcID, tMsg) self:ShowWarEnd() end
	rktEventEngine.SubscribeExecute(EVENT_LIGEANCE_WAR_END, 0, 0, self.OnEventWarEnd)
end

-- 销毁
function LigeanceWnd:OnDestroy()
	
	self:Hide()
	
	rktEventEngine.UnSubscribeExecute(EVENT_LIGEANCE_WAR_END, 0, 0, self.OnEventWarEnd)
	
	UIControl.OnDestroy(self)
end

-- 显示
function LigeanceWnd:Show()
	UIControl.Show(self)
	
	local tData = IGame.LigeanceEctype:GetWarInfo()
	if tData[1] then
		self.Controls.m_TextClan1.text = tData[1].strClan
		self.Controls.m_TextClan2.text = tData[2].strClan
		self.Controls.m_TextClan3.text = tData[3].strClan
	end
	local nScore = IGame.LigeanceEctype:GetScore()
	self.Controls.m_TextScore.text = nScore
	
	local nTime = IGame.LigeanceEctype:GetFightEndTime()
	self:SetCDTimer(nTime)
	
	self.Controls.m_EndBG.gameObject:SetActive(false)
end

-- 关闭
function LigeanceWnd:Hide()
	UIControl.Hide(self)
	self:StopCDTimer()
end

-- 显示结算界面
function LigeanceWnd:ShowWarEnd()

	self.Controls.m_EndBG.gameObject:SetActive(true)
	
	local tData = IGame.LigeanceEctype:GetWinInfo()
	
	self.Controls.m_TextWin1.text = tData.strClan
	self.Controls.m_TextWin2.text = tData.strLigeance
end

------------------------------------------------------------
-- 设置战斗结束倒计时
function LigeanceWnd:SetCDTimer(nTime)
	
	self:StopCDTimer()

	local nTimeCount = nTime - IGame.EntityClient:GetZoneServerTime()
	local strText = "活动结束"
	
	if nTimeCount > 1 then
		strText = GetCDTime(nTimeCount, 3, 3)

		self.m_TimerCallBack = function() self:OnTimer() end
	end
	
	self.Controls.m_TextTime.text = strText
	
	self.m_LeftTime = nTimeCount

	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "LigeanceWnd:SetCDTimer")
end

-- 定时器
function LigeanceWnd:OnTimer()
	
	self.m_LeftTime = self.m_LeftTime - 1
	if self.m_LeftTime < 1 then
		self.Controls.m_TextTime.text = "活动结束"
		self:StopCDTimer()
		return
	end

	self.Controls.m_TextTime.text = GetCDTime(self.m_LeftTime, 3, 3)
end

-- 停止倒计时
function LigeanceWnd:StopCDTimer()
	
	if self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

-- 切换战场
function LigeanceWnd:OnBtnWarList()
	IGame.Ligeance:ShowWarList()
end

-- 离开战场
function LigeanceWnd:OnBtnLeave()
	self:Hide()
	IGame.LigeanceEctype:Request_LeaveEctype()
end

return LigeanceWnd
------------------------------------------------------------

