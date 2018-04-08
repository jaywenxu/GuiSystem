-- 帮派响应子界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-08 14:34:15
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-08 15:01:47

local ClanResponseWdt = UIControl:new {
	windowName  = "ClanResponseWdt",
	
	m_ListEndIdx  = 0,

	m_ClanList  = {},
	m_TotalNum  = 0,
	
	m_bPreFilter = false,  --上一次是否为过滤状态
	
	m_SelClanIdx = 0,

	m_OnRespCallBack = nil,

	m_LastRespTime = 0,
}

local ClanRespCellClass = require( ClanSysDef.ClanNonePath .. "ClanResponseCell" )

local this = ClanResponseWdt

local ListRefreshCnt = ClanSysDef.ClanListRefreCnt

function ClanResponseWdt:Attach(obj)
	UIControl.Attach(self,obj)

	self:InitUI()

	self:SetSelClanInfo("", "", 0)
	
	self:SubControlExecute()
end


function ClanResponseWdt:OnDestroy()
	UIControl.OnDestroy(self)
    self:UnSubControlExecute()
	table_release(self)
end


function ClanResponseWdt:Show()
	UIControl.Show(self)

	self.m_ListEndIdx = ListRefreshCnt
	IGame.ClanClient:GetClanList(ClanSysDef.InformalState, 1, self.m_ListEndIdx)

	self.Controls.searchInputField.text = ""
end

function ClanResponseWdt:InitUI()
	local controls = self.Controls
    local scrollView = controls.m_ClanListScr

	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	controls.listView = listView

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
 	controls.m_RespOpBtn.onClick:AddListener(handler(self, self.OnBtnResponseClicked))
 	controls.m_ChatWithHostBtn.onClick:AddListener(handler(self, self.OnBtnChatClicked))
end


-- 请求刷新列表
function ClanResponseWdt:RequestList()
	local remainCnt = self.m_TotalNum - self.m_ListEndIdx
	if remainCnt > 0 then
		local start = self.m_ListEndIdx
		self.m_ListEndIdx = self.m_ListEndIdx + ListRefreshCnt
		IGame.ClanClient:GetClanList(ClanSysDef.InformalState, start, self.m_ListEndIdx)
	end
end


function ClanResponseWdt:SubControlExecute()
	
	-- 帮会响应事件
	self.m_OnRespCallBack = handler(self, self.OnClanResponseEvt)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_RESPOND, SOURCE_TYPE_CLAN, 0, self.m_OnRespCallBack )
end

function ClanResponseWdt:UnSubControlExecute()
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_RESPOND , SOURCE_TYPE_CLAN, 0, self.m_OnRespCallBack )
	self.m_OnRespCallBack = nil
end


-- EnhancedListView 一行被“创建”时的回调
function ClanResponseWdt:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function ClanResponseWdt:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function ClanResponseWdt:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end


-- 创建条目
function ClanResponseWdt:CreateCellItems( listcell )
	local item = ClanRespCellClass:new({})
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.Controls.listTglGroup)
	item:SetSelectCallback(slot(self.OnItemCellSelected, self))
	item:SetRespTimeOutCallback(slot(self.OnClanRespTimeOut, self))
	self:RefreshCellItems(listcell)
end


--- 刷新列表
function ClanResponseWdt:RefreshCellItems( listcell )	
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
function ClanResponseWdt:OnItemCellSelected(cellIdx)
	if cellIdx == self.m_SelClanIdx or cellIdx < 1 then
		return
	end

	local data = self.m_ClanList[cellIdx]
	if not data then return end

	self:SetSelClanInfo(data.szManifesto, data.szShaikhName, data.nShaikhFaceID)

	self:RefreshBtnState(data.nIsApply)

	local bVisible = data.dwShikhPDBID ~= GetHeroPDBID()
	self.Controls.m_ChatWithHostBtn.gameObject:SetActive(bVisible)

	self.m_SelClanIdx = cellIdx
end

-- 设置选中的帮主信息
function ClanResponseWdt:SetSelClanInfo(declare, hostName, faceID)
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


-- 刷新按钮状态
function ClanResponseWdt:RefreshBtnState(bIsApply)
	local controls = self.Controls
	controls.m_ResponseImg.gameObject:SetActive(not bIsApply)
	controls.m_UnresponseImg.gameObject:SetActive(bIsApply)
end


-- 搜索按钮回调
function ClanResponseWdt:OnBtnSearchClicked()
	local txt = self.Controls.searchInputField.text
	IGame.ClanClient:FilterList(ClanSysDef.InformalState , txt)
