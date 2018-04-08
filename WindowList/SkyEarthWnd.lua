--SkyEarthWnd.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	聂敏隆
-- 日  期:	2017.11.23
-- 版  本:	1.0
-- 描  述:	天地劫窗口
-------------------------------------------------------------------

local SkyEarthWnd = UIControl:new
{
	windowName      = "SkyEarthWnd",
	
	pEventUpdate = nil,
		
	m_LeftTime      = 0,   -- 战斗结束倒计时剩余时间
	m_TimerCallBack = nil, -- 战斗结束倒计时回调
	
	nShowFloor = 1,		-- 当前显示的层数
	tTextTime = 
	{
		[1] = {"距离二层开启：","二层已开启"},
		[2] = {"距离三层开启：","三层已开启"},
	}
}

-- 初始化
function SkyEarthWnd:Attach( obj )
	
	UIControl.Attach(self,obj)
	
	obj:SetActive(false)
	
	self.pEventUpdate = function(nEventID, nSrctype, nSrcID, tMsg) self:OnEventUpdate() end
	rktEventEngine.SubscribeExecute(EVENT_SKYEARTH_UPDATE, 0, 0, self.pEventUpdate)
	
	self.Controls.m_BtnFloor1.onClick:AddListener(handler(self, self.OnBtnRule))
	self.Controls.m_BtnFloor2.onClick:AddListener(handler(self, self.OnBtnRule))
	self.Controls.m_BtnFloor3.onClick:AddListener(handler(self, self.OnBtnRule))
end

-- 销毁
function SkyEarthWnd:OnDestroy()
	
	self:Hide()
	
	rktEventEngine.UnSubscribeExecute(EVENT_SKYEARTH_UPDATE, 0, 0, self.pEventUpdate)
	
	UIControl.OnDestroy(self)
end

-- 显示
function SkyEarthWnd:Show()
	UIControl.Show(self)
	
	self:OnEventUpdate()
end

-- 关闭
function SkyEarthWnd:Hide()
	UIControl.Hide(self)
	self:StopCDTimer()
end

-- 刷新界面
function SkyEarthWnd:OnEventUpdate()

	local nFloor = IGame.SkyEarth:GetFloor()
	
	if nFloor == 1 then
		self:HideFloor2()
		self:HideFloor3()
		self:ShowFloor1()

	elseif nFloor == 2 then
		self:HideFloor1()
		self:HideFloor3()
		self:ShowFloor2()	
		
	elseif nFloor == 3 then
		self:HideFloor1()
		self:HideFloor2()
		self:ShowFloor3()
	end
end

-- 显示1层
function SkyEarthWnd:ShowFloor1()
	
	self.nShowFloor = 1
	self.Controls.m_Floor1.gameObject:SetActive(true)
	local tData = IGame.SkyEarth:GetInfoFloor1()
	if not tData then
		return
	end
	
	self.Controls.m_TextNum1_1.text = tData[1].."/1"
	self.Controls.m_TextNum2_1.text = tData[2].."/1"
	self.Controls.m_TextNum3_1.text = tData[3].."/1"
	
	local nTime = IGame.SkyEarth:GetTimeNext()
	
	if nTime < 0 then
		self.Controls.m_TextTime1.gameObject:SetActive(false)
	else
		self.Controls.m_TextTime1.gameObject:SetActive(true)
		self:SetCDTimer(nTime)
	end
end

-- 隐藏1层
function SkyEarthWnd:HideFloor1()
	self.Controls.m_Floor1.gameObject:SetActive(false)
	self:StopCDTimer()
end

-- 显示2层
function SkyEarthWnd:ShowFloor2()
	self.nShowFloor = 2
	self.Controls.m_Floor2.gameObject:SetActive(true)
	local tData = IGame.SkyEarth:GetInfoFloor2()
	if not tData then
		return
	end
	
	self.Controls.m_TextNum1_2.text = tData[1]
	self.Controls.m_TextNum2_2.text = tData[2]
	self.Controls.m_TextNum3_2.text = tData[3]
	self.Controls.m_TextNum4_2.text = tData[4]
	self.Controls.m_TextNum5_2.text = tData[5]
	
	if tData[5] then
		self.Controls.m_TextNum5_2.text = tData[5]
	else
		self.Controls.m_TextNum5_2.gameObject:SetActive(false)
		self.Controls.m_TextBoss.gameObject:SetActive(false)
	end
	
	local nTime = IGame.SkyEarth:GetTimeNext()
	
	if nTime < 0 then
		self.Controls.m_TextTime2.gameObject:SetActive(false)
	else
		self.Controls.m_TextTime2.gameObject:SetActive(true)
		self:SetCDTimer(nTime)
	end
end

-- 隐藏2层
function SkyEarthWnd:HideFloor2()
	self.Controls.m_Floor2.gameObject:SetActive(false)
	self:StopCDTimer()
end

-- 显示3层
function SkyEarthWnd:ShowFloor3()
	self.nShowFloor = 3
	self.Controls.m_Floor3.gameObject:SetActive(true)
	
	local tData = IGame.SkyEarth:GetInfoFloor3()
	if not tData then
		return
	end
	
	self.Controls.m_TextNum1_3.text = tData[1]
	
end

-- 隐藏3层
function SkyEarthWnd:HideFloor3()
	self.Controls.m_Floor3.gameObject:SetActive(false)
end

-- 设置战斗结束倒计时
function SkyEarthWnd:SetCDTimer(nTime)
	
	self:StopCDTimer()
	
	if not self.tTextTime[self.nShowFloor] then 
		return
	end

	local nTimeCount = nTime - IGame.EntityClient:GetZoneServerTime()
	local strText = self.tTextTime[self.nShowFloor][2]
	
	if nTimeCount > 1 then
		strText = GetCDTime(nTimeCount, 3, 3)

		strText = self.tTextTime[self.nShowFloor][1]..strText

		self.m_TimerCallBack = function() self:OnTimer() end
	end
	
	self.m_LeftTime = nTimeCount

	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "SkyEarthWnd:SetCDTimer")
	
	if self.nShowFloor == 1 then
		self.Controls.m_TextTime1.text = strText
	
	elseif self.nShowFloor == 2 then
		self.Controls.m_TextTime2.text = strText
	end
end

-- 定时器
function SkyEarthWnd:OnTimer()
		
	if not self.tTextTime[self.nShowFloor] then
		self:StopCDTimer()
		return
	end
	
	local strText = self.tTextTime[self.nShowFloor][2]
	
	self.m_LeftTime = self.m_LeftTime - 1
	
	if self.m_LeftTime > 0 then
		strText = GetCDTime(self.m_LeftTime, 3, 3)
		strText = self.tTextTime[self.nShowFloor][1]..strText
	else
		self:StopCDTimer()
	end
	
	if self.nShowFloor == 1 then
		self.Controls.m_TextTime1.text = strText
	
	elseif self.nShowFloor == 2 then
		self.Controls.m_TextTime2.text = strText
	end
end

-- 停止倒计时
function SkyEarthWnd:StopCDTimer()
	
	if self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

-- 显示规则
function SkyEarthWnd:OnBtnRule()
	IGame.SkyEarth:ShowRule()
end

return SkyEarthWnd
------------------------------------------------------------

