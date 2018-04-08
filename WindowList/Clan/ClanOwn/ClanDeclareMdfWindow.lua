-- 帮派申明修改界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-08 17:59:16

local ClanDeclareMdfWindow = UIWindow:new
{
	windowName        = "ClanDeclareMdfWindow",
}

------------------------------------------------------------
function ClanDeclareMdfWindow:Init()
end

function ClanDeclareMdfWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))

	local inputField = controls.m_ChatInput:GetComponent(typeof(InputField))
	inputField.onValueChanged:AddListener(handler(self, self.OnInputFieldChanged))
 	controls.inputField = inputField

 	self:OnInputFieldChanged()
end


function ClanDeclareMdfWindow:OnBtnCloseClicked()
	self:Hide()
end


function ClanDeclareMdfWindow:OnInputFieldChanged()
	local controls = self.Controls
	local inputField = controls.inputField
	local leftLen = inputField.characterLimit - inputField:GetInputWordsLength()
	controls.m_InputLeftTxt.text = string.format("还可编辑%d个字",  math.floor(leftLen * 0.5)) 
end

function ClanDeclareMdfWindow:OnBtnConfirmClicked()
	local txt = self.Controls.inputField.text
	if IsNilOrEmpty(txt) then
		print("error! the input cannot equal nil")
		return 
	end

	IGame.ClanClient:MotifyRequest(emClanManifesto, txt)
end



return ClanDeclareMdfWindow
------------------------------------------------------------

