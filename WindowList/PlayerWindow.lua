-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    星辰互动
-- 日  期:    2017年5月2日
-- 版  本:    1.0
-- 描  述:    人物窗口
-------------------------------------------------------------------
local PlayerWindow = UIWindow:new
{
	windowName = "PlayerWindow",
	tabName = {
		emProperty = 1,
		emTitle = 2,
		emRank = 3,
		emMax = 4,
	},
	curTab = 0,
	bSubExecute = false,
}

local titleImagePath = AssetPath.TextureGUIPath.."Character/Character_renwu.png"
------------------------------------------------------------
function PlayerWindow:Init()
    self.ModelWidget = require("GuiSystem.WindowList.Player.PlayerModelWidget")
	self.PropertyWidget = require("GuiSystem.WindowList.Player.PlayerPropertyWidget")
	self.PlayerEquipWidget = require("GuiSystem.WindowList.Player.PlayerEquipWidget")
	self:InitCallbacks()
end
------------------------------------------------------------
function PlayerWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	--self.ModelWidget:Attach(self.transform:Find("Player_Model_Wight").gameObject)
	--self.PropertyWidget:Attach(self.transform:Find("Pages/PlayerPropertyWight").gameObject)
	--self.PlayerEquipWidget:Attach( self.transform:Find("Player_Equip_Wight").gameObject )
	self.callback_OnCloseButtonClick =	function()
										self.curTab = 0
										self:Hide()
										self.PlayerEquipWidget:ShowHeroModel(false)
									end
	UIWindow.AddCommonWindowToThisWindow(self,true,titleImagePath,self.callback_OnCloseButtonClick,nil,function() self:SetFullScreen() end,true)

	-- 注册选项卡事件
	for i = 1, 3 do
		self.Controls["m_OptionBarTog"..i].onValueChanged:AddListener(function(on) self:OnOptionBarTogClick(on, i) end)
		self.Controls.m_TogGrop.transform:Find("OptionBarTog ("..i..")/Background").gameObject:SetActive(true)
		self.Controls.m_TogGrop.transform:Find("OptionBarTog ("..i..")/Checkmark").gameObject:SetActive(false)
	end
	self:SubscribeWinEvent()
	if GetHero():GetNumProp(CREATURE_PROP_LEVEL) < 30 then
		self.Controls["m_OptionBarTog2"].gameObject:SetActive(false)
	else
		self.Controls["m_OptionBarTog2"].gameObject:SetActive(true)
	end
	self:ShowType( self.curTab )
end

function PlayerWindow:OnDestroy()
	UIWindow.OnDestroy(self)
	self:UnsubscribeWinEvent()
	self.PlayerEquipWidget:OnDestroy()
end

function PlayerWindow:Show(bringTop)
	GetHero():ObservePersonPropChange(true)
	UIWindow.Show(self,bringTop)
end

function PlayerWindow:Hide()
	UIWindow.Hide(self)
	PlayerWindow.HideTitle()
	GetHero():ObservePersonPropChange(false)
end

-- 标签变化
function PlayerWindow:OnOptionBarTogClick(on, tabName)
	if not on then
		self.Controls.m_TogGrop.transform:Find("OptionBarTog ("..tabName..")/Background").gameObject:SetActive(true)
		self.Controls.m_TogGrop.transform:Find("OptionBarTog ("..tabName..")/Checkmark").gameObject:SetActive(false)
		return
	else
		self.Controls.m_TogGrop.transform:Find("OptionBarTog ("..tabName..")/Background").gameObject:SetActive(false)
		self.Controls.m_TogGrop.transform:Find("OptionBarTog ("..tabName..")/Checkmark").gameObject:SetActive(true)
	end
	if self.curTab == tabName then -- 相同标签不用响应
		return
	end
	for i = 1, 3 do
		if tabName == i then
			self.Controls["m_OptionBarTog"..i].isOn = true
		else
			self.Controls["m_OptionBarTog"..i].isOn = false
		end
	end	
	self.curTab = tabName
	self:ShowType(tabName)
end

