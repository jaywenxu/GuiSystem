-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/19
-- 版  本:    1.0
-- 描  述:    打造窗口
-------------------------------------------------------------------

local ForgeWindow = UIWindow:new
{
	windowName = "ForgeWindow",
	m_ForgeTypeName = {"强化","镶嵌","洗炼","合成"},
	m_CurForgeType = 1,				-- 当前打造类型
}


local this = ForgeWindow					-- 方便书写
local zero = int64.new("0")

--[[local titleImagePath			= AssetPath.TextureGUIPath.."Strength/stronger_baoti_qianghua_1.png"
local titleImagePath_Normal		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_qianghua_1.png"
local titleImagePath_PCT		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_fujiaqianghua_1.png"
local titleImagePath_Shuffle	= AssetPath.TextureGUIPath.."Strength/stronger_baoti_xilian_1.png"
local titleImagePath_Conpound	= AssetPath.TextureGUIPath.."Strength/stronger_baoshihecheng.png"
local titleImagePath_Setting	= AssetPath.TextureGUIPath.."Strength/stronge_xiangqian.png"
--]]
local titleImagePath			= AssetPath.TextureGUIPath.."Strength/Strength_dazao.png"
local titleImagePath_Normal		= AssetPath.TextureGUIPath.."Strength/Strength_dazao.png"
local titleImagePath_PCT		= AssetPath.TextureGUIPath.."Strength/Strength_dazao.png"
local titleImagePath_Shuffle	= AssetPath.TextureGUIPath.."Strength/Strength_dazao.png"
local titleImagePath_Conpound	= AssetPath.TextureGUIPath.."Strength/Strength_dazao.png"
local titleImagePath_Setting	= AssetPath.TextureGUIPath.."Strength/Strength_dazao.png"

------------------------------------------------------------
function ForgeWindow:Init()
	self.ForgeEquipWidget		= require("GuiSystem.WindowList.Forge.ForgeEquipWidget")
	self.ForgeSmeltWidget		= require("GuiSystem.WindowList.Forge.ForgeSmeltWidget")
	self.ForgeShuffleWidget 	= require("GuiSystem.WindowList.Forge.ForgeShuffleWidget")
	self.ForgeSettingWidget 	= require("GuiSystem.WindowList.Forge.ForgeSetting.ForgeSettingWidget")
	self.ForgeConpoundWidget 	= require("GuiSystem.WindowList.Forge.ForgeSetting.ForgeConpoundWidget")
	--self.ChatMessageWidget = require("GuiSystem.WindowList.Chat.ChatMessageWidget")
end
------------------------------------------------------------
function ForgeWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.callback_OnCloseButtonClick =	function()
										self:OnCloseButtonClick()
									end
	-- 注册打造选项卡事件
	for i = 1, 3 do
		self.Controls["m_TogRedDot"..i] = self.Controls["m_ForgeTypeTog"..i].transform:Find("RedDot")
		self.Controls["m_TogRedDot"..i].gameObject:SetActive(false)
		self.Controls["m_ForgeTypeTog"..i].onValueChanged:AddListener(function(on) self:ChangeForgePage(on, i) end)
	end
	
	UIWindow.AddCommonWindowToThisWindow(self,true,titleImagePath,self.callback_OnCloseButtonClick,nil,function() self:SetFullScreen() end)
	self:SubscribeEvent()

	self:ShowType(self.m_CurForgeType)
end

function ForgeWindow:OnEventTriggerClick(eventData)
	self.ForgeShuffleWidget:OnEventTriggerClick()
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

function ForgeWindow:Show( bringTop)
	UIWindow.Show(self,bringTop)
	--PreLoadMgr.PreLoadUIEffect(OPENUI_AFTER_PRELOADRESOURCE.UI_FORGE_PATH)
end

------------------------------------------------------------
-- 窗口销毁
function ForgeWindow:OnDestroy()
	self:UnsubscribeEvent()
	UIWindow.OnDestroy(self)
end

function ForgeWindow:SetEquipPlace(EquipPlace)
	self.ForgeEquipWidget:SetEquipPlace(EquipPlace)
end

function ForgeWindow:OnCloseButtonClick()
	if not self:isLoaded() then
		return
	end
	if self.ForgeConpoundWidget.transform ~= nil and self.ForgeConpoundWidget:isShow() then
		UIManager.ForgeWindow:ChangeForgePage(true, 2)
		return
	end
	self.m_CurForgeType = 0
	self:Hide()
end

