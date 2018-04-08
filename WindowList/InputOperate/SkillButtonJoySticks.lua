--/******************************************************************
--** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	张杰
--** 日  期:	2017-02-28
--** 版  本:	1.0
--** 描  述:	移动用虚拟摇杆
--** 应  用:  
--******************************************************************/

local SkillUITargetClass = require("GuiSystem.WindowList.InputOperate.SkillButtonInteraction.SkillUITarget")
local QingGongController = require ("Client.Controller.QingGongController")
local statement = require("Client.SkillClient.Statement")

local interval = 30
local cooldown_effect_min_time = 500
local cooldown_text_min_time = 1000
local jump_button_id = 8
local tweenerDuration = 0.01

--目前可以显示轮盘的普通技能joyStickID
local canShowThumbID = {3,4,5,6}
local iconNameToIndex = {
	HeadIcon_1 = 1,
	HeadIcon_2 = 2,
	HeadIcon_3 = 3,
}
------------------------------------------------------------
local SkillButtonJoySticks = UIControl:new
{
	windowName = "SkillButtonJoySticks",
	
	-- 配置按钮id转成self.Controls按钮编号
	configButtonMap = {[1] = 0, [2] = 1, [3] = 2, [4] = 3, [5] = 4, [6] = 5, [7] = 6,},
	
	-- 事件id转成self.Controls按钮编号
	EventIDMap = {[2] = 0, [3] = 1, [4] = 2, [5] = 3, [6] = 4, [7] = 5, [8] = 6,},

	-- 冷却id -> 按钮编号
	freezeMap = {},
	
	-- 正在冷却的按钮编号
	coolingButton = {},
	
	-- 按钮id -> 技能id
	skillMap = {},
	
	-- [技能id] = 计数
	-- 技能id引用计数，用于外部禁用某个技能按钮，引用计数降至0时，该技能解除禁止，否则技能不可用
	skillReferenceCount = {},
    
    -- [技能id] = {外部原因字符串1, 外部原因字符串2}
    -- 技能id引用计数，用于外部禁用某个技能按钮，引用计数降至0时，该技能解除禁止，否则技能不可用
    -- 记录因某些外部原因不能发起的技能，比如某些技能需要召唤物存在时才能使用
    skillReferenceCountFromExternals = {},

	m_IsVisible = false, -- 是否显示界面
	
	-- 正在显示环形光圈的按钮编号
	ringEffect = {},
	
	-- 当前状态  1-技能状态   2-轻功状态
	State = 1,
    
    -- 禁用轻功状态的原因。决定了点击按钮时，是执行跳跃，还是执行轻功
    -- 如果禁用轻功状态，则当前显示的图标是跳跃图标，否则是轻功图标。
    QingGongForbidStatusReason = {},
    
    -- 无法使用轻功的原因。决定了点击按钮时，使用轻功能否成功
    -- 如果有无法使用的原因，则轻功图标上要显示禁止标记
    QingGongForbidUseReason = {},
    
    -- 技能区域显示方案
    SkillAreaPlan = gSkillAreaPlan.Normal,
}

------------------------------------------------------------
function SkillButtonJoySticks:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.QingGongUpCB = function() self:OnQingGongUpBtnClick() end
	self.Controls.m_QingGongBtn_Up.onClick:AddListener(self.QingGongUpCB)
	self.QingGongDownCB = function() self:OnQingGongDownBtnClick() end
	self.Controls.m_QingGongBtn_Down.onClick:AddListener(self.QingGongDownCB)
	
	self.QingGongAnimation = self.Controls.skillbutton_6:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	self.PuGongAnimation = self.Controls.skillbutton_0:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	
	
    self.m_callbackOnJoyStickPointDown = function( id ) self:OnJoyStickPointDown(id) end
    self.m_callbackOnJoyStickPointUp = function( id ) self:OnJoyStickPointUp(id) end
	
	self.m_callbackOnGuaJiPointUp = function( ) self:OnExcetGuaJiButtonUp() end
	self.ChangeSkillBtnCB = function() self:OnChangeSkillBtnClick() end
	self.ButtonScriptChche = {}
	self.ButtonComChache = {}
	
	--施法目标脚本缓存
	self.SkillUITarget = SkillUITargetClass:new()
	self.SkillUITarget:Attach(self.Controls.m_SkillUITarget.gameObject)
	
	--鼠标移入，移除响应事件
	self.OnPointEnterCB = function(eventData) self:OnPointerEnter(eventData) end
	self.OnPointExitCB = function(eventData) self:OnPointerExit(eventData) end
	
	self.SkillUITarget:SetPointEnterCB(self.OnPointEnterCB)
	self.SkillUITarget:SetPointExitCB(self.OnPointExitCB)
	
	self.CurEnterIndex = nil
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	self.Vocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
	
    for i = 0, 6 do
        local joyStick = self.Controls["skillbutton_"..i]:GetComponent(typeof(rkt.UIJoyStick))
		local buttonCom = self.Controls["skillbutton_"..i]:GetComponent(typeof(Button))
        if nil ~= joyStick then
            self.Controls["m_JoyStick_"..i] = joyStick
            joyStick.onPointDown:AddListener( self.m_callbackOnJoyStickPointDown )
            joyStick.onPointUp:AddListener( self.m_callbackOnJoyStickPointUp )
			
			local button = UIControl:new({windowName = "button"})
			button:Attach(self.Controls["skillbutton_"..i].gameObject)
			self.Controls["m_Button_"..i] = button
			if joyStick.JoyStickID == NormalAttackID then
				self.NormalAttackBtn = button
			end
			if nil ~= buttonCom then
				table.insert(self.ButtonScriptChche, joyStick.JoyStickID, button)
				if joyStick.JoyStickID ~= NormalAttackID then
					buttonCom.onClick:AddListener(function() self:OnSkillBtnClick(joyStick.JoyStickID) end)
					table.insert(self.ButtonComChache, joyStick.JoyStickID, buttonCom)
				end
			end
        end
    end
	
	--订阅设置修改
	self.OnSettingChangeCB = function() self:OnSettingChange() end
	rktEventEngine.SubscribeExecute(EVENT_SETTING_CHANGESETTING, SOURCE_TYPE_SYSTEM, 0,self.OnSettingChangeCB)

	-- 冷却相关事件
	self.callback_OnExecuteEventFreezeStart = function(event, srctype, srcid, msg) self:OnExecuteEventFreezeStart(msg) end
	self.callback_OnExecuteEventFreezeEnd = function(event, srctype, srcid, msg) self:OnExecuteEventFreezeEnd(msg) end
	self.callback_OnExecuteEventSkillButtonRefresh = function(event, srctype, srcid, msg) self:OnExecuteEventSkillButtonRefresh(msg) end 
	rktEventEngine.SubscribeExecute(EVENT_FREEZE_START, SOURCE_TYPE_FREEZE, 0, self.callback_OnExecuteEventFreezeStart)
	rktEventEngine.SubscribeExecute(EVENT_FREEZE_END, SOURCE_TYPE_FREEZE, 0, self.callback_OnExecuteEventFreezeEnd)
	rktEventEngine.SubscribeExecute(EVENT_HERO_SKILL_BUTTON_REFRESH, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventSkillButtonRefresh)
	
	-- 禁止技能相关事件
	self.callback_OnExecuteEventForbidSkillBegin = function(event, srctype, srcid, msg) self:OnExecuteEventForbidSkillBegin(msg) end
	self.callback_OnExecuteEventForbidSkillEnd = function(event, srctype, srcid, msg) self:OnExecuteEventForbidSkillEnd(msg) end
	self.callback_OnExecuteEventOnlyEnableSkillBegin = function(event, srctype, srcid, msg) self:OnExecuteEventOnlyEnableSkillBegin(msg) end
	self.callback_OnExecuteEventOnlyEnableSkillEnd = function(event, srctype, srcid, msg) self:OnExecuteEventOnlyEnableSkillEnd(msg) end
	rktEventEngine.SubscribeExecute(EVENT_FORBID_SOME_SKILL_BEGIN, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventForbidSkillBegin)
	rktEventEngine.SubscribeExecute(EVENT_FORBID_SOME_SKILL_END, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventForbidSkillEnd)
	rktEventEngine.SubscribeExecute(EVENT_ONLY_ENABLE_SOME_SKILL_BEGIN, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventOnlyEnableSkillBegin)
	rktEventEngine.SubscribeExecute(EVENT_ONLY_ENABLE_SOME_SKILL_END, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventOnlyEnableSkillEnd)

	--使用技能成功
	self.UseSkillSuccessCB = function(_,_,_,skillID) self:PlaySkillUseSuccessEffect(skillID) end
	rktEventEngine.SubscribeExecute(EVENT_SKILL_USE_SUCCESS, SOURCE_TYPE_SYSTEM, 0, self.UseSkillSuccessCB)
	
	self.callback_OnTimerCoolDown = function() self:OnTimerCoolDown() end
	
	rktEventEngine.FireExecute(EVENT_SKILL_JOYSTICK_WINDOW_ATTACH, SOURCE_TYPE_SYSTEM, 0)
	
	-- 挂机
	local skillGuaJiButton = self.Controls["skillGuaJi"]:GetComponent(typeof(Button))
	self.Controls["m_skillGuaJiButton"] = skillGuaJiButton
	skillGuaJiButton.onClick:AddListener( self.m_callbackOnGuaJiPointUp )
	self.callback_OnExecuteGuaJiStateRefesh = function(event, srctype, srcid, msg) self:OnExecuteEventGuaJiStateRefesh(msg) end
	rktEventEngine.SubscribeExecute(EVENT_GUAJI_STATE_REFRESH, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteGuaJiStateRefesh)
	
	-- 连招提示事件
	self.callback_OnExecuteEventComboHint = function(event, srctype, srcid, msg) self:OnExecuteEventComboHint(msg) end
	rktEventEngine.SubscribeExecute(EVENT_COMBO_HINT_ON_BUTTON, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventComboHint)
	self.callback_OnTimerRingEffect = function() self:OnTimerRingEffect() end
    
    -- 跳跃按钮的点击缩放效果
    self.Controls.m_JumpClickAnimation = self.Controls.skillbutton_6:GetComponent(typeof(Button)).gameObject:GetComponent(typeof(rkt.ButtonClickAnimation))
	
	--修改技能流派按钮
	self.Controls.m_ChangeSkillBtn.onClick:AddListener(self.ChangeSkillBtnCB)
	
	-- 战斗状态改变
	self.callback_OnExecuteEventBattleStateChange = function(event, srctype, srcid, msg) self:OnBattleStateChange(msg) end
	rktEventEngine.SubscribeExecute(EVENT_PK_STATE_SWITCH, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventBattleStateChange)
    
    -- 主角升级
    self.callback_OnExecuteEventHeroUpgrade = function() self:OnHeroUpgrade() end
    rktEventEngine.SubscribeExecute(EVENT_PERSON_UPGRADE, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventHeroUpgrade)
    
    -- 荒岛求生玩法的药品按钮
    self.PubgLeechdomButtonCB = function() self:OnPubgLeechdomButtonClicked() end
    self.Controls.m_Pubg_LeechdomButton.onClick:AddListener(self.PubgLeechdomButtonCB)
	
	-- 更新界面显示
	self:UpdateVisible()
    
    -- 更新轻功气力值
    self:UpdateQingGongStrengthOnAttach()
    
    -- 更新跳跃按钮点击动画
    self:RefreshJumpClickAnimation()
    
    -- 召唤物技能发起条件
    self:SubscribeEnableOnSummonEvent()
    
    -- 轻功按钮显示状态
    self:CheckQingGongButtonImageRefreshOnAttach()
    
    -- 根据技能方案刷新显示
    self:RefreshUIOnSkillAreaPlan()

	return self
