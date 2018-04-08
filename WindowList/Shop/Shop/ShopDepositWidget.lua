--------------------------------------------------------------------
--------------------------充值面板----------------------------
local ShopDepositWidget = UIControl:new
{
	windowName 	= "ShopDepositWidget",
}

local this = ShopDepositWidget

function ShopDepositWidget:Init()

end

function ShopDepositWidget:Attach(obj)
	UIControl.Attach(self,obj)	
		
	self.callback_OnConfirmClick = function(on) self:OnConfirmClick(on) end
	self.Controls.m_ButtonConfirm.onClick:AddListener(self.callback_OnConfirmClick)
	
	self.callback_OnCancleClick = function(on) self:OnCancleClick(on) end
	self.Controls.m_ButtonCancel.onClick:AddListener(self.callback_OnCancleClick)
end

--------------------------------------------------------------------------------
-- 点击确认按钮 触发事件
--------------------------------------------------------------------------------
function ShopDepositWidget:OnConfirmClick()
	--跳转到充值面板									TODO
	
	
	
end


--------------------------------------------------------------------------------
-- 点击取消按钮 触发事件
--------------------------------------------------------------------------------
function ShopDepositWidget:OnCancleClick()
	
	
end


function ShopDepositWidget:OnDestroy()	
	UIControl.OnDestroy(self)
end

return this