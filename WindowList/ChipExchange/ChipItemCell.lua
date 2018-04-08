--------------------------------------------------------------------

local ChipItemCell = UIControl:new
{
	windowName 	= "ChipItemCell",
	m_index		= nil,				-- 物品兑换ID

	m_selected_calback = nil ,		-- 选中时回调
	
	m_nType 	= nil,				-- 货币类型
	m_nCount	= nil, 				-- 需要消耗的货币数量

	m_DayOrWeek		= 1,				-- 1 物品控制天   2 物品控制周
}

local this = ChipItemCell

function ChipItemCell:Init()

end

function ChipItemCell:Attach(obj)
	UIControl.Attach(self,obj)	
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))	
	self.Controls.ItemToggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable)
	self:CallbackInit()
	self:SubscribeEvent()
	self:SetFocus(false)
	return self
end

-- 销毁
function ChipItemCell:OnDestroy()
	self:UnSubscribeEvent()
	UIControl.OnDestroy(self)
end

-- 回收
function ChipItemCell:OnRecycle()
	self.Controls.ItemToggle.group  = nil
	self.Controls.ItemToggle.isOn = false

	self:UnSubscribeEvent()
	self:ClearInfo()
end

-- 清除换
function ChipItemCell:ClearInfo()
	self.m_index		= nil
	self.m_selected_calback = nil
	self.m_nType 	= nil
	self.m_nCount	= nil
	self.m_DayOrWeek = 0
end

-------------------------------------------------------------------
-- 设置选中时回调函数	
-- @param func_cb : 回调函数
-------------------------------------------------------------------
function ChipItemCell:SetSelectCallback(func_cb)
	self.m_selected_calback = func_cb
end	


-------------------------------------------------------------------
-- 设置组	
-- @param toggleGroup : 要设置的item(需要有toggle属性)
-------------------------------------------------------------------
function ChipItemCell:SetToggleGroup(toggleGroup)
	
	self.Controls.ItemToggle.group = toggleGroup
end

-- 选中
function ChipItemCell:OnSelectChanged(on)
	if not on then
		return
	end
	if nil ~= self.m_selected_calback then 
		self.m_selected_calback(self, on)
	end
end

-------------------------------------------------------------------
-- 设置当前item的属性	
-- @param index : 要获取物品的索引
-------------------------------------------------------------------
function ChipItemCell:SetItemCellInfo(index)
	self.m_index = index
	if not self:isLoaded() then
		return
	end
	local info = IGame.ChipExchangeClient:GetInfoByIndex(index)

	
	if nil ~= info then 

		-- 这是需求图片
		local bNeedIcoFlg = info.bShowNeedFlg
		if bNeedIcoFlg == 1 then
			self.Controls.m_NeedIco.gameObject:SetActive(true)
		else
			self.Controls.m_NeedIco.gameObject:SetActive(false)
		end
		
		-- 设置需要消耗的货币数量   暂时只支持消耗一种 不能消耗 货币+材料	 	
		local tStuff = IGame.ChipExchangeClient:GetChipGoodsStuff(index)
		self.m_nType = tStuff.nType
		local DaZhe = GameHelp:GetChipDaZhe(self.m_nType)
		self.m_nCount = math.ceil(tStuff.nValue * DaZhe)
		if self.m_nCount >= 10000 then
			self.m_nCount = self.m_nCount / 10000
			self.Controls.m_Text_Money.text 	= self.m_nCount .. "万"
		else 
			self.Controls.m_Text_Money.text 	= self.m_nCount 
		end

		-- 设置银两图片
		local silverIconPath = GameHelp:GetCurrencyIcon(tStuff.nType,tStuff.nGoodsID)
		if not IsNilOrEmpty(silverIconPath) then
			UIFunction.SetImageSprite(self.Controls.m_Image_MoneyIcon, silverIconPath)
		end

		self.Controls.m_Text_LimitGoods.gameObject:SetActive(true)
		-- 设置单独物品限购信息 n:(1表示天 2表示周), count: 数量
		local nLimitExchange = IGame.ChipExchangeClient:isLimitExchange(index) 
		if nLimitExchange == 0 then
			self.Controls.m_Text_LimitGoods.text = ""
			self.Controls.m_SaleOutImg.gameObject:SetActive(false)
		else 
			local n, count = IGame.ChipExchangeClient:GetLimitToGoodsTime(index)
			if nil ~= n and nil ~= count then 
				self.Controls.m_Text_LimitGoods.gameObject:SetActive(true)	
				if 1 == n then 
					local exist =  IGame.ChipExchangeClient:GetLimitGoodsCountByDay(index)
					self.Controls.m_Text_LimitGoods.text = "日限购:<color=#FF7800FF>"..exist.."/"..count.."</color>"
					if exist >= count then 
						self.Controls.m_SaleOutImg.gameObject:SetActive(true)
						self.Controls.m_Text_LimitGoods.gameObject:SetActive(false)
					else
						self.Controls.m_SaleOutImg.gameObject:SetActive(false)
						self.Controls.m_Text_LimitGoods.gameObject:SetActive(true) 
					end

					self.m_DayOrWeek = 1
				elseif 2 == n then 			
					local exist =  IGame.ChipExchangeClient:GetLimitGoodsCountByWeek(index)
					self.Controls.m_Text_LimitGoods.text = "周限购:<color=#FF7800FF>"..exist.."/"..count.."</color>"

					if exist >= count then 
						self.Controls.m_SaleOutImg.gameObject:SetActive(true)
						self.Controls.m_Text_LimitGoods.gameObject:SetActive(false)
					else
						self.Controls.m_SaleOutImg.gameObject:SetActive(false) 
						self.Controls.m_Text_LimitGoods.gameObject:SetActive(true)
					end 
					self.m_DayOrWeek = 2
				end	
			else
				self.Controls.m_Text_LimitGoods.text = ""	
			end	 
		end

	end
