
----------------------------------------------------------------
---------------------------------------------------------------
-- 主界面右边下部分分窗口
-- 包含：打造、包裹
---------------------------------------------------------------
------------------------------------------------------------
require("GuiSystem.WindowList.ForgeWindow")
local MainRightBottomWindow = UIWindow:new
{
	windowName = "MainRightBottomWindow" ,
	mNeedUpDate = false,
	m_switchState = true,

	m_IsVisible = true, -- 界面是否显示，在每个地图配置中配置
	bSubExecute = false,
	m_haveDoEnable = false,
	m_needShowFumoTou = false,

}


local this = MainRightBottomWindow   -- 方便书写
------------------------------------------------------------
function MainRightBottomWindow:Init()
   
	self.FunctionWidget = require("GuiSystem.WindowList.MainHUD.FunctionWidget"):new()
	self.FunctionWidget:Init()
	self:InitCallbacks()
end
------------------------------------------------------------
function MainRightBottomWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)
	local controls = self.Controls
	self.FunctionWidget:Attach(controls.m_FuncWidget.gameObject )

	controls.m_SwitchBtn.onClick:AddListener(function() self:OnSwitchButtonClick() end)
	controls.m_PacketButton.onClick:AddListener(function() self:OnPacketButtonClick() end)
	controls.m_DiceButton.onClick:AddListener(function() self:OnDiceButtonClick() end)
	controls.btnAni = controls.m_SwitchRectOpen.gameObject:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	controls.m_FumoTouLeaveBtn.onClick:AddListener(function() self:OnClickFumoTouLeave() end)
	controls.m_DiceButton.gameObject:SetActive(false)
	controls.m_FumoTouLeaveBtn.gameObject:SetActive(false)
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable)) 
	self.unityBehaviour.onDisable:AddListener(function() self:OnDisable() end) 
	self:SubscribeWinExecute()
	uerror(" create MainMidBottomWindow")
	if self.m_haveDoEnable == false then 
		self:OnEnable()
	end

end

function MainRightBottomWindow:OnDestroy()
	self.m_haveDoEnable =false
	self.m_switchState = true
	self.bSubExecute = false
    self.mNeedUpDate = false
end

function MainRightBottomWindow:OnDisable()
	self.m_haveDoEnable =false
end
------------------------------------------------------------
-- 注册控件事件
function MainRightBottomWindow:SubscribeWinExecute()
	if self.bSubExecute then
		return
	end
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_UNEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ONEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_FUMOTOU_SHOW_ICON, SOURCE_TYPE_PERSON, 0, self.callback_OnFuMoTouIconShowEvent)
	rktEventEngine.SubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.callback_OnUpdateProp)
	
	-- 帮会红点：红包
	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_RIGHT_BOTTOM, self.RefreshRedDot, self)
	--SysRedDotsMgr.Register(IGame.ClanBuildingPresenter:GetBaseLayout(),"帮会",controls.m_BuildTgl,"m_BuildTgl")
	
	self.bSubExecute = true
end
------------------------------------------------------------
-- 注销控件事件
function MainRightBottomWindow:UnSubscribeWinExecute()
	
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_UNEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ONEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_FUMOTOU_SHOW_ICON, SOURCE_TYPE_PERSON, 0, self.callback_OnFuMoTouIconShowEvent)
	rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.callback_OnUpdateProp)
	
	-- 帮会红点：红包
	rktEventEngine.UnSubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_RIGHT_BOTTOM, self.RefreshRedDot, self)
	
	self.bSubExecute = false
end

function MainRightBottomWindow:Show(bringTop)
	UIWindow.Show(self, bringTop)
end

function MainRightBottomWindow:OnEnable()
	if self.m_FirstlyEnabled then
		IGame.ClanBuildingPresenter:UpdateClanBtnRetDotState()
	end
	self:RefreshRedDot()
	self:RefreshPackRedDot()
	self:UpdateVisible()
	self.m_haveDoEnable =true
	if self.m_needShowFumoTou == true then 
		self:OnFuMoTouIconShowEvent(1)
	else
		self:OnFuMoTouIconShowEvent(0)
	end
	

	self:RefreshFumoNum()
	self.m_FirstlyEnabled = true
