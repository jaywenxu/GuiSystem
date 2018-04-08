-------------------------------------------------------------------
-- @Author: XieXiaoMei
-- @Date:   2017-08-07 10:05:43
-- @Vers:	1.0
-- @Desc:	领地战战斗窗口
-------------------------------------------------------------------

local LigeanceFightWindow    = UIWindow:new
{
	windowName      = "LigeanceFightWindow",
		
	m_OccupiesWdt = nil,

	m_LeftTime      = 0,   -- 战斗结束倒计时剩余时间
	m_TimerCallBack = nil, -- 战斗结束倒计时回调

	m_EventHandler = {},

	m_LigeanceID = "",

	m_Timestamp = 0,
	
	bNeedInit = false,
	
	bShowReadyTimer = false,
}


local LigeanceEctype= IGame.LigeanceEctype
local OccupiesWdtFile = "GuiSystem.WindowList.LigeanceFight.LigeOccupiesWdt"

local this = LigeanceFightWindow
------------------------------------------------------------
function LigeanceFightWindow:Init()

end

------------------------------------------------------------
-- 初始化
function LigeanceFightWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls

	controls.m_FrameBtn.onClick:AddListener(handler(self, self.OnBtnOccupiesClicked))
	controls.m_OccupiesPnlBtn.onClick:AddListener(handler(self, self.OnBtnOccupiesPnlClicked))
	controls.m_SwtBattleSpaceBtn.onClick:AddListener(handler(self, self.OnBtnSwtBattleSpaceClicked))

	
	self.m_EventHandler[EVENT_LIGE_FIGHT_TIMER_INFO_UP] = self.OnRefreshTimerEvt
	self.m_EventHandler[EVENT_LIGE_FIGHT_OCCUPIES_UP] = self.ShowOccupiesWdt

	for eventID, handler in pairs(self.m_EventHandler) do
		rktEventEngine.SubscribeExecute( eventID, 0, 0, handler, self)
	end

	self:VisibleReadyTimer(false) -- 默认显示战斗倒计时
	
	if self.bNeedInit then
		self.bNeedInit = false
		self:ShowWindowTimer(self.bShowReadyTimer)
	end
end

------------------------------------------------------------
-- 销毁
function LigeanceFightWindow:OnDestroy()
	for eventID, handler in pairs(self.m_EventHandler) do
		rktEventEngine.UnSubscribeExecute( eventID, 0, 0, handler, self)
	end
	
	self:StopCDTimer()

	UIWindow.OnDestroy(self)
	
	table_release(self)
end

------------------------------------------------------------
-- 关闭
function LigeanceFightWindow:Hide(destory )
	UIWindow.Hide(self, destory )

	self:StopCDTimer()
end


------------------------------------------------------------
-- 显示准备倒计时
function LigeanceFightWindow:ShowReadyTimer()
	print("LigeanceFightWindow:ShowReadyTimer()")

	self:VisibleReadyTimer(true)

	local timestamp = LigeanceEctype:GetReadyEndTime()
	local leadClan, contribute, contriMax = LigeanceEctype:GetFightInfo()
	self:RefreshTimerInfo(timestamp, leadClan, contribute, contriMax)

end

------------------------------------------------------------
-- 更新战斗数据
function LigeanceFightWindow:OnRefreshTimerEvt(_, _, _, timestamp, leadClan, contribute, contriMax)
	self:RefreshTimerInfo( timestamp, leadClan, contribute, contriMax)
end


------------------------------------------------------------
-- 显示战斗数据
function LigeanceFightWindow:ShowFightTimer()

	self:VisibleReadyTimer(false)

	local timestamp = LigeanceEctype:GetFightEndTime()
	local leadClan, contribute, contriMax = LigeanceEctype:GetFightInfo()
	self:RefreshTimerInfo(timestamp, leadClan, contribute, contriMax)
end

function LigeanceFightWindow:RefreshTimerInfo(timestamp, leadClan, contribute, contriMax)
	if timestamp ~= nil and self.m_Timestamp ~= timestamp  then
		self:SetCDTimer(timestamp)
	end

	if leadClan ~= nil then
		self.Controls.m_ClanNameTxt.text = leadClan
	end

	if contribute ~= nil or contribute ~= nil then
		self.Controls.m_ContributeTxt.text = contribute .. "/" .. contriMax
	end
end

function LigeanceFightWindow:VisibleReadyTimer(bShowReady)
	self.Controls.m_Ready.gameObject:SetActive(bShowReady)
end

------------------------------------------------------------
-- 隐藏准备倒计时
function LigeanceFightWindow:HideReadyTimer()
	if not self:isLoaded() then
		return
	end
	self:VisibleReadyTimer(true)
end

------------------------------------------------------------
-- 设置战斗结束倒计时
function LigeanceFightWindow:SetCDTimer(timestamp)
	self:StopCDTimer()

	local timerTxt = self.Controls.m_FightEndCDTxt

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

	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "HGLY fight time down")

	self.m_Timestamp = timestamp
end

------------------------------------------------------------
-- 停止倒计时timer
function LigeanceFightWindow:StopCDTimer()
	if nil ~= self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

------------------------------------------------------------
-- 据点按钮按下
function LigeanceFightWindow:OnBtnOccupiesClicked()
	LigeanceEctype:Request_UpdateInfo()
end

------------------------------------------------------------
-- 显示据点面板
function LigeanceFightWindow:ShowOccupiesWdt()
	local controls = self.Controls
	controls.m_Occupies.gameObject:SetActive(true)

	local id = LigeanceEctype:GetLigeanceID()
	if self.m_LigeanceID ~= id then
		local ligeCfg = IGame.rktScheme:GetSchemeInfo(LIGEANCE_CSV, id)
		if not ligeCfg then
			cLog("本地配置不能为空 id:".. data.nID, "red")
			return
		end
		controls.m_LigeNameTxt.text = ligeCfg.szName -- 战场名字

		self.m_LigeanceID = id
	end

	local warInfo = LigeanceEctype:GetWarInfo()
	for i, v in ipairs(warInfo) do
		local cell = controls["m_OccupyCell"..i]

		local ligeaceNameTxt = cell:Find("LigeaceName"):GetComponent(typeof(Text))
		ligeaceNameTxt.text = v.strPoint

		local occupyClanTxt = cell:Find("OccupyClan"):GetComponent(typeof(Text))
		occupyClanTxt.text = v.strClan

		local takeFlagPeoTxt = cell:Find("TakeFlagPeople"):GetComponent(typeof(Text))
		takeFlagPeoTxt.text = v.strBanner
	end

end

------------------------------------------------------------
-- 据点底部面板按下--关闭据点面板
function LigeanceFightWindow:OnBtnOccupiesPnlClicked()
	self.Controls.m_Occupies.gameObject:SetActive(false)
end

------------------------------------------------------------
-- 切换战斗战场
function LigeanceFightWindow:OnBtnSwtBattleSpaceClicked()
	IGame.Ligeance:ShowWarList()
end

function LigeanceFightWindow:ShowWindowTimer(bShowReadyTimer)

	self.bShowReadyTimer = bShowReadyTimer
	
	if not this:isShow() then
		self.bNeedInit = true
		this:Show(true)
		return
	end
	
	if self.bShowReadyTimer then
		this:ShowReadyTimer()
	else
		this:ShowFightTimer()
	end
end

return LigeanceFightWindow
------------------------------------------------------------

