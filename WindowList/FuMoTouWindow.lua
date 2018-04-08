--/******************************************************************
--** 文件名:    FuMoTouWindow.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-07-11
--** 版  本:    1.0
--** 描  述:    伏魔骰界面
--** 应  用:  
--******************************************************************/

local FuMoTouItem = require("GuiSystem.WindowList.FuMoTou.FuMoTouItem")

local FuMoTouWindow = UIWindow:new
{
    windowName = "FuMoTouWindow",		-- 窗口名称
    
	m_IsWindowInvokeOnShow = false,    	-- 窗口是否调用了OnWindowShow方法的标识:boolean
	m_HadCallCnt = 0,					-- 已经召唤次数:number
	m_HadHelpCnt = 0,					-- 已经协助次数:number
	
	m_EnhancedListView = 0,        		-- 伏魔骰图标的无限列表:EnhancedListView
    m_EnhancedScroller = 0,        		-- 伏魔骰图标的无限列表的滚动视图:EnhancedListView
	
	m_ListPoint = {},					-- 伏魔骰点数列表:table(number)
	m_ListPointScheme = {},				-- 伏魔骰点数配置列表:table(gFuMoTaCfg.monsters)
}

function FuMoTouWindow:Init()
	
end

function FuMoTouWindow:OnAttach( obj )
	
    UIWindow.OnAttach(self, obj)
    
	self.onUseButtonClick = function() self:OnUseButtonClick() end
	self.onCloseButtonClick = function() self:OnCloseButtonClick() end
	self.onDecButtononClick =function() self:OnDecButtonClick() end
	self.Controls.m_ButtonUse.onClick:AddListener(self.onUseButtonClick)
	self.Controls.m_ButtonClose.onClick:AddListener(self.onCloseButtonClick)
	self.Controls.m_ButtonDec.onClick:AddListener(self.onDecButtononClick)
	self.Controls.m_closeBg.onClick:AddListener(self.onCloseButtonClick)
	-- 绑定无限列表
	self:AttachEhancedList()
    -- 事件绑定
    --self:SubscribeEvent()
	
    if self.m_IsWindowInvokeOnShow then
        self.m_IsWindowInvokeOnShow = false
        self:OnWindowShow()
    end
	
    return self
	
end

--伏魔骰描述
function FuMoTouWindow:OnDecButtonClick()
	UIManager.CommonGuideWindow:ShowWindow(gFuMoTouCfg.RuleID)
end

-- 窗口销毁
function FuMoTouWindow:OnDestroy()
	
    -- 移除事件的绑定
    --self:UnSubscribeEvent()
    UIWindow.OnDestroy(self)
	
end

function FuMoTouWindow:_showWindow()
	
    UIWindow._showWindow(self)
    if self:isLoaded() then
        self:OnWindowShow()
    else
        self.m_IsWindowInvokeOnShow = true
    end
	
end

-- 绑定无限列表
function FuMoTouWindow:AttachEhancedList()
	
    self.m_EnhancedListView = self.Controls.m_TfScroFuMoTouItem:GetComponent(typeof(EnhancedListView))
    self.m_EnhancedScroller = self.Controls.m_TfScroFuMoTouItem:GetComponent(typeof(EnhancedScroller))
    self.m_EnhancedListView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
    self.m_EnhancedListView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
    self.m_EnhancedScroller.scrollerScrollingChanged = function(scroller ,scrolling) self:OnEnhancedScrollerScrol(scroller ,scrolling) end
	
end

-- 事件绑定
function FuMoTouWindow:SubscribeEvent()
	
    self.m_ArrSubscribeEvent = 
    {
        {
            e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_ON_LAST_SMALL_TYPE_ITEM_CREATE_SUCC,
            f = function(event, srctype, srcid) self:HandleLastSmallTypeItemCreateSucc() end,
        },
    }
	
    for k,v in pairs(self.m_ArrSubscribeEvent) do
        rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
    end
	
end

-- 移除事件的绑定
function FuMoTouWindow:UnSubscribeEvent()
	
    for k,v in pairs(self.m_ArrSubscribeEvent) do
        rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
    end
	
end

-- 显示窗口
-- @callCnt:召唤次数:number
-- @helpCnt:协助次数:number
function FuMoTouWindow:ShowWindow(callCnt, helpCnt)

	self.m_HadCallCnt = callCnt
	self.m_HadHelpCnt = helpCnt
	
    UIWindow.Show(self, true)
	
end

-- 窗口每次打开执行的行为
function FuMoTouWindow:OnWindowShow()
	
	self.m_ListPoint = {}
	self.m_ListPointScheme = {}
	for k,v in pairs(gFuMoTouCfg.monsters) do
		table.insert(self.m_ListPoint, k)
		self.m_ListPointScheme[k] = v
	end

	self.Controls.m_TextUseCnt.text = string.format("今天已使用伏魔骰: %d/%d 次", self.m_HadCallCnt, gFuMoTouCfg.MaxCallCount)
	self.Controls.m_TextHelpCnt.text = string.format("今天获得协助宝箱: %d/%d 次", self.m_HadHelpCnt, gFuMoTouCfg.MaxHelpCount)
	
	table.sort(self.m_ListPoint)
	self.m_EnhancedListView:SetCellCount( #self.m_ListPoint , true )
end

-- EnhancedListView 一行被创建时的回调
-- @goCell:新行实例:GameObject
function FuMoTouWindow:OnGetCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    if not enhancedCell then
        print(goCell.name)
    end

    enhancedCell.onRefreshCellView = handler( self , self.OnRefreshCellView )

    local item = FuMoTouItem:new({})
    item:Attach(goCell)
    item:SetIndex(enhancedCell.dataIndex)
	
end

-- EnhancedListView 一行可见时的回调
-- @goCell:行实例:GameObject
function FuMoTouWindow:OnCellViewVisiable( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems( enhancedCell )
	
end

-- EnhancedListView 一行强制刷新时的回调
-- @goCell:行实例:GameObject
function FuMoTouWindow:OnRefreshCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems(enhancedCell)
	
end

-- EnhancedScroller 在滚动的时候处理
-- @scroller:滚动视图:EnhancedScroller
-- @scrolling:是否在滚动中的标识:boolean
function FuMoTouWindow:OnEnhancedScrollerScrol( scroller ,scrolling )
	
end

-- 刷新一行图标
-- @enhancedCell:无限列表的行图标:EnhancedListViewCell
function FuMoTouWindow:RefreshCellItems( enhancedCell )
	
    local behav = enhancedCell:GetComponent(typeof(UIWindowBehaviour))
    local item = behav.LuaObject
	
	local point = self.m_ListPoint[enhancedCell.dataIndex + 1]
	local scheme = self.m_ListPointScheme[point]
    item:UpdateItem(point, scheme)
	
end


-- 使用按钮的点击行为
function FuMoTouWindow:OnUseButtonClick()
	
	GameHelp.PostServerRequest("RequestFuMoTouRandom()")

end

-- 关闭按钮的点击行为
function FuMoTouWindow:OnCloseButtonClick()
	
	UIManager.FuMoTouWindow:Hide()
	
end

return FuMoTouWindow