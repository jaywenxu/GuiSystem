--/******************************************************************
--** 文件名:    ExchangePutControlWidget.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-22
--** 版  本:    1.0
--** 描  述:    摆摊上架窗口-上架物品操作窗口
--** 应  用:  
--******************************************************************/

local ExchangePutControlWidget = UIControl:new
{
    windowName = "ExchangePutControlWidget",
	
	m_GoodsMaxSellCnt = 0,					-- 物品最大可出售数量:number
	m_GoodsMinSellCnt = 1,					-- 物品最小可出售数量:number

	m_SuggestPrice = 0,						-- 推荐价格:number
	m_PriceRateFactor = 0,					-- 价格比率变动系数:number
	m_GoodsSellCnt = 0,						-- 物品出售数量:number

	m_GoodsUid = nil,						-- 要出售物品的uid:long
	m_StallData = nil,						-- 摊位数据:SMsgExchangeTableExchangeBill
	
	m_GoodsScheme = nil,					-- 商品配置表:ExchangeGoodsCfg
	m_ParamScheme = nil,					-- 交易参数配置表:ExchangeConfig
}

function ExchangePutControlWidget:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onGoodCellClick = function() self:OnGoodCellClick() end
	self.onSubPriceButtonClick = function() self:OnSubPriceButtonClick() end
	self.onAddPriceButtonClick = function() self:OnAddPriceButtonClick() end
	self.onSubCntButtonClick = function() self:OnSubCntButtonClick() end
	self.onAddCntButtonClick = function() self:OnAddCntButtonClick() end
	self.onPutButtonClick = function() self:OnPutButtonClick() end
	self.onDownButtonClick = function() self:OnDownButtonClick() end
	self.onReputButtonClick = function() self:OnReputButtonClick() end
	self.onGoodsCntButtonClick = function() self:OnGoodsCntButtonClick() end
	self.Controls.m_ButtonGoodCell.onClick:AddListener(self.onGoodCellClick)
	self.Controls.m_ButtonSubPrice.onClick:AddListener(self.onSubPriceButtonClick)
	self.Controls.m_ButtonAddPrice.onClick:AddListener(self.onAddPriceButtonClick)
	self.Controls.m_ButtonSubCnt.onClick:AddListener(self.onSubCntButtonClick)
	self.Controls.m_ButtonAddCnt.onClick:AddListener(self.onAddCntButtonClick)
	self.Controls.m_ButtonPut.onClick:AddListener(self.onPutButtonClick)
	self.Controls.m_ButtonDown.onClick:AddListener(self.onDownButtonClick)
	self.Controls.m_ButtonReput.onClick:AddListener(self.onReputButtonClick)
	self.Controls.m_ButtonGoodsCnt.onClick:AddListener(self.onGoodsCntButtonClick)
	
	self.onTipsButtonClick = function() self:OnClickTipsBtn() end
	self.Controls.m_ButtonTipsReSell.onClick:AddListener(self.onTipsButtonClick)
	self.Controls.m_ButtonTipsSell.onClick:AddListener(self.onTipsButtonClick)
	
	self.onHideTipsWnd = function() self:OnHideTipsWnd() end
	self.Controls.m_ButtonHideTips.onClick:AddListener(self.onHideTipsWnd)
end

-- 上架处理的更新
-- @goodsUid:商品gid:long
function ExchangePutControlWidget:UpdateForPut(goodsUid)
	self.m_GoodsUid = goodsUid
	self.m_StallData = nil

	local entity = IGame.EntityClient:Get(goodsUid)
	if not entity then
		return
	end
	
	local goodsCfgId = entity:GetNumProp(GOODS_PROP_GOODSID)
	self.m_GoodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, goodsCfgId)
	if not self.m_GoodsScheme then
		return
	end
	
	self.m_ParamScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_CONFIG_CSV, 1)
	if not self.m_ParamScheme then
		return
	end
	
	self.m_GoodsMaxSellCnt = entity:GetNumProp(GOODS_PROP_NO_BIND_QTY)
	self.m_GoodsMinSellCnt = 1
	self.m_PriceRateFactor = 0
	self.m_GoodsSellCnt = 1
	self.m_SuggestPrice = self.m_GoodsScheme.suggestedPrice
	
	-- 装备价格和数量处理
	local quality = 0
	local attrNum = 0
	if self.m_GoodsScheme.class == GOODS_CLASS_EQUIPMENT then
		quality  = entity:GetNumProp(EQUIP_PROP_QUALITY)
		attrNum = entity:GetAdditionalPropNum()
		self.m_SuggestPrice = ExchangeWindowTool.CalcEquipSuggetPrice(goodsCfgId, quality, attrNum)
		self.m_GoodsMaxSellCnt = 1
	end
	
	-- 不能超过单次出售数量
	if self.m_GoodsMaxSellCnt > self.m_GoodsScheme.onceSellMax then
		self.m_GoodsMaxSellCnt = self.m_GoodsScheme.onceSellMax
	end
	
	self.Controls.m_TfFirstPutNode.gameObject:SetActive(true)
	self.Controls.m_TfReputNode.gameObject:SetActive(false)
	
	-- 更新操作的元素的显示
	self:UpdateControlElementShow()
	
	ExchangeWindowTool.SetGoodsIconAndBg(self.Controls.m_ImageGoodsIcon, self.Controls.m_ImageGoodsQuality, goodsCfgId, quality, attrNum)
	ExchangeWindowTool.SetEntityTextLabel(entity, self.Controls.m_TextGoodsName, false)
	ExchangeWindowTool.SetGoodsNumLabel(self.Controls.m_TextGoodsNum, goodsCfgId, 0) --self.m_GoodsMaxSellCnt)
	
