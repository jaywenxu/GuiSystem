--/******************************************************************
---** 文件名:	BaiTanSellWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-09
--** 版  本:	1.0
--** 描  述:	交易窗口-摆摊窗口-出售窗口
--** 应  用:  
--******************************************************************/

local BaiTanSellStallWidget = require("GuiSystem.WindowList.Exchange.BaiTanSellStallWidget")
local BaiTanSellSelectWidget = require("GuiSystem.WindowList.Exchange.BaiTanSellSelectWidget")

local BaiTanSellWidget = UIControl:new
{
	windowName = "BaiTanSellWidget",
	
	m_BaiTanSellStallWidget = nil,		-- 已上架物窗口:BaiTanSellStallWidget
	m_BaiTanSellSelectWidget = nil,		-- 选择上架物窗口:BaiTanSellSelectWidget
}

function BaiTanSellWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.m_BaiTanSellStallWidget = BaiTanSellStallWidget:new()
	self.m_BaiTanSellSelectWidget = BaiTanSellSelectWidget:new()
	
	self.m_BaiTanSellStallWidget:Attach(self.Controls.m_TfBaiTanSellStallWidget.gameObject)
	self.m_BaiTanSellSelectWidget:Attach(self.Controls.m_TfBaiTanSellSelectWidget.gameObject)
	
	self.onQueryHistoryButtonClick = function() self:OnQueryHistoryButtonClick() end
	self.Controls.m_ButtonQueryHistory.onClick:AddListener(self.onQueryHistoryButtonClick)
	
end

-- 显示窗口
function BaiTanSellWidget:ShowWidget()
	
	UIControl.Show(self)
	--self.transform.gameObject:SetActive(true)
	
	self.m_BaiTanSellStallWidget:ShowWidget()
	self.m_BaiTanSellSelectWidget:ShowWidget()
	
end

-- 隐藏窗口
function BaiTanSellWidget:HideWidget()
	
	UIControl.Hide(self, false)
	--self.transform.gameObject:SetActive(false)
	
end

-- 查询历史按钮的点击行为
function BaiTanSellWidget:OnQueryHistoryButtonClick()
	
	IGame.ExchangeClient:RequestQueryExchangeLog()
	
end

-- 上架物品回包事件处理
function BaiTanSellWidget:HandleNet_OnPutGoods()
	
	self.m_BaiTanSellStallWidget:UpdateWidget()
	self.m_BaiTanSellSelectWidget:UpdateWidget()
	
end

-- 下架物品回包事件处理
function BaiTanSellWidget:HandleNet_OnDownGoods()
	
	self.m_BaiTanSellStallWidget:UpdateWidget()
	self.m_BaiTanSellSelectWidget:UpdateWidget()
	
end

-- 收到摊位数据通知处理
function BaiTanSellWidget:HandleNet_OnStallDataNotice()
	
	self.m_BaiTanSellStallWidget:UpdateWidget()
	self.m_BaiTanSellSelectWidget:UpdateWidget()
	
end

-- 出售界面摊位选中事件处理
-- @stallId:摊位id:long
function BaiTanSellWidget:HandleUI_SellStallItemSelected(stallId)
	
	self.m_BaiTanSellStallWidget:ChangeTheSelectedStall(stallId)
	
end

-- 出售界面摆摊背包格子选中处理
-- @entityUid:选中的实体uid:long
function BaiTanSellWidget:HandleUI_SellPacketCellSelected(entityUid)
	
	self.m_BaiTanSellSelectWidget:ChangeTheSelectCell(entityUid)
	
end


function BaiTanSellWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function BaiTanSellWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BaiTanSellWidget:CleanData()
	self.Controls.m_ButtonQueryHistory.onClick:RemoveListener(self.onQueryHistoryButtonClick)
	self.onQueryHistoryButtonClick = nil
end

return BaiTanSellWidget