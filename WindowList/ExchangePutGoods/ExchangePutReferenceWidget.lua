--/******************************************************************
--** 文件名:    ExchangePutReferenceWidget.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-22
--** 版  本:    1.0
--** 描  述:    摆摊上架窗口-上架物品参考窗口
--** 应  用:  
--******************************************************************/

local ExchangePutReferenceItem = require("GuiSystem.WindowList.ExchangePutGoods.ExchangePutReferenceItem")

local ExchangePutReferenceWidget = UIControl:new
{
    windowName = "ExchangePutReferenceWidget",
	
	m_ArrReferenceItem = {},		-- 参考图标集合:table(ExchangePutReferenceItem)
}

function ExchangePutReferenceWidget:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	for itemIdx = 1, 4 do
		local item = ExchangePutReferenceItem:new()
		item:Attach(self.Controls[string.format("m_TfExchangePutReferenceItem%d", itemIdx)].gameObject)
		
		self.m_ArrReferenceItem[itemIdx] = item
	end
	
end

-- 更新窗口
-- @msgBody:协议回包消息体:SMsgExchangeCheapest_SC
-- @goodsCfgId:物品配置id:number
-- @goodsQuality:物品品质:number
function ExchangePutReferenceWidget:UpdateWidget(msgBody, goodsCfgId, goodsQuality)
	
	local haveRefData = msgBody.btNum > 0
	self.Controls.m_TfNoReferenceNode.gameObject:SetActive(not haveRefData)
	self.Controls.m_TfLayoutExchangePutReferenceItem.gameObject:SetActive(haveRefData)

	if not haveRefData then
		return
	end

	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, goodsCfgId)
	if not goodsScheme then
		return
	end

	for itemIdx = 1, 4 do
		local item = self.m_ArrReferenceItem[itemIdx]
		local itemNeedShow = itemIdx <= msgBody.btNum
		item.transform.gameObject:SetActive(itemNeedShow)
		
		if itemNeedShow then
			if goodsScheme.class == GOODS_CLASS_EQUIPMENT  then -- 装备		
				item:UpdateForEquip(msgBody.objPrices[itemIdx], goodsCfgId, goodsQuality)
			else -- 道具
				item:UpdateForLeechdom(msgBody.objPrices[itemIdx], goodsCfgId)
			end
			
		end
	end
	
end

return ExchangePutReferenceWidget