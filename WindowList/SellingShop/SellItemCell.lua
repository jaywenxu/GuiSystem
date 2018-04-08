--出售物品Cell
local SellItemCell= UIControl:new
{
	windowName = "SellItemCell",
}


function SellItemCell:Attach(obj)
	UIControl.Attach(self,obj)
	self.OnClickItemFun = function() self:OnClickItem() end
	self.Controls.OnClickIteam.onClick:AddListener(self.OnClickItemFun)
end

function SellItemCell:OnClickItem()

end

------------------------------------------------------------
function SellItemCell:OnRecycle()
	
	self.unityBehaviour.onEnable:RemoveListener(self.OnClickItemFun) 
	
end