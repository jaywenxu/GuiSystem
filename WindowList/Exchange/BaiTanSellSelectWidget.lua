--/******************************************************************
--** 文件名:    BaiTanSellSelectWidget.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-26
--** 版  本:    1.0
--** 描  述:    摆摊出售窗口-上架物选择窗口
--** 应  用:  
--******************************************************************/

local BaiTanSellRowBagItem = require("GuiSystem.WindowList.Exchange.BaiTanSellRowBagItem")

local ONE_LINE_ITEM_CNT = 4       -- 一行图标数量


local BaiTanSellSelectWidget = UIControl:new
{
    windowName = "BaiTanSellSelectWidget",
	
	m_SelectedUid = 0,			-- 当前选中的uid:long
	m_EnhancedListView = 0,        	-- 上架物行图标的无限列表:EnhancedListView
    m_EnhancedScroller = 0,        	-- 上架物行图标的无限列表的滚动视图:EnhancedListView
	
	m_ListRowBagItem = {},			-- 行图标脚本列表:table(BaiTanSellRowBagItem)
	m_ListRowData = {},				-- 上架物行数据列表，每个子table里面有5个数据:table(table(entity)),
}

function BaiTanSellSelectWidget:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	-- 绑定无限列表
	self:AttachEhancedList()
	
end

-- 显示窗口
function BaiTanSellSelectWidget:ShowWidget()
	
	if ExchangeWindowPresetDataMgr.m_DstSelectedPacketItemUid ~= nil then
		self.m_SelectedUid = ExchangeWindowPresetDataMgr.m_DstSelectedPacketItemUid 
		ExchangeWindowPresetDataMgr:PresetDestPacketSelectEntityUid(nil)
	else 
		self.m_SelectedUid = 0
	end
	
	-- 更新窗口
	self:UpdateWidget()
	
end

-- 更新窗口
function BaiTanSellSelectWidget:UpdateWidget()
	
	-- 准备行数据
	self:PrepareRowData()

	self.m_EnhancedListView:SetCellCount( MAX_PACKET_SIZE / ONE_LINE_ITEM_CNT , true )
	
end

-- 出售界面摆摊背包格子选中处理
-- @entityUid:选中的实体uid:long
function BaiTanSellSelectWidget:ChangeTheSelectCell(entityUid)
	
	self.m_SelectedUid = entityUid
	
	for k,v in pairs(self.m_ListRowBagItem) do
		v:HideSelectedTip()
	end
	
end

-- 准备行数据
function BaiTanSellSelectWidget:PrepareRowData()
	
	local packetPart = GetHeroEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end

	self.m_ListRowData = {}
	-- 先填充80个0
	local colIdx = 1
	local rowData = nil
	for cellIdx = 1, MAX_PACKET_SIZE do
		if colIdx == 1 then
			local newRowData = {}
			
			rowData = newRowData
			table.insert(self.m_ListRowData, rowData)
		end
		
		table.insert(rowData, 0)
		colIdx = colIdx + 1
		
		if colIdx > ONE_LINE_ITEM_CNT then
			colIdx = 1
		end
	end

	-- 将能上架的物品丢进去
	local rowIdx = 1
	colIdx = 1
	local listAllPackgetItemUid = packetPart:GetAllGoods()
	for k,v in pairs(listAllPackgetItemUid) do
		local entity = IGame.EntityClient:Get(v)
		local canPut = ExchangeWindowTool.CheckGoodsCanPut(entity)
		
		if canPut then
			self.m_ListRowData[rowIdx][colIdx] = entity

			colIdx = colIdx + 1
			if colIdx > ONE_LINE_ITEM_CNT then
				colIdx = 1
				rowIdx = rowIdx + 1
			end
		end
	end
	
end

-- 绑定无限列表
function BaiTanSellSelectWidget:AttachEhancedList()
	
    self.m_EnhancedListView = self.Controls.m_TfScroBaiTanSellRowBagItem:GetComponent(typeof(EnhancedListView))
    self.m_EnhancedScroller = self.Controls.m_TfScroBaiTanSellRowBagItem:GetComponent(typeof(EnhancedScroller))
	
    self.m_EnhancedListView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
    self.m_EnhancedListView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
    self.m_EnhancedScroller.scrollerScrollingChanged = function(scroller ,scrolling) self:OnEnhancedScrollerScrol(scroller ,scrolling) end

end

-- EnhancedListView 一行被创建时的回调
-- @goCell:新行实例:GameObject
function BaiTanSellSelectWidget:OnGetCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    if not enhancedCell then
        print(goCell.name)
    end

    enhancedCell.onRefreshCellView = handler( self , self.OnRefreshCellView )
	
	local item = BaiTanSellRowBagItem:new()
    item:Attach(goCell)
	
	table.insert(self.m_ListRowBagItem, item)
	
end

-- EnhancedListView 一行可见时的回调
-- @goCell:行实例:GameObject
function BaiTanSellSelectWidget:OnCellViewVisiable( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems( enhancedCell )
	
end

-- EnhancedListView 一行强制刷新时的回调
-- @goCell:行实例:GameObject
function BaiTanSellSelectWidget:OnRefreshCellView( goCell )
	
    local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
    self:RefreshCellItems(enhancedCell)
	
end

-- EnhancedScroller 在滚动的时候处理
-- @scroller:滚动视图:EnhancedScroller
-- @scrolling:是否在滚动中的标识:boolean
function BaiTanSellSelectWidget:OnEnhancedScrollerScrol( scroller ,scrolling )
	
	
	
end

-- 刷新一行图标
-- @enhancedCell:无限列表的行图标:EnhancedListViewCell
function BaiTanSellSelectWidget:RefreshCellItems( enhancedCell )
	
    local behav = enhancedCell:GetComponent(typeof(UIWindowBehaviour))
    local item = behav.LuaObject
	
	local rowData = self.m_ListRowData[enhancedCell.dataIndex + 1]
    item:UpdateItem(rowData, self.m_SelectedUid)
	
end

return BaiTanSellSelectWidget