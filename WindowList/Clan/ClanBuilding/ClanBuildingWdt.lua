-- 帮会系统之帮会建筑主界面(分页)
-- @Author: LiaoJunXi
-- @Date:   2017-08-31 12:25:45
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-26 12:50:45

local ClanBuildingWdt = UIControl:new {
	windowName = "ClanBuildingWdt",
	
	m_Presenter = nil,
	m_BuildingItems = {},
	m_RefreshUICallback = nil,
	m_RefreshItemCallback = nil,
}

local ClanExchangeNPCID = 3

local GUIModulePath = "GuiSystem.WindowList.Clan.ClanBuilding."

---------- 公用重载的方法 -----------------------------------------------
local this = ClanBuildingWdt

function ClanBuildingWdt:Attach( obj )
	UIControl.Attach(self, obj)
	self.m_Presenter = IGame.ClanBuildingPresenter
	self.ChipExchangeWidget = require("GuiSystem.WindowList.ChipExchange.ChipExchangeWidget"):new()	-- 通用商城子窗口
	self.ChipExchangeWidget:Init()
	self:InitUI()
	self:SubscribeEvts()

	self.m_Presenter.isUIPrepared = true
end

function ClanBuildingWdt:OnDestroy()
	self.m_Presenter.isUIPrepared = false
	
	self:UnSubscribeEvts()
	self.m_RefreshUICallback = nil
	self.m_RefreshItemCallback = nil
	
	UIControl.OnDestroy(self)	
	table_release(self)
end

function ClanBuildingWdt:OnRecycle()
	self.m_Presenter.isUIPrepared = false
	
	self:UnSubscribeEvts()
	self.m_RefreshUICallback = nil
	self.m_RefreshItemCallback = nil
	
	UIControl.OnRecycle(self)	
	table_release(self)
end

function ClanBuildingWdt:Hide(destory)
	if self.ChipExchangeWidget then
		self.ChipExchangeWidget:Hide()
	end
	UIControl.Hide(self)
end

function ClanBuildingWdt:InitUI()
	local controls = self.Controls
	
	local m_ItemLua = require( GUIModulePath.."ClanBuildingItem" )
	
	local m_ShrineScript = m_ItemLua:new({})
	m_ShrineScript:Attach(controls.m_ClanShrine.gameObject)
	self.m_BuildingItems.m_ShrineItem = m_ShrineScript
	self.m_BuildingItems.m_ShrineItem:SetSelectCallback(handler(self, self.OnClickShrineItem))
	
	local m_AcademyScript = m_ItemLua:new({})
	m_AcademyScript:Attach(controls.m_ClanAcademy.gameObject)
	self.m_BuildingItems.m_AcademyItem = m_AcademyScript
	self.m_BuildingItems.m_AcademyItem:SetSelectCallback(handler(self, self.OnClickAcademyItem))
	
	local m_WelfareScript = m_ItemLua:new({})
	m_WelfareScript:Attach(controls.m_ClanWelfare.gameObject)
	self.m_BuildingItems.m_WelfareItem = m_WelfareScript
	self.m_BuildingItems.m_WelfareItem:SetSelectCallback(handler(self, self.OnClickWelfareItem))
	
	local m_PresbyterScript = m_ItemLua:new({})
	m_PresbyterScript:Attach(controls.m_ClanPresbyter.gameObject)
	self.m_BuildingItems.m_PresbyterItem = m_PresbyterScript
	self.m_BuildingItems.m_PresbyterItem:SetSelectCallback(handler(self, self.OnClickPresbyterItem))
	
	local m_WarfareScript = m_ItemLua:new({})
	m_WarfareScript:Attach(controls.m_ClanWarfare.gameObject)
	self.m_BuildingItems.m_WarfareItem = m_WarfareScript
	self.m_BuildingItems.m_WarfareItem:SetSelectCallback(handler(self, self.OnClickWarfareItem))
	
	local m_TresonScript = m_ItemLua:new({})
	m_TresonScript:Attach(controls.m_ClanTreson.gameObject)
	self.m_BuildingItems.m_TresonItem = m_TresonScript
	self.m_BuildingItems.m_TresonItem:SetSelectCallback(handler(self, self.OnClickTresonItem))
	
	-- 注册红点事件
	local nParentLayout = self.m_Presenter:GetLayout()["建筑分页"]
	SysRedDotsMgr.Register(nParentLayout,"福利按钮",controls.m_ClanWelfare,"m_ClanWelfare",handler(self, self.OnWelfareHintStatus))
	
	if not self.m_Presenter.isIssued then
		self:RefreshUI()
	end
end

function ClanBuildingWdt:OnWelfareHintStatus()
	if not self.m_Presenter.GetLayout then return end
	local partLayout = self.m_Presenter:GetLayout()
	local nParentLayout = partLayout["建筑分页"]
	local result = self.m_Presenter:IsUnclaimed() 
	SysRedDotsMgr.SetVisible(nParentLayout,"福利按钮","m_ClanWelfare",result)
end

function ClanBuildingWdt:CheckWelfareHintStatus()
	local nParentLayout = self.m_Presenter:GetLayout()["建筑分页"]
	SysRedDotsMgr.Check(nParentLayout,"福利按钮")
end

