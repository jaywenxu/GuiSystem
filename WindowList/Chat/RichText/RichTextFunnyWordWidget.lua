------------------------------------------------------------
-- ChatWindow 的子窗口,不要通过 UIManager 访问
-- 频道切换Toggle窗口
------------------------------------------------------------

--local RichTextGoodsCellClass = require( "GuiSystem.WindowList.Chat.RichText.RichTextGoodsCell" )

local RichTextFunnyWordCellClass = require( "GuiSystem.WindowList.Chat.RichText.RichTextFunnyWordCell" )

local RichTextFunnyWordWidget = UIControl:new
{
	windowName = "RichTextFunnyWordWidget",
	m_GoodsInfo = {},
	m_TargetName = "",
}

local this = RichTextFunnyWordWidget   -- 方便书写
local CELL_ITEM_COUNT_IN_LINE = 3       -- 一列二个物品格子
local zero = int64.new("0")
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function RichTextFunnyWordWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	-- 事件
	self.Controls.listViewRichTextGoods = self.Controls.RichTextGoodsCellList:GetComponent(typeof(EnhancedListView))
	self.callback_OnGetCellView = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.listViewRichTextGoods.onGetCellView:AddListener(self.callback_OnGetCellView)
	self.callback_OnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.listViewRichTextGoods.onCellViewVisiable:AddListener(self.callback_OnCellViewVisiable)
	self.Controls.scrollerRichTextGoods = self.Controls.RichTextGoodsCellList:GetComponent(typeof(EnhancedScroller))
	self.Controls.GoodsToggleGroup = self.Controls.RichTextGoodsCellList:GetComponent(typeof(ToggleGroup))
	--self.Controls.scrollerRichTextGoods:SetCellCount( 0 , true )
	self:RefrashWidget()
	return self
end

------------------------------------------------------------
function RichTextFunnyWordWidget:OnDestroy()
	UIControl.OnDestroy(self)
end
	
------------------------------------------------------------
-- 创建Cell
function RichTextFunnyWordWidget:CreateCellItems( listcell )
	for i = 1 , CELL_ITEM_COUNT_IN_LINE , 1 do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.RichTextFunnyWordCell ,
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
			local item = RichTextFunnyWordCellClass:new({})
			item:Attach(obj)
			if listcell.transform.childCount == CELL_ITEM_COUNT_IN_LINE then
				self:RefreshCellItems(listcell)
			end	
		end , i , AssetLoadPriority.GuiNormal )
	end
end

------------------------------------------------------------
--- 刷新物品格子内容
function RichTextFunnyWordWidget:RefreshCellItems( listcell )
	local listcell_trans = listcell.transform
	if listcell_trans.childCount ~= CELL_ITEM_COUNT_IN_LINE then
		return
	end
	
	for i = 1 , CELL_ITEM_COUNT_IN_LINE , 1 do
		local itemCell = listcell_trans:GetChild( i - 1 )
		local CellIndex = listcell.dataIndex
		local itemIndex = listcell.dataIndex * CELL_ITEM_COUNT_IN_LINE + i
		local FunnyWordInfo = Chat_Funny_Word[itemIndex] or {}
		if nil ~= itemCell.gameObject then
			local behav = itemCell:GetComponent(typeof(UIWindowBehaviour))
			if nil ~= behav then
				local item = behav.LuaObject
				if nil ~= item and item.windowName == "RichTextFunnyWordCell" then
					if not FunnyWordInfo.TitleName then
						item:Hide()
					else
						item:Show()
						item:SetIndex(itemIndex)
					end
				end
			end
		end
	end
end
------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function RichTextFunnyWordWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end
------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function RichTextFunnyWordWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView )
	if 0 == listcell.transform.childCount then
		self:CreateCellItems(listcell)
	end
end
------------------------------------------------------------
-- EnhancedListView 一行强制刷新时的回调
function RichTextFunnyWordWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end
------------------------------------------------------------
function RichTextFunnyWordWidget:RefrashWidget()
	
	local CountTmp = math.ceil(table.getn(Chat_Funny_Word)/CELL_ITEM_COUNT_IN_LINE)
	print("CountTmp "..table.getn(Chat_Funny_Word)..","..CountTmp)
	if math.fmod(table.getn(self.m_GoodsInfo),CELL_ITEM_COUNT_IN_LINE) > 0 then
		CountTmp = CountTmp + 1
	end
	-- 设置最大行数
	self.Controls.listViewRichTextGoods:SetCellCount( CountTmp , true )
end

function RichTextFunnyWordWidget:ReloadData()
	self.Controls.scrollerRichTextGoods:ReloadData()
end

function RichTextFunnyWordWidget:SetTargetName(TargetName)
	self.m_TargetName = TargetName
end

function RichTextFunnyWordWidget:SetFunnyWord(Index)
	if not Index or not Chat_Funny_Word or not Chat_Funny_Word[Index] then
		return
	end
	if self.m_TargetName == "" then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "没有目标角色")
		return
	end
	local szFunnyText = Chat_Funny_Word[Index].FunnyText
	local szMyName = GetHero():GetName()
	local txt = ""
	txt = string.gsub(szFunnyText,Chat_Funny_Word_Target,self.m_TargetName)
	txt = string.gsub(txt,Chat_Funny_Word_Self,szMyName)
	UIManager.RichTextWindow:SetInputText(txt)
	self.m_TargetName = ""
end

return this