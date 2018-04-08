--/******************************************************************
--** 文件名:    ExchangePutReferenceItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-22
--** 版  本:    1.0
--** 描  述:    摆摊上架窗口-上架物品参考窗口-参考物图标
--** 应  用:  
--******************************************************************/

local ExchangePutReferenceItem = UIControl:new
{
    windowName = "ExchangePutReferenceItem",
	m_referenceData = nil,
	m_cfgId = 0,
}

function ExchangePutReferenceItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	self.onGoodCellClick = function() self:OnGoodCellClick() end
	self.Controls.m_GoodsBtn.onClick:AddListener(self.onGoodCellClick)
end

-- 更新道具显示
-- @referenceData:参考数据:stExchangeCheapest
-- @cfgId:商品配置表id:number
function ExchangePutReferenceItem:UpdateForLeechdom(referenceData, cfgId)
	self.m_referenceData = referenceData
	self.m_cfgId = cfgId
	self.Controls.m_TextGoodsPrice.text = NumTo10Wan(referenceData.dwPrice)
	
	ExchangeWindowTool.SetGoodsNameLabel(self.Controls.m_TextGoodsName, cfgId, 0, 0, false)
	ExchangeWindowTool.SetGoodsNumLabel(self.Controls.m_TextGoodsNum, cfgId, referenceData.dwNum)
	ExchangeWindowTool.SetGoodsIconAndBg(self.Controls.m_ImageIcon, self.Controls.m_ImageQuality, cfgId, 0, 0)
	
end

-- 更新装备显示
-- @referenceData:参考数据:stExchangeCheapest
-- @cfgId:装备配置表id:number
-- @quality:装备品质:number
function ExchangePutReferenceItem:UpdateForEquip(referenceData, cfgId, quality)
	self.m_referenceData = referenceData
	self.m_cfgId = cfgId
	self.Controls.m_TextGoodsPrice.text = NumTo10Wan(referenceData.dwPrice)
	
	ExchangeWindowTool.SetGoodsNameLabel(self.Controls.m_TextGoodsName, cfgId, quality, 0, false)
	ExchangeWindowTool.SetGoodsNumLabel(self.Controls.m_TextGoodsNum, cfgId, referenceData.dwNum)
	ExchangeWindowTool.SetGoodsIconAndBg(self.Controls.m_ImageIcon, self.Controls.m_ImageQuality, cfgId, quality, 0)
	
end

-- 物品图标的点击行为
function ExchangePutReferenceItem:OnGoodCellClick()
	-- 后期操作商品
	local stallId = self.m_referenceData.dwSeq
	local goodsCfgId = self.m_cfgId
	local stallState = E_GoodState_OnShelf
	local tfItem = self.Controls.m_GoodsBtn.transform
	IGame.ExchangeClient:RequestExchangeGoodsTips(stallId, goodsCfgId, stallState, tfItem)
	
end

return ExchangePutReferenceItem