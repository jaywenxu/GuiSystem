-- 技能复活窗口

local SkillReliveWindow = UIWindow:new
{
	windowName        = "SkillReliveWindow",
	
	m_BtnCnt          = 2,
	m_Content         = "",

	m_CancelBtnTxt    = "取消",
	m_ConfirmBtnTxt    = "确认",
	
	m_ConfirmCallBack = nil,
	m_CancelCallBack  = nil,
}

----------------------------------------------------------------
function SkillReliveWindow:Init()
	self.callback_OnTimerCountDown = function() self:OnTimerCountDown() end
end

function SkillReliveWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls

 	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
 	controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCancelClicked))
 	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
 	controls.m_SingleConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))

 	self:UpdateUI()
end

function SkillReliveWindow:UpdateUI()
	local controls = self.Controls
	
	controls.m_ContentTxt.text = self.m_Content

	controls.m_ConfirmBtnTxt.text = self.m_ConfirmBtnTxt
	controls.m_CancelBtnTxt.text = self.m_CancelBtnTxt.."("..self.countDown..")"

	controls.m_SingConfBtnTxt.text = self.m_ConfirmBtnTxt

	local bIsDoubleBtn = self.m_BtnCnt == 2
	controls.m_CancelBtn.gameObject:SetActive(bIsDoubleBtn)
	controls.m_ConfirmBtn.gameObject:SetActive(bIsDoubleBtn)

	controls.m_SingleConfirmBtn.gameObject:SetActive(not bIsDoubleBtn)

end

function SkillReliveWindow:OnBtnCloseClicked()
	rktTimer.KillTimer(self.callback_OnTimerCountDown)
	self:Hide()
end

function SkillReliveWindow:OnBtnCancelClicked()
	if self.m_CancelCallBack ~= nil then
		self.m_CancelCallBack()
	end

	self:OnBtnCloseClicked()
end

function SkillReliveWindow:OnBtnConfirmClicked()
	if self.m_ConfirmCallBack ~= nil then
		self.m_ConfirmCallBack()
	end

	self:OnBtnCloseClicked()
end

----------------------------------------------------------------
--[[
@purpose	：显示确认弹出框
@param ：
data = {
		btnCnt 			: 按钮个数，默认为2
		content 		: 内容
		confirmBtnTxt   ：确认按钮文本
		cancelBtnTxt 	：取消按钮文本
		confirmCallBack : 确认按钮回调，不传默认关闭弹框
		cancelCallBack 	: 取消按钮回调，不传默认关闭弹框
}
]]
function SkillReliveWindow:ShowDiglog(data)
	UIWindow.Show(self, true)

	self.countDown = data.countDown or 25
	
	self.m_BtnCnt = data.btnCnt or 2
	self.m_Content = data.content or ""

	self.m_ConfirmBtnTxt = data.confirmBtnTxt or "确认"
	self.m_CancelBtnTxt = data.cancelBtnTxt or "取消"
	
	self.m_ConfirmCallBack  = data.confirmCallBack
	self.m_CancelCallBack   = data.cancelCallBack
	
	rktTimer.KillTimer(self.callback_OnTimerCountDown)
	rktTimer.SetTimer(self.callback_OnTimerCountDown, 1000, self.countDown + 5, "SkillReliveWindow:ShowDiglog")

	if not self:isLoaded() then
		return 
	end

	self:UpdateUI()
end

function SkillReliveWindow:OnTimerCountDown()
	self.countDown = self.countDown - 1
	if self.countDown < 0 then
		self:OnBtnCloseClicked()
		return
	end
	
	self.Controls.m_CancelBtnTxt.text = self.m_CancelBtnTxt.."("..self.countDown..")"
end

return SkillReliveWindow
