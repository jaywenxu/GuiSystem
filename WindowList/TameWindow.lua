-------------------------------------------------------------------
-- 文件名:	TameWindow.lua
-- 版  权:  (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:  何水大(765865368@qq.com)
-- 日  期:  2017-12-27
-- 版  本:  1.0
-- 描  述:  驯马玩法UI
-------------------------------------------------------------------

local REFRESH_TIMER_LANG = 100
local FREEZE_GROUP = 204
local TAMEDRUG_TYPE = 9

local TameWindow = UIWindow:new
{
	windowName = "TameWindow",	-- 窗口名称
	m_NeedUpdate = false,
	m_curPower = 0,
	m_maxPower = 0,
	m_time = 0,
	m_crit = false,
	m_lastClickTime = 0, -- 不让太过频道点击按钮
	m_CritTweenAnim = nil,
	m_tameDrug = {}, -- 驯马药
	m_CoolInfo = nil,
	m_curDrugID = 0,
}

function TameWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	local controls = self.Controls
	
	local powerSlider = controls.m_PowerSlider:GetComponent(typeof(Slider))
	controls.m_PowerSlider = powerSlider
	
	self.callback_AddPowerBtn = function () self:OnAddPower() end
	controls.m_AddPowerBtn.onClick:AddListener(self.callback_AddPowerBtn)
	
	self.callback_UseDrugBtn = function () self:OnUseDrug() end
	controls.m_UseDrugBtn.onClick:AddListener(self.callback_UseDrugBtn)
	
	self.callback_AddrugBtn = function () self:OnAddDrug() end
	controls.m_AddDrugBtn.onClick:AddListener(self.callback_AddrugBtn)
	
	self.m_CritTweenAnim = controls.m_Crit:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	
	self:LoadTameDrugConfig()
	self:SetCurDrug()
	if self.m_NeedUpdate == true then
		self.m_NeedUpdate = false
		self:ShowUI()
	end
	
	self.callback_OnTimerCoolDown = function() self:OnTimerCoolDown() end
	
	-- 冷却相关事件
	self.callback_OnExecuteEventFreezeStart = function(event, srctype, srcid, msg) self:OnExecuteEventFreezeStart(msg) end
	rktEventEngine.SubscribeExecute(EVENT_FREEZE_START, SOURCE_TYPE_FREEZE, 0, self.callback_OnExecuteEventFreezeStart)
end

-- 窗口销毁
function TameWindow:OnDestroy()	
	
	local controls = self.Controls
	
	local powerSlider = controls.m_PowerSlider:GetComponent(typeof(Slider))
	controls.m_PowerSlider = powerSlider

	controls.m_AddPowerBtn.onClick:RemoveListener(self.callback_AddPowerBtn)
	self.callback_AddPowerBtn = nil

	controls.m_UseDrugBtn.onClick:RemoveListener(self.callback_UseDrugBtn)
	self.callback_UseDrugBtn = nil

	controls.m_AddDrugBtn.onClick:RemoveListener(self.callback_AddrugBtn)
	self.callback_AddrugBtn = nil
	
	rktEventEngine.UnSubscribeExecute(EVENT_FREEZE_START, SOURCE_TYPE_FREEZE, 0, self.callback_OnExecuteEventFreezeStart)
	self.callback_OnExecuteEventFreezeStart = nil
	
	if self.timer_CD then
		rktTimer.KillTimer( self.callback_OnTimerCoolDown )
		self.timer_CD = nil
    end
	
	self.m_CoolInfo = nil
	
    UIWindow.OnDestroy(self)
end

function TameWindow:RefreshUI()
	if self:isLoaded() then
		self:ShowUI()
	else
		self.m_NeedUpdate = true
	end
end

-- 设置界面信息
function TameWindow:ShowTameInfo(curPower, maxPower, time, crit)
	self.m_curPower = curPower
	self.m_maxPower = maxPower
	self.m_time = time
	self.m_crit = crit
	
	self:RefreshUI()
end

function TameWindow:ShowUI()
	local controls = self.Controls
	controls.m_Crit.gameObject:SetActive(false)
	if self.m_crit then
		controls.m_Crit.gameObject:SetActive(true)
		self.m_CritTweenAnim:DORestart(true)
	end
	
	controls.m_PowerSlider.maxValue = self.m_maxPower
	controls.m_PowerSlider.minValue = 0
	
	controls.m_PowerSlider.value = self.m_curPower
	
	controls.m_PowerTxt.text = string.format("耐力%d/%d", self.m_curPower, self.m_maxPower)
	controls.m_TimeTxt.text = string.format("剩余时间：%d", self.m_time)
end

function TameWindow:OnAddPower()
	local tick = luaGetTickCount()
	if tick - self.m_lastClickTime < 100 then
		return
	end
	
	GameHelp.PostServerRequest("Request_TameAddPower()")
	self.m_lastClickTime = tick
end

function TameWindow:OnUseDrug()
	if self.m_CoolInfo then
		return
	end
	
	local curDrugID = self.m_curDrugID
	if curDrugID > 0 then
		IGame.SkepClient:ShortCutUseGoods(curDrugID)
	end
end

function TameWindow:OnAddDrug()
	IGame.LifeSkillClient:SetDefaultSkillID(emCook)
	UIManager.PlayerSkillWindow:ShowWindow("TAB_TYPE_LIFESKILL")
end

function TameWindow:OnTimerCoolDown()
	local leftAmount = 0
	local CoolInfo = self.m_CoolInfo
	if CoolInfo then
		CoolInfo.LeftTime = CoolInfo.TotalTime - (Time.realtimeSinceStartup - CoolInfo.StartTime)*1000
		if CoolInfo.LeftTime > 0 then
			leftAmount = CoolInfo.LeftTime / CoolInfo.TotalTime
		else
			self.m_CoolInfo = nil
			if self.timer_CD then
				rktTimer.KillTimer( self.callback_OnTimerCoolDown )
				self.timer_CD = nil
			end
		end
	end
	
	self.Controls.m_UseDrugBtn.enabled = leftAmount == 0
	
	self.Controls.m_CoolImg.fillAmount = leftAmount
	
	self:SetCurDrug()
end

function TameWindow:OnExecuteEventFreezeStart(msg)
	local nGoodsID = msg.dwFreezeID
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodsID)
	if schemeInfo == nil then
		return
	end
	
	if schemeInfo.lGoodsSubClass ~= TAMEDRUG_TYPE then
		return
	end
		
	local freezeTime = msg.dwFreezeTime
	
	-- 如果之前没有定时器，现在有，那么就要开启一个
	if self.timer_CD == nil then
		rktTimer.SetTimer( self.callback_OnTimerCoolDown , REFRESH_TIMER_LANG , -1 , "TameWindow:OnExecuteEventFreezeStart()" )
		self.timer_CD = true
	end
	
	self.m_CoolInfo = {TotalTime = freezeTime,LeftTime = freezeTime,StartTime = Time.realtimeSinceStartup}