function PlayerWindow.ShowProperty()
	if PlayerWindow.ModelWidget.transform == nil then
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.Player.PlayerModelWidget ,
			function ( path , obj , ud )
				if nil ==obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				local item = PlayerWindow.ModelWidget
				item:Attach(obj)
				obj.transform:SetParent(PlayerWindow.transform,false)
				obj.transform:SetSiblingIndex(3)
				item:Refresh()
			end,"", AssetLoadPriority.GuiNormal )
	else
		PlayerWindow.ModelWidget:Refresh()
		PlayerWindow.transform:Find("Player_Model_Wight(Clone)").gameObject:SetActive(true)
	end
	
	if PlayerWindow.PropertyWidget.transform == nil then
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.Player.PlayerPropertyWidget ,
			function ( path , obj , ud )
				if nil ==obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				local item = PlayerWindow.PropertyWidget
				item:Attach(obj)
				obj.transform:SetParent(PlayerWindow.transform:Find("Pages"),false)
				obj.transform:SetSiblingIndex(0)
				item:Refresh()
			end,"", AssetLoadPriority.GuiNormal )
	else
		PlayerWindow.PropertyWidget:Refresh()
		PlayerWindow.transform:Find("Pages/PlayerPropertyWight(Clone)").gameObject:SetActive(true)
	end
	
	if PlayerWindow.PlayerEquipWidget.transform == nil then
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.Player.PlayerEquipWidget ,
			function ( path , obj , ud )
				if nil ==obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				local item = PlayerWindow.PlayerEquipWidget
				item:Attach(obj)
				obj.transform:SetParent(PlayerWindow.transform,false)
				obj.transform:SetSiblingIndex(1)
				item:ReloadData()
			end,"", AssetLoadPriority.GuiNormal )
	else
		PlayerWindow.PlayerEquipWidget:ReloadData()
		PlayerWindow.transform:Find("Player_Equip_Wight(Clone)").gameObject:SetActive(true)
	end
end

function PlayerWindow.HideProperty()
	if not PlayerWindow.transform then
		return
	end
	local wdt = PlayerWindow.transform:Find("Player_Model_Wight(Clone)")
	if wdt then wdt.gameObject:SetActive(false) end
	wdt = PlayerWindow.transform:Find("Pages/PlayerPropertyWight(Clone)")
	if wdt then wdt.gameObject:SetActive(false) end
	wdt = PlayerWindow.transform:Find("Player_Equip_Wight(Clone)")
	if wdt then wdt.gameObject:SetActive(false) end
end

function PlayerWindow.ShowRank()
	--PlayerWindow.Controls.m_PageSet.gameObject:SetActive(true)
end

function PlayerWindow.HideRank()
	--PlayerWindow.Controls.m_PageSet.gameObject:SetActive(false)
end

function PlayerWindow.ShowTitle()
	UIManager.TitleWindow:Show()
end

function PlayerWindow.HideTitle()
	UIManager.TitleWindow:Hide()
end

local PlayerTypeShowOrHide = {
	[1] = {ShowFunc = PlayerWindow.ShowProperty,	HideFunc = PlayerWindow.HideProperty},
	[2] = {ShowFunc = PlayerWindow.ShowTitle,	HideFunc = PlayerWindow.HideTitle},	
	[3] = {ShowFunc = PlayerWindow.ShowRank,		HideFunc = PlayerWindow.HideRank},
}

function PlayerWindow:ShowType(index)
	self.curTab = index or 1
	if not self:isLoaded() then
		return
	end
	self.Controls.m_TogGrop.transform:Find("OptionBarTog ("..self.curTab..")/Background").gameObject:SetActive(false)
	self.Controls.m_TogGrop.transform:Find("OptionBarTog ("..self.curTab..")/Checkmark").gameObject:SetActive(true)
	self.Controls["m_OptionBarTog"..self.curTab].isOn = true
	for i=1,3 do 
		if i == index then
			PlayerTypeShowOrHide[i].ShowFunc()
		else
			PlayerTypeShowOrHide[i].HideFunc()
		end
	end
end

-- 脱装备
function PlayerWindow:OnEventUnEquip(fromPlace)
	if not fromPlace or type(fromPlace) ~= "number" then
		return
	end
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
	if self.curTab == 1 then
		self.PlayerEquipWidget:ClearCell(fromPlace)
	end
end

-- 更新属性
function PlayerWindow:OnUpdateProp(msg)
	
	if not self:isShow() then
		self.NeedReload = true
		return
	end
    
    local hero = GetHero()
    if not hero then
        return
    end
    
    if tostring(msg.uidEntity) ~= tostring(hero:GetUID()) then
        return
    end
    
	if self.curTab == 1 then
		self.PropertyWidget:Refresh()
	end
	self.ModelWidget:Refresh()
end

-- 订阅事件
function PlayerWindow:SubscribeWinEvent()
	if self.bSubExecute then
		return
	end
	rktEventEngine.SubscribeExecute(EVENT_SKEP_UNEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventUnEquip)
	rktEventEngine.SubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_PERSON, tEntity_Class_Person, self.callback_OnUpdateProp)
	self.bSubExecute = true
end

-- 取消订阅事件
function PlayerWindow:UnsubscribeWinEvent()
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_UNEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventUnEquip)
	rktEventEngine.UnSubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_PERSON, tEntity_Class_Person, self.callback_OnUpdateProp)
	self.bSubExecute = false
end

-- 初始化全局回调函数
function PlayerWindow:InitCallbacks()
	self.callback_OnEventUnEquip = function(event, srctype, srcid, fromPlace) self:OnEventUnEquip(fromPlace) end
	self.callback_OnUpdateProp = function(event, srctype, srcid, msg) self:OnUpdateProp(msg) end
end

return PlayerWindow