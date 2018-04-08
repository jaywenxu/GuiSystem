-- 帮派成员界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 16:09:08
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-08 16:11:28

local ClanMembersWdt = UIControl:new {
	windowName = "ClanMembersWdt",

	m_Clan = nil,

	m_SelMemberIdx = 0,
	m_MemberInfoWdt = nil,

	m_SelSortMode = "",
	m_SelSortType = "",

	m_MemberList = {},

	m_EventHandler = {},

	m_ClanManagerWdt = nil,
	
	m_IsAppeared = false
}

local LuaWidgetPath = "GuiSystem.WindowList.Clan.ClanOwn."
local ClanMemberCell = require(LuaWidgetPath .. "ClanMemberCell" )

local this = ClanMembersWdt

local sortTypes = ClanSysDef.MemberSortTypes
local TitleTglNameSortMap = {
	["Title"]       = sortTypes.Title, 
	["Name"]        = sortTypes.Name,	 		
	["Level"]       = sortTypes.Level, 
	["Job"]         = sortTypes.Job,
	["Position"]    = sortTypes.Position, 
	["WeekContrib"] = sortTypes.Contribute, 
	["PassGong"]    = -1, 	
	["OnlineState"] = sortTypes.Online
}

--------------------------------------------------------------------------------
function ClanMembersWdt:Attach(obj)
	UIControl.Attach(self,obj)

	self:InitUI()

	self:InitTitleTgls()
		
	self:RefreshRedDot()
end

function ClanMembersWdt:OnDestroy()
    
	UIControl.OnDestroy(self)	
	self.m_IsAppeared = false
	
	table_release(self) 
end


function ClanMembersWdt:Show()
	UIControl.Show(self)

	if self.m_ClanManagerWdt then
		self.m_ClanManagerWdt:Hide()
	end

	self:ResetTitleTgls()

	self:RefreshUI()
end

-- 刷新界面
function ClanMembersWdt:RefreshUI()
	if self.m_MemberInfoWdt then
		self.m_MemberInfoWdt:Hide()
	end

	self.m_SelTitleTgl = nil
	if not self.Controls.listTglGroup then
		return
	end
	
	self:RefreshMainPopedoms()

	self.Controls.listTglGroup:SetAllTogglesOff()

	self:RefreshMembers()

	self:SetMembersCnt()
end

function ClanMembersWdt:RefreshPopedoms()
	local controls = self.Controls

	local isHasPopedom = handler(IGame.ClanClient, IGame.ClanClient.HasPopedom)

	local bEnabled = isHasPopedom(emClanPopedom_ModifyManifesto)
	controls.m_DeclareMdfBtn.gameObject:SetActive(bEnabled)

	bEnabled = isHasPopedom(emClanPopedom_ModifyNotice)
	controls.m_ClanNameMdfBtn.gameObject:SetActive(bEnabled)
end



-- 重新装载数据
function ClanMembersWdt:RefreshMembers()
	self.m_Clan = IGame.ClanClient:GetClan()
	self.m_MemberList = self.m_Clan:GetMemberList() or {}

	local controls = self.Controls
	if controls.listView then
		controls.listView:SetCellCount( #self.m_MemberList , true )
	end
end

-- 设置成员数量
function ClanMembersWdt:SetMembersCnt()
	local controls = self.Controls

	local maxMemberCnt = ClanSysDef.GetMaxMemberCnt(tonumber(IGame.ClanClient:GetClanData(emClanProp_Level)))

	local str = string.format("帮会成员：%s/%s", #self.m_MemberList, maxMemberCnt)
	controls.m_MembersTxt.text = str
end

-- 初始化UI
function ClanMembersWdt:InitUI()
	local controls = self.Controls
    local scrollView = controls.m_MembersScr

	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	controls.listView = listView

	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	listScroller.scrollerScrollingChanged = function () -- 监听滚动事件，当scroller滚动时，关掉成员信息面板
		if self.m_MemberInfoWdt and self.m_MemberInfoWdt:isShow() then 
    		self.m_MemberInfoWdt:Hide()
    	end
	end

	controls.listScroller = listScroller

	local listTglGroup = scrollView.transform:Find("Viewport"):GetComponent(typeof(ToggleGroup))
	controls.listTglGroup = listTglGroup

 	controls.m_ExitClanBtn.onClick:AddListener(handler(self, self.OnBtnExitClanClicked))
 	controls.m_ManageClantBtn.onClick:AddListener(handler(self, self.OnBtnManageClanClicked))
 	controls.m_WelcomeNewBtn.onClick:AddListener(handler(self, self.OnBtnWelcomeNewClicked))
 	controls.m_ClanListBtn.onClick:AddListener(handler(self, self.OnBtnClanListClicked))
	controls.m_RedPacketBtn.onClick:AddListener(handler(self, self.OnBtnRedPacketClicked)) -- 红包按钮
	
	self:RefreshMainPopedoms()
	
	if not self.m_IsAppeared then
		UIManager.ClanOwnWindow:Appear()
		self.m_IsAppeared = true
	end
end

function ClanMembersWdt:RefreshMainPopedoms()
	local isHasPopedom = handler(IGame.ClanClient, IGame.ClanClient.HasPopedom)
	local bHasPepedom = isHasPopedom(emClanPopedom_AcceptMember)
	if self.Controls.m_ManageClantBtn and nil ~= bHasPepedom then
		self.Controls.m_ManageClantBtn.gameObject:SetActive(bHasPepedom)
	end
end

-- 初始化列表标题toggles
function ClanMembersWdt:InitTitleTgls()
	local controls = self.Controls
	local titleTransf = controls.m_TitleTlgs
	
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

-- 注册控件事件
function ClanMembersWdt:SubControlExecute()
        
	-- 请求帮派列表
	self.m_MemberListUpCallBack = handler(self, self.OnMemberListUpEvt)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_MEMBERLISTUPDATE, SOURCE_TYPE_CLAN, 0, self.m_MemberListUpCallBack )

	-- 成员删除、退帮事件
	self.m_MemberDelCallBack = handler(self, self.OnMembersDelEvt)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_DELMEMBER, SOURCE_TYPE_CLAN, 0, self.m_MemberDelCallBack )

	-- 成员加入事件
	self.m_MemberJoinCallBack = handler(self, self.RefreshMembers)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_ADDMEMBER, SOURCE_TYPE_CLAN, 0, self.m_MemberJoinCallBack )

	-- 成员更新事件
	self.m_MemberUpCallBack = handler(self, self.OnUpdateMemberEvt)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_UPDATEMEMBER, SOURCE_TYPE_CLAN, 0, self.m_MemberUpCallBack )

	-- 自己退帮事件
	self.m_ExitClanCallBack = handler(self, self.OnExitClanEvt)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_QUIT, SOURCE_TYPE_CLAN, 0, self.m_ExitClanCallBack )

	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_CLAN_MEMBERSWDT, self.RefreshRedDot, self)

	--self:RefreshRedDot()