function ForgeWindow.ShowSmelt()
	-- 加载强化子窗口
	if ForgeWindow.ForgeSmeltWidget.transform == nil then
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.Forge.ForgeSmeltWidget ,
			function ( path , obj , ud )
				if nil ==obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				local item = ForgeWindow.ForgeSmeltWidget
				item:Attach(obj)
				obj.transform:SetParent(ForgeWindow.transform:Find("Pages"),false)
				obj.transform:SetSiblingIndex(2)
				item:Refresh()
			end,"", AssetLoadPriority.GuiNormal )
	else
		ForgeWindow.transform:Find("Pages/Forge_Smelt_Widget(Clone)").gameObject:SetActive(true)
		ForgeWindow.ForgeSmeltWidget:Refresh()
	end
end

function ForgeWindow.HideSmelt()
	if ForgeWindow.ForgeSmeltWidget.transform == nil then
		return
	end
	ForgeWindow.transform:Find("Pages/Forge_Smelt_Widget(Clone)").gameObject:SetActive(false)
end

function ForgeWindow.ShowSet()	
	-- 加载镶嵌子窗口
	if ForgeWindow.ForgeSettingWidget.transform == nil then
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.Forge.ForgeSettingWidget ,
			function ( path , obj , ud )
				if nil ==obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				local item = ForgeWindow.ForgeSettingWidget
				item:Attach(obj)
				obj.transform:SetParent(ForgeWindow.transform:Find("Pages"),false)
				obj.transform:SetSiblingIndex(2)
				item:Refresh()
			end,"", AssetLoadPriority.GuiNormal )
	else
		ForgeWindow.transform:Find("Pages/Forge_Setting_Widget(Clone)").gameObject:SetActive(true)
		ForgeWindow.ForgeSettingWidget:Refresh()
	end
	--ForgeWindow.Controls.m_PageSet.gameObject:SetActive(true)
end

function ForgeWindow.HideSet()
	if not ForgeWindow.ForgeSettingWidget or ForgeWindow.ForgeSettingWidget.transform == nil then
		return
	end
	ForgeWindow.ForgeSettingWidget:Hide()
	--ForgeWindow.transform:Find("Pages/Forge_Setting_Widget(Clone)").gameObject:SetActive(false)
end

function ForgeWindow.ShowConpound()	
	-- 加载合成子窗口
	if ForgeWindow.ForgeConpoundWidget.transform == nil then
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.Forge.ForgeConpoundWidget ,
			function ( path , obj , ud )
				if nil ==obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				local item = ForgeWindow.ForgeConpoundWidget
				item:Attach(obj)
				obj.transform:SetParent(ForgeWindow.transform:Find("Pages"),false)
				obj.transform:SetSiblingIndex(3)
				item:Refresh()
			end,"", AssetLoadPriority.GuiNormal )
	else
		ForgeWindow.transform:Find("Pages/Forge_Conpound_Widget(Clone)").gameObject:SetActive(true)
		ForgeWindow.ForgeConpoundWidget:Refresh()
	end
	if ForgeWindow.ForgeEquipWidget.transform ~= nil then
		ForgeWindow.ForgeEquipWidget:Hide()
	end
	
	ForgeWindow.HideSet()
end

function ForgeWindow.HideConpound()
	if not ForgeWindow.ForgeConpoundWidget or ForgeWindow.ForgeConpoundWidget.transform == nil then
		return
	end
	ForgeWindow.ForgeConpoundWidget:Hide()
	--ForgeWindow.ForgeEquipWidget:Show()
	--ForgeWindow.ForgeSettingWidget:Show(true,function ()ForgeWindow.ForgeSettingWidget:Refresh() end)
end

function ForgeWindow.ShowShuffle()
	-- 加载洗炼子窗口
	if ForgeWindow.ForgeShuffleWidget.transform == nil then
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.Forge.ForgeShuffleWidget ,
			function ( path , obj , ud )
				if nil ==obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				local item = ForgeWindow.ForgeShuffleWidget
				item:Attach(obj)
				obj.transform:SetParent(ForgeWindow.transform:Find("Pages"),false)
				obj.transform:SetSiblingIndex(2)
				item:Refresh()
			end,"", AssetLoadPriority.GuiNormal )
	else
		ForgeWindow.transform:Find("Pages/Forge_Shuffle_Widget(Clone)").gameObject:SetActive(true)
		ForgeWindow.ForgeShuffleWidget:Refresh()
	end
end

function ForgeWindow.HideShuffle()
	if ForgeWindow.ForgeShuffleWidget.transform == nil then
		return
	end
	ForgeWindow.transform:Find("Pages/Forge_Shuffle_Widget(Clone)").gameObject:SetActive(false)
end

