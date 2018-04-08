--主界面组队按钮下的面板
---------------------------------------------------------------
---------------------------------------------------------------
local TeamPanelWidget = UIControl:new
{
	windowName = "TeamPanelWidget" ,	
	updateInterval = 10,	
}
---------------------------------------------------------------
function TeamPanelWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.callback_OnCreateTeamButtonClick = function() TeamPanelWidget:OnCreateTeamButtonClick() end
	self.Controls.m_CreateTeamBtn.onClick:AddListener(self.callback_OnCreateTeamButtonClick)
	self.callback_OnFindTeamButtonClick = function() TeamPanelWidget:OnFindTeamButtonClick() end
	self.Controls.m_FindTeamBtn.onClick:AddListener(self.callback_OnFindTeamButtonClick)
	
	--队伍的创建队伍事件注册
	self.CreateTeam = function(event, srctype, srcid, eventData) self:OnCreateTeam(event, srctype, srcid, eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0 , self.CreateTeam)

	return self
end
---------------------------------------------------------------
function TeamPanelWidget:OnDestroy()
	--队伍的创建队伍注销
	self.Controls.m_CreateTeamBtn.onClick:RemoveListener(self.callback_OnCreateTeamButtonClick)
	self.Controls.m_FindTeamBtn.onClick:RemoveListener(self.callback_OnFindTeamButtonClick)
	
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , self.teamID , self.CreateTeam)
	
	UIControl.OnDestroy(self)
end
---------------------------------------------------------------



------------------------------------------------------------
function TeamPanelWidget:OnCreateTeam(event, srctype, srcid, eventData) 
	local oldTeamID = eventData.nOldTeamID
	if UIManager.TeamWindow:isShow() then 
		UIManager.TeamWindow:CreateMyTeamPanel()
		UIManager.TeamWindow:RefreshMyTeam()
	end
	if self:isShow() then 
		self:Hide()
		UIManager.TeamShowPanelWindow:Show()
	end

	
end 
------------------------------------------------------------

--创建组队按钮按下
function TeamPanelWidget:OnCreateTeamButtonClick()
	
	local MyTeam = IGame.TeamClient:GetTeam()
    if MyTeam == nil then return end 
    
	if MyTeam:GetTeamID() == INVALID_TEAM_ID then
		--向服务器发送创建队伍的申请消息，默认TargetID 为0，等级为1-100级
		IGame.TeamClient:CreateTeam()
		UIManager.TeamWindow:Show(true)
		UIManager.TeamWindow:CreateMyTeamPanel()
		self:Hide()
	else
		IGame.TeamClient:LeaveTeam()
	end

end

--寻找组队按钮按下
function TeamPanelWidget:OnFindTeamButtonClick() 
	UIManager.TeamWindow:Show()
end
---------------------------------------------------------------
return TeamPanelWidget