end 

-- 注销控件事件
function ClanMembersWdt:UnSubControlExecute()
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_MEMBERLISTUPDATE , SOURCE_TYPE_CLAN, 0, self.m_MemberListUpCallBack )
	self.m_MemberListUpCallBack = nil	

	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_DELMEMBER , SOURCE_TYPE_CLAN, 0, self.m_MemberDelCallBack )
	self.m_MemberDelCallBack = nil

	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_ADDMEMBER , SOURCE_TYPE_CLAN, 0, self.m_MemberJoinCallBack )
	self.m_MemberJoinCallBack = nil

	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_UPDATEMEMBER , SOURCE_TYPE_CLAN, 0, self.m_MemberUpCallBack )
	self.m_MemberUpCallBack = nil

	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_QUIT , SOURCE_TYPE_CLAN, 0, self.m_ExitClanCallBack )
	self.m_ExitClanCallBack = nil

	rktEventEngine.UnSubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_CLAN_MEMBERSWDT, self.RefreshRedDot, self)
end


-- 刷新红点显示
function ClanMembersWdt:RefreshRedDot(_, _, _, evtData)
	local redDotObjs = 
	{
		["红包"] = self.Controls.m_RedPacketBtn,
		["帮会管理"] = self.Controls.m_ManageClantBtn,
	}

	SysRedDotsMgr.RefreshRedDot(redDotObjs, "ClanMembersWdt", evtData)
end


--------------------------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function ClanMembersWdt:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function ClanMembersWdt:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function ClanMembersWdt:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end


-- 创建条目
function ClanMembersWdt:CreateCellItems( listcell )
	local item = ClanMemberCell:new({})
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.Controls.listTglGroup)
	item:SetSelectCallback(slot(self.OnItemCellSelected, self))
	item:SetPassGongCallback(slot(self.OnPassGongBtnClicked, self))
	
	local idx = listcell.dataIndex + 1
	listcell.gameObject.name = string.format("ClanMemberCell-%d",idx)

	if self.m_SelMemberIdx ~= 0 then
		item:SetToggleOn(self.m_SelMemberIdx == idx)
	end
end


--- 刷新单个cell
function ClanMembersWdt:RefreshCellItems( listcell )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	local item = behav.LuaObject
	
	local idx = listcell.dataIndex + 1
	item:SetCellData(idx, self.m_MemberList[idx])
	--item.gameObject.name = string.format("ClanMemberCell-%d",idx)
end

-- cell被选择回调
function ClanMembersWdt:OnItemCellSelected(idx)
	local member = self.m_MemberList[idx]
	if not member then
		return
	end

	self.m_SelMemberIdx = idx
	
	local hero = IGame.EntityClient:GetHero()
	if member.dwPDBID == hero:GetNumProp(CREATURE_PROP_PDBID) then
		print("不能选中自己")
		if self.m_MemberInfoWdt then
			self.m_MemberInfoWdt:Hide()
		end
		return 
	end

	if isTableEmpty(self.m_MemberInfoWdt) then
		self.m_MemberInfoWdt = require(LuaWidgetPath .. "MemberInfoWdt"):new()
		self.m_MemberInfoWdt:Attach(self.Controls.m_MemberInfoWdt.gameObject)
	end

	self.m_MemberInfoWdt:Hide()

	rktTimer.SetTimer(function () 
			self.m_MemberInfoWdt:Show(true, nil, member)
		end, 300 , 1, "MemberInfoWdt delay show")
