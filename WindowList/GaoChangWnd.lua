--GaoChangWnd.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	聂敏隆
-- 日  期:	2017.11.22
-- 版  本:	1.0
-- 描  述:	高昌秘道窗口
-------------------------------------------------------------------

local GaoChangWnd = UIControl:new
{
	windowName      = "GaoChangWnd",
		
	m_LeftTime      = 0,   -- 战斗结束倒计时剩余时间
	m_TimerCallBack = nil, -- 战斗结束倒计时回调

}

-- 初始化
function GaoChangWnd:Attach( obj )
	
	UIControl.Attach(self,obj)
	
	obj:SetActive(false)

	local tControl = self.Controls

	tControl.m_BtnRule.onClick:AddListener(handler(self, self.OnBtnRule))
	tControl.m_BtnRuleBG.onClick:AddListener(handler(self, self.OnBtnRuleBG))
end

-- 销毁
function GaoChangWnd:OnDestroy()
	
	self:Hide()
	
	UIControl.OnDestroy(self)
end

-- 显示
function GaoChangWnd:Show()
	UIControl.Show(self)
	
	local nTime,nKeyNum,nKeyGold = IGame.GaoChangEctype:GetFightInfo()
	
	self.Controls.m_TextKeyNumN.text = nKeyNum
	self.Controls.m_TextKeyNumG.text = nKeyGold
	
	self:SetCDTimer(nTime)
	
	self.Controls.m_BtnRuleBG.gameObject:SetActive(false)
end

-- 关闭
function GaoChangWnd:Hide()
	UIControl.Hide(self)
	self:StopCDTimer()
end

------------------------------------------------------------
-- 设置战斗结束倒计时
function GaoChangWnd:SetCDTimer(nTime)
	
	self:StopCDTimer()

	local nTimeCount = nTime - IGame.EntityClient:GetZoneServerTime()
	local strText = "活动结束"
	
	if nTimeCount > 1 then
		strText = GetCDTime(nTimeCount, 3, 3)

		self.m_TimerCallBack = function() self:OnTimer() end
	end
	
	self.Controls.m_TextTime.text = strText
	
	self.m_LeftTime = nTimeCount

	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "GaoChangWnd:SetCDTimer")
end

-- 定时器
function GaoChangWnd:OnTimer()
	
	self.m_LeftTime = self.m_LeftTime - 1
	if self.m_LeftTime < 1 then
		self.Controls.m_TextTime.text = "活动结束"
		self:StopCDTimer()
		return
	end

	self.Controls.m_TextTime.text = GetCDTime(self.m_LeftTime, 3, 3)
end

-- 停止倒计时
function GaoChangWnd:StopCDTimer()
	
	if self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

-- 显示规则
function GaoChangWnd:OnBtnRule()
	self.Controls.m_BtnRuleBG.gameObject:SetActive(true)
end

-- 显示规则
function GaoChangWnd:OnBtnRuleBG()
	self.Controls.m_BtnRuleBG.gameObject:SetActive(false)
end

return GaoChangWnd
------------------------------------------------------------

