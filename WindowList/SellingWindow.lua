--xwj 2017-06-06

--摆摊窗口
local SellingWindow=UIWindow:new
{
	
	windowName = "SellingWindow",
	m_WantToBuyWidget = nil,
	m_WantToSellWidget = nil,
	m_WantToShowWidget = nil,
	m_tableType={
		m_table_type_buy=0,
		m_table_type_sell=1,
		m_table_type_show=2,
	}
	
}

--加载子模块
function SellingWindow:Init()
	self.m_WantToBuyWidget = require("GuiSystem.WindowList.SellingShop.WantToBuyWidget")
	self.m_WantToSellWidget = require("GuiSystem.WindowList.SellingShop.WantToSellWidget")
	self.m_WantToShowWidget = require("GuiSystem.WindowList.SellingShop.WantToShowWidget")
	self.Controls.m_BuyToggle.onValueChanged:AddListener(function(on) self:OnClickTab(self.m_tableType.m_table_type_buy,on) end)
	self.Controls.m_SellToggle.onValueChanged:AddListener(function(on)self:OnClickTab(self.m_tableType.m_table_type_sell,on) end)
	self.Controls.m_ShowToggle.onValueChanged:AddListener(function(on)self:OnClickTab(self.m_tableType.m_table_type_show,on)end)
	self.Controls.m_OnClickCloseBtn.onClick:AddListener(function() self:Hide(false) end)
end

function SellingWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	return self
end

--点击窗口标签页
function SellingWindow:OnClickTab(tabeType,on)
	if nil == self.m_WantToBuyWidget.transform or 
		nil == self.m_WantToSellWidget.transform or 
		nil == self.m_WantToShowWidget.transform then 
		return 
		end
	if true == on then 
		if tabeType == self.m_tableType.m_table_type_buy then
			
		elseif tabeType == self.m_tableType.m_table_type_sell then 
			
		elseif tabeType == self.m_tableType.m_table_type_show then 
			 
		end
		
	else
		
	end

end