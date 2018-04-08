-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    方称称
-- 日  期:    2017/05/27
-- 版  本:    1.0
-- 描  述:    副本倒计时窗口
-------------------------------------------------------------------

local EctypeTimerWindow = UIWindow:new
{
	windowName = "EctypeTimerWindow",
	m_timers   = 20,						--时间
	m_timeData,
	m_killNum,
	m_monsterNum,
	m_nCacheTickCount = 0,
	strFunLeave = nil,
}

local this = EctypeTimerWindow	-- 方便书写

function EctypeTimerWindow:Init()
	self.updateTimerFunc = function() self:UpdateTime() end
end

function EctypeTimerWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)
	
	self.Controls.m_QuitBtn.onClick:AddListener( handler(self, self.QuitCallback) )
	
	self:ShowTimer(self.m_timeData)
	self:UpdateMonsterInfo(self.m_killNum,self.m_monsterNum)
	
	return self
end

--退出副本
function EctypeTimerWindow:QuitCallback()
	
	local strFun = self.strFunLeave
	local confirmCallBack = function ( )
		-- 关闭定时器
		rktTimer.KillTimer( self.updateTimerFunc )
		GameHelp.PostServerRequest(strFun)
		self:Hide()
	end
	local data = 
	{
		content = "你确定要离开副本吗?",
		confirmCallBack = confirmCallBack,
	}	
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

--隐藏窗口
function EctypeTimerWindow:hideWindow()
	-- 关闭定时器
	rktTimer.KillTimer( self.updateTimerFunc )
	self:Hide()
    UIManager.ConfirmPopWindow:Hide()
end

function EctypeTimerWindow:OnDestroy()
	UIWindow.OnDestroy(self)
	-- 关闭定时器
	rktTimer.KillTimer( self.callbackTimerFunc )
	
	self.m_killNum = nil
	self.m_monsterNum = nil
end

-- totalTimes:倒计时总时间秒（S）
-- timeData = { timer_interval = , isHideExitBtn = , isHideTimeBar , strFunLeave =  }
-- strFunLeave：点击离开按钮函数(字符串形式)，如果不填默认 RequestForceGoBace
function EctypeTimerWindow:ShowTimer(timeData)	
	if not timeData then
		return
	end
	
	self.m_timeData = timeData
	if not self:isLoaded() then
		return
	end
	
	self.m_timers = tonumber(timeData.timer_interval)
	self.strFunLeave = timeData.strFunLeave or "RequestForceGoBace()"
	self.m_nCacheTickCount = luaGetTickCount()
	
	rktTimer.KillTimer( self.updateTimerFunc )
	-- 刷新一下时间 不然这里要等到下一秒才刷新
	self:UpdateTime()
	rktTimer.SetTimer( self.updateTimerFunc, 1000, -1, "EctypeTimerWindow:ShowTimer")
	
	if timeData.isHideExitBtn and timeData.isHideExitBtn == 1 then
		self.Controls.m_QuitBtn.gameObject:SetActive(false)
	else
		self.Controls.m_QuitBtn.gameObject:SetActive(true)
	end
			
	if timeData.isHideTimeBar and timeData.isHideTimeBar == 1 then
		self.Controls.m_Timer.gameObject:SetActive(false)
		self.Controls.m_Bg2.gameObject:SetActive(false)
	else
		self.Controls.m_Timer.gameObject:SetActive(true)
		self.Controls.m_Bg2.gameObject:SetActive(true)
	end
end


function EctypeTimerWindow:UpdateMonsterInfo(killNum,monsterNum)
	if killNum == nil or monsterNum == nil then
		return
	end
	self.m_killNum = killNum
	self.m_monsterNum = monsterNum
	
	if not self:isLoaded() then
		return
	end
	
	self.Controls.m_Bg1.gameObject:SetActive(true)
	self.Controls.m_Bg2.gameObject:SetActive(false)
	self.Controls.m_Counter.gameObject:SetActive(true)
	self.Controls.m_CntText.text = killNum .. "/" .. monsterNum
end


--更新时间
function EctypeTimerWindow:UpdateTime()
	if not self:isLoaded() then
		return
	end
	
	local curTickCount = luaGetTickCount()
	local passTickCount = curTickCount - self.m_nCacheTickCount
	self.m_nCacheTickCount = curTickCount
	
	self.m_timers = self.m_timers - passTickCount / 1000
	if self.m_timers <= 0 then
		-- 关闭定时器
		rktTimer.KillTimer( self.updateTimerFunc )
		self:Hide()
	end
	
	self.Controls.m_TimerText.text = GetCDTime(self.m_timers, 3, 2)
end

return EctypeTimerWindow