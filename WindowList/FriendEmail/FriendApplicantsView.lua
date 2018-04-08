-- 申请添加玩家为好友的所有玩家的申请消息的列表界面
-- @Author: LiaoJunXi
-- @Date:   2017-07-27 17:50:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-27 18:05:08

local FriendApplicantsView = UIControl:new
{
	windowName = "FriendApplicantsView",
	m_RefreshUICallback = nil,
	m_FriendClient = nil,
	m_SelCellIdx = 1,
	m_ApplicantCells = {},
}
local FriendApplicantCell = require( "GuiSystem.WindowList.FriendEmail.FriendApplicantCell" )

------------------------------------------公共重载方法开始------------------------------------------
function FriendApplicantsView:Attach( obj )
	UIControl.Attach(self, obj)
	
	self.m_FriendClient = IGame.FriendClient
	self:InitUI()
	
	self:SubscribeEvts()
end

function FriendApplicantsView:OnDestroy()
	self:UnSubscribeEvts()
	self.m_RefreshUICallback = nil
	UIControl.OnDestroy(self)	
	table_release(self)
	self.m_SelCellIdx = 1
end

function FriendApplicantsView:OnRecycle()
	self:UnSubscribeEvts()
	self.m_RefreshUICallback = nil
	UIControl.OnRecycle(self)
	table_release(self)
	self.m_SelCellIdx = 1
end

function FriendApplicantsView:Hide(destory)
	UIControl.Hide(self)
end

function FriendApplicantsView:Show()
	UIControl.Show(self)
	
	self:RefreshUI()
end

function FriendApplicantsView:SubscribeEvts()
	self.m_RefreshUICallback = handler(self, self.RefreshUI)
	rktEventEngine.SubscribeExecute( EVENT_FRIEND_UPDATE_APPLICANTLIST, SOURCE_TYPE_FRIEND, 0, self.m_RefreshUICallback)
end

function FriendApplicantsView:UnSubscribeEvts()
	rktEventEngine.UnSubscribeVote(EVENT_FRIEND_UPDATE_APPLICANTLIST , SOURCE_TYPE_FRIEND, 0, self.m_RefreshUICallback)
end

function FriendApplicantsView:InitUI()
	-- init scrollView
	local controls = self.Controls
	local scrollView  = controls.m_ScrollCellView
	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(handler(self, self.OnGetCellView))
	listView.onCellViewVisiable:AddListener(handler(self, self.OnCellRefreshVisible))
	controls.listView = listView
	
	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller
	
	-- ToggleGroup for Applicant cell
	controls.listTglGroup  = scrollView:GetComponent(typeof(ToggleGroup))
	
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_RefuseAllBtn.onClick:AddListener(handler(self, self.OnBtnRefuseAllClicked))
end

-- EnhancedListView 一行被“创建”时的回调
function FriendApplicantsView:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnCellRefreshVisible)
	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function FriendApplicantsView:OnCellRefreshVisible( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- 创建条目
function FriendApplicantsView:CreateCellItems( listcell )
	local cell = FriendApplicantCell:new({})
	cell:Attach(listcell.gameObject)
	cell:SetToggleGroup(self.Controls.listTglGroup)
	cell:SetSelectCallback(handler(self, self.OnItemCellSelected))
	
	local idx = listcell.dataIndex + 1
	self.m_ApplicantCells[idx] = cell
end

--- 刷新列表
function FriendApplicantsView:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local cell = behav.LuaObject

	local idx = listcell.dataIndex + 1
	if self.m_FriendClient then
		local m_ApplicantList = self.m_FriendClient:GetBeAddFriendList()
		cell:SetCellData(idx, m_ApplicantList[idx])
		if self.m_SelCellIdx == 0 then
			self.m_SelCellIdx = 1
		end
		cell:SetToggleIsOn(idx == self.m_SelCellIdx)
		if idx == #m_ApplicantList then 
			self.m_FriendClient:UpdateFriendChatState() 
		end
	end
end
------------------------------------------公共重载方法结束------------------------------------------

------------------------------------------ 刷新界面显示 ------------------------------------------
function FriendApplicantsView:RefreshUI()
	local m_ApplicantList = self.m_FriendClient:GetBeAddFriendList()
	
	self.Controls.listTglGroup:SetAllTogglesOff()
	self.m_FriendClient.m_BeAddFlag = false
	
	local listView = self.Controls.listView
	local bdCnt = #m_ApplicantList
	
	listView:SetCellCount( bdCnt , false )
	self.Controls.listScroller:ReloadData()
	
	self:SelectCell(self.m_SelCellIdx)
	
	local trans = self.transform:Find("ScrollListBG/ScrollCellList/Container")
	if not trans then return end
	trans.localPosition = Vector3.New(-5, 299, 0)
end

-- 选中对应的Cell
function FriendApplicantsView:SelectCell(idx)
	local cell = self.m_ApplicantCells[idx]
	if cell then
		cell:SetToggleIsOn(true)
	end
end

function FriendApplicantsView:OnItemCellSelected(idx)
	local m_ApplicantList = self.m_FriendClient:GetBeAddFriendList()
	local data = m_ApplicantList[idx]
	
	if data == nil then
		self.m_SelCellIdx = 1
		return
	end
	
	self.m_SelCellIdx = idx
end
------------------------------------------ 刷新界面结束 ------------------------------------------

------------------------------------------ 界面原件响应 ------------------------------------------
function FriendApplicantsView:OnBtnCloseClicked()
	self:Hide()
end

function FriendApplicantsView:OnBtnRefuseAllClicked()
	self.m_FriendClient:ClearBeAddFriendList()
end

return FriendApplicantsView