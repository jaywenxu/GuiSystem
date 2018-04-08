-- 帮派加入子界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-08 14:29:15
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-08 15:45:16

local ClanJoinWdt = UIControl:new {
	windowName = "ClanJoinWdt",

	m_ListEndIdx = 0,

	m_ClanList = {},
	m_TotalNum = 0,

	m_SelClanIdx = 0,
	
	m_bPreFilter = false,   --上一次是否为过滤状态

	m_JoinClanCallBack = nil,
}


local ClanJoinCellClass = require( ClanSysDef.ClanNonePath .. "ClanJoinCell" )

local this = ClanJoinWdt
local ListRefreshCnt = ClanSysDef.ClanListRefreCnt

function ClanJoinWdt:Attach(obj)
	UIControl.Attach(self,obj)

	self:InitUI()

	self:SetSelClanInfo("", "", 0)

	self:SubscribeEvts()

	self.m_SelClanIdx = 0
end 


function ClanJoinWdt:OnDestroy()
	self:UnSubscribeEvts()

	table_release(self)
end

function ClanJoinWdt:Show(bHideJoinBtns)
	UIControl.Show(self)
	
	self.m_ListEndIdx = ListRefreshCnt

	IGame.ClanClient:GetClanList(ClanSysDef.FormalState, 1, self.m_ListEndIdx)

	self.Controls.searchInputField.text = ""

	self:HideJoinOpBtns(bHideJoinBtns == true)

end

function ClanJoinWdt:InitUI()
	local controls = self.Controls
    local scrollView = controls.m_ClanListScr

	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	controls.listView = listView

    controls.listView:SetCellCount( 0 , true )

	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	listScroller.scrollerScrolled = function(scroller, vector, pos) -- 列表滚动事件，每帧调用
		if vector.y < 0 then -- normalize坐标值（1是顶部，0代表底部）
			self:RequestList()
		end
	end

	controls.listScroller = listScroller

	local listTglGroup = scrollView.transform:Find("Viewport"):GetComponent(typeof(ToggleGroup))
	controls.listTglGroup = listTglGroup

 	local searchClan = controls.m_SearchClan
 	local searchInputField = searchClan:Find("SearchInputField"):GetComponent(typeof(InputField))
 	controls.searchInputField = searchInputField

 	controls.m_SearchBtn.onClick:AddListener(handler(self, self.OnBtnSearchClicked))
 	controls.m_ChatWithHostBtn.onClick:AddListener(handler(self, self.OnBtnChatClicked))
 	controls.m_JoinBtn.onClick:AddListener(handler(self, self.OnBtnJoinClicked))
 	controls.m_JoinAllBtn.onClick:AddListener(handler(self, self.OnBtnJoinAllClicked))
end


function ClanJoinWdt:HideJoinOpBtns(bHide)
	local controls = self.Controls

	controls.m_JoinBtn.gameObject:SetActive(not bHide)
 	controls.m_JoinAllBtn.gameObject:SetActive(not bHide)
end


function ClanJoinWdt:SubscribeEvts()
	self.m_JoinClanCallBack = function (_, _, _, evtData) self:OnJoinClanEvt(evtData) end
	rktEventEngine.SubscribeExecute( EVENT_CLAN_APPLYJOIN , SOURCE_TYPE_CLAN, 0, self.m_JoinClanCallBack )
end

function ClanJoinWdt:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_APPLYJOIN , SOURCE_TYPE_CLAN, 0, self.m_JoinClanCallBack )
	self.m_JoinClanCallBack = nil
end

-- EnhancedListView 一行被“创建”时的回调
function ClanJoinWdt:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function ClanJoinWdt:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function ClanJoinWdt:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end


-- 创建条目
function ClanJoinWdt:CreateCellItems( listcell )
	local item = ClanJoinCellClass:new({})
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.Controls.listTglGroup)
	item:SetSelectCallback(slot(self.OnItemCellSelected, self))
	
	local idx = listcell.dataIndex + 1
	listcell.gameObject.name = string.format("ClanJoinCell-%d",idx)
	
	self:RefreshCellItems(listcell)
end


--- 刷新列表
function ClanJoinWdt:RefreshCellItems( listcell )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject
    local idx = listcell.dataIndex + 1
	local bFocus = idx == self.m_SelClanIdx
	
	item:SetCellData(idx, self.m_ClanList[idx], bFocus)
end

-- 帮会选中事件
function ClanJoinWdt:OnItemCellSelected(idx)
	if idx == self.m_SelClanIdx or idx < 1 then
		return
	end
	
	local data = self.m_ClanList[idx]
	if not data then
		return 
	end

	self:SetSelClanInfo(data.szManifesto, data.szShaikhName, data.nShaikhFaceID)

	local bVisible = data.dwShikhPDBID ~= GetHeroPDBID()
	self.Controls.m_ChatWithHostBtn.gameObject:SetActive(bVisible)

	self.m_SelClanIdx = idx
