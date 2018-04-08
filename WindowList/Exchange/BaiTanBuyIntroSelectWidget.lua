--/******************************************************************
--** 文件名:    BaiTanBuyIntroSelectWidget.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    交易界面-摆摊部件-介绍图标选择部件
--** 应  用:  
--******************************************************************/

local BaiTanBuyRowIntroItem = require("GuiSystem.WindowList.Exchange.BaiTanBuyRowIntroItem")

local BaiTanBuyIntroSelectWidget = UIControl:new
{
    windowName = "BaiTanBuyIntroSelectWidget",
	
	m_BigTypeId = 0,						-- 大类型id:number
	m_SmallTypeId = 0,						-- 小类型id:number
	m_LevelId = 0,							-- 等级id:number
	m_ShowForBuy = false,					-- 是否在购买状态下显示的标识:boolean
	
	m_CurSelectedQuality = 0,				-- 当前选中的品质:number
	m_CurSelectedGoodsCfgId = 0,			-- 当前选中的商品配置id:number
	
	m_EnhancedListView = nil,        		-- 商品介绍行图标的无限列表:EnhancedListView
    m_EnhancedScroller = nil,        		-- 商品介绍行图标的无限列表的滚动视图:EnhancedListView
	
	m_ListRowIntroData = {},				-- 行数据列表:table(table(IntroItemData)),表里面的每个表有2个数据	
	m_ListRowIntroItem = {},				-- 所有的行介绍图标实例列表:table(BaiTanBuyRowIntroItem)
}

function BaiTanBuyIntroSelectWidget:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	-- 绑定无限列表
	self:AttachEhancedList()
	
end

-- 绑定无限列表
function BaiTanBuyIntroSelectWidget:AttachEhancedList()
	
	self.m_EnhancedListView = self.Controls.m_TfScroBaiTanGoodsIntroItem:GetComponent(typeof(EnhancedListView))
	self.m_EnhancedScroller = self.Controls.m_TfScroBaiTanGoodsIntroItem:GetComponent(typeof(EnhancedScroller))
	
	self.m_EnhancedListView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	self.m_EnhancedListView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	
	self.m_EnhancedScroller.scrollerScrollingChanged = function(scroller ,scrolling) self:OnEnhancedScrollerScrol(scroller ,scrolling) end
	
end

-- 显示窗口
-- @bigTypeId:大类型id:number
-- @smallTypeId:小类型id:number
-- @levelId:等级id:number
-- @showForBuy:是否在购买状态显示的标识:boolean
function BaiTanBuyIntroSelectWidget:ShowWidget(bigTypeId, smallTypeId, levelId, showForBuy)
	
	--self.transform.gameObject:SetActive(true)
	UIControl.Show(self)
	
	self.m_ShowForBuy = showForBuy
	self.m_CurSelectedQuality = 0
	self.m_CurSelectedGoodsCfgId = 0
	
	-- 更新部件的显示
	self:UpdateWidgetShow(bigTypeId, smallTypeId, levelId, true)
	
end

-- 隐藏窗口
function BaiTanBuyIntroSelectWidget:HideWidget()
	
	UIControl.Hide(self, false)
	--self.transform.gameObject:SetActive(false)
	
end

-- 更新窗口的显示
-- @bigTypeId:大类型id:number
-- @smallTypeId:小类型id:number
-- @levelId:等级id:number
-- @needResetScroPos:是否需要重置滚动列表位置的标识:boolean
function BaiTanBuyIntroSelectWidget:UpdateWidgetShow(bigTypeId, smallTypeId, levelId, needResetScroPos)
	
    --self.transform.gameObject:SetActive(true)
	
	self.m_BigTypeId = bigTypeId
	self.m_SmallTypeId = smallTypeId
	self.m_LevelId = levelId
	self.m_ListRowIntroData = ExchangeWindowTool.GetSmallTypeRowIntroData(bigTypeId, smallTypeId, levelId, not self.m_ShowForBuy)

	self.m_EnhancedListView:SetCellCount( #self.m_ListRowIntroData , true )
	
	if needResetScroPos then
		 --self.m_EnhancedScroller:JumpToDataIndex( 0, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2, function() self.m_EnhancedScroller:Resize(false) end )
	end
	
end

-- 变更选中的介绍图标
-- @selectedQuailty:选中的品质id:number
-- @selectedGoodsCfgId:选中的商品配置id:number
function BaiTanBuyIntroSelectWidget:ChangeTheSelectedIntroItem(selectedQuailty, selectedGoodsCfgId)
	
	self.m_CurSelectedQuality = selectedQuailty
	self.m_CurSelectedGoodsCfgId = selectedGoodsCfgId
	
	for k,v in pairs(self.m_ListRowIntroItem) do
		v:HideItemSelectedTip()
	end
	
end

-- EnhancedListView 一行被创建时的回调
-- @goCell:新行实例:GameObject
function BaiTanBuyIntroSelectWidget:OnGetCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    if not enhancedCell then
        print(goCell.name)
    end

    enhancedCell.onRefreshCellView = handler( self , self.OnRefreshCellView )
	
	local item = BaiTanBuyRowIntroItem:new()
	item:Attach(goCell)
	
	table.insert(self.m_ListRowIntroItem, item)
	
end

-- EnhancedListView 一行可见时的回调
-- @goCell:行实例:GameObject
function BaiTanBuyIntroSelectWidget:OnCellViewVisiable( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems( enhancedCell )
	
end

-- EnhancedListView 一行强制刷新时的回调
-- @goCell:行实例:GameObject
function BaiTanBuyIntroSelectWidget:OnRefreshCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems(enhancedCell)
	
end

-- EnhancedScroller 在滚动的时候处理
-- @scroller:滚动视图:EnhancedScroller
-- @scrolling:是否在滚动中的标识:boolean
function BaiTanBuyIntroSelectWidget:OnEnhancedScrollerScrol( scroller ,scrolling )
	
end

-- 刷新一行图标
-- @enhancedCell:无限列表的行图标:EnhancedListViewCell
function BaiTanBuyIntroSelectWidget:RefreshCellItems( enhancedCell )
	
    local behav = enhancedCell:GetComponent(typeof(UIWindowBehaviour))
    local item = behav.LuaObject
	local rowData = self.m_ListRowIntroData[enhancedCell.dataIndex + 1]
	
    item:UpdateItem(rowData, self.m_CurSelectedQuality, self.m_CurSelectedGoodsCfgId)
	
end

return BaiTanBuyIntroSelectWidget