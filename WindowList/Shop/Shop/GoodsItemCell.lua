
local ShopWidgetClass = require("GuiSystem.WindowList.Shop.Shop.ShopWidget")

local GoodsItemCell = UIControl:new
{
	windowName 	= "GoodsItemCell",
	m_index		= nil,				-- 第几个物品
	m_type      = nil, 				-- 物品类型
	
	m_selected_calback = nil ,		-- 选中时回调
	
	m_nType 	= nil,				-- 货币类型
	m_nCount	= nil, 				-- 需要消耗的货币数量

	m_DayOrWeek		= 1,				-- 1 物品控制天   2 物品控制周	

	m_plazaID = -1,					--plazaID
}

local zheKouStr = {
	[10] = "1 折",
	[20] = "2 折",
	[30] = "3 折",
	[40] = "4 折",
	[50] = "5 折",
	[60] = "6 折",
	[70] = "7 折",
	[80] = "8 折",
	[90] = "9 折",
	[100] = "免 费",
}



local this = GoodsItemCell

GoodsItemCell.TipSpritePath = AssetPath.TextureGUIPath.."Common_frame/"

local SellOutSpritePath  = AssetPath.TextureGUIPath.."Shop/store_showan.png"		--临时售罄的图片，等美术出图后换掉	TODO

function GoodsItemCell:Init()

end

function GoodsItemCell:Attach(obj)
	UIControl.Attach(self,obj)	
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))	
	self.Controls.ItemToggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
end


-- 销毁
function GoodsItemCell:OnDestroy()	
	if self.Controls.ItemToggle then
		self.Controls.ItemToggle.onValueChanged:RemoveListener(self.callback_OnSelectChanged)
	end
	UIControl.OnDestroy(self)
end

-------------------------------------------------------------------
-- 设置选中时回调函数	
-- @param func_cb : 回调函数
-------------------------------------------------------------------
function GoodsItemCell:SetSelectCallback(func_cb)
	
	self.m_selected_calback = func_cb
end	

-------------------------------------------------------------------
-- 设置组	
-- @param toggleGroup : 要设置的item(需要有toggle属性)
-------------------------------------------------------------------
function GoodsItemCell:SetToggleGroup(toggleGroup)
	
	self.Controls.ItemToggle.group = toggleGroup
end

-- 选中
function GoodsItemCell:OnSelectChanged(on)
	if not on then
		self.Controls.m_SelectImg.gameObject:SetActive(false)
	else
		self.Controls.m_SelectImg.gameObject:SetActive(true)
		if nil ~= self.m_selected_calback then 
			self.m_selected_calback(self, 0, m_index)
		end
	end
	
end


-------------------------------------------------------------------
-- 设置当前item的属性	
-- @param index : 要获取物品的索引				这里从服务器判断是否已经达到购买次数，或者售罄，设置置灰相关		TODO
-- @param nGoodsType : 所属类型	
-------------------------------------------------------------------
function GoodsItemCell:SetItemCellInfo(nGoodsType,index)
	local info = IGame.PlazaClient:GetInfoByIndex(nGoodsType,index)
	local goodsInfo = IGame.PlazaClient:GetGoodsData(nGoodsType,index)
	
	if nil ~= info and nil ~= goodsInfo then 
		-- 设置物品名称
		self.Controls.m_Text_GoodsName.text = string.format("<color=#%s>%s</color>",AssetPath_GoodsQualityColor[goodsInfo.lBaseLevel],goodsInfo.szName) 
		
		-- 设置需要消耗的货币数量   暂时只支持消耗一种 不能消耗 货币+材料	 	
		self.m_nType = info.nYuanbaoType		--钻石类型
		self.m_nCount = info.nPrice		        --道具单价
		

		-- 设置货币图片
		UIFunction.SetImageSprite(self.Controls.m_Image_MoneyIcon, AssetPath_CurrencyIcon[self.m_nType])
		
		if nil == info.nMarkType or info.nMarkType == "" then 
			self.Controls.m_TipImageCtl.gameObject:SetActive(false)
		else
			self.Controls.m_TipImageCtl.gameObject:SetActive(true)
			self.Controls.m_ZheKouText.text = zheKouStr[info.nCutPercent]
--			UIFunction.SetImageSprite(self.Controls.m_ZheKouImage, GoodsItemCell.TipSpritePath..info.nMarkType)
			if info.bCut then
				local price =  info.nPrice
				self.m_nCount = Mathf.Round(price * info.nCutPercent / 100)        --道具单价
			end
		end
		if self.m_nCount >= 10000 then
			self.Controls.m_Text_Money.text 	= self.m_nCount / 10000 .. "万"
		else
			self.Controls.m_Text_Money.text 	= self.m_nCount
		end
		
		--置灰还原
		UIFunction.SetImgComsGray(ShopWidgetClass.Controls.m_BuyBtnImage.gameObject,false)
