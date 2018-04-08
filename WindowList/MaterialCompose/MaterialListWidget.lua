-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-05-04
-- 描  述:    商品显示
-------------------------------------------------------------------

local MaterialItemCellClass = require( "GuiSystem.WindowList.MaterialCompose.MaterialItemCell" )


local ITEM_COUNT_IN_LINE = 1 --一行俩列


local MaterialListWidget = UIControl:new
{
	windowName = "MaterialListWidget",
	m_nCount = 0,		-- item数量
	m_CurrIndex = 0,
	m_goodsId   = 0,
}

local this = MaterialListWidget


function MaterialListWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.Controls.ItemList = self.Controls.m_ItemList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateActivityList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.ItemList.onGetCellView:AddListener(self.callbackCreateActivityList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.ItemList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	
	self.Controls.scroller =  self.Controls.m_ItemList:GetComponent(typeof(EnhancedScroller))
	self.Controls.ItemToggleGroup =  self.Controls.m_ItemList:GetComponent(typeof(ToggleGroup))
	
	return self
end

-- 创建物品列表
function MaterialListWidget:onCreateLimitList(listcell)
	if nil == listcell.gameObject then   -- 判断U3D对象是否已经被销毁
		rkt.GResources.RecycleGameObject(obj)
		uerror("object had been destroy!")
		return
	end	
	local item = MaterialItemCellClass:new({})

	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.Controls.ItemToggleGroup)
	item:SetSelectCallback(function(itemCell ,on) MaterialListWidget.OnItemCellSelected(itemCell ,on) end)
	self:RefreshCellItems(listcell)
end

-- item 被选中
function MaterialListWidget.OnItemCellSelected(itemCell ,on)
	if not on then
		return
	end
	local itemIndex = itemCell:GetItemIndex()
	local nGoodID = itemCell:GetGoodID()
    if  itemIndex and itemIndex ~= 0 then
		if on then
			UIManager.MaterialComposeWindow:RefreshDataInfo(nGoodID,nil,false)
		end         		
	end	
end

--- 刷新列表
function MaterialListWidget:RefreshCellItems( listcell )	
	local tFilterGoodsTable = UIManager.MaterialComposeWindow:GetFilterGoodsList()
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	-- 当前是第几个item
	local itemIndex = listcell.dataIndex + 1
	if nil ~= listcell.gameObject then 
		local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
		if nil ~= behav then 
			local item = behav.LuaObject
			if nil ~= item and "MaterialItemCell" == item.windowName then 
				local nGoodID = tFilterGoodsTable[itemIndex]
				local goodsNum = packetPart:GetGoodNum(nGoodID)
				item:SetItemCellInfo(nGoodID, itemIndex, goodsNum)
				if self.m_goodsId ==  nGoodID then
					item:SetFocus(true)
				else
					item:SetFocus(false)
				end
			end
		end
	else
		print("can't get activeity object index:"..itemIndex)
	end
end

function MaterialListWidget:SetGoodID(nGoodID)
	self.m_goodsId = nGoodID
end

-- 重新加载
function MaterialListWidget:ReloadData(goodsId,ReloadFlg)
	if ReloadFlg == nil then
		ReloadFlg = true
	end
	self.m_goodsId = goodsId
	local tFilterGoodsTable = UIManager.MaterialComposeWindow:GetFilterGoodsList()
	self.m_nCount = table.getn(tFilterGoodsTable)
	local itemIndex = 0
	for i, v in pairs(tFilterGoodsTable) do
		if v == goodsId then 
			itemIndex = i
		end
	end
	if self.m_nCount > 4 then
		if self.m_nCount - itemIndex < 3  then
			itemIndex = self.m_nCount - 3
		end
	end
	
	if itemIndex ~= 0 then 
		itemIndex = itemIndex - 1
	end
	if ReloadFlg then
		self.Controls.ItemList:SetCellCount( self.m_nCount , ReloadFlg )	
		if self.m_nCount >4 then
			DelayExecuteEx(10,function () self:JumpToDataIndex( itemIndex )	end)
		end
	end
end

function MaterialListWidget:JumpToDataIndex( itemIndex )
	self.Controls.scroller:JumpToDataIndex( itemIndex, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2, nil)
end

-- EnhancedListView 一行被“创建”时的回调
function MaterialListWidget:OnGetCellView( goCell )
	--print("<color=red>一行被“创建”时的回调</color>")
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:onCreateLimitList(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function MaterialListWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function MaterialListWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

function MaterialListWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

return this