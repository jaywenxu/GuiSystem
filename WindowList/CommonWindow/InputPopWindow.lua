
--通用输入确认框，如有需要，扩展它
local InputPopWindow = UIWindow:new
{
	windowName        = "InputPopWindow",
	m_ConfirmCallBack = nil,			--确认点击回调

	m_Content = "",
	m_TitlePath = "",
	m_MaxLimit = 100,				--最大字符限制
	m_MinLimit = 1,					--最小字符限制
}

function InputPopWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls

 	controls.m_BGMaskBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
 	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	self.inputComponent = controls.m_InputFieldTrans:GetComponent(typeof(InputField))
	self.inputComponent.onValueChanged:AddListener(handler(self, self.OnInputValueChange))
	
	self.LateUpdateUI = function() self:UpdateUI() end
	
 	self:UpdateUI()
end

function InputPopWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

--关闭界面
function InputPopWindow:OnBtnCloseClicked()
	self:Hide()
end

--确认按钮点击回调
function InputPopWindow:OnBtnConfirmClicked()
	if self.m_ConfirmCallBack ~= nil then
		local inputStr = self.inputComponent.text
		local length = utf8.wchar_size(inputStr)
		if length > self.m_MaxLimit then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "输入过长，请重新输入")
			return
		elseif length < self.m_MinLimit then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "输入过短，请重新输入")
			return
		end
		self.m_ConfirmCallBack(inputStr)
	end

	self:OnBtnCloseClicked()
end

--输入改变回调，字符限制, todo
function InputPopWindow:OnInputValueChange()
	local length = utf8.wchar_size(self.inputComponent.text)
	if length > self.m_MaxLimit then
		self.inputComponent.text = self.InputText
		return
	end
	self.InputText = self.inputComponent.text
end

function InputPopWindow:UpdateUI()
	UIFunction.SetImageSprite(self.Controls.m_TitleImg, self.m_TitlePath)
	self.inputComponent.characterLimit = self.m_MaxLimit
	self.Controls.m_ContentLabel.text = self.m_Content
	self.inputComponent.text = ""
end


----------------------------------------------------------------
--[[
@purpose	：显示确认弹出框
@param ：
data = {
		title			: 标题资源路径
		confirmCallBack : 确认按钮回调，不传默认关闭弹框
		content			: 内容
		maxLimit		: 最大字符限制
		minLimit		: 最小字符限制
}
]]
function InputPopWindow:ShowDiglog(data)
	UIWindow.Show(self, true)
	
	self.m_TitlePath = data.title or AssetPath.TextureGUIPath.."Common_frame/Common_mz_tishi.png"
	self.m_ConfirmCallBack = data.confirmCallBack
	self.m_Content = data.content
	self.m_MaxLimit = data.maxLimit
	self.m_MinLimit = data.minLimit or 1
	
	if self:isLoaded() then
		self:UpdateUI()
	else
		--rktTimer.SetTimer(self.LateUpdateUI, 60, -1 ,"InputPopWindow:UpdateUI()")
	end
end

return InputPopWindow