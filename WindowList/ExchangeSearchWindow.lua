--/******************************************************************
--** 文件名:    ExchangeSearchWindow.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    商品交易搜索窗口
--** 应  用:  
--******************************************************************/

ExchangeFuzzySearchResultItem = require("GuiSystem.WindowList.ExchangeSearch.ExchangeFuzzySearchResultItem")
ExchangeSearchRecordItem = require("GuiSystem.WindowList.ExchangeSearch.ExchangeSearchRecordItem")

local ExchangeSearchWindow = UIWindow:new
{
    windowName = "ExchangeSearchWindow",        -- 窗口名称
	
    m_IsWindowInvokeOnShow = false;    			-- 窗口是否调用了OnWindowShow方法的标识:boolean
	m_InputSearch = nil,						-- 搜索输入栏:InputField

	m_EnhancedListView = 0,        				-- 模糊搜索结果图标的无限列表:EnhancedListView
    m_EnhancedScroller = 0,        				-- 模糊搜索结果图标的无限列表的滚动视图:EnhancedListView
	
	m_ListSearchRecordItem = {},				-- 搜索记录图标脚本:table(ExchangeSearchRecordItem)
	m_ListFuzzySearchResult = {},				-- 模糊搜索结果:table(table(BaiTanFuzzySearchData)) --每个子表有最多2数据
}

function ExchangeSearchWindow:Init()
	
	
end

function ExchangeSearchWindow:OnAttach( obj )
	
    UIWindow.OnAttach(self, obj)
	
	-- 绑定无限列表
	self:AttachEhancedList()

	self.m_InputSearch = self.Controls.m_TfInputSearch.gameObject:GetComponent("InputField")
	self.m_InputSearch.onEndEdit:AddListener(function(inputField) self:OnSearchInputEndEdit(inputField) end);
	
	self.Controls.m_ButtonFuzzySearchMask.onClick:AddListener(function() self:OnFuzzySearchMaskClick() end)
	self.Controls.m_ButtonClose.onClick:AddListener(function() self:OnCloseButtonClick() end)
	self.Controls.m_ButtonSearch.onClick:AddListener(function() self:OnSearchButtonClick() end)
	
	for recordIdx = 1, MAX_SEARCH_RECORD_SAVE_NUM do
		local tf = self.Controls[string.format("m_TfExchangeSearchRecordItem%d", recordIdx)]
		local item = ExchangeSearchRecordItem:new()
		item:Attach(tf.gameObject)
		
		self.m_ListSearchRecordItem[recordIdx] = item
	end
	
	if self.m_IsWindowInvokeOnShow then
        self.m_IsWindowInvokeOnShow = false
        self:OnWindowShow()
    end
	
    return self
	
end

function ExchangeSearchWindow:OnDestroy()
	UIWindow.OnDestroy(self)

	table_release(self)			
end


function ExchangeSearchWindow:_showWindow()
	
    UIWindow._showWindow(self)
	
    if self:isLoaded() then
        self:OnWindowShow()
    else
        self.m_IsWindowInvokeOnShow = true
    end
	
end


-- 窗口每次打开执行的行为
function ExchangeSearchWindow:OnWindowShow()

	self.Controls.m_TfFuzzySearchNode.gameObject:SetActive(false)
	self.m_InputSearch.text = ""
	
	
	-- 更新搜索记录图标的显示
	self:UpdateRecordItemShow()
	
end

-- 更新搜索记录图标的显示
function ExchangeSearchWindow:UpdateRecordItemShow()
	
	local listRecord = IGame.ExchangeClient:GetSearchRecord()
	local tableSort = {}
	local tableSortTime = {}

	-- 排序,最大的时间显示在最前面
	for k,v in pairs(listRecord) do
		table.insert(tableSort, -v.m_LastSearchTime)
		tableSortTime[-v.m_LastSearchTime] = v
	end

	table.sort(tableSort)

	local recordCnt = #listRecord
	for itemIdx = 1, #self.m_ListSearchRecordItem do
		local item = self.m_ListSearchRecordItem[itemIdx]
		local itemNeedShow = itemIdx <= recordCnt
		
		item.transform.gameObject:SetActive(itemNeedShow)
		
		if itemNeedShow then
			local recordTime = tableSort[itemIdx]
			local recordData = tableSortTime[recordTime]
			item:UpdateItem(recordData)
		end
	end
	
end

