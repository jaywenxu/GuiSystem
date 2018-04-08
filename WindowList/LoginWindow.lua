--/******************************************************************
---** 文件名:	LoginWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	周加财
--** 日  期:	2017-01-07
--** 版  本:	1.0
--** 描  述:	登陆窗口
--** 应  用:  
--******************************************************************/

------------------------------------------------------------
local LoginWindow = UIWindow:new
{
	windowName = "LoginWindow" ,

	m_Server = nil,
}
local this = LoginWindow   -- 方便书写

local gEntryConfigUrl = "http://172.16.127.122/serverlist/entryconfig.json"
--local gEntryConfigUrl = "http://172.16.50.23/entryconfig.json"

------------------------------------------------------------
function LoginWindow:Init()

end
------------------------------------------------------------
function LoginWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	-- 销毁Launcher窗口
	local nLauncherBG = GameObject.Find("UILauncherCanvas")
	if nLauncherBG then nLauncherBG:GetComponent(typeof(DOTweenAnimation)):DORestart(true) end
	
	-- 登陆按钮
	self.calbackLoginButtonClick = function() self:OnLoginButtonClick() end
	self.Controls.m_loginBtn.onClick:AddListener( self.calbackLoginButtonClick )
	
	-- 公告按钮
	self.calbackAnnouncementButtonClick = function() self:OnAnnouncementButtonClick() end
	self.Controls.m_announceBtn.onClick:AddListener( self.calbackAnnouncementButtonClick )
    
	
	-- 注册按钮事件有两种方式，上面的为一种，下面的为另一种 m_SelectAreaBtn 为UIWindowBehavior
	-- 选择区域点击，即登陆的服务器区域
	self.calbackSelectAreaClick = function() self:OnSelectAreaClick() end
	self.Controls.m_SelectAreaBtn.onClick:AddListener( self.calbackSelectAreaClick )
    UIFunction.AddEventTriggerListener( self.Controls.m_SelectAreaBtn , EventTriggerType.PointerDown , function( eventData ) self:OnSelectAreaBtnPointDown(eventData) end )
    UIFunction.AddEventTriggerListener( self.Controls.m_SelectAreaBtn , EventTriggerType.PointerUp , function( eventData ) self:OnSelectAreaBtnPointUp(eventData) end )
	
	-- 账号按钮
	self.calbackAccountClick = function() self:OnAccountButtonClick() end
	self.Controls.m_AccountBtn.onClick:AddListener( self.calbackAccountClick )
	
	-- 用户协议
	self.calbackUserAgreementClick = function() self:OnUserAgreementClick() end
	self.Controls.m_UserAgreementBtn.onClick:AddListener( self.calbackUserAgreementClick )
	
	-- 账号关闭按钮
	self.calbackAccountCloseClick = function() self:OnAccountCloseClick() end
	self.Controls.m_AccountCloseBtn.onClick:AddListener( self.calbackAccountCloseClick )
	
	-- 账号注册按钮
	self.calbackAccountRegisterClick = function() self:OnAccountRegisterClick() end
	self.Controls.m_AccountRegisterBtn.onClick:AddListener( self.calbackAccountRegisterClick )
	
	-- 账号登陆按钮
	self.calbackAccountLoginClick = function() self:OnAccountLoginClick() end
	self.Controls.m_AccountLoginBtn.onClick:AddListener( self.calbackAccountLoginClick )
	
	-- 忘记账号按钮
	self.calbackForgetAccountClick = function() self:OnForgetAccountClick() end
	self.Controls.m_ForgetAccountBtn.onClick:AddListener( self.calbackForgetAccountClick )
	
	-- 忘记密码按钮
	self.calbackForgetPasswordClick = function() self:OnForgetPasswordClick() end
	self.Controls.m_ForgetPasswordBtn.onClick:AddListener( self.calbackForgetPasswordClick )
	
	self.RefrshSelectedServer = function() self:SetSelectedServer(nil) end
	rktEventEngine.SubscribeExecute( EVENT_REQUEST_SERVERLIST_SUCCEED , SOURCE_TYPE_SYSTEM, 0 ,self.RefrshSelectedServer)

	self:SetSelectedServer(nil)
	-- 登录账号按钮不置灰
	self:SetLoginButtonGray(false)

    -- 预加载上一次选择的角色
    IGame.SelectActorForm:PreloadLastSelectedRoleRes()
	
	self:playMusic()
    return self