end

-- 后期处理的更新
-- @stallData:摊位数据:SMsgExchangeTableExchangeBill
function ExchangePutControlWidget:UpdateForRedeal(stallData)
	self.Controls.m_TipsWnd.gameObject:SetActive(false)
	
	self.m_GoodsUid = nil
	self.m_StallData = stallData
	
	local goodsCfgId = stallData.nGoods
	local quality = stallData.btColor
	local attrNum = stallData.btProNum
	
	self.m_GoodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, goodsCfgId)
	if not self.m_GoodsScheme then
		return
	end
	
	self.m_ParamScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_CONFIG_CSV, 1)
	if not self.m_ParamScheme then
		return
	end
	
	self.m_SuggestPrice = self.m_GoodsScheme.suggestedPrice
	
	if self.m_GoodsScheme.class == GOODS_CLASS_EQUIPMENT then
		self.m_SuggestPrice = ExchangeWindowTool.CalcEquipSuggetPrice(self.m_StallData.nGoods, 
			self.m_StallData.btColor, self.m_StallData.btProNum)
	end
	
	self.Controls.m_TfFirstPutNode.gameObject:SetActive(false)
	self.Controls.m_TfReputNode.gameObject:SetActive(true)
	
	self.m_GoodsMaxSellCnt = stallData.nNoBindQty
	self.m_GoodsMinSellCnt = stallData.nNoBindQty
	self.m_PriceRateFactor = math.floor((((stallData.dwPrice + 10) / self.m_SuggestPrice - 1) * 100) / self.m_GoodsScheme.priceDelta)
	self.m_GoodsSellCnt = stallData.nNoBindQty
	
	-- 更新操作的元素的显示
	self:UpdateControlElementShow()
	
	ExchangeWindowTool.SetGoodsIconAndBg(self.Controls.m_ImageGoodsIcon, self.Controls.m_ImageGoodsQuality, goodsCfgId, quality, attrNum)
	ExchangeWindowTool.SetGoodsNameLabel(self.Controls.m_TextGoodsName, goodsCfgId, quality, attrNum, true)
	ExchangeWindowTool.SetGoodsNumLabel(self.Controls.m_TextGoodsNum, goodsCfgId, 0)
	
end

-- 更新操作的元素的显示
function ExchangePutControlWidget:UpdateControlElementShow()
	
	local priceRate = self.m_PriceRateFactor * self.m_GoodsScheme.priceDelta
	local price = self.m_SuggestPrice * (100 + priceRate) / 100
	price = math.floor(price)
	local totalPrice = self.m_GoodsSellCnt * price
	local putCost = totalPrice * self.m_ParamScheme.factorageRate / 10000
	putCost = math.floor(putCost)
	if putCost < self.m_ParamScheme.minFactorage then
		putCost = self.m_ParamScheme.minFactorage 
	elseif putCost > self.m_ParamScheme.maxFactorage then
		putCost = self.m_ParamScheme.maxFactorage 
	end
	
	if self.m_PriceRateFactor == 0 then
		self.Controls.m_TextPriceRate.text = "基准价格"
	elseif self.m_PriceRateFactor > 0 then
		self.Controls.m_TextPriceRate.text = string.format("基准价格+%d", priceRate) .. "%"
	else
		self.Controls.m_TextPriceRate.text = string.format("基准价格%d", priceRate) .. "%"
	end
	
	self.Controls.m_TextGoodsPrice.text = NumTo10Wan(price)
	self.Controls.m_TextGoodsSelectedCnt.text = string.format("%d", self.m_GoodsSellCnt)
	
	self.Controls.m_TextTotalPrice.text = NumTo10Wan(totalPrice)
	
	self.Controls.m_TextPutCost.text = string.format("%d", putCost)
	
	local nYL = GetHero():GetCurrency(emCoinClientType_YinLiang)
	
	self.Controls.m_TextReputCost.text = string.format("%d", putCost)
	if putCost > nYL then
		self.Controls.m_TextReputCost.color = UIFunction.ConverRichColorToColor("E4595A")
		self.Controls.m_TextPutCost.color = UIFunction.ConverRichColorToColor("E4595A")
	else
		self.Controls.m_TextReputCost.color = UIFunction.ConverRichColorToColor("597993")
		self.Controls.m_TextPutCost.color = UIFunction.ConverRichColorToColor("597993")
	end
	
	
	-- 更新按钮的灰度显示
	self:UpdateButtonGrayShow()
	
