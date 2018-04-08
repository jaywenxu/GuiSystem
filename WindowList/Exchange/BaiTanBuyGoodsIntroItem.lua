--/******************************************************************
--** 文件名:    BaiTanBuyGoodsIntroItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    交易界面-摆摊部件-商品介绍图标
--** 应  用:  
--******************************************************************/

local BaiTanBuyGoodsIntroItem = UIControl:new
{
    windowName = "BaiTanBuyGoodsIntroItem",
	
	m_IntroData = nil,			-- 介绍数据:IntroItemData
}

function BaiTanBuyGoodsIntroItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ButtonItem.onClick:RemoveListener(self.onItemClick)
	self.Controls.m_ButtonItem.onClick:AddListener(self.onItemClick)
	
end

-- 更新图标
-- @introData:商品介绍数据:IntroItemData
-- @isSelected:是否在选中的标识:boolean
function BaiTanBuyGoodsIntroItem:UpdateItem(introData, isSelected)
	
	self.m_IntroData = introData
	
	local goodsScheme = introData.m_GoodsScheme
	local totalSellCnt = IGame.ExchangeClient:GetSmallTypeGoodsTotalSellCnt(goodsScheme.goodsID, self.m_IntroData.m_Quality)
	
	self.Controls.m_LabelSellCnt.text = string.format("在售 %d", totalSellCnt)
	self.Controls.m_TfSelectedTip.gameObject:SetActive(isSelected)
	
	ExchangeWindowTool.SetGoodsNameLabel(self.Controls.m_LabelItemName, goodsScheme.goodsID, introData.m_Quality, 0, true)
	ExchangeWindowTool.SetGoodsIconAndBg(self.Controls.m_ImageIcon, self.Controls.m_ImageQuality, goodsScheme.goodsID, introData.m_Quality, 0)
	
end

-- 隐藏图标的选中提示
function BaiTanBuyGoodsIntroItem:HideItemSelectedTip()
	if nil ~= self.transform then
		self.Controls.m_TfSelectedTip.gameObject:SetActive(false)
	end
end

-- 图标的点击行为
function BaiTanBuyGoodsIntroItem:OnItemClick()
	
	local goodsScheme = self.m_IntroData.m_GoodsScheme
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_CHANGE_QUERY_GOODS, goodsScheme.goodsID, self.m_IntroData.m_Quality)

	self.Controls.m_TfSelectedTip.gameObject:SetActive(true)

end

function BaiTanBuyGoodsIntroItem:RecycleItem()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function BaiTanBuyGoodsIntroItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BaiTanBuyGoodsIntroItem:CleanData()
	if self.onItemClick then
		self.Controls.m_ButtonItem.onClick:RemoveListener(self.onItemClick)
		self.onItemClick = nil
	end	
end

return BaiTanBuyGoodsIntroItem