end

-- 召唤物技能发起条件
function SkillButtonJoySticks:SubscribeEnableOnSummonEvent()
    self.callback_OnExecuteEventPawnAdd = function(event, srctype, srcid, msg) self:OnExecuteEventPawnAdd(msg) end
    rktEventEngine.SubscribeExecute(EVENT_PERSON_PAWNADDPET, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventPawnAdd)
    self.callback_OnExecuteEventPawnKill = function(event, srctype, srcid, msg) self:OnExecuteEventPawnKill(msg) end
    rktEventEngine.SubscribeExecute(EVENT_PERSON_PAWNKILLPET, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventPawnKill)
end

-- 召唤物技能发起条件
function SkillButtonJoySticks:UnsubscribeEnableOnSummonEvent()
    rktEventEngine.UnSubscribeExecute(EVENT_PERSON_PAWNADDPET, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventPawnAdd)
    self.callback_OnExecuteEventPawnAdd = nil
    rktEventEngine.UnSubscribeExecute(EVENT_PERSON_PAWNKILLPET, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventPawnKill)
    self.callback_OnExecuteEventPawnKill = nil
end

------------------------------------------------------------
function SkillButtonJoySticks:OnJoyStickPointDown( id )
    if self:IsCooling(self.EventIDMap[id]) and not GetHero():IsQingGonging() then
        if id ~= jump_button_id then -- 非跳跃按钮，提示冷却
            self:CoolDownHint()
        elseif not QingGongController:CanSwitchToQingGong() then -- 跳跃按钮，如果不能发起轻功，则提示冷却，能发起轻功，就不提示
            self:CoolDownHint()
        end
        
        return
    end
    
    local skillID = self.skillMap[id]
	if id == NormalAttackID then -- 普攻
		rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_DOWN , 0 , id , skillID)
		if self:IsForbiddenByReferenceCount(skillID) or self:IsForbiddenByReferenceCountFromExternals(skillID) then
            return -- 屏蔽点击
        end
        
		self:PlayCommonAttackClickEffect(self.NormalAttackBtn.Controls.m_EffectParent)
	else -- 非普攻	
		if id == jump_button_id then
			if self.State == 2 then
				-- 轻功状态下，点击跳跃按钮，则发送轻功事件
				rktEventEngine.FireExecute( EVENT_JOY_STICK_POINT_DOWN , 0 , JOY_STICK_ID.QingGong_Segment_Normal)
			elseif self.State == 1 then
                -- 技能状态下，点击跳跃按钮，则走技能流程，在技能流程里判断是否切换为轻功状态
                self:OnNormalSkillPointerDown(id)
			end
		else
			self:OnNormalSkillPointerDown(id)
		end					
	end
end
------------------------------------------------------------
function SkillButtonJoySticks:OnJoyStickPointUp( id )
	if self:IsCooling(self.EventIDMap[id]) then
		return
	end
	if id == NormalAttackID then
		rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_UP , 0 , id , {manualCast = false, skill_id = self.skillMap[id]})
	else
		self:OnNormalSkillPointerUp(id)								
	end
end
------------------------------------------------------------
--技能button点击触发技能方式
function SkillButtonJoySticks:OnSkillBtnClick(id)
    local skillID = self.skillMap[id]
    if self:IsForbiddenByReferenceCountFromExternals(skillID) then -- 外部条件禁用的技能，不响应
        self:NotifyMessageOnForbiddenByReferenceCountFromExternals(skillID)
        return
    end
    
	if not rkt.UIJoyStick.IsShowThumb( self.Controls["m_JoyStick_"..self.EventIDMap[id]].JoyStickID ) then
		rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_DOWN , 0 , id , skillID)
		rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_UP , 0 , id , {manualCast = false, skill_id = skillID})
	end
end

-- 外部技能禁用提示
function SkillButtonJoySticks:NotifyMessageOnForbiddenByReferenceCountFromExternals(skillID)
    local extendedScheme = IGame.SkillClient:GetSkillScheme(skillID, 1, 1)
    if extendedScheme ~= nil and extendedScheme.preskill_message_hint_id ~= nil then
        local preskillScheme = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, extendedScheme.preskill_message_hint_id, 1, 1)
        if preskillScheme ~= nil then
            IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先使用前置技能"..preskillScheme.Name)        
        end
    end
end

--技能使用成功播放特效
function SkillButtonJoySticks:PlaySkillUseSuccessEffect(skillID)
	local id
	for i, data in pairs(self.skillMap) do
		if data == skillID then
			id = i
			break
		end
	end
	
	if not id or id == NormalAttackID then return end
	self:PlaySkillClickEffect(self.ButtonScriptChche[id].Controls.m_EffectParent)
end
------------------------------------------------------------
function SkillButtonJoySticks:OnDestroy()
	
    UIControl.OnDestroy(self)
	self.CurEnterIndex = nil
	
	rktEventEngine.UnSubscribeExecute(EVENT_SETTING_CHANGESETTING, SOURCE_TYPE_SYSTEM, 0,self.OnSettingChangeCB)

	rktEventEngine.UnSubscribeExecute(EVENT_FREEZE_START, SOURCE_TYPE_FREEZE, 0, self.callback_OnExecuteEventFreezeStart)
	rktEventEngine.UnSubscribeExecute(EVENT_FREEZE_END, SOURCE_TYPE_FREEZE, 0, self.callback_OnExecuteEventFreezeEnd)
	rktEventEngine.UnSubscribeExecute(EVENT_HERO_SKILL_BUTTON_REFRESH, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventSkillButtonRefresh)
	self.callback_OnExecuteEventFreezeStart = nil
	self.callback_OnExecuteEventFreezeEnd = nil
	self.callback_OnExecuteEventSkillButtonRefresh = nil
	
	rktEventEngine.UnSubscribeExecute(EVENT_FORBID_SOME_SKILL_BEGIN, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventForbidSkillBegin)
	rktEventEngine.UnSubscribeExecute(EVENT_FORBID_SOME_SKILL_END, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventForbidSkillEnd)
	rktEventEngine.UnSubscribeExecute(EVENT_ONLY_ENABLE_SOME_SKILL_BEGIN, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventOnlyEnableSkillBegin)
	rktEventEngine.UnSubscribeExecute(EVENT_ONLY_ENABLE_SOME_SKILL_END, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventOnlyEnableSkillEnd)
	
	rktEventEngine.UnSubscribeExecute(EVENT_SKILL_USE_SUCCESS, SOURCE_TYPE_SYSTEM, 0, self.UseSkillSuccessCB)	

	self.UseSkillSuccessCB = nil
	self.callback_OnExecuteEventForbidSkillBegin = nil
	self.callback_OnExecuteEventForbidSkillEnd = nil
	self.callback_OnExecuteEventOnlyEnableSkillBegin = nil
	self.callback_OnExecuteEventOnlyEnableSkillEnd = nil
	
	rktTimer.KillTimer(self.callback_OnTimerCoolDown)
	self.callback_OnTimerCoolDown = nil

	rktEventEngine.UnSubscribeExecute(EVENT_COMBO_HINT_ON_BUTTON, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExecuteEventComboHint)
	
	rktTimer.KillTimer(self.callback_OnTimerRingEffect)
	self.callback_OnTimerRingEffect = nil
	
	rktEventEngine.UnSubscribeExecute(EVENT_PK_STATE_SWITCH, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventBattleStateChange)
	self.callback_OnExecuteEventBattleStateChange = nil
    
    rktEventEngine.UnSubscribeExecute(EVENT_PERSON_UPGRADE, SOURCE_TYPE_PERSON, 0, self.callback_OnExecuteEventHeroUpgrade)
    self.callback_OnExecuteEventHeroUpgrade = nil
    
    -- 召唤物技能发起条件
    self:UnsubscribeEnableOnSummonEvent()