--		if not ShopWidgetClass.Controls.m_BuyBtn.interactable then 
			ShopWidgetClass.Controls.m_BuyBtn.interactable = true
--		end
		self.Controls.m_SellOutCtl.gameObject:SetActive(false)
		
		-- 设置单独物品限购信息 n:(1表示天 2表示周), count: 数量
		local nLimitExchange = IGame.PlazaClient:IsLimitBuy(nGoodsType,index) 
		if nLimitExchange == 0 then
			self.Controls.m_Text_LimitGoods.text = ""
		else 
			local n, count = IGame.PlazaClient:GetLimitToGoodsTime(nGoodsType,index)						--限购数量需要和服务器，显示

			if nil ~= n and nil ~= count then 
				self.Controls.m_Text_LimitGoods.gameObject:SetActive(true)	
				if 1 == n then 
					local exist =  IGame.PlazaClient:GetLimitGoodsCountByDay(info.nSaleID)					--日限购，																		--test
					self.Controls.m_Text_LimitGoods.text = string.format("日限购:<color=#%s>%d/%d</color>" ,AssetPath_GoodsXianGouColor[1], exist, count)
					self.m_DayOrWeek = 1
					if count == exist then 
						self.Controls.m_SellOutCtl.gameObject:SetActive(true)
						UIFunction.SetImgComsGray(ShopWidgetClass.Controls.m_BuyBtnImage.gameObject,true)
						ShopWidgetClass.Controls.m_BuyBtn.interactable  = false
						self.Controls.m_Text_LimitGoods.gameObject:SetActive(false)
					end
				elseif 2 == n then 			
					local exist =  IGame.PlazaClient:GetLimitGoodsCountByWeek(info.nSaleID)					--周限购																		--test
					self.Controls.m_Text_LimitGoods.text = string.format("限购:<color=#%s>%d/%d</color>" ,AssetPath_GoodsXianGouColor[1], exist, count)
					self.m_DayOrWeek = 2
					if count == exist then 
						self.Controls.m_SellOutCtl.gameObject:SetActive(true)
						UIFunction.SetImgComsGray(ShopWidgetClass.Controls.m_BuyBtnImage.gameObject,true)
						ShopWidgetClass.Controls.m_BuyBtn.interactable  = false
						self.Controls.m_Text_LimitGoods.gameObject:SetActive(false)
					end
				end	
			else
				self.Controls.m_Text_LimitGoods.text = ""	
			end	 
		end
		
		self.m_type = nGoodsType				
		self.m_index = index
		self.m_plazaID = info.nSaleID
	end	

end

function GoodsItemCell:SetFocus(on)
	self.Controls.ItemToggle.isOn = on
end

-------------------------------------------------------------------
-- 设置当前item的图标	
-- @param  nGoodsType: 当前分类
-- @param index : 索引
-------------------------------------------------------------------
function GoodsItemCell:SetIcon(nGoodsType, index)
	--物品总表中的一条数据,   武器或者物品
	local goodsInfo = IGame.PlazaClient:GetGoodsData(nGoodsType, index)			
	local subGoodsInfo = IGame.PlazaClient:GetInfoByIndex(nGoodsType, index)
	
	if not goodsInfo or not subGoodsInfo then
		return
	end
	
	
	-- 设置物品背景
	local GoodsType = subGoodsInfo.nSelectType
	
	if 1 == GoodsType then  -- 装备				TODO
		
	elseif 2 == GoodsType then -- 物品
		UIFunction.SetImageSprite(self.Controls.m_Image_GoodsIcon , AssetPath.TextureGUIPath..goodsInfo.lIconID1)				--物品图标
		local goodsBgPath = goodsInfo.lIconID2
		UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath.TextureGUIPath..goodsBgPath)	
	end
end

function GoodsItemCell:GetGoodsIndex()
	if nil ~= self.m_index then 
		return self.m_index
	end
end

---------------------------------------------------商会相关---------------------------------------------------------
--商会条目显示
function GoodsItemCell:SetCofCCellInfo(nGoodsType, index)
	local info = IGame.PlazaClient:GetCofCConfigInfoByIndex(nGoodsType,index)							--plaza表
	local goodsInfo = IGame.PlazaClient:GetCofCGoodsData(nGoodsType,index)								--物品总表
	if nil ~= info and nil ~= goodsInfo then 
		-- 设置物品名称
		self.Controls.m_Text_GoodsName.text = string.format("<color=#%s>%s</color>",AssetPath_GoodsQualityColor[goodsInfo.lBaseLevel],goodsInfo.szName) 
		
		-- 设置需要消耗的货币数量   暂时只支持消耗一种 不能消耗 货币+材料	 	
		self.m_nType = info.nYuanbaoType		--钻石类型
		self.m_nCount = info.nPrice		        --道具单价
		

		-- 设置货币图片
		UIFunction.SetImageSprite(self.Controls.m_Image_MoneyIcon, AssetPath_CurrencyIcon[self.m_nType])
		
		if nil == info.nMarkType or info.nMarkType == "" then 
			self.Controls.m_TipImageCtl.gameObject:SetActive(false)
		else
			self.Controls.m_TipImageCtl.gameObject:SetActive(true)
			self.Controls.m_ZheKouText.text = zheKouStr[info.nCutPercent]