end

function TameWindow:LoadTameDrugConfig()
	local pTmpTable = IGame.rktScheme:GetSchemeTable(LIFESKILLTAMEDRUG_CSV)
	if not pTmpTable then
		uerror("TameWindow:LoadTameDrugConfig，配置文件LifeSkillTameDrug.csv不存在")
		return
	end
	
	local drugs = {}
	for k, v in pairs(pTmpTable) do
		local nGoodsID = v.nGoodsID
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodsID)
		if schemeInfo then
			local info = {nGoodsID = nGoodsID, nPower = v.nPower, nLimitLevel = schemeInfo.lAllowLevel}
			table.insert(drugs, info)
		else
			uerror("Leechdom.csv物品不存在，ID:" .. nGoodsID)
		end
	end
	
	if table_count(drugs) == 0 then
		uerror("TameWindow:LoadTameDrugConfig 驯马药没有配置！")
		return
	end
	
	local heroLevel = GameHelp:GetHeroLevel()
	table.sort(drugs, function(a, b)
		if a.nLimitLevel >= heroLevel and b.nLimitLevel >= heroLevel then
			return a.nPower > b.nPower
		end
		
		return a.nLimitLevel < b.nLimitLevel
	end)
	
	self.m_tameDrug = drugs
end

function TameWindow:GetBestDrug()
    local heroLevel = GameHelp:GetHeroLevel()
    for index, info in pairs(self.m_tameDrug) do
		if heroLevel >= info.nLimitLevel then
			local goodsID = info.nGoodsID
			if IGame.SkepClient:FindGoodsInPackage(goodsID) then
				return goodsID
			end
		end
	end
	
	return 0
end

function TameWindow:SetCurDrug()
	local controls = self.Controls
	local curDrugID = self:GetBestDrug()
	if curDrugID ~= 0 then
		controls.m_AddDrugBtn.gameObject:SetActive(false)
		controls.m_UseDrugBtn.enabled = true
		
		local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
		local num = packetPart:GetGoodNum(curDrugID)
		controls.m_TextDrugNum.text = tostring(num)
	else
		if self.timer_CD then
			rktTimer.KillTimer( self.callback_OnTimerCoolDown )
			self.timer_CD = nil
		end
		controls.m_AddDrugBtn.gameObject:SetActive(true)
		controls.m_UseDrugBtn.enabled = false
		controls.m_TextDrugNum.text = ""
		curDrugID = self.m_tameDrug[1].nGoodsID
		self.Controls.m_CoolImg.fillAmount = 1
	end
	
	local scheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, curDrugID)
	if not scheme then
		uerror("Leechdom.csv物品不存在，ID:" .. curDrugID)
		return
	end
					
	UIFunction.SetImageSprite(controls.m_DrugImg, AssetPath.TextureGUIPath..scheme.lIconID1)
	self.m_curDrugID = curDrugID
end

return TameWindow