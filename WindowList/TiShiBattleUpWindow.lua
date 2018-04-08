-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/03/07
-- 版  本:    1.0
-- 描  述:    战力增加的提示窗口
-------------------------------------------------------------------

local TiShiBattleUpWindow = UIWindow:new
{
	windowName		= "TiShiBattleUpWindow",
	m_TimeHander	= nil,
	m_TimerRunning	= false,
	m_StepTime		= 64,		-- 每步时间
	m_StepValue		= nil,		-- 每步增加的数值
	m_LiveTime		= 500,		-- 结束停留时间
	m_StepCnt		= nil,		-- 步数记数
	m_MaxStep		= 21,		-- 最大步数
	m_StartValue	= nil,
	m_ShowValue		= nil,
	m_TargetValue	= nil,
	m_CntWei = 0,
	m_DelayShow = false,
	m_TimerHanderDelay = nil,
}

local this = TiShiBattleUpWindow					-- 方便书写

------------------------------------------------------------
function TiShiBattleUpWindow:Init()
	self.m_TimeHander = function() self:OnTimer() end
	self.m_KillTimeHander = function() self:KillTimer() end
end

------------------------------------------------------------
function TiShiBattleUpWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._SpecialTopLayer)
	local ss = string.format("%0"..self.m_CntWei.."d", self.m_ShowValue)
	self.Controls.m_ValueText.text = tostring(ss)
    return self
end

------------------------------------------------------------
--设置内容
function TiShiBattleUpWindow:SetBattleValue()
	if not self:isLoaded() then
		return
	end
	local ss = string.format("%0"..self.m_CntWei.."d", self.m_ShowValue)
	self.Controls.m_ValueText.text = tostring(ss)
end

------------------------------------------------------------
--定时器回调函数
function TiShiBattleUpWindow:OnTimer()
	if self.m_ShowValue <self.m_TargetValue then
		self.m_StepCnt = self.m_StepCnt + 1
		if self.m_StepCnt >= self.m_MaxStep then
			self.m_ShowValue = self.m_TargetValue
			self:SetBattleValue()
		else
			self.m_ShowValue = self.m_ShowValue + self.m_StepValue
			if self.m_ShowValue >= self.m_TargetValue then
				self.m_ShowValue = self.m_TargetValue
				self:SetBattleValue()
			else
				self:SetBattleValue()
				return
			end
		end
	elseif self.m_ShowValue <self.m_TargetValue then
		uerror("战力值超了 m_ShowValue : "..self.m_ShowValue..", m_TargetValue : "..self.m_TargetValue)
	end
	rktTimer.SetTimer(self.m_KillTimeHander, self.m_LiveTime, 1, "TiShiBattleUpWindow:SetTimer")
end

function TiShiBattleUpWindow:KillTimer()
	self.m_TimerRunning = false
	m_StartValue	= nil
	self:Hide()
	rktTimer.KillTimer( self.m_TimeHander )
end

------------------------------------------------------------
-- 添加新的tpis消息到列表
function TiShiBattleUpWindow:OnBattleValueArrived(LastValue,BattleValue)
	if not LastValue or LastValue == 0 or not BattleValue or LastValue == BattleValue then
		return
	end
	local hero = GetHero()
	if not hero then
		return
	end
	self.m_StartValue = LastValue
	self.m_ShowValue = self.m_StartValue
	self.m_TargetValue	= tonumber(BattleValue)
	self.m_CntWei = string.len(tostring(BattleValue))
	if self.m_DelayShow then
		return
	end
	
	if not self.m_CntWei or self.m_CntWei < 0 then
		return
	end
	if not self.m_TargetValue or self.m_TargetValue < self.m_StartValue then
		return
	end
	local AddValue = self.m_TargetValue - self.m_StartValue
	if AddValue > 21 then
		self.m_StepValue =  math.modf(AddValue/21)
	else
		self.m_StepValue = 1
	end
	self:Show(true)
	self:StartRefrashValue()
end

------------------------------------------------------------
-- 刷新战力值显示
function TiShiBattleUpWindow:StartRefrashValue()
	if not self:isLoaded() then
		DelayExecuteEx(100,function ()
			self:StartRefrashValue()
		end)
		return
	end
	self:Show(true)
	self.m_StepCnt = 0
	if self.m_TimerRunning == true then
		rktTimer.KillTimer( self.m_TimeHander )
		rktTimer.KillTimer( self.m_KillTimeHander )
	end
	self.m_TimerRunning = true
	rktTimer.SetTimer(self.m_TimeHander, self.m_StepTime, -1, "TiShiBattleUpWindow:SetTimer")
	
	self:SetBattleValue()
end

function TiShiBattleUpWindow:SetDelayShow(Flg)
	self.m_DelayShow = Flg
	if Flg then
		self.m_TimerHanderDelay = DelayExecuteEx(2000,function ()
			self:SetDelayShow(false)
		end)
	else
		if self.m_TimerHanderDelay then
			KillDelayExecuteFunction(self.m_TimerHanderDelay)
			self.m_TimerHanderDelay = nil
		end
	end
end

function TiShiBattleUpWindow:DelayShow()
	self:OnBattleValueArrived(self.m_StartValue,self.m_TargetValue)
end

return this