function ClanBuildingWdt:SubscribeEvts()
	self.m_RefreshUICallback = handler(self, self.RefreshUI)
	rktEventEngine.SubscribeExecute(EVENT_CLAN_BUILDING_LIST_REFRESH, SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
	self.m_RefreshItemCallback = handler(self, self.RefreshItem)
	rktEventEngine.SubscribeExecute(EVENT_CLAN_MAP_BUILDING_UPGRADE, SOURCE_TYPE_CLAN, 0, self.m_RefreshItemCallback)
end

function ClanBuildingWdt:UnSubscribeEvts()
	rktEventEngine.UnSubscribeVote(EVENT_CLAN_BUILDING_LIST_REFRESH , SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
	rktEventEngine.UnSubscribeVote(EVENT_CLAN_MAP_BUILDING_UPGRADE, SOURCE_TYPE_CLAN, 0, self.m_RefreshItemCallback)
end

function ClanBuildingWdt:Show()
	UIControl.Show(self)
	if not self:isLoaded() then
		return
	end

	if not self.m_Presenter.isIssued then
		self:RefreshUI()
	end
end
--------------------------------------------------------------------------

------------- 点击Item回调的方法 ---------------
-- 点击主殿
function ClanBuildingWdt:OnClickShrineItem()
	UIManager.ClanShrineWindow:ShowWindow()
end

-- 点击研究院
function ClanBuildingWdt:OnClickAcademyItem()
	if not self.m_Presenter.ClanAcademy then return end
	if self.m_Presenter.ClanAcademy.m_Unlock then
		-- 技能的数据是一登入就随人物下发的，存储在人物数据的技能部件里,所以每次打开界面时去筹备数据即可。
		UIManager.ClanAcademyWindow:ShowWindow()
	else
		self:ShowUnlockTip()
	end
end

-- 点击福利院
function ClanBuildingWdt:OnClickWelfareItem()
	if not self.m_Presenter.ClanWelfare then return end
	if self.m_Presenter.ClanWelfare.m_Unlock then
		self.m_Presenter.isUIWelfareClicked = true
		self.m_Presenter:PrepareWelfareData()
	else
		self:ShowUnlockTip()
	end
end

-- 点击长老院
function ClanBuildingWdt:OnClickPresbyterItem()
	if not self.m_Presenter.ClanPresbyter then return end
	if self.m_Presenter.ClanPresbyter.m_Unlock then
		self.m_Presenter:PreparePresbyterData()
	else
		self:ShowUnlockTip()
	end
end

-- 点击战争学院
function ClanBuildingWdt:OnClickWarfareItem()
	if not self.m_Presenter.ClanWarfare then return end
	if self.m_Presenter.ClanWarfare.m_Unlock then
		self.m_Presenter:PrepareWarfareData()
	else
		self:ShowUnlockTip()
	end
end

-- 点击珍宝阁
function ClanBuildingWdt:OnClickTresonItem()
	if not self.m_Presenter.ClanTreson then return end
	if self.m_Presenter.ClanTreson.m_Unlock then
		IGame.ChipExchangeClient:OpenChipExchangeShop(ClanExchangeNPCID, 0, 1, "Clan" )
	else
		self:ShowUnlockTip()
	end
end

function ClanBuildingWdt:ShowChipExchange(npcid,nSubType,nSelectIndex)
	if not self.ChipExchangeWidget:isLoaded() then
		self.ChipExchangeWidget:FetchWidget(UIManager.ClanOwnWindow.Controls.m_ChipExchangeBG)
	end
	self.ChipExchangeWidget:ShowWidget(npcid,nSubType,nSelectIndex)
end

function ClanBuildingWdt:IsExchengeShow()
	return self.ChipExchangeWidget and self.ChipExchangeWidget:isShow()
end

function ClanBuildingWdt:ExchengeHide()
	if not self.ChipExchangeWidget then
		return
	end
	self.ChipExchangeWidget:Hide()
end

function ClanBuildingWdt:ShowUnlockTip()
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "建筑尚未解锁,请先到主殿解锁该建筑！")
end
------------------------------------------------

------------- 刷新界面显示 ---------------
function ClanBuildingWdt:RefreshUI()
	if not self.m_Presenter then return end
	self.m_Presenter.isIssued = true
	if isTableEmpty(self.m_BuildingItems) then return end
	self.m_BuildingItems.m_ShrineItem:SetItemContent(self.m_Presenter.ClanShrine)
	self.m_BuildingItems.m_AcademyItem:SetItemContent(self.m_Presenter.ClanAcademy)
	self.m_BuildingItems.m_WelfareItem:SetItemContent(self.m_Presenter.ClanWelfare)
	self.m_BuildingItems.m_PresbyterItem:SetItemContent(self.m_Presenter.ClanPresbyter)
	self.m_BuildingItems.m_WarfareItem:SetItemContent(self.m_Presenter.ClanWarfare)
	self.m_BuildingItems.m_TresonItem:SetItemContent(self.m_Presenter.ClanTreson)
	
	self:CheckWelfareHintStatus()
end

function ClanBuildingWdt:RefreshItem(event, srctype, srcid, data)
	print(debug.traceback("<color=red>ClanBuildingWdt:RefreshItem("..data.nID..")</color>"))
	if not isTableEmpty(self.m_Presenter.BdName) then
		self.m_BuildingItems["m_"..self.m_Presenter.BdName[data.nID].."Item"]:
		SetItemContent(self.m_Presenter:GetBuildingByID(data.nID))
	end
end
------------------------------------------

return ClanBuildingWdt