--FireDestroyWnd.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	聂敏隆
-- 日  期:	2017.11.30
-- 版  本:	1.0
-- 描  述:	火攻粮营窗口
-------------------------------------------------------------------

local FireDestroyWnd = UIControl:new
{
	windowName      = "FireDestroyWnd",
		
	m_LeftTime      = 0,   -- 战斗结束倒计时剩余时间
	m_TimerCallBack = nil, -- 战斗结束倒计时回调
	
	HPbarBlue = nil,
	HPbarRed = nil,
}

-- 初始化
function FireDestroyWnd:Attach( obj )
	
	UIControl.Attach(self,obj)
	
	obj:SetActive(false)

	local tControl = self.Controls

	tControl.m_BtnRank.onClick:AddListener(handler(self, self.OnBtnRank))
	self.HPbarBlue = tControl.m_BlueHP:GetComponent(typeof(Slider))
	self.HPbarRed = tControl.m_RedHP:GetComponent(typeof(Slider))
	
	self.pEventUpdateScore = function(nEventID, nSrctype, nSrcID, nScore) self:OnEventUpdateScore(nScore) end
	rktEventEngine.SubscribeExecute( EVENT_FIREDESTROY_UPDATE_SCORE, 0, 0, self.pEventUpdateScore)
end

-- 销毁
function FireDestroyWnd:OnDestroy()
	
	self:Hide()
	
	rktEventEngine.UnSubscribeExecute( EVENT_FIREDESTROY_UPDATE_SCORE, 0, 0, self.pEventUpdateScore)
	
	UIControl.OnDestroy(self)
end

-- 显示
function FireDestroyWnd:Show()
	UIControl.Show(self)
	
	local nTime = IGame.FireDestroyEctype:GetTime()
	self:SetCDTimer(nTime)
	
	local tWarInfo = IGame.FireDestroyEctype:GetWarInfo()
	if not tWarInfo then
		return
	end
	
	self.HPbarBlue.value = tWarInfo.nCampHP2/tWarInfo.nMaxHP
	self.HPbarRed.value = tWarInfo.nCampHP1/tWarInfo.nMaxHP
	self.Controls.m_TextBlueHP.text = tWarInfo.nCampHP2.."/"..tWarInfo.nMaxHP
	self.Controls.m_TextRedHP.text = tWarInfo.nCampHP1.."/"..tWarInfo.nMaxHP
	
	self.Controls.m_TextScore.text = tWarInfo.nScore
end

-- 关闭
function FireDestroyWnd:Hide()
	UIControl.Hide(self)
	self:StopCDTimer()
end

------------------------------------------------------------
-- 设置战斗结束倒计时
function FireDestroyWnd:SetCDTimer(nTime)
	
	self:StopCDTimer()

	local nTimeCount = nTime - IGame.EntityClient:GetZoneServerTime()
	local strText = "活动结束"
	
	if nTimeCount > 1 then
		strText = GetCDTime(nTimeCount, 3, 3)

		self.m_TimerCallBack = function() self:OnTimer() end
	end
	
	self.Controls.m_TextTime.text = strText
	
	self.m_LeftTime = nTimeCount

	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "FireDestroyWnd:SetCDTimer")
end

-- 定时器
function FireDestroyWnd:OnTimer()
	
	self.m_LeftTime = self.m_LeftTime - 1
	if self.m_LeftTime < 1 then
		self.Controls.m_TextTime.text = "活动结束"
		self:StopCDTimer()
		return
	end

	self.Controls.m_TextTime.text = GetCDTime(self.m_LeftTime, 3, 3)
end

-- 停止倒计时
function FireDestroyWnd:StopCDTimer()
	
	if self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

-- 显示排名
function FireDestroyWnd:OnBtnRank()
	UIManager.HGLYRankWindow:ShowWindow(self.m_LeftTime - 1)
end

-- 更新分数
function FireDestroyWnd:OnEventUpdateScore(nScore)
	self.Controls.m_TextScore.text = nScore
end

return FireDestroyWnd
------------------------------------------------------------