local ForgeTypeShowOrHide = {
	[1] = {ShowFunc = ForgeWindow.ShowSmelt,	HideFunc = ForgeWindow.HideSmelt,	Widget = "ForgeSmeltWidget",},
	[2] = {ShowFunc = ForgeWindow.ShowSet,		HideFunc = ForgeWindow.HideSet,		Widget = "ForgeSettingWidget",},
	[3] = {ShowFunc = ForgeWindow.ShowShuffle,	HideFunc = ForgeWindow.HideShuffle,	Widget = "ForgeShuffleWidget",},
	[4] = {ShowFunc = ForgeWindow.ShowConpound,	HideFunc = ForgeWindow.HideConpound,	Widget = "ForgeConpoundWidget",},
}

function ForgeWindow:ShowType(index)
	self.m_CurForgeType = index or 1
	if self.Controls["m_ForgeTypeTog"..self.m_CurForgeType] then
		self.Controls["m_ForgeTypeTog"..self.m_CurForgeType].isOn = true
	end
	local path = {
		titleImagePath_Normal,
		titleImagePath_Setting,
		titleImagePath_Shuffle,
		titleImagePath_Conpound,
	}
	if self.CommonWindowWidget then
		self.CommonWindowWidget:SetName(path[self.m_CurForgeType])
	end
	
	if ForgeWindow.ForgeConpoundWidget and ForgeWindow.ForgeConpoundWidget.transform ~= nil then
		ForgeWindow.ForgeConpoundWidget:Hide()
	end
	if index ~= 4 then
		if ForgeWindow.ForgeEquipWidget.transform == nil then
			rkt.GResources.FetchGameObjectAsync( GuiAssetList.Forge.ForgeEquipWidget ,
				function ( path , obj , ud )
					if nil ==obj then   -- 判断U3D对象是否已经被销毁
						return
					end
					ForgeWindow.ForgeEquipWidget:Attach(obj)
					obj.transform:SetParent(ForgeWindow.transform,false)
					obj.transform:SetSiblingIndex(4)
					ForgeWindow.ForgeEquipWidget:ReloadData()
				end,"", AssetLoadPriority.GuiNormal )
		else
			ForgeWindow.ForgeEquipWidget:ReloadData()
		end
		
		if ForgeWindow.ForgeEquipWidget and ForgeWindow.ForgeEquipWidget.transform ~= nil then
			ForgeWindow.ForgeEquipWidget:Show()
		end
	end
	
	for i=1,4 do 
		if i == index then
			ForgeTypeShowOrHide[i].ShowFunc()
		else
			ForgeTypeShowOrHide[i].HideFunc()
		end
	end
	for i=1,3 do
		if self[ForgeTypeShowOrHide[i].Widget] then
			if self[ForgeTypeShowOrHide[i].Widget]:IsCanUpGrade() then
				self.Controls["m_TogRedDot"..i].gameObject:SetActive(true)
			else
				self.Controls["m_TogRedDot"..i].gameObject:SetActive(false)
			end
		end
	end
end

function ForgeWindow:RefreshTogRedDot()
	for i=1,3 do
		if self[ForgeTypeShowOrHide[i].Widget] then
			if self[ForgeTypeShowOrHide[i].Widget]:IsCanUpGrade() then
				self.Controls["m_TogRedDot"..i].gameObject:SetActive(true)
			else
				self.Controls["m_TogRedDot"..i].gameObject:SetActive(false)
			end
		end
	end
end

function ForgeWindow:RefreshWidget()
	if not self.m_CurForgeType or not ForgeTypeShowOrHide[self.m_CurForgeType] then
		return
	end
	ForgeTypeShowOrHide[self.m_CurForgeType].ShowFunc()
	if self.ForgeEquipWidget:isShow() then
		self.ForgeEquipWidget:ReloadData()
	end
end

function ForgeWindow:Refresh()
	self:RefreshTogRedDot()
	self:RefreshWidget()
end


-- 标签变化
function ForgeWindow:ChangeForgePage(on, index, EquipPlace)
	
	if not on then
		return
	end

	if EquipPlace then
		self:SetEquipPlace(EquipPlace)
	end

	if index == self.m_CurForgeType then -- 相同标签不用响应
		return
	end
	local ForgeOpenLv = {
		FORGE_SMELT_OPEN_LEVEL,
		FORGE_SETTING_OPEN_LEVEL,
		FORGE_SHUFFLE_OPEN_LEVEL,
		FORGE_SETTING_OPEN_LEVEL,
	}
	if GameHelp:GetHeroLevel() < ForgeOpenLv[index] then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, ForgeOpenLv[index].."级后开放！")
		return
	end
	
	if not self:isLoaded() then
        self.m_CurForgeType = index
		return
	end


	self:ShowType(index)
end

function ForgeWindow:OnEquipSelected(on)
	if not self:isLoaded() then
		return
	end
	local ForgeTypeRefresh = {
		[1] = self.ForgeSmeltWidget,
		[2] = self.ForgeSettingWidget,
		[3] = self.ForgeShuffleWidget,
	}
	if ForgeTypeRefresh[self.m_CurForgeType] == nil then
		return
	end
	
	ForgeTypeRefresh[self.m_CurForgeType]:Refresh()