-- 显示模糊搜索结果
-- @listFuzzySearchData:模糊搜索匹配到的配置:table(BaiTanFuzzySearchData)
function ExchangeSearchWindow:ShowFuzzySearchResult(listFuzzySearchData)
	
	self.Controls.m_TfFuzzySearchNode.gameObject:SetActive(true)
	
	-- 根据序号排序搜索到数据
	local tableSort = {}
	local tableNo = {}
	for k,v in pairs(listFuzzySearchData) do
		local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, v.m_GoodsCfgId )
		if goodsScheme ~= nil then
			local no = goodsScheme.index * 10000 + v.m_Quality
			table.insert(tableSort, no)
			tableNo[no] = v
		end
	end
	
	table.sort(tableSort)
	
	-- 整理数据，图标一行有2个记录
	self.m_ListFuzzySearchResult = {}
	local tableIdx = 1
	local schemeIdx = 1
	for resultIdx = 1, #tableSort do
		if self.m_ListFuzzySearchResult[tableIdx] == nil then
			self.m_ListFuzzySearchResult[tableIdx] = {}
		end
		
		local no = tableSort[resultIdx]
		local data = tableNo[no]
		
		self.m_ListFuzzySearchResult[tableIdx][schemeIdx] = data
		
		schemeIdx = schemeIdx + 1
		if schemeIdx > 2 then
			tableIdx = tableIdx + 1
			schemeIdx = 1
		end
	end
	self.m_EnhancedListView:SetCellCount( #self.m_ListFuzzySearchResult , true )
end

-- 绑定无限列表
function ExchangeSearchWindow:AttachEhancedList()
	
    self.m_EnhancedListView = self.Controls.m_TfScroExchangeFuzzySearchResultItem:GetComponent(typeof(EnhancedListView))
    self.m_EnhancedScroller = self.Controls.m_TfScroExchangeFuzzySearchResultItem:GetComponent(typeof(EnhancedScroller))
	
    self.m_EnhancedListView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
    self.m_EnhancedListView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	
    self.m_EnhancedScroller.scrollerScrollingChanged = function(scroller ,scrolling) self:OnEnhancedScrollerScrol(scroller ,scrolling) end

end

-- EnhancedListView 一行被创建时的回调
-- @goCell:新行实例:GameObject
function ExchangeSearchWindow:OnGetCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))

    enhancedCell.onRefreshCellView = handler( self , self.OnRefreshCellView )

    local item = ExchangeFuzzySearchResultItem:new({})
    item:Attach(goCell)
	
end

-- EnhancedListView 一行可见时的回调
-- @goCell:行实例:GameObject
function ExchangeSearchWindow:OnCellViewVisiable( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems( enhancedCell )
	
end

-- EnhancedListView 一行强制刷新时的回调
-- @goCell:行实例:GameObject
function ExchangeSearchWindow:OnRefreshCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems(enhancedCell)
	
end

-- EnhancedScroller 在滚动的时候处理
-- @scroller:滚动视图:EnhancedScroller
-- @scrolling:是否在滚动中的标识:boolean
function ExchangeSearchWindow:OnEnhancedScrollerScrol( scroller ,scrolling )
	
end

-- 刷新一行图标
-- @enhancedCell:无限列表的行图标:EnhancedListViewCell
function ExchangeSearchWindow:RefreshCellItems( enhancedCell )
	
    local behav = enhancedCell:GetComponent(typeof(UIWindowBehaviour))
    local item = behav.LuaObject
	local listScheme = self.m_ListFuzzySearchResult[enhancedCell.dataIndex + 1]
    
	item:UpdateItem(listScheme)
	
end


-- 搜索输入栏结束时的行为
-- 模糊匹配
-- @inputField:输入栏控件:InputField
function ExchangeSearchWindow:OnSearchInputEndEdit(inputField)
	
	if self.m_InputSearch.text == "" then
		return
	end
	
	local listFuzzySearchData = ExchangeWindowTool.GetFuzzySearchNameResultData(self.m_InputSearch.text)
	if not listFuzzySearchData then
		return
	end
	
	self:ShowFuzzySearchResult(listFuzzySearchData)
	
end

-- 搜索按钮的点击行为
-- 完全匹配
function ExchangeSearchWindow:OnSearchButtonClick()
	
	if self.m_InputSearch.text == "" then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请输入正确的商品名称！")
		return
	end
	
	local searchData = ExchangeWindowTool.GetSearchNameResultData(self.m_InputSearch.text)
	if not searchData then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请输入正确的商品名称！")
		return
	end
	
	IGame.ExchangeClient:AddSearchRecord(searchData)
	UIManager.ExchangeSearchWindow:Hide()
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_CHANGE_QUERY_GOODS,  searchData.m_GoodsCfgId, searchData.m_Quality)
		
end

-- 模式搜索遮罩点击行为
function ExchangeSearchWindow:OnFuzzySearchMaskClick()
	
	self.Controls.m_TfFuzzySearchNode.gameObject:SetActive(false)
	
end

-- 关闭按钮的点击行为
function ExchangeSearchWindow:OnCloseButtonClick()
	
	UIManager.ExchangeSearchWindow:Hide()
	
end

return ExchangeSearchWindow