end
------------------------------------------------------------
function SkillButtonJoySticks:FindButtonIDBySkillID(skillID)
	local id = 0
	for i,v in pairs(self.skillMap) do
		if v == skillID then
			id = i
			break
		end
	end
	
	if id == 0 then
		return
	end
	
	return self.EventIDMap[id]
end
------------------------------------------------------------
function SkillButtonJoySticks:OnExecuteEventFreezeStart(msg)
	local freezeID = msg.dwFreezeID
	local freezeTime = msg.dwFreezeTime
	local bTrigger = msg.bTrigger
	local skill_original_id = msg.skill_original_id
	local buttonID = self.freezeMap[freezeID]
	if not buttonID then
		-- 查找原始技能ID
		if skill_original_id == nil then
			return
		end
		
		buttonID = self:FindButtonIDBySkillID(skill_original_id)
		if not buttonID then
			return
		end
	end
	
	local hasCooling = self:HasCooling()
	local newCooling = false
	local button = self.Controls["m_Button_"..buttonID]
	if freezeTime > cooldown_effect_min_time then -- 少于500毫秒的不需要启动冷却光圈
		newCooling = true
		self.coolingButton[buttonID] = {freezeTime = freezeTime, beginTick = luaGetTickCount()}
		button.Controls.m_SkillCDImg.gameObject:SetActive(true)
		button.Controls.m_SkillCDImg.fillAmount = 1
		
		if freezeTime > cooldown_text_min_time then -- 少于1秒的不需要显示文字
			button.Controls.m_SkillCDTime.gameObject:SetActive(true)
			button.Controls.m_SkillCDTime.text = math.floor(freezeTime / 1000)
		else
			button.Controls.m_SkillCDTime.gameObject:SetActive(false)
		end
	elseif bTrigger then
		self.coolingButton[buttonID] = nil
		button.Controls.m_SkillCDImg.gameObject:SetActive(false)
		button.Controls.m_SkillCDTime.gameObject:SetActive(false)
	end
	
	-- 如果之前没有定时器，现在有，那么就要开启一个
	if not hasCooling and newCooling then
		rktTimer.KillTimer(self.callback_OnTimerCoolDown)
		rktTimer.SetTimer(self.callback_OnTimerCoolDown, interval, -1, "SkillButtonJoySticks:OnExecuteEventFreezeStart")
	end
	
	-- 如果开启了冷却光圈，并且是独立冷却而不是关联冷却，就不需要环形光圈了
	if bTrigger then
		self:HideRingEffect(buttonID)
	end
end
------------------------------------------------------------
function SkillButtonJoySticks:OnExecuteEventFreezeEnd(msg)
	local freezeID = msg.dwFreezeID
	local freezeTime = msg.dwFreezeTime
	local buttonID = self.freezeMap[freezeID]
	if not buttonID then
		return
	end
	
	if freezeTime <= cooldown_effect_min_time then
		return
	end
	
    local needHideEffect = false
    if GetHero():IsQingGonging() then
        needHideEffect = true -- 轻功飞行状态，不播放结束光效
    elseif not self:IsForbidQingGongStatus() then
        needHideEffect = true -- 轻功允许状态，不播放结束光效
    end
    
	if self.coolingButton[buttonID] and not needHideEffect then
		self:PlaySkillCoolOverEffect(self.Controls["m_Button_"..buttonID].Controls.m_EffectParent)
	end
	
	self.coolingButton[buttonID] = nil
	local button = self.Controls["m_Button_"..buttonID]
	button.Controls.m_SkillCDImg.gameObject:SetActive(false)
	button.Controls.m_SkillCDTime.gameObject:SetActive(false)
	
	-- 如果没有冷却了，就可以关掉这个定时器
	if not self:HasCooling() then
		rktTimer.KillTimer(self.callback_OnTimerCoolDown)
	end
end
------------------------------------------------------------
function SkillButtonJoySticks:OnExecuteEventSkillButtonRefresh(msg)
    self:CheckEnableOnOtherConditions()
    
	local scheme = IGame.rktScheme:GetSchemeInfo(SKILLBUTTON_CSV, msg.voc, msg.index)
	if not scheme then
		return
	end
    
    local heroLevel = 1
    local hero = GetHero()
    if hero then
        heroLevel = hero:GetNumProp(CREATURE_PROP_LEVEL)
    end

	local skillList = msg.totalSkillList
	local configButtonMap = self.configButtonMap
	self.freezeMap = {}
	self.skillMap = {}
	local freezeMap = self.freezeMap
	local skillMap = self.skillMap
	
	for i = 1, 7 do
		local buttonIndex = configButtonMap[i]
		local buttonExist = false
		
		-- 先全部隐藏
		if buttonIndex ~= nil and self.Controls["m_Button_"..buttonIndex] ~= nil then
			buttonExist = true
			local button = self.Controls["m_Button_"..buttonIndex]
			button.Controls.m_LockImage.gameObject:SetActive(true)
			button.Controls.m_SkillIcon.gameObject:SetActive(true)
			button.Controls.m_SkillCDTime.gameObject:SetActive(false)
			button.Controls.m_SkillCDTime.text = ""
			button.Controls.m_SkillCDImg.gameObject:SetActive(false)
			button.Controls.m_SkillCDImg.fillAmount = 0
			button.Controls.m_StudyLevel.gameObject:SetActive(true)
			button.Controls.m_UnlearnImage.gameObject:SetActive(true)
			button.Controls.m_RingImage.gameObject:SetActive(false)
			self.Controls["m_JoyStick_"..buttonIndex].enabled = false
		end
		
        -- 找出当前Button位置配置的技能id
		local skill_learned = false
        local skillID = self:GetSkillIDFromSkillButtonScheme(scheme, i)
		if skillID ~= nil and skillID > 0 then
			local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, skillID, 1)
			local skillScheme = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, skillID, 1, 1)
			if skillScheme ~= nil and skillUpdateScheme ~= nil and GameHelp.IsMainSkill(skillScheme.SkillClass) and buttonExist then
				for j,k in pairs(self.EventIDMap) do
					if k == buttonIndex and skillID > 0 then
						skillMap[j] = skillID
						break
					end
				end
				
				local button = self.Controls["m_Button_"..buttonIndex]
				UIFunction.SetImageSprite(button.Controls.m_SkillIcon, AssetPath.TextureGUIPath..skillUpdateScheme.Icon)
				if skillList[skillID] ~= nil and skillList[skillID] > 0 and heroLevel >= skillUpdateScheme.NeedLevel then
                    skill_learned = true
					self.Controls["skillbutton_"..buttonIndex].gameObject:SetActive(true)
					button.Controls.m_LockImage.gameObject:SetActive(false)
					button.Controls.m_SkillIcon.gameObject:SetActive(true)
					button.Controls.m_SkillCDTime.gameObject:SetActive(true)
					button.Controls.m_UnlearnImage.gameObject:SetActive(false)
					button.Controls.m_StudyLevel.gameObject:SetActive(false)
					self.Controls["m_JoyStick_"..buttonIndex].enabled = true
				else
                    -- 如果没学会技能，要根据当前的技能方案来确定如何显示界面。其中，常规方案不需要额外处理。
                    if self.SkillAreaPlan == gSkillAreaPlan.Pubg then
                        button.Controls.m_SkillIcon.gameObject:SetActive(false)
                        button.Controls.m_StudyLevel.gameObject:SetActive(false)
                        button.Controls.m_UnlearnImage.gameObject:SetActive(false)
                    end
                end
				
				if skillScheme.CoolDown > 0 then
					freezeMap[skillScheme.CoolDown] = buttonIndex
				end
                
				button.Controls.m_StudyLevel.text = string.format("%d级",skillUpdateScheme.NeedLevel)
			end
		else
            -- 如果没学会技能，要根据当前的技能方案来确定如何显示界面。其中，常规方案不需要额外处理。
            if self.SkillAreaPlan == gSkillAreaPlan.Pubg then
                local button = self.Controls["m_Button_"..buttonIndex]
                button.Controls.m_SkillIcon.gameObject:SetActive(false)
                button.Controls.m_StudyLevel.gameObject:SetActive(false)
                button.Controls.m_UnlearnImage.gameObject:SetActive(false)
            end
        end
		
		-- 跳跃
		if i == 7 and buttonExist and not skill_learned then
			local button = self.Controls["m_Button_"..buttonIndex]
			button.Controls.m_LockImage.gameObject:SetActive(false)
			UIFunction.SetImageSprite(button.Controls.m_SkillIcon, AssetPath.TextureGUIPath.."Main_mainUI/Main_jn_qinggong.png")			
			button.Controls.m_SkillIcon.gameObject:SetActive(true)
			button.Controls.m_SkillCDTime.gameObject:SetActive(false)
			button.Controls.m_SkillCDTime.text = ""
			button.Controls.m_SkillCDImg.gameObject:SetActive(false)
			button.Controls.m_SkillCDImg.fillAmount = 0
			button.Controls.m_StudyLevel.gameObject:SetActive(false)
			button.Controls.m_UnlearnImage.gameObject:SetActive(true)
			self.Controls["m_JoyStick_"..buttonIndex].enabled = false
			if skillID and skillID > 0 then
				local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, skillID, 1)
				if skillUpdateScheme then
					button.Controls.m_StudyLevel.text = string.format("%d级", skillUpdateScheme.NeedLevel)
				end
			end
		end
		
		-- 绝技
		if i == 6 and buttonExist and not skill_learned then
            if self.SkillAreaPlan == gSkillAreaPlan.Normal then -- 常规方案，绝技没学会时要隐藏
                self.Controls["skillbutton_"..buttonIndex].gameObject:SetActive(false)
                local button = self.Controls["m_Button_"..buttonIndex]
                button.Controls.m_SkillIcon.gameObject:SetActive(false)
            elseif self.SkillAreaPlan == gSkillAreaPlan.Pubg then -- 荒野求生方案，绝技没学会时要显示出来
                self.Controls["skillbutton_"..buttonIndex].gameObject:SetActive(true)
                local button = self.Controls["m_Button_"..buttonIndex]
                button.Controls.m_SkillIcon.gameObject:SetActive(false)
                button.Controls.m_StudyLevel.gameObject:SetActive(false)
                button.Controls.m_UnlearnImage.gameObject:SetActive(false)
            end
		end
	end
    
    -- 刷新轮盘状态
    for i = 1, 7 do
		local buttonIndex = configButtonMap[i]
        self:RefreshThumbState(buttonIndex)
    end
	
	self:CheckQingGongButtonImageRefreshOnAttach()
