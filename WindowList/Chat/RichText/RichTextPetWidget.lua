--------RichTextPetWidget.lua-----------------------------
-- ChatWindow 的子窗口,不要通过 UIManager 访问
-- @author	Jack Miao
-- @desc	灵兽聊天栏富文本框
-- @date	2017.11.6
------------------------------------------------------------

local RichTextPetCellClass = require( "GuiSystem.WindowList.Chat.RichText.ChatPetCell" )

local RichTextPetWidget = UIControl:new
{
	windowName = "RichTextPetWidget",
	m_PetListInfo = {},
}

local this = RichTextPetWidget   		-- 方便书写
local CELL_ITEM_COUNT_IN_LINE = 3       -- 一列二个物品格子

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function RichTextPetWidget:Attach( obj )
	
	UIControl.Attach(self,obj)
	
	-- 事件
	self.Controls.listViewRichTextGoods = self.Controls.RichTextPetCellList:GetComponent(typeof(EnhancedListView))
	
	self.callback_OnGetCellView = function(goCell) self:OnGetCellView(goCell) end	
	self.Controls.listViewRichTextGoods.onGetCellView:AddListener(self.callback_OnGetCellView)
	
	self.callback_OnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end	
	self.Controls.listViewRichTextGoods.onCellViewVisiable:AddListener(self.callback_OnCellViewVisiable)
	
	self.Controls.scrollerRichTextGoods = self.Controls.RichTextPetCellList:GetComponent(typeof(EnhancedScroller))
	
	self.Controls.PetToggleGroup = self.Controls.RichTextPetCellList:GetComponent(typeof(ToggleGroup))
	
	self:RefreshWidget()
	return self
end

------------------------------------------------------------
function RichTextPetWidget:OnDestroy()
	UIControl.OnDestroy(self)
end
	
------------------------------------------------------------
function RichTextPetWidget.OnItemCellSelected( itemCell , on)
	
	if not on then return end 

	local uid = itemCell:GetPetUID()
	local entity = IGame.EntityClient:Get(uid)	
	if entity == nil or not EntityClass:IsPet(entity:GetEntityClass()) then return end 
	
	-- 显示tips
	local petInfoStr = CompositeInfoByUID(uid)
	local InPutString = "<herf><color=green>["..entity:GetName().."]</color><fun>"
	InPutString = InPutString.."ShowEntityTips("..petInfoStr..")</fun></herf>"
	UIManager.RichTextWindow:InsertRichText(entity:GetName(),InPutString,false)
end

------------------------------------------------------------
-- 创建Cell
function RichTextPetWidget:CreateCellItems( listcell )
	
	for i = 1 , CELL_ITEM_COUNT_IN_LINE , 1 do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.RichTextPetCell ,
		function ( path , obj , ud )
			if nil == listcell.gameObject then   -- 判断U3D对象是否已经被销毁
				rkt.GResources.RecycleGameObject(obj)
				return
			end
			if listcell.transform.childCount >= CELL_ITEM_COUNT_IN_LINE then  -- 已经满了
				rkt.GResources.RecycleGameObject(obj)
				return
			end
			obj.transform:SetParent(listcell.transform,false)
			local item = RichTextPetCellClass:new({})
			item:Attach(obj)
			item:SetToggleGroup( this.Controls.PetToggleGroup )
			item:SetItemCellSelectedCallback( RichTextPetWidget.OnItemCellSelected )
			if listcell.transform.childCount == CELL_ITEM_COUNT_IN_LINE then
				self:RefreshCellItems(listcell)
			end	
		end , i , AssetLoadPriority.GuiNormal )
	end
end

------------------------------------------------------------
--- 刷新物品格子内容
function RichTextPetWidget:RefreshCellItems( listcell )
	
	local listcell_trans = listcell.transform
	if listcell_trans.childCount ~= CELL_ITEM_COUNT_IN_LINE then
		return
	end
	
	for i = 1 , CELL_ITEM_COUNT_IN_LINE , 1 do
		local itemCell = listcell_trans:GetChild( i - 1 )
		local CellIndex = listcell.dataIndex
		local itemIndex = listcell.dataIndex * CELL_ITEM_COUNT_IN_LINE + i
		local pet_info = self.m_PetListInfo[itemIndex] or {}
		if nil ~= itemCell.gameObject and nil ~= itemCell:GetComponent(typeof(UIWindowBehaviour)) then
			local item = itemCell:GetComponent(typeof(UIWindowBehaviour)).LuaObject
			if nil ~= item and item.windowName == "ChatPetCell" then
				if pet_info.uid == nil or IGame.EntityClient:Get(pet_info.uid) == nil then
					item:Hide()
				else
					item:Show()
					item:SetPetInfo(pet_info.uid)
				end
			end
		end
	end
end
------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function RichTextPetWidget:OnCellViewVisiable( goCell )
	
	if goCell == nil then return end 
	
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end
------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function RichTextPetWidget:OnGetCellView( goCell )

	if goCell == nil then return end 
	
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView )
	
	if 0 == listcell.transform.childCount then
		self:CreateCellItems(listcell)
	end
end
------------------------------------------------------------
-- EnhancedListView 一行强制刷新时的回调
function RichTextPetWidget:OnRefreshCellView( goCell )
	
	if goCell == nil then return end 	
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end
------------------------------------------------------------
function RichTextPetWidget:RefreshWidget()
	
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then return end
	
	local petTable = IGame.PetClient:GetCurPetTable()
	if petTable == nil then return end 
	
	self.m_PetListInfo = petTable
	
	local CountTmp = math.ceil(table.getn(self.m_PetListInfo)/CELL_ITEM_COUNT_IN_LINE)
	self.Controls.listViewRichTextGoods:SetCellCount( CountTmp , true )
end

function RichTextPetWidget:ReloadData()
	self.Controls.scrollerRichTextGoods:ReloadData()
end

return this