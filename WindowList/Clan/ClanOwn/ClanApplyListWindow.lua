-- 帮派申请列表窗口
-- @Author: XieXiaoMei
-- @Date:   2017-04-13 14:59:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-25 17:36:06

local ClanApplyListWindow = UIWindow:new
{
	windowName  = "ClanApplyListWindow",
	
	m_ApplyList = {},
	m_SelMemberID = 0,

	m_SelSortMode = "",
	m_SelSortType = 0


}

local ApplyListCell = require( ClanSysDef.ClanOwnPath .. "ApplyListCell" )

local this = ClanApplyListWindow

local sortTypes = ClanSysDef.MemberSortTypes
local TitleTglNameSortMap = {
	["Title"]       = sortTypes.Title, 
	["Name"]        = sortTypes.Name,	 		
	["Level"]       = sortTypes.Level, 
	["Job"]         = sortTypes.Job,
	-- ["OnlineState"] = sortTypes.Online
}


------------------------------------------------------------
function ClanApplyListWindow:Init()
	Debugger.Log("ClanApplyListWindow:Init()")
end

function ClanApplyListWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self:InitUI()

	self:InitTitleTgls()
	
	self:SubscribeEvts()

	self:RefreshUI()
end

function ClanApplyListWindow:InitUI()
	local controls = self.Controls
	local scrollView = controls.m_ApplyListScr

	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	controls.listView = listView

	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller

	local listTglGroup = scrollView.transform:Find("Viewport"):GetComponent(typeof(ToggleGroup))
	controls.listTglGroup = listTglGroup

	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_RefreshBtn.onClick:AddListener(handler(self, self.OnBtnRefreshClicked))
	controls.m_AllCleanBtn.onClick:AddListener(handler(self, self.OnBtnAllCleanClicked))
	controls.m_RejectBtn.onClick:AddListener(handler(self, self.OnBtnRejectClicked))
	controls.m_AgreeBtn.onClick:AddListener(handler(self, self.OnBtnAgreeClicked))
end


-- 初始化列表标题toggles
function ClanApplyListWindow:InitTitleTgls()
	local controls = self.Controls
	local titleTransf = controls.m_TitleTgls
	
	local tgls = {}
	for name, sortType in pairs(TitleTglNameSortMap) do
		local tgl = titleTransf:Find(name):GetComponent(typeof(Toggle))
		tgl.onValueChanged:AddListener(function (on)
			self:OnTitleTglChanged(sortType, on)
		end)
		tgls[sortType] = tgl
	end

	controls.titleTgls = tgls
end


-- 重置title toggles的状态
function ClanApplyListWindow:ResetTitleTgls()

	local tgls = self.Controls.titleTgls
	for k, tgl in pairs(tgls) do
		tgl.isOn = false
	end

	self.m_SelSortType = ""
end

-- title toggle 切换回调
function ClanApplyListWindow:OnTitleTglChanged(sortType, on)
	local preSortType = self.m_SelSortType
	if sortType ~= preSortType and not on then -- 非同个toggle点击，并且是被切换状态，不理睬
		return
	end

	local sortMode  = ClanSysDef.DescSortMode -- 默认升序
	if sortType == preSortType then
		sortMode = self.m_SelSortMode == ClanSysDef.AsceSortMode and ClanSysDef.DescSortMode or ClanSysDef.AsceSortMode
	end

	local tgl = self.Controls.titleTgls[sortType]
	local arrow = tgl.transform:Find("Arrow") 
	local angle = sortMode == ClanSysDef.DescSortMode and 0 or 180 --设置title toggle 箭头升降序图片
	arrow.transform.localRotation = Vector3.New(0, 0, angle)

	self.m_SelSortMode = sortMode
	self.m_SelSortType = sortType

	-- self.m_Clan:SortMember(sortType, sortMode) -- 排序

	-- self:RefreshMembers() --刷新界面数据
end



function ClanApplyListWindow:OnDestroy()
	self:UnSubscribeEvts()

	UIWindow.OnDestroy(self)

	table_release(self)