end

-- 设置选中的帮主信息
function ClanJoinWdt:SetSelClanInfo(declare, hostName, faceID)
	local controls = self.Controls
	
	local szDeclare = declare or ""
	controls.m_DeclareTxt.text = StringFilter.Filter(szDeclare, "*")
	
	local szHostName = hostName or ""
	controls.m_HostNameTxt.text = StringFilter.Filter(szHostName, "*")

	if faceID > 0 then
		controls.m_ChatWithHost.gameObject:SetActive(true)
		controls.m_Unorganized.gameObject:SetActive(false)
		UIFunction.SetHeadImage(controls.m_HostHeadBgImg, faceID)
	else
		controls.m_ChatWithHost.gameObject:SetActive(false)
		controls.m_Unorganized.gameObject:SetActive(true)
	end
end


-- 搜索按钮回调
function ClanJoinWdt:OnBtnSearchClicked()
	local txt = self.Controls.searchInputField.text
	IGame.ClanClient:FilterList(ClanSysDef.FormalState , txt)
end


-- 聊天按钮回调
function ClanJoinWdt:OnBtnChatClicked()
	if self.m_SelClanIdx < 1 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "没有选择帮会!")
	else
		local data = self.m_ClanList[self.m_SelClanIdx]
		UIManager.FriendEmailWindow:OnPrivateChat(data.dwShikhPDBID)	
	end
end

-- 加入按钮回调
function ClanJoinWdt:OnBtnJoinClicked()
	if self.m_SelClanIdx < 1 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "没有选择帮会!")
		return 
	end

	local data = self.m_ClanList[self.m_SelClanIdx]
    if not data then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "没有选择帮会!")
        return
    end
    
	local clanID = data.dwID
	if clanID == nil or clanID < 1 then
		print("error! the clanID cannot equal nil")
		return 
	end

	local limitLv = data.nLevelLimit
	local limitJob = data.dwVocationLimit
	local hero = IGame.EntityClient:GetHero()
	local selfLvl = hero:GetNumProp(CREATURE_PROP_LEVEL)
	local selfJob = hero:GetNumProp(CREATURE_PROP_VOCATION)

	if data.nIsApply then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你已申请过此帮会")
	else
		IGame.ClanClient:JoinRequest(clanID)
	end
	
end

-- 请求刷新列表
function ClanJoinWdt:RequestList()
	local remainCnt = self.m_TotalNum - self.m_ListEndIdx
	if remainCnt > 0 then
		local start = self.m_ListEndIdx
		self.m_ListEndIdx = self.m_ListEndIdx + ListRefreshCnt

		IGame.ClanClient:GetClanList(ClanSysDef.FormalState, start, self.m_ListEndIdx)
	end
end


-- 一键加入按钮回调
function ClanJoinWdt:OnBtnJoinAllClicked()

	local data = 
	{
		content = "系统将自动帮你选择合适的帮会加入，是否确认？",
		confirmCallBack = function() IGame.ClanClient:FastJoinRequest() end
	}	
	UIManager.ConfirmPopWindow:ShowDiglog(data)

end


-- 加入帮派事件
function ClanJoinWdt:OnJoinClanEvt(evtData)
	print("<color=green> --------- OnJoinClanEvt 帮派加入事件</color>")

	if self.m_SelClanIdx < 1 then
		return
	end

	self.m_ClanList[self.m_SelClanIdx].nIsApply = true

	self.Controls.listScroller:Resize(true)	
	self.Controls.listScroller:RefreshActiveCellViews()
end

function ClanJoinWdt:SetFocusIdx(bFilter)
	
	local nFocusIdx = 0
	if self.m_SelClanIdx == 0 then
		nFocusIdx = 1
	else
		nFocusIdx = self.m_SelClanIdx
	end
	
	if bFilter then
		nFocusIdx = 1
	else
		if self.m_bPreFilter then
			nFocusIdx = 1
		else
			nFocusIdx = nFocusIdx
		end
	end
	
	self:OnItemCellSelected(nFocusIdx)
	
	self.m_bPreFilter = bFilter
end

-- 列表数据事件
function ClanJoinWdt:OnClanListEvt(evtData)

	self.m_TotalNum = evtData.nTotalNum
	
	local bFilter   = evtData.bFilter
	local ClanListMgr = IGame.ClanClient:GetClanListManager()
	if bFilter then
		self.m_ClanList = ClanListMgr:GetFilterList(ClanSysDef.FormalState)
	else
		self.m_ClanList = ClanListMgr:GetList(ClanSysDef.FormalState)
	end
	self:SetFocusIdx(bFilter)	

    self.Controls.listView:SetCellCount( #self.m_ClanList, false)

	self.Controls.listScroller:Resize(true)	
	self.Controls.listScroller:RefreshActiveCellViews()
end

return ClanJoinWdt
