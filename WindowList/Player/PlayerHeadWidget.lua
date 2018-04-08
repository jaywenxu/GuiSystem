--/*******************************************************************
--** 文件名:    PlayerHeadWidget.lua
--** 版  权:    (C) 深圳冰川网络技术有限公司 2016 - Speed
--** 创建人:    zjc
--** 日  期:    2017/01/18
--** 版  本:    1.0
--** 描  述:    玩家头像组件
--** 应  用:    显示玩家头像、血条、等级等信息
--********************************************************************/


local PlayerHeadWidget = UIControl:new
{
	windowName = "PlayerHeadWidget",
    playHeadICon = "",					--玩家头像  
	playerNameText = "",			--玩家名称
    playerEffectivenessText = "", 	--玩家战斗力
    playerLevelText = "",			--玩家等级
    bloodImg = 0,					--血条进度条
	lastBattlePower=0,				--缓存上次的战力值
	bSubscibeEffectiveness = false,
	m_needUpdateHeadInfo = true,	-- 必须更新头像信息
	m_isAwake = false,				-- 是否已经在加载，加载在Attach
	m_LastPower = nil,
	bSubExecute = false,
}
local this = PlayerHeadWidget

function PlayerHeadWidget:Attach( obj )
    UIControl.Attach(self,obj)
	
	-- 客户端创建英雄事件
	self.CreateMainHeroCallBack = function() PlayerHeadWidget:OnCreateMainHero() end
	
	-- 客户端销毁英雄事件
	self.DestroyMainHeroCallBack =  function() PlayerHeadWidget:OnDestroyMainHero() end 
	-- 属性更新事件
	self.callback_OnExecuteEventUpdateProp = function(event, srctype, srcid, msg) self:OnExecuteEventUpdateProp(event, srctype, srcid, msg) end
	self.hpSlider = self.Controls.m_hpSlider:GetComponent(typeof(Slider))
	self:SubscribeExecute()
	self.m_isAwake = true
	if self.m_needUpdateHeadInfo == true then
		self.m_needUpdateHeadInfo = false
		self:UpdateHeadInfo()
	end
	
end

--销毁时取消订阅事件
function PlayerHeadWidget:OnDestroy()
	self:UnSubscribeExecute()
end

------------------------------------------------------------
-- 注册控件事件
function PlayerHeadWidget:SubscribeExecute()
	if self.bSubExecute then
		return
	end
	rktEventEngine.SubscribeExecute( EVENT_PERSON_CREATEHERO , SOURCE_TYPE_PERSON , 0 , self.CreateMainHeroCallBack )
	rktEventEngine.SubscribeExecute( EVENT_PERSON_DESTROYHERO , SOURCE_TYPE_PERSON , 0 , self.DestroyMainHeroCallBack)
	rktEventEngine.SubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.callback_OnExecuteEventUpdateProp)
	
    self.m_OnStrPropUpdate = handler(self, self.OnStrPropUpdate)
	rktEventEngine.SubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.m_OnStrPropUpdate)
    
    self.bSubExecute = true
end
------------------------------------------------------------
-- 注销控件事件
function PlayerHeadWidget:UnSubscribeExecute()
	-- 客户端创建英雄事件
	rktEventEngine.UnSubscribeExecute( EVENT_PERSON_CREATEHERO , SOURCE_TYPE_PERSON , 0 , self.CreateMainHeroCallBack )
	-- 客户端销毁英雄事件
	rktEventEngine.UnSubscribeExecute( EVENT_PERSON_DESTROYHERO , SOURCE_TYPE_PERSON , 0 , self.DestoryMainHeroCallBack )
	-- 属性更新事件
	rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.callback_OnExecuteEventUpdateProp)
	
	rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.m_OnStrPropUpdate)
    self.m_OnStrPropUpdate = nil
    
    self.bSubExecute = false
end


-- 玩家头像组件
function PlayerHeadWidget:Update()
	self:UpdateHeadInfo()
	self:UpdateBoold()
end

--设置玩家名
function PlayerHeadWidget:SetPlayerName(szName)

	self.Controls.playerNameText.text = szName
end

function PlayerHeadWidget:GetPlayerName()

	return self.Controls.playerNameText.text
end


-- 设置战斗力
function PlayerHeadWidget:SetPlayerEffectiveness(nPower)
	if self.lastBattlePower ~= 0 and nPower > self.lastBattlePower then

		local info = {}
		info.sourceBattlePower = self.lastBattlePower
		info.endBattlePower = nPower
		-- 提示增加战斗力
		--GlobalGame.Instance.EventEngine.FireExecute(GVIEWCMD_CHANGE_BATTLEPOWER, SOURCE_TYPE_UI, 0, info)
	end
	self.Controls.playerEffectivenessText.text = nPower
	self.lastBattlePower = nPower
end


-- 设置玩家等级
function PlayerHeadWidget:SetPlayerLevel()
	local pHero = GetHero()
	if not pHero then
		return
	end
	
	self.Controls.playerLevelText.text = pHero:GetNumProp(CREATURE_PROP_LEVEL)
end

