--/******************************************************************
--** 文件名:    ExchangeHistoryItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    摆摊交易历史记录图标
--** 应  用:  
--******************************************************************/

local ExchangeHistoryItem = UIControl:new
{
    windowName = "ExchangeHistoryItem",
	m_index = 1,
}

function ExchangeHistoryItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
end

-- 更新图标
-- @historyData:历史数据:stExchangeTradeLogInfo
function ExchangeHistoryItem:UpdateItem(historyData)

	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, historyData.nGoods)
	if not goodsScheme then
		return
	end
	
	local tradeDate = os.date("*t", historyData.dwTimeStamp)
	
	self.Controls.m_TextTime.text = string.format("%d月%d日%d:%d", tradeDate.month, tradeDate.day, tradeDate.hour, tradeDate.min)
	self.Controls.m_TextGoodsName.text = goodsScheme.name
	self.Controls.m_TextGoodsCnt.text = string.format("%d", historyData.nQty)
	self.Controls.m_TextIncome.text = NumTo10Wan(historyData.dwTax)
	
	if self.m_index % 2 == 1 then
		self.Controls.m_BG.gameObject:SetActive(true)
	else
		self.Controls.m_BG.gameObject:SetActive(false)
	end
end

function ExchangeHistoryItem:SetIndex(index)
	self.m_index = index
end

return ExchangeHistoryItem