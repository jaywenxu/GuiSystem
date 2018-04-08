-- 好友、邮件界面
-- @Author: XieXiaoMei
-- @Date:   2017-05-11 20:32:35
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-30 10:17:52

local FriendEmailWindow = UIWindow:new
{
	windowName = "FriendEmailWindow",

	m_TabToggles = {},
	m_WidgetObjs = {},
	m_TabWidgets = {},
	--m_TabTglTxts = {},
	m_CurTglIdx = 0,
	m_JumpToIdx = 1,
	m_PrivateTag = false
}

-- 右侧tab toggles
local TabToggles = 
{
	["Friend"] = 1,
	["Email"]  = 2 ,
}

-- 右侧子窗口lua文件名
local TabWdtLuaFiles =  
{
	[1] = "FriendWidget" ,
	[2] = "EmailWidget",
}

-- 子窗口lua文件路径
local WdtLuaFilePath = "GuiSystem.WindowList.FriendEmail."

local this = FriendEmailWindow

function FriendEmailWindow:Init()
end


function FriendEmailWindow:OnAttach( obj )
	UIWindow.OnAttach(self, obj)

	self.m_CurTglIdx = 0
	self.m_JumpToIdx = 1
	self.m_PrivateTag = false

	self:InitUI()

	-- self.m_TabToggles[TabToggles.Email].isOn = true
	self.m_TabToggles[TabToggles.Friend].isOn = true

	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,
	 REDDOT_UI_EVENT_FRIEND_EMAIL, self.RefreshRedDot, self)
end


function FriendEmailWindow:OnDestroy()
	rktEventEngine.UnSubscribeExecute( EVENT_UI_REDDOT_UPDATE , SOURCE_TYPE_SYSTEM , 
		REDDOT_UI_EVENT_FRIEND_EMAIL, self.RefreshRedDot, self )

	UIWindow.OnDestroy(self)
	
	table_release(self)
end


function FriendEmailWindow:InitUI()
	local controls = self.Controls

	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))

	--[[self.m_TabTglTxts = {
		controls.m_FriendTglTxt,
		controls.m_EmailTglTxt,
	}--]]
	
	self.m_TabToggles = {
		controls.m_FrientTgl,
		controls.m_EmailTgl,
	}

	self.m_WidgetObjs = {
		controls.m_FriendWidget,
		controls.m_EmailWidget,
	}

	for i=1, 2 do
		local tgl = self.m_TabToggles[i]
		tgl.onValueChanged:AddListener(function (on)
			self:OnTogglesChanged(i, on)
		end)
	end
end

-- 设置标题栏的子窗口title和icon图片
function FriendEmailWindow:SetTitleIconImg(iconImgPath, titleImgPath)
	local controls = self.Controls

	local SetImgSprite = function (img, path)
		UIFunction.SetImageSprite(img, path, function ()
			if img ~= nil then
				img:SetNativeSize()
			end
		end)
	end

	SetImgSprite(controls.m_TitleImg, iconImgPath)
	--SetImgSprite(controls.m_WdtIconImg, titleImgPath)
end

function FriendEmailWindow:OnTogglesChanged(idx, on)
	if self.m_PrivateTag then 
		self.m_PrivateTag = false 
		return
	end

	local tabWdt = self.m_TabWidgets[idx]
	if not tabWdt then
		tabWdt = require( WdtLuaFilePath .. TabWdtLuaFiles[idx]):new()
		tabWdt:Attach(self.m_WidgetObjs[idx].gameObject)

		self.m_TabWidgets[idx] = tabWdt
		
		if nil ~= self.m_TabWidgets[idx].m_JumpToIdx then
			self.m_TabWidgets[idx].m_JumpToIdx = self.m_JumpToIdx
			self.m_JumpToIdx = 1
		end
	end

	if on then
		tabWdt:Show()
		self.m_CurTglIdx = idx
	else
		tabWdt:Hide()
	end
end

function FriendEmailWindow:OnBtnCloseClicked()
	self:Hide()
end

-- 当前是邮件切页显示
function FriendEmailWindow:IsMailWidgetShow()
	return self.m_CurTglIdx == TabToggles.Email
end

function FriendEmailWindow:IsFriendWidgetShow()
	return self.m_CurTglIdx == TabToggles.Friend
end

function FriendEmailWindow:Show( bringTop)
	UIWindow.Show(self, bringTop)
	if not self:isLoaded() then
		return
	end

	self:ShowUI()
end

function FriendEmailWindow:ShowUI()
	local tabWdt = self.m_TabWidgets[self.m_CurTglIdx]
	if not tabWdt:isShow() then
		tabWdt:Show()
		local otherIdx = 3-self.m_CurTglIdx
		self.m_TabWidgets[otherIdx]:Hide()
	end
	
	if nil ~= self.m_TabWidgets[TabToggles.Friend] then
		self.m_TabWidgets[TabToggles.Friend].m_JumpToIdx = self.m_JumpToIdx
		self.m_JumpToIdx = 1
	end
	
	if self:IsFriendWidgetShow() then
		if not self.m_TabWidgets[TabToggles.Friend].m_TabToggles[1].isOn then
			self.m_TabWidgets[TabToggles.Friend].m_TabToggles[1].isOn = true
		else
			self.m_TabWidgets[self.m_CurTglIdx]:RefreshUI()
		end
	else
		self.m_TabWidgets[self.m_CurTglIdx]:RefreshUI()
	end
	
	self:RefreshRedDot()
end

function FriendEmailWindow:Hide(destory)
	UIWindow.Hide(self)
	
	if UIManager.RichTextWindow:isShow() then UIManager.RichTextWindow:Hide() end
	if UIManager.ChatHistoryWindow:isShow() then UIManager.ChatHistoryWindow:Hide() end
end

-- 刷新红点标记
function FriendEmailWindow:RefreshRedDot(_, _, _, evtData)
	local redDotObjs = 
	{
		["邮件"] = self.m_TabToggles[TabToggles.Email],
		["好友"] = self.m_TabToggles[TabToggles.Friend]
	}

	SysRedDotsMgr.RefreshRedDot(redDotObjs, "FriendEmail", evtData)
end

function FriendEmailWindow:OnPrivateChat(playerID)
	local idx = IGame.FriendClient:GetIdxByPDBID(playerID)
	if idx > 0 then
		self.m_JumpToIdx = idx
	else
		IGame.FriendClient:OnRequestToChat(playerID)	
		self.m_JumpToIdx = 1
	end
	self.m_CurTglIdx = 1
	if not self.m_TabToggles[TabToggles.Friend] then
		self:Show(true)
		return
	end
	self:Show(true)
	if self.m_TabToggles[TabToggles.Friend].isOn then
		return
	end
	
	self.m_PrivateTag = true
	self.m_TabToggles[TabToggles.Friend].isOn = true
end

return FriendEmailWindow