end

function LoginWindow:Show(top)
	if self:isLoaded() then 
		self:playMusic()
	end
	UIWindow.Show(self,top)
end

function LoginWindow:Hide(destory)
	UIWindow.Hide(self,destory)
	--self:stopMusic()
end

--播放音效
function LoginWindow:playMusic()
	if self.bgMusic == nil then 
		self.bgMusic = SoundHelp.PlayMusicByConfigID(LOGIN_BG_AUDIO_ID)
	end

end

--停止播放音效
function LoginWindow:stopMusic()
	if self.bgMusic == nil then 
		return
	end
	SoundHelp.StopMusicByConfigID(LOGIN_BG_AUDIO_ID)
	self.bgMusic = nil
end

function LoginWindow:OnDestroy()
	rktEventEngine.UnSubscribeExecute( EVENT_REQUEST_SERVERLIST_SUCCEED , SOURCE_TYPE_SYSTEM, 0 ,self.RefrshSelectedServer)
--	self:stopMusic()
	self.bgMusic = nil
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
-- 账号界面显示或隐藏
------------------------------------------------------------
function LoginWindow:AccountShow(bShow)
	if not bShow then
		bShow = false
	else
		bShow = true
	end
	self.Controls.m_AccountWidget.gameObject:SetActive(bShow)
end

function LoginWindow:CheckUserInfo(info)

	if info == nil then
		uerror("LoginWindow:CheckUserInfo userinfo is nil")
		return false
	end
	if IsNilOrEmpty(info.account) or IsNilOrEmpty(info.pwd) 
	or IsNilOrEmpty(info.ip) or IsNilOrEmpty(info.port) then
		uerror("LoginWindow:CheckUserInfo userinfo is error table:",tableToString(info))
		return false
	end
	return true
end