end

function ForgeWindow:GetSelsctEquipPlace()
	return self.ForgeEquipWidget:GetSelsctEquipPlace()
end

-- 更新属性
function ForgeWindow:OnUpdateProp(EquipUID)
	print("事件来了")
	local hero = GetHero()
	if not hero then
		return
	end
	if not self:isShow() then
		return
	end
		
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	local SelsctEquipPlace = self:GetSelsctEquipPlace()
	
	local CurEquipUID = equipPart:GetGoodsUIDByPos(SelsctEquipPlace + 1)
	--print("当前显示UID : "..tostringEx(CurEquipUID))
	if CurEquipUID ~= EquipUID then
		return
	end
	local RefreshFunc = {
		"ForgeSmeltWidget",
		"",
		"ForgeShuffleWidget",
	}
	if not RefreshFunc[self.m_CurForgeType] then
		return
	end
	self[RefreshFunc[self.m_CurForgeType]]:Refresh()
	self.ForgeEquipWidget:ReloadData()
	--self.ForgeEquipWidget:SetForceScore(hero:GetNumProp(CREATURE_PROP_POWER))
end

-- 更新属性
function ForgeWindow:OnHeroUpdateProp()
--	print("事件来了")
	local hero = GetHero()
	if not hero then
		return
	end
	if not self:isShow() then
		return
	end

	local RefreshFunc = {
		"ForgeSmeltWidget",
		"ForgeSettingWidget",
		"ForgeShuffleWidget",
	}
	if not RefreshFunc[self.m_CurForgeType] then
		return
	end
	self[RefreshFunc[self.m_CurForgeType]]:Refresh()
	self.ForgeEquipWidget:SetForceScore(math.floor(hero:GetNumProp(CREATURE_PROP_POWER)/10) )
end


-- 添加新物品事件
function ForgeWindow:OnEventAddGoods()
	if not self:isShow() then
		return
	end
	self:ShowType(self.m_CurForgeType)
	self.ForgeEquipWidget:ReloadData()
end

-- 删除物品事件
function ForgeWindow:OnEventRemoveGoods()
	self:OnEventAddGoods()
end

-- 商城更新
function ForgeWindow:OnEventPlazaListUpdate()
	print("商城更新")
	if not self:isShow() then
		return
	end
	if self.m_CurForgeType == 4 then
		ForgeWindow.ForgeConpoundWidget:Refresh()
	end
end

function ForgeWindow:OnEventSetUpdate()
	if not self:isShow() then
		return
	end
	self.ForgeEquipWidget:ReloadData()
	self:Refresh()
end

function ForgeWindow:GetCurType()
	return self.m_CurForgeType
end


-- 订阅事件
function ForgeWindow:SubscribeEvent()
	self:InitCallbacks()
	rktEventEngine.SubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_GOODS, tEntity_Class_Equipment, self.callback_OnUpdateProp)
	rktEventEngine.SubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_PERSON, tEntity_Class_Person, self.callback_OnHeroUpdateProp)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
	rktEventEngine.SubscribeExecute(EVENT_PLAZA_LIST_UPDATE,SOURCE_TYPE_PLAZA,0,self.callback_OnEventPlazaListUpdate)
	rktEventEngine.SubscribeExecute(EVENT_FORGE_SET_UPDATE,0,0,self.callback_OnEventSetUpdate)
end

-- 取消订阅事件
function ForgeWindow:UnsubscribeEvent()
	rktEventEngine.UnSubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_GOODS, tEntity_Class_Equipment, self.callback_OnUpdateProp)
	rktEventEngine.UnSubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_PERSON, tEntity_Class_Person, self.callback_OnHeroUpdateProp)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_PLAZA_LIST_UPDATE,SOURCE_TYPE_PLAZA,0,self.callback_OnEventPlazaListUpdate)
	rktEventEngine.UnSubscribeExecute(EVENT_FORGE_SET_UPDATE,0,0,self.callback_OnEventSetUpdate)
end

-- 初始化全局回调函数
function ForgeWindow:InitCallbacks()
	self.callback_OnUpdateProp = function(event, srctype, srcid, UID) self:OnUpdateProp(UID) end
	self.callback_OnHeroUpdateProp = function(event, srctype, srcid, UID) self:OnHeroUpdateProp(UID) end
	self.callback_OnEventAddGoods = function() self:OnEventAddGoods() end
	self.callback_OnEventRemoveGoods = function() self:OnEventRemoveGoods() end
	self.callback_OnEventPlazaListUpdate = function() self:OnEventPlazaListUpdate() end
	self.callback_OnEventSetUpdate = function() self:OnEventSetUpdate() end
end

return ForgeWindow







