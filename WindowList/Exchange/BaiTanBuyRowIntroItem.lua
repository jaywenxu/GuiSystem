--/******************************************************************
--** 文件名:    BaiTanBuyRowIntroItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    交易界面-摆摊部件-商品行介绍图标
--** 应  用:  
--******************************************************************/

local BaiTanBuyGoodsIntroItem = require("GuiSystem.WindowList.Exchange.BaiTanBuyGoodsIntroItem")

local BaiTanBuyRowIntroItem = UIControl:new
{
    windowName = "BaiTanBuyRowIntroItem",
	
	m_ArrBaiTanBuyGoodsIntroItem = {},		-- 摆摊商品介绍图标脚本集合:table(BaiTanBuyGoodsIntroItem)
}

function BaiTanBuyRowIntroItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.m_ArrBaiTanBuyGoodsIntroItem[1] = BaiTanBuyGoodsIntroItem:new()
	self.m_ArrBaiTanBuyGoodsIntroItem[2] = BaiTanBuyGoodsIntroItem:new()
	
	self.m_ArrBaiTanBuyGoodsIntroItem[1]:Attach(self.Controls.m_TfBaiTanBuyGoodsIntroItem1.gameObject)
	self.m_ArrBaiTanBuyGoodsIntroItem[2]:Attach(self.Controls.m_TfBaiTanBuyGoodsIntroItem2.gameObject)
	
end

-- 更新图标
-- @listIntroData:商品行介绍数据:table(IntroItemData)
-- @curSelectedQuality:当前选中的品质:number
-- @curSelectedGoodsCfgId:当前选中的商品配到id:number
function BaiTanBuyRowIntroItem:UpdateItem(listIntroData, curSelectedQuality, curSelectedGoodsCfgId)
	
	self:UpdateOneGoodsIntroItem(1, listIntroData[1], curSelectedQuality, curSelectedGoodsCfgId)
	self:UpdateOneGoodsIntroItem(2, listIntroData[2], curSelectedQuality, curSelectedGoodsCfgId)
	
end

-- 隐藏图标的选中提示
function BaiTanBuyRowIntroItem:HideItemSelectedTip()
	
	self.m_ArrBaiTanBuyGoodsIntroItem[1]:HideItemSelectedTip()
	self.m_ArrBaiTanBuyGoodsIntroItem[2]:HideItemSelectedTip()
	
end

-- 更新一个商品介绍图标
-- @introData:商品介绍数据:IntroItemData
-- @curSelectedQuality:当前选中的品质:number
-- @curSelectedGoodsCfgId:当前选中的商品配到id:number
function BaiTanBuyRowIntroItem:UpdateOneGoodsIntroItem(itemIdx, introData, curSelectedQuality, curSelectedGoodsCfgId)
	
	local item = self.m_ArrBaiTanBuyGoodsIntroItem[itemIdx]
	
	if not introData then
		item.transform.gameObject:SetActive(false)
		return
	end
	
	local isSelected = false 
	local goodsScheme = introData.m_GoodsScheme
	
	if goodsScheme.class == GOODS_CLASS_EQUIPMENT then
		isSelected = goodsScheme.goodsID == curSelectedGoodsCfgId and introData.m_Quality == curSelectedQuality
	else
		isSelected = goodsScheme.goodsID == curSelectedGoodsCfgId
	end
	
	item.transform.gameObject:SetActive(true)
	item:UpdateItem(introData, isSelected)
	
end

function BaiTanBuyRowIntroItem:OnRecycle()
	
	self.m_ArrBaiTanBuyGoodsIntroItem[1]:RecycleItem()
	self.m_ArrBaiTanBuyGoodsIntroItem[2]:RecycleItem()
	
	UIControl.OnRecycle(self)
end
return BaiTanBuyRowIntroItem