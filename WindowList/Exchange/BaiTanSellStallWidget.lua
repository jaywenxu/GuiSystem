--/******************************************************************
--** 文件名:    BaiTanSellStallWidget.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-26
--** 版  本:    1.0
--** 描  述:    摆摊出售窗口-摊位窗口
--** 应  用:  
--******************************************************************/

local BaiTanSellRowStallItem = require("GuiSystem.WindowList.Exchange.BaiTanSellRowStallItem")

local BaiTanSellStallWidget = UIControl:new
{
    windowName = "BaiTanSellStallWidget",
	
	m_CurSelectedStallId = 0,			-- 当前选中的摊位id:long
	
	m_EnhancedListView = 0,        		-- 摊位行图标的无限列表:EnhancedListView
    m_EnhancedScroller = 0,        		-- 摊位行图标的无限列表的滚动视图:EnhancedListView
	
	m_ListStallRowData = {},			-- 摊位行数据列表,每个子table有2个数据:table(table())
}

function BaiTanSellStallWidget:Attach(obj)
	
    UIControl.Attach(self, obj)
	
	-- 绑定无限列表
	self:AttachEhancedList()
	
end

-- 显示窗口
function BaiTanSellStallWidget:ShowWidget()
	
	self.m_CurSelectedStallId = 0
	
	-- 更新窗口
	self:UpdateWidget()
	
end

-- 更新窗口
function BaiTanSellStallWidget:UpdateWidget()
	
	local paramScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_CONFIG_CSV, 1)
	if not paramScheme then
		uerror("没有找到 ExchangeConfig.csv!")
		return
	end 
	
	local listStallData = IGame.ExchangeClient:GetAllStallData()
	if not listStallData then 
		return
	end

	-- 计算有效的摊位数量
	local havePutGoodsCnt = #listStallData
	local validPutGoodsCnt = 0
	for k,v in pairs(listStallData) do
		if v.btState ~= E_GoodState_Check then
			validPutGoodsCnt = validPutGoodsCnt + 1
		end
	end

	self.m_ListStallRowData = {}
	
	self.Controls.m_TfNoStallNode.gameObject:SetActive(havePutGoodsCnt < 1)
	self.Controls.m_TfHaveStallNode.gameObject:SetActive(havePutGoodsCnt > 0)
	self.Controls.m_TextStallNum.text = string.format("我的摊位%d/%d", validPutGoodsCnt, paramScheme.billsLimitOfPerson)
	
	if havePutGoodsCnt > 0 then
		local rowIdx = 1
		local colIdx = 1
		for dataIdx = 1, havePutGoodsCnt do
			if colIdx == 1 then
				self.m_ListStallRowData[rowIdx] = {}
				self.m_ListStallRowData[rowIdx][1] = 0
				self.m_ListStallRowData[rowIdx][2] = 0
			end
			
			self.m_ListStallRowData[rowIdx][colIdx] = listStallData[dataIdx]
			
			colIdx = colIdx + 1
			
			if colIdx > 2 then
				colIdx = 1
				rowIdx = rowIdx + 1
			end
		end

		self.m_EnhancedListView:SetCellCount( #self.m_ListStallRowData , true )
	end
	
end

-- 变更选中的
-- @stallId:摊位id:long
function BaiTanSellStallWidget:ChangeTheSelectedStall(stallId)
	
	self.m_CurSelectedStallId = stallId
	
	-- 更新窗口
	self:UpdateWidget()
	
end

-- 绑定无限列表
function BaiTanSellStallWidget:AttachEhancedList()
	
    self.m_EnhancedListView = self.Controls.m_TfScroBaiTanSellRowStallItem:GetComponent(typeof(EnhancedListView))
    self.m_EnhancedScroller = self.Controls.m_TfScroBaiTanSellRowStallItem:GetComponent(typeof(EnhancedScroller))
	
    self.m_EnhancedListView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
    self.m_EnhancedListView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
    --self.m_EnhancedScroller.scrollerScrollingChanged = function(scroller ,scrolling) self:OnEnhancedScrollerScrol(scroller ,scrolling) end

end

-- EnhancedListView 一行被创建时的回调
-- @goCell:新行实例:GameObject
function BaiTanSellStallWidget:OnGetCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    if not enhancedCell then
        print(goCell.name)
    end
    enhancedCell.onRefreshCellView = handler( self , self.OnRefreshCellView )
    local item = BaiTanSellRowStallItem:new({})
    item:Attach(goCell)
	
end

-- EnhancedListView 一行可见时的回调
-- @goCell:行实例:GameObject
function BaiTanSellStallWidget:OnCellViewVisiable( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems( enhancedCell )
	
end

-- EnhancedListView 一行强制刷新时的回调
-- @goCell:行实例:GameObject
function BaiTanSellStallWidget:OnRefreshCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems(enhancedCell)
	
end

-- EnhancedScroller 在滚动的时候处理
-- @scroller:滚动视图:EnhancedScroller
-- @scrolling:是否在滚动中的标识:boolean
function BaiTanSellStallWidget:OnEnhancedScrollerScrol( scroller ,scrolling )
	
end

-- 刷新一行图标
-- @enhancedCell:无限列表的行图标:EnhancedListViewCell
function BaiTanSellStallWidget:RefreshCellItems( enhancedCell )
	
    local behav = enhancedCell:GetComponent(typeof(UIWindowBehaviour))
    local item = behav.LuaObject
	
    local rowData = self.m_ListStallRowData[enhancedCell.dataIndex + 1]
    item:UpdateItem(rowData, self.m_CurSelectedStallId)
	
end


return BaiTanSellStallWidget