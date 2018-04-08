-- 帮会长老院的窗口
-- @Author: LiaoJunXi
-- @Date:   2017-09-06 19:36:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-30 12:22:48

local ClanPresbyterWindow = UIWindow:new
{
	windowName        = "ClanPresbyterWindow",
	
	m_Presenter = nil,
	m_ActivityCells = {}, -- 当前显示的活动项缓存
	m_ScheduleCells = {},
	m_SelActivityIdx = 1, --当前选择的活动格
	m_SelScheduleIdx = 1,
}

require("GuiSystem.WindowList.Clan.ClanSysDef")
local ClanPresbyterActivityCell = require(ClanSysDef.ClanBuildingPath .. "ClanPresbyterActivityCell")
local ClanPresbyterScheduleCell = require(ClanSysDef.ClanBuildingPath .. "ClanPresbyterScheduleCell")

-----------------------------公共重载方法-------------------------------
function ClanPresbyterWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.m_Presenter = IGame.ClanBuildingPresenter
	
	self:InitUI()
	self:CreateMenu()
	--self:ShowUI()
end

function ClanPresbyterWindow:InitUI()
	local controls = self.Controls

	-- init list tgl group, cell prefab
	local scrollView  = controls.m_ActivityScrollView
	controls.activityGroup  = scrollView:GetComponentInChildren(typeof(ToggleGroup))	
	controls.m_ActivityCellContainer = scrollView.content
	scrollView = controls.m_ScheduleScrollView
	controls.scheduleGroup  = scrollView:GetComponentInChildren(typeof(ToggleGroup))	
	controls.m_ScheduleCellContainer = scrollView.content
	------------------------------------------------
	
	-- BtnFunc for <Detailed>
	controls.m_DetailedBtn.onClick:AddListener(handler(self, self.OnBtnDetailedClicked))
end

function ClanPresbyterWindow:Hide(destroy)
	UIWindow.Hide(self, destory)
end

-- 界面销毁
function ClanPresbyterWindow:OnDestroy()
	self.m_Presenter = nil
	
	UIWindow.OnDestroy(self)
	table_release(self)
	
	self.m_SelActivityIdx = 1
	self.m_SelScheduleIdx = 1
end

----------------------- 刷新UI -------------------------
function ClanPresbyterWindow:CreateMenu()
	local schedList = self.m_Presenter:GetPresbyterScheduleList()
	if not schedList then return end
	local count = #schedList

	for i=1, count do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.ClanBuilding.ClanPresbyterScheduleCell,
		
		function ( path , obj , ud ) 
			local controls = self.Controls
			
			obj.transform:SetParent(controls.m_ScheduleCellContainer)
			obj.transform.localScale = Vector3.New(1,1,1)
			
			local cell = ClanPresbyterScheduleCell:new({})
			cell:Attach(obj)
			
			cell:SetToggleGroup(controls.scheduleGroup)
			cell:SetSelectCallback(handler(self, self.OnScheduleCellSelected))
			-- 刷新Cell
			self:RefreshScheduleCell(i, cell)
			
			table.insert(self.m_ScheduleCells,i,cell)
			
		end , i , AssetLoadPriority.GuiNormal )
	end
end

-- 刷新 Skill Cell
function ClanPresbyterWindow:RefreshScheduleCell(idx, cell)
	if not cell then cell = self.m_ScheduleCells[idx] end
	cell:SetCellData(idx, self.m_Presenter:GetPresbyterScheduleData(idx))
	
	if self.m_SelScheduleIdx == 0 then
		self.m_SelScheduleIdx = 1
	end
	--[[if idx == self.m_SelScheduleIdx and cell:IsToggleOn() then
		self:OnScheduleCellSelected(idx)
	end--]]
	cell:SetToggleIsOn(idx == self.m_SelScheduleIdx)
end

function ClanPresbyterWindow:RefreshUI(exceptInfo)
	if not self:isShow() then
		return
	end
	self:RefreshInfo()
	self:HideCells()
	self:CreateCells()
end

