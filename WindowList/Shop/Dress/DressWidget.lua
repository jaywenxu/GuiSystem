

local DressWidget = UIControl:new {
	windowName = "DressWidget",
	
}

function DressWidget:Attach(obj)
	UIControl.Attach(self,obj)

	self.ExteriorTypeWidget = require("GuiSystem.WindowList.Shop.Dress.ExteriorTypeWidget")
	
	self.ExteriorTypeWidget:Attach(self.Controls.m_ExteriorTypeWidget.gameObject)
end

function DressWidget:Show()
	UIControl.Show(self)
	
	self.ExteriorTypeWidget:Show()
--	self.ExteriorTypeWidget:SetDefaultTab(1)
end

function DressWidget:Hide(destroy)
	UIControl.Hide(self)
end

return DressWidget