end

-- 更新界面是否显示
function MainRightBottomWindow:UpdateVisible()
	if not self.m_IsVisible then --隐藏
		self:Hide()
	else
		self:Show(true)
		if not self.m_switchState then 
			self:ChangeSkillVisiableState(true)
		else
			self:ChangeSkillVisiableState(false)
		end
	end
end

-- 设置界面是否显示
function MainRightBottomWindow:SetVisible(isVisible)
	self.m_IsVisible = isVisible
	if not isVisible and self:isShow() then
		self:Hide()
	elseif isVisible and not self:isShow() then
		self:Show(true)
	end    
    rktEventEngine.FireExecute(EVENT_MAIN_RIGHT_BOTTOM_WINDOW_SHOW_OR_HIDE, SOURCE_TYPE_SYSTEM, 0)
end

-- 点击背包按钮
function MainRightBottomWindow:OnPacketButtonClick()
	--[[local totalScore = 0
	UIManager.PackWindow:UpdateEquipTotalScore(totalScore)
	UIManager.PackWindow:Show(true)--]]
	local effectInfo = {}
	effectInfo.playRadius = 5
	effectInfo.selfRadius = 3.4 
	effectInfo.tag="dasd"
	effectInfo.centerPoint= Vector3.New(0,0,0)
	EffectHelp.PlayChickingEffect(effectInfo)

end

-- 点击骰子按钮
function MainRightBottomWindow:OnDiceButtonClick()
	
	GameHelp.PostServerRequest("RequestFuMoTouRandomNpc()")

end

function MainRightBottomWindow:OnClickFumoTouLeave()
	local data = 
	{
		content = "你确定要离开伏魔骰吗？",
		confirmCallBack = function()  GameHelp.PostServerRequest("RequestFuMoTouEndLeave()") end,
	}	
	UIManager.ConfirmPopWindow:ShowDiglog(data)
	
end
--
function MainRightBottomWindow:OnSwitchButtonClick()
	
--[[	if self.Controls.btnAni ~= nil then 
		if self.m_switchState then
			self.Controls.btnAni:DORestart( )
		else
			self.Controls.btnAni:DOPlayBackwards()
		end
	end--]]
	
	self:ChangeSkillVisiableState(self.m_switchState)
	self.m_switchState = not self.m_switchState
end


function MainRightBottomWindow:ChangeSkillVisiableState(state)
	if state == false then 
		self.FunctionWidget:MoveInWindow()
		UIManager.InputOperateWindow:HideSkillButtonArea()
	else
		self.FunctionWidget:MoveOutWindow()
		UIManager.InputOperateWindow:ShowSkillButtonArea()
	end
	
	if self.Controls.btnAni ~= nil then 
		if state == true then
			self.Controls.btnAni:DORestart()
		else
			self.Controls.btnAni:DOPlayBackwards( )
		end
	end
end

-- bSkillBtnsShowing 为true 切换到技能界面
function MainRightBottomWindow:SwitchSkillAttackState(bSkillBtnsShowing)
	if bSkillBtnsShowing == true then
		if self.m_switchState == true then
			if self:isLoaded() then
				self:OnSwitchButtonClick()
			else
				self.m_switchState = false
			end 
		end
	else
		if self.m_switchState == false then
			if self:isLoaded() then
				self:OnSwitchButtonClick()
			else
				self.m_switchState = true
			end 
		end
	end
end

function MainRightBottomWindow:RefreshFumoNum(num)
	if self:isLoaded() then 
		if num == nil then 
		
			num = GameHelp:GetHeroPacketGoodsNum(gFuMoTouCfg.fumoGoodsID)

		end
		if num > 999 then 
			self.Controls.m_FuMoNum.text="..."
		else
			self.Controls.m_FuMoNum.text = num
		end

	end
	
end