end

--------------------------------------------------------
-- 判断Unity3D对象是否被加载
function ChipItemCell:isLoaded()
	return not tolua.isnull( self.transform )
end

function ChipItemCell:SetFocus(on)
	if not self:isLoaded() then
		return
	end
	self.Controls.ItemToggle.isOn = on
end

function ChipItemCell:OnDisable()
	self:SetFocus(false)
end

-------------------------------------------------------------------
-- 设置当前item的图标	
-- @param IconPath : 当前金钱要显示的图标路径
-- @param index : 索引
-------------------------------------------------------------------
function ChipItemCell:SetIcon(IconPath, index)
	-- 设置物品图标
	if nil ~= IconPath and self.Controls.m_Image_GoodsIcon then 
		UIFunction.SetImageSprite(self.Controls.m_Image_GoodsIcon, IconPath)
	end
	
	-- 设置物品背景
	local ChipType = IGame.ChipExchangeClient:GetChipTypeByIndex(index)
	local nameColor = nil 
	if 1 == ChipType then  -- 装备
		local BaseLevel = IGame.ChipExchangeClient:GetGoodsBaseLevel(index)			-- 获取档次	
		local EquipQuality = IGame.ChipExchangeClient:GetEquipQualityByIndex(index)	-- 获取品阶
		if nil == BaseLevel or nil == EquipQuality then 
			print("ChipItemCell:SetIcon")
			return 
		end
		local EquipImageBgPath = GameHelp.GetEquipImageBgPath(EquipQuality,BaseLevel)
		UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , EquipImageBgPath)		
		nameColor = DColorDef.getNameColor(1,BaseLevel,EquipQuality)
	elseif 2 == ChipType then -- 物品
		local goodsBgPath = IGame.ChipExchangeClient:GetGoodsBaseLevel(index)
		local level  = IGame.ChipExchangeClient:GetGoodsBaseRealLevel(index)
		UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath.TextureGUIPath..goodsBgPath)	
		nameColor = DColorDef.getNameColor(0,level)
	end
			
	local name =IGame.ChipExchangeClient:GetGoodsName(index)
				-- 设置物品名称
	self.Controls.m_Text_GoodsName.text  = string.format("<color=#%s>%s</color>", nameColor or "597993FF" ,  name or "")  
end

function ChipItemCell:GetChipIndex()
	if nil ~= self.m_index then 
		return self.m_index
	end	
end

-- 添加新物品事件
function ChipItemCell:OnEventAddGoods()
	if not self:isShow() then
		return
	end
	local info = IGame.ChipExchangeClient:GetInfoByIndex(self.m_index)
	local nGoodID = IGame.ChipExchangeClient:GetGoodsIDByIndex(self.m_index)
	if not info or not nGoodID then
		return
	end
	if IGame.TaskSick:IsTaskNeedGoods(nGoodID) then
		info.bShowNeedFlg = 1
		self.Controls.m_NeedIco.gameObject:SetActive(true)
	else
		info.bShowNeedFlg = 0
		self.Controls.m_NeedIco.gameObject:SetActive(false)
	end
	--self:SetItemCellInfo(self.m_index)
end

-- 删除物品事件
function ChipItemCell:OnEventRemoveGoods()
	self:OnEventAddGoods()
end


-- 注册事件
function ChipItemCell:SubscribeEvent()
	rktEventEngine.SubscribeExecute( EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute( EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

-- 取消事件
function ChipItemCell:UnSubscribeEvent()
	rktEventEngine.UnSubscribeExecute( EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute( EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

function ChipItemCell:CallbackInit()
	self.callback_OnEventAddGoods = function() self:OnEventAddGoods() end
	self.callback_OnEventRemoveGoods = function() self:OnEventRemoveGoods() end
end


return this