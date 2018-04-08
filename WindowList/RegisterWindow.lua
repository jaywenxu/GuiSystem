------------------------------------------------------------
local RegisterWindow = UIWindow:new
{
	windowName = "RegisterWindow" ,
}
local this = RegisterWindow   -- 方便书写
------------------------------------------------------------
function RegisterWindow:Init()

end
------------------------------------------------------------
function RegisterWindow:OnAttach( obj )
	print( "RegisterWindow.Attach" )
	UIWindow.OnAttach(self,obj)
--[[	self.Controls.btnLogin = self.transform:Find( "LoginButton" ):GetComponent(typeof(Button))
	self.calbackLoginButtonClick = function() self:OnLoginButtonClick() end
	self.Controls.btnLogin.onClick:AddListener( self.calbackLoginButtonClick )
	
	self.Controls.btnAccount = self.transform:Find( "AccountButton" ):GetComponent(typeof(Button))
	self.calbackAccountButtonClick = function() self:OnAccountButtonClick() end
	self.Controls.btnAccount.onClick:AddListener( self.calbackAccountButtonClick )
	
	self.Controls.btnAnnouncement = self.transform:Find( "AnnouncementButton" ):GetComponent(typeof(Button))
	self.calbackAnnouncementButtonClick = function() self:OnAnnouncementButtonClick() end
	self.Controls.btnAnnouncement.onClick:AddListener( self.calbackAnnouncementButtonClick )
	--]]
	--self.Controls.inputAccount = self.transform:Find( "LoginModule/InputFieldAccount" ):GetComponent(typeof(InputField))
	--self.Controls.inputPassword = self.transform:Find( "LoginModule/InputFieldPassword" ):GetComponent(typeof(InputField))
    return self
end
------------------------------------------------------------
function RegisterWindow:OnLoginButtonClick()
	print( "login button clicked" )
end

------------------------------------------------------------
function RegisterWindow:OnAccountButtonClick()
	print( "account button clicked" )
end

------------------------------------------------------------
function RegisterWindow:OnAnnouncementButtonClick()
	print( "announcement button clicked" )
end
------------------------------------------------------------
function RegisterWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
return this