end

-- 取消成员选中
function ClanMembersWdt:MemberSelectedOFF()
	self.Controls.listTglGroup:SetAllTogglesOff()
	self.m_SelMemberIdx = 0
end
--------------------------------------------------------------------------------

-- 重置title toggles的状态
function ClanMembersWdt:ResetTitleTgls()
	local tgls = self.Controls.titleTgls
	for k, tgl in pairs(tgls) do
		tgl.isOn = false
	end

	self.m_SelSortType = ""
end

-- title toggle 切换回调
function ClanMembersWdt:OnTitleTglChanged(sortType, on)
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
	local angle = sortMode == ClanSysDef.DescSortMode and 0 or 180
	arrow.transform.localRotation = Vector3.New(0, 0, angle) --设置title toggle 箭头升降序图片

	self.m_SelSortMode = sortMode
	self.m_SelSortType = sortType

	if sortType == -1 then
		print("此排序类型暂未实现")
		return 
	end

	self:MemberSelectedOFF() -- 取消选中

	self.m_Clan:SortMember(sortType, sortMode) -- 排序

	self:RefreshMembers() --刷新界面数据
end


-- 退帮列表按钮回调
function ClanMembersWdt:OnBtnExitClanClicked()
	local content = ""
	local confirmCallBack = nil
	local selfName = IGame.EntityClient:GetHero():GetName()
	local hostName =  self.m_Clan:GetStringProp(emClanShaikhName)
	if selfName == hostName then -- 退帮人是帮主
		if self.m_Clan:GetClanListCount() <= 1 then --仅剩帮主一人，解散帮会
			content = string.format("你退出帮会后，本帮会将自动解散。确定解散帮会吗？")
			confirmCallBack = function ( )
				IGame.ClanClient:DismissRequest()
			end
		else
			local str = "帮主不能脱离帮会！"
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, str)
			return
		end
	else
		local clanName = self.m_Clan:GetStringProp(emClanProp_Name)
		content = string.format("确定脱离<color=green>%s</color>帮会吗？", clanName)
		confirmCallBack = function ( )
			IGame.ClanClient:QuitRequest()
		end
	end
	
	local data = {
		content = content,
		confirmCallBack = confirmCallBack
	}
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end


-- 帮会列表按钮回调
function ClanMembersWdt:OnBtnClanListClicked()
	UIManager.ClanNoneWindow:ShowWindow(true, true)
end

-- 红包按钮
function ClanMembersWdt:OnBtnRedPacketClicked()
	UIManager.RedPacketWindow:OpenPanel(2)
end


-- 帮会管理按钮回调
function ClanMembersWdt:OnBtnManageClanClicked()
	if not self.m_ClanManagerWdt then
		self.m_ClanManagerWdt  = require(LuaWidgetPath .. "ClanManagerWdt"):new()
		self.m_ClanManagerWdt:Attach(self.Controls.m_ManageClanWdt.gameObject)
	end
	
	self.m_ClanManagerWdt:Show()
end

-- 帮会迎新按钮回调
function ClanMembersWdt:OnBtnWelcomeNewClicked()
	UIManager.ClanWelcomeNewWindow:Show(true)
end

-- 传功按钮回调
function ClanMembersWdt:OnPassGongBtnClicked(idx)
	--print(idx .. " ------------ " .. tableToString(self.m_MemberList))
	local member = self.m_MemberList[tonumber(idx)]
	local clanObj = IGame.ClanClient:GetClan()
	if clanObj == nil then
		return
	end
	local impartManager = clanObj:GetImpartManager()
	if impartManager and impartManager:CheckCanImpart(member.dwPDBID) then
		local reqStr = string.format("RequestInviteImpart(%d)", member.dwPDBID)
		GameHelp.PostServerRequest(reqStr)
	end
end

---------------------------------------------------------------------------------------

function ClanMembersWdt:OnMemberListUpEvt()
	self:RefreshUI()
end

function ClanMembersWdt:OnMembersDelEvt()
	self:RefreshUI()
end

function ClanMembersWdt:OnUpdateMemberEvt()
	self:RefreshUI()
end

function ClanMembersWdt:OnExitClanEvt(_, _, _, evtData)
	local memberID = evtData.dwPDBID
	local hero = IGame.EntityClient:GetHero()
	if memberID == hero:GetNumProp(CREATURE_PROP_PDBID) then -- 退帮人是自己
		print("自己退帮")
		UIManager.ClanOwnWindow:Hide(true)
	else
		print("他人退帮")
	end
end

return ClanMembersWdt