function MainRightBottomWindow:RefreshRedDot()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
    if not self:isLoaded() then
        return
    end

	local FunName_TransName = { --  key:自己的按钮的红点名字  Index:功能模块的名字 
		["m_TouXianRedDot"] = 1,
        ["m_PetRedDot"] = 2,
	}
	local SwitchFlg = false
	for key,Index in pairs(FunName_TransName) do
		if GameHelp:MainRightIsCanUpGrade(Index) then
			self["FunctionWidget"].Controls[key].gameObject:SetActive(true)
			SwitchFlg = true
		else
			self["FunctionWidget"].Controls[key].gameObject:SetActive(false)
		end
	end
	
	-- 判断帮会的红点
	local clanFlag = false
	local pClan = IGame.ClanClient:GetClan()
	if pClan then
		clanFlag = SysRedDotsMgr.GetSysFlag("MainRightBottom", "帮会")
	end
	SwitchFlg = SwitchFlg or clanFlag	
	
	if SwitchFlg then
		self.Controls.m_SwitchRedDot.gameObject:SetActive(true)
	else
		self.Controls.m_SwitchRedDot.gameObject:SetActive(false)
	end
end
-- 添加新物品事件
function MainRightBottomWindow:OnEventAddGoods()
	if not self:isShow() then
		return
	end
	self:RefreshRedDot()
	self:RefreshPackRedDot()
	self:RefreshFumoNum()
end

-- 删除物品事件
function MainRightBottomWindow:OnEventRemoveGoods()
	if not self:isShow() then
		return
	end
	self:RefreshRedDot()
	self:RefreshPackRedDot()
end

-- 包裹红点
function MainRightBottomWindow:RefreshPackRedDot()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local PackRedDotFlg = false
	local PackRedDotFlg = forgePart:IsCanUpGrade()
	if PackRedDotFlg then
		self.Controls.m_PackBtnRed.gameObject:SetActive(true)
		return
	end
	self.Controls.m_PackBtnRed.gameObject:SetActive(false)
end

-- 收到伏魔骰图标的显示事件
-- @needShow:是否需要显示:number
function MainRightBottomWindow:OnFuMoTouIconShowEvent(needShow)
	self.m_needShowFumoTou = (needShow == 1)
	if self:isLoaded() then 
		self.Controls.m_DiceButton.gameObject:SetActive(needShow == 1)
		self.Controls.m_FumoTouLeaveBtn.gameObject:SetActive(needShow == 1)
	end


	
end

-- 属性更新
function MainRightBottomWindow:OnUpdateProp(msg)
	if not msg or not msg.nPropCount then
		return
	end
    
	-- 战斗力变化刷新红点
	for i = 1, msg.nPropCount do
		if msg.propData[i].nPropID == CREATURE_PROP_POWER then
			self:RefreshRedDot()
		end
	end
end

-- 初始化全局回调函数
function MainRightBottomWindow:InitCallbacks()
	--self.callback_OnUpdateProp = function(event, srctype, srcid, UID) self:OnUpdateProp(UID) end
	self.callback_OnEventAddGoods = function() self:OnEventAddGoods() end
	self.callback_OnEventRemoveGoods = function() self:OnEventRemoveGoods() end
	self.callback_OnFuMoTouIconShowEvent = function(event, srctype, srcid, needShow) self:OnFuMoTouIconShowEvent(needShow) end
	self.callback_OnUpdateProp = function(event, srctype, srcid, msg) self:OnUpdateProp( msg ) end
	self.callback_OnEventShowNewPacket = function(event, srctype, srcid, repacket) self:OnEventShowNewPacket( repacket ) end
end

-- 获取切换按钮状态
function MainRightBottomWindow:GetSwitchState()
    return self.m_switchState
end

-- 是否需要隐藏
function MainRightBottomWindow:IsVisibleByConfig()
    return self.m_IsVisible
end

-- 隐藏包裹按钮和切换按钮
function MainRightBottomWindow:ShowPackButtonAndSwitchButton(isShow)
    if not self:isLoaded() then
        return
    end
    self.Controls.m_PacketButton.gameObject:SetActive(isShow)
    self.Controls.m_SwitchBtn.gameObject:SetActive(isShow)
end

------------------------------------------------------------
return this
