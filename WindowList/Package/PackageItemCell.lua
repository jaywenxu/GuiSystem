------------------------------------------------------------
-- 包裹格子,不要通过 UIManager 访问
-- 复用类
------------------------------------------------------------
local PackageItemCell = UIControl:new
{
    windowName = "PackageItemCell" ,
	onItemCellSelected = nil  ,   --  选中回调
	onItemCellPointClick = nil,  -- 单击回调
	onItemCellPointDoubleClick = nil, --双击回调
	goodsUID = 0, -- 当前格子里的物品UID
	bIsLock = true,
	m_select =false,
	m_wareSkepWidget = nil,
	selectedGoodsUID = {},
	m_itemType = "pack",
	doubleClickTimer = false,
	m_lastClickTime = 0,
	m_pageIndex = 0,
	m_lineIndex = 0,
}

local mName = "【包裹格子】，"
local DoubleClickTime= 300
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
--Select (UnityEngine.UI.Image)
--m_SelFlagIcon : SelFlag (UnityEngine.UI.Image)
--m_LockIcon : Lock (UnityEngine.UI.Image)
--m_Count : Count (UnityEngine.UI.Text)
--m_BindIcon : Bind (UnityEngine.UI.Image)
--m_ItemBG : ItemBG (UnityEngine.UI.Image)
--m_ItemIcon : Item (UnityEngine.UI.Image)
--m_BG : BG (UnityEngine.UI.Image)
--m_PowerIcon : Power (UnityEngine.UI.Image)
------------------------------------------------------------
function PackageItemCell:Attach( obj )
	UIControl.Attach(self,obj)
    self.callback_OnSelectChanged = function( on ) self:OnSelectChanged(on) end
    self.Controls.ItemToggle = self.Controls.m_Main_BG:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callback_OnSelectChanged  ) 
	
	self.callback_OnEquipSelectedChanged = function( on ) self:OnEquipSelectedChanged(on) end
	self.Controls.m_equipChoose.onValueChanged:AddListener(self.callback_OnEquipSelectedChanged)
	self.OnClickBg = function(obj,on) self:OnPointClickItem(obj,on) end
	self:SetItemCellSelectedCallback (self.OnClickBg)
--[[	local listen = self.Controls.m_bg:GetComponent(typeof(UnityEngine.EventSystems.EventTrigger))
	listen.onClick = self.OnClickBg --]]
	--UIFunction.AddEventTriggerListener(self.Controls.m_bg,EventTriggerType.PointerClick,self.OnClickBg)
	self.goodsUID = 0
	self.originPosition = self.transform.localPosition
	self.m_equipDecompose = false
    return self
end

------------------------------------------------------------
function PackageItemCell:OnPointClickItem(obj,on )
	if on == true then 
		if UIManager.PackWindow:IsWareTab() then 
			if self.doubleClickTimer == true  then 
				if nil ~= self.onItemCellPointDoubleClick then 
					self.onItemCellPointDoubleClick(self, on)
					self.doubleClickTimer=false
				end
			else
				self.doubleClickTimer=true
				self.fun=function() self:TimerOnClick()end
				rktTimer.SetTimer(self.fun,DoubleClickTime,1,"")
			end
		else
			self:onPointClick()

		end
		
	end

end

function PackageItemCell:TimerOnClick()
	if self.doubleClickTimer == true then 
		self.doubleClickTimer = false
		self:onPointClick()
	end
	
end

function PackageItemCell:onPointClick() 
	
	if nil ~= self.onItemCellPointClick then 
		self.onItemCellPointClick(self, true)
	end
	
end


function PackageItemCell:SetItemCellPointerClickCallback(cb)
	self.onItemCellPointClick = cb
end

function PackageItemCell:SetItemCellPointerDoubleClickCallback(cb)
	self.onItemCellPointDoubleClick = cb
end
------------------------------------------------------------
function PackageItemCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end
------------------------------------------------------------
function PackageItemCell:OnSelectChanged( on )
	self.Controls.m_Select.gameObject:SetActive(on)
	self.m_select = on
	
	if nil ~= self.onItemCellSelected then
		self.onItemCellSelected( self , on )
	end
end

function PackageItemCell:OnEquipSelectedChanged(on)
	-- 保存uid
	if on then
		self.Controls.m_Checkmark.gameObject:SetActive(true)
	else
		self.Controls.m_Checkmark.gameObject:SetActive(false)
	end
	UIManager.PackWindow:SetEquipDecomposeUID(self.goodsUID, on)
end