end
--------------------------------------------------------------
function SkillButtonJoySticks:HasCooling()
	for i,v in pairs(self.coolingButton) do
		if v then
			return true
		end
	end
	
	return false
end

function SkillButtonJoySticks:IsCooling(buttonID)
	if self.coolingButton[buttonID] == nil then 
		return false
	end
	return true
end
--------------------------------------------------------------
function SkillButtonJoySticks:OnTimerCoolDown()
	local hasCooling = false
	for i,v in pairs(self.coolingButton) do
		local button = self.Controls["m_Button_"..i]
		local passedTick = luaGetTickCount() - v.beginTick
		local leftAmount = 1 - passedTick / v.freezeTime
		button.Controls.m_SkillCDImg.fillAmount = leftAmount
		
		if leftAmount < 0 then
			button.Controls.m_SkillCDImg.fillAmount = 0
			self.coolingButton[i] = nil
		else
			hasCooling = true
			if not button.Controls.m_SkillCDImg.gameObject.activeInHierarchy then 
				button.Controls.m_SkillCDImg.gameObject:SetActive(true)
			end
		end
		
		local leftTime = math.ceil(v.freezeTime * button.Controls.m_SkillCDImg.fillAmount / 1000)
		if leftTime <= 0 then
			leftTime = 0
			button.Controls.m_SkillCDTime.text = 0
			button.Controls.m_SkillCDTime.gameObject:SetActive(false)
		else
			button.Controls.m_SkillCDTime.text = leftTime
			button.Controls.m_SkillCDTime.gameObject:SetActive(true)
		end
        
        local needHideCDImg = false
        if i == 6 then
            if GetHero():IsQingGonging() then -- 轻功飞行状态下，隐藏光圈
                needHideCDImg = true
            elseif not self:IsForbidQingGongStatus() then -- 轻功状态允许时，隐藏光圈
                needHideCDImg = true
            end
        end
        
        if needHideCDImg then
            button.Controls.m_SkillCDImg.gameObject:SetActive(false)
            button.Controls.m_SkillCDTime.gameObject:SetActive(false)
        end       
	end
	
	if not hasCooling then
		rktTimer.KillTimer(self.callback_OnTimerCoolDown)
	end
end
--------------------------------------------------------------
-- 点击挂机按钮弹起
function SkillButtonJoySticks:OnExcetGuaJiButtonUp()
	if not IGame.AutoSystemManager:IsOnAutoSystem() and CommonApi:IsTrainFollow() then
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "取消跟随后将自动进入挂机状态。")
	end
	rktEventEngine.FireEvent( EVENT_GUAJI_BUTTON_UP , SOURCE_TYPE_PERSON, 0 )
end
--------------------------------------------------------------
-- 挂机状态更新
function SkillButtonJoySticks:OnExecuteEventGuaJiStateRefesh(msg)
	if not self:isLoaded() then
        return
    end
	self:RefeshGuaJiState(msg.nState)
end
--------------------------------------------------------------
-- 刷新挂机状态
function SkillButtonJoySticks:RefeshGuaJiState(nState)
	local imagePath = AssetPath.TextureGUIPath .. "Main_mainUI/Main_button_guaiji.png"
	local bActive = false
	-- 挂机状态
	if nState and nState == 1 then
		imagePath =  AssetPath.TextureGUIPath .. "Main_mainUI/Main_button_guaiji.png"
		bActive = true
	end
	self.Controls["m_guaJiStateBg"].gameObject:SetActive(bActive)
	UIFunction.SetImageSprite( self.Controls["m_guaJiIcon"] , imagePath )
	self.Controls["m_guaJiIcon"].enabled = not bActive
end
--------------------------------------------------------------
-- 禁止某些技能：开始
function SkillButtonJoySticks:OnExecuteEventForbidSkillBegin(msg)
	-- 更新引用计数
	for i,v in pairs(msg) do
		if not self.skillReferenceCount[v] then
			self.skillReferenceCount[v] = 0
		end
		
		self.skillReferenceCount[v] = self.skillReferenceCount[v] + 1
	end
	
	self:RefreshForbidSkillEffect()
end
--------------------------------------------------------------
-- 禁止某些技能：结束
function SkillButtonJoySticks:OnExecuteEventForbidSkillEnd(msg)
	-- 更新引用计数
	for i,v in pairs(msg) do
		if not self.skillReferenceCount[v] then
			self.skillReferenceCount[v] = 0
		end
		
		self.skillReferenceCount[v] = self.skillReferenceCount[v] - 1
	end
	
	self:RefreshForbidSkillEffect()
end
--------------------------------------------------------------
-- 只允许某些技能：开始
function SkillButtonJoySticks:OnExecuteEventOnlyEnableSkillBegin(msg)
	-- 所有可能使用的技能
	local allPossibleSkill = self:GetAllButtonSkill()
	for i,v in pairs(msg) do
		allPossibleSkill[v] = nil -- 把只允许使用的技能置空
	end
	
	-- 剩余的即为禁用的技能，要更新引用计数
	for i,v in pairs(allPossibleSkill) do
		if not self.skillReferenceCount[i] then
			self.skillReferenceCount[i] = 0
		end
		
		self.skillReferenceCount[i] = self.skillReferenceCount[i] + 1
	end
	
	self:RefreshForbidSkillEffect()
end
--------------------------------------------------------------
-- 只允许某些技能：结束
function SkillButtonJoySticks:OnExecuteEventOnlyEnableSkillEnd(msg)
	-- 所有可能使用的技能
	local allPossibleSkill = self:GetAllButtonSkill()
	for i,v in pairs(msg) do
		allPossibleSkill[v] = nil -- 把只允许使用的技能置空
	end
	
	-- 剩余的即为禁用的技能，要更新引用计数
	for i,v in pairs(allPossibleSkill) do
		if not self.skillReferenceCount[i] then
			self.skillReferenceCount[i] = 0
		end
		
		self.skillReferenceCount[i] = self.skillReferenceCount[i] - 1
	end
	
	self:RefreshForbidSkillEffect()
