--邀请组队中朋友项
------------------------------------------------------------
local MyTeamInviteFriendCell = UIControl:new
{
	windowName = "MyTeamInviteFriendCell" ,
	m_Entity = nil,
}
------------------------------------------------------------
function MyTeamInviteFriendCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.callback_OnInviteButtonClick = function() self:OnInviteButtonClick() end
	self.Controls.m_InviteButton.onClick:AddListener(self.callback_OnInviteButtonClick)
	
	return self
end
-------------------------------------------------------------
function MyTeamInviteFriendCell:OnDestroy()
	
	self.Controls.m_InviteButton.onClick:RemoveListener(self.callback_OnInviteButtonClick)
	UIControl.OnDestroy(self)
end
------------------------------------------------------------
--刷新Cell
function MyTeamInviteFriendCell:OnRefreshCellView(name, level)
	self.Controls.m_NameText.text = name
	self.Controls.m_LevelText.text = level
end
------------------------------------------------------------
--邀请按钮
function MyTeamInviteFriendCell:OnInviteButtonClick() 
	local myTeam = IGame.TeamClient:GetTeam()
	print("邀请你加入队伍："..tostring(myTeam:GetTeamID()))
	if self.m_Entity~= nil then
		IGame.TeamClient:InvitedJoin(self.m_Entity:GetNumProp(CREATURE_PROP_PDBID))
	end
	
end
------------------------------------------------------------
function MyTeamInviteFriendCell:OnRecycle()
	self.Controls.m_InviteButton.onClick:RemoveListener(self.callback_OnInviteButtonClick)
	UIControl.OnRecycle(self)
end
------------------------------------------------------------
return MyTeamInviteFriendCell