--			UIFunction.SetImageSprite(self.Controls.m_ZheKouImage, GoodsItemCell.TipSpritePath..info.nMarkType)
			if info.bCut then
				local price =  info.nPrice
				self.m_nCount = Mathf.Round(price * info.nCutPercent / 100)        --道具单价
			end
		end
		if self.m_nCount >= 10000 then
			self.Controls.m_Text_Money.text 	= self.m_nCount / 10000 .. "万"
		else
			self.Controls.m_Text_Money.text 	= self.m_nCount
		end
		
		--置灰还原
		UIFunction.SetImgComsGray(ShopWidgetClass.Controls.m_BuyBtnImage.gameObject,false)
--		if not ShopWidgetClass.Controls.m_BuyBtn.interactable then 
			ShopWidgetClass.Controls.m_BuyBtn.interactable = true
--		end
		self.Controls.m_SellOutCtl.gameObject:SetActive(false)
		
		-- 设置单独物品限购信息 n:(1表示天 2表示周), count: 数量
		local nLimitExchange
		if info == nil or info.GoodsTime == 0 or info.GoodsTime == nil then
			nLimitExchange = 0
		else
			nLimitExchange = info.GoodsTime
		end
		
		if nLimitExchange == 0 then
			self.Controls.m_Text_LimitGoods.text = ""
		else 
			local n, count = IGame.PlazaClient:GetCofCLimitToGoodsTime(nGoodsType,index)						--限购数量需要和服务器，显示

			if nil ~= n and nil ~= count then 
				self.Controls.m_Text_LimitGoods.gameObject:SetActive(true)	
				if 1 == n then 
					local exist =  IGame.PlazaClient:GetCofCLimitGoodsCountByDay(info.nSaleID)					--日限购，																		--test
					self.Controls.m_Text_LimitGoods.text = string.format("日限购:<color=#%s>%d/%d</color>" ,AssetPath_GoodsXianGouColor[1], exist, count)
					self.m_DayOrWeek = 1
					if count == exist then 
						self.Controls.m_SellOutCtl.gameObject:SetActive(true)
						UIFunction.SetImgComsGray(ShopWidgetClass.Controls.m_BuyBtnImage.gameObject,true)
						ShopWidgetClass.Controls.m_BuyBtn.interactable  = false
						self.Controls.m_Text_LimitGoods.gameObject:SetActive(false)
					end
				elseif 2 == n then 			
					local exist =  IGame.PlazaClient:GetCofCLimitGoodsCountByWeek(info.nSaleID)					--周限购																		--test
					self.Controls.m_Text_LimitGoods.text = string.format("限购:<color=#%s>%d/%d</color>" ,AssetPath_GoodsXianGouColor[1], exist, count)
					self.m_DayOrWeek = 2
					if count == exist then 
						self.Controls.m_SellOutCtl.gameObject:SetActive(true)
						UIFunction.SetImgComsGray(ShopWidgetClass.Controls.m_BuyBtnImage.gameObject,true)
						ShopWidgetClass.Controls.m_BuyBtn.interactable  = false
						self.Controls.m_Text_LimitGoods.gameObject:SetActive(false)
					end
				end	
			else
				self.Controls.m_Text_LimitGoods.text = ""	
			end	 
		end
		
		self.m_type = nGoodsType				
		self.m_index = index
		self.m_plazaID = info.nSaleID
	end	

end

--商会图标显示
function GoodsItemCell:SetCofCIcon(tabType, index)
	--物品总表中的一条数据,   武器或者物品
	local goodsInfo = IGame.PlazaClient:GetCofCGoodsData(tabType, index)			
	local subGoodsInfo = IGame.PlazaClient:GetCofCConfigInfoByIndex(tabType, index)
	
	if not goodsInfo or not subGoodsInfo then
		return
	end
	
	
	-- 设置物品背景
	local GoodsType = subGoodsInfo.nSelectType
	
	if 1 == GoodsType then  -- 装备				TODO
		
	elseif 2 == GoodsType then -- 物品
		UIFunction.SetImageSprite(self.Controls.m_Image_GoodsIcon , AssetPath.TextureGUIPath..goodsInfo.lIconID1)				--物品图标
		local goodsBgPath = goodsInfo.lIconID2
		UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath.TextureGUIPath..goodsBgPath)	
	end
end

return this