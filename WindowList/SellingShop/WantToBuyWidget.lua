
--我要购买
local WantToBuyWidget= UIControl:new
{
	windowName = "PlayerEquipWidget",
}

function WantToBuyWidget:Attach(obj)
	UIControl.Attach(self,obj)
	self.m_enhanceListView = self.Controls.m_ItemListScroller:GetComponent(typeof(EnhancedListView))
	return self
end