end

function ClanApplyListWindow:Show( bringTop)
	UIWindow.Show(self, bringTop)

	if not self:isLoaded() then
		return 
	end

	self.Controls.listTglGroup:SetAllTogglesOff()
	self.m_SelMemberID = 0

	self:ResetTitleTgls()

	self:RefreshUI()
end

-- 监听事件
function ClanApplyListWindow:SubscribeEvts()
	self.m_ApplyListUpCallBack = handler(self, self.RefreshUI)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_APPLYJOIN, SOURCE_TYPE_CLAN, 0, self.m_ApplyListUpCallBack )
	rktEventEngine.SubscribeExecute( EVENT_CLAN_REMOVEAPPLY, SOURCE_TYPE_CLAN, 0, self.m_ApplyListUpCallBack )
end 

-- 去除事件监听
function ClanApplyListWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_APPLYJOIN , SOURCE_TYPE_CLAN, 0, self.m_ApplyListUpCallBack )
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_REMOVEAPPLY , SOURCE_TYPE_CLAN, 0, self.m_ApplyListUpCallBack )
	self.m_ApplyListUpCallBack = nil
end

-- 刷新界面
function ClanApplyListWindow:RefreshUI()

	self.m_SelMemberID = 0

	local controls = self.Controls

	self.m_ApplyList = IGame.ClanClient:GetClan():GetApplyList() or {}
	controls.listView:SetCellCount( #self.m_ApplyList , true )
	local bHasPopedom = IGame.ClanClient:HasPopedom(emClanPopedom_AcceptMember) --是否有接收成员权限
	controls.m_AllCleanBtn.gameObject:SetActive(bHasPopedom)
	controls.m_RejectBtn.gameObject:SetActive(bHasPopedom)
	controls.m_AgreeBtn.gameObject:SetActive(bHasPopedom)
end

-- EnhancedListView 一行被“创建”时的回调
function ClanApplyListWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)

	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function ClanApplyListWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function ClanApplyListWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

--- 刷新列表
function ClanApplyListWindow:CreateCellItems( listcell )	
	local item = ApplyListCell:new({})
	
	local idx = listcell.dataIndex + 1
	listcell.gameObject.name = string.format("ApplyListCell-%d",idx)
	
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.Controls.listTglGroup)
	item:SetSelectCallback(self.OnItemCellSelected)
end

--- 刷新列表
function ClanApplyListWindow:RefreshCellItems( listcell, on )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		uerror("ChatMessageWidget:RefreshCellItems item为空")
		return
	end

	local idx = listcell.dataIndex + 1
	item:SetCellData(self.m_ApplyList[idx], idx)
end

-- cell被选中事件
function ClanApplyListWindow.OnItemCellSelected(memberID)
	this.m_SelMemberID = memberID
end

-- 退出按钮按下事件
function ClanApplyListWindow:OnBtnCloseClicked()
	self:Hide()
end

-- 刷新按钮按下事件
function ClanApplyListWindow:OnBtnRefreshClicked()
	self:RefreshUI()
end

-- 清空按钮按下事件
function ClanApplyListWindow:OnBtnAllCleanClicked()
	IGame.ClanClient:RefuseAllApply()
end

-- 拒绝按钮按下事件
function ClanApplyListWindow:OnBtnRejectClicked()
	self:AgreeOrRejectReq(false)
end

-- 同意按钮按下事件
function ClanApplyListWindow:OnBtnAgreeClicked()
	self:AgreeOrRejectReq(true)
end


-- 发送同意或拒绝请求
function ClanApplyListWindow:AgreeOrRejectReq(bAgree)
	if self.m_SelMemberID < 1 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先选择处理对象")
		return 
	end

	IGame.ClanClient:AcceptRequest(self.m_SelMemberID, bAgree)
end

-- 成员加入成功事件
function ClanApplyListWindow:OnMemberJoinEvt()
	print("OnMemberJoinEvt 成员加入成功事件")
	self.m_SelMemberID = 0

	self:RefreshUI()
end

return ClanApplyListWindow