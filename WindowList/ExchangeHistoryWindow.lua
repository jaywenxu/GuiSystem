--/******************************************************************
--** 文件名:    ExchangeHistoryWindow.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    摆摊交易历史界面
--** 应  用:  
--******************************************************************/

local ExchangeHistoryItem = require("GuiSystem.WindowList.ExchangeHistory.ExchangeHistoryItem")

local ExchangeHistoryWindow = UIWindow:new
{
    windowName = "ExchangeHistoryWindow",	-- 窗口名称
    m_IsWindowInvokeOnShow = false;			-- 窗口是否调用了OnWindowShow方法的标识:boolean
	
	m_EnhancedListView = 0,        			-- 交易历史图标的无限列表:EnhancedListView
    m_EnhancedScroller = 0,        			-- 交易历史图标的无限列表的滚动视图:EnhancedListView
	
	m_ListHistroyData = {},					-- 交易历史数据列表:table(stExchangeTradeLogInfo)
}

function ExchangeHistoryWindow:Init()
	
end

function ExchangeHistoryWindow:OnAttach( obj )
	
    UIWindow.OnAttach(self, obj)

	self.Controls.m_ButtonClose.onClick:AddListener(function() self:OnCloseButtonClick() end)
	self.Controls.m_ButtonMask.onClick:AddListener(function() self:OnMaskButtonClick() end)
	
	-- 绑定无限列表
	self:AttachEhancedList()

    if self.m_IsWindowInvokeOnShow then
        self.m_IsWindowInvokeOnShow = false
        self:OnWindowShow()
    end
	
    return self
end

function ExchangeHistoryWindow:OnDestroy()
	UIWindow.OnDestroy(self)

	table_release(self)			
end


function ExchangeHistoryWindow:_showWindow()
	
    UIWindow._showWindow(self)
    if self:isLoaded() then
        self:OnWindowShow()
    else
        self.m_IsWindowInvokeOnShow = true
    end
	
end

-- 显示窗口
-- @msgBody:协议回包消息体:SMsgExchangeQueryLogs_SC
function ExchangeHistoryWindow:ShowWindow(msgBody)
	
	self.m_ListHistroyData = {}
	
	for dataIdx = 1, msgBody.counts do
		local data = msgBody.tradeLogInfoList[dataIdx]
		table.insert(self.m_ListHistroyData, msgBody.tradeLogInfoList[dataIdx])
		-- 只显示出售的
		--if data.btOpType == 2 then
		--	table.insert(self.m_ListHistroyData, msgBody.tradeLogInfoList[dataIdx])
		--end
	end
	
    UIWindow.Show(self, true)
	
end

-- 绑定无限列表
function ExchangeHistoryWindow:AttachEhancedList()
	
    self.m_EnhancedListView = self.Controls.m_TfScroExchangeHistoryItem:GetComponent(typeof(EnhancedListView))
    self.m_EnhancedScroller = self.Controls.m_TfScroExchangeHistoryItem:GetComponent(typeof(EnhancedScroller))
	
    self.m_EnhancedListView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
    self.m_EnhancedListView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	
    self.m_EnhancedScroller.scrollerScrollingChanged = function(scroller ,scrolling) self:OnEnhancedScrollerScrol(scroller ,scrolling) end
	
end

-- 窗口每次打开执行的行为
function ExchangeHistoryWindow:OnWindowShow()
	
	local haveHistoryData = #self.m_ListHistroyData > 0
	self.Controls.m_TfNoHistoryNode.gameObject:SetActive(not haveHistoryData)
	self.Controls.m_TfHaveHistoryNode.gameObject:SetActive(haveHistoryData)
	
	if not haveHistoryData then 
		return
	end
	self.m_EnhancedListView:SetCellCount( #self.m_ListHistroyData , true )
end

-- EnhancedListView 一行被创建时的回调
-- @goCell:新行实例:GameObject
function ExchangeHistoryWindow:OnGetCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    if not enhancedCell then
        print(goCell.name)
    end
	
    enhancedCell.onRefreshCellView = handler( self , self.OnRefreshCellView )

    local item = ExchangeHistoryItem:new({})
	item:SetIndex(enhancedCell.dataIndex)
    item:Attach(goCell)
	
end

-- EnhancedListView 一行可见时的回调
-- @goCell:行实例:GameObject
function ExchangeHistoryWindow:OnCellViewVisiable( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems( enhancedCell )
	
end

-- EnhancedListView 一行强制刷新时的回调
-- @goCell:行实例:GameObject
function ExchangeHistoryWindow:OnRefreshCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems(enhancedCell)
	
end

-- EnhancedScroller 在滚动的时候处理
-- @scroller:滚动视图:EnhancedScroller
-- @scrolling:是否在滚动中的标识:boolean
function ExchangeHistoryWindow:OnEnhancedScrollerScrol( scroller ,scrolling )
	
end

-- 刷新一行图标
-- @enhancedCell:无限列表的行图标:EnhancedListViewCell
function ExchangeHistoryWindow:RefreshCellItems( enhancedCell )
	
    local behav = enhancedCell:GetComponent(typeof(UIWindowBehaviour))
    local item = behav.LuaObject
	
    local data = self.m_ListHistroyData[enhancedCell.dataIndex + 1]
    item:UpdateItem(data)
	
end

-- 关闭按钮的点击行为
function ExchangeHistoryWindow:OnCloseButtonClick()
	
	UIManager.ExchangeHistoryWindow:Hide()
	
end

-- 遮罩按钮的点击行为
function ExchangeHistoryWindow:OnMaskButtonClick()
	
	UIManager.ExchangeHistoryWindow:Hide()
	
end

return ExchangeHistoryWindow