end
	
-- 更新按钮的灰度显示
function ExchangePutControlWidget:UpdateButtonGrayShow()

	local maxFactor = self.m_GoodsScheme.priceUpLimit / self.m_GoodsScheme.priceDelta
	local minFactor = self.m_GoodsScheme.priceLowLimit / self.m_GoodsScheme.priceDelta
	
	UIFunction.SetImageGray(self.Controls.m_ImageSubPrice, self.m_PriceRateFactor <= -minFactor)
	UIFunction.SetImageGray(self.Controls.m_ImageAddPrice, self.m_PriceRateFactor >= minFactor)
	UIFunction.SetImageGray(self.Controls.m_ImageSubCnt, self.m_GoodsSellCnt <= self.m_GoodsMinSellCnt)
	UIFunction.SetImageGray(self.Controls.m_ImageAddCnt, self.m_GoodsSellCnt >= self.m_GoodsMaxSellCnt)
	
end

-- 变更物品的价格比率
-- @strideFactor:比率变动幅度系数:number
function ExchangePutControlWidget:ChangeGoodsPriceRate(strideFactor)

	local maxFactor = self.m_GoodsScheme.priceUpLimit / self.m_GoodsScheme.priceDelta
	local minFactor = self.m_GoodsScheme.priceLowLimit / self.m_GoodsScheme.priceDelta
	
	self.m_PriceRateFactor = self.m_PriceRateFactor + strideFactor
	if self.m_PriceRateFactor > maxFactor then
		self.m_PriceRateFactor = maxFactor
	elseif self.m_PriceRateFactor < -minFactor then
		self.m_PriceRateFactor = -minFactor
	end
	
end

-- 变动物品的出售数量
-- @dstSellCnt:打算出售的处理:number
function ExchangePutControlWidget:ChangeGoodsSellCount(dstSellCnt)

	if dstSellCnt < self.m_GoodsMinSellCnt then
		dstSellCnt = self.m_GoodsMinSellCnt
	elseif dstSellCnt > self.m_GoodsMaxSellCnt then
		dstSellCnt = self.m_GoodsMaxSellCnt
	end
	
	self.m_GoodsSellCnt = dstSellCnt
	
end

-- 物品图标的点击行为
function ExchangePutControlWidget:OnGoodCellClick()

	-- 上架
	if self.m_GoodsUid ~= nil then
		local entity = IGame.EntityClient:Get(self.m_GoodsUid)
		ExchangeWindowTool.ClickEntityItem(entity, self.Controls.m_ButtonGoodCell.transform)
		return
	end
	
	-- 后期操作商品
	local stallId = self.m_StallData.dwSeq
	local goodsCfgId = self.m_StallData.nGoods
	local stallState = self.m_StallData.btState
	local tfItem = self.Controls.m_ButtonGoodCell.transform
	IGame.ExchangeClient:RequestExchangeGoodsTips(stallId, goodsCfgId, stallState, tfItem)
	
end

-- 减少售价按钮的点击行为
function ExchangePutControlWidget:OnSubPriceButtonClick()
	
	-- 变更物品的价格比率
	self:ChangeGoodsPriceRate(-1)
	-- 更新操作的元素的显示
	self:UpdateControlElementShow()
	
end

-- 增加售价按钮的点击行为
function ExchangePutControlWidget:OnAddPriceButtonClick()
	
	-- 变更物品的价格比率
	self:ChangeGoodsPriceRate(1)
	-- 更新操作的元素的显示
	self:UpdateControlElementShow()
	
end

-- 减少出售数量按钮的点击行为
function ExchangePutControlWidget:OnSubCntButtonClick()
	
	-- 变动物品的出售数量
	self:ChangeGoodsSellCount(self.m_GoodsSellCnt - 1)
	-- 更新操作的元素的显示
	self:UpdateControlElementShow()
	
end

-- 增加出售数量按钮的点击行为
function ExchangePutControlWidget:OnAddCntButtonClick()
	
	-- 变动物品的出售数量
	self:ChangeGoodsSellCount(self.m_GoodsSellCnt + 1)
	-- 更新操作的元素的显示
	self:UpdateControlElementShow()
	
end

