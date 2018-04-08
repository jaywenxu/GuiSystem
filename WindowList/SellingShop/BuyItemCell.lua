--购买物品Cell
local BuyItmCell= UIControl:new
{
	windowName = "BuyItmCell",
	m_itemID = nil,
}

function BuyItmCell:Attach(obj)
	UIControl.Attach(self,obj)
	self.OnClickBuyFun = function() self:OnClickBuyBtn() end
	self.Controls.m_buyBtn.onClick:AddListener(self.OnClickBuyFun)
	return self
end

--点击购买按钮
function BuyItmCell:OnClickBuyBtn()
	
end



--初始化并且刷新UI
function BuyItmCell:InitRefreshUI(info)
	self.m_itemID = info.id
end


------------------------------------------------------------
function MyTeamRoleCell:OnRecycle()
	
	self.unityBehaviour.onEnable:RemoveListener(self.OnClickBuyFun) 
	
end