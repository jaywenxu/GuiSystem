--------------------------------------------------------------------
--------------------------确认购买----------------------------
local ChipConfirmWidget = UIControl:new
{
	windowName 	= "ChipConfirmWidget",
}

local this = ChipConfirmWidget

function ChipConfirmWidget:Init()

end

function ChipConfirmWidget:Attach(obj)
	UIControl.Attach(self,obj)	
		
	
	self.callback_OnConfirmClick = function(on) self:OnConfirmClick(on) end
	self.Controls.m_ButtonConfirm.onClick:AddListener(self.callback_OnConfirmClick)
	
	self.callback_OnCancleClick = function(on) self:OnCancleClick(on) end
	self.Controls.m_ButtonCancel.onClick:AddListener(self.callback_OnCancleClick)
	
	self.Controls.m_ButtonClose.onClick:AddListener(self.callback_OnCancleClick)
	
	return self
end

--------------------------------------------------------------------------------
-- 点击确认按钮 触发事件
--------------------------------------------------------------------------------
function ChipConfirmWidget:OnConfirmClick()
	
	local npcID		= IGame.ChipExchangeClient:GetCurExchangeNpcID()
	local exchID 	= UIManager.ChipExchangeWindow:GetExchid()
	-- 物品品阶
	local prizeid   = UIManager.ChipExchangeWindow:GetPrizeid()
	-- 是否只允许非绑资源
	local useUnBind = UIManager.ChipExchangeWindow:GetuseUnBind()
	local num 		= UIManager.ChipExchangeWindow:GetInputFieldNum()
	
	
	if 0 == num then 
		return 
	end

	GameHelp.PostServerRequest("RequestChipExchange("..exchID..","..prizeid..","..num..","..useUnBind..","..npcID..","..npcID..")")
	UIManager.ChipExchangeWindow:SetHintVisible(false)
	
end



--------------------------------------------------------------------------------
-- 点击取消按钮 触发事件
--------------------------------------------------------------------------------
function ChipConfirmWidget:OnCancleClick()
	
	UIManager.ChipExchangeWindow:SetHintVisible(false)	
end


function ChipConfirmWidget:OnDestroy()	
	UIControl.OnDestroy(self)
end

return this