end

-- 与帮主聊天按钮回调
function ClanResponseWdt:OnBtnChatClicked()
	if self.m_SelClanIdx < 1 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先选择帮会!")
	else
		local data = self.m_ClanList[self.m_SelClanIdx]
		UIManager.FriendEmailWindow:OnPrivateChat(data.dwShikhPDBID)
	end
end

-- 响应按钮回调
function ClanResponseWdt:OnBtnResponseClicked()
	if os.time() - self.m_LastRespTime < 5 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你点击太频繁了!")
		return 
	end

	if self.m_SelClanIdx < 1 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先选择帮会!")
		return
	end

	local name = IGame.EntityClient:GetHero():GetName()
	local data = self.m_ClanList[self.m_SelClanIdx]
	
	if self.m_ClanList[self.m_SelClanIdx].szShaikhName == name then
		if not data.nIsApply then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你无法响应自己的帮会")
		else
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你无法退出响应自己的帮会")
		end
		return
	end

	local data = self.m_ClanList[self.m_SelClanIdx]
	if not data.nIsApply then
		IGame.ClanClient:RespondRequest(data.dwID) -- 响应
		
	else
		IGame.ClanClient:QuitRequest() -- 取消响应
		data.nIsApply = false
	end

	self.m_LastRespTime = os.time()
end

-- 响应事件
function ClanResponseWdt:OnClanResponseEvt(_, _, _, evtData)
	print("<color=green> --------- OnCreateClanEvt 帮会响应！！！</color>")

	local clanID  = evtData.dwClanID
	local bFormal = evtData.bFormal -- 成为正式帮会
	local bQuit   = evtData.bQuit -- 是否是退出响应
	print("clanID:", clanID)
	
	local data = self.m_ClanList[self.m_SelClanIdx]
	if data.dwID ~= clanID then
		return 
	end
	print("evtData.bQuit = "..tostring(evtData.bQuit))

	-- 本地做刷新帮派数据操作 
	if not bQuit then -- 响应帮会
		data.nMemberCount = data.nMemberCount + 1
		data.nIsApply = true
	else --退出响应
		data.nMemberCount = data.nMemberCount - 1
		data.nIsApply = false
	end
	print("data.nIsApply = "..tostring(data.nIsApply))
	self.Controls.listScroller:ReloadData()
	
	self:RefreshBtnState(data.nIsApply)
end

function ClanResponseWdt:OnClanRespTimeOut(clanIdx)
	table.remove(self.m_ClanList, clanIdx)

	self:RefreshList()
end

function ClanResponseWdt:GetDefaultFocus()
	for k, tClan in pairs(self.m_ClanList) do
		if tClan.nIsApply then
			return k
		end
	end
end

function ClanResponseWdt:SetFocusIdx(bFilter)
	local nFocusIdx = 0
	if self.m_SelClanIdx == 0 then
		nFocusIdx = self:GetDefaultFocus() or 1
	else
		nFocusIdx = self.m_SelClanIdx
	end
	
	if bFilter then
		nFocusIdx = self:GetDefaultFocus() or 1
	else
		if self.m_bPreFilter then
			nFocusIdx = self:GetDefaultFocus() or 1
		else
			nFocusIdx = nFocusIdx
		end
	end
	
	self:OnItemCellSelected(nFocusIdx)
	
	self.m_bPreFilter = bFilter
end

-- 帮会列表事件
function ClanResponseWdt:OnClanListEvt(evtData)
	
	self.m_TotalNum = evtData.nTotalNum
	local bFilter = evtData.bFilter
	local ClanListMgr = IGame.ClanClient:GetClanListManager()
	if bFilter then
		self.m_ClanList = ClanListMgr:GetFilterList(ClanSysDef.InformalState)
	else
		self.m_ClanList = ClanListMgr:GetList(ClanSysDef.InformalState)
	end
	
	self:SetFocusIdx(bFilter)
		
    self:RefreshList()
end


function ClanResponseWdt:RefreshList()
	local controls = self.Controls

	controls.listView:SetCellCount( #self.m_ClanList , false )
	controls.listScroller:Resize(true)	
	controls.listScroller:RefreshActiveCellViews()
end

function ClanResponseWdt:Hide( destroy )
	
	-- 界面关闭时候，清理所有响应帮会(清理倒计时定时器)，因重新打开界面时候会重新请求数据填充
	self.Controls.listView:SetCellCount(0 , true ) 

	UIControl.Hide(self, destroy)
end


return ClanResponseWdt