-- 上架按钮的点击行为
function ExchangePutControlWidget:OnPutButtonClick()
	
	local priceRate = self.m_PriceRateFactor * self.m_GoodsScheme.priceDelta
	local price = self.m_SuggestPrice * ((100 + priceRate) / 100)
	
	IGame.ExchangeClient:RequestExchangeShelfOnGoods(self.m_GoodsUid, price, self.m_GoodsSellCnt)
	
end

-- 下架按钮的点击行为
function ExchangePutControlWidget:OnDownButtonClick()
	
	IGame.ExchangeClient:RequestExchangeShelfOffGoods(self.m_StallData.dwSeq, self.m_StallData.nGoods, self.m_StallData.nNoBindQty)
	
end

-- 重新上架按钮的点击行为
function ExchangePutControlWidget:OnReputButtonClick()
	
	local priceRate = self.m_PriceRateFactor * self.m_GoodsScheme.priceDelta
	local price = self.m_SuggestPrice * ((100 + priceRate) / 100)
	
	IGame.ExchangeClient:RequestExchangeReShelfOnGoods(self.m_StallData.dwSeq, price, self.m_StallData.nNoBindQty)
	
end

-- 道具数量按钮的点击刑
function ExchangePutControlWidget:OnGoodsCntButtonClick()
	
	-- 数量不可以变得的时候，不要弹数量窗口
	if self.m_GoodsMaxSellCnt == self.m_GoodsMinSellCnt then
		return
	end
	
	local onUpdateChange = function(num) 
		-- 变动物品的出售数量
	self:ChangeGoodsSellCount(num)
	-- 更新操作的元素的显示
	self:UpdateControlElementShow()
	end
	
	local numTable = {
	    ["inputNum"] = self.m_GoodsSellCnt,
		["minNum"] = 1,
		["maxNum"] =  self.m_GoodsMaxSellCnt,
		["bLimitExchange"] = 0
	}
	
	local otherInfoTable = {
		["inputTransform"] = self.Controls.m_ButtonGoodsCnt.transform,
	    ["bDefaultPos"] = 1,
	    ["callback_UpdateNum"] = onUpdateChange
	}
	
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable)
	
end 

--[[-- 数量输入栏结束时的行为
-- 模糊匹配
-- @inputField:输入栏控件:InputField
function ExchangePutControlWidget:OnCountInputEndEdit(inputField)
	
	local dstCnt = 1
	if self.m_InputGoodsCnt.text ~= "" then
		dstCnt = tonumber(self.m_InputGoodsCnt.text)
	end
	
	-- 变动物品的出售数量
	self:ChangeGoodsSellCount(dstCnt)
	-- 更新操作的元素的显示
	self:UpdateControlElementShow()
	
end--]]


function ExchangePutControlWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function ExchangePutControlWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function ExchangePutControlWidget:CleanData()
	
	self.Controls.m_ButtonGoodCell.onClick:RemoveListener(self.onGoodCellClick)
	self.Controls.m_ButtonSubPrice.onClick:RemoveListener(self.onSubPriceButtonClick)
	self.Controls.m_ButtonAddPrice.onClick:RemoveListener(self.onAddPriceButtonClick)
	self.Controls.m_ButtonSubCnt.onClick:RemoveListener(self.onSubCntButtonClick)
	self.Controls.m_ButtonAddCnt.onClick:RemoveListener(self.onAddCntButtonClick)
	self.Controls.m_ButtonPut.onClick:RemoveListener(self.onPutButtonClick)
	self.Controls.m_ButtonDown.onClick:RemoveListener(self.onDownButtonClick)
	self.Controls.m_ButtonReput.onClick:RemoveListener(self.onReputButtonClick)
	self.Controls.m_ButtonGoodsCnt.onClick:RemoveListener(self.onGoodsCntButtonClick)
	self.onGoodCellClick = nil
	self.onSubPriceButtonClick = nil
	self.onAddPriceButtonClick = nil
	self.onSubCntButtonClick = nil
	self.onAddCntButtonClick = nil
	self.onPutButtonClick = nil
	self.onDownButtonClick = nil
	self.onReputButtonClick = nil
	self.onGoodsCntButtonClick = nil
	
	
	self.Controls.m_ButtonTipsReSell.onClick:RemoveListener(self.onTipsButtonClick)
	self.Controls.m_ButtonTipsSell.onClick:RemoveListener(self.onTipsButtonClick)
	self.onTipsButtonClick = nil
	
	self.Controls.m_ButtonHideTips.onClick:RemoveListener(self.onHideTipsWnd)
	self.onHideTipsWnd = nil
end

function ExchangePutControlWidget:OnClickTipsBtn()
	self.Controls.m_TipsWnd.gameObject:SetActive(true)
end

function ExchangePutControlWidget:OnHideTipsWnd()
	self.Controls.m_TipsWnd.gameObject:SetActive(false)
end

return ExchangePutControlWidget