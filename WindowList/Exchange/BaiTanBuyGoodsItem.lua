--/******************************************************************
--** 文件名:    BaiTanBuyGoodsItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    摆摊窗口-购买窗口-购买图标
--** 应  用:  
--******************************************************************/

local BaiTanBuyGoodsItem = UIControl:new
{
    windowName = "BaiTanBuyGoodsItem",
	
	m_StallData = {},		-- 摊位数据:ExchangeBillBaseInfo
	
}

function BaiTanBuyGoodsItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.onCollectButtonClick = function() self:OnCollectButtonClick() end
	self.onGoodsCellClick = function() self:OnGoodsCellClick() end
	self.Controls.m_ButtonItem.onClick:AddListener(self.onItemClick)
	self.Controls.m_ButtonCollect.onClick:AddListener(self.onCollectButtonClick)
	self.Controls.m_ButtonGoodsCell.onClick:AddListener(self.onGoodsCellClick)
	
end

-- 更新图标
-- @stallData:摊位数据:ExchangeBillBaseInfo
-- @isSelected:是否选中的标识:boolean
function BaiTanBuyGoodsItem:UpdateItem(stallData, isSelected)
	
	self.m_StallData = stallData
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, stallData.goodsID)
	if not goodsScheme then
		return
	end
	
	self.Controls.m_TextGoodsPrice.text = NumTo10Wan(stallData.price)
	self.Controls.m_TfSelectedTip.gameObject:SetActive(isSelected)

	-- 更新商品的公示时间
	self:UpdateGoodsGongShiTime()
	-- 更新收藏元素的显示
	self:UpdateTheCollectElementShow()
	
	ExchangeWindowTool.SetGoodsNameLabel(self.Controls.m_TextGoodsName, stallData.goodsID, stallData.btColor, stallData.btProNum, true, true)
	ExchangeWindowTool.SetGoodsNumLabel(self.Controls.m_TextGoodsCount, stallData.goodsID, stallData.goodsQnt)
	ExchangeWindowTool.SetGoodsIconAndBg(self.Controls.m_ImageGoodsIcon, self.Controls.m_ImageGoodsQuality, stallData.goodsID, stallData.btColor, stallData.btProNum)
	
end

-- 设置时间文本的显示
-- @textTime:要设置时间的文本:Text
-- @endTime:结束时间:number
function BaiTanBuyGoodsItem:SetTimeLabelShow(textTime, endTime)
	local remainTime = endTime - GetServerTimeSecond()
	if remainTime < 1 then
		remainTime = 1
	end
	
	textTime.text = SecondTimeToString_HM(remainTime)

end

-- 更新商品的公示时间
function BaiTanBuyGoodsItem:UpdateGoodsGongShiTime()
	
	if self.m_StallData.btState ~= E_GoodState_Publicity then
		self.Controls.m_TextGongShiTime.text = ""
	else 
		self:SetTimeLabelShow(self.Controls.m_TextGongShiTime, self.m_StallData.timeStamp)
	end
	
end

-- 更新收藏元素的显示
function BaiTanBuyGoodsItem:UpdateTheCollectElementShow()
	
	local isInCollect = IGame.ExchangeClient:CheckTheStallIsInCollect(self.m_StallData.seq)
	
	if isInCollect then
		self.Controls.m_TextCollectState.text = "<color=#FF7800>已收藏</color>"
		UIFunction.SetImageSprite(self.Controls.m_ImageCollectIcon, AssetPath.TextureGUIPath.."Exchanger/Exchange_shoucang_xuan.png")
	else
		self.Controls.m_TextCollectState.text = "<color=#597993>收藏</color>"
		UIFunction.SetImageSprite(self.Controls.m_ImageCollectIcon, AssetPath.TextureGUIPath.."Exchanger/Exchange_shoucang_mo.png")
	end
	
end

-- 图标的点击行为
function BaiTanBuyGoodsItem:OnItemClick()
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_SELECT_BUY_GOODS, self.m_StallData.seq)
	
end

-- 收藏按钮的点击行为
function BaiTanBuyGoodsItem:OnCollectButtonClick()
	
	local isInCollect = IGame.ExchangeClient:CheckTheStallIsInCollect(self.m_StallData.seq)
	if isInCollect then
		IGame.ExchangeClient:RequestRmvCollectStall(self.m_StallData.seq)
	else 
		IGame.ExchangeClient:RequestCollectStall(self.m_StallData.seq)
	end
	
	-- 更新收藏元素的显示
	self:UpdateTheCollectElementShow()
	
end

-- 物品图标的点击行为
function BaiTanBuyGoodsItem:OnGoodsCellClick()
	
	local stallId = self.m_StallData.seq
	local goodsCfgId = self.m_StallData.goodsID
	local stallState = self.m_StallData.btState
	local tfItem = self.Controls.m_ButtonGoodsCell.transform
	
	IGame.ExchangeClient:RequestExchangeGoodsTips(stallId, goodsCfgId, stallState, tfItem)
	
end


function BaiTanBuyGoodsItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function BaiTanBuyGoodsItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BaiTanBuyGoodsItem:CleanData()
	
	self.Controls.m_ButtonItem.onClick:RemoveListener(self.onItemClick)
	self.Controls.m_ButtonCollect.onClick:RemoveListener(self.onCollectButtonClick)
	self.Controls.m_ButtonGoodsCell.onClick:RemoveListener(self.onGoodsCellClick)
	self.onItemClick = nil
	self.onCollectButtonClick = nil
	self.onGoodsCellClick = nil
	
end


return BaiTanBuyGoodsItem