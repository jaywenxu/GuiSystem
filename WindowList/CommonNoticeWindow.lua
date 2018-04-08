

-- 通用提示信息窗口

------------------------------------------------------------
local CommonNoticeWindow = UIWindow:new
{
	windowName = "CommonNoticeWindow" ,
    m_szContent = ""
}
------------------------------------------------------------
function CommonNoticeWindow:Init()
	
end
------------------------------------------------------------
function CommonNoticeWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self:AddListener( self.Controls.CloseButton , "onClick" , self.OnCloseBtnClick , self )
    if not IsNilOrEmpty(self.m_szContent) then
        self.Controls.NoticeText.text = self.m_szContent
    end
end
------------------------------------------------------------
function CommonNoticeWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

function CommonNoticeWindow:OnCloseBtnClick()
	self.m_szContent = ""
	self:Hide()
end

-- 显示提示信息
function CommonNoticeWindow:ShowNotice(szContent)
    self.m_szContent = szContent
    if not self:isLoaded() then
        return
    end
	self.Controls.NoticeText.text = self.m_szContent
end

return CommonNoticeWindow
