-- 帮会主殿的窗口
-- @Author: LiaoJunXi
-- @Date:   2017-08-31 19:36:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-30 12:22:48

local ClanShrineWindow = UIWindow:new
{
	windowName        = "ClanShrineWindow",
	
	m_Presenter = nil,
	m_BuildingCells = {},
	m_RefreshUICallback = nil,
	m_SelCellIdx = 1, --当前选择的建筑格
	m_BuildDemandCapacity = 4,
	m_FirstEnter = true,
}

require("GuiSystem.WindowList.Clan.ClanSysDef")
local ClanBuildingCell = require(ClanSysDef.ClanBuildingPath .. "ClanBuildingCell")

-----------------------------公共重载方法-------------------------------
-- 初始化
function ClanShrineWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.m_Presenter = IGame.ClanBuildingPresenter
	
	self:InitUI()
	self:SubscribeEvts()
end

function ClanShrineWindow:InitUI()
	local controls = self.Controls
	controls.m_UpgradeBtn.onClick:AddListener(handler(self, self.OnBtnUpgradeClicked))
	
	local scrollView  = controls.m_ScrollView
	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(handler(self, self.OnGetCellView))
	listView.onCellViewVisiable:AddListener(handler(self, self.OnCellRefreshVisible))
	controls.listView = listView
	
	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller
	
	controls.listTglGroup  = controls.m_ViewPort:GetComponent(typeof(ToggleGroup))
	
	self:RefreshUI()
end

function ClanShrineWindow:SubscribeEvts()
	self.m_RefreshUICallback = handler(self, self.RefreshUI)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_SHRINE_BUILDING_UPGRADE, SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
end

function ClanShrineWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeVote(EVENT_CLAN_SHRINE_BUILDING_UPGRADE , SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
end

-- 界面销毁
function ClanShrineWindow:OnDestroy()
	self:UnSubscribeEvts()
	self.m_Presenter = nil
	self.m_RefreshUICallback = nil
	UIWindow.OnDestroy(self)
	table_release(self)
	
	self.m_SelCellIdx = 1
	self.m_BuildDemandCapacity = 4
	self.m_FirstEnter = true
end

-- EnhancedListView 一行被“创建”时的回调
function ClanShrineWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnCellRefreshVisible)
	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function ClanShrineWindow:OnCellRefreshVisible( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- 创建条目
function ClanShrineWindow:CreateCellItems( listcell )
	local item = ClanBuildingCell:new({})
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.Controls.listTglGroup)
	item:SetSelectCallback(handler(self, self.OnItemCellSelected))
	
	local idx = listcell.dataIndex + 1
	self.m_BuildingCells[idx] = item
end

--- 刷新列表
function ClanShrineWindow:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject

	local idx = listcell.dataIndex + 1
	if self.m_Presenter then
		local m_BuildingList = self.m_Presenter:GetBuildingDataList()
		item:SetCellData(idx, m_BuildingList[idx])
		if self.m_SelCellIdx == 0 then
			self.m_SelCellIdx = 1
		end
		if idx == self.m_SelCellIdx and item:IsToggleOn() then
			self:OnItemCellSelected(idx)
		end
		item:SetToggleIsOn(idx == self.m_SelCellIdx)
	end
end
------------------------------------------------------------

----------------------- 刷新UI -------------------------
function ClanShrineWindow:RefreshUI()
	if not self:isShow() then
		--return
	end
	
	local m_BuildingList = self.m_Presenter:GetBuildingDataList()
	
	self.Controls.listTglGroup:SetAllTogglesOff()
	
	local listView = self.Controls.listView
	local bdCnt = #m_BuildingList
	
	listView:SetCellCount( bdCnt , false )
	self.Controls.listScroller:ReloadData()
	
	--if not self.m_FirstEnter then -- 非第一次进入，保持原先位置不变，只刷新当前界面活动的元素
		self.Controls.listScroller:Resize(true)
		--self.Controls.listScroller:RefreshActiveCellViews()
		
	if self.m_FirstEnter and bdCnt > 0 then -- 第一次进入，ReloadData操作默认位置为顶部
		self.m_FirstEnter = false
		self:SelectBuildingCell(self.m_SelCellIdx)
	end
	
	if self.Controls.listScroller then
		local nLayoutGroup = self.Controls.listScroller.gameObject:GetComponentInChildren(typeof(UnityEngine.UI.VerticalLayoutGroup))
		if nLayoutGroup then
			nLayoutGroup.childForceExpandHeight = false
		end
	end
end

