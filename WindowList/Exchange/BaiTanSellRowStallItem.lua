--/******************************************************************
--** 文件名:    BaiTanSellRowStallItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-26
--** 版  本:    1.0
--** 描  述:    摆摊出售窗口-出售摊位行图标
--** 应  用:  
--******************************************************************/

local BaiTanSellStallItem = require("GuiSystem.WindowList.Exchange.BaiTanSellStallItem")

local BaiTanSellRowStallItem = UIControl:new
{
    windowName = "BaiTanSellRowStallItem",
	
	m_BaiTanSellStallItem1 = nil,	-- 摊位图标1:BaiTanSellStallItem
	m_BaiTanSellStallItem2 = nil,	-- 摊位图标2:BaiTanSellStallItem
}

function BaiTanSellRowStallItem:Attach(obj)
    UIControl.Attach(self,obj)

	self.m_BaiTanSellStallItem1 = BaiTanSellStallItem:new()
	self.m_BaiTanSellStallItem2 = BaiTanSellStallItem:new()
	
	self.m_BaiTanSellStallItem1:Attach(self.Controls.m_TfBaiTanSellStallItem1.gameObject)
	self.m_BaiTanSellStallItem2:Attach(self.Controls.m_TfBaiTanSellStallItem2.gameObject)
	
end

-- 更新图标
-- @rowStallData:一行货摊数据:table(SMsgExchangeTableExchangeBill or 0)
-- @theSelectedStallId:当前选中的摊位id:long
function BaiTanSellRowStallItem:UpdateItem(rowStallData, theSelectedStallId)
	
	self:UpdateOneStallItem(self.m_BaiTanSellStallItem1, rowStallData[1], theSelectedStallId)
	self:UpdateOneStallItem(self.m_BaiTanSellStallItem2, rowStallData[2], theSelectedStallId)
	
end

-- 更新一个货摊图标
-- @stallItem:货摊图标:BaiTanSellStallItem
-- @stallData:货摊数据:SMsgExchangeTableExchangeBill or 0
-- @theSelectedStallId:当前选中的摊位id:long
function BaiTanSellRowStallItem:UpdateOneStallItem(stallItem, stallData, theSelectedStallId)	
	if stallData == 0 then
		stallItem.transform.gameObject:SetActive(false)
		return
	end
	
	stallItem.transform.gameObject:SetActive(true)
	stallItem:UpdateItem(stallData, theSelectedStallId) 

end

function BaiTanSellRowStallItem:OnRecycle()
	-- 清除数据
	
	self.m_BaiTanSellStallItem1:RecycleItem()
	self.m_BaiTanSellStallItem2:RecycleItem()
	
	UIControl.OnRecycle(self)
end

return BaiTanSellRowStallItem