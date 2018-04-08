-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-05-04
-- 描  述:    商品显示
-------------------------------------------------------------------

local ChipItemCellClass = require( "GuiSystem.WindowList.ChipExchange.ChipItemCell" )
local ChipItemGroupCellClass = require( "GuiSystem.WindowList.ChipExchange.ChipItemGroupCell" )

-- 设置item 中的金钱图标
local ItemMoneyIconPath = 
{
	AssetPath.TextureGUIPath.."Activity/.png",	-- 竞技页 图标
	AssetPath.TextureGUIPath.."Activity/.png",	-- 论剑   图标
	AssetPath.TextureGUIPath.."Activity/.png",	-- 侠义度 图标
	AssetPath.TextureGUIPath.."Activity/.png",	-- 保留   图标
}

local CHIPCELL_ITEM_COUNT_IN_LINE = 2 --一行俩列


local ChipListWidget = UIControl:new
{
	windowName = "ChipListWidget",
	m_nCount = 0,		-- item数量
	m_CurrIndex = 0,
	m_selectedIndex = 1,  -- 选中Index
	m_itemScriptCache = {}
}

local this = ChipListWidget


function ChipListWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	
	self.Controls.ChipList = self.Controls.m_ChipList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateActivityList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.ChipList.onGetCellView:AddListener(self.callbackCreateActivityList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.ChipList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	
	self.Controls.scroller =  self.Controls.m_ChipList:GetComponent(typeof(EnhancedScroller))
	self.Controls.ItemToggleGroup =  self.Controls.m_ChipList:GetComponent(typeof(ToggleGroup))
	
	-- 要显示的行数  
	self.m_nCount = IGame.ChipExchangeClient:GetInfoCount()

	self.Controls.ChipList:SetCellCount( math.ceil(self.m_nCount / CHIPCELL_ITEM_COUNT_IN_LINE ) , true )
	
	return self
	
end

-- 创建物品列表
function ChipListWidget:onCreateLimitList(listcell)
	for i = 1 , CHIPCELL_ITEM_COUNT_IN_LINE , 1 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.ChipItemCell ,
		function ( path , obj , ud )
			if nil == listcell.gameObject then   -- 判断U3D对象是否已经被销毁
				rkt.GResources.RecycleGameObject(obj)
				print("object had been destroy!")
				return
			end
			if listcell.transform.childCount >= CHIPCELL_ITEM_COUNT_IN_LINE then  -- 已经满了
				print("full of listcell transform!")
				rkt.GResources.RecycleGameObject(obj)
				return
			end
							
			obj.transform:SetParent(listcell.transform, false)
			
			local item = ChipItemCellClass:new({})
			item:Attach(obj)
			
			
			if listcell.transform.childCount == CHIPCELL_ITEM_COUNT_IN_LINE then
				self:RefreshCellItems(listcell)
			end		--]]
		end , i , AssetLoadPriority.GuiNormal )
	end
end

-- item 被选中
function ChipListWidget:OnItemCellSelected(itemCell ,on)
	-- false 直接返回不处理
	if not on then
		return
	end
	local index = itemCell:GetChipIndex()
	if not index then
		return
	end
	self:Refresh(index,false)
	self.m_ChipExchangeWidget.ChipExchengeGoodsInfo:UpdateExchangeGoodsInfo(index)
	self.m_ChipExchangeWidget.ChipExchengeExpense:UpdateExchangeExpenseInfo(index)
	self.m_ChipExchangeWidget:SetSecIndex(index)
end

--- 刷新列表
function ChipListWidget:RefreshCellItems( listcell )	
	local listcell_trans = listcell.transform

	if listcell_trans.childCount ~= CHIPCELL_ITEM_COUNT_IN_LINE then
		return
	end
	
	for i = 1, CHIPCELL_ITEM_COUNT_IN_LINE, 1 do
		local itemCell = listcell_trans:GetChild(i - 1)
		
		-- 当前是第几个item
		local itemIndex = listcell.dataIndex * CHIPCELL_ITEM_COUNT_IN_LINE + i
		if itemIndex > self.m_nCount then 
			itemCell.gameObject:SetActive(false)
			return
		else
			itemCell.gameObject:SetActive(true)
		end
		
		if nil ~= itemCell.gameObject then 
			local behav = itemCell:GetComponent(typeof(UIWindowBehaviour))
			if nil ~= behav then 
				
				local item = behav.LuaObject
				if nil ~= item and "ChipItemCell" == item.windowName then
					item:SetSelectCallback(handler(self,self.OnItemCellSelected))
					item:SetToggleGroup(self.Controls.ItemToggleGroup)
					--item:SetFocus(false)
					item:SetItemCellInfo(itemIndex)
					if itemIndex == self.m_selectedIndex then
						item:SetFocus(true)
					end
					item:SetIcon(AssetPath.TextureGUIPath..IGame.ChipExchangeClient:GetGoodsIcon(itemIndex), itemIndex)
					table.insert(self.m_itemScriptCache, itemIndex, item)
				end
			end
		else
			print("can't get activeity object index:"..itemIndex)
		end
	end	
end

-- 重新加载
function ChipListWidget:ReloadData()
	if not self:isLoaded() then
		return
	end
	self.m_nCount = IGame.ChipExchangeClient:GetInfoCount()
	self.Controls.ChipList:SetCellCount( math.ceil(self.m_nCount / CHIPCELL_ITEM_COUNT_IN_LINE ) , true )
end

function ChipListWidget:UpdateData(index)
	local item = self.m_itemScriptCache[index]
	if item ~= nil then
		-- 购买成功刷新当前item 
		UIManager.ChipExchangeWindow:UpdateExchangeGoodsInfo(index)
		UIManager.ChipExchangeWindow:UpdateExchangeExpenseInfo(index)
		item:SetItemCellInfo(index)
	end
end

function ChipListWidget:UpdateSelectedIndex()
	self.m_selectedIndex = 1
end

-- EnhancedListView 一行被“创建”时的回调
function ChipListWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	local item = ChipItemGroupCellClass:new({})
	item:Attach(goCell)
	if 0 == listcell.transform.childCount then
		self:onCreateLimitList(listcell)	
	end
end

-- EnhancedListView 一行强制刷新时的回调
function ChipListWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function ChipListWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

function ChipListWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

function ChipListWidget:Refresh(selectItemIndex,ReloadFlg)
	self.m_selectedIndex = selectItemIndex or self.m_selectedIndex
	self.m_selectItemGoodID = IGame.ChipExchangeClient:GetGoodsIDByIndex(self.m_index)
	if ReloadFlg then
		self:ReloadData()
	end
end




return this