function ClanShrineWindow:SetSelBuildingDesc(idx)
	local data = self.m_Presenter.m_BuildingList[idx]
	if data == nil then
		self.m_SelCellIdx = 1
		return
	end
	
	local controls = self.Controls
	controls.m_NameTxt.text = data.m_BaseCfg.Name
	controls.m_LevTxt.text = GetValuable(data.m_Unlock, data.nLevel .. "级", "<color=#E4595A>未解锁</color>")
	controls.m_DemandTxt.text = data.m_DemandDesc
	
	controls.m_UnlockLabel.enabled = not data.m_Unlock
	controls.m_UpgradeLabel.enabled = data.m_Unlock
	
	self:SetBuildingDemandDesc(data)
	
	-- 这里资金满足需要动态判断
	local m_Funds = IGame.ClanClient:GetClanData(emClanProp_Funds)
	if not data.m_IsMaxLev then
		data.m_Satisfy = (data.m_Cost <= m_Funds)
		local color = GetValuable(data.m_Satisfy, "<color=#597993FF>", "<color=#E4595A>")
		controls.m_CostTxt.text = tostring(data.m_Cost)
		controls.m_HasTxt.text = color .. m_Funds .. "</color>"
	else
		controls.m_CostTxt.text = "<color=#10a41b>已满级</color>"
		controls.m_HasTxt.text = tostring(m_Funds)
		controls["m_BuildingDemand_1"].gameObject:SetActive(true)
		controls["m_DemandDescTxt_1"].text = "<color=#10a41b>已满级</color>"
		for i = 2, self.m_BuildDemandCapacity do
			controls["m_BuildingDemand_"..i].gameObject:SetActive(false)
		end
	end
	UIFunction.SetComsGray(controls.m_UpgradeBtn.gameObject, data.m_IsMaxLev, {typeof(Image)})
	controls.m_Regulations.text = (string.gsub(data.m_LevCfg.Desc, "\\n", "\n"))
	
	controls.m_UpgradeBtn.gameObject:SetActive((self.m_Presenter:IsIDentity(emClanIdentity_Shaikh) or
	self.m_Presenter:IsIDentity(emClanIdentity_Underboss)) )
	
	if nil ~= data.m_LevCfg.Icon and "" ~= data.m_LevCfg.Icon then
		UIFunction.SetImageSprite(self.Controls.m_IconImg, GuiAssetList.GuiRootTexturePath .. data.m_LevCfg.Icon)
	end
end 

function ClanShrineWindow:SetBuildingDemandDesc(data)
	local controls = self.Controls
	if nil ~= data.m_Demand and type(data.m_Demand) == "table" then
		local capacity = 1
		--print(debug.traceback("<color=white>self.m_BuildDemandCapacity = "..self.m_BuildDemandCapacity.."</color>"))
		for i = 1, #data.m_Demand do
			if i <= self.m_BuildDemandCapacity then
				controls["m_DemandDescTxt_"..i].text = data.m_Demand[i]
				controls["m_BuildingDemand_"..i].gameObject:SetActive(true)
				capacity = capacity + 1
			end
		end
		if capacity <= self.m_BuildDemandCapacity then
			for k = capacity, self.m_BuildDemandCapacity do
				controls["m_BuildingDemand_"..k].gameObject:SetActive(false)
			end
		end
	else
		print("<color=#E4595A>错误：建筑的前置建筑要求为空或者不是table</color>")
	end
end

-----------------------界面响应事件方法-------------------------
-- 显示窗口
function ClanShrineWindow:ShowWindow()
	UIWindow.Show(self, true)
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(self, self.OnBtnCloseClicked)
end

-- 选中对应建筑类型的Cell
function ClanShrineWindow:SelectBuildingCell(idx)
	if self.m_Presenter and self.m_Presenter.m_BuildingList and self.m_BuildingCells[idx] then
		local item = self.m_BuildingCells[idx]
		if item:IsToggleOn() then
			self:OnItemCellSelected(idx)
		end
		item:SetToggleIsOn(true)
	end
end

-- 选中建筑Cell后，Cell的Toggle回调
function ClanShrineWindow:OnItemCellSelected(idx)
	local data = self.m_Presenter.m_BuildingList[idx]
	if data == nil then
		self.m_SelCellIdx = 1
		return
	end
	
	self.m_SelCellIdx = idx
	
	self:SetSelBuildingDesc(idx)
end

function ClanShrineWindow:OnBtnUpgradeClicked()
	if self.m_Presenter:IsIDentity(emClanIdentity_Shaikh) or 
		self.m_Presenter:IsIDentity(emClanIdentity_Underboss) then
		local m_BuildingList = self.m_Presenter:GetBuildingDataList()
		local id = m_BuildingList[self.m_SelCellIdx].nID
		print("<color=white>ClanShrineWindow:OnBtnUpgradeClicked()</color>")
		IGame.ClanClient.m_ClanBuildingManager:RsqBuildingUpgrade(id)
	else
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你没有建设或升级的权限！")
	end
end

-- 界面隐藏
function ClanShrineWindow:OnBtnCloseClicked()
	self:Hide()
	local owenWin = UIManager.ClanOwnWindow
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(owenWin, owenWin.Hide)
end

return ClanShrineWindow