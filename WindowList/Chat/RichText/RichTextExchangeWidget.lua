------------------------------------------------------------
-- ChatWindow 的子窗口,不要通过 UIManager 访问
-- 频道切换Toggle窗口
------------------------------------------------------------

--local RichTextGoodsCellClass = require( "GuiSystem.WindowList.Chat.RichText.RichTextGoodsCell" )

local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )

local RichTextExchangeWidget = UIControl:new
{
	windowName = "RichTextExchangeWidget",
	m_GoodsInfo = {},
}

local this = RichTextExchangeWidget   -- 方便书写
local CELL_ITEM_COUNT_IN_LINE = 3       -- 一列二个物品格子
local zero = int64.new("0")
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function RichTextExchangeWidget:Attach( obj )
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
function RichTextExchangeWidget:OnDestroy()
	UIControl.OnDestroy(self)
end
	
------------------------------------------------------------
function RichTextExchangeWidget.OnItemCellSelected( itemCell , on)
	local StallData = itemCell.m_UserData

	-- 装备
	if StallData.btClass == GOODS_CLASS_EQUIPMENT  then
		local nEquipUID = IGame.ExchangeClient:GetListStallTipDataUID(StallData.dwSeq)
		-- 装备tip数据已经存在
		if nEquipUID ~= nil then
			RichTextExchangeWidget.OnEntityBack(nEquipUID)
			return
		end
		IGame.ExchangeClient:OnRequestExchangeGoodsTips(StallData.dwSeq,StallData.nGoods,StallData.btState,RichTextExchangeWidget.OnEntityBack)
		return
	end
	
	-- 道具
	if StallData.btClass == GOODS_CLASS_LEECHDOM  then
		print( "<color=blue> Leechdom id ："..tostring(StallData.nGoods).."</color>")
		local LeechdomInfoStr = CompositeLeechdomInfoByID(StallData.nGoods)
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, StallData.nGoods)
		if not schemeInfo then
			uerror(mName.."找不到物品配置，物品ID="..tostringEx(StallData.nGoods))
			return
		end
		local Color = DColorDef.getNameColor(0,schemeInfo.lBaseLevel)
		local InPutString = "<herf><color=#"..Color..">["..schemeInfo.szName.."]</color><fun>"
		InPutString = InPutString.."ShowEntityTips("..LeechdomInfoStr..")</fun></herf>"
		-- InPutString = "<herf><color=#FF0000>倚天屠龙刀</color><fun>ShowEquipTips('{[1]=1}')</fun></herf>"
		-- <herf><color=#FF0000>桃木灵</color><fun>ShowEntityTip
		UIManager.ChatWindow:InsertRichText(schemeInfo.szName,InPutString,false)
		return
	end
end
	
------------------------------------------------------------
function RichTextExchangeWidget.OnEntityBack(UID)
	local entity = IGame.EntityClient:GetDeceitEntity(UID)
	print( "<color=blue> 点击了装备 uid ："..tostring(uid).."</color>")
	local EquipInfoStr = CompositeInfoByUID(UID) 
	print( "<color=green>装备的属性 uid ："..EquipInfoStr.."</color>")
	local Quality = entity:GetNumProp(EQUIP_PROP_QUALITY)
	local AdditionalPropNum = entity:GetShuffleAdditionalPropNum()
	local Color = DColorDef.getNameColor(1,Quality,AdditionalPropNum)
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	if not schemeInfo then
		uerror(mName.."找不到物品配置，物品ID="..tostringEx(entity:GetNumProp(GOODS_PROP_GOODSID)))
		return
	end
	
	local InPutString = "<herf><color="..Color.."><"..schemeInfo.szName.."></color><fun>"
	InPutString = InPutString.."ShowEntityTips("..EquipInfoStr..")</fun></herf>"
	--InPutString = "<herf><color=#FF0000>倚天屠龙刀</color><fun>ShowEntityTips('{[1]=1}')</fun></herf>"
	UIManager.ChatWindow:InsertRichText(schemeInfo.szName,InPutString,false)
end
------------------------------------------------------------
function RichTextExchangeWidget.OnItemCellSelectedGood( itemCell , on)
	if not on then
		return
	end
	local uid = itemCell:GetGoodsUID()
	local entity = IGame.EntityClient:Get(uid)

	-- 显示tips
	if entity then
		local entityClass = entity:GetEntityClass()
		if EntityClass:IsEquipment(entityClass) then
			local EquipInfoStr = CompositeInfoByUID(uid)
			local Quality = entity:GetNumProp(EQUIP_PROP_QUALITY)
			local AdditionalPropNum = entity:GetShuffleAdditionalPropNum()
			local Color = DColorDef.getNameColor(1,Quality,AdditionalPropNum)
			local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
			if not schemeInfo then
				uerror(mName.."找不到物品配置，物品ID="..tostringEx(entity:GetNumProp(GOODS_PROP_GOODSID)))
				return
			end
			
			local InPutString = "<herf><color="..Color.."><"..schemeInfo.szName.."></color><fun>"
			InPutString = InPutString.."ShowEntityTips("..EquipInfoStr..")</fun></herf>"
			UIManager.RichTextWindow:InsertRichText(schemeInfo.szName,InPutString,false)
		elseif EntityClass:IsLeechdom(entityClass) then
			local LeechdomInfoStr = CompositeInfoByUID(uid)
			local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
			if not schemeInfo then
				uerror(mName.."找不到物品配置，物品ID="..tostringEx(entity:GetNumProp(GOODS_PROP_GOODSID)))
				return
			end
			local Color = DColorDef.getNameColor(0, schemeInfo.lBaseLevel)
			local InPutString = "<herf><color=#"..Color.."><"..schemeInfo.szName.."></color><fun>"
			InPutString = InPutString.."ShowEntityTips("..LeechdomInfoStr..")</fun></herf>"
			UIManager.RichTextWindow:InsertRichText(schemeInfo.szName,InPutString,false)
		end
		return
	end
end
------------------------------------------------------------
-- 创建Cell
function RichTextExchangeWidget:CreateCellItems( listcell )
	for i = 1 , CELL_ITEM_COUNT_IN_LINE , 1 do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.CommonGoodCell ,
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
			local item = CommonGoodCellClass:new({})
			item:Attach(obj)
			item:SetToggleGroup( this.Controls.GoodsToggleGroup )
			item:SetItemCellSelectedCallback( RichTextExchangeWidget.OnItemCellSelected )
			if listcell.transform.childCount == CELL_ITEM_COUNT_IN_LINE then
				self:RefreshCellItems(listcell)
			end	
		end , i , AssetLoadPriority.GuiNormal )
	end
end

------------------------------------------------------------
--- 刷新物品格子内容
function RichTextExchangeWidget:RefreshCellItems( listcell )
	local listcell_trans = listcell.transform
	if listcell_trans.childCount ~= CELL_ITEM_COUNT_IN_LINE then
		return
	end
	
	for i = 1 , CELL_ITEM_COUNT_IN_LINE , 1 do
		local itemCell = listcell_trans:GetChild( i - 1 )
		local CellIndex = listcell.dataIndex
		local itemIndex = listcell.dataIndex * CELL_ITEM_COUNT_IN_LINE + i
		local GoodsInfo = self.m_GoodsInfo[itemIndex] or {}
		local EquipType = false
		if nil ~= itemCell.gameObject then
			local behav = itemCell:GetComponent(typeof(UIWindowBehaviour))
			if nil ~= behav then
				local item = behav.LuaObject
				if nil ~= item and item.windowName == "CommonGoodCell" then
					if not GoodsInfo then
						item:Hide()
					else
						item:Show()
						if GoodsInfo.btClass == GOODS_CLASS_EQUIPMENT then
							item:SetEquipItemInfo(GoodsInfo.nGoods,GoodsInfo.btColor,GoodsInfo.btProNum)
						else
							item:SetLeechdomItemInfo(GoodsInfo.nGoods)
						end
						
						item:SetUserData(GoodsInfo)
						item:SetPuttedOn(EquipType)
					end
				end
			end
		end
	end
end
------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function RichTextExchangeWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end
------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function RichTextExchangeWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView )
	if 0 == listcell.transform.childCount then
		self:CreateCellItems(listcell)
	end
end
------------------------------------------------------------
-- EnhancedListView 一行强制刷新时的回调
function RichTextExchangeWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end
------------------------------------------------------------
function RichTextExchangeWidget:RefrashWidget()
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then
		return false
	end
	local pPacketPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not pPacketPart then
		return
	end
	local pEquipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not pEquipPart then
		return
	end
	local ExchangeGoodsList = IGame.ExchangeClient:GetAllStallData()
	print("装备栏物品uid"..tostringEx(ExchangeGoodsList))
	self.m_GoodsInfo = {}
	for key,StallData in pairs(ExchangeGoodsList) do
		if StallData.btState == 2 or StallData.btState == 1 then
			table.insert(self.m_GoodsInfo,StallData)
		end
	end

	print("装备栏物品 self.m_GoodsInfo"..tostringEx(self.m_GoodsInfo))
	local CountTmp = math.floor(table.getn(self.m_GoodsInfo)/CELL_ITEM_COUNT_IN_LINE)
	print(" 摆摊展示 CountTmp "..table.getn(self.m_GoodsInfo)..","..CountTmp)
	if math.fmod(table.getn(self.m_GoodsInfo),CELL_ITEM_COUNT_IN_LINE) > 0 then
		CountTmp = CountTmp + 1
	end
	-- 设置最大行数
	self.Controls.listViewRichTextGoods:SetCellCount( CountTmp , true )
end

function RichTextExchangeWidget:ReloadData()
	self.Controls.scrollerRichTextGoods:ReloadData()
end
return this