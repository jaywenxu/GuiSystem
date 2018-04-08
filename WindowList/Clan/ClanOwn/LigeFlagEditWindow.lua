-- 领地旗帜编辑界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-26 18:20:57

local LigeFlagEditWindow = UIWindow:new
{
	windowName        = "LigeFlagEditWindow",

	m_SelColorID 	  = 1, --选中的颜色ID
}

------------------------------------------------------------
-- 初始化
function LigeFlagEditWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))

	local inputField = controls.m_InputField:GetComponent(typeof(InputField))
	inputField.onValueChanged:AddListener(handler(self, self.OnInputFieldChanged))
 	controls.inputField = inputField

 	for i=1, 8 do -- 8种颜色
 		local colorTf = controls.m_Colors:Find("Color"..i )
 		local tgl = colorTf:GetComponent(typeof(Toggle))
		tgl.onValueChanged:AddListener(function(on) 
			if not on then return end

			self.m_SelColorID = i

			local imgPath = ClanSysDef.LigeanceTexturePath .. ClanSysDef.LigeanceFlagPngs[i]
 			UIFunction.SetImageSprite(controls.m_FlagImg, imgPath)
		end)
 	end

 	self.Controls.m_FlagTxt.text = ""
end

------------------------------------------------------------
-- 输入框改变回调
function LigeFlagEditWindow:OnInputFieldChanged()
	local controls = self.Controls
	controls.m_FlagTxt.text = controls.inputField.text
end

------------------------------------------------------------
-- 关闭按钮回调
function LigeFlagEditWindow:OnBtnCloseClicked()
	self:Hide()
end

------------------------------------------------------------
-- 确定按钮回调
function LigeFlagEditWindow:OnBtnConfirmClicked()
	local txt = self.Controls.inputField.text
	if IsNilOrEmpty(txt) then
		print("error! the input cannot equal nil")
		return 
	end

	if IsChinese_utf8(txt, 1) then --一个汉字
		IGame.Ligeance:RequestSetBanner(self.m_SelColorID, txt)
	else
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "帮会旗帜只能输入一个汉字")
	end
end

------------------------------------------------------------

return LigeFlagEditWindow