end
--------------------------------------------------------------
-- 刷新禁止技能表现
function SkillButtonJoySticks:RefreshForbidSkillEffect()
    -- 轻功状态下，不需要刷新这类表现。因为此时技能按钮都隐藏了。
    if self.State == 2 then
        return
    end
    
	local hero = GetHero()
	if not hero then
		return
	end
	
	local voc = hero:GetNumProp(CREATURE_PROP_VOCATION)
	local studySkillPart = hero:GetEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studySkillPart then
		return
	end
	
	local liuPai = studySkillPart:GetLiuPai()
	local buttonScheme = IGame.rktScheme:GetSchemeInfo(SKILLBUTTON_CSV, voc, liuPai)
	if not buttonScheme then
		return
	end
	
	local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
	if not skillPart then
		return
	end
	
	local skillList = skillPart:GetTotalSkillList()
	if not skillList then
		return
	end
	
	local configButtonMap = self.configButtonMap
	
	for i = 1, 7 do
		local buttonIndex = configButtonMap[i]
		local buttonExist = false
		if buttonIndex ~= nil and self.Controls["m_Button_"..buttonIndex] ~= nil then
			buttonExist = true
		end
		
        -- 非跳跃按钮，或者是跳跃按钮，但是处于禁用轻功状态。此时可以按照普通技能处理相关显示。
        if buttonIndex ~= 6 or self:IsForbidQingGongStatus() then
            local skillID = self:GetSkillIDFromSkillButtonScheme(buttonScheme, i)
            if skillID and skillID > 0 then
                local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, skillID, 1)
                local skillScheme = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, skillID, 1, 1)
                if skillScheme ~= nil and skillUpdateScheme ~= nil and GameHelp.IsMainSkill(skillScheme.SkillClass) and buttonExist then
                    local button = self.Controls["m_Button_"..buttonIndex]
                    button.Controls.m_UnlearnImage.gameObject:SetActive(false)
                    --UIFunction.SetImageSprite(button.Controls.m_SkillIcon, AssetPath.TextureGUIPath..skillUpdateScheme.Icon)
                    if skillList[skillID] ~= nil and skillList[skillID] > 0 then -- 已经学了该技能
                        if self:IsForbiddenByReferenceCount(skillID) then -- 判断引用计数
                            if not button.Controls.m_UnlearnImage.gameObject.activeInHierarchy or not button.Controls.m_LockImage.gameObject.activeInHierarchy then
                                button.Controls.m_ForbidImage.gameObject:SetActive(true)
                            end
                            self.Controls["m_JoyStick_"..buttonIndex].enabled = false
                        elseif self:IsForbiddenByReferenceCountFromExternals(skillID) then -- 判断外部禁用原因
                            button.Controls.m_UnlearnImage.gameObject:SetActive(true)
                            self.Controls["m_JoyStick_"..buttonIndex].enabled = false
                        else
                            button.Controls.m_ForbidImage.gameObject:SetActive(false)
                            self.Controls["m_JoyStick_"..buttonIndex].enabled = true
                        end
                    end
                end
            end
        else
            local button = self.Controls["m_Button_"..buttonIndex]
            -- 跳跃按钮，且处于轻功允许状态。此时要按照轻功处理显示。
            local QingGongManager = hero:GetQingGongManager()
            if not QingGongManager or QingGongManager:GetQingGongID() == 0 then
                button.Controls.m_UnlearnImage.gameObject:SetActive(true)
                button.Controls.m_ForbidImage.gameObject:SetActive(false)
            else
                button.Controls.m_UnlearnImage.gameObject:SetActive(false)
                if self:IsForbidQingGongUse() then
                    button.Controls.m_ForbidImage.gameObject:SetActive(true)
                else
                    button.Controls.m_ForbidImage.gameObject:SetActive(false)
                end
            end
        end
	end
end
--------------------------------------------------------------
-- 获取所有可能映射的技能id
function SkillButtonJoySticks:GetAllButtonSkill()
	local t = {}
	
	local hero = GetHero()
	if not hero then
		return t
	end
	
	local voc = hero:GetNumProp(CREATURE_PROP_VOCATION)
	for liuPai = 1, 2 do
		local buttonScheme = IGame.rktScheme:GetSchemeInfo(SKILLBUTTON_CSV, voc, liuPai)
		if buttonScheme then
			for i = 1, 7 do
				local skillID = self:GetSkillIDFromSkillButtonScheme(buttonScheme, i)
				if skillID > 0 then
					t[skillID] = 1
				end
			end
		end
	end
	
	return t
end
--------------------------------------------------------------
--=====================================================================================================================

--点击技能按钮逻辑
function SkillButtonJoySticks:OnNormalSkillPointerDown(id)
	local buttonIndex = self.EventIDMap[id]
	if rkt.UIJoyStick.IsShowThumb( self.Controls["m_JoyStick_"..buttonIndex].JoyStickID ) then					--需要显示轮盘
		--层级控制
		self:SetSibling(buttonIndex)
		if self.Vocation == PERSON_VOCATION_LINGXIN then
			if PlayerPrefs_GetBool("CureShowCureHeadIcon", false) or PlayerPrefs_GetBool("ResShowHeadIcon", false) then
				local memberInfo = self:GetSkillInfluenceMemberInfo(id)
				if memberInfo and #memberInfo > 0 then
					for i,data in pairs(self.SkillUITarget.HeadIconCache) do
						if i <= #memberInfo then
							self:SetHeadIconView(i, true, memberInfo[i])
						else
							self:SetHeadIconView(i, false)
						end
					end
				else
					for i,data in pairs(self.SkillUITarget.HeadIconCache) do
						data:Hide()
						--[[if i <= 2 then														--just for test,  need delete
							data:Show()
						else
							data:Hide()
						end--]]
					end
				end
			else
				--灵心职业，设置不显示头像，不处理
			end
		else
			--非灵心职业, 暂时无需求
			self.Controls["skillbutton_"..buttonIndex].transform:SetAsLastSibling()
			--发送按下事件
			rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_DOWN , 0 , id , self.skillMap[id])
		end
	else
		--不显示轮盘的情况下啥都不做， 技能释放放在button控件交互中
	end

end

--抬起逻辑
function SkillButtonJoySticks:OnNormalSkillPointerUp(id)
	local buttonIndex = self.EventIDMap[id]
	if not self.SkillUITarget:isShow() then
		self.CurEnterIndex = nil
		self.CurEnterName = nil
	end
    
    self.SkillUITarget:Hide()
    
    local skill_id = self.skillMap[id]
	if rkt.UIJoyStick.IsShowThumb( self.Controls["m_JoyStick_"..buttonIndex].JoyStickID ) then
		if self.Vocation == PERSON_VOCATION_LINGXIN then
			if PlayerPrefs_GetBool("CureShowCureHeadIcon", false) or PlayerPrefs_GetBool("ResShowHeadIcon", false) then
				if self.CurEnterIndex then						--检测到对应施法
					local targetPDBID = self.SkillUITarget.HeadIconCache[self.CurEnterIndex]:GetPDBID()
                    local entity = IGame.EntityClient:GetByPDBID(targetPDBID)
                    local targetUID = 0
                    if entity ~= nil then
                        targetUID = entity:GetUID()
                    end
                    
					rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_UP , 0 , id , {manualCast = true, skill_id = skill_id, targetUID = targetUID})
				else
					rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_UP , 0 , id , {manualCast = false, skill_id = skill_id})
				end
			else
				rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_UP , 0 , id , {manualCast = false, skill_id = skill_id})
			end
		else
			rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_UP , 0 , id , {manualCast = false, skill_id = skill_id})
		end
	else
--		rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_UP , 0 , id , {manualCast = false, skill_id = skill_id})
	end
    
    self.CurEnterIndex = nil
	self.CurEnterName = nil
end

--设置头像部分显示
function SkillButtonJoySticks:SetHeadIconView(index, show, memInfo)
	if show then
		self.SkillUITarget.HeadIconCache[index]:Show()
		--显示设置
		self.SkillUITarget.HeadIconCache[index]:SetPDBID(memInfo.dwPDBID)
		self.SkillUITarget.HeadIconCache[index]:SetHeadIcon(memInfo.nFaceID)
		local percent = memInfo.nCurHP/memInfo.nMaxHP
		self.SkillUITarget.HeadIconCache[index]:SetHP(percent, true)
		if memInfo.bCaptainFlag == true then
			self.SkillUITarget.HeadIconCache[index]:SetCaptain(true)
		else
			self.SkillUITarget.HeadIconCache[index]:SetCaptain(false)
		end
	else
		self.SkillUITarget.HeadIconCache[index]:Hide()
	end
end

--设置层级
function SkillButtonJoySticks:SetSibling(buttonIndex)
	self.SkillUITarget:Show()
	self.Controls["skillbutton_"..buttonIndex].transform:SetAsLastSibling()
	local siblingCount = self.Controls["skillbutton_"..buttonIndex].transform:GetSiblingIndex()
	self.SkillUITarget.transform:SetSiblingIndex(siblingCount - 1)
end

--鼠标进入事件
function SkillButtonJoySticks:OnPointerEnter(eventData)
	if not self.CurEnterIndex or not self.CurEnterName then
		self.CurEnterIndex = tonumber(iconNameToIndex[eventData.pointerEnter.name])
		self.CurEnterName = eventData.pointerEnter.name
		self.SkillUITarget:SetSelected(self.CurEnterIndex, true)
	else
		return
	end
end

--鼠标移出事件
function SkillButtonJoySticks:OnPointerExit(eventData)
	if self.CurEnterIndex and self.CurEnterName == eventData.pointerEnter.name then
		self.SkillUITarget:SetSelected(self.CurEnterIndex, false)
		self.CurEnterIndex = nil
		self.CurEnterName = nil
	end
end

--设置修改订阅事件,设置轮盘状态
function SkillButtonJoySticks:OnSettingChange()
	local configButtonMap = self.configButtonMap
	for i = 1, 7 do 
		self:RefreshThumbState(configButtonMap[i])
	end
end