function ClanPresbyterWindow:RefreshInfo()
	local controls = self.Controls
	local nEldersTarget = self.m_Presenter.m_BuildingModel:GetEldersObj()
	
	controls.m_CurrentScroe.text = tostring(self.m_Presenter.m_Presbyter.m_Obj.m_nTotalScore)
	controls.m_CurrentDividend.text = self.m_Presenter.m_Presbyter.m_DividendTxt
	controls.m_WageIcon.enabled = nEldersTarget.m_nCurDividend > 0
end

-- 销毁Skill Cell List的所有Cell，释放table
function ClanPresbyterWindow:HideCells()
	for i,cell in pairs(self.m_ActivityCells) do
		cell:Hide()
	end
	--self.m_ActivityCells = {}
end

-- Wage Cell List
function ClanPresbyterWindow:CreateCells()
	--print(debug.traceback("ClanPresbyterWindow:CreateCells"))
	local actList = self.m_Presenter:GetPresbyterActivityList(self.m_SelScheduleIdx)
	if not actList then return end
	local count = #actList

	for i=1, count do	
		local cell = self.m_ActivityCells[i]
		if not cell then
			rkt.GResources.FetchGameObjectAsync( GuiAssetList.ClanBuilding.ClanPresbyterActivityCell,
			function ( path , obj , ud ) 
				local controls = self.Controls
				obj.transform:SetParent(controls.m_ActivityCellContainer)
				obj.transform.localScale = Vector3.New(1,1,1)
				cell = ClanPresbyterActivityCell:new({})
				cell:Attach(obj)
				table.insert(self.m_ActivityCells,i,cell)
				
				cell:SetToggleGroup(controls.activityGroup)
				cell:SetSelectCallback(handler(self, self.OnItemCellSelected))
				cell:Show()
				self:RefreshActivityCell(i, cell)
			end , i , AssetLoadPriority.GuiNormal )
		else
			cell:Show()
			self:RefreshActivityCell(i, cell)
		end
	end
end

-- 刷新 Skill Cell
function ClanPresbyterWindow:RefreshActivityCell(idx, cell)
	if not cell then cell = self.m_ActivityCells[idx] end
	cell:SetCellData(idx, self.m_Presenter:GetPresbyterActivityData(idx))
	
	if self.m_SelActivityIdx == 0 then
		self.m_SelActivityIdx = 1
	end
	if idx == self.m_SelActivityIdx and cell:IsToggleOn() then
		self:OnItemCellSelected(idx)
	end
	cell:SetToggleIsOn(idx == self.m_SelActivityIdx)
end

-----------------------界面响应事件方法-------------------------
-- 显示窗口
function ClanPresbyterWindow:ShowWindow()
	print("ClanPresbyterWindow:ShowWindow")
	UIWindow.Show(self, true)
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(self, self.OnBtnCloseClicked)
	if not self:isLoaded() then
		return
	end
	self:ShowUI()
end

function ClanPresbyterWindow:ShowUI()
	print("ClanPresbyterWindow:ShowUI()")
	
	self:RefreshUI()
end

-- 选中建筑Cell后，Cell的Toggle回调
function ClanPresbyterWindow:OnItemCellSelected(idx)
	local data = self.m_Presenter:GetPresbyterActivityData(idx)
	if not data then self.m_SelActivityIdx = 1 return end
	self.m_SelActivityIdx = idx
end

function ClanPresbyterWindow:OnScheduleCellSelected(idx)
	local data = self.m_Presenter:GetPresbyterScheduleData(idx)
	if not data then self.m_SelScheduleIdx = 1 return end
	self.m_SelScheduleIdx = idx
	self:RefreshUI()
end

-- 界面隐藏
function ClanPresbyterWindow:OnBtnCloseClicked()
	self:Hide()
	local owenWin = UIManager.ClanOwnWindow
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(owenWin, owenWin.Hide)
end

-- 查看帮助
function ClanPresbyterWindow:OnBtnDetailedClicked()
	UIManager.CommonGuideWindow:ShowWindow(31)
end

return ClanPresbyterWindow