-- 帮派信息界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 16:09:08
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-07 19:55:33

local ClanInfoWdt = UIControl:new {
	windowName = "ClanInfoWdt",

	m_ClanList = {},
	m_TotalNum = 0,

	m_NameMdfWdt = nil,
	m_DeclareMdfWdt = nil,

	m_UpdateInfoCallBack = nil,
}

local GUIModulePath = "GuiSystem.WindowList.Clan.ClanOwn."
local ClanNewsClass = require("GuiSystem.WindowList.Clan.ClanOwn.ClanNewsCell")

local this = ClanInfoWdt

------------------------------------------------------

function ClanInfoWdt:Attach(obj)
	UIControl.Attach(self,obj)

	self:InitUI()

	self:SetClanInfo()

	self:OnUpdateNewsList()
    
    --隐藏templete
    self.Controls.m_ClanNewsCell.gameObject:SetActive(false)
end

function ClanInfoWdt:InitUI()
	local controls = self.Controls
    local scrollView = controls.m_ClanNewsScr

	local listView = scrollView:GetComponent(typeof(EnhanceDynamicSizeListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	controls.listView = listView

	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller

	controls.m_DeclareMdfBtn.onClick:AddListener(handler(self, self.OnBtnDeclareMdfClicked))
 	controls.m_ClanNameMdfBtn.onClick:AddListener(handler(self, self.OnBtnClanNameMdfClicked))

 	controls.m_ClanMapBtn.onClick:AddListener(handler(self, self.OnBtnClanMapClicked))
 	controls.m_ClanCourseBtn.onClick:AddListener(handler(self, self.OnBtnClanCourseClicked))
    
 	controls.m_DescBtn.onClick:AddListener(handler(self, self.OnDescBtnClick))
    
	self:SubExecute()
end

function ClanInfoWdt:OnDescBtnClick()
	UIManager.CommonGuideWindow:ShowWindow(36)
end

function ClanInfoWdt:SubExecute()
	-- 请求帮派列表
	self.m_UpdateInfoCallBack = handler(self, self.SetClanInfo)
	rktEventEngine.SubscribeExecute( MSG_CLAN_CLANBASEDATA_OC, SOURCE_TYPE_CLAN, 0, self.m_UpdateInfoCallBack )
	
	rktEventEngine.SubscribeExecute( EVENT_CLAN_BASEDATAUPDATE, SOURCE_TYPE_CLAN, 0, self.m_UpdateInfoCallBack )
	
	-- 帮会新闻更新
	self.m_UpdateNewsCallBack = handler(self, self.OnUpdateNewsList)
	rktEventEngine.SubscribeExecute( EVENT_UPDATE_CLANNEWS, SOURCE_TYPE_CLAN, 0, self.m_UpdateNewsCallBack )
end 

function ClanInfoWdt:UnSubExecute()
	rktEventEngine.UnSubscribeExecute( MSG_CLAN_CLANBASEDATA_OC , SOURCE_TYPE_CLAN, 0, self.m_UpdateInfoCallBack )
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_BASEDATAUPDATE , SOURCE_TYPE_CLAN, 0, self.m_UpdateInfoCallBack )
	self.m_UpdateInfoCallBack = nil
	
	rktEventEngine.SubscribeExecute( EVENT_UPDATE_CLANNEWS, SOURCE_TYPE_CLAN, 0, self.m_UpdateNewsCallBack )
	self.m_UpdateNewsCallBack = nil
end

function ClanInfoWdt:OnDestroy()
	UIControl.OnDestroy(self)
	self:UnSubExecute()
	table_release(self) 
end

function ClanInfoWdt:Show()
	UIControl.Show(self)

	local controls = self.Controls

	local isHasPopedom = handler(IGame.ClanClient, IGame.ClanClient.HasPopedom)

	local bHasPepedom = isHasPopedom(emClanPopedom_ModifyManifesto) -- 是否修改宣言权限
	controls.m_DeclareMdfBtn.gameObject:SetActive(bHasPepedom)

	bHasPepedom = isHasPopedom(emClanPopedom_ModifyManifesto) -- 是否修改帮名权限
	controls.m_ClanNameMdfBtn.gameObject:SetActive(bHasPepedom)
	
	self:SetClanInfo()
    
    self:RefreshNews()
end

function ClanInfoWdt:RefreshNews()
    IGame.ClanClient:RequestClanData(emClanRequestNewsList)
end

function ClanInfoWdt:SetClanInfo()
	local clanClient = IGame.ClanClient
	local clan = clanClient:GetClan()
	if not clan then
		return 
	end

	local getClanAttr = function (key)
		return clanClient:GetClanData(key)
	end

	local controls = self.Controls
	
	local szClanName = StringFilter.Filter(getClanAttr(emClanProp_Name), "*")
	controls.m_NameTxt.text         = szClanName
	
	local szHostName = StringFilter.Filter(getClanAttr(emClanShaikhName), "*")
	controls.m_HostTxt.text         = szHostName
	
	controls.m_LevelTxt.text        = getClanAttr(emClanProp_Level).."级"
	
	controls.m_IDTxt.text           = getClanAttr(emClanProp_ID)
	
	local membersCnt = clanClient:GetClan():GetMemberCnt()
	local maxMemberCnt = ClanSysDef.GetMaxMemberCnt(tonumber(getClanAttr(emClanProp_Level)))
	controls.m_MembersTxt.text      = string.format("%s", membersCnt).."/"..maxMemberCnt
	
	controls.m_MoneyTxt.text        = getClanAttr(emClanProp_Funds)

	controls.m_ActiveNumTxt.text = getClanAttr(emClanProp_ClanActivity)
	
	local szDeclareTxt = StringFilter.Filter(getClanAttr(emClanManifesto), "*")
	controls.m_DeclareTxt.text = szDeclareTxt
end

function ClanInfoWdt:SetCellListSize()

	local DescTxt = self.Controls.m_NewsDesc
	local DateTxt = self.Controls.m_NewsDate
	local nSpace = 30
	local nSpace2 = 45
	
	for k, v in pairs(self.m_NewsList) do
		-- 计算Cell大小
        local Content = RichTextHelp.AsysSerText(v.szCoutext, 32)
		local Rect = rkt.UIAndTextHelpTools.GetRichTextSize(DescTxt, Content)
		local nHeight = Rect.y

		local Rect2 = rkt.UIAndTextHelpTools.GetRichTextSize(DescTxt, "星期")
		local nHeight2 = Rect2.y
		
		local dateHeight = GetValuable(v.collapse, 0, nHeight2+nSpace2)
		
		-- 设置Cell大小
		self.Controls.listView:SetCellHeight(nHeight + nSpace + dateHeight, k - 1)
	end
end

function ClanInfoWdt:OnUpdateNewsList()
	if not self:isShow() then
		return 
	end

	local controls = self.Controls

	self.m_NewsList = IGame.ClanClient:GetClan():GetNewsList() or {}
	self:CalculateDate()
	controls.listView:SetCellCount( #self.m_NewsList , true )
	self:SetCellListSize()
	controls.listScroller:ReloadData()
end

function ClanInfoWdt:CalculateDate()
	if self.m_NewsList then
		for i, v in ipairs(self.m_NewsList) do
			local data = v
			local dateTab = os.date("*t",data.nTime)
			if dateTab then data.flag = tostring(dateTab.year).. "-" .. tostring(dateTab.month).."-"..tostring(dateTab.day) end -- 用天标记，同一天的放一组
			
			local lastData = self.m_NewsList[i-1]
			local nextData = self.m_NewsList[i+1]
			if lastData then
				dateTab = os.date("*t",lastData.nTime)
				if dateTab then lastData.flag = tostring(dateTab.year).. "-" .. tostring(dateTab.month).."-"..tostring(dateTab.day) end
			end
			if nextData then
				dateTab = os.date("*t",nextData.nTime)
				if dateTab then nextData.flag = tostring(dateTab.year).. "-" .. tostring(dateTab.month).."-"..tostring(dateTab.day) end
			end
			
			data.showDate = (not lastData) or (data.flag ~= lastData.flag) 
			data.collapse = (not nextData) or (data.flag == nextData.flag) 
			--data.collapse = not data.showDate
		end
	end
end

function ClanInfoWdt:CreateNewsItem(listcell)   
    local item = ClanNewsClass:new({})
    item:Attach(listcell.gameObject)	
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行被“创建”时的回调
function ClanInfoWdt:OnGetCellView( goCell )  
    goCell:SetActive(true)
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:CreateNewsItem(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function ClanInfoWdt:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function ClanInfoWdt:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

--- 刷新列表
function ClanInfoWdt:RefreshCellItems( listcell )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		uerror("Error： UI Window Behaviour")
		return
	end
	
	local item = behav.LuaObject
	if item == nil then
		uerror("LimitListWidget:RefreshCellItems item为空")
		return
	end
	
	local idx = listcell.dataIndex + 1
	if nil ~= item and item.windowName == "ClanNewsCell" then 
		item:SetCellData(idx)
	end
end

-- 帮会地图按钮点击事件
function ClanInfoWdt:OnBtnClanMapClicked()
	UIManager.ClanOwnWindow:Hide(true)

	IGame.ClanClient:RequestEnterEctype()
end

-- 帮派历程按钮点击事件
function ClanInfoWdt:OnBtnClanCourseClicked()

	UIManager.ClanCourseWindow:Show(true)
end

-- 修改帮名按钮点击事件
function ClanInfoWdt:OnBtnClanNameMdfClicked()

	UIManager.ClanNameMdfWindow:Show(true)
end

-- 修改声明按钮点击事件
function ClanInfoWdt:OnBtnDeclareMdfClicked()
	UIManager.ClanDeclareMdfWindow:Show(true)
end

return ClanInfoWdt