--刷新是否需要显示轮盘
function SkillButtonJoySticks:RefreshThumbState(buttonIndex)
    local joyStickID = self.Controls["m_JoyStick_"..buttonIndex].JoyStickID
	local skillID = self.skillMap[joyStickID]
	if not skillID then -- 该按钮没配置对应的技能id
		rkt.UIJoyStick.SetShowThumb( joyStickID , false )
		return
	end
    
    -- 检查是否学习该技能
    local hero = GetHero()
    if not hero then
        rkt.UIJoyStick.SetShowThumb( joyStickID , false )
		return
    end
    
    local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
    if not skillPart or skillPart:GetTotalSkillLevel(skillID) <= 0 then
        rkt.UIJoyStick.SetShowThumb( joyStickID , false )
		return
    end
    
    -- 等级不够最低使用等级也不行
    local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, skillID, 1)
    if skillUpdateScheme and hero:GetNumProp(CREATURE_PROP_LEVEL) < skillUpdateScheme.NeedLevel then
        rkt.UIJoyStick.SetShowThumb( joyStickID , false )
        return
    end
    
	local contain = false
	for i, data in pairs(canShowThumbID) do
		if joyStickID == data then
			contain = true
		end
	end
    
	if not contain then
		rkt.UIJoyStick.SetShowThumb( joyStickID , false )
		return
	end
	
	if self.Vocation == PERSON_VOCATION_LINGXIN then			--灵心职业， 辅助技能 特殊处理， 
		if PlayerPrefs.GetInt("SkillRelease", 1) == 2 then 	--精确释放勾选
			local skillRecord = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, skillID,1,1)
			if skillRecord.SupportPreciseCast then				--配置表决定需要显示轮盘
				rkt.UIJoyStick.SetShowThumb( joyStickID , true )
			else
				rkt.UIJoyStick.SetShowThumb( joyStickID , false )
			end
		else--简单施法
			local skillType, record = self:CheckAssistSkill(joyStickID)
			if not skillType then			--不是辅助技能
				rkt.UIJoyStick.SetShowThumb( joyStickID , false )
			else
				if skillType == 1 then 
					if PlayerPrefs_GetBool("CureShowCureHeadIcon", false) then   --勾选治疗头像
						rkt.UIJoyStick.SetShowThumb( joyStickID , true )
					else
						rkt.UIJoyStick.SetShowThumb( joyStickID , false )
					end
				elseif skillType == 2 then
					if PlayerPrefs_GetBool("CureShowCureHeadIcon", false) then   --勾选治疗头像
						rkt.UIJoyStick.SetShowThumb( joyStickID , true )
					else
						rkt.UIJoyStick.SetShowThumb( joyStickID , false )
					end 
				end
			end
		end
	else
		if PlayerPrefs.GetInt("SkillRelease", 1) == 2 then						--非灵心职业轮盘施法
			local skillRecord = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, skillID,1,1)
			if not skillRecord then 
				rkt.UIJoyStick.SetShowThumb( joyStickID , false )
				return
			end
			if skillRecord.SupportPreciseCast then
				rkt.UIJoyStick.SetShowThumb( joyStickID , true )
			else
				rkt.UIJoyStick.SetShowThumb( joyStickID , false )
			end
		else		--普通施法
			rkt.UIJoyStick.SetShowThumb( joyStickID , false )
		end
	end
end

--判断是否是辅助技能，返回， 1-治疗，2-单体复活， 并返回技能记录，  不是辅助技能则返回nil
function SkillButtonJoySticks:CheckAssistSkill(id)
	local skillID = self.skillMap[id]
	if not skillID or skillID <= 0 then return end
	local skillRecord = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, skillID,1,1)
	if not skillRecord then return end
	
	local filterType = skillRecord.FilterType
	if skillRecord.IsRevive then
		return 2, skillRecord
    else
        local condition = 0
        for i,v in pairs(filterType) do
            if v == "ally" then
                condition = condition + 1
            elseif v == "alive" then
                condition = condition + 1
            end
        end
        
        if condition == 2 and skillRecord.MaxTargets == 1 then
            return 1, skillRecord
        end
	end
    
	return nil
end

--获取辅助技能范围内的队友,返回  {MemberInfo}, 出错返回nil，否则返回空表
function SkillButtonJoySticks:GetSkillInfluenceMemberInfo(id)
	local skillType, skillRecord = self:CheckAssistSkill(id)
	if not skillType or not skillRecord then return end
	
	local retTable = {}
	local myTeam = IGame.TeamClient:GetTeam()				--m_listMemberInfo
	
	local currentID = IGame.EntityClient:GetMapID()
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	local position = pHero:GetPosition()
	local heroPDBID = pHero:GetNumProp(CREATURE_PROP_PDBID)
	
	for i, data in pairs(myTeam.m_listMemberInfo) do
		if currentID == data.nMapID and heroPDBID ~= data.dwPDBID then
            local entity = IGame.EntityClient:GetByPDBID(data.dwPDBID)
            if entity ~= nil then
                if Vector3.Distance(position, entity:GetPosition()) <= skillRecord.AttackDistance then
                    if skillType == 2 then
                        if data.nCurHP <= 0 then
                            table.insert(retTable, data)
                        end
                    elseif skillType == 1 then
                        table.insert(retTable, data)
                    end
                end
            end
		end
	end
	return retTable
end

--====================================================================================================================================
--------------------------------------------------------------

--冷却完成特效
function SkillButtonJoySticks:PlaySkillCoolOverEffect(nParentTrans)
	rkt.EntityView.CreateEffect( "Assets/IGSoft_Resources/Projects/Prefabs/UI_effect/ef_JNJD.prefab" ,
        function(path,obj)
			obj.transform:SetParent(nParentTrans,false)
        end , "" , true )
end

--普通攻击点击特效
function SkillButtonJoySticks:PlayCommonAttackClickEffect(nParentTrans)
	rkt.EntityView.CreateEffect( "Assets/IGSoft_Resources/Projects/Prefabs/UI_effect/ef_PTGJ.prefab" ,
        function(path,obj)
			obj.transform:SetParent(nParentTrans,false)
        end , "" , true )
end

--技能点击特效
function SkillButtonJoySticks:PlaySkillClickEffect(nParentTrans)
	rkt.EntityView.CreateEffect( "Assets/IGSoft_Resources/Projects/Prefabs/UI_effect/ef_SFJN.prefab" ,
        function(path,obj)
			obj.transform:SetParent(nParentTrans,false)
        end , "" , true )
end

-----------------------------------------------------------
-- 更新挂机状态
function SkillButtonJoySticks:UpdataGuaJiState()
	if not self:isLoaded() then
		return
	end
	local bState = 0
	if IGame.AutoSystemManager:IsOnAutoSystem() and not IGame.AutoSystemManager:IsTrainFollowing() then
		bState = 1
	end
	self:RefeshGuaJiState(bState)
end

------------------------------------------------------------
-- 更新界面显示
function SkillButtonJoySticks:UpdateVisible()
	if not self:isLoaded() then
		return
	end

	-- 更新挂机状态
	self:UpdataGuaJiState()
end

-- 连招提示事件
function SkillButtonJoySticks:OnExecuteEventComboHint(msg)
	local skillID = msg.skillID
	local waitTime = msg.waitTime
	local buttonID = self:FindButtonIDBySkillID(skillID)
	if not buttonID then
		return
	end
	
	local hasRingEffect = self:HasRingEffect()
	local button = self.Controls["m_Button_"..buttonID]
	self.ringEffect[buttonID] = {freezeTime = waitTime, beginTick = luaGetTickCount()}
	button.Controls.m_RingImage.gameObject:SetActive(true)
	button.Controls.m_RingImage.fillAmount = 1
	
	-- 如果之前没有定时器，现在有，那么就要开启一个
	if not hasRingEffect then
		rktTimer.KillTimer(self.callback_OnTimerRingEffect)
		rktTimer.SetTimer(self.callback_OnTimerRingEffect, interval, -1, "SkillButtonJoySticks:OnExecuteEventComboHint")
	end
end

-- 环形光效更新
function SkillButtonJoySticks:OnTimerRingEffect()
	local hasRingEffect = false
	for i,v in pairs(self.ringEffect) do
		local button = self.Controls["m_Button_"..i]
		local passedTick = luaGetTickCount() - v.beginTick
		local leftAmount = 1 - passedTick / v.freezeTime
		button.Controls.m_RingImage.fillAmount = leftAmount
		if leftAmount < 0 then
			button.Controls.m_RingImage.fillAmount = 0
			self.ringEffect[i] = nil
		else
			hasRingEffect = true
			if not button.Controls.m_RingImage.gameObject.activeInHierarchy then 
				button.Controls.m_RingImage.gameObject:SetActive(true)
			end
		end
	end
	
	if not hasRingEffect then
		rktTimer.KillTimer(self.callback_OnTimerRingEffect)
	end
end

-- 是否有环形光效
function SkillButtonJoySticks:HasRingEffect()
	return next(self.ringEffect) ~= nil
end

-- 销毁环形光效
function SkillButtonJoySticks:HideRingEffect(buttonID)
	local button = self.Controls["m_Button_"..buttonID]
	if button == nil then
		return
	end
	
	button.Controls.m_RingImage.fillAmount = 0
	self.ringEffect[buttonID] = nil
	
	if not self:HasRingEffect() then
		rktTimer.KillTimer(self.callback_OnTimerRingEffect)
	end
end

-- 点击轻功按钮
function SkillButtonJoySticks:OnQingGongClick()
	rktEventEngine.FireExecute(EVENT_SKILL_BUTTON_QINGGONG, SOURCE_TYPE_SYSTEM, 0)
end

-- 是否有按钮在冷却中
function SkillButtonJoySticks:IsSkillButtonsInCooling()
    return self:HasCooling() or self:HasRingEffect()
end

--点击切换技能流派按钮	
function SkillButtonJoySticks:OnChangeSkillBtnClick()
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	if studyPart.liuPai == 1 then
		studyPart:RequestChangeLiuPai(2)
	elseif studyPart.liuPai == 2 then 
		studyPart:RequestChangeLiuPai(1)
	end
end

-- 战斗状态改变事件
function SkillButtonJoySticks:OnBattleStateChange(msg)
    self:CheckQingGongButtonImageRefreshOnAttach()