-- 设置血量
function PlayerHeadWidget:UpdateBoold()

	local pHero = GetHero()
	if not pHero then
		return
	end
	local nCurHP = pHero:GetNumProp(CREATURE_PROP_CUR_HP)
	local nMaxHP = pHero:GetNumProp(CREATURE_PROP_MAX_HP)
	if self.hpSlider ~= nil then 
		self.hpSlider.value = nCurHP / nMaxHP
	end
	
end

-- 设置头像
function PlayerHeadWidget:SetHeroHead()

	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end	
	local nFaceID = pHero:GetNumProp(CREATURE_PROP_FACEID)
	local iconPath = gPersonHeadIconCfg[nFaceID]
	if not iconPath then
		local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
		local nSex = pHero:GetNumProp(CREATURE_PROP_SEX)
		if nSex == 0 then
			nFaceID = gDefaultVocationHeadCfg[nVocation].maleIcon
		else
			nFaceID = gDefaultVocationHeadCfg[nVocation].femaleIcon
		end
		iconPath = gPersonHeadIconCfg[nFaceID]
	end
	if iconPath == nil then
		iconPath = AssetPath.TextureGUIPath.."Icon_Head/city_touxiang_001.png"
	end
	UIFunction.SetImageSprite( self.Controls.playHeadIcon , iconPath )
end

-- 获取并设置战斗力
function PlayerHeadWidget:UpdatePlayerEffectiveness()

	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end	
	local nPower = pHero:GetNumProp(CREATURE_PROP_POWER)
	local nOldPower = self.m_LastPower
	self:SetPlayerEffectiveness(nPower)
	UIManager.TiShiBattleUpWindow:OnBattleValueArrived(nOldPower,nPower)
	self.m_LastPower = nPower
end

--  注册主角战力值改变事件
function PlayerHeadWidget:SubscibeEffectiveness()
    
	if self.bSubscibeEffectiveness == true then
		return
	end
	self.OnNoteOperateCallBack = function() self:OnNoteOperateState() end
	rktEventEngine.SubscribeExecute( EVENT_PERSON_NOTE_OPERATESTATE , SOURCE_TYPE_PERSON , 0 , self.OnNoteOperateCallBack )
	self.bSubscibeEffectiveness = true
end

-- 注销主角战力值改变事件
function PlayerHeadWidget:UnSubscibeEffectiveness()

	rktEventEngine.UnSubscribeExecute( EVENT_PERSON_NOTE_OPERATESTATE , SOURCE_TYPE_PERSON , 0 , self.OnNoteOperateCallBack )
	self.bSubscibeEffectiveness = false
end

function PlayerHeadWidget:OnStrPropUpdate(_, _, _, MsgData)
    if MsgData.nPropID == CREATURE_PROP_NAME then
        self:SetPlayerName(MsgData.szValue)
    else
   
    end
end

-- 数值变化监听事件回调
function PlayerHeadWidget:PropertyChanged(nProp)
   
	if nProp == CREATURE_PROP_CUR_HP or nProp == CREATURE_PROP_MAX_HP then
        self:UpdateBoold()
		
		-- 血量上限改变时，判断是否激活血池定时器
		if nProp == CREATURE_PROP_MAX_HP then
			IGame.AutoSystemManager.m_AutoSystemUseDrag:CheckBloodPoolTimerByHP()
		end
    elseif nProp == CREATURE_PROP_LEVEL then
		self:SetPlayerLevel()
		--self:UpdatePlayerEffectiveness()
			
		-- 自动恢复药排序
		IGame.AutoSystemManager.m_AutoSystemUseDrag:SortDrag()
    elseif nProp == CREATURE_PROP_POWER then
		self:UpdatePlayerEffectiveness()
    end
end
function PlayerHeadWidget:UpdateHeadInfo()
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end	
	local szName = pHero:GetName()
	
	if self.m_isAwake == true then
		
		self:SetPlayerName(szName)
		self:UpdatePlayerEffectiveness()
		self:UpdateBoold()
		self:SetPlayerLevel()
		self:SetHeroHead()
	else
		self.m_needUpdateHeadInfo = true
	end
end

-- 创建主角
function PlayerHeadWidget:OnCreateMainHero()
	
	-- EVENT_PERSON_CREATEHERO
	self:SubscibeEffectiveness()
	self:UpdateHeadInfo()
end

function PlayerHeadWidget:OnDestroyMainHero()
	
	-- EVENT_PERSON_DESTROYHERO
	-- 注销主角战力值改变事件
	self:UnSubscibeEffectiveness()
end

function PlayerHeadWidget:OnNoteOperateState()
	
	-- EVENT_PERSON_NOTE_OPERATESTATE
	-- 设置战斗力
	self:UpdatePlayerEffectiveness()
end

function PlayerHeadWidget:OnExecuteEventUpdateProp(event, srctype, srcid, msg)
	if not msg or type(msg) ~= "table" or not msg.nPropCount or msg.nPropCount == 0  then
		return
	end
	for i = 1, msg.nPropCount do
		self:PropertyChanged(msg.propData[i].nPropID)
	end
end

return this