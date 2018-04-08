-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    何荣德
-- 日  期:    2017-12-20
-- 版  本:    1.0
-- 描  述:    假人战场倒计时窗口
-------------------------------------------------------------------

local JRBattleTimerWindow = UIWindow:new
{
	windowName = "JRBattleTimerWindow",
	m_nTimers   = 0,						--时间
    m_nOwnCampPoints = 0,
    m_nEnemyCampPoints = 0,
}

local this = JRBattleTimerWindow	-- 方便书写

function JRBattleTimerWindow:Init()
    if self.updateTimerFunc then
        self.updateTimerFunc = nil
    end
	self.updateTimerFunc = function() self:UpdateTime() end
end

function JRBattleTimerWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)
	
    self:Init()
	self:ShowTimer(self.m_nTimers)
    self:UpdateOwnCampPoints(self.m_nOwnCampPoints)
    self:UpdateEnemyCampPoints(self.m_nEnemyCampPoints)
	
	return self
end

function JRBattleTimerWindow:Clear()
   if self.updateTimerFunc then
        rktTimer.KillTimer( self.updateTimerFunc )
        self.updateTimerFunc = nil
    end
    
    self.m_nTimers   = 0
    self.m_nOwnCampPoints = 0
    self.m_nEnemyCampPoints = 0 
end

function JRBattleTimerWindow:OnDestroy()
    UIWindow.OnDestroy(self)
	self:Clear()
end

function JRBattleTimerWindow:ShowTimer(nTime)
    self.m_nTimers = nTime
	if not self:isLoaded() then
        self:Show()
		return
	end
	
	self.m_nCacheTickCount = luaGetTickCount()
	
    if self.updateTimerFunc then
        rktTimer.KillTimer( self.updateTimerFunc )
    end
    
	-- 刷新一下时间 不然这里要等到下一秒才刷新
	self:UpdateTime()
	rktTimer.SetTimer( self.updateTimerFunc, 500, -1, "JRBattleTimerWindow:ShowTimer")
end

function JRBattleTimerWindow:UpdateOwnCampPoints(nPoints)
    self.m_nOwnCampPoints = nPoints
    if not self:isLoaded() then
        return
    end
    
    self.Controls.m_LanCount.text = nPoints
end

function JRBattleTimerWindow:UpdateEnemyCampPoints(nPoints)
    self.m_nEnemyCampPoints = nPoints
    if not self:isLoaded() then
        return
    end
    
    self.Controls.m_HongCount.text = nPoints
end


--更新时间
function JRBattleTimerWindow:UpdateTime()
	if not self:isLoaded() then
		return
	end
	
	local curTickCount = luaGetTickCount()
	local passTickCount = curTickCount - self.m_nCacheTickCount
	self.m_nCacheTickCount = curTickCount
	
	self.m_nTimers = self.m_nTimers - passTickCount / 1000
	if self.m_nTimers <= 0 then
		-- 关闭定时器
		rktTimer.KillTimer( self.updateTimerFunc )
		self:Hide()
	end
	
	self.Controls.m_TimeCount.text = GetCDTime(self.m_nTimers, 3, 3)
end

return JRBattleTimerWindow