function PackageItemCell:SetEquipChooseStatus(on,nSecQuality)
	if not self.m_equipDecompose then 
		return
	end
	local entity = IGame.EntityClient:Get(self.goodsUID)
	--self.Controls.m_equipChoose.isOn = false
	if entity then 
		local nQuality  = entity:GetNumProp(EQUIP_PROP_QUALITY) 
		if on then 
			if nQuality == nSecQuality then 
				self.Controls.m_equipChoose.gameObject:SetActive(true) 
	            self.Controls.m_equipChoose.isOn = true
			end
		else 
			if nQuality == nSecQuality then 
				self.Controls.m_equipChoose.gameObject:SetActive(true) 
	            self.Controls.m_equipChoose.isOn = false
			end
		end

	else 
		self.Controls.m_equipChoose.gameObject:SetActive(false) 
		self.Controls.m_equipChoose.isOn = false
	end

end


------------------------------------------------------------
function PackageItemCell:SetItemInfo(uidGoods, itemIndex, curSize, maxSize)
	self.goodsUID = uidGoods
	self.Controls.m_equipChoose.isOn = false
	local entity = IGame.EntityClient:Get(uidGoods)
	if itemIndex <= curSize then 
		self.Controls.m_Main_BG.raycastTarget = ( nil ~= entity )
	else 
		self.Controls.m_Main_BG.raycastTarget = true
	end
	
	
	if entity and EntityClass:IsGoods(entity:GetEntityClass()) then
		if EntityClass:IsLeechdom(entity:GetEntityClass()) then
			local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
			if not schemeInfo then
				print(mName.."找不到物品配置，物品ID=", entity:GetNumProp(GOODS_PROP_GOODSID))
				return
			end

			local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
			UIFunction.SetImageSprite( self.Controls.m_ItemIcon , imagePath )
			
			local imageBgPath = AssetPath.TextureGUIPath..schemeInfo.lIconID2
			UIFunction.SetImageSprite( self.Controls.m_ItemBG , imageBgPath )
			
			self.Controls.m_ItemIcon.gameObject:SetActive(true)
			self.Controls.m_ItemBG.gameObject:SetActive(true)
			local totalNum = entity:GetNumProp(GOODS_PROP_QTY)
			local noBindNum = entity:GetNumProp(GOODS_PROP_NO_BIND_QTY) 
			-- 物品没有分解功能
			self.Controls.m_equipChoose.gameObject:SetActive(false)
			
			if totalNum <= 1 then 
				self.Controls.m_Count.gameObject:SetActive(false)
			else
				if totalNum > 999 then
					self.Controls.m_Count.text = "999+"
				else
					self.Controls.m_Count.text = totalNum
				end
				
				self.Controls.m_Count.gameObject:SetActive(true)
			end 
			if lua_NumberAndTest(entity:GetNumProp(GOODS_PROP_BIND) , tGoods_BindFlag_Hold) then
				self.Controls.m_BindIcon.gameObject:SetActive(true)
			else
				self.Controls.m_BindIcon.gameObject:SetActive(false)
			end
		else
			local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
			if not schemeInfo then
				print(mName.."找不到物品配置，物品ID=", entity:GetNumProp(GOODS_PROP_GOODSID))
				return
			end
			local nGoodsID = entity:GetNumProp(GOODS_PROP_GOODSID)
			local imagePath = AssetPath.TextureGUIPath .. schemeInfo.IconIDNormal
			local nQuality  = entity:GetNumProp(EQUIP_PROP_QUALITY)
			local nAdditionalPropNum = entity:GetAdditionalPropNum()
			if schemeInfo.GoodsSubClass == EQUIPMENT_SUBCLASS_BATTLEBOOK then
				local battleBookInfo = entity:GetBattleBookProp()
				if battleBookInfo then
					nQuality = battleBookInfo.quality or 1
				end
				
				nAdditionalPropNum = 0
				local battleBookScheme = IGame.rktScheme:GetSchemeInfo(BATTLE_BOOK_UPGRADE_CSV, nGoodsID, battleBookInfo.level)
				if battleBookScheme then
					for i,v in pairs(battleBookScheme.Property) do
						nAdditionalPropNum = nAdditionalPropNum + 1
					end
				end
			end
			
	        local imageBgPath =  self:GetIconBgPath(nQuality, nAdditionalPropNum)
	
			UIFunction.SetImageSprite( self.Controls.m_ItemBG , imageBgPath )
			UIFunction.SetImageSprite( self.Controls.m_ItemIcon , imagePath )
			self.Controls.m_ItemIcon.gameObject:SetActive(true)
			self.Controls.m_ItemBG.gameObject:SetActive(true)
			local totalNum = entity:GetNumProp(GOODS_PROP_QTY)
			local noBindNum = entity:GetNumProp(GOODS_PROP_NO_BIND_QTY)
			
			-- 是不是一键分解功能
			local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY) 
			if self.m_equipDecompose then 
				if nQuality == 1 then
				    self.Controls.m_equipChoose.isOn = true
				end
				self.Controls.m_equipChoose.gameObject:SetActive(true) 
			else 
				self.Controls.m_equipChoose.gameObject:SetActive(false)
			end
			
			self.Controls.m_Count.text = totalNum
			if totalNum <= 1 then 
				self.Controls.m_Count.gameObject:SetActive(false)
			else 
				self.Controls.m_Count.gameObject:SetActive(true)
			end 
			if lua_NumberAndTest(entity:GetNumProp(GOODS_PROP_BIND) , tGoods_BindFlag_Hold) then
				self.Controls.m_BindIcon.gameObject:SetActive(true)
			else
				self.Controls.m_BindIcon.gameObject:SetActive(false)
			end
		end
		
	else
		if self.m_select == true then 
			self.Controls.m_Select.gameObject:SetActive(false)
		end 
		self.Controls.m_ItemIcon.sprite = nil
		self.Controls.m_ItemIcon.gameObject:SetActive(false)
		self.Controls.m_ItemBG.gameObject:SetActive(false)
		self.Controls.m_equipChoose.gameObject:SetActive(false)
		self.Controls.m_Count.text = ""
		self.Controls.m_Count.gameObject:SetActive(false)
		self.Controls.m_BindIcon.gameObject:SetActive(false)
		if itemIndex <= curSize then
			self.Controls.m_BG.gameObject:SetActive(false)
		else
			if self.m_equipDecompose then 
				-- 分解时不显示锁
				self.Controls.m_BG.gameObject:SetActive(false)
			else 
				if self.m_itemType == "pack" then 
					self.Controls.m_BG.gameObject:SetActive(true) -- 未开孔的要显示锁图标
				else 
					self.Controls.m_BG.gameObject:SetActive(false) -- 仓库界面不显示锁显示锁图标
				end
				
			end
			
		end
	end
	if self.m_equipDecompose then
		self.bIsLock = false
	else 
		if itemIndex <= curSize then
			self.bIsLock = false
		else
			self.bIsLock = true
		end
	end

end


function PackageItemCell:SetItemType(itemType) 
	self.m_itemType =  itemType
end

function PackageItemCell:SetSelect(on)
	self.Controls.m_Select.gameObject:SetActive(on)
end

function PackageItemCell:GetIconBgPath(nQuality, nAdditionalPropNum)
	if  nQuality == 2 then
		if nAdditionalPropNum <= 4 then 
			nAdditionalPropNum = 4
		else 
			nAdditionalPropNum = 5
		end
	elseif nQuality == 3 then 
		if nAdditionalPropNum <= 5 then 
			nAdditionalPropNum = 5
		else 
			nAdditionalPropNum = 6
		end
	elseif nQuality == 4 then
		if nAdditionalPropNum <= 6 then 
			nAdditionalPropNum = 6
		else 
			nAdditionalPropNum = 7
		end	 
	end
	
	if nQuality <= 1 then 
		imageBgPath = AssetPath_EquipColor[1]
	else 
		imageBgPath = AssetPath_EquipColor[nQuality.."_"..nAdditionalPropNum]
	end
	
	return imageBgPath
end


------------------------------------------------------------
function PackageItemCell:SetItemCellSelectedCallback( cb )
	self.onItemCellSelected = cb
end
------------------------------------------------------------
function PackageItemCell:OnRecycle()
	self.onItemCellSelected = nil
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChanged )
	UIManager.PackWindow:SetEquipDecomposeUID(self.goodsUID, false)
	self.goodsUID = 0
end
------------------------------------------------------------
function PackageItemCell:OnDestroy()
	self.onItemCellSelected = nil
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChanged )
	UIManager.PackWindow:SetEquipDecomposeUID(self.goodsUID, false)
	self.goodsUID = 0
	
	UIControl.OnDestroy(self)
end
------------------------------------------------------------
function PackageItemCell:GetGoodsUID()
	return self.goodsUID
end
------------------------------------------------------------
function PackageItemCell:ClearGoodsInfo()
	self.Controls.m_ItemIcon.sprite = nil
	self.Controls.m_ItemIcon.gameObject:SetActive(false)
	self.Controls.m_ItemBG.gameObject:SetActive(false)
	self.Controls.m_Count.text = ""
	self.Controls.m_Count.gameObject:SetActive(false)
	self.Controls.m_BindIcon.gameObject:SetActive(false)
end
------------------------------------------------------------
function PackageItemCell:IsLock()
	return self.bIsLock
end

function PackageItemCell:SetWareSkepWidget(WareSkepWidget)
	self.m_wareSkepWidget = WareSkepWidget
end

function PackageItemCell:SetPuttedOn(Flg)
	self.Controls.m_PuttedOn.gameObject:SetActive(Flg)
end

function PackageItemCell:GetOriginPosition()
	return self.originPosition
end

function PackageItemCell:SetEquipDecompose(bEquipDecompose)
	self.m_equipDecompose = bEquipDecompose
end

function PackageItemCell:SetCoolImg(leftAmount)
	self.Controls.m_CoolImg.fillAmount = leftAmount
	--self.Controls.m_CoolImg:DOFillAmount( 0, 10000)
end

------------------------------------------------------------
return PackageItemCell




