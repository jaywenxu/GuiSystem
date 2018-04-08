-- 提示窗口
------------------------------------------------------------
local ExtendedConfirmWindow = UIWindow:new
{
	windowName = "ExtendedConfirmWindow",
	m_LableUp = "",
	m_LableBottom = "",
	m_ConfirmCallBack = nil,
}
------------------------------------------------------------
function ExtendedConfirmWindow:Init()
	self.m_LableUp = ""
	self.m_LableBottom = ""
	self.m_ConfirmCallBack = nil
end
------------------------------------------------------------
function ExtendedConfirmWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.Controls.m_CloseBtn.onClick:AddListener(function() self:OnBtnCloseClick() end)
	self.Controls.m_ConfirmBtn.onClick:AddListener(function() self:OnConfirmBtnClick() end)
	UIFunction.AddEventTriggerListener( self.transform , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end )
    self:Refresh()
end
------------------------------------------------------------
function ExtendedConfirmWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

-- 关闭按钮
function ExtendedConfirmWindow:OnBtnCloseClick()
	self:Init()
    self:Hide()
end

-- 确认按钮
function ExtendedConfirmWindow:OnConfirmBtnClick()
	if self.m_ConfirmCallBack then
		self.m_ConfirmCallBack()
		self.m_ConfirmCallBack = nil
	end
    self:OnBtnCloseClick()
end

function ExtendedConfirmWindow:OnCloseButtonClick(eventData)
	 self:OnBtnCloseClick()
end

function ExtendedConfirmWindow:Refresh()
	if not self:isLoaded() then
		return
	end
	
	self.Controls.m_NowLv.text = self.InfoTable.NowLv
	self.Controls.m_NextLv.text = self.InfoTable.NextLv
	self.Controls.m_NowProp.text = self.InfoTable.NowProp
	self.Controls.m_NextProp.text = self.InfoTable.NextProp
	self.Controls.m_Text.text = self.InfoTable.Text
end
--[[
function ExtendedConfirmWindow:ShowWindow(LableUp,LableBottom,callback_func)
	UIWindow.Show(self, true)
	self.m_LableUp = LableUp
	self.m_LableBottom = LableBottom
	self.m_ConfirmCallBack = callback_func
	self:Refresh()
end
--]]
function ExtendedConfirmWindow:ShowWindow(InfoTable,callback_func)
	UIWindow.Show(self, true)
	self.InfoTable = InfoTable
	self.m_ConfirmCallBack = callback_func
	self:Refresh()
end

return ExtendedConfirmWindow