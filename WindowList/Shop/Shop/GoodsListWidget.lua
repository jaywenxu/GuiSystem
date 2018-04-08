
local ItemCellClass = require( "GuiSystem.WindowList.Shop.Shop.GoodsItemCell" )
local ShopWidgetClass = require("GuiSystem.WindowList.Shop.Shop.ShopWidget")

local CELL_ITEM_COUNT_IN_LINE = 2 --一行俩列

local GoodsListWidget = UIControl:new
{
	windowName = "GoodsListWidget",
	m_nCount = 0,		-- item数量
	m_CurrTypeIndex = 0,		--当前商品类型分页索引
	m_CurIndex = 1,				--当前选中商品索引
	m_itemScriptCache = {},	--缓存的item脚本table， key：index，value:GoodsItemCell脚本	

	m_JumpToGoodsIndex = -1,
}


function GoodsListWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.Controls.ItemToggleGroup =  self.Controls.m_ScrollRect:GetComponent(typeof(ToggleGroup))
	self.Scroll = self.Controls.m_ScrollRect:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	GoodsListWidget.m_CurIndex = 1
	self.OnItemCellSelectedCB = function(itemCell ,on) self:OnItemCellSelected(itemCell ,on) end
end

--创建滑动列表
function GoodsListWidget:CreateGoodsList(nType)
	local nNum = IGame.PlazaClient:GetGoodsListCountByType(nType)
	self.m_CurrTypeIndex = nType
	local tableNum = table.getn(self.m_itemScriptCache) 
	if tableNum > 0 then
		--销毁之前的
		for i, data in pairs(self.m_itemScriptCache) do
			data:Destroy()
		end
	end
	self.m_itemScriptCache = {}
	local loadNum = 0
	
	
	for	i = 1,nNum do 
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.GoodsItemCell ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_Grid)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = ItemCellClass:new({})
			item:Attach(obj)
			item:SetToggleGroup(self.Controls.ItemToggleGroup)
			item:SetSelectCallback(self.OnItemCellSelectedCB)
			
			item:SetItemCellInfo(self.m_CurrTypeIndex,i)
			item:SetIcon(self.m_CurrTypeIndex, i)
			
			item:SetFocus(false)
			if i == 1 then
				item:SetFocus(true)
				self.m_CurIndex	= 1
			end
			table.insert(self.m_itemScriptCache,i,item)	
			loadNum = loadNum + 1
			if loadNum == nNum then
				if self.m_JumpToGoodsIndex ~= -1 then
					self.m_itemScriptCache[self.m_JumpToGoodsIndex]:SetFocus(true)
					self.NeedJump = true
					self.JumpType = nType
					self.JumpIndex = self.m_JumpToGoodsIndex
					rktTimer.SetTimer(function()
						local pos =	IGame.PlazaClient:GetPosByTypeAndID(self.JumpType,self.JumpIndex)
						self.Scroll.verticalNormalizedPosition = pos
						self.NeedJump = false
						end,50, 1,"")--延迟跳转
					
					self.m_JumpToGoodsIndex = -1
				end
			end
			
		end , i , AssetLoadPriority.GuiNormal )
	end
end



-- item 被选中
function GoodsListWidget:OnItemCellSelected(itemCell ,on)	
	if self.NeedJump then
		local pos =	IGame.PlazaClient:GetPosByTypeAndID(self.JumpType,self.JumpIndex)
		self.Scroll.verticalNormalizedPosition = pos
		self.NeedJump = false
	end
	local index = itemCell:GetGoodsIndex()
	self.m_CurIndex = index
	if nil ~= index then 
		ShopWidgetClass:UpdateExchangeGoodsInfo(index)                   
		ShopWidgetClass:UpdateExchangeExpenseInfo(index)
	end

	rktEventEngine.FireEvent(EVENT_SHOP_CLICKGOODSITEM,0,0)
end


--购买成功后刷新界面
function GoodsListWidget:RefreshBuySuccess(plazaID)
	local cellitem = nil
	for i,data in pairs(self.m_itemScriptCache) do
		if data.m_plazaID == plazaID then
			cellitem = data
		end
	end
	
	if nil ~= cellitem then
		cellitem:SetItemCellInfo(cellitem.m_type,cellitem.m_index)
	end
end

function GoodsListWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

return GoodsListWidget