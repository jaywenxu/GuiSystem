--================AuctionRecordItem.lua=============================
-- @author	Jack Miao
-- @desc	竞品日志记录Item
-- @date	2017.12.25
--================AuctionRecordItem.lua=============================

local AuctionRecordItem = UIControl:new
{
    windowName = "AuctionRecordItem",
	m_index = 0,
}

function AuctionRecordItem:Attach(obj)
	
    UIControl.Attach(self,obj)	
end

function AuctionRecordItem:RefreshUI(Record)

    if not Record then return end 
    
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, Record.nGoodsID)
	if not goodsScheme then
        uerror("[拍卖系统]AuctionRecordItem:RefreshUI->根据物品ID获取配置失败！"..tostring(Record.nGoodsID))
		return
	end
	
	local tradeDate = os.date("*t", Record.dwBargainTime)
	
	local strTime = string.format("%d-%d-%d %d:", tradeDate.year, tradeDate.month, tradeDate.day, tradeDate.hour)
    if tradeDate.min == 0 then 
        strTime = strTime.."00"
    else 
        strTime = strTime..tradeDate.min
    end 
    self.Controls.m_TextTime.text = strTime
    
	self.Controls.m_TextGoodsName.text = goodsScheme.name	
	self.Controls.m_TextPrice.text = NumTo10Wan(Record.dwAuctionMoney or 0)
    local strWay = "竞价"
    if Record.nWay == E_AuctionRecord_ClanMaxPrice or Record.nWay == E_AuctionRecord_GlobalMaxPrice then 
        strWay = "一口价"
    elseif Record.nWay == E_AuctionRecord_ClanPassed then 
        strWay = "流拍至全服"
    elseif Record.nWay == E_AuctionRecord_GlobalPassed then
        strWay = "流拍"
    end 
    self.Controls.m_TextAuctionWay.text = strWay
    
	if self.m_index % 2 == 1 then
		self.Controls.m_BG.gameObject:SetActive(true)
	else
		self.Controls.m_BG.gameObject:SetActive(false)
	end
end

function AuctionRecordItem:SetIndex(index)
	self.m_index = index
end

function AuctionRecordItem:GetIndex()
 
    return self.m_index
end

return AuctionRecordItem