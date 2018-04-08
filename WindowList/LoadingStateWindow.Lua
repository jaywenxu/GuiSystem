--------------LoadingStateWindow.lua---------------------------------------------
-- 版  权   : (C) 深圳冰川网络技术有限公司 2010 - All Rights Reserved
-- author   : 周加财
-- created  : 2017-12-27
-- purpose  : 登录状态窗口
-----------------------------------------------------------------------

------------------------------------------------------------
local LoadingStateWindow = UIWindow:new
{
	windowName = "LoadingStateWindow" ,
	mtext = "请稍等",
}
local this = LoadingStateWindow
------------------------------------------------------------
function LoadingStateWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self:ResfeshText()
end
------------------------------------------------------------
------------------------------------------------------------
function LoadingStateWindow:OnDestroy()
    UIWindow.OnDestroy(self)
   
end

------------------------------------------------------------
function LoadingStateWindow:ResfeshText()
	if self:isLoaded() then
		self.Controls.m_Text.text = self.mtext
	end
end
------------------------------------------------------------
function LoadingStateWindow:UpdateText( szText )
	self:Show()
	self.mtext = szText
	self:ResfeshText()
end
------------------------------------------------------------
------------------------------------------------------------
return LoadingStateWindow