end

-- 冷却提示
function SkillButtonJoySticks:CoolDownHint()
    if not self.lastHintTick then
        self.lastHintTick = 0
    end
    
    local curTick = luaGetTickCount()
    if self.lastHintTick > 0 and curTick - self.lastHintTick < 1000 then -- 1秒冷却
        return
    end
    
    self.lastHintTick = curTick
    IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "技能正在冷却中")
end

------------------------轻功相关-----------------------------------
--轻功翅膀按钮回调， TODO
function SkillButtonJoySticks:OnQingGongUpBtnClick()
	rktEventEngine.FireExecute( EVENT_JOY_STICK_POINT_DOWN , 0 , JOY_STICK_ID.QingGong_Segment_Rise)
end

--轻功俯冲按钮毁掉,   TODO
function SkillButtonJoySticks:OnQingGongDownBtnClick()
	rktEventEngine.FireExecute( EVENT_JOY_STICK_POINT_DOWN , 0 , JOY_STICK_ID.QingGong_Segment_Dive)
end

--对外接口，  设置显示状态 1-技能  2-轻功
function SkillButtonJoySticks:SetStateView(state)
	if not self:isLoaded() then return end
	
	if state ~= 1 and state ~= 2 then return end
	
	self.State = state
	self:DoChangeStateAnim(self.State)
end

--切换动画,只做表现，不更新数据
function SkillButtonJoySticks:DoChangeStateAnim(state)
	if state == 1 then
		local tweener = self.Controls.skillbutton_6.gameObject.transform:DOLocalMove(Vector3.New(-81,250,0),tweenerDuration,false)
		self.Controls.skillbutton_6.gameObject.transform:DOScale(1,tweenerDuration)
		--tweener:SetEase(DG.Tweening.Ease.Linear)
		tweener:OnComplete(function() 
					self.Controls.m_NormalSkillParent.gameObject:SetActive(true)
					self.Controls.m_QingGongParent.gameObject:SetActive(false)
                    self:SetJumpButtonClickAnimationEnabled(false)
				end)
	elseif state == 2 then
		local tweener = self.Controls.skillbutton_6.gameObject.transform:DOLocalMove(Vector3.New(-108,216,0),tweenerDuration,false)
		self.Controls.skillbutton_6.gameObject.transform:DOScale(1.6,tweenerDuration)
		--tweener:SetEase(DG.Tweening.Ease.Linear)
		tweener:OnComplete(function() 
			self.Controls.m_NormalSkillParent.gameObject:SetActive(false)
			self.Controls.m_QingGongParent.gameObject:SetActive(true)
            self:SetJumpButtonClickAnimationEnabled(true)
		end)
	else
		return
	end
end

--更新气力值
function SkillButtonJoySticks:UpdateQingGongStrength(curValue, maxValue)
	if not self:isLoaded() then
		return
	end
	
    self.curValue = curValue
    self.maxValue = maxValue
    
	if self.curValue < 0 then
		self.curValue = 0
	end
    
    if self.maxValue <= 0 then
        self.maxValue = 1
    end
    
	self.Controls.m_QingGonFillImg.fillAmount = self.curValue / self.maxValue
    self:UpdateQingGongStrengthImage()
end

-- 更新气力值图片
function SkillButtonJoySticks:UpdateQingGongStrengthImage()
    local hero = GetHero()
    if not hero then
        return
    end
    
    local QingGongManager = hero:GetQingGongManager()
    if not QingGongManager then
        return
    end
    
    local nextSegment = QingGongManager:GetQingGongSegmentByJoystickID(JOY_STICK_ID.QingGong_Segment_Normal)
    local id = QingGongManager:GetQingGongID()
    local level = QingGongManager:GetQingGongLevel(id)
    local segment = IGame.rktScheme:GetSchemeInfo(QINGGONG_CSV, id, level, nextSegment)
    if not segment then
        return
    end
    
    if self.curValue < segment.InstantCost then
        UIFunction.SetImageSprite(self.Controls.m_QingGonFillImg, AssetPath.TextureGUIPath.."Main_mainUI/Main_jn_qilitiao_hong.png")
    else
        UIFunction.SetImageSprite(self.Controls.m_QingGonFillImg, AssetPath.TextureGUIPath.."Main_mainUI/Main_jn_qilitiao.png")
    end
end

-- 更新气力值
function SkillButtonJoySticks:UpdateQingGongStrengthOnAttach()
    local hero = GetHero()
    if not hero then
        return
    end
    
    local QingGongManager = hero:GetQingGongManager()
    if not QingGongManager then
        return
    end
    
    QingGongManager:SetStrength(QingGongManager:GetStrength())
end

-- 隐藏挂机按钮
function SkillButtonJoySticks:ShowGuaJiButton(isShow)
    if not self:isLoaded() then
        return
    end
    
    if self.SkillAreaPlan == gSkillAreaPlan.Pubg then
        isShow = false
    end
    
    self.Controls.skillGuaJi.gameObject:SetActive(isShow)
end

-- 设置跳跃按钮的点击缩放效果
function SkillButtonJoySticks:SetJumpButtonClickAnimationEnabled(enabled, originalSize)
    self.Controls.m_JumpClickAnimation.enabled = enabled
    if enabled then
        self.Controls.m_JumpClickAnimation.m_OringinScale = Vector3.New(1.6, 1.6, 1.6)
		self.Controls.m_JumpClickAnimation.pressedScale = Vector3.New(1.28,1.28,1.28)
    else
        self.Controls.m_JumpClickAnimation.m_OringinScale = Vector3.New(1.0, 1.0, 1.0)
    end
end

-- 更新跳跃按钮点击动画
function SkillButtonJoySticks:RefreshJumpClickAnimation()
    if self.State == 1 then
        self:SetJumpButtonClickAnimationEnabled(false, 1)
    else
        self:SetJumpButtonClickAnimationEnabled(true, 1.6)
    end
end

-- 检测技能按钮是否变为可用的外部条件
function SkillButtonJoySticks:CheckEnableOnOtherConditions()
    -- 1、检测召唤条件
    self:CheckEnableOnOtherConditions_Summon()
    
    -- 2、其他……
end

-- 增加召唤物
function SkillButtonJoySticks:OnExecuteEventPawnAdd(msg)
    self:CheckEnableOnOtherConditions()
    self:RefreshForbidSkillEffect()
end

-- 删除召唤物
function SkillButtonJoySticks:OnExecuteEventPawnKill(msg)
    self:CheckEnableOnOtherConditions()
    self:RefreshForbidSkillEffect()
end

-- 检测召唤物
function SkillButtonJoySticks:CheckEnableOnOtherConditions_Summon()
    local hero = GetHero()
    if not hero then
        return
    end
    
    local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
    if not skillPart then
        return
    end
    
    local skillList = skillPart:GetTotalSkillList()
    for i,v in pairs(skillList) do
        local extendedScheme = IGame.SkillClient:GetSkillScheme(i, v, 1)
        if extendedScheme ~= nil then
            statement.analyze_skill_scheme(i, v)
            -- 需要某个召唤物才能发起
            if extendedScheme.enabled_on_summon_id ~= nil then
                local conjurePart = hero:GetEntityPart(ENTITYPART_CREATURE_CONJURE)
                if conjurePart == nil or not conjurePart:HasPawnID(extendedScheme.enabled_on_summon_id) then
                    self:AddSkillForbidReasonFromExternals(i, "summon")
                else
                    self:RemoveSkillForbidReasonFromExternals(i, "summon")
                end
            end
        end
    end
end

-- 添加外部禁止技能条件
function SkillButtonJoySticks:AddSkillForbidReasonFromExternals(skillID, strReason)
    if not self.skillReferenceCountFromExternals[skillID] then
        self.skillReferenceCountFromExternals[skillID] = {}
    end
    
    local t = self.skillReferenceCountFromExternals[skillID]
    for i,v in pairs(t) do
        if v == strReason then
            return -- 存在相同原因则不再添加
        end
    end
    
    table.insert(t, strReason)
end

-- 移除外部禁止技能条件
function SkillButtonJoySticks:RemoveSkillForbidReasonFromExternals(skillID, strReason)
    if not self.skillReferenceCountFromExternals[skillID] then
        return
    end
    
    local t = self.skillReferenceCountFromExternals[skillID]
    for i = #t, 1, -1 do
        if t[i] == strReason then
            table.remove(t, i)
        end
    end
end

-- 某个技能id是否被其他模块禁用
function SkillButtonJoySticks:IsForbiddenByReferenceCount(skillID)
    if self.skillReferenceCount[skillID] and self.skillReferenceCount[skillID] > 0 then
        return true
    end
    
    return false
end

-- 某个技能id是否被其他外部模块禁用
function SkillButtonJoySticks:IsForbiddenByReferenceCountFromExternals(skillID)
    if self.skillReferenceCountFromExternals[skillID] ~= nil and next(self.skillReferenceCountFromExternals[skillID]) ~= nil then
        return true
    end
    
    return false
end

-- 外部模块禁用轻功
function SkillButtonJoySticks:AddQingGongForbidStatusReason(strReason, noRefresh)
    self.QingGongForbidStatusReason[strReason] = true
    
    if not noRefresh then
        self:CheckQingGongButtonImageRefresh()
    end
end

-- 外部模块解禁轻功
function SkillButtonJoySticks:RemoveQingGongForbidStatusReason(strReason, noRefresh)
    self.QingGongForbidStatusReason[strReason] = nil
    
    if not noRefresh then
        self:CheckQingGongButtonImageRefresh()
    end
end

-- 检测轻功按钮图片切换
-- 可以使用轻功时，替换成轻功图片
-- 不能使用轻功时，替换成跳跃图片
function SkillButtonJoySticks:CheckQingGongButtonImageRefresh()
    if not self:isLoaded() then
        return
    end
    
    if not self.Controls then
        return
    end
    
    local button = self.Controls["m_Button_6"]
    if not button then
        return
    end
    
    -- 如果禁用轻功状态，则显示跳跃图片
    if self:IsForbidQingGongStatus() then
        local jump_icon = self:GetJumpSkillIcon()
        if jump_icon == nil then
            jump_icon = "Main_mainUI/city_tiaoqi_1.png"
        end
        
        UIFunction.SetImageSprite(button.Controls.m_SkillIcon, AssetPath.TextureGUIPath..jump_icon)	
        self.Controls.m_QingGongStrengthImg.gameObject:SetActive(false)
    else
        -- 如果没有禁用，则显示轻功图片
        UIFunction.SetImageSprite(button.Controls.m_SkillIcon, AssetPath.TextureGUIPath.."Main_mainUI/Main_jn_qinggong.png")	
        self.Controls.m_QingGongStrengthImg.gameObject:SetActive(true)
    end
    
    -- 检测禁用图标
    self:RefreshForbidSkillEffect()
end

-- 是否禁止切换轻功
function SkillButtonJoySticks:IsForbidQingGongStatus()
    return next(self.QingGongForbidStatusReason) ~= nil
end

-- 添加轻功禁用条件
function SkillButtonJoySticks:AddQingGongForbidUseReason(strReason)
    self.QingGongForbidUseReason[strReason] = true
    self:CheckQingGongButtonImageRefresh()
end

-- 移除轻功禁用条件
function SkillButtonJoySticks:RemoveQingGongForbidUseReason(strReason)
    self.QingGongForbidUseReason[strReason] = nil
    self:CheckQingGongButtonImageRefresh()
end

-- 是否禁用轻功
function SkillButtonJoySticks:IsForbidQingGongUse()
    return next(self.QingGongForbidUseReason) ~= nil
end

-- 轻功按钮显示状态
function SkillButtonJoySticks:CheckQingGongButtonImageRefreshOnAttach()
    -- 当前地图是否禁用
    if IGame.ZoneMatron:CanQingGong() then
        self:RemoveQingGongForbidStatusReason("ZoneMatron", true)
    else
        self:AddQingGongForbidStatusReason("ZoneMatron", true)
    end
    
    -- 战斗状态
    if QingGongController:IsInBattleState(GetHero()) then
        self:AddQingGongForbidStatusReason("BattleState", true)
    else
        self:RemoveQingGongForbidStatusReason("BattleState", true)
    end
    
    -- 刷新
    self:CheckQingGongButtonImageRefresh()
end

-- 获取跳跃按钮图片
function SkillButtonJoySticks:GetJumpSkillIcon()
    local hero = GetHero()
	if not hero then
		return
	end
	
	local voc = hero:GetNumProp(CREATURE_PROP_VOCATION)
	local studySkillPart = hero:GetEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studySkillPart then
		return
	end
	
	local liuPai = studySkillPart:GetLiuPai()
	local buttonScheme = IGame.rktScheme:GetSchemeInfo(SKILLBUTTON_CSV, voc, liuPai)
	if not buttonScheme then
		return
	end
    
    local jump_skill_id = buttonScheme.Button7[1] or 0
    if not jump_skill_id or jump_skill_id <= 0 then
        return
    end
    
    local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, jump_skill_id, 1)
    if not skillUpdateScheme then
        return
    end
    
    return skillUpdateScheme.Icon
end

-- 主角升级
function SkillButtonJoySticks:OnHeroUpgrade()
    local hero = GetHero()
    if not hero then
        return
    end
    
    local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
    if skillPart ~= nil then
        skillPart:OnExecuteEvent_SkillJoystickLoad()
    end
end

-- 获取某个技能Button位置配置的技能id
-- 在同一个Button位置，现在策划可以配置多个技能id，要获取学习了的那个技能id
-- 如果学习了多个，就取第一个
-- 如果都没有学习，也取第一个
-- skillButtonScheme:   SkillButton.csv配置表
-- configButtonIndex:   配置表中第几个Button位置
function SkillButtonJoySticks:GetSkillIDFromSkillButtonScheme(skillButtonScheme, configButtonIndex)
    local hero = GetHero()
    if not hero then
        return 0
    end
    
    local heroLevel = hero:GetNumProp(CREATURE_PROP_LEVEL)
    local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
    if not skillPart then
        return 0
    end
    
    local curSkillAreaPlan = self.SkillAreaPlan
    local skillList = skillPart:GetTotalSkillList()
    local skillIDs = skillButtonScheme["Button"..configButtonIndex]
    local skillID = 0
    local skillUpdateScheme
    local skillScheme
    
    -- 根据当前技能方案，从前往后，找到第一个学习了的技能id
    for i = 1, #skillIDs do
        local id = skillIDs[i]
        skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, id, 1)
        skillScheme = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, id, 1, 1)
        if skillUpdateScheme ~= nil and skillScheme ~= nil and GameHelp.IsMainSkill(skillScheme.SkillClass)
        and curSkillAreaPlan == skillUpdateScheme.SkillPlan and skillList[id] ~= nil and skillList[id] > 0
        and heroLevel >= skillUpdateScheme.NeedLevel then
            skillID = skillIDs[i]
            break
        end
    end
    
    -- 如果没有学习了的技能id，就以配置的第一个技能id为准
    if skillID == 0 then
        for i = 1, #skillIDs do
            local id = skillIDs[i]
            skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, id, 1)
            if skillUpdateScheme ~= nil and curSkillAreaPlan == skillUpdateScheme.SkillPlan then
                skillID = skillIDs[i]
                break
            end
        end
    end
    
    return skillID
end

-- 切换技能显示方案
function SkillButtonJoySticks:SwitchSkillAreaPlan(plan)
    if plan < gSkillAreaPlan.Normal or plan >= gSkillAreaPlan.Max then
        uerror("SkillButtonJoySticks:SwitchSkillAreaPlan invalid plan id: "..tostring(plan))
        return
    end
    
    if self.SkillAreaPlan == plan then
        return
    end
    
    self.SkillAreaPlan = plan
    
    -- 刷新按钮界面
    local hero = GetHero()
    if hero then
        local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
        if skillPart ~= nil then
            skillPart:OnExecuteEvent_SkillJoystickLoad()
        end
    end
    
    -- 显示或隐藏额外按钮
    self:RefreshUIOnSkillAreaPlan()
    
    -- 刷新显示
    UIManager.InputOperateWindow:ShowBasedOnMainRightBottomWindow()
end

-- 根据技能显示方案显示或隐藏一些按钮
function SkillButtonJoySticks:RefreshUIOnSkillAreaPlan()
    if not self:isLoaded() then
        return
    end
    
    if self.SkillAreaPlan == gSkillAreaPlan.Normal then
        self:ShowGuaJiButton(true)
        self.Controls.m_PubgParent.gameObject:SetActive(false)
    else
        self:ShowGuaJiButton(false)
        self.Controls.m_PubgParent.gameObject:SetActive(true)
    end
    
    -- 订阅物品增删事件
    if not self.callback_OnExecuteEventPacketChange then
        self.callback_OnExecuteEventPacketChange = function() self:OnExecuteEventPacketChange() end
    end
    
    rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnExecuteEventPacketChange)
    rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnExecuteEventPacketChange)
    
    if self.SkillAreaPlan == gSkillAreaPlan.Pubg then
        rktEventEngine.SubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnExecuteEventPacketChange)
        rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnExecuteEventPacketChange)
        
        -- 立即刷新一次物品数量
        self:OnExecuteEventPacketChange()
    end
end

-- 包裹物品数量变化
function SkillButtonJoySticks:OnExecuteEventPacketChange()
    if not self:isLoaded() then
        return
    end
    
    local hero = GetHero()
    if not hero then
        return
    end
    
    local packetPart = hero:GetEntityPart(ENTITYPART_PERSON_PACKET)
    if packetPart == nil then
        return
    end
    
    -- todo: 确认灵气、药品的物品id
    local lingqiNum = packetPart:GetGoodNum(2011)
    local leechdomNum = packetPart:GetGoodNum(2012)
    
    self.Controls.m_Pubg_LingQiNum.text = lingqiNum
    self.Controls.m_Pubg_LeechdomNum.text = leechdomNum
end

-- 荒岛求生玩法的药品按钮
function SkillButtonJoySticks:OnPubgLeechdomButtonClicked()
    local LeechdomID = 2012 -- todo: 确认药品id
    local hero = GetHero()
    if not hero then
        return
    end
    
    local packetPart = hero:GetEntityPart(ENTITYPART_PERSON_PACKET)
    if packetPart == nil then
        return
    end
    
    local uid = packetPart:GetGoodsUIDByGoodsID(LeechdomID)
    if uid == -1 then
        return
    end
    
    IGame.SkepClient:RequestUseItem(uid)
end

-- 获取当前的技能方案
function SkillButtonJoySticks:GetSkillAreaPlan()
    return self.SkillAreaPlan
end


return SkillButtonJoySticks