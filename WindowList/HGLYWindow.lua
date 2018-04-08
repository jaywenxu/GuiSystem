-- 火攻粮营界面
-- @Author: XieXiaoMei
-- @Date:   2017-06-12 14:05:43
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-10 12:17:52

local HGLYWindow    = UIWindow:new
{
	windowName      = "HGLYWindow",
	
	m_FightEndLeftTime      = 0,   -- 战斗结束倒计时剩余时间
	m_FightEndTimerCallBack = nil, -- 战斗结束倒计时回调

	m_ReadyEndLeftTime      = 0,   -- 准备结束倒计时剩余时间
	m_ReadyEndTimerCallBack = nil, -- 准备结束倒计时回调
}

------------------------------------------------------------
function HGLYWindow:Init()
end

function HGLYWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls

	local blueCampProSld = controls.m_BlueCampSlider:GetComponent(typeof(Slider))
	controls.blueCampProSld = blueCampProSld

	local redCampProSld = controls.m_RedCampSlider:GetComponent(typeof(Slider))
	controls.redCampProSld = redCampProSld

	controls.m_RankBtn.onClick:AddListener(handler(self, self.OnBtnRankClicked))

	self.m_BanlanceCallBack = handler(self, self.OnBanlanceEvt)
	rktEventEngine.SubscribeExecute( EVENT_FIREDESTROY_BANLANCE, 0, 0, self.m_BanlanceCallBack )

	controls.m_ReadyCD.gameObject:SetActive(false)
	controls.m_FightInfo.gameObject:SetActive(false)

    if nil ~= self.m_cachedFightInfo then
        local info = self.m_cachedFightInfo
        self.m_cachedFightInfo = nil
        self:RefreshFightInfo( info.redCampVal , info.blueCampVal , info.max , info.time , info.contribute )
    end
    if self.m_needShowReadyCD then
        self.m_needShowReadyCD = false
        self:ShowReadyCD()
    end
end

function HGLYWindow:OnDestroy()
	rktEventEngine.UnSubscribeExecute( EVENT_FIREDESTROY_BANLANCE , 0, 0, self.m_BanlanceCallBack )
	self.m_BanlanceCallBack = nil
	
	self:StopCDTimer(self.m_FightEndTimerCallBack)
	self:StopCDTimer(self.m_ReadyEndTimerCallBack)

	UIWindow.OnDestroy(self)
	
	table_release(self)
end


function HGLYWindow:Hide(destory )
	UIWindow.Hide(self, destory )

	self:StopCDTimer(self.m_FightEndTimerCallBack)
	self:StopCDTimer(self.m_ReadyEndTimerCallBack)

	UIManager.HGLYRankWindow:Hide()
end

-- 更新战斗数据
function HGLYWindow:RefreshFightInfo(redCampVal, blueCampVal, max, time, contribute)

    if not self:isLoaded() then
        self.m_cachedFightInfo = { redCampVal = redCampVal , blueCampVal = blueCampVal , max = max , time = time , contribute = contribute }
        return
    end

	self.Controls.m_FightInfo.gameObject:SetActive(true)

	self:SetFightEndTimer(time)

	self:SetRedCampSlider(redCampVal, max)
	self:SetBlueCampSlider(blueCampVal, max)
	self:SetContribute(contribute)
end

-- 显示准备倒计时
function HGLYWindow:ShowReadyCD()

    if not self:isLoaded() then
        self.m_needShowReadyCD = true
        return
    end

	self:StopCDTimer(self.m_ReadyEndTimerCallBack)

	local readyEndTime = IGame.FireDestroyEctype:GetReadyEndTime()
	local curTime = IGame.EntityClient:GetZoneServerTime()

	local controls = self.Controls
	controls.m_ReadyCD.gameObject:SetActive(readyEndTime > curTime)
	
	
	if readyEndTime > curTime then 
		self.m_ReadyEndLeftTime = readyEndTime - curTime

		local timerTxt = controls.m_ReadyCDTxt
		timerTxt.text = GetCDTime(self.m_ReadyEndLeftTime, 3, 3)

		self.m_ReadyEndTimerCallBack = function ()
			self.m_ReadyEndLeftTime = self.m_ReadyEndLeftTime - 1
			if self.m_ReadyEndLeftTime < 0 then
				self:HideReadyTimer()
				return
			end

			timerTxt.text = GetCDTime(self.m_ReadyEndLeftTime, 3, 3)
		end

		rktTimer.SetTimer(self.m_ReadyEndTimerCallBack, 1000, -1, "HGLY fight ready time down")
	end
end

-- 隐藏准备倒计时
function HGLYWindow:HideReadyTimer()
	if not self:isLoaded() then
		return
	end
	
	self:StopCDTimer(self.m_ReadyEndTimerCallBack)
	self.Controls.m_ReadyCD.gameObject:SetActive(false)
end


-- 设置战斗结束倒计时
function HGLYWindow:SetFightEndTimer(time)
	self:StopCDTimer(self.m_FightEndTimerCallBack)

	local timerTxt = self.Controls.m_LeftTimeTxt
	if time < 1 then
		timerTxt.text = "活动结束"
		return
	end
	
	timerTxt.text = GetCDTime(time, 3, 3)

	self.m_FightEndTimerCallBack = function() --倒计时timer
		self.m_FightEndLeftTime = self.m_FightEndLeftTime - 1
		if self.m_FightEndLeftTime < 1 then
			timerTxt.text = "活动结束"
			self:StopCDTimer(self.m_FightEndTimerCallBack)
			return
		end

		timerTxt.text ="".. GetCDTime(self.m_FightEndLeftTime, 3, 3)
	end
	self.m_FightEndLeftTime = time

	rktTimer.SetTimer(self.m_FightEndTimerCallBack, 1000, -1, "HGLY fight time down")
end


-- 停止倒计时timer
function HGLYWindow:StopCDTimer(timerCallback)
	if nil ~= timerCallback then
		rktTimer.KillTimer(timerCallback)
		timerCallback = nil
	end
end


-- 设置我方方阵型进度条
function HGLYWindow:SetBlueCampSlider(value, max)
	local controls = self.Controls

	controls.blueCampProSld.value = value / max

	controls.m_BluePercentTxt.text = string.format("%d/%d", value, max)
end

-- 设置敌方阵型进度条
function HGLYWindow:SetRedCampSlider(value, max)
	local controls = self.Controls

	controls.redCampProSld.value = value / max

	controls.m_RedPercentTxt.text = string.format("%d/%d", value, max)
end

-- 设置贡献值
function HGLYWindow:SetContribute(value)
	local controls = self.Controls

	controls.m_ContributeTxt.text = value
end

-- 排行按钮
function HGLYWindow:OnBtnRankClicked()
	UIManager.HGLYRankWindow:ShowWindow(self.m_FightEndLeftTime - 1)
end


-- 结算事件
function HGLYWindow:OnBanlanceEvt(_, _, _)
	UIManager.HGLYRankWindow:ShowWindow(0)
	UIManager.HGLYRankWindow:OnBanlanceEvt()
end



return HGLYWindow
------------------------------------------------------------

