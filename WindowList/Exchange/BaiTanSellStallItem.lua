--/******************************************************************
--** 文件名:    BaiTanSellStallItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-26
--** 版  本:    1.0
--** 描  述:    摆摊出售窗口-出售摊位图标
--** 应  用:  
--******************************************************************/

local BaiTanSellStallItem = UIControl:new
{
    windowName = "BaiTanSellStallItem",
	
	m_StallData = nil,		-- 摊位数据:SMsgExchangeTableExchangeBill
}

function BaiTanSellStallItem:Attach(obj)
    UIControl.Attach(self,obj)

    self:AddListener( self.Controls.m_ButtonItem , "onClick" , self.OnStallItemClick , self )
    self:AddListener( self.Controls.m_ButtonGoodsCell , "onClick" , self.OnGoodsCellClick , self )
	
end

-- 更新图标
-- @stallData:摊位数据:SMsgExchangeTableExchangeBill
-- @theSelectedStallId:当前选中的摊位id:long
function BaiTanSellStallItem:UpdateItem(stallData, theSelectedStallId)
	
	local isSelected = tostring(theSelectedStallId) == tostring(stallData.dwSeq)
	self.m_StallData = stallData

    self.transform.gameObject:SetActive(true)
	self.Controls.m_LabelGoodsPrice.text = NumTo10Wan(stallData.dwPrice)
	
	ExchangeWindowTool.SetGoodsIconAndBg(self.Controls.m_ImageGoodsIcon, self.Controls.m_ImageGoodsQuality, 
		stallData.nGoods, stallData.btColor, stallData.btProNum)
	ExchangeWindowTool.SetGoodsNameLabel(self.Controls.m_LabelGoodsName, stallData.nGoods, stallData.btColor, stallData.btProNum, false, true)
	ExchangeWindowTool.SetGoodsNumLabel(self.Controls.m_LabelGoodsCount, stallData.nGoods, stallData.nNoBindQty)
	
	-- 审核时间
	if stallData.btState == E_GoodState_Check then
		-- 设置时间文本的显示
		self:SetTimeLabelShow(self.Controls.m_LabelVerifyTime, stallData.dwTimeStamp)
	end
	
	-- 公示时间
	if stallData.btState == E_GoodState_Publicity then
		-- 设置时间文本的显示
		self:SetTimeLabelShow(self.Controls.m_LabelGongShiTime, stallData.dwTimeStamp)
	end

	local bgClr = self.Controls.m_ImageBg.color
	
	if isSelected then
		bgClr.a = 1
	else 
		bgClr.a = 0.68
	end
	
	self.Controls.m_ImageBg.color = bgClr

	self.Controls.m_TfCanExtractNode.gameObject:SetActive(stallData.nSoldNum > 0 and stallData.btState ~= E_GoodState_Check)
	self.Controls.m_TfOnVerifyNode.gameObject:SetActive(stallData.btState == E_GoodState_Check)
	self.Controls.m_TfOverTimeNode.gameObject:SetActive(stallData.nSoldNum < 1 and stallData.btState == E_GoodState_Overdue)
	self.Controls.m_TfGongShiNode.gameObject:SetActive(stallData.btState == E_GoodState_Publicity)
	
end

-- 设置时间文本的显示
-- @textTime:要设置时间的文本:Text
-- @endTime:结束时间:number
function BaiTanSellStallItem:SetTimeLabelShow(textTime, endTime)
	local remainTime = endTime - GetServerTimeSecond()
	if remainTime < 1 then
		remainTime = 1
	end
	
	textTime.text = SecondTimeToString_HM(remainTime)

end

-- 摊位图标的点击行为
function BaiTanSellStallItem:OnStallItemClick()
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, self.m_StallData.nGoods)
	if not goodsScheme then
		return
	end
	
	-- 可提取的时候先提取
	if self.m_StallData.nSoldNum > 0 then
		
		IGame.ExchangeClient:RequestGetIncome(self.m_StallData.dwSeq)
		return
	end
	
	ExchangeWindowPresetDataMgr:PresetPutData(nil, self.m_StallData)
	
	--UIManager.ExchangePutGoodsWindow:SetStallData(self.m_StallData)
	
	-- 装备
	if goodsScheme.class == GOODS_CLASS_EQUIPMENT  then
		IGame.ExchangeClient:RequestQueryReferencePrice(self.m_StallData.nGoods, self.m_StallData.btColor)
		return
	end
	
	-- 道具
	IGame.ExchangeClient:RequestQueryReferencePrice(self.m_StallData.nGoods, 0)
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_SELL_STALL_ITEM_SELECTED, self.m_StallData.dwSeq)

end

-- 道具图标的点击行为
function BaiTanSellStallItem:OnGoodsCellClick()
	
end

function BaiTanSellStallItem:RecycleItem()
	-- 清除数据
	UIControl.OnRecycle(self)
end

function BaiTanSellStallItem:OnDestroy()
	-- 清除数据
	UIControl.OnDestroy(self)
	
	self.m_StallData = nil
end


return BaiTanSellStallItem