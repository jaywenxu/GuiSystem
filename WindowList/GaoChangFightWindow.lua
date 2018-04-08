-------------------------------------------------------------------
-- @Author: XieXiaoMei
-- @Date:   2017-08-21 15:05:43
-- @Vers:	1.0
-- @Desc:	高昌密道战斗窗口
-------------------------------------------------------------------

local GaoChangFightWindow    = UIWindow:new
{
	windowName      = "GaoChangFightWindow",
		
	m_LeftTime      = 0,   -- 战斗结束倒计时剩余时间
	m_TimerCallBack = nil, -- 战斗结束倒计时回调

	m_EventHandler = {},

	m_Timestamp = 0,
}


local LigeanceEctype= IGame.LigeanceEctype
local OccupiesWdtFile = "GuiSystem.WindowList.LigeanceFight.LigeOccupiesWdt"

local this = GaoChangFightWindow
------------------------------------------------------------
function GaoChangFightWindow:Init()

end

 
------------------------------------------------------------
-- 初始化
function GaoChangFightWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls

	self:AddListener( controls.m_ExitBtn , "onClick" ,  self.OnBtnExitFightClicked, self )
	self:AddListener( controls.m_WndBgBtn , "onClick" ,  self.OnBtnWndBgClicked, self )
	self:AddListener( controls.m_KeysDescBgBtn , "onClick" ,  self.OnBtnKesDescBgClicked, self )

	self.m_EventHandler[EVENT_UI_GAOCHANG_INFO_UPDATE] = self.RefreshInfo
	for eventID, handler in pairs(self.m_EventHandler) do
		rktEventEngine.SubscribeExecute( eventID, 0, 0, handler, self)
	end

	self:RefreshInfo()
end


------------------------------------------------------------
-- 销毁
function GaoChangFightWindow:OnDestroy()
	for eventID, handler in pairs(self.m_EventHandler) do
		rktEventEngine.UnSubscribeExecute( eventID, 0, 0, handler, self)
	end
	
	self:StopCDTimer()

	UIWindow.OnDestroy(self)
	
	table_release(self)
end

------------------------------------------------------------
-- 关闭
function GaoChangFightWindow:Hide(destory )
	UIWindow.Hide(self, destory )

	self:StopCDTimer()
end



------------------------------------------------------------
-- 更新战斗数据
function GaoChangFightWindow:RefreshInfo()
	local timestamp, normKeyNum, goldKeyNum = IGame.GaoChangEctype:GetFightInfo()
	
	if timestamp ~= nil and self.m_Timestamp ~= timestamp  then
		self:SetCDTimer(timestamp)
	end

	if normKeyNum ~= nil then
		self.Controls.m_GoldKeyNumTxt.text = goldKeyNum
	end

	if goldKeyNum ~= nil then
		self.Controls.m_NormKeyNumTxt.text = normKeyNum
	end
end


------------------------------------------------------------
-- 设置战斗结束倒计时
function GaoChangFightWindow:SetCDTimer(timestamp)
	self:StopCDTimer()

	local timerTxt = self.Controls.m_RefreTimerTxt

	local time = timestamp - IGame.EntityClient:GetZoneServerTime()
	if time < 1 then
		timerTxt.text = "活动结束"
		return
	end
	
	timerTxt.text = GetCDTime(time, 3, 3)

	self.m_TimerCallBack = function() --倒计时timer
		self.m_LeftTime = self.m_LeftTime - 1
		if self.m_LeftTime < 1 then
			timerTxt.text = "活动结束"
			self:StopCDTimer()
			return
		end

		timerTxt.text = GetCDTime(self.m_LeftTime, 3, 3)
	end
	self.m_LeftTime = time

	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "GCMD fight time down")

	self.m_Timestamp = timestamp
end

------------------------------------------------------------
-- 停止倒计时timer
function GaoChangFightWindow:StopCDTimer()
	if nil ~= self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

------------------------------------------------------------
-- 离开战斗
function GaoChangFightWindow:OnBtnExitFightClicked()
	IGame.GaoChangEctype:Request_LeaveEctype()
end

------------------------------------------------------------
-- 战斗窗口背景按下--弹出钥匙描述弹框
function GaoChangFightWindow:OnBtnWndBgClicked()
	self:ShowKeysDescWdt(true)
end

------------------------------------------------------------
-- 钥匙描述弹框背景按下--关闭钥匙描述弹框
function GaoChangFightWindow:OnBtnKesDescBgClicked()
	self:ShowKeysDescWdt(false)
end

------------------------------------------------------------
-- 显示、关闭钥匙描述弹框
function GaoChangFightWindow:ShowKeysDescWdt(isShow)
	self.Controls.m_KeysDescWdt.gameObject:SetActive(isShow)
end

return GaoChangFightWindow
------------------------------------------------------------