-- 响应登陆按钮
------------------------------------------------------------
function LoginWindow:OnLoginButtonClick()

	print("LoginWindow:OnLoginButtonClick", luaGetTickCount())	
	if isTableEmpty(self.m_Server)  then 
		local data = {}
		data.content = "暂无服务器数据"
		UIManager.ConfirmPopWindow:ShowDiglog(data)
		return
	end

	local ipList = self.m_Server.ipList
	local data = ipList[1]
	if #ipList > 1 then
		local random = math.random(1, #ipList)
		data = ipList[random]
	end
	
	if IsNilOrEmpty(data.ip) or IsNilOrEmpty(data.port) then
		uerror("LoginWindow:CheckUserInfo ipData is error table:",tableToString(data))
		return
	end
	
	local userinfo = LoginApi_GetUserData()
	if IsNilOrEmpty(userinfo.account) then
		UIManager.CommonNoticeWindow:Show(true)
		UIManager.CommonNoticeWindow:ShowNotice("账号为空，请输入你的账号")
		return
	elseif IsNilOrEmpty(userinfo.pwd) then
		UIManager.CommonNoticeWindow:Show(true)
		UIManager.CommonNoticeWindow:ShowNotice("密码为空，请输入正确的密码")
		return
	end

	data.account = userinfo.account
	data.pwd = userinfo.pwd

	IGame.LoginForm:StartLoginClick(data)	

	LoginApi_SaveUserData(userinfo.account, userinfo.pwd, self.m_Server.serverID)

	rktRenderQualitySetting.CheckNotSetQualityLevel()

	-- 登录账号按钮设置置灰
	self:SetLoginButtonGray(true)
end

------------------------------------------------------------
-- 设置登录账号按钮状态
function LoginWindow:SetLoginButtonGray(bGray)
	
	if not self:isLoaded() then
		return
	end
	GameHelp:SetButtonGray(self.Controls.m_loginBtn.gameObject, bGray)
end
------------------------------------------------------------
function LoginWindow:SetSelectedServer(server)
	if not self:isLoaded() then 
		return
	end
	local s = "暂无服务器数据"
	if not server then
		server = IGame.HttpController:GetRecommendServer()
	end

	if server ~= nil then
		s = server.serverName
		self.m_Server = server
	end
	
	self.Controls.m_ServerNameText.text = s

end

-- 点击选择区域
------------------------------------------------------------
function LoginWindow:OnSelectAreaClick()
	--UIManager.ServerSelectWindow:Show()
end

function LoginWindow:OnSelectAreaBtnPointDown(eventData)
    self.mIsSelAreaBtnDown = true
    self.mBtnDownTime = Time.time
end

function LoginWindow:OnSelectAreaBtnPointUp(eventData)
    print("current:"..Time.time..', begin:'..self.mBtnDownTime)
    if not self.mIsSelAreaBtnDown or not self.mBtnDownTime or (Time.time -self.mBtnDownTime) < 3 then
        UIManager.ServerSelectWindow:Show()
        return
    end
    rkt.CLuaConnection.SendHttpMessage( gEntryConfigUrl , nil , LoginWindow.CallBackReqEntryConfig)
end

function LoginWindow.CallBackReqEntryConfig(text,err)
    if not IsNilOrEmpty(err) or IsNilOrEmpty(text) then
        UIManager.ServerSelectWindow:Show()
        return 
    end
    
    print('decode:'..gEntryConfigUrl)
    IGame.LoginForm.entryconfig = require('cjson').decode(text)
    UIManager.EntryConfigWindow:Show()
end

-- 响应公告按钮
------------------------------------------------------------
function LoginWindow:OnAnnouncementButtonClick()
	IGame.HttpController:RequestGonggao()
end

-- 响应账号按钮
------------------------------------------------------------
function LoginWindow:OnAccountButtonClick()
	-- 账号界面
	LoginWindow:AccountShow(true)
	
	local info = LoginApi_GetUserData()
	self.Controls.Input_EdtUserName:GetComponent(typeof(InputField)).text = info.account or ""
	self.Controls.Input_EdtPassword:GetComponent(typeof(InputField)).text = info.pwd or ""
end

-- 用户协议
function LoginWindow:OnUserAgreementClick()
	if not UIManager.UserAgreementWindow:isShow() then
		UIManager.UserAgreementWindow:ShowUserAgreement()
	end
end

-- 响应账号关闭按钮
------------------------------------------------------------
function LoginWindow:OnAccountCloseClick()
	LoginWindow:AccountShow(false)
end

-- 响应点击账号界面注册
------------------------------------------------------------
function LoginWindow:OnAccountRegisterClick()
	local data = {}
	data.content = "该功能后面开发...."
	UIManager.ConfirmPopWindow:ShowDiglog(data)
	LoginWindow:AccountShow(false)
end

-- 响应点击账号界面登陆
------------------------------------------------------------
function LoginWindow:OnAccountLoginClick()
	
	self.LastUserName = self.Controls.Input_EdtUserName:GetComponent(typeof(InputField)).text
	self.LastPassWord = self.Controls.Input_EdtPassword:GetComponent(typeof(InputField)).text
	if IsNilOrEmpty(self.LastUserName) or IsNilOrEmpty(self.LastPassWord ) then
		-- uerror("UserName or password is nil or empty") 这里应该弹窗提示用户,而不是打印log
		return
	end
	
	if self.m_Server then
		LoginApi_SaveUserData(self.LastUserName,self.LastPassWord, self.m_Server.serverID)
	end
	LoginWindow:AccountShow(false)
end

-- 响应忘记账号
------------------------------------------------------------
function LoginWindow:OnForgetAccountClick()
	local data = {}
	data.content = "账号找回功能后面开发...."
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

-- 响应忘记密码
------------------------------------------------------------
function LoginWindow:OnForgetPasswordClick()
	local data = {}
	data.content = "密码找回功能后面开发...."
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

-- 显示登陆信息
------------------------------------------------------------
function LoginWindow:ShowLoginTips(szContent,nWaring)
	if not self:isLoaded() then
		return
	end
	if nWaring then
		szContent = "<color=red>"..szContent.."</color>"
	else
		szContent = "<color=green>"..szContent.."</color>"
	end
	self.Controls.m_transTip.text = szContent
	self.Controls.m_transTip.transform.gameObject:SetActive(true)
end

-- 隐藏登陆信息
------------------------------------------------------------
function LoginWindow:HideLoginTips()
	if not self:isLoaded() then
		return
	end
	self.Controls.m_transTip.transform.gameObject:SetActive(false)
	self:SetLoginButtonGray(false)
end



------------------------------------------------------------
return this
