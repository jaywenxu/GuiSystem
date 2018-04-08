--邀请组队窗口
---------------------------------------------------
local TeamInvitedRespondWindow = UIWindow:new
{
	windowName = "TeamInvitedRespondWindow" ,
	m_info = nil,
}
---------------------------------------------------
function TeamInvitedRespondWindow:Init()
end
---------------------------------------------------
function TeamInvitedRespondWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.Controls.m_RefuseButton.onClick:AddListener(function() self:RefuseButtonClick() end)
	self.Controls.m_AcceptButton.onClick:AddListener(function() self:AcceptButtonClick() end)
	self.Controls.m_CloseButton.onClick:AddListener(function() self:CloseWindow() end)
	self:RefreshUI()
	return self
end
---------------------------------------------------
function TeamInvitedRespondWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

function TeamInvitedRespondWindow:InitInfo(info)
	self.m_info = info
	if self:isLoaded() then
		self:RefreshUI()
	end
end

function TeamInvitedRespondWindow:RefreshUI()
	if self.m_info ~= nil then 
		self.Controls.m_InvitedInfoText.text = self.m_info.szInviterName .."邀请你加入".. self.m_info.szCaptainName.."的队伍"
	end
end

function TeamInvitedRespondWindow:RefuseButtonClick() 
	IGame.TeamClient:luaInvitedRespond(self.m_info.dwBuildingSN, EBuildFlowResult_Disagree)
	self:CheckHaveInvite()
end
---------------------------------------------------
function TeamInvitedRespondWindow:AcceptButtonClick() 

	IGame.TeamClient:luaInvitedRespond(self.m_info.dwBuildingSN, true)
	self:Hide(true)
--	self:CheckHaveInvite()
end

function TeamInvitedRespondWindow:CloseWindow()
	-- 品质说设置为拒绝
	IGame.TeamClient:luaInvitedRespond(self.m_info.dwBuildingSN, EBuildFlowResult_Disagree)
--	IGame.TeamClient:luaInvitedRespond(self.m_info.dwBuildingSN, EBuildFlowResult_Ignore)
	self:CheckHaveInvite()
end

function TeamInvitedRespondWindow:CheckHaveInvite()
	local info = IGame.TeamClient:GetNewInvitePersonInfo()
	if info == nil then 
		self:Hide(true)
	else
		self:InitInfo(info)
	end
end
---------------------------------------------------
return TeamInvitedRespondWindow
