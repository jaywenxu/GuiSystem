--/******************************************************************
---** 文件名:	PlayerSkillUpgradeWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	许文杰
--** 日  期:	2017-08-28
--** 版  本:	1.0
--** 描  述:	玩家背包仓库
--** 应  用:  
--******************************************************************/

--感觉enhancescroller的滑动回弹不好用，自己写算了

--仓库页签界面
local PackageItemCellClass = require( "GuiSystem.WindowList.Package.PackageItemCell" )

local WareWidget = UIControl:new
{
    windowName = "WareWidget" ,
	pageIndex = nil,

}
function WareWidget:Attach(obj)
	UIControl.Attach(self,obj)
	self.callback_OnWareItemCellSelected = function(itemCell , on) self:OnWareItemCellSelected(itemCell , on) end
	self.callback_OnWareItemCellPointClick = function(itemCell, on) self:OnWareItemCellPointClick(itemCell, on) end
end


function WareWidget:InitWare(toggleGroup,warePage)
	self.pageIndex = warePage
	self:CreateCell(toggleGroup)
end

local WARE_LINE_COUNT_IN_WARE = 5   --一个仓库有5行
local WARE_ITEM_COUNT_IN_ROW = 6	-- 仓库-行6个物品格子


--仓库格子生成
function WareWidget:CreateCell(toggleGroup,selectFun,ClickFun)
	local childTrs = nil
	for i =1,WARE_LINE_COUNT_IN_WARE do
		childTrs = self.transform:GetChild(i-1)
		if childTrs ~= nil then 
			local count = childTrs.childCount
			for k = 1 ,WARE_ITEM_COUNT_IN_ROW do 
				if k >count then 
					rkt.GResources.FetchGameObjectAsync( GuiAssetList.PackageItemCell ,
					function ( path , obj , ud )
						if nil == childTrs.gameObject then   -- 判断U3D对象是否已经被销毁
							rkt.GResources.RecycleGameObject(obj)
							return
						end
						if childTrs.childCount >= WARE_ITEM_COUNT_IN_ROW then  -- 已经满了
							rkt.GResources.RecycleGameObject(obj)
							return
						end
						local trs = self.transform:GetChild(ud-1)
						obj.transform:SetParent(trs,false)
						local item = PackageItemCellClass:new({})
						obj.name =tostring((ud-1)*WARE_ITEM_COUNT_IN_ROW+trs.childCount)
						item:Attach(obj)
						item:SetToggleGroup(toggleGroup)
						item:SetItemCellPointerClickCallback(self.callback_OnWareItemCellSelected )
						item:SetItemCellPointerDoubleClickCallback(self.callback_OnWareItemCellPointClick )
						self:RefreshWareCellItems(item,(ud-1)*WARE_ITEM_COUNT_IN_ROW+trs.childCount)
						end , i , AssetLoadPriority.GuiNormal )
				else
						
					local item =childTrs:GetChild(k-1)
					local behav = item.gameObject:GetComponent(typeof(UIWindowBehaviour))
					if nil ~= behav then
						local cellClass = behav.LuaObject	
						self:RefreshWareCellItems(cellClass,(i-1)*WARE_ITEM_COUNT_IN_ROW+k)
					end
				end
				
				
			end
		end
	end
end

--刷新全部
function WareWidget:RefreshWidget()
	for i =1,WARE_LINE_COUNT_IN_WARE do
		childTrs = self.transform:GetChild(i-1)
		if childTrs ~= nil then 
			local item 
			for k=1 ,WARE_ITEM_COUNT_IN_ROW do 
				item =childTrs:GetChild(k-1)
				local behav = item.gameObject:GetComponent(typeof(UIWindowBehaviour))
				if nil ~= behav then
					local cellClass = behav.LuaObject	
					self:RefreshWareCellItems(cellClass,(i-1)*WARE_ITEM_COUNT_IN_ROW+k)
				end
			end
		end
	end

end

------------------------------------------------------------
--- 刷新物品格子内容
function WareWidget:RefreshWareCellItems(item,cellIndex )	
	local tGoodsUID = {}
	local itemType = "ware"
	local curSize = 0
	local maxSize = 0
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE)
	if warePart and warePart:IsLoad() then
		tGoodsUID = warePart:GetAllGoods(self.pageIndex)
		curSize = warePart:GetSize(self.pageIndex)
		maxSize = warePart:GetMaxSize(self.pageIndex)
	end
	local nCurOnItem = item		
	local itemIndex = tonumber(cellIndex) 
	local uidGoods = tGoodsUID[itemIndex] or 0
	item:SetItemType(itemType)
	item:SetItemInfo(uidGoods, itemIndex, curSize, maxSize)
	
	--[[if tostring(uidGoods) == tostring(self.m_selectUid) then
		nCurOnItem = item
		local pentity = IGame.EntityClient:Get(uidGoods)
		if pentity then
			uerror("RefreshWareCellItems: "..pentity:GetNumProp(GOODS_PROP_GOODSID))
		end
	end
	if nCurOnItem then
		nCurOnItem:SetSelect(true)
	end--]]

end


-- 选中仓库物品，意思是从仓库移动至包裹
function WareWidget:OnWareItemCellSelected( itemCell , on)
--[[	if not on then
		return
	end--]]
	
	local uid = itemCell:GetGoodsUID()

	if uid == zero or uid == 0 then
		return
	end
	self.m_selectUid = uid
    local pEquipEntity = IGame.EntityClient:Get(uid)
	local goodsId      = pEquipEntity:GetNumProp(GOODS_PROP_GOODSID)
	local position     = itemCell:GetOriginPosition()
	local MoveType     = "ware"
	local entityClass = pEquipEntity:GetEntityClass()
	if EntityClass:IsEquipment(entityClass) then
		local subInfo = {
			bShowBtn = 1,
			bShowCompare = false,
			bRightBtnType = 4,
		}
		UIManager.EquipTooltipsWindow:Show(true)
        UIManager.EquipTooltipsWindow:SetEntity(pEquipEntity, subInfo)
	else
		local subInfo = {
			bShowBtnType	= 1, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			bBottomBtnType = 4,
		}
		UIManager.GoodsTooltipsWindow:Show(true)
        UIManager.GoodsTooltipsWindow:SetGoodsEntity(pEquipEntity, subInfo )
	end
	    
	
end

function WareWidget:OnWareItemCellPointClick(itemCell, on)
	--if not on then
	--	return
--end
	local uid = itemCell:GetGoodsUID()
	if uid == zero or uid == 0 then
		return
	end 
	self.m_selectUid = uid
	IGame.SkepClient.RequestWareToPacket(uid)